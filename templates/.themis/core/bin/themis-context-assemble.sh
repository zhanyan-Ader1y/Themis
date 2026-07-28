#!/usr/bin/env bash
#
# Themis Context Assemble 确定性执行器。
# 用途：固定 Catalog 候选、校验模型选择，并生成可重建的 Context Bundle。
# 边界：不总结 L3、不接受候选外 ID、不把 Cache 提升为唯一事实来源。
#
set -uo pipefail

THEMIS_CONTEXT_SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source-path=SCRIPTDIR
# shellcheck source=_themis-context-common.sh
. "${THEMIS_CONTEXT_SCRIPT_DIR}/_themis-context-common.sh"

THEMIS_CONTEXT_ACTION=
THEMIS_CONTEXT_REQUEST_PATH=
THEMIS_CONTEXT_SELECTION_PATH=
THEMIS_CONTEXT_BUNDLE_ID=

usage() {
  cat <<'EOF'
Usage:
  themis-context-assemble.sh prepare --workspace <root> --request <relative-yaml>
  themis-context-assemble.sh select --workspace <root> --bundle <CBL-id> --selection <relative-yaml>
  themis-context-assemble.sh finalize --workspace <root> --bundle <CBL-id> [--project-root <root>]
  themis-context-assemble.sh status --workspace <root> --bundle <CBL-id>
  themis-context-assemble.sh recover --workspace <root> --transaction <id>
EOF
}

parse_arguments() {
  THEMIS_CONTEXT_ACTION=${1-}
  case "${THEMIS_CONTEXT_ACTION}" in prepare|select|finalize|status|recover) ;; *) return 1 ;; esac
  THEMIS_CONTEXT_COMMAND="assemble.${THEMIS_CONTEXT_ACTION}"
  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --workspace|--project-root|--request|--selection|--bundle|--transaction)
        [ "$#" -ge 2 ] && [ -n "$2" ] || return 1
        case "$1" in
          --workspace) THEMIS_CONTEXT_WORKSPACE_INPUT=$2 ;;
          --project-root) THEMIS_CONTEXT_PROJECT_ROOT=$2 ;;
          --request) THEMIS_CONTEXT_REQUEST_PATH=$2 ;;
          --selection) THEMIS_CONTEXT_SELECTION_PATH=$2 ;;
          --bundle) THEMIS_CONTEXT_BUNDLE_ID=$2 ;;
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
    prepare) [ -n "${THEMIS_CONTEXT_REQUEST_PATH}" ] ;;
    select) themis_context_hash_id_valid "${THEMIS_CONTEXT_BUNDLE_ID}" CBL- && [ -n "${THEMIS_CONTEXT_SELECTION_PATH}" ] ;;
    finalize|status) themis_context_hash_id_valid "${THEMIS_CONTEXT_BUNDLE_ID}" CBL- ;;
    recover) themis_context_hash_id_valid "${THEMIS_CONTEXT_TRANSACTION_ID}" CTXTX- ;;
  esac
}

bundle_directory() {
  printf '%s/cache/resolved-context/%s\n' "${THEMIS_CONTEXT_WORKSPACE}" "${THEMIS_CONTEXT_BUNDLE_ID}"
}

