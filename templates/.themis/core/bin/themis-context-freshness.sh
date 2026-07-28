#!/usr/bin/env bash
#
# Themis Context Freshness 确定性执行器。
# 用途：计算 Context 当前性、显式记录 Signal，并保存人工 disposition。
# 边界：check 只读；任何命令都不改写 L3、Catalog registry 或 Item status。
#
set -uo pipefail

THEMIS_CONTEXT_SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source-path=SCRIPTDIR
# shellcheck source=_themis-context-common.sh
. "${THEMIS_CONTEXT_SCRIPT_DIR}/_themis-context-common.sh"

THEMIS_CONTEXT_ACTION=
THEMIS_CONTEXT_ITEM_ID=
THEMIS_CONTEXT_ALL=0
THEMIS_CONTEXT_REPORT_PATH=
THEMIS_CONTEXT_SIGNAL_ID=
THEMIS_CONTEXT_SIGNAL_STATUS=
THEMIS_CONTEXT_ACTOR=
THEMIS_CONTEXT_NOTE_PATH=
THEMIS_CONTEXT_EVIDENCE=
THEMIS_CONTEXT_REPORT_FILE=
THEMIS_CONTEXT_STATUS_DATA=

usage() {
  cat <<'EOF'
Usage:
  themis-context-freshness.sh check --workspace <root> (--id <CTX-id>|--all) [--project-root <root>]
  themis-context-freshness.sh record --workspace <root> --report <relative-yaml>
  themis-context-freshness.sh resolve --workspace <root> --signal <CSG-id> --status resolved|accepted|superseded --actor <value> --note <relative-file> [--evidence <relative-path> ...]
  themis-context-freshness.sh status --workspace <root> [--signal <CSG-id>]
  themis-context-freshness.sh recover --workspace <root> --transaction <id>
EOF
}

parse_arguments() {
  THEMIS_CONTEXT_ACTION=${1-}
  case "${THEMIS_CONTEXT_ACTION}" in check|record|resolve|status|recover) ;; *) return 1 ;; esac
  THEMIS_CONTEXT_COMMAND="freshness.${THEMIS_CONTEXT_ACTION}"
  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --workspace|--project-root|--id|--report|--signal|--status|--actor|--note|--evidence|--transaction)
        [ "$#" -ge 2 ] && [ -n "$2" ] || return 1
        case "$1" in
          --workspace) THEMIS_CONTEXT_WORKSPACE_INPUT=$2 ;;
          --project-root) THEMIS_CONTEXT_PROJECT_ROOT=$2 ;;
          --id) THEMIS_CONTEXT_ITEM_ID=$2 ;;
          --report) THEMIS_CONTEXT_REPORT_PATH=$2 ;;
          --signal) THEMIS_CONTEXT_SIGNAL_ID=$2 ;;
          --status) THEMIS_CONTEXT_SIGNAL_STATUS=$2 ;;
          --actor) THEMIS_CONTEXT_ACTOR=$2 ;;
          --note) THEMIS_CONTEXT_NOTE_PATH=$2 ;;
          --evidence)
            [ -n "${THEMIS_CONTEXT_EVIDENCE}" ] && THEMIS_CONTEXT_EVIDENCE="${THEMIS_CONTEXT_EVIDENCE}"$'\n'
            THEMIS_CONTEXT_EVIDENCE="${THEMIS_CONTEXT_EVIDENCE}$2"
            ;;
          --transaction) THEMIS_CONTEXT_TRANSACTION_ID=$2 ;;
        esac
        shift
        ;;
      --all) THEMIS_CONTEXT_ALL=1 ;;
      --help|-h) usage; exit 0 ;;
      *) return 1 ;;
    esac
    shift
  done
  [ -n "${THEMIS_CONTEXT_WORKSPACE_INPUT}" ] || return 1
  case "${THEMIS_CONTEXT_ACTION}" in
    check)
      if [ "${THEMIS_CONTEXT_ALL}" -eq 1 ]; then [ -z "${THEMIS_CONTEXT_ITEM_ID}" ]; else themis_context_item_id_valid "${THEMIS_CONTEXT_ITEM_ID}"; fi
      ;;
    record) [ -n "${THEMIS_CONTEXT_REPORT_PATH}" ] ;;
    resolve)
      themis_context_hash_id_valid "${THEMIS_CONTEXT_SIGNAL_ID}" CSG- &&
      case "${THEMIS_CONTEXT_SIGNAL_STATUS}" in resolved|accepted|superseded) true ;; *) false ;; esac &&
      [ -n "${THEMIS_CONTEXT_ACTOR}" ] && [ -n "${THEMIS_CONTEXT_NOTE_PATH}" ]
      ;;
    status) [ -z "${THEMIS_CONTEXT_SIGNAL_ID}" ] || themis_context_hash_id_valid "${THEMIS_CONTEXT_SIGNAL_ID}" CSG- ;;
    recover) themis_context_hash_id_valid "${THEMIS_CONTEXT_TRANSACTION_ID}" CTXTX- ;;
  esac
}

