#!/usr/bin/env bash
#
# Themis Context Catalog 确定性执行器。
# 用途：绑定 Workspace identity，并事务式检查、注册或撤销受治理 L3 Item。
# 边界：不创建 L3、不删除知识文件、不自动重绑项目，也不处理 Knowledge Promotion 决策。
#
set -uo pipefail

THEMIS_CONTEXT_SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source-path=SCRIPTDIR
# shellcheck source=_themis-context-common.sh
. "${THEMIS_CONTEXT_SCRIPT_DIR}/_themis-context-common.sh"

THEMIS_CONTEXT_ACTION=
THEMIS_CONTEXT_ITEM_PATH=
THEMIS_CONTEXT_ITEM_ID=
THEMIS_CONTEXT_EXPECTED_DIGEST=
THEMIS_CONTEXT_TRANSACTION_ID=

usage() {
  cat <<'EOF'
Usage:
  themis-context-catalog.sh bind --workspace <root> --project-root <root>
  themis-context-catalog.sh check --workspace <root> [--project-root <root>]
  themis-context-catalog.sh register --workspace <root> --item <context-relative-path> --expected-catalog-digest <digest>
  themis-context-catalog.sh remove --workspace <root> --id <CTX-id> --expected-catalog-digest <digest>
  themis-context-catalog.sh status --workspace <root>
  themis-context-catalog.sh recover --workspace <root> --transaction <id>
EOF
}

parse_arguments() {
  THEMIS_CONTEXT_ACTION=${1-}
  case "${THEMIS_CONTEXT_ACTION}" in bind|check|register|remove|status|recover) ;; *) return 1 ;; esac
  THEMIS_CONTEXT_COMMAND="catalog.${THEMIS_CONTEXT_ACTION}"
  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --workspace|--project-root|--item|--id|--expected-catalog-digest|--transaction)
        [ "$#" -ge 2 ] && [ -n "$2" ] || return 1
        case "$1" in
          --workspace) THEMIS_CONTEXT_WORKSPACE_INPUT=$2 ;;
          --project-root) THEMIS_CONTEXT_PROJECT_ROOT=$2 ;;
          --item) THEMIS_CONTEXT_ITEM_PATH=$2 ;;
          --id) THEMIS_CONTEXT_ITEM_ID=$2 ;;
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
  case "${THEMIS_CONTEXT_ACTION}" in
    bind) [ -n "${THEMIS_CONTEXT_WORKSPACE_INPUT}" ] && [ -n "${THEMIS_CONTEXT_PROJECT_ROOT}" ] ;;
    check|status) [ -n "${THEMIS_CONTEXT_WORKSPACE_INPUT}" ] ;;
    register) [ -n "${THEMIS_CONTEXT_ITEM_PATH}" ] && [ -n "${THEMIS_CONTEXT_EXPECTED_DIGEST}" ] ;;
    remove) themis_context_item_id_valid "${THEMIS_CONTEXT_ITEM_ID}" && [ -n "${THEMIS_CONTEXT_EXPECTED_DIGEST}" ] ;;
    recover) [ -n "${THEMIS_CONTEXT_TRANSACTION_ID}" ] ;;
  esac
}

# 将 staged Catalog 摘要更新并 read-back 校验。
finalize_staged_catalog() {
  local staged=$1
  local digest
  digest=$(themis_context_catalog_digest "${staged}") || return 1
  THEMIS_CONTEXT_NEW_CATALOG_DIGEST=${digest} "${THEMIS_CONTEXT_YQ}" eval -i '.catalog_digest = strenv(THEMIS_CONTEXT_NEW_CATALOG_DIGEST)' "${staged}" || return 1
  themis_context_validate_catalog "${staged}"
}

# 在 Context 锁和单文件事务内替换 Catalog。
replace_catalog() {
  local operation=$1
  local staged=$2
  themis_context_require_clean_transactions || return $?
  themis_context_acquire_lock "${operation}" || return $?
  themis_context_begin_file_transaction "${operation}" "${THEMIS_CONTEXT_CATALOG}" || return 1
  if ! themis_context_commit_file_transaction "${staged}" "${THEMIS_CONTEXT_CATALOG}"; then
    if themis_context_rollback_transaction; then
      themis_context_add_error context_transaction_failed context/catalog.yaml
      return 1
    fi
    return 2
  fi
  THEMIS_CONTEXT_CATALOG_DIGEST=$(themis_context_catalog_digest "${THEMIS_CONTEXT_CATALOG}") || return 1
  return 0
}

