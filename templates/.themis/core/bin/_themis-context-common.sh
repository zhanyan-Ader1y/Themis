#!/usr/bin/env bash
#
# Themis Context 共享确定性运行时。
# 用途：为 Context 执行器统一提供机器输出、摘要、Workspace containment、revision、锁和事务。
# 边界：只处理显式 Workspace；不发现父目录、不执行语义判断、不改写 Core 或正式 L3 内容。
# 兼容性：保持 Bash 3.2；要求 mikefarah/yq v4、sha256sum、realpath 和标准 POSIX 工具。
#

# shellcheck disable=SC2034
THEMIS_CONTEXT_COMMAND=
THEMIS_CONTEXT_WORKSPACE_INPUT=
THEMIS_CONTEXT_WORKSPACE=
THEMIS_CONTEXT_PROJECT_ROOT=
THEMIS_CONTEXT_SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
THEMIS_CONTEXT_CORE_ROOT=$(CDPATH='' cd -- "${THEMIS_CONTEXT_SCRIPT_DIR}/.." && pwd)
THEMIS_CONTEXT_PROTOCOL_ROOT="${THEMIS_CONTEXT_CORE_ROOT}/protocols/context"
THEMIS_CONTEXT_YQ=${YQ:-yq}
THEMIS_CONTEXT_TMP_ROOT=
THEMIS_CONTEXT_WARNINGS=
THEMIS_CONTEXT_ERRORS=
THEMIS_CONTEXT_LOCK_HELD=0
THEMIS_CONTEXT_LOCK_TOKEN=
THEMIS_CONTEXT_LOCK_DIR=
THEMIS_CONTEXT_TRANSACTION_ACTIVE=0
THEMIS_CONTEXT_TRANSACTION_DIR=
THEMIS_CONTEXT_TRANSACTION_MANIFEST=
THEMIS_CONTEXT_TRANSACTION_PHASE=
THEMIS_CONTEXT_PROJECT_NAME=
THEMIS_CONTEXT_PROJECT_LOGICAL_ROOT=
THEMIS_CONTEXT_WORKSPACE_DIGEST=
THEMIS_CONTEXT_CATALOG=
THEMIS_CONTEXT_CATALOG_DIGEST=