validate_request() {
  local request=$1
  "${THEMIS_CONTEXT_YQ}" eval -e '
    (keys | length) == 7 and has("intent") and has("spec_ref") and has("task_ref") and
    has("scope") and has("filters") and has("token_budget") and has("content_budget_bytes") and
    (.intent | type) == "!!str" and .intent != "" and
    ((.spec_ref == null) or ((.spec_ref | type) == "!!str")) and
    ((.task_ref == null) or ((.task_ref | type) == "!!str")) and
    (.scope | type) == "!!seq" and (.filters | type) == "!!map" and
    (.token_budget | type) == "!!int" and .token_budget > 0 and
    (.content_budget_bytes | type) == "!!int" and .content_budget_bytes > 0 and
    ([.filters | keys[] | select(. != "id" and . != "category" and . != "kind" and . != "scope" and . != "status" and . != "path_prefix" and . != "terms")] | length) == 0 and
    ((.filters.terms // []) | type) == "!!seq"
  ' "${request}" >/dev/null 2>&1
}

catalog_candidates_json() {
  local request=$1
  local candidates_tsv="${THEMIS_CONTEXT_TMP_ROOT}/bundle-candidates.tsv"
  local id category kind scope status path terms filter_values old_ifs
  filter_values=$("${THEMIS_CONTEXT_YQ}" eval -r '
    [.filters.id // "", .filters.category // "", .filters.kind // "", .filters.scope // "",
     .filters.status // "", .filters.path_prefix // "", ((.filters.terms // []) | join(""))] | join("")
  ' "${request}") || return 1
  old_ifs=${IFS}
  IFS=$'\037'
  read -r id category kind scope status path terms <<EOF
${filter_values}
EOF
  IFS=${old_ifs}
  THEMIS_FILTER_ID=${id} THEMIS_FILTER_CATEGORY=${category} THEMIS_FILTER_KIND=${kind} THEMIS_FILTER_STATUS=${status} \
    "${THEMIS_CONTEXT_YQ}" eval -r '
      .items | to_entries |
      map(select(strenv(THEMIS_FILTER_ID) == "" or .key == strenv(THEMIS_FILTER_ID))) |
      map(select(strenv(THEMIS_FILTER_CATEGORY) == "" or .value.category == strenv(THEMIS_FILTER_CATEGORY))) |
      map(select(strenv(THEMIS_FILTER_KIND) == "" or .value.kind == strenv(THEMIS_FILTER_KIND))) |
      map(select(strenv(THEMIS_FILTER_STATUS) == "" or .value.status == strenv(THEMIS_FILTER_STATUS))) |
      sort_by(.value.category, .value.path, .key) |
      .[] | [.key, .value.path, .value.item_digest, (.value.scope | join("")),
             .value.title, .value.category, .value.kind, .value.authority, .value.status,
             (.value.tags | join("")), .value.abstract, .value.overview] | @tsv
    ' "${THEMIS_CONTEXT_CATALOG}" 2>/dev/null |
    THEMIS_FILTER_SCOPE=${scope} THEMIS_FILTER_PATH=${path} THEMIS_FILTER_TERMS=${terms} awk -F '\t' '
      BEGIN { n=split(ENVIRON["THEMIS_FILTER_TERMS"], terms, "\036"); scope=ENVIRON["THEMIS_FILTER_SCOPE"]; path=ENVIRON["THEMIS_FILTER_PATH"] }
      {
        if ($0 == "") next
        if (path != "" && index($2, path) != 1) next
        if (scope != "") {
          found=0; count=split($4, scopes, "\037")
          for (i=1; i<=count; i++) if (scopes[i] == scope) found=1
          if (!found) next
        }
        hay=tolower($0); matched=1
        for (i=1; i<=n; i++) if (terms[i] != "" && index(hay, tolower(terms[i])) == 0) matched=0
        if (matched) print
      }
    ' >"${candidates_tsv}" || return 1
  if [ ! -s "${candidates_tsv}" ]; then
    printf '[]\n'
    return 0
  fi
  THEMIS_FILTER_FILE=${candidates_tsv} "${THEMIS_CONTEXT_YQ}" -n -o=json -I=0 '
    [load_str(strenv(THEMIS_FILTER_FILE)) | split("\n")[] | select(. != "") | split("\t") |
      {"id": .[0], "path": .[1], "digest": .[2], "freshness": "current"}]
  '
}

prepare_bundle() {
  local request
  local candidates
  local revision
  local identity
  local staged_dir="${THEMIS_CONTEXT_TMP_ROOT}/bundle"
  local manifest="${staged_dir}/manifest.yaml"
  local target
  request=$(themis_context_resolve_relative_path "${THEMIS_CONTEXT_REQUEST_PATH}" "${THEMIS_CONTEXT_WORKSPACE}") || {
    themis_context_add_error context_request_path_invalid "${THEMIS_CONTEXT_REQUEST_PATH}"
    return 1
  }
  if [ ! -f "${request}" ] || [ -L "${request}" ] || ! validate_request "${request}"; then
    themis_context_add_error context_request_invalid "${THEMIS_CONTEXT_REQUEST_PATH}"
    return 1
  fi
  themis_context_validate_catalog || { themis_context_add_error context_catalog_invalid context/catalog.yaml; return 1; }
  candidates=$(catalog_candidates_json "${request}") || { themis_context_add_error context_search_failed; return 1; }
  revision=$("${THEMIS_CONTEXT_YQ}" -o=json -I=0 '.revision' "${THEMIS_CONTEXT_CATALOG}") || return 1
  identity=$(
    {
      "${THEMIS_CONTEXT_YQ}" -o=json -I=0 'sort_keys(..)' "${request}" 2>/dev/null || return 1
      printf '%s\n%s\n%s\n' "${THEMIS_CONTEXT_CATALOG_DIGEST}" "${revision}" "${candidates}"
    } | themis_context_sha256_stdin
  ) || return 1
  THEMIS_CONTEXT_BUNDLE_ID="CBL-${identity#sha256:}"
  target=$(bundle_directory)
  mkdir "${staged_dir}" || return 1
  THEMIS_BUNDLE_ID=${THEMIS_CONTEXT_BUNDLE_ID} THEMIS_REQUEST_FILE=${request} \
  THEMIS_CATALOG_DIGEST=${THEMIS_CONTEXT_CATALOG_DIGEST} THEMIS_REVISION=${revision} THEMIS_CANDIDATES=${candidates} \
  "${THEMIS_CONTEXT_YQ}" -n '
    {
      "bundle_schema": "themis-context-bundle",
      "id": strenv(THEMIS_BUNDLE_ID),
      "request": {
        "intent": load(strenv(THEMIS_REQUEST_FILE)).intent,
        "spec_ref": load(strenv(THEMIS_REQUEST_FILE)).spec_ref,
        "task_ref": load(strenv(THEMIS_REQUEST_FILE)).task_ref,
        "scope": load(strenv(THEMIS_REQUEST_FILE)).scope,
        "filters": load(strenv(THEMIS_REQUEST_FILE)).filters
      },
      "catalog_digest": strenv(THEMIS_CATALOG_DIGEST),
      "revision": (strenv(THEMIS_REVISION) | from_json),
      "candidates": (strenv(THEMIS_CANDIDATES) | from_json),
      "selected": [], "excluded": [], "code_refs": [], "signal_refs": [],
      "token_budget": load(strenv(THEMIS_REQUEST_FILE)).token_budget,
      "content_budget_bytes": load(strenv(THEMIS_REQUEST_FILE)).content_budget_bytes,
      "content_bytes": 0, "status": "partial"
    }
  ' >"${manifest}" || return 1
  themis_context_validate_bundle_manifest "${manifest}" || return 1
  themis_context_require_clean_transactions || return $?
  themis_context_acquire_lock assemble.prepare || return $?
  themis_context_begin_directory_transaction assemble.prepare "${target}" || return 1
  if ! themis_context_commit_directory_transaction "${staged_dir}" "${target}"; then
    themis_context_rollback_transaction || return 2
    themis_context_add_error context_transaction_failed "cache/resolved-context/${THEMIS_CONTEXT_BUNDLE_ID}"
    return 1
  fi
  return 0
}

validate_selection() {
  local selection=$1
  "${THEMIS_CONTEXT_YQ}" eval -e '
    (keys | length) == 2 and has("selected") and has("excluded") and
    (.selected | type) == "!!seq" and (.excluded | type) == "!!seq" and
    ((.selected + .excluded) | map(select((type) != "!!map" or (keys | length) != 2 or
      (has("id") | not) or (has("reason") | not) or (.id | type) != "!!str" or (.reason | type) != "!!str")) | length) == 0 and
    (((.selected + .excluded) | map(.id) | length) == ((.selected + .excluded) | map(.id) | unique | length))
  ' "${selection}" >/dev/null 2>&1
}

selection_refs_json() {
  local selection=$1
  local field=$2
  local manifest=$3
  local refs
  local expected_count
  local actual_count
  # shellcheck disable=SC2016
  refs=$(THEMIS_SELECTION_FILE=${selection} THEMIS_SELECTION_FIELD=${field} "${THEMIS_CONTEXT_YQ}" -o=json -I=0 '
    .candidates as $candidates |
    load(strenv(THEMIS_SELECTION_FILE))[strenv(THEMIS_SELECTION_FIELD)] as $choices |
    [$choices[] as $choice |
      $candidates[] | select(.id == $choice.id) | .reason = $choice.reason]
  ' "${manifest}" 2>/dev/null) || return 1
  expected_count=$(THEMIS_SELECTION_FIELD=${field} "${THEMIS_CONTEXT_YQ}" eval -r '.[strenv(THEMIS_SELECTION_FIELD)] | length' "${selection}") || return 1
  actual_count=$(printf '%s' "${refs}" | "${THEMIS_CONTEXT_YQ}" -p=json eval -r 'length' -) || return 1
  [ "${actual_count}" -eq "${expected_count}" ] || return 2
  printf '%s\n' "${refs}"
}

select_bundle() {
  local directory
  local manifest
  local selection
  local staged="${THEMIS_CONTEXT_TMP_ROOT}/bundle-selected.yaml"
  local selected_refs
  local excluded_refs
  directory=$(bundle_directory)
  manifest="${directory}/manifest.yaml"
  selection=$(themis_context_resolve_relative_path "${THEMIS_CONTEXT_SELECTION_PATH}" "${THEMIS_CONTEXT_WORKSPACE}") || {
    themis_context_add_error context_selection_path_invalid "${THEMIS_CONTEXT_SELECTION_PATH}"
    return 1
  }
  if [ ! -f "${manifest}" ] || ! themis_context_validate_bundle_manifest "${manifest}"; then
    themis_context_add_error context_bundle_invalid "cache/resolved-context/${THEMIS_CONTEXT_BUNDLE_ID}/manifest.yaml"
    return 1
  fi
  if [ ! -f "${selection}" ] || [ -L "${selection}" ] || ! validate_selection "${selection}"; then
    themis_context_add_error context_selection_invalid "${THEMIS_CONTEXT_SELECTION_PATH}"
    return 1
  fi
  selected_refs=$(selection_refs_json "${selection}" selected "${manifest}")
  case $? in 0) ;; 2) themis_context_add_error context_selection_out_of_bounds "${THEMIS_CONTEXT_SELECTION_PATH}"; return 1 ;; *) return 1 ;; esac
  excluded_refs=$(selection_refs_json "${selection}" excluded "${manifest}")
  case $? in 0) ;; 2) themis_context_add_error context_selection_out_of_bounds "${THEMIS_CONTEXT_SELECTION_PATH}"; return 1 ;; *) return 1 ;; esac
  cp "${manifest}" "${staged}" || return 1
  THEMIS_SELECTED_REFS=${selected_refs} THEMIS_EXCLUDED_REFS=${excluded_refs} "${THEMIS_CONTEXT_YQ}" eval -i '
    .selected = (strenv(THEMIS_SELECTED_REFS) | from_json) |
    .excluded = (strenv(THEMIS_EXCLUDED_REFS) | from_json) |
    .content_bytes = 0 | .status = "partial"
  ' "${staged}" || return 1
  themis_context_validate_bundle_manifest "${staged}" || return 1
  themis_context_require_clean_transactions || return $?
  themis_context_acquire_lock assemble.select || return $?
  themis_context_begin_file_transaction assemble.select "${manifest}" || return 1
  if ! themis_context_commit_file_transaction "${staged}" "${manifest}"; then
    themis_context_rollback_transaction || return 2
    themis_context_add_error context_transaction_failed "cache/resolved-context/${THEMIS_CONTEXT_BUNDLE_ID}/manifest.yaml"
    return 1
  fi
  return 0
}