signal_identity() {
  local kind=$1
  local scope_json=$2
  local sources_json=$3
  local revision_json=$4
  local subject=$5
  {
    printf '%s\n%s\n%s\n%s\n%s\n%s\n' "${kind}" "${subject}" "${scope_json}" "${sources_json}" "${THEMIS_CONTEXT_WORKSPACE_DIGEST}" "${revision_json}"
  } | themis_context_sha256_stdin
}

source_state_json() {
  local refs_file=$1
  local root=$2
  local output="${THEMIS_CONTEXT_TMP_ROOT}/sources.jsonl"
  local path expected resolved actual state
  : >"${output}"
  while IFS=$'\t' read -r path expected; do
    [ -n "${path}" ] || continue
    resolved=$(themis_context_resolve_relative_path "${path}" "${root}") || {
      THEMIS_SOURCE_PATH=${path} THEMIS_EXPECTED=${expected} "${THEMIS_CONTEXT_YQ}" -n -o=json -I=0 \
        '{"path": strenv(THEMIS_SOURCE_PATH), "expected_digest": strenv(THEMIS_EXPECTED), "actual_digest": null, "state": "missing"}' >>"${output}"
      continue
    }
    if [ ! -f "${resolved}" ] || [ -L "${resolved}" ]; then
      actual=null; state=missing
    else
      actual=$(themis_context_file_digest "${resolved}") || return 1
      if [ -n "${expected}" ] && [ "${actual}" != "${expected}" ]; then state=drift; else state=current; fi
    fi
    THEMIS_SOURCE_PATH=${path} THEMIS_EXPECTED=${expected} THEMIS_ACTUAL=${actual} THEMIS_SOURCE_STATE=${state} \
      "${THEMIS_CONTEXT_YQ}" -n -o=json -I=0 '
        {"path": strenv(THEMIS_SOURCE_PATH), "expected_digest": (strenv(THEMIS_EXPECTED) | select(. != "") // null),
         "actual_digest": (strenv(THEMIS_ACTUAL) | select(. != "null") // null), "state": strenv(THEMIS_SOURCE_STATE)}
      ' >>"${output}" || return 1
  done <"${refs_file}"
  if [ ! -s "${output}" ]; then printf '[]\n'; return 0; fi
  THEMIS_SOURCES_FILE=${output} "${THEMIS_CONTEXT_YQ}" -n -o=json -I=0 \
    '[load_str(strenv(THEMIS_SOURCES_FILE)) | split("\n")[] | select(. != "") | from_json]'
}

check_freshness() {
  local report="${THEMIS_CONTEXT_TMP_ROOT}/freshness-report.yaml"
  local items_json
  local refs="${THEMIS_CONTEXT_TMP_ROOT}/source-refs.tsv"
  local revision='{"kind":"unavailable","commit":null,"worktree":"unknown"}'
  local project_root="${THEMIS_CONTEXT_WORKSPACE}/../.."
  local items_filter
  local entries="${THEMIS_CONTEXT_TMP_ROOT}/freshness-entries.jsonl"
  local id path digest item live_digest sources scope item_state source_state kind signal_digest signal_id
  themis_context_validate_catalog || { themis_context_add_error context_catalog_invalid context/catalog.yaml; return 1; }
  if [ -n "${THEMIS_CONTEXT_PROJECT_ROOT}" ]; then
    themis_context_open_project_root || return $?
    project_root=${THEMIS_CONTEXT_PROJECT_ROOT}
    revision=$(themis_context_revision_json "${project_root}") || return 1
  fi
  if [ "${THEMIS_CONTEXT_ALL}" -eq 1 ]; then items_filter=''; else items_filter=${THEMIS_CONTEXT_ITEM_ID}; fi
  : >"${entries}"
  while IFS=$'\t' read -r id path digest; do
    [ -n "${id}" ] || continue
    item=$(themis_context_resolve_relative_path "context/${path}" "${THEMIS_CONTEXT_WORKSPACE}") || item=
    if [ -z "${item}" ] || [ ! -f "${item}" ]; then
      item_state=missing; live_digest=
    elif themis_context_load_item "${item}"; then
      live_digest=${THEMIS_CONTEXT_ITEM_DIGEST}
      if [ "${live_digest}" = "${digest}" ]; then item_state=current; else item_state=stale; fi
    else
      item_state=stale; live_digest=
    fi
    THEMIS_CONTEXT_ID=${id} "${THEMIS_CONTEXT_YQ}" eval -r '.items[strenv(THEMIS_CONTEXT_ID)].source_refs[]? | [.path, (.digest // "")] | @tsv' "${THEMIS_CONTEXT_CATALOG}" >"${refs}" 2>/dev/null || return 1
    sources=$(source_state_json "${refs}" "${project_root}") || return 1
    scope=$(THEMIS_CONTEXT_ID=${id} "${THEMIS_CONTEXT_YQ}" -o=json -I=0 '.items[strenv(THEMIS_CONTEXT_ID)].scope' "${THEMIS_CONTEXT_CATALOG}") || return 1
    source_state=$(printf '%s' "${sources}" | "${THEMIS_CONTEXT_YQ}" -p=json eval -r '[.[] | select(.state != "current")] | length' -)
    kind=
    if [ "${item_state}" = missing ]; then kind=missing
    elif [ "${item_state}" = stale ]; then kind=stale
    elif [ "${source_state}" -ne 0 ]; then kind=context_code_drift
    fi
    signal_id=null
    if [ -n "${kind}" ]; then
      signal_digest=$(signal_identity "${kind}" "${scope}" "${sources}" "${revision}" "${id}") || return 1
      signal_id="CSG-${signal_digest#sha256:}"
    fi
    THEMIS_ITEM_ID=${id} THEMIS_ITEM_PATH=${path} THEMIS_EXPECTED_DIGEST=${digest} THEMIS_LIVE_DIGEST=${live_digest} \
    THEMIS_ITEM_STATE=${item_state} THEMIS_SOURCES=${sources} THEMIS_KIND=${kind} THEMIS_SIGNAL_ID=${signal_id} \
      "${THEMIS_CONTEXT_YQ}" -n -o=json -I=0 '
        {"id": strenv(THEMIS_ITEM_ID), "path": strenv(THEMIS_ITEM_PATH), "expected_digest": strenv(THEMIS_EXPECTED_DIGEST),
         "actual_digest": (strenv(THEMIS_LIVE_DIGEST) | select(. != "") // null), "state": strenv(THEMIS_ITEM_STATE),
         "sources": (strenv(THEMIS_SOURCES) | from_json), "signal_kind": (strenv(THEMIS_KIND) | select(. != "") // null),
         "signal_id": (strenv(THEMIS_SIGNAL_ID) | select(. != "null") // null)}
      ' >>"${entries}" || return 1
  done <<EOF
$(THEMIS_FILTER_ID=${items_filter} "${THEMIS_CONTEXT_YQ}" eval -r '.items | to_entries[] | select(strenv(THEMIS_FILTER_ID) == "" or .key == strenv(THEMIS_FILTER_ID)) | [.key, .value.path, .value.item_digest] | @tsv' "${THEMIS_CONTEXT_CATALOG}")
EOF
  if [ -n "${THEMIS_CONTEXT_ITEM_ID}" ] && [ ! -s "${entries}" ]; then
    themis_context_add_error context_id_missing "${THEMIS_CONTEXT_ITEM_ID}"
    return 1
  fi
  if [ -s "${entries}" ]; then
    items_json=$(THEMIS_ENTRIES=${entries} "${THEMIS_CONTEXT_YQ}" -n -o=json -I=0 \
      '[load_str(strenv(THEMIS_ENTRIES)) | split("\n")[] | select(. != "") | from_json]') || return 1
  else
    items_json='[]'
  fi
  THEMIS_ITEMS=${items_json} THEMIS_CATALOG_DIGEST=${THEMIS_CONTEXT_CATALOG_DIGEST} THEMIS_REVISION=${revision} \
  THEMIS_WORKSPACE_DIGEST=${THEMIS_CONTEXT_WORKSPACE_DIGEST} "${THEMIS_CONTEXT_YQ}" -n '
    {"report_schema": "themis-context-freshness-report", "catalog_digest": strenv(THEMIS_CATALOG_DIGEST),
     "workspace_identity_digest": strenv(THEMIS_WORKSPACE_DIGEST), "revision": (strenv(THEMIS_REVISION) | from_json),
     "items": (strenv(THEMIS_ITEMS) | from_json)}
  ' >"${report}" || return 1
  THEMIS_CONTEXT_REPORT_FILE=${report}
  return 0
}

validate_report() {
  local report=$1
  "${THEMIS_CONTEXT_YQ}" eval -e '
    (keys | length) == 5 and has("report_schema") and has("catalog_digest") and
    has("workspace_identity_digest") and has("revision") and has("items") and
    .report_schema == "themis-context-freshness-report" and (.items | type) == "!!seq"
  ' "${report}" >/dev/null 2>&1
}

record_signal_from_item() {
  local item_json=$1
  local report=$2
  local kind id scope sources revision now target staged first
  kind=$(printf '%s' "${item_json}" | "${THEMIS_CONTEXT_YQ}" -p=json eval -r '.signal_kind // ""' -)
  [ -n "${kind}" ] || return 0
  id=$(printf '%s' "${item_json}" | "${THEMIS_CONTEXT_YQ}" -p=json eval -r '.signal_id' -)
  sources=$(printf '%s' "${item_json}" | "${THEMIS_CONTEXT_YQ}" -p=json -o=json -I=0 '.sources' -)
  scope=$(THEMIS_CONTEXT_ID=$(printf '%s' "${item_json}" | "${THEMIS_CONTEXT_YQ}" -p=json eval -r '.id' -) \
    "${THEMIS_CONTEXT_YQ}" -o=json -I=0 '.items[strenv(THEMIS_CONTEXT_ID)].scope' "${THEMIS_CONTEXT_CATALOG}") || return 1
  revision=$("${THEMIS_CONTEXT_YQ}" -o=json -I=0 '.revision' "${report}") || return 1
  now=$(themis_context_now)
  target="${THEMIS_CONTEXT_WORKSPACE}/state/context-signals/${id}.yaml"
  staged="${THEMIS_CONTEXT_TMP_ROOT}/${id}.yaml"
  first=${now}
  if [ -e "${target}" ]; then
    if [ ! -f "${target}" ] || [ -L "${target}" ] || ! themis_context_validate_signal "${target}"; then
      themis_context_add_error context_signal_invalid "state/context-signals/${id}.yaml"
      return 2
    fi
    first=$("${THEMIS_CONTEXT_YQ}" eval -r '.first_observed_at' "${target}")
    cp "${target}" "${staged}" || return 1
    THEMIS_REVISION=${revision} THEMIS_SOURCES=${sources} THEMIS_NOW=${now} "${THEMIS_CONTEXT_YQ}" eval -i '
      .revision = (strenv(THEMIS_REVISION) | from_json) |
      .sources = (strenv(THEMIS_SOURCES) | from_json) |
      .last_observed_at = strenv(THEMIS_NOW)
    ' "${staged}" || return 1
  else
    THEMIS_SIGNAL_ID=${id} THEMIS_SIGNAL_KIND=${kind} THEMIS_PROJECT=${THEMIS_CONTEXT_PROJECT_NAME} \
    THEMIS_WORKSPACE_DIGEST=${THEMIS_CONTEXT_WORKSPACE_DIGEST} THEMIS_REVISION=${revision} THEMIS_SCOPE=${scope} \
    THEMIS_SOURCES=${sources} THEMIS_FIRST=${first} THEMIS_NOW=${now} "${THEMIS_CONTEXT_YQ}" -n '
      {"signal_schema": "themis-context-signal", "id": strenv(THEMIS_SIGNAL_ID), "kind": strenv(THEMIS_SIGNAL_KIND),
       "status": "open", "project": strenv(THEMIS_PROJECT), "workspace_identity_digest": strenv(THEMIS_WORKSPACE_DIGEST),
       "revision": (strenv(THEMIS_REVISION) | from_json), "scope": (strenv(THEMIS_SCOPE) | from_json),
       "sources": (strenv(THEMIS_SOURCES) | from_json), "evidence_refs": [],
       "first_observed_at": strenv(THEMIS_FIRST), "last_observed_at": strenv(THEMIS_NOW), "disposition": null}
    ' >"${staged}" || return 1
  fi
  themis_context_validate_signal "${staged}" || return 1
  themis_context_begin_file_transaction freshness.record "${target}" || return 1
  if ! themis_context_commit_file_transaction "${staged}" "${target}"; then
    themis_context_rollback_transaction || return 2
    return 1
  fi
  return 0
}

record_report() {
  local report item_json
  report=$(themis_context_resolve_relative_path "${THEMIS_CONTEXT_REPORT_PATH}" "${THEMIS_CONTEXT_WORKSPACE}") || {
    themis_context_add_error context_report_path_invalid "${THEMIS_CONTEXT_REPORT_PATH}"; return 1;
  }
  if [ ! -f "${report}" ] || ! validate_report "${report}"; then
    themis_context_add_error context_report_invalid "${THEMIS_CONTEXT_REPORT_PATH}"; return 1
  fi
  themis_context_validate_catalog || { themis_context_add_error context_catalog_invalid context/catalog.yaml; return 1; }
  [ "$("${THEMIS_CONTEXT_YQ}" eval -r '.catalog_digest' "${report}")" = "${THEMIS_CONTEXT_CATALOG_DIGEST}" ] || {
    themis_context_add_error context_report_stale "${THEMIS_CONTEXT_REPORT_PATH}"; return 2;
  }
  [ "$("${THEMIS_CONTEXT_YQ}" eval -r '.workspace_identity_digest' "${report}")" = "${THEMIS_CONTEXT_WORKSPACE_DIGEST}" ] || {
    themis_context_add_error context_report_identity_conflict "${THEMIS_CONTEXT_REPORT_PATH}"; return 2;
  }
  themis_context_require_clean_transactions || return $?
  themis_context_acquire_lock freshness.record || return $?
  while IFS= read -r item_json; do
    [ -n "${item_json}" ] || continue
    record_signal_from_item "${item_json}" "${report}" || return $?
  done <<EOF
$("${THEMIS_CONTEXT_YQ}" -o=json -I=0 '.items[] | select(.signal_id != null)' "${report}")
EOF
}

resolve_signal() {
  local target staged note note_digest now evidence_json='[]' path resolved digest output="${THEMIS_CONTEXT_TMP_ROOT}/evidence.jsonl"
  target="${THEMIS_CONTEXT_WORKSPACE}/state/context-signals/${THEMIS_CONTEXT_SIGNAL_ID}.yaml"
  if [ ! -f "${target}" ] || ! themis_context_validate_signal "${target}"; then
    themis_context_add_error context_signal_invalid "state/context-signals/${THEMIS_CONTEXT_SIGNAL_ID}.yaml"; return 1
  fi
  note=$(themis_context_resolve_relative_path "${THEMIS_CONTEXT_NOTE_PATH}" "${THEMIS_CONTEXT_WORKSPACE}") || {
    themis_context_add_error context_note_path_invalid "${THEMIS_CONTEXT_NOTE_PATH}"; return 1;
  }
  [ -f "${note}" ] || { themis_context_add_error context_note_invalid "${THEMIS_CONTEXT_NOTE_PATH}"; return 1; }
  note_digest=$(themis_context_file_digest "${note}") || return 1
  : >"${output}"
  while IFS= read -r path; do
    [ -n "${path}" ] || continue
    resolved=$(themis_context_resolve_relative_path "${path}" "${THEMIS_CONTEXT_WORKSPACE}") || return 1
    [ -f "${resolved}" ] || return 1
    digest=$(themis_context_file_digest "${resolved}") || return 1
    THEMIS_EVIDENCE_PATH=${path} THEMIS_EVIDENCE_DIGEST=${digest} "${THEMIS_CONTEXT_YQ}" -n -o=json -I=0 \
      '{"path": strenv(THEMIS_EVIDENCE_PATH), "digest": strenv(THEMIS_EVIDENCE_DIGEST)}' >>"${output}" || return 1
  done <<EOF
${THEMIS_CONTEXT_EVIDENCE}
EOF
  if [ -s "${output}" ]; then
    evidence_json=$(THEMIS_EVIDENCE_FILE=${output} "${THEMIS_CONTEXT_YQ}" -n -o=json -I=0 \
      '[load_str(strenv(THEMIS_EVIDENCE_FILE)) | split("\n")[] | select(. != "") | from_json]') || return 1
  fi
  staged="${THEMIS_CONTEXT_TMP_ROOT}/signal-resolved.yaml"
  cp "${target}" "${staged}" || return 1
  now=$(themis_context_now)
  THEMIS_SIGNAL_STATUS=${THEMIS_CONTEXT_SIGNAL_STATUS} THEMIS_ACTOR=${THEMIS_CONTEXT_ACTOR} \
  THEMIS_NOTE_PATH=${THEMIS_CONTEXT_NOTE_PATH} THEMIS_NOTE_DIGEST=${note_digest} THEMIS_DECIDED_AT=${now} \
  THEMIS_EVIDENCE_JSON=${evidence_json} "${THEMIS_CONTEXT_YQ}" eval -i '
    .status = strenv(THEMIS_SIGNAL_STATUS) |
    .evidence_refs = (strenv(THEMIS_EVIDENCE_JSON) | from_json) |
    .disposition = {"actor": strenv(THEMIS_ACTOR),
      "note": {"path": strenv(THEMIS_NOTE_PATH), "digest": strenv(THEMIS_NOTE_DIGEST)},
      "decided_at": strenv(THEMIS_DECIDED_AT)}
  ' "${staged}" || return 1
  themis_context_validate_signal "${staged}" || return 1
  themis_context_require_clean_transactions || return $?
  themis_context_acquire_lock freshness.resolve || return $?
  themis_context_begin_file_transaction freshness.resolve "${target}" || return 1
  if ! themis_context_commit_file_transaction "${staged}" "${target}"; then
    themis_context_rollback_transaction || return 2
    themis_context_add_error context_transaction_failed "state/context-signals/${THEMIS_CONTEXT_SIGNAL_ID}.yaml"
    return 1
  fi
}

signal_status() {
  local root="${THEMIS_CONTEXT_WORKSPACE}/state/context-signals"
  local target
  local output="${THEMIS_CONTEXT_TMP_ROOT}/signal-status.json"
  local rows="${THEMIS_CONTEXT_TMP_ROOT}/signal-status.jsonl"
  if [ -n "${THEMIS_CONTEXT_SIGNAL_ID}" ]; then
    target="${root}/${THEMIS_CONTEXT_SIGNAL_ID}.yaml"
    if [ ! -f "${target}" ] || ! themis_context_validate_signal "${target}"; then
      themis_context_add_error context_signal_invalid "state/context-signals/${THEMIS_CONTEXT_SIGNAL_ID}.yaml"; return 1
    fi
    "${THEMIS_CONTEXT_YQ}" -o=json -I=0 '{"id": .id, "kind": .kind, "status": .status, "last_observed_at": .last_observed_at}' "${target}" >"${output}" || return 1
    THEMIS_CONTEXT_STATUS_DATA=$(cat "${output}")
    return 0
  fi
  set -- "${root}"/*.yaml
  if [ ! -e "$1" ]; then THEMIS_CONTEXT_STATUS_DATA='{"count":0,"signals":[]}'; return 0; fi
  : >"${rows}"
  for target in "$@"; do
    themis_context_validate_signal "${target}" || { themis_context_add_error context_signal_invalid "state/context-signals/$(basename -- "${target}")"; return 1; }
    "${THEMIS_CONTEXT_YQ}" -o=json -I=0 '{"id": .id, "kind": .kind, "status": .status, "last_observed_at": .last_observed_at}' "${target}" >>"${rows}" || return 1
  done
  THEMIS_SIGNALS_FILE=${rows} "${THEMIS_CONTEXT_YQ}" -n -o=json -I=0 \
    '{"signals": [load_str(strenv(THEMIS_SIGNALS_FILE)) | split("\n")[] | select(. != "") | from_json]} | .count = (.signals | length)' >"${output}" || return 1
  THEMIS_CONTEXT_STATUS_DATA=$(cat "${output}")
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
    check)
      check_freshness; result=$?
      if [ "${result}" -eq 0 ]; then data=$("${THEMIS_CONTEXT_YQ}" -o=json -I=0 '.' "${THEMIS_CONTEXT_REPORT_FILE}"); fi
      ;;
    record) record_report; result=$? ;;
    resolve) resolve_signal; result=$? ;;
    status) signal_status; result=$?; [ "${result}" -eq 0 ] && data=${THEMIS_CONTEXT_STATUS_DATA} ;;
    recover) themis_context_acquire_lock freshness.recover && themis_context_recover_transaction "${THEMIS_CONTEXT_TRANSACTION_ID}"; result=$? ;;
  esac
  case "${result}" in 0) status=ok ;; 2) status=needs_adjudication ;; *) status=invalid ;; esac
  themis_context_emit "${status}" "${data}"
}

main "$@"