# 将任意字符串转换为 JSON 字符串内容。
themis_context_json_escape() {
  local value=${1-}
  value=${value//\/\\}
  value=${value//\"/\\\"}
  value=${value//$'\r'/\\r}
  value=${value//$'\n'/\\n}
  value=${value//$'\t'/\\t}
  printf '%s' "${value}"
}

# 将稳定 warning 追加到结果数组。
themis_context_add_warning() {
  local id=$1
  local path=${2-}
  local entry
  entry="{\"id\":\"$(themis_context_json_escape "${id}")\""
  if [ -n "${path}" ]; then
    entry="${entry},\"path\":\"$(themis_context_json_escape "${path}")\""
  fi
  entry="${entry}}"
  if [ -n "${THEMIS_CONTEXT_WARNINGS}" ]; then
    THEMIS_CONTEXT_WARNINGS="${THEMIS_CONTEXT_WARNINGS},${entry}"
  else
    THEMIS_CONTEXT_WARNINGS=${entry}
  fi
}

# 将稳定 error 追加到结果数组；自然语言诊断只写 stderr。
themis_context_add_error() {
  local id=$1
  local path=${2-}
  local entry
  entry="{\"id\":\"$(themis_context_json_escape "${id}")\""
  if [ -n "${path}" ]; then
    entry="${entry},\"path\":\"$(themis_context_json_escape "${path}")\""
  fi
  entry="${entry}}"
  if [ -n "${THEMIS_CONTEXT_ERRORS}" ]; then
    THEMIS_CONTEXT_ERRORS="${THEMIS_CONTEXT_ERRORS},${entry}"
  else
    THEMIS_CONTEXT_ERRORS=${entry}
  fi
}

# 输出恰好一个稳定 JSON object，并返回与 status 对应的退出码。
themis_context_emit() {
  local status=$1
  local data=${2:-'{}'}
  local exit_code=1
  local workspace_value=${THEMIS_CONTEXT_WORKSPACE_INPUT-}
  case "${status}" in
    ok) exit_code=0 ;;
    invalid) exit_code=1 ;;
    needs_adjudication|unavailable) exit_code=2 ;;
  esac
  printf '{"schema":"themis-context-result","command":"%s","status":"%s","workspace":"%s","data":%s,"warnings":[%s],"errors":[%s]}\n' \
    "$(themis_context_json_escape "${THEMIS_CONTEXT_COMMAND}")" \
    "${status}" \
    "$(themis_context_json_escape "${workspace_value}")" \
    "${data}" \
    "${THEMIS_CONTEXT_WARNINGS}" \
    "${THEMIS_CONTEXT_ERRORS}"
  return "${exit_code}"
}

# 输出稳定 UTC RFC3339 秒精度时间。
themis_context_now() {
  TZ=UTC date '+%Y-%m-%dT%H:%M:%SZ'
}

# 对 stdin 原始字节计算协议摘要。
themis_context_sha256_stdin() {
  local digest
  digest=$(sha256sum | cut -d' ' -f1) || return 1
  printf 'sha256:%s\n' "${digest}"
}

# 对文件原始字节计算协议摘要。
themis_context_file_digest() {
  local file=$1
  local digest
  digest=$(sha256sum "${file}" | cut -d' ' -f1) || return 1
  printf 'sha256:%s\n' "${digest}"
}

# 对 YAML 执行递归 key-sort 和紧凑 JSON canonicalization。
themis_context_yaml_digest() {
  local file=$1
  {
    "${THEMIS_CONTEXT_YQ}" -o=json -I=0 'sort_keys(..)' "${file}" 2>/dev/null || return 1
    printf '\n'
  } | themis_context_sha256_stdin
}

# 计算 Catalog registry 身份；revision 与自摘要不改变受治理内容身份。
themis_context_catalog_digest() {
  local file=$1
  {
    "${THEMIS_CONTEXT_YQ}" -o=json -I=0 'del(.catalog_digest, .revision) | sort_keys(..)' "${file}" 2>/dev/null || return 1
    printf '\n'
  } | themis_context_sha256_stdin
}

# 从 Markdown 提取 YAML frontmatter；输入必须以 --- 开始并具有结束分隔符。
themis_context_extract_frontmatter() {
  local item=$1
  local output=$2
  awk '
    NR == 1 { sub(/^\357\273\277/, ""); if ($0 != "---") exit 2; active=1; next }
    active && $0 == "---" { found=1; exit }
    active { sub(/\r$/, ""); print }
    END { if (!found) exit 3 }
  ' "${item}" >"${output}"
}

# 从 Markdown 提取正文并归一化为 LF 和单个末尾换行。
themis_context_extract_body() {
  local item=$1
  local output=$2
  awk '
    NR == 1 { sub(/^\357\273\277/, ""); if ($0 != "---") exit 2; next }
    !frontmatter_done && $0 == "---" { frontmatter_done=1; next }
    frontmatter_done { sub(/\r$/, ""); lines[++count]=$0 }
    END {
      while (count > 0 && lines[count] == "") count--
      for (i=1; i<=count; i++) print lines[i]
      if (count == 0) print ""
    }
  ' "${item}" >"${output}"
}

# 校验 Context 相对路径，拒绝歧义、逃逸和任一祖先符号链接。
themis_context_resolve_relative_path() {
  local relative=$1
  local base=${2:-${THEMIS_CONTEXT_WORKSPACE}}
  local current=${base}
  local segment
  local remainder=${relative}

  case "${relative}" in
    ''|/*|[A-Za-z]:*|*\\*|*$'\n'*|*$'\r'*|*$'\t'*|*/|*'//'*) return 1 ;;
  esac
  while :; do
    segment=${remainder%%/*}
    case "${segment}" in ''|.|..) return 1 ;; esac
    current="${current}/${segment}"
    if [ -L "${current}" ]; then
      return 1
    fi
    if [ "${remainder}" = "${segment}" ]; then
      break
    fi
    remainder=${remainder#*/}
  done
  case "$(realpath -m -- "${current}")" in
    "$(realpath -m -- "${base}")"/*) printf '%s\n' "${current}" ;;
    *) return 1 ;;
  esac
}

# 校验协议摘要字符串。
themis_context_digest_valid() {
  local value=${1-}
  local suffix
  case "${value}" in sha256:*) suffix=${value#sha256:} ;; *) return 1 ;; esac
  [ "${#suffix}" -eq 64 ] || return 1
  case "${suffix}" in *[!0-9a-f]*) return 1 ;; esac
  return 0
}

# 校验固定前缀加十六进制身份。
themis_context_hash_id_valid() {
  local value=$1
  local prefix=$2
  local suffix=${value#"${prefix}"}
  [ "${suffix}" != "${value}" ] || return 1
  [ "${#suffix}" -eq 64 ] || return 1
  case "${suffix}" in *[!0-9a-f]*) return 1 ;; esac
  return 0
}

# 校验 CTX 稳定身份。
themis_context_item_id_valid() {
  local value=${1-}
  local suffix
  case "${value}" in CTX-*) suffix=${value#CTX-} ;; *) return 1 ;; esac
  [ "${#suffix}" -ge 3 ] || return 1
  case "${suffix}" in *[!0-9]*) return 1 ;; esac
  return 0
}

# 校验 Catalog 引用存在性和 supersession 无环；单次 yq 批量导出后由 awk 判图。
themis_context_validate_catalog_graph() {
  local file=${1:-${THEMIS_CONTEXT_CATALOG}}
  # shellcheck disable=SC2016
  "${THEMIS_CONTEXT_YQ}" eval -r '
    .items | to_entries |
    map(. as $entry |
      [["N", .key]] +
      [.value.dependencies[]? | ["D", $entry.key, .]] +
      [.value.supersedes[]? | ["S", $entry.key, .]]) |
    flatten(1) | .[] | @tsv
  ' "${file}" 2>/dev/null | awk -F '\t' '
    NF == 0 { next }
    $1 == "N" { nodes[$2] = 1; next }
    $1 == "D" { refs[$3] = 1; next }
    $1 == "S" { refs[$3] = 1; supersedes[$2 SUBSEP $3] = 1; next }
    { invalid = 1 }
    function visit(node, key, parts, target) {
      state[node] = 1
      for (key in supersedes) {
        split(key, parts, SUBSEP)
        if (parts[1] != node) continue
        target = parts[2]
        if (state[target] == 1) invalid = 1
        else if (state[target] == 0) visit(target)
      }
      state[node] = 2
    }
    END {
      for (target in refs) if (!(target in nodes)) invalid = 1
      for (node in nodes) if (state[node] == 0) visit(node)
      exit invalid ? 1 : 0
    }
  '
}

# 批量校验 Catalog 结构、自摘要和引用图，不逐字段启动 yq。
themis_context_validate_catalog() {
  local file=${1:-${THEMIS_CONTEXT_CATALOG}}
  local actual_digest
  if ! "${THEMIS_CONTEXT_YQ}" eval -e '
    (keys | length) == 7 and
    has("binding") and has("catalog_digest") and has("catalog_schema") and has("items") and
    has("project") and has("revision") and has("workspace_identity_digest") and
    .catalog_schema == "themis-context-catalog" and
    (.binding == "unbound" or .binding == "bound") and
    (.project | type) == "!!map" and
    (.project | keys | length) == 2 and (.project | has("name")) and (.project | has("root")) and
    .project.root == "." and
    (.revision | type) == "!!map" and
    (.revision | keys | length) == 3 and (.revision | has("commit")) and (.revision | has("kind")) and (.revision | has("worktree")) and
    (.revision.kind == "git" or .revision.kind == "unavailable") and
    (.items | type) == "!!map" and
    ((.binding == "unbound" and
      .project.name == null and .workspace_identity_digest == null and .revision.kind == "unavailable" and (.items | length) == 0) or
     (.binding == "bound" and
      (.project.name | type) == "!!str" and .project.name != "" and
      (.workspace_identity_digest | type) == "!!str")) and
    ([.items[] | select(
      (keys | length) != 15 or
      (has("abstract") | not) or (has("authority") | not) or (has("category") | not) or
      (has("content_digest") | not) or (has("dependencies") | not) or (has("item_digest") | not) or
      (has("kind") | not) or (has("overview") | not) or (has("path") | not) or
      (has("scope") | not) or (has("source_refs") | not) or (has("status") | not) or
      (has("supersedes") | not) or (has("tags") | not) or (has("title") | not) or
      (.path | type) != "!!str" or (.title | type) != "!!str" or
      (.kind | type) != "!!str" or (.abstract | type) != "!!str" or (.overview | type) != "!!str" or
      (.scope | type) != "!!seq" or (.tags | type) != "!!seq" or (.source_refs | type) != "!!seq" or
      (.dependencies | type) != "!!seq" or (.supersedes | type) != "!!seq" or
      (.category != "domain" and .category != "glossary" and .category != "decisions" and
       .category != "architecture" and .category != "engineering" and .category != "pitfalls" and .category != "external") or
      (.authority != "declared" and .authority != "governed" and .authority != "external_reference" and
       .authority != "derived_fact" and .authority != "derived_navigation") or
      (.status != "active" and .status != "deprecated" and .status != "superseded" and .status != "archived")
    )] | length) == 0
  ' "${file}" >/dev/null 2>&1; then
    return 1
  fi
  if [ "${file}" = "${THEMIS_CONTEXT_CATALOG-}" ] && [ -n "${THEMIS_CONTEXT_CATALOG_DIGEST-}" ]; then
    actual_digest=${THEMIS_CONTEXT_CATALOG_DIGEST}
  else
    actual_digest=$(themis_context_catalog_digest "${file}") || return 1
  fi
  [ "$("${THEMIS_CONTEXT_YQ}" eval -r '.catalog_digest // ""' "${file}")" = "${actual_digest}" ] || return 1
  themis_context_validate_catalog_graph "${file}" || return 1
  return 0
}

# 校验 Bundle manifest 的固定字段、类型和状态合同。
themis_context_validate_bundle_manifest() {
  local manifest=$1
  "${THEMIS_CONTEXT_YQ}" eval -e '
    (keys | length) == 14 and
    has("bundle_schema") and has("id") and has("request") and has("catalog_digest") and
    has("revision") and has("candidates") and has("selected") and has("excluded") and
    has("code_refs") and has("signal_refs") and has("token_budget") and has("content_budget_bytes") and
    has("content_bytes") and has("status") and
    .bundle_schema == "themis-context-bundle" and
    (.id | type) == "!!str" and (.id | test("^CBL-[0-9a-f]{64}$")) and
    (.request | type) == "!!map" and
    (.request | keys | length) == 5 and (.request | has("intent")) and (.request | has("spec_ref")) and
    (.request | has("task_ref")) and (.request | has("scope")) and (.request | has("filters")) and
    (.catalog_digest | type) == "!!str" and (.catalog_digest | test("^sha256:[0-9a-f]{64}$")) and
    (.revision | type) == "!!map" and (.revision | keys | length) == 3 and
    (.revision | has("commit")) and (.revision | has("kind")) and (.revision | has("worktree")) and
    ((.revision.kind == "git" and (.revision.commit | type) == "!!str" and
      (.revision.worktree == "clean" or .revision.worktree == "dirty")) or
     (.revision.kind == "unavailable" and .revision.commit == null and .revision.worktree == "unknown")) and
    (.candidates | type) == "!!seq" and (.selected | type) == "!!seq" and (.excluded | type) == "!!seq" and
    ((.candidates + .selected + .excluded) |
      [.[] | select(
        type != "!!map" or
        ((keys - ["reason"]) | length) != 4 or
        (has("id") | not) or (has("path") | not) or (has("digest") | not) or (has("freshness") | not) or
        (.id | type) != "!!str" or (.id | test("^CTX-[0-9]{3,}$") | not) or
        (.path | type) != "!!str" or .path == "" or
        (.digest | type) != "!!str" or (.digest | test("^sha256:[0-9a-f]{64}$") | not) or
        (.freshness | type) != "!!str" or
        (has("reason") and (.reason | type) != "!!str")
      )] | length) == 0 and
    (([.selected[]?.id] + [.excluded[]?.id]) | length) ==
      (([.selected[]?.id] + [.excluded[]?.id]) | unique | length) and
    ((([.selected[]?.id] + [.excluded[]?.id]) - [.candidates[]?.id]) | length) == 0 and
    (.code_refs | type) == "!!seq" and (.signal_refs | type) == "!!seq" and
    ([.signal_refs[]? | select(type != "!!str" or (test("^CSG-[0-9a-f]{64}$") | not))] | length) == 0 and
    (.token_budget | type) == "!!int" and .token_budget > 0 and
    (.content_budget_bytes | type) == "!!int" and .content_budget_bytes > 0 and
    (.content_bytes | type) == "!!int" and .content_bytes >= 0 and .content_bytes <= .content_budget_bytes and
    (.status == "partial" or .status == "complete" or .status == "conflict" or .status == "unavailable")
  ' "${manifest}" >/dev/null 2>&1
}

# 校验持久 Signal 的固定字段、枚举和人工处置结构。
themis_context_validate_signal() {
  local signal=$1
  "${THEMIS_CONTEXT_YQ}" eval -e '
    (keys | length) == 13 and
    has("signal_schema") and has("id") and has("kind") and has("status") and has("project") and
    has("workspace_identity_digest") and has("revision") and has("scope") and has("sources") and
    has("evidence_refs") and has("first_observed_at") and has("last_observed_at") and has("disposition") and
    .signal_schema == "themis-context-signal" and
    (.id | type) == "!!str" and (.id | test("^CSG-[0-9a-f]{64}$")) and
    (.kind == "missing" or .kind == "stale" or .kind == "context_conflict" or .kind == "context_code_drift") and
    (.status == "open" or .status == "resolved" or .status == "accepted" or .status == "superseded") and
    (.project | type) == "!!str" and
    (.workspace_identity_digest | type) == "!!str" and
    (.workspace_identity_digest | test("^sha256:[0-9a-f]{64}$")) and
    (.revision | type) == "!!map" and (.revision | keys | length) == 3 and
    (.revision | has("commit")) and (.revision | has("kind")) and (.revision | has("worktree")) and
    ((.revision.kind == "git" and (.revision.commit | type) == "!!str" and
      (.revision.worktree == "clean" or .revision.worktree == "dirty")) or
     (.revision.kind == "unavailable" and .revision.commit == null and .revision.worktree == "unknown")) and
    (.scope | type) == "!!seq" and (.sources | type) == "!!seq" and
    ([.scope[]? | select(type != "!!str")] | length) == 0 and
    ([.sources[]? | select(
      type != "!!map" or
      (keys | length) != 4 or
      (has("path") | not) or (has("expected_digest") | not) or
      (has("actual_digest") | not) or (has("state") | not) or
      (.path | type) != "!!str" or
      ((.expected_digest != null) and
       ((.expected_digest | type) != "!!str" or (.expected_digest | test("^sha256:[0-9a-f]{64}$") | not))) or
      ((.actual_digest != null) and
       ((.actual_digest | type) != "!!str" or (.actual_digest | test("^sha256:[0-9a-f]{64}$") | not))) or
      (.state != "current" and .state != "missing" and .state != "drift")
    )] | length) == 0 and
    (.evidence_refs | type) == "!!seq" and
    ([.evidence_refs[]? | select(
      type != "!!map" or (keys | length) != 2 or
      (has("path") | not) or (has("digest") | not) or
      (.path | type) != "!!str" or
      (.digest | type) != "!!str" or (.digest | test("^sha256:[0-9a-f]{64}$") | not)
    )] | length) == 0 and
    (.first_observed_at | type) == "!!str" and
    (.last_observed_at | type) == "!!str" and
    ((.status == "open" and .disposition == null) or
     (.status != "open" and (.disposition | type) == "!!map" and (.disposition | keys | length) == 3 and
      (.disposition | has("actor")) and (.disposition | has("note")) and (.disposition | has("decided_at"))))
  ' "${signal}" >/dev/null 2>&1
}

# 解析并校验一个 L3 Item；结果字段供 Catalog/Lint 调用方复用。
themis_context_load_item() {
  local item=$1
  local frontmatter="${THEMIS_CONTEXT_TMP_ROOT}/item-frontmatter-$$.yaml"
  local body="${THEMIS_CONTEXT_TMP_ROOT}/item-body-$$.md"
  local values
  local old_ifs
  if [ ! -f "${item}" ] || [ -L "${item}" ]; then
    return 1
  fi
  themis_context_extract_frontmatter "${item}" "${frontmatter}" || return 1
  themis_context_extract_body "${item}" "${body}" || return 1
  if ! "${THEMIS_CONTEXT_YQ}" eval -e '
    (keys | length) == 15 and
    has("abstract") and has("authority") and has("category") and has("content_digest") and
    has("context_item_schema") and has("dependencies") and has("id") and has("kind") and
    has("overview") and has("scope") and has("source_refs") and has("status") and
    has("supersedes") and has("tags") and has("title") and
    .context_item_schema == "themis-context-item" and
    (.id | type) == "!!str" and (.title | type) == "!!str" and .title != "" and
    (.kind | type) == "!!str" and .kind != "" and
    (.abstract | type) == "!!str" and (.overview | type) == "!!str" and
    (.scope | type) == "!!seq" and (.tags | type) == "!!seq" and (.source_refs | type) == "!!seq" and
    (.dependencies | type) == "!!seq" and (.supersedes | type) == "!!seq" and
    (([.id, .title, .kind, .abstract, .overview] + .scope + .tags + .dependencies + .supersedes) |
      [.[] | select(type == "!!str" and test("[\\t\\r\\n]"))] | length) == 0 and
    (.category == "domain" or .category == "glossary" or .category == "decisions" or
     .category == "architecture" or .category == "engineering" or .category == "pitfalls" or .category == "external") and
    (.authority == "declared" or .authority == "governed" or .authority == "external_reference" or
     .authority == "derived_fact" or .authority == "derived_navigation") and
    (.status == "active" or .status == "deprecated" or .status == "superseded" or .status == "archived") and
    ((.scope + .tags + .dependencies + .supersedes) |
      [.[] | select(type != "!!str")] | length) == 0 and
    (((.dependencies + .supersedes) |
      [.[] | select(test("^CTX-[0-9]{3,}$") | not)] | length) == 0) and
    ([.source_refs[]? | select(
      type != "!!map" or
      (keys | length) != 2 or
      (has("path") | not) or (has("digest") | not) or
      (.path | type) != "!!str" or .path == "" or
      (.digest | type) != "!!str" or
      (.digest | test("^sha256:[0-9a-f]{64}$") | not)
    )] | length) == 0
  ' "${frontmatter}" >/dev/null 2>&1; then
    return 1
  fi
  THEMIS_CONTEXT_ITEM_CONTENT_DIGEST=$(themis_context_file_digest "${body}") || return 1
  if [ "$("${THEMIS_CONTEXT_YQ}" eval -r '.content_digest // ""' "${frontmatter}")" != "${THEMIS_CONTEXT_ITEM_CONTENT_DIGEST}" ]; then
    return 1
  fi
  THEMIS_CONTEXT_ITEM_DIGEST=$(
    {
      "${THEMIS_CONTEXT_YQ}" -o=json -I=0 'del(.content_digest) | sort_keys(..)' "${frontmatter}" 2>/dev/null
      printf '%s\n' "${THEMIS_CONTEXT_ITEM_CONTENT_DIGEST}"
    } | themis_context_sha256_stdin
  ) || return 1
  values=$("${THEMIS_CONTEXT_YQ}" eval -r '[.id, .title, .category, .kind, .authority, .status] | @tsv' "${frontmatter}") || return 1
  old_ifs=${IFS}
  IFS=$'\t'
  # shellcheck disable=SC2086
  set -- ${values}
  IFS=${old_ifs}
  THEMIS_CONTEXT_ITEM_ID=${1-}
  THEMIS_CONTEXT_ITEM_TITLE=${2-}
  THEMIS_CONTEXT_ITEM_CATEGORY=${3-}
  THEMIS_CONTEXT_ITEM_KIND=${4-}
  THEMIS_CONTEXT_ITEM_AUTHORITY=${5-}
  THEMIS_CONTEXT_ITEM_STATUS=${6-}
  themis_context_item_id_valid "${THEMIS_CONTEXT_ITEM_ID}" || return 1
  THEMIS_CONTEXT_ITEM_FRONTMATTER=${frontmatter}
  THEMIS_CONTEXT_ITEM_BODY=${body}
  return 0
}

# 从一个已校验 Item 生成 Catalog entry YAML。
themis_context_render_item_entry() {
  local path=$1
  local output=$2
  THEMIS_CONTEXT_ITEM_PATH=${path} THEMIS_CONTEXT_ITEM_DIGEST_VALUE=${THEMIS_CONTEXT_ITEM_DIGEST} \
    "${THEMIS_CONTEXT_YQ}" eval '
      {
        "path": strenv(THEMIS_CONTEXT_ITEM_PATH),
        "title": .title,
        "category": .category,
        "kind": .kind,
        "authority": .authority,
        "status": .status,
        "scope": .scope,
        "tags": .tags,
        "abstract": .abstract,
        "overview": .overview,
        "source_refs": .source_refs,
        "dependencies": .dependencies,
        "supersedes": .supersedes,
        "content_digest": .content_digest,
        "item_digest": strenv(THEMIS_CONTEXT_ITEM_DIGEST_VALUE)
      }
    ' "${THEMIS_CONTEXT_ITEM_FRONTMATTER}" >"${output}"
}

# 检查运行依赖，失败时仍输出协议 JSON。
themis_context_require_runtime() {
  local version
  for command_name in "${THEMIS_CONTEXT_YQ}" sha256sum realpath awk sort; do
    if ! command -v "${command_name}" >/dev/null 2>&1; then
      printf 'Themis Context failed: required command %s is unavailable.\n' "${command_name}" >&2
      themis_context_add_error runtime_dependency_missing "${command_name}"
      themis_context_emit unavailable '{}'
      return $?
    fi
  done
  version=$("${THEMIS_CONTEXT_YQ}" --version 2>&1 || true)
  case "${version}" in
    *mikefarah/yq*version\ v4.*) ;;
    *)
      printf '%s\n' 'Themis Context failed: mikefarah/yq v4 is required.' >&2
      themis_context_add_error unsupported_yq
      themis_context_emit unavailable '{}'
      return $?
      ;;
  esac
  return 0
}

# 初始化进程级临时目录；只使用系统临时区，不写 Workspace。
themis_context_prepare_temp() {
  THEMIS_CONTEXT_TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/themis-context.XXXXXX") || return 1
  return 0
}

# 验证显式 Workspace 和固定 manifest paths，并读取逻辑 identity。
themis_context_open_workspace() {
  local workspace_schema
  local artifact_schema
  local project_name
  local project_root
  local context_path
  local state_path
  local cache_path
  local manifest_values
  local old_ifs
  local workspace_real
  if [ -z "${THEMIS_CONTEXT_WORKSPACE_INPUT}" ] || [ ! -d "${THEMIS_CONTEXT_WORKSPACE_INPUT}" ]; then
    printf '%s\n' 'Themis Context failed: explicit Workspace directory is required.' >&2
    themis_context_add_error workspace_missing "${THEMIS_CONTEXT_WORKSPACE_INPUT}"
    return 1
  fi
  if [ -L "${THEMIS_CONTEXT_WORKSPACE_INPUT}" ]; then
    themis_context_add_error workspace_symlink_forbidden "${THEMIS_CONTEXT_WORKSPACE_INPUT}"
    return 1
  fi
  workspace_real=$(realpath -- "${THEMIS_CONTEXT_WORKSPACE_INPUT}") || return 1
  THEMIS_CONTEXT_WORKSPACE=${workspace_real}
  if [ ! -f "${THEMIS_CONTEXT_WORKSPACE}/manifest.yaml" ] || [ -L "${THEMIS_CONTEXT_WORKSPACE}/manifest.yaml" ]; then
    themis_context_add_error unsupported_workspace_layout manifest.yaml
    return 2
  fi
  manifest_values=$("${THEMIS_CONTEXT_YQ}" eval -r \
    '[.workspace_schema // "", .artifact_schema // "", .project.name // "", .project.root // "", .paths.context // "", .paths.state // "", .paths.cache // ""] | join("")' \
    "${THEMIS_CONTEXT_WORKSPACE}/manifest.yaml" 2>/dev/null) || {
    themis_context_add_error manifest_invalid manifest.yaml
    return 1
  }
  old_ifs=${IFS}
  IFS=$'\037'
  read -r workspace_schema artifact_schema project_name project_root context_path state_path cache_path <<EOF
${manifest_values}
EOF
  IFS=${old_ifs}
  if [ "${workspace_schema}" != 'themis-workspace' ] || [ "${artifact_schema}" != 'themis-artifact' ] || \
     [ "${project_root}" != '.' ] || [ "${context_path}" != 'workspace/context' ] || \
     [ "${state_path}" != 'workspace/state' ] || [ "${cache_path}" != 'workspace/cache' ]; then
    themis_context_add_error unsupported_workspace_layout manifest.yaml
    return 2
  fi
  THEMIS_CONTEXT_PROJECT_NAME=${project_name}
  THEMIS_CONTEXT_PROJECT_LOGICAL_ROOT=${project_root}
  THEMIS_CONTEXT_CATALOG="${THEMIS_CONTEXT_WORKSPACE}/context/catalog.yaml"
  if [ ! -f "${THEMIS_CONTEXT_CATALOG}" ] || [ -L "${THEMIS_CONTEXT_CATALOG}" ]; then
    themis_context_add_error unsupported_workspace_layout context/catalog.yaml
    return 2
  fi
  THEMIS_CONTEXT_WORKSPACE_DIGEST=$(
    {
      "${THEMIS_CONTEXT_YQ}" -o=json -I=0 \
        '{"workspace_schema": .workspace_schema, "artifact_schema": .artifact_schema, "project": {"name": .project.name, "root": .project.root}, "paths": .paths} | sort_keys(..)' \
        "${THEMIS_CONTEXT_WORKSPACE}/manifest.yaml" 2>/dev/null || return 1
      printf '\n'
    } | themis_context_sha256_stdin
  ) || {
    themis_context_add_error workspace_identity_digest_failed manifest.yaml
    return 1
  }
  THEMIS_CONTEXT_CATALOG_DIGEST=$(themis_context_catalog_digest "${THEMIS_CONTEXT_CATALOG}") || return 1
  return 0
}

# 校验显式项目 root 与 Workspace 的声明关系。
themis_context_open_project_root() {
  local project_real
  local workspace_parent
  if [ -z "${THEMIS_CONTEXT_PROJECT_ROOT}" ] || [ ! -d "${THEMIS_CONTEXT_PROJECT_ROOT}" ] || [ -L "${THEMIS_CONTEXT_PROJECT_ROOT}" ]; then
    themis_context_add_error project_root_missing "${THEMIS_CONTEXT_PROJECT_ROOT}"
    return 1
  fi
  project_real=$(realpath -- "${THEMIS_CONTEXT_PROJECT_ROOT}") || return 1
  workspace_parent=$(realpath -m -- "${THEMIS_CONTEXT_WORKSPACE}/../..")
  if [ "${project_real}" != "${workspace_parent}" ]; then
    themis_context_add_error project_workspace_mismatch "${THEMIS_CONTEXT_PROJECT_ROOT}"
    return 2
  fi
  THEMIS_CONTEXT_PROJECT_ROOT=${project_real}
  return 0
}

# 输出当前 Git 或 unavailable revision 的紧凑 JSON。
themis_context_revision_json() {
  local root=$1
  local commit
  local worktree=unknown
  if command -v git >/dev/null 2>&1 && git -C "${root}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    commit=$(git -C "${root}" rev-parse HEAD 2>/dev/null || true)
    if [ -n "${commit}" ]; then
      if [ -n "$(git -C "${root}" status --porcelain 2>/dev/null)" ]; then
        worktree=dirty
      else
        worktree=clean
      fi
      printf '{"kind":"git","commit":"%s","worktree":"%s"}\n' "${commit}" "${worktree}"
      return 0
    fi
  fi
  printf '%s\n' '{"kind":"unavailable","commit":null,"worktree":"unknown"}'
}

# 获取 Context 专属 owner-token 锁；未知已有锁必须人工裁决。
themis_context_acquire_lock() {
  local operation=$1
  local lock_parent="${THEMIS_CONTEXT_WORKSPACE}/state/locks"
  local now
  local host
  local token_input
  THEMIS_CONTEXT_LOCK_DIR="${lock_parent}/context.lock"
  if [ ! -d "${lock_parent}" ] || [ -L "${lock_parent}" ]; then
    themis_context_add_error unsupported_workspace_layout state/locks
    return 2
  fi
  now=$(themis_context_now)
  host=$(hostname 2>/dev/null | LC_ALL=C tr -cd 'A-Za-z0-9._-' || true)
  [ -n "${host}" ] || host=unknown
  token_input="${operation}|$$|${host}|${now}|${THEMIS_CONTEXT_TMP_ROOT}|${THEMIS_CONTEXT_WORKSPACE_DIGEST}"
  THEMIS_CONTEXT_LOCK_TOKEN=$(printf '%s\n' "${token_input}" | themis_context_sha256_stdin)
  if ! mkdir "${THEMIS_CONTEXT_LOCK_DIR}" 2>/dev/null; then
    themis_context_add_error context_lock_present state/locks/context.lock
    return 2
  fi
  THEMIS_CONTEXT_LOCK_OPERATION=${operation} THEMIS_CONTEXT_LOCK_PID=$$ THEMIS_CONTEXT_LOCK_HOST=${host} \
  THEMIS_CONTEXT_LOCK_STARTED_AT=${now} THEMIS_CONTEXT_LOCK_WORKSPACE=${THEMIS_CONTEXT_WORKSPACE_DIGEST} \
  THEMIS_CONTEXT_LOCK_OWNER_TOKEN=${THEMIS_CONTEXT_LOCK_TOKEN} "${THEMIS_CONTEXT_YQ}" -n '
    {
      "operation": strenv(THEMIS_CONTEXT_LOCK_OPERATION),
      "pid": (strenv(THEMIS_CONTEXT_LOCK_PID) | tonumber),
      "host": strenv(THEMIS_CONTEXT_LOCK_HOST),
      "started_at": strenv(THEMIS_CONTEXT_LOCK_STARTED_AT),
      "workspace_identity_digest": strenv(THEMIS_CONTEXT_LOCK_WORKSPACE),
      "owner_token": strenv(THEMIS_CONTEXT_LOCK_OWNER_TOKEN)
    }
  ' >"${THEMIS_CONTEXT_LOCK_DIR}/owner.yaml" || {
    rmdir "${THEMIS_CONTEXT_LOCK_DIR}" 2>/dev/null || true
    return 1
  }
  THEMIS_CONTEXT_LOCK_HELD=1
  return 0
}

# 只释放 owner token 完全匹配的本进程锁。
themis_context_release_lock() {
  local current_token
  if [ "${THEMIS_CONTEXT_LOCK_HELD}" -ne 1 ] || [ ! -f "${THEMIS_CONTEXT_LOCK_DIR}/owner.yaml" ]; then
    return 0
  fi
  current_token=$("${THEMIS_CONTEXT_YQ}" eval -r '.owner_token // ""' "${THEMIS_CONTEXT_LOCK_DIR}/owner.yaml" 2>/dev/null || true)
  if [ "${current_token}" = "${THEMIS_CONTEXT_LOCK_TOKEN}" ]; then
    rm -f "${THEMIS_CONTEXT_LOCK_DIR}/owner.yaml"
    rmdir "${THEMIS_CONTEXT_LOCK_DIR}" 2>/dev/null || true
  fi
  THEMIS_CONTEXT_LOCK_HELD=0
}

# 在新写操作前拒绝任何未知 Context 事务残留。
themis_context_require_clean_transactions() {
  local root="${THEMIS_CONTEXT_WORKSPACE}/state/transactions/context"
  local entry
  if [ ! -d "${root}" ] || [ -L "${root}" ]; then
    themis_context_add_error unsupported_workspace_layout state/transactions/context
    return 2
  fi
  for entry in "${root}"/*; do
    if [ -e "${entry}" ] && [ "$(basename -- "${entry}")" != '.gitkeep' ]; then
      themis_context_add_error context_transaction_residue "state/transactions/context/$(basename -- "${entry}")"
      return 2
    fi
  done
  return 0
}

# 创建受锁保护的单文件事务，并保存旧状态摘要和 backup。
themis_context_begin_file_transaction() {
  local operation=$1
  local target=$2
  local target_relative=${target#"${THEMIS_CONTEXT_WORKSPACE}/"}
  local identity
  local transaction_root="${THEMIS_CONTEXT_WORKSPACE}/state/transactions/context"
  identity=$(printf '%s\n' "${operation}|${target_relative}|${THEMIS_CONTEXT_LOCK_TOKEN}|$(themis_context_now)" | themis_context_sha256_stdin)
  identity=${identity#sha256:}
  THEMIS_CONTEXT_TRANSACTION_DIR="${transaction_root}/CTXTX-${identity}"
  THEMIS_CONTEXT_TRANSACTION_MANIFEST="${THEMIS_CONTEXT_TRANSACTION_DIR}/transaction.yaml"
  mkdir "${THEMIS_CONTEXT_TRANSACTION_DIR}" || return 1
  mkdir "${THEMIS_CONTEXT_TRANSACTION_DIR}/stage" "${THEMIS_CONTEXT_TRANSACTION_DIR}/backup" || return 1
  cat >"${THEMIS_CONTEXT_TRANSACTION_MANIFEST}" <<EOF
transaction_schema: themis-context-transaction
id: CTXTX-${identity}
operation: ${operation}
owner_token: ${THEMIS_CONTEXT_LOCK_TOKEN}
workspace_identity_digest: ${THEMIS_CONTEXT_WORKSPACE_DIGEST}
target: ${target_relative}
target_kind: file
had_target: $([ -e "${target}" ] && printf 'true' || printf 'false')
phase: prepared
EOF
  if [ -f "${target}" ]; then
    cp -p "${target}" "${THEMIS_CONTEXT_TRANSACTION_DIR}/backup/value"
  fi
  THEMIS_CONTEXT_TRANSACTION_ACTIVE=1
  THEMIS_CONTEXT_TRANSACTION_PHASE=prepared
  return 0
}

# 更新事务 phase，供显式 recovery 和故障注入判断。
themis_context_set_transaction_phase() {
  THEMIS_CONTEXT_TRANSACTION_PHASE=$1
  THEMIS_CONTEXT_PHASE=$1 "${THEMIS_CONTEXT_YQ}" eval -i '.phase = strenv(THEMIS_CONTEXT_PHASE)' "${THEMIS_CONTEXT_TRANSACTION_MANIFEST}"
}

# 提交一个已由调用方 read-back 校验的单文件 replacement。
themis_context_commit_file_transaction() {
  local staged=$1
  local target=$2
  local target_dir
  target_dir=$(dirname -- "${target}")
  cp -p "${staged}" "${THEMIS_CONTEXT_TRANSACTION_DIR}/stage/value" || return 1
  themis_context_set_transaction_phase staged || return 1
  if [ "${THEMIS_CONTEXT_FAIL_PHASE-}" = after_stage ]; then
    return 1
  fi
  if [ -e "${target}" ]; then
    rm -f "${target}"
  fi
  cp -p "${THEMIS_CONTEXT_TRANSACTION_DIR}/stage/value" "${target_dir}/.$(basename -- "${target}").context-new" || return 1
  themis_context_set_transaction_phase replacing || return 1
  if [ "${THEMIS_CONTEXT_FAIL_PHASE-}" = after_backup ]; then
    return 1
  fi
  mv "${target_dir}/.$(basename -- "${target}").context-new" "${target}" || return 1
  themis_context_set_transaction_phase replaced || return 1
  if [ "${THEMIS_CONTEXT_FAIL_PHASE-}" = after_replace ]; then
    return 1
  fi
  rm -rf "${THEMIS_CONTEXT_TRANSACTION_DIR}"
  THEMIS_CONTEXT_TRANSACTION_ACTIVE=0
  THEMIS_CONTEXT_TRANSACTION_DIR=
  THEMIS_CONTEXT_TRANSACTION_MANIFEST=
  return 0
}

# 创建受锁保护的目录事务；目录目标用于完整 Cache candidate replacement。
themis_context_begin_directory_transaction() {
  local operation=$1
  local target=$2
  local target_relative=${target#"${THEMIS_CONTEXT_WORKSPACE}/"}
  local identity
  local transaction_root="${THEMIS_CONTEXT_WORKSPACE}/state/transactions/context"
  identity=$(printf '%s\n' "${operation}|${target_relative}|${THEMIS_CONTEXT_LOCK_TOKEN}|$(themis_context_now)" | themis_context_sha256_stdin)
  identity=${identity#sha256:}
  THEMIS_CONTEXT_TRANSACTION_DIR="${transaction_root}/CTXTX-${identity}"
  THEMIS_CONTEXT_TRANSACTION_MANIFEST="${THEMIS_CONTEXT_TRANSACTION_DIR}/transaction.yaml"
  mkdir "${THEMIS_CONTEXT_TRANSACTION_DIR}" || return 1
  mkdir "${THEMIS_CONTEXT_TRANSACTION_DIR}/stage" "${THEMIS_CONTEXT_TRANSACTION_DIR}/backup" || return 1
  cat >"${THEMIS_CONTEXT_TRANSACTION_MANIFEST}" <<EOF
transaction_schema: themis-context-transaction
id: CTXTX-${identity}
operation: ${operation}
owner_token: ${THEMIS_CONTEXT_LOCK_TOKEN}
workspace_identity_digest: ${THEMIS_CONTEXT_WORKSPACE_DIGEST}
target: ${target_relative}
target_kind: directory
had_target: $([ -e "${target}" ] && printf 'true' || printf 'false')
phase: prepared
EOF
  if [ -d "${target}" ]; then
    cp -Rp "${target}/." "${THEMIS_CONTEXT_TRANSACTION_DIR}/backup/" || return 1
  elif [ -e "${target}" ]; then
    return 1
  fi
  THEMIS_CONTEXT_TRANSACTION_ACTIVE=1
  THEMIS_CONTEXT_TRANSACTION_PHASE=prepared
  return 0
}

# 以同一父目录内 rename 提交完整目录，不暴露半完成 Cache。
themis_context_commit_directory_transaction() {
  local staged=$1
  local target=$2
  local target_dir
  local pending
  target_dir=$(dirname -- "${target}")
  pending="${target_dir}/.$(basename -- "${target}").context-new"
  mkdir "${THEMIS_CONTEXT_TRANSACTION_DIR}/stage/value" || return 1
  cp -Rp "${staged}/." "${THEMIS_CONTEXT_TRANSACTION_DIR}/stage/value/" || return 1
  themis_context_set_transaction_phase staged || return 1
  if [ "${THEMIS_CONTEXT_FAIL_PHASE-}" = after_stage ]; then return 1; fi
  rm -rf "${pending}"
  mkdir "${pending}" || return 1
  cp -Rp "${THEMIS_CONTEXT_TRANSACTION_DIR}/stage/value/." "${pending}/" || return 1
  themis_context_set_transaction_phase replacing || return 1
  if [ "${THEMIS_CONTEXT_FAIL_PHASE-}" = after_backup ]; then return 1; fi
  rm -rf "${target}"
  mv "${pending}" "${target}" || return 1
  themis_context_set_transaction_phase replaced || return 1
  if [ "${THEMIS_CONTEXT_FAIL_PHASE-}" = after_replace ]; then return 1; fi
  rm -rf "${THEMIS_CONTEXT_TRANSACTION_DIR}"
  THEMIS_CONTEXT_TRANSACTION_ACTIVE=0
  THEMIS_CONTEXT_TRANSACTION_DIR=
  THEMIS_CONTEXT_TRANSACTION_MANIFEST=
  return 0
}

# 回滚本进程活动事务；恢复失败时保留 recovery path。
themis_context_rollback_transaction() {
  local target_relative
  local target
  local had_target
  local target_kind
  if [ "${THEMIS_CONTEXT_TRANSACTION_ACTIVE}" -ne 1 ] || [ ! -f "${THEMIS_CONTEXT_TRANSACTION_MANIFEST}" ]; then
    return 0
  fi
  target_relative=$("${THEMIS_CONTEXT_YQ}" eval -r '.target' "${THEMIS_CONTEXT_TRANSACTION_MANIFEST}" 2>/dev/null || true)
  had_target=$("${THEMIS_CONTEXT_YQ}" eval -r '.had_target' "${THEMIS_CONTEXT_TRANSACTION_MANIFEST}" 2>/dev/null || true)
  target_kind=$("${THEMIS_CONTEXT_YQ}" eval -r '.target_kind // "file"' "${THEMIS_CONTEXT_TRANSACTION_MANIFEST}" 2>/dev/null || true)
  target=$(themis_context_resolve_relative_path "${target_relative}" "${THEMIS_CONTEXT_WORKSPACE}") || return 1
  if [ "${THEMIS_CONTEXT_FAIL_PHASE-}" = restore ] || [ "${THEMIS_CONTEXT_FAIL_RESTORE-}" = 1 ]; then
    themis_context_add_error context_restore_failed "${THEMIS_CONTEXT_TRANSACTION_DIR#"${THEMIS_CONTEXT_WORKSPACE}/"}"
    return 1
  fi
  case "${target_kind}:${had_target}" in
    file:true)
      [ -f "${THEMIS_CONTEXT_TRANSACTION_DIR}/backup/value" ] || return 1
      cp -p "${THEMIS_CONTEXT_TRANSACTION_DIR}/backup/value" "${target}" || return 1
      ;;
    file:false) rm -f "${target}" ;;
    directory:true)
      rm -rf "${target}"
      mkdir "${target}" || return 1
      cp -Rp "${THEMIS_CONTEXT_TRANSACTION_DIR}/backup/." "${target}/" || return 1
      ;;
    directory:false) rm -rf "${target}" ;;
    *) return 1 ;;
  esac
  rm -rf "${THEMIS_CONTEXT_TRANSACTION_DIR}"
  THEMIS_CONTEXT_TRANSACTION_ACTIVE=0
  return 0
}

# 恢复一个可验证的单文件 Context 事务；未知形状保持原样。
themis_context_recover_transaction() {
  local transaction_id=$1
  local transaction_dir
  local manifest
  local owner_workspace
  local target_relative
  local target
  local had_target
  local target_kind
  case "${transaction_id}" in CTXTX-[0-9a-f][0-9a-f]*) ;; *) return 1 ;; esac
  transaction_dir="${THEMIS_CONTEXT_WORKSPACE}/state/transactions/context/${transaction_id}"
  manifest="${transaction_dir}/transaction.yaml"
  if [ ! -f "${manifest}" ] || [ -L "${transaction_dir}" ]; then
    return 1
  fi
  owner_workspace=$("${THEMIS_CONTEXT_YQ}" eval -r '.workspace_identity_digest // ""' "${manifest}" 2>/dev/null || true)
  target_relative=$("${THEMIS_CONTEXT_YQ}" eval -r '.target // ""' "${manifest}" 2>/dev/null || true)
  had_target=$("${THEMIS_CONTEXT_YQ}" eval -r '.had_target // ""' "${manifest}" 2>/dev/null || true)
  target_kind=$("${THEMIS_CONTEXT_YQ}" eval -r '.target_kind // "file"' "${manifest}" 2>/dev/null || true)
  if [ "${owner_workspace}" != "${THEMIS_CONTEXT_WORKSPACE_DIGEST}" ]; then
    return 1
  fi
  target=$(themis_context_resolve_relative_path "${target_relative}" "${THEMIS_CONTEXT_WORKSPACE}") || return 1
  case "${target_kind}:${had_target}" in
    file:true)
      [ -f "${transaction_dir}/backup/value" ] || return 1
      cp -p "${transaction_dir}/backup/value" "${target}" || return 1
      ;;
    file:false) rm -f "${target}" ;;
    directory:true)
      rm -rf "${target}"
      mkdir "${target}" || return 1
      cp -Rp "${transaction_dir}/backup/." "${target}/" || return 1
      ;;
    directory:false) rm -rf "${target}" ;;
    *) return 1 ;;
  esac
  rm -rf "${transaction_dir}"
  return 0
}

# 统一清理临时目录、活动事务和当前进程锁。
themis_context_cleanup() {
  if [ "${THEMIS_CONTEXT_TRANSACTION_ACTIVE}" -eq 1 ]; then
    if ! themis_context_rollback_transaction; then
      printf '%s\n' 'Themis Context failed to restore an active transaction; recovery data was retained.' >&2
    fi
  fi
  themis_context_release_lock
  if [ -n "${THEMIS_CONTEXT_TMP_ROOT}" ] && [ -d "${THEMIS_CONTEXT_TMP_ROOT}" ]; then
    rm -rf "${THEMIS_CONTEXT_TMP_ROOT}"
  fi
}