render_context_markdown() {
  local manifest=$1
  local output=$2
  local id path item
  : >"${output}"
  while IFS=$'\t' read -r id path; do
    [ -n "${id}" ] || continue
    item=$(themis_context_resolve_relative_path "context/${path}" "${THEMIS_CONTEXT_WORKSPACE}") || return 1
    themis_context_load_item "${item}" || return 1
    [ "${THEMIS_CONTEXT_ITEM_ID}" = "${id}" ] || return 1
    {
      printf '## %s — %s\n\n' "${id}" "${THEMIS_CONTEXT_ITEM_TITLE}"
      cat "${THEMIS_CONTEXT_ITEM_BODY}"
      printf '\n'
    } >>"${output}"
  done <<EOF
$("${THEMIS_CONTEXT_YQ}" eval -r '.selected[] | [.id, .path] | @tsv' "${manifest}")
EOF
}

relevant_open_signals_json() {
  local manifest=$1
  local output=$2
  local root="${THEMIS_CONTEXT_WORKSPACE}/state/context-signals"
  local scopes="${THEMIS_CONTEXT_TMP_ROOT}/selected-scopes.txt"
  local rows="${THEMIS_CONTEXT_TMP_ROOT}/relevant-signals.jsonl"
  local id signal signal_id status scope relevant selected_scope
  : >"${scopes}"
  : >"${rows}"
  while IFS= read -r id; do
    [ -n "${id}" ] || continue
    THEMIS_CONTEXT_ID=${id} "${THEMIS_CONTEXT_YQ}" eval -r '.items[strenv(THEMIS_CONTEXT_ID)].scope[]?' "${THEMIS_CONTEXT_CATALOG}" >>"${scopes}" || return 1
  done <<EOF
$("${THEMIS_CONTEXT_YQ}" eval -r '.selected[].id' "${manifest}")
EOF
  set -- "${root}"/*.yaml
  if [ ! -e "$1" ]; then printf '[]\n' >"${output}"; return 0; fi
  for signal in "$@"; do
    if ! themis_context_validate_signal "${signal}"; then
      themis_context_add_error context_signal_invalid "state/context-signals/$(basename -- "${signal}")"
      return 1
    fi
    status=$("${THEMIS_CONTEXT_YQ}" eval -r '.status' "${signal}") || return 1
    [ "${status}" = open ] || continue
    signal_id=$("${THEMIS_CONTEXT_YQ}" eval -r '.id' "${signal}") || return 1
    relevant=0
    if [ "$("${THEMIS_CONTEXT_YQ}" eval -r '.scope | length' "${signal}")" -eq 0 ]; then
      relevant=1
    else
      while IFS= read -r scope; do
        [ -n "${scope}" ] || continue
        while IFS= read -r selected_scope; do
          if [ "${scope}" = "${selected_scope}" ]; then relevant=1; break; fi
        done <"${scopes}"
        [ "${relevant}" -eq 1 ] && break
      done <<EOF
$("${THEMIS_CONTEXT_YQ}" eval -r '.scope[]' "${signal}")
EOF
    fi
    if [ "${relevant}" -eq 1 ]; then
      THEMIS_SIGNAL_ID=${signal_id} "${THEMIS_CONTEXT_YQ}" -n -o=json -I=0 'strenv(THEMIS_SIGNAL_ID)' >>"${rows}" || return 1
    fi
  done
  if [ ! -s "${rows}" ]; then printf '[]\n' >"${output}"; return 0; fi
  THEMIS_SIGNAL_ROWS=${rows} "${THEMIS_CONTEXT_YQ}" -n -o=json -I=0 \
    '[load_str(strenv(THEMIS_SIGNAL_ROWS)) | split("\n")[] | select(. != "") | from_json] | unique | sort' >"${output}"
}

finalize_bundle() {
  local directory
  local manifest
  local staged_dir="${THEMIS_CONTEXT_TMP_ROOT}/bundle-final"
  local staged_manifest="${staged_dir}/manifest.yaml"
  local context_md="${staged_dir}/context.md"
  local current_item_digest id digest
  local signal_refs_file="${THEMIS_CONTEXT_TMP_ROOT}/relevant-signals.json"
  local content_bytes budget revision status=complete signal_refs
  directory=$(bundle_directory)
  manifest="${directory}/manifest.yaml"
  if [ ! -f "${manifest}" ] || ! themis_context_validate_bundle_manifest "${manifest}"; then
    themis_context_add_error context_bundle_invalid "cache/resolved-context/${THEMIS_CONTEXT_BUNDLE_ID}/manifest.yaml"
    return 1
  fi
  themis_context_validate_catalog || { themis_context_add_error context_catalog_invalid context/catalog.yaml; return 1; }
  if [ "$("${THEMIS_CONTEXT_YQ}" eval -r '.catalog_digest' "${manifest}")" != "${THEMIS_CONTEXT_CATALOG_DIGEST}" ]; then
    themis_context_add_error context_bundle_catalog_stale "cache/resolved-context/${THEMIS_CONTEXT_BUNDLE_ID}/manifest.yaml"
    return 2
  fi
  if [ "$("${THEMIS_CONTEXT_YQ}" eval -r '.selected | length' "${manifest}")" -eq 0 ]; then
    themis_context_add_error context_selection_missing
    return 1
  fi
  while IFS=$'\t' read -r id _item_path digest; do
    [ -n "${id}" ] || continue
    current_item_digest=$(THEMIS_CONTEXT_ID=${id} "${THEMIS_CONTEXT_YQ}" eval -r '.items[strenv(THEMIS_CONTEXT_ID)].item_digest // ""' "${THEMIS_CONTEXT_CATALOG}")
    [ "${current_item_digest}" = "${digest}" ] || { themis_context_add_error context_item_stale "${id}"; return 2; }
  done <<EOF
$("${THEMIS_CONTEXT_YQ}" eval -r '.selected[] | [.id, .path, .digest] | @tsv' "${manifest}")
EOF
  revision=$("${THEMIS_CONTEXT_YQ}" -o=json -I=0 '.revision' "${THEMIS_CONTEXT_CATALOG}") || return 1
  if [ -n "${THEMIS_CONTEXT_PROJECT_ROOT}" ]; then
    themis_context_open_project_root || return $?
    revision=$(themis_context_revision_json "${THEMIS_CONTEXT_PROJECT_ROOT}") || return 1
  fi
  case "${revision}" in *'"kind":"git"'*) ;; *) status=unavailable ;; esac
  relevant_open_signals_json "${manifest}" "${signal_refs_file}" || return $?
  signal_refs=$(cat "${signal_refs_file}")
  if [ "$(printf '%s' "${signal_refs}" | "${THEMIS_CONTEXT_YQ}" -p=json eval -r 'length' -)" -ne 0 ]; then status=conflict; fi
  mkdir "${staged_dir}" || return 1
  cp "${manifest}" "${staged_manifest}" || return 1
  render_context_markdown "${manifest}" "${context_md}" || { themis_context_add_error context_render_failed; return 1; }
  content_bytes=$(wc -c <"${context_md}" | tr -d ' ')
  budget=$("${THEMIS_CONTEXT_YQ}" eval -r '.content_budget_bytes' "${manifest}")
  if [ "${content_bytes}" -gt "${budget}" ]; then
    themis_context_add_error context_budget_exceeded
    return 1
  fi
  THEMIS_REVISION=${revision} THEMIS_CONTENT_BYTES=${content_bytes} THEMIS_STATUS=${status} THEMIS_SIGNAL_REFS=${signal_refs} \
    "${THEMIS_CONTEXT_YQ}" eval -i '
      .revision = (strenv(THEMIS_REVISION) | from_json) |
      .signal_refs = (strenv(THEMIS_SIGNAL_REFS) | from_json) |
      .content_bytes = (strenv(THEMIS_CONTENT_BYTES) | tonumber) |
      .status = strenv(THEMIS_STATUS)
    ' "${staged_manifest}" || return 1
  themis_context_validate_bundle_manifest "${staged_manifest}" || return 1
  themis_context_require_clean_transactions || return $?
  themis_context_acquire_lock assemble.finalize || return $?
  themis_context_begin_directory_transaction assemble.finalize "${directory}" || return 1
  if ! themis_context_commit_directory_transaction "${staged_dir}" "${directory}"; then
    themis_context_rollback_transaction || return 2
    themis_context_add_error context_transaction_failed "cache/resolved-context/${THEMIS_CONTEXT_BUNDLE_ID}"
    return 1
  fi
  return 0
}

bundle_status() {
  local manifest
  manifest="$(bundle_directory)/manifest.yaml"
  if [ ! -f "${manifest}" ] || ! themis_context_validate_bundle_manifest "${manifest}"; then
    themis_context_add_error context_bundle_invalid "cache/resolved-context/${THEMIS_CONTEXT_BUNDLE_ID}/manifest.yaml"
    return 1
  fi
  "${THEMIS_CONTEXT_YQ}" -o=json -I=0 '{"id": .id, "status": .status, "catalog_digest": .catalog_digest, "candidate_count": (.candidates | length), "selected_count": (.selected | length), "content_bytes": .content_bytes}' "${manifest}"
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
  trap themis_context_cleanup EXIT HUP INT TERM
  themis_context_open_workspace
  case $? in 0) ;; 2) themis_context_emit unavailable '{}'; return $? ;; *) themis_context_emit invalid '{}'; return $? ;; esac
  case "${THEMIS_CONTEXT_ACTION}" in
    prepare)
      prepare_bundle; result=$?
      [ "${result}" -eq 0 ] && data="{\"bundle_id\":\"${THEMIS_CONTEXT_BUNDLE_ID}\"}"
      ;;
    select) select_bundle; result=$?; [ "${result}" -eq 0 ] && data="{\"bundle_id\":\"${THEMIS_CONTEXT_BUNDLE_ID}\"}" ;;
    finalize) finalize_bundle; result=$?; [ "${result}" -eq 0 ] && data=$(bundle_status) ;;
    status) data=$(bundle_status); result=$? ;;
    recover) themis_context_acquire_lock assemble.recover && themis_context_recover_transaction "${THEMIS_CONTEXT_TRANSACTION_ID}"; result=$? ;;
  esac
  case "${result}" in 0) status=ok ;; 2) status=needs_adjudication ;; *) status=invalid ;; esac
  themis_context_emit "${status}" "${data}"
}

main "$@"
