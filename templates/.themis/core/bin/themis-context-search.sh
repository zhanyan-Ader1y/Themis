#!/usr/bin/env bash
#
# Themis Context Search 确定性执行器。
# 用途：只查询唯一 Catalog，并返回稳定、可复验的 Context 候选集合。
# 边界：不扫描未注册 L3、不写 Signal、不把排名或无命中解释为项目事实。
#
set -uo pipefail

THEMIS_CONTEXT_SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source-path=SCRIPTDIR
# shellcheck source=_themis-context-common.sh
. "${THEMIS_CONTEXT_SCRIPT_DIR}/_themis-context-common.sh"

# shellcheck disable=SC2034
THEMIS_CONTEXT_COMMAND=search.query
THEMIS_CONTEXT_FILTER_ID=
THEMIS_CONTEXT_FILTER_CATEGORY=
THEMIS_CONTEXT_FILTER_KIND=
THEMIS_CONTEXT_FILTER_SCOPE=
THEMIS_CONTEXT_FILTER_STATUS=
THEMIS_CONTEXT_FILTER_PATH=
THEMIS_CONTEXT_TERMS=
THEMIS_CONTEXT_LIMIT=100

usage() {
  printf '%s\n' 'Usage: themis-context-search.sh query --workspace <root> [--id <CTX-id>] [--category <value>] [--kind <value>] [--scope <value>] [--status <value>] [--path-prefix <path>] [--term <text> ...] [--limit <n>]'
}

parse_arguments() {
  [ "${1-}" = query ] || return 1
  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --workspace|--id|--category|--kind|--scope|--status|--path-prefix|--term|--limit)
        [ "$#" -ge 2 ] && [ -n "$2" ] || return 1
        case "$1" in
          --workspace) THEMIS_CONTEXT_WORKSPACE_INPUT=$2 ;;
          --id) THEMIS_CONTEXT_FILTER_ID=$2 ;;
          --category) THEMIS_CONTEXT_FILTER_CATEGORY=$2 ;;
          --kind) THEMIS_CONTEXT_FILTER_KIND=$2 ;;
          --scope) THEMIS_CONTEXT_FILTER_SCOPE=$2 ;;
          --status) THEMIS_CONTEXT_FILTER_STATUS=$2 ;;
          --path-prefix) THEMIS_CONTEXT_FILTER_PATH=$2 ;;
          --term)
            if [ -n "${THEMIS_CONTEXT_TERMS}" ]; then THEMIS_CONTEXT_TERMS="${THEMIS_CONTEXT_TERMS}"$'\n'; fi
            THEMIS_CONTEXT_TERMS="${THEMIS_CONTEXT_TERMS}$2"
            ;;
          --limit) THEMIS_CONTEXT_LIMIT=$2 ;;
        esac
        shift
        ;;
      --help|-h) usage; exit 0 ;;
      *) return 1 ;;
    esac
    shift
  done
  [ -n "${THEMIS_CONTEXT_WORKSPACE_INPUT}" ] || return 1
  case "${THEMIS_CONTEXT_LIMIT}" in ''|*[!0-9]*|0) return 1 ;; esac
  [ "${THEMIS_CONTEXT_LIMIT}" -le 1000 ] || return 1
  if [ -n "${THEMIS_CONTEXT_FILTER_ID}" ]; then themis_context_item_id_valid "${THEMIS_CONTEXT_FILTER_ID}" || return 1; fi
  case "${THEMIS_CONTEXT_FILTER_CATEGORY}" in ''|domain|glossary|decisions|architecture|engineering|pitfalls|external) ;; *) return 1 ;; esac
  case "${THEMIS_CONTEXT_FILTER_STATUS}" in ''|active|deprecated|superseded|archived) ;; *) return 1 ;; esac
  return 0
}

# 若导航摘要与 Catalog 不一致，只返回 warning；Catalog Search 仍保持可用。
check_navigation_currency() {
  local projection
  local frontmatter="${THEMIS_CONTEXT_TMP_ROOT}/navigation.yaml"
  for projection in context/.abstract.md context/.overview.md; do
    if [ ! -f "${THEMIS_CONTEXT_WORKSPACE}/${projection}" ] || \
       ! themis_context_extract_frontmatter "${THEMIS_CONTEXT_WORKSPACE}/${projection}" "${frontmatter}" || \
       [ "$("${THEMIS_CONTEXT_YQ}" eval -r '.catalog_digest // ""' "${frontmatter}" 2>/dev/null || true)" != "${THEMIS_CONTEXT_CATALOG_DIGEST}" ]; then
      themis_context_add_warning navigation_stale "${projection}"
    fi
  done
}

