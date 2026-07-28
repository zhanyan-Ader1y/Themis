#!/usr/bin/env bash
#
# Themis Context Navigation 确定性执行器。
# 用途：从 Catalog/L3 metadata 生成、发布 L1/L2 投影，并重建可删除索引。
# 边界：只复制受治理 metadata；不生成新事实、不扫描未注册 L3、不替换正式 Context 目录。
#
set -uo pipefail

THEMIS_CONTEXT_SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source-path=SCRIPTDIR
# shellcheck source=_themis-context-common.sh
. "${THEMIS_CONTEXT_SCRIPT_DIR}/_themis-context-common.sh"

THEMIS_CONTEXT_ACTION=
THEMIS_CONTEXT_CANDIDATE_PATH=
THEMIS_CONTEXT_EXPECTED_DIGEST=
THEMIS_CONTEXT_TRANSACTION_ID=
THEMIS_CONTEXT_NAVIGATION_DATA=
THEMIS_CONTEXT_CATEGORIES='domain glossary decisions architecture engineering pitfalls external'

usage() {
  cat <<'EOF'
Usage:
  themis-context-navigation.sh render --workspace <root> --candidate <cache-relative-directory>
  themis-context-navigation.sh publish --workspace <root> --candidate <cache-relative-directory> --expected-catalog-digest <digest>
  themis-context-navigation.sh status --workspace <root>
  themis-context-navigation.sh rebuild-index --workspace <root>
  themis-context-navigation.sh recover --workspace <root> --transaction <id>
EOF
}

parse_arguments() {
  THEMIS_CONTEXT_ACTION=${1-}
  case "${THEMIS_CONTEXT_ACTION}" in render|publish|status|rebuild-index|recover) ;; *) return 1 ;; esac
  THEMIS_CONTEXT_COMMAND="navigation.${THEMIS_CONTEXT_ACTION}"
  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --workspace|--candidate|--expected-catalog-digest|--transaction)
        [ "$#" -ge 2 ] && [ -n "$2" ] || return 1
        case "$1" in
          --workspace) THEMIS_CONTEXT_WORKSPACE_INPUT=$2 ;;
          --candidate) THEMIS_CONTEXT_CANDIDATE_PATH=$2 ;;
          --expected-catalog-digest) THEMIS_CONTEXT_EXPECTED_DIGEST=$2 ;;
          --transaction) THEMIS_CONTEXT_TRANSACTION_ID=$2 ;;
        esac
        shift
        ;;
      --help|-h) usage; exit 0 ;;
      *) return 1 ;;
    esac
    shift
  done
  [ -n "${THEMIS_CONTEXT_WORKSPACE_INPUT}" ] || return 1
  case "${THEMIS_CONTEXT_ACTION}" in
    render) [ -n "${THEMIS_CONTEXT_CANDIDATE_PATH}" ] ;;
    publish) [ -n "${THEMIS_CONTEXT_CANDIDATE_PATH}" ] && themis_context_digest_valid "${THEMIS_CONTEXT_EXPECTED_DIGEST}" ;;
    status|rebuild-index) true ;;
    recover) themis_context_hash_id_valid "${THEMIS_CONTEXT_TRANSACTION_ID}" CTXTX- ;;
  esac
}