catalog_bind() {
  local binding
  local bound_digest
  local revision
  local staged="${THEMIS_CONTEXT_TMP_ROOT}/catalog-bound.yaml"
  themis_context_open_project_root || return $?
  themis_context_validate_catalog || return 1
  binding=$("${THEMIS_CONTEXT_YQ}" eval -r '.binding' "${THEMIS_CONTEXT_CATALOG}")
  bound_digest=$("${THEMIS_CONTEXT_YQ}" eval -r '.workspace_identity_digest // ""' "${THEMIS_CONTEXT_CATALOG}")
  if [ "${binding}" = bound ]; then
    if [ "${bound_digest}" = "${THEMIS_CONTEXT_WORKSPACE_DIGEST}" ]; then
      return 0
    fi
    themis_context_add_error catalog_identity_conflict context/catalog.yaml
    return 2
  fi
  if [ -z "${THEMIS_CONTEXT_PROJECT_NAME}" ]; then
    themis_context_add_error project_name_missing manifest.yaml
    return 1
  fi
  revision=$(themis_context_revision_json "${THEMIS_CONTEXT_PROJECT_ROOT}") || return 1
  cp "${THEMIS_CONTEXT_CATALOG}" "${staged}" || return 1
  THEMIS_CONTEXT_BIND_NAME=${THEMIS_CONTEXT_PROJECT_NAME} \
  THEMIS_CONTEXT_BIND_DIGEST=${THEMIS_CONTEXT_WORKSPACE_DIGEST} \
  THEMIS_CONTEXT_BIND_KIND=$(printf '%s' "${revision}" | "${THEMIS_CONTEXT_YQ}" -p=json eval -r '.kind' -) \
  THEMIS_CONTEXT_BIND_COMMIT=$(printf '%s' "${revision}" | "${THEMIS_CONTEXT_YQ}" -p=json eval -r '.commit // ""' -) \
  THEMIS_CONTEXT_BIND_WORKTREE=$(printf '%s' "${revision}" | "${THEMIS_CONTEXT_YQ}" -p=json eval -r '.worktree' -) \
    "${THEMIS_CONTEXT_YQ}" eval -i '
      .binding = "bound" |
      .project.name = strenv(THEMIS_CONTEXT_BIND_NAME) |
      .workspace_identity_digest = strenv(THEMIS_CONTEXT_BIND_DIGEST) |
      .revision.kind = strenv(THEMIS_CONTEXT_BIND_KIND) |
      .revision.commit = (strenv(THEMIS_CONTEXT_BIND_COMMIT) | select(. != "") // null) |
      .revision.worktree = strenv(THEMIS_CONTEXT_BIND_WORKTREE)
    ' "${staged}" || return 1
  finalize_staged_catalog "${staged}" || return 1
  replace_catalog catalog.bind "${staged}"
}

catalog_check() {
  local bound_digest
  if [ -n "${THEMIS_CONTEXT_PROJECT_ROOT}" ]; then
    themis_context_open_project_root || return $?
  fi
  themis_context_validate_catalog || {
    themis_context_add_error context_catalog_invalid context/catalog.yaml
    return 1
  }
  bound_digest=$("${THEMIS_CONTEXT_YQ}" eval -r '.workspace_identity_digest // ""' "${THEMIS_CONTEXT_CATALOG}")
  if [ "${bound_digest}" != '' ] && [ "${bound_digest}" != "${THEMIS_CONTEXT_WORKSPACE_DIGEST}" ]; then
    themis_context_add_error catalog_identity_conflict context/catalog.yaml
    return 2
  fi
  return 0
}

catalog_register() {
  local item
  local relative
  local existing_path
  local existing_digest
  local entry="${THEMIS_CONTEXT_TMP_ROOT}/entry.yaml"
  local staged="${THEMIS_CONTEXT_TMP_ROOT}/catalog-register.yaml"
  catalog_check || return $?
  if [ "${THEMIS_CONTEXT_EXPECTED_DIGEST}" != "${THEMIS_CONTEXT_CATALOG_DIGEST}" ]; then
    themis_context_add_error catalog_digest_conflict context/catalog.yaml
    return 2
  fi
  relative=${THEMIS_CONTEXT_ITEM_PATH#context/}
  item=$(themis_context_resolve_relative_path "context/${relative}" "${THEMIS_CONTEXT_WORKSPACE}") || {
    themis_context_add_error context_item_path_invalid "context/${relative}"
    return 1
  }
  themis_context_load_item "${item}" || {
    themis_context_add_error context_item_invalid "context/${relative}"
    return 1
  }
  case "${relative}" in "${THEMIS_CONTEXT_ITEM_CATEGORY}"/*.md) ;; *) themis_context_add_error context_item_category_path_mismatch "context/${relative}"; return 1 ;; esac
  existing_path=$(THEMIS_CONTEXT_ID=${THEMIS_CONTEXT_ITEM_ID} "${THEMIS_CONTEXT_YQ}" eval -r '.items[strenv(THEMIS_CONTEXT_ID)].path // ""' "${THEMIS_CONTEXT_CATALOG}")
  existing_digest=$(THEMIS_CONTEXT_ID=${THEMIS_CONTEXT_ITEM_ID} "${THEMIS_CONTEXT_YQ}" eval -r '.items[strenv(THEMIS_CONTEXT_ID)].item_digest // ""' "${THEMIS_CONTEXT_CATALOG}")
  if [ -n "${existing_path}" ] && [ "${existing_path}" != "${relative}" ]; then
    themis_context_add_error context_id_conflict "${THEMIS_CONTEXT_ITEM_ID}"
    return 2
  fi
  if [ -n "${existing_path}" ] && [ "${existing_digest}" = "${THEMIS_CONTEXT_ITEM_DIGEST}" ]; then
    return 0
  fi
  if THEMIS_CONTEXT_PATH_VALUE=${relative} THEMIS_CONTEXT_ID=${THEMIS_CONTEXT_ITEM_ID} "${THEMIS_CONTEXT_YQ}" eval -e '.items | to_entries[] | select(.key != strenv(THEMIS_CONTEXT_ID) and .value.path == strenv(THEMIS_CONTEXT_PATH_VALUE))' "${THEMIS_CONTEXT_CATALOG}" >/dev/null 2>&1; then
    themis_context_add_error context_path_conflict "context/${relative}"
    return 2
  fi
  themis_context_render_item_entry "${relative}" "${entry}" || return 1
  cp "${THEMIS_CONTEXT_CATALOG}" "${staged}" || return 1
  THEMIS_CONTEXT_ID=${THEMIS_CONTEXT_ITEM_ID} THEMIS_CONTEXT_ENTRY=${entry} \
    "${THEMIS_CONTEXT_YQ}" eval -i '.items[strenv(THEMIS_CONTEXT_ID)] = load(strenv(THEMIS_CONTEXT_ENTRY))' "${staged}" || return 1
  if ! finalize_staged_catalog "${staged}"; then
    themis_context_add_error catalog_reference_or_cycle_invalid "${THEMIS_CONTEXT_ITEM_ID}"
    return 1
  fi
  replace_catalog catalog.register "${staged}"
}

catalog_remove() {
  local status
  local referenced
  local staged="${THEMIS_CONTEXT_TMP_ROOT}/catalog-remove.yaml"
  catalog_check || return $?
  if [ "${THEMIS_CONTEXT_EXPECTED_DIGEST}" != "${THEMIS_CONTEXT_CATALOG_DIGEST}" ]; then
    themis_context_add_error catalog_digest_conflict context/catalog.yaml
    return 2
  fi
  if ! THEMIS_CONTEXT_ID=${THEMIS_CONTEXT_ITEM_ID} "${THEMIS_CONTEXT_YQ}" eval -e '.items | has(strenv(THEMIS_CONTEXT_ID))' "${THEMIS_CONTEXT_CATALOG}" >/dev/null 2>&1; then
    return 0
  fi
  status=$(THEMIS_CONTEXT_ID=${THEMIS_CONTEXT_ITEM_ID} "${THEMIS_CONTEXT_YQ}" eval -r '.items[strenv(THEMIS_CONTEXT_ID)].status' "${THEMIS_CONTEXT_CATALOG}")
  referenced=$(THEMIS_CONTEXT_ID=${THEMIS_CONTEXT_ITEM_ID} "${THEMIS_CONTEXT_YQ}" eval -r '[.items[] | (.dependencies + .supersedes)[] | select(. == strenv(THEMIS_CONTEXT_ID))] | length' "${THEMIS_CONTEXT_CATALOG}")
  if [ "${status}" = active ] || [ "${referenced}" -ne 0 ]; then
    themis_context_add_error context_remove_requires_adjudication "${THEMIS_CONTEXT_ITEM_ID}"
    return 2
  fi
  cp "${THEMIS_CONTEXT_CATALOG}" "${staged}" || return 1
  THEMIS_CONTEXT_ID=${THEMIS_CONTEXT_ITEM_ID} "${THEMIS_CONTEXT_YQ}" eval -i 'del(.items[strenv(THEMIS_CONTEXT_ID)])' "${staged}" || return 1
  finalize_staged_catalog "${staged}" || return 1
  replace_catalog catalog.remove "${staged}"
}

main() {
  local result
  local status=ok
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
    bind) catalog_bind ;;
    check) catalog_check ;;
    register) catalog_register ;;
    remove) catalog_remove ;;
    status)
      if ! themis_context_validate_catalog; then
        themis_context_add_error context_catalog_invalid context/catalog.yaml
        false
      fi
      ;;
    recover)
      themis_context_acquire_lock catalog.recover && themis_context_recover_transaction "${THEMIS_CONTEXT_TRANSACTION_ID}"
      ;;
  esac
  result=$?
  case "${result}" in 0) status=ok ;; 2) status=needs_adjudication ;; *) status=invalid ;; esac
  THEMIS_CONTEXT_CATALOG_DIGEST=$(themis_context_catalog_digest "${THEMIS_CONTEXT_CATALOG}" 2>/dev/null || printf '')
  themis_context_emit "${status}" "{\"binding\":\"$(themis_context_json_escape "$("${THEMIS_CONTEXT_YQ}" eval -r '.binding // "unknown"' "${THEMIS_CONTEXT_CATALOG}" 2>/dev/null || printf unknown)")\",\"catalog_digest\":\"$(themis_context_json_escape "${THEMIS_CONTEXT_CATALOG_DIGEST}")\"}"
}

main "$@"