main() {
  local candidates
  local candidate_tsv
  local filtered_tsv="${THEMIS_CONTEXT_TMP_ROOT}/search-filtered.tsv"
  local count
  if ! parse_arguments "$@"; then
    usage >&2
    themis_context_add_error invalid_arguments
    themis_context_emit invalid '{}'
    return $?
  fi
  themis_context_require_runtime || return $?
  themis_context_prepare_temp || { themis_context_add_error temporary_directory_failed; themis_context_emit unavailable '{}'; return $?; }
  trap themis_context_cleanup EXIT HUP INT TERM
  themis_context_open_workspace
  case $? in 0) ;; 2) themis_context_emit unavailable '{}'; return $? ;; *) themis_context_emit invalid '{}'; return $? ;; esac
  if ! themis_context_validate_catalog; then
    themis_context_add_error context_catalog_invalid context/catalog.yaml
    themis_context_emit invalid '{}'
    return $?
  fi
  check_navigation_currency
  # 一次 yq 完成结构过滤，再由单个 awk 完成 ASCII term 匹配，避免逐 Item 启动进程。
  candidate_tsv=$(THEMIS_FILTER_ID=${THEMIS_CONTEXT_FILTER_ID} \
    THEMIS_FILTER_CATEGORY=${THEMIS_CONTEXT_FILTER_CATEGORY} \
    THEMIS_FILTER_KIND=${THEMIS_CONTEXT_FILTER_KIND} \
    THEMIS_FILTER_SCOPE=${THEMIS_CONTEXT_FILTER_SCOPE} \
    THEMIS_FILTER_STATUS=${THEMIS_CONTEXT_FILTER_STATUS} \
    THEMIS_FILTER_PATH=${THEMIS_CONTEXT_FILTER_PATH} \
    "${THEMIS_CONTEXT_YQ}" eval -r '
      .items | to_entries |
      map(select(strenv(THEMIS_FILTER_ID) == "" or .key == strenv(THEMIS_FILTER_ID))) |
      map(select(strenv(THEMIS_FILTER_CATEGORY) == "" or .value.category == strenv(THEMIS_FILTER_CATEGORY))) |
      map(select(strenv(THEMIS_FILTER_KIND) == "" or .value.kind == strenv(THEMIS_FILTER_KIND))) |
      map(select(strenv(THEMIS_FILTER_STATUS) == "" or .value.status == strenv(THEMIS_FILTER_STATUS))) |
      sort_by(.value.category, .value.path, .key) |
      .[] | [.key, .value.path, .value.title, .value.category, .value.kind, .value.authority, .value.status,
             (.value.scope | join("")), (.value.tags | join("")), .value.abstract,
             .value.overview, .value.item_digest] | @tsv
    ' "${THEMIS_CONTEXT_CATALOG}" 2>/dev/null) || {
      themis_context_add_error context_search_failed
      themis_context_emit invalid '{}'
      return $?
    }
  LC_ALL=C THEMIS_FILTER_TERMS=${THEMIS_CONTEXT_TERMS} \
  THEMIS_FILTER_SCOPE=${THEMIS_CONTEXT_FILTER_SCOPE} \
  THEMIS_FILTER_PATH=${THEMIS_CONTEXT_FILTER_PATH} \
  THEMIS_FILTER_LIMIT=${THEMIS_CONTEXT_LIMIT} awk -F '\t' '
    BEGIN {
      n=split(ENVIRON["THEMIS_FILTER_TERMS"], terms, "\n")
      scope=ENVIRON["THEMIS_FILTER_SCOPE"]
      path=ENVIRON["THEMIS_FILTER_PATH"]
      limit=ENVIRON["THEMIS_FILTER_LIMIT"] + 0
    }
    {
      if ($0 == "") next
      if (path != "" && index($2, path) != 1) next
      if (scope != "") {
        scope_match=0
        scope_count=split($8, scopes, "\037")
        for (i=1; i<=scope_count; i++) if (scopes[i] == scope) scope_match=1
        if (!scope_match) next
      }
      hay=tolower($0); match_all=1
      for (i=1; i<=n; i++) if (terms[i] != "" && index(hay, tolower(terms[i])) == 0) match_all=0
      if (match_all && emitted < limit) { print; emitted++ }
    }
  ' <<EOF >"${filtered_tsv}"
${candidate_tsv}
EOF
  if [ ! -s "${filtered_tsv}" ]; then
    candidates='[]'
  else
    candidates=$(THEMIS_FILTER_FILE=${filtered_tsv} "${THEMIS_CONTEXT_YQ}" -n -o=json -I=0 '
      [load_str(strenv(THEMIS_FILTER_FILE)) | split("\n")[] | select(. != "") | split("\t") |
        {"id": .[0], "path": .[1], "title": .[2], "category": .[3], "kind": .[4], "authority": .[5], "status": .[6],
         "scope": (.[7] | split("") | map(select(. != ""))),
         "tags": (.[8] | split("") | map(select(. != ""))), "abstract": .[9], "overview": .[10],
         "digest": .[11], "freshness": "current"}]
    ' 2>/dev/null) || {
      themis_context_add_error context_search_failed
      themis_context_emit invalid '{}'
      return $?
    }
  fi
  count=$(printf '%s' "${candidates}" | "${THEMIS_CONTEXT_YQ}" -p=json eval -r 'length' -)
  if [ "${count}" -eq 0 ]; then themis_context_add_warning missing_context_candidate; fi
  themis_context_emit ok "{\"catalog_digest\":\"${THEMIS_CONTEXT_CATALOG_DIGEST}\",\"count\":${count},\"candidates\":${candidates}}"
}

main "$@"