resolve_candidate() {
  case "${THEMIS_CONTEXT_CANDIDATE_PATH}" in cache/context-index/*) ;; *) return 1 ;; esac
  themis_context_resolve_relative_path "${THEMIS_CONTEXT_CANDIDATE_PATH}" "${THEMIS_CONTEXT_WORKSPACE}"
}

projection_digest() {
  local metadata=$1
  local body=$2
  {
    "${THEMIS_CONTEXT_YQ}" -o=json -I=0 'del(.projection_digest, .generated_at) | sort_keys(..)' "${metadata}" 2>/dev/null || return 1
    cat "${body}"
  } | themis_context_sha256_stdin
}

write_projection() {
  local output=$1
  local level=$2
  local category=$3
  local source_items=$4
  local body=$5
  local metadata="${THEMIS_CONTEXT_TMP_ROOT}/projection-$$.yaml"
  local normalized_body="${THEMIS_CONTEXT_TMP_ROOT}/projection-body-$$.md"
  local digest now generated_at
  awk '
    { sub(/\r$/, ""); lines[++count]=$0 }
    END {
      while (count > 0 && lines[count] == "") count--
      for (i=1; i<=count; i++) print lines[i]
      if (count == 0) print ""
    }
  ' "${body}" >"${normalized_body}" || return 1
  now=$(themis_context_now)
  generated_at=${now}
  if [ "$("${THEMIS_CONTEXT_YQ}" eval -r '.binding' "${THEMIS_CONTEXT_CATALOG}")" = unbound ] &&
     [ "$("${THEMIS_CONTEXT_YQ}" eval -r '.items | length' "${THEMIS_CONTEXT_CATALOG}")" -eq 0 ]; then
    generated_at=null
  fi
  THEMIS_LEVEL=${level} THEMIS_CATEGORY=${category} THEMIS_CATALOG_DIGEST=${THEMIS_CONTEXT_CATALOG_DIGEST} \
  THEMIS_SOURCE_ITEMS=${source_items} THEMIS_NOW=${generated_at} "${THEMIS_CONTEXT_YQ}" -n '
    {"projection_schema": "themis-context-navigation", "level": strenv(THEMIS_LEVEL),
     "category": (strenv(THEMIS_CATEGORY) | select(. != "") // null),
     "catalog_digest": strenv(THEMIS_CATALOG_DIGEST), "source_items": (strenv(THEMIS_SOURCE_ITEMS) | from_json),
     "projection_digest": "sha256:0000000000000000000000000000000000000000000000000000000000000000",
     "generated_at": (strenv(THEMIS_NOW) | select(. != "null") // null)}
  ' >"${metadata}" || return 1
  digest=$(projection_digest "${metadata}" "${normalized_body}") || return 1
  THEMIS_PROJECTION_DIGEST=${digest} "${THEMIS_CONTEXT_YQ}" eval -i '.projection_digest = strenv(THEMIS_PROJECTION_DIGEST)' "${metadata}" || return 1
  {
    printf '%s\n' '---'
    cat "${metadata}"
    printf '%s\n' '---'
    cat "${normalized_body}"
  } >"${output}"
}

source_items_json() {
  local category=${1-}
  if [ -n "${category}" ]; then
    THEMIS_CATEGORY=${category} "${THEMIS_CONTEXT_YQ}" -o=json -I=0 \
      '[.items | to_entries[] | select(.value.category == strenv(THEMIS_CATEGORY)) | {"id": .key, "digest": .value.item_digest}] | sort_by(.id)' "${THEMIS_CONTEXT_CATALOG}"
  else
    "${THEMIS_CONTEXT_YQ}" -o=json -I=0 \
      '[.items | to_entries[] | {"id": .key, "digest": .value.item_digest}] | sort_by(.id)' "${THEMIS_CONTEXT_CATALOG}"
  fi
}

render_root_abstract() {
  local output=$1
  local body="${THEMIS_CONTEXT_TMP_ROOT}/root-abstract.md"
  local category count
  {
    printf '# Context Abstract\n\n'
    if [ "$("${THEMIS_CONTEXT_YQ}" eval -r '.items | length' "${THEMIS_CONTEXT_CATALOG}")" -eq 0 ]; then
      printf 'No governed Context Items are registered.\n'
    else
      for category in ${THEMIS_CONTEXT_CATEGORIES}; do
        count=$(THEMIS_CATEGORY=${category} "${THEMIS_CONTEXT_YQ}" eval -r '[.items[] | select(.category == strenv(THEMIS_CATEGORY) and .status == "active")] | length' "${THEMIS_CONTEXT_CATALOG}")
        printf -- '- %s: %s active\n' "${category}" "${count}"
      done
    fi
  } >"${body}"
  write_projection "${output}" L1 '' "$(source_items_json)" "${body}"
}

render_root_overview() {
  local output=$1
  local body="${THEMIS_CONTEXT_TMP_ROOT}/root-overview.md"
  {
    printf '# Context Overview\n\n'
    if [ "$("${THEMIS_CONTEXT_YQ}" eval -r '.items | length' "${THEMIS_CONTEXT_CATALOG}")" -eq 0 ]; then
      printf 'No governed Context Items are registered.\n'
    else
      "${THEMIS_CONTEXT_YQ}" eval -r '
        .items | to_entries | sort_by(.value.category, .value.path, .key) | .[] |
        "## " + .key + " — " + .value.title + "\n\n" +
        "- Category: " + .value.category + "\n" +
        "- Status: " + .value.status + "\n" +
        "- Scope: " + (.value.scope | join(", ")) + "\n" +
        "- Path: " + .value.path + "\n" +
        "- Digest: " + .value.item_digest + "\n\n" + .value.abstract + "\n"
      ' "${THEMIS_CONTEXT_CATALOG}"
    fi
  } >"${body}"
  write_projection "${output}" L2 '' "$(source_items_json)" "${body}"
}

render_category_overview() {
  local category=$1
  local output=$2
  local body="${THEMIS_CONTEXT_TMP_ROOT}/${category}-overview.md"
  local count
  count=$(THEMIS_CATEGORY=${category} "${THEMIS_CONTEXT_YQ}" eval -r '[.items[] | select(.category == strenv(THEMIS_CATEGORY))] | length' "${THEMIS_CONTEXT_CATALOG}")
  {
    printf '# %s Context Overview\n\n' "${category}"
    if [ "${count}" -eq 0 ]; then
      printf 'No governed Context Items are registered in this category.\n'
    else
      THEMIS_CATEGORY=${category} "${THEMIS_CONTEXT_YQ}" eval -r '
        .items | to_entries | map(select(.value.category == strenv(THEMIS_CATEGORY))) |
        sort_by(.value.path, .key) | .[] |
        "## " + .key + " — " + .value.title + "\n\n" +
        "- Status: " + .value.status + "\n" +
        "- Scope: " + (.value.scope | join(", ")) + "\n" +
        "- Path: " + .value.path + "\n" +
        "- Digest: " + .value.item_digest + "\n" +
        "- Dependencies: " + (.value.dependencies | join(", ")) + "\n" +
        "- Supersedes: " + (.value.supersedes | join(", ")) + "\n\n" + .value.overview + "\n"
      ' "${THEMIS_CONTEXT_CATALOG}"
    fi
  } >"${body}"
  write_projection "${output}" L2 "${category}" "$(source_items_json "${category}")" "${body}"
}

render_navigation_tree() {
  local target=$1
  local category
  mkdir "${target}" || return 1
  for category in ${THEMIS_CONTEXT_CATEGORIES}; do mkdir "${target}/${category}" || return 1; done
  render_root_abstract "${target}/.abstract.md" || return 1
  render_root_overview "${target}/.overview.md" || return 1
  for category in ${THEMIS_CONTEXT_CATEGORIES}; do render_category_overview "${category}" "${target}/${category}/.overview.md" || return 1; done
}

render_candidate() {
  local target staged="${THEMIS_CONTEXT_TMP_ROOT}/navigation-candidate"
  target=$(resolve_candidate) || { themis_context_add_error context_candidate_path_invalid "${THEMIS_CONTEXT_CANDIDATE_PATH}"; return 1; }
  themis_context_validate_catalog || { themis_context_add_error context_catalog_invalid context/catalog.yaml; return 1; }
  render_navigation_tree "${staged}" || return 1
  themis_context_require_clean_transactions || return $?
  themis_context_acquire_lock navigation.render || return $?
  themis_context_begin_directory_transaction navigation.render "${target}" || return 1
  if ! themis_context_commit_directory_transaction "${staged}" "${target}"; then
    themis_context_rollback_transaction || return 2
    themis_context_add_error context_transaction_failed "${THEMIS_CONTEXT_CANDIDATE_PATH}"
    return 1
  fi
}

validate_projection() {
  local file=$1
  local level=$2
  local category=$3
  local frontmatter="${THEMIS_CONTEXT_TMP_ROOT}/navigation-frontmatter.yaml"
  local body="${THEMIS_CONTEXT_TMP_ROOT}/navigation-body.md"
  local digest
  [ -f "${file}" ] && [ ! -L "${file}" ] || return 1
  themis_context_extract_frontmatter "${file}" "${frontmatter}" || return 1
  themis_context_extract_body "${file}" "${body}" || return 1
  "${THEMIS_CONTEXT_YQ}" eval -e '
    (keys | length) == 7 and has("projection_schema") and has("level") and has("category") and
    has("catalog_digest") and has("source_items") and has("projection_digest") and has("generated_at") and
    .projection_schema == "themis-context-navigation" and (.source_items | type) == "!!seq"
  ' "${frontmatter}" >/dev/null 2>&1 || return 1
  [ "$("${THEMIS_CONTEXT_YQ}" eval -r '.level' "${frontmatter}")" = "${level}" ] || return 1
  [ "$("${THEMIS_CONTEXT_YQ}" eval -r '.category // ""' "${frontmatter}")" = "${category}" ] || return 1
  [ "$("${THEMIS_CONTEXT_YQ}" eval -r '.catalog_digest' "${frontmatter}")" = "${THEMIS_CONTEXT_CATALOG_DIGEST}" ] || return 1
  case "$("${THEMIS_CONTEXT_YQ}" eval -r '.generated_at // "null"' "${frontmatter}")" in
    null|[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z) ;;
    *) return 1 ;;
  esac
  digest=$(projection_digest "${frontmatter}" "${body}") || return 1
  [ "$("${THEMIS_CONTEXT_YQ}" eval -r '.projection_digest' "${frontmatter}")" = "${digest}" ]
}

validate_candidate() {
  local candidate=$1 category
  validate_projection "${candidate}/.abstract.md" L1 '' || return 1
  validate_projection "${candidate}/.overview.md" L2 '' || return 1
  for category in ${THEMIS_CONTEXT_CATEGORIES}; do
    validate_projection "${candidate}/${category}/.overview.md" L2 "${category}" || return 1
  done
}

projection_declared_digest() {
  local file=$1
  local frontmatter="${THEMIS_CONTEXT_TMP_ROOT}/declared-digest-$$.yaml"
  themis_context_extract_frontmatter "${file}" "${frontmatter}" || return 1
  "${THEMIS_CONTEXT_YQ}" eval -r '.projection_digest // ""' "${frontmatter}"
}

validate_candidate_against_catalog() {
  local candidate=$1
  local expected="${THEMIS_CONTEXT_TMP_ROOT}/navigation-expected"
  local category relative
  render_navigation_tree "${expected}" || return 1
  for relative in .abstract.md .overview.md; do
    [ "$(projection_declared_digest "${candidate}/${relative}")" = "$(projection_declared_digest "${expected}/${relative}")" ] || return 1
  done
  for category in ${THEMIS_CONTEXT_CATEGORIES}; do
    relative="${category}/.overview.md"
    [ "$(projection_declared_digest "${candidate}/${relative}")" = "$(projection_declared_digest "${expected}/${relative}")" ] || return 1
  done
}

navigation_target_list() {
  local category
  printf '%s\n' 'context/.abstract.md' 'context/.overview.md'
  for category in ${THEMIS_CONTEXT_CATEGORIES}; do printf 'context/%s/.overview.md\n' "${category}"; done
}

begin_publish_transaction() {
  local candidate=$1
  local root="${THEMIS_CONTEXT_WORKSPACE}/state/transactions/context"
  local identity relative target backup staged
  identity=$(printf '%s\n' "navigation.publish|${THEMIS_CONTEXT_CATALOG_DIGEST}|${THEMIS_CONTEXT_LOCK_TOKEN}|$(themis_context_now)" | themis_context_sha256_stdin)
  THEMIS_CONTEXT_TRANSACTION_ID="CTXTX-${identity#sha256:}"
  THEMIS_CONTEXT_TRANSACTION_DIR="${root}/${THEMIS_CONTEXT_TRANSACTION_ID}"
  THEMIS_CONTEXT_TRANSACTION_MANIFEST="${THEMIS_CONTEXT_TRANSACTION_DIR}/transaction.yaml"
  mkdir "${THEMIS_CONTEXT_TRANSACTION_DIR}" "${THEMIS_CONTEXT_TRANSACTION_DIR}/backup" "${THEMIS_CONTEXT_TRANSACTION_DIR}/stage" || return 1
  while IFS= read -r relative; do
    target="${THEMIS_CONTEXT_WORKSPACE}/${relative}"
    backup="${THEMIS_CONTEXT_TRANSACTION_DIR}/backup/${relative}"
    staged="${THEMIS_CONTEXT_TRANSACTION_DIR}/stage/${relative}"
    mkdir -p "$(dirname -- "${backup}")" "$(dirname -- "${staged}")" || return 1
    [ -f "${target}" ] && cp -p "${target}" "${backup}"
    cp -p "${candidate}/${relative#context/}" "${staged}" || return 1
  done <<EOF
$(navigation_target_list)
EOF
  THEMIS_TX_ID=${THEMIS_CONTEXT_TRANSACTION_ID} THEMIS_WORKSPACE_DIGEST=${THEMIS_CONTEXT_WORKSPACE_DIGEST} \
  THEMIS_CATALOG_DIGEST=${THEMIS_CONTEXT_CATALOG_DIGEST} "${THEMIS_CONTEXT_YQ}" -n '
    {"transaction_schema": "themis-context-navigation-transaction", "id": strenv(THEMIS_TX_ID),
     "operation": "navigation.publish", "workspace_identity_digest": strenv(THEMIS_WORKSPACE_DIGEST),
     "catalog_digest": strenv(THEMIS_CATALOG_DIGEST), "phase": "prepared"}
  ' >"${THEMIS_CONTEXT_TRANSACTION_MANIFEST}" || return 1
  THEMIS_CONTEXT_TRANSACTION_ACTIVE=1
}

restore_publish_transaction() {
  local dir=$1 relative target backup
  while IFS= read -r relative; do
    target="${THEMIS_CONTEXT_WORKSPACE}/${relative}"
    backup="${dir}/backup/${relative}"
    if [ -f "${backup}" ]; then cp -p "${backup}" "${target}" || return 1; else rm -f "${target}"; fi
    rm -f "$(dirname -- "${target}")/.$(basename -- "${target}").context-new"
  done <<EOF
$(navigation_target_list)
EOF
}

commit_publish_transaction() {
  local relative target staged pending
  THEMIS_PHASE=staged "${THEMIS_CONTEXT_YQ}" eval -i '.phase = strenv(THEMIS_PHASE)' "${THEMIS_CONTEXT_TRANSACTION_MANIFEST}" || return 1
  while IFS= read -r relative; do
    target="${THEMIS_CONTEXT_WORKSPACE}/${relative}"
    staged="${THEMIS_CONTEXT_TRANSACTION_DIR}/stage/${relative}"
    pending="$(dirname -- "${target}")/.$(basename -- "${target}").context-new"
    cp -p "${staged}" "${pending}" || return 1
    mv "${pending}" "${target}" || return 1
  done <<EOF
$(navigation_target_list)
EOF
  THEMIS_PHASE=replaced "${THEMIS_CONTEXT_YQ}" eval -i '.phase = strenv(THEMIS_PHASE)' "${THEMIS_CONTEXT_TRANSACTION_MANIFEST}" || return 1
  rm -rf "${THEMIS_CONTEXT_TRANSACTION_DIR}"
  THEMIS_CONTEXT_TRANSACTION_ACTIVE=0
}

publish_candidate() {
  local candidate
  candidate=$(resolve_candidate) || { themis_context_add_error context_candidate_path_invalid "${THEMIS_CONTEXT_CANDIDATE_PATH}"; return 1; }
  themis_context_validate_catalog || { themis_context_add_error context_catalog_invalid context/catalog.yaml; return 1; }
  if [ "${THEMIS_CONTEXT_EXPECTED_DIGEST}" != "${THEMIS_CONTEXT_CATALOG_DIGEST}" ]; then
    themis_context_add_error catalog_digest_conflict context/catalog.yaml; return 2
  fi
  if [ ! -d "${candidate}" ] || ! validate_candidate "${candidate}" || ! validate_candidate_against_catalog "${candidate}"; then
    themis_context_add_error context_navigation_candidate_invalid "${THEMIS_CONTEXT_CANDIDATE_PATH}"
    return 1
  fi
  themis_context_require_clean_transactions || return $?
  themis_context_acquire_lock navigation.publish || return $?
  begin_publish_transaction "${candidate}" || return 1
  if ! commit_publish_transaction; then
    if restore_publish_transaction "${THEMIS_CONTEXT_TRANSACTION_DIR}"; then
      rm -rf "${THEMIS_CONTEXT_TRANSACTION_DIR}"
      THEMIS_CONTEXT_TRANSACTION_ACTIVE=0
      themis_context_add_error context_transaction_failed "${THEMIS_CONTEXT_CANDIDATE_PATH}"
      return 1
    fi
    themis_context_add_error context_restore_failed "state/transactions/context/${THEMIS_CONTEXT_TRANSACTION_ID}"
    THEMIS_CONTEXT_TRANSACTION_ACTIVE=0
    return 2
  fi
}

navigation_status() {
  local category stale=0
  themis_context_validate_catalog || { themis_context_add_error context_catalog_invalid context/catalog.yaml; return 1; }
  validate_projection "${THEMIS_CONTEXT_WORKSPACE}/context/.abstract.md" L1 '' || stale=1
  validate_projection "${THEMIS_CONTEXT_WORKSPACE}/context/.overview.md" L2 '' || stale=1
  for category in ${THEMIS_CONTEXT_CATEGORIES}; do
    validate_projection "${THEMIS_CONTEXT_WORKSPACE}/context/${category}/.overview.md" L2 "${category}" || stale=1
  done
  if [ "${stale}" -eq 1 ]; then
    themis_context_add_warning navigation_stale
    THEMIS_CONTEXT_NAVIGATION_DATA="{\"current\":false,\"catalog_digest\":\"${THEMIS_CONTEXT_CATALOG_DIGEST}\"}"
  else
    THEMIS_CONTEXT_NAVIGATION_DATA="{\"current\":true,\"catalog_digest\":\"${THEMIS_CONTEXT_CATALOG_DIGEST}\"}"
  fi
}

rebuild_index() {
  local target="${THEMIS_CONTEXT_WORKSPACE}/cache/context-index/index.yaml"
  local staged="${THEMIS_CONTEXT_TMP_ROOT}/context-index.yaml"
  themis_context_validate_catalog || { themis_context_add_error context_catalog_invalid context/catalog.yaml; return 1; }
  "${THEMIS_CONTEXT_YQ}" eval '
    {"index_schema": "themis-context-index", "catalog_digest": .catalog_digest,
     "items": [.items | to_entries[] | {"id": .key, "path": .value.path, "category": .value.category,
       "kind": .value.kind, "status": .value.status, "scope": .value.scope, "tags": .value.tags,
       "title": .value.title, "abstract": .value.abstract, "digest": .value.item_digest}]}
  ' "${THEMIS_CONTEXT_CATALOG}" >"${staged}" || return 1
  themis_context_require_clean_transactions || return $?
  themis_context_acquire_lock navigation.rebuild-index || return $?
  themis_context_begin_file_transaction navigation.rebuild-index "${target}" || return 1
  if ! themis_context_commit_file_transaction "${staged}" "${target}"; then
    themis_context_rollback_transaction || return 2
    themis_context_add_error context_transaction_failed cache/context-index/index.yaml
    return 1
  fi
}

recover_navigation() {
  local dir="${THEMIS_CONTEXT_WORKSPACE}/state/transactions/context/${THEMIS_CONTEXT_TRANSACTION_ID}"
  local manifest="${dir}/transaction.yaml"
  [ -f "${manifest}" ] || return 1
  "${THEMIS_CONTEXT_YQ}" eval -e '.transaction_schema == "themis-context-navigation-transaction" and .operation == "navigation.publish"' "${manifest}" >/dev/null 2>&1 || return 1
  [ "$("${THEMIS_CONTEXT_YQ}" eval -r '.workspace_identity_digest' "${manifest}")" = "${THEMIS_CONTEXT_WORKSPACE_DIGEST}" ] || return 1
  restore_publish_transaction "${dir}" || return 1
  rm -rf "${dir}"
}

navigation_cleanup() {
  if [ "${THEMIS_CONTEXT_TRANSACTION_ACTIVE}" -eq 1 ] && [ -n "${THEMIS_CONTEXT_TRANSACTION_DIR}" ]; then
    if restore_publish_transaction "${THEMIS_CONTEXT_TRANSACTION_DIR}"; then
      rm -rf "${THEMIS_CONTEXT_TRANSACTION_DIR}"
      THEMIS_CONTEXT_TRANSACTION_ACTIVE=0
    else
      printf '%s\n' 'Themis Context failed to restore an active navigation transaction; recovery data was retained.' >&2
    fi
  fi
  themis_context_release_lock
  if [ -n "${THEMIS_CONTEXT_TMP_ROOT}" ] && [ -d "${THEMIS_CONTEXT_TMP_ROOT}" ]; then rm -rf "${THEMIS_CONTEXT_TMP_ROOT}"; fi
}

main() {
  local result status=ok data='{}'
  if ! parse_arguments "$@"; then
    usage >&2
    themis_context_add_error invalid_arguments
    themis_context_emit invalid '{}'
    return $?
  fi
  themis_context_require_runtime || return $?
  themis_context_prepare_temp || { themis_context_add_error temporary_directory_failed; themis_context_emit unavailable '{}'; return $?; }
  trap navigation_cleanup EXIT HUP INT TERM
  themis_context_open_workspace
  case $? in 0) ;; 2) themis_context_emit unavailable '{}'; return $? ;; *) themis_context_emit invalid '{}'; return $? ;; esac
  case "${THEMIS_CONTEXT_ACTION}" in
    render) render_candidate; result=$?; [ "${result}" -eq 0 ] && data="{\"candidate\":\"$(themis_context_json_escape "${THEMIS_CONTEXT_CANDIDATE_PATH}")\",\"catalog_digest\":\"${THEMIS_CONTEXT_CATALOG_DIGEST}\"}" ;;
    publish) publish_candidate; result=$? ;;
    status) navigation_status; result=$?; [ "${result}" -eq 0 ] && data=${THEMIS_CONTEXT_NAVIGATION_DATA} ;;
    rebuild-index) rebuild_index; result=$? ;;
    recover) themis_context_acquire_lock navigation.recover && recover_navigation; result=$? ;;
  esac
  case "${result}" in 0) status=ok ;; 2) status=needs_adjudication ;; *) status=invalid ;; esac
  themis_context_emit "${status}" "${data}"
}

main "$@"
