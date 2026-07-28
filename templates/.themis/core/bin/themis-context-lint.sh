#!/usr/bin/env bash
#
# Themis Context Lint 确定性执行器。
# 用途：只读校验 Catalog、L3 Item、Bundle 与 Signal 的结构、摘要、引用和路径。
# 边界：不修复、不注册、不创建 Signal，也不把未注册文件提升为正式 Context。
#
set -uo pipefail

THEMIS_CONTEXT_SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source-path=SCRIPTDIR
# shellcheck source=_themis-context-common.sh
. "${THEMIS_CONTEXT_SCRIPT_DIR}/_themis-context-common.sh"

# shellcheck disable=SC2034
THEMIS_CONTEXT_COMMAND=lint
THEMIS_CONTEXT_KIND=all
THEMIS_CONTEXT_PATH=

usage() {
  printf '%s\n' 'Usage: themis-context-lint.sh lint --workspace <root> [--kind all|item|catalog|bundle|signal] [--path <relative-path>]'
}

parse_arguments() {
  [ "${1-}" = lint ] || return 1
  shift
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --workspace|--kind|--path)
        [ "$#" -ge 2 ] && [ -n "$2" ] || return 1
        case "$1" in
          --workspace) THEMIS_CONTEXT_WORKSPACE_INPUT=$2 ;;
          --kind) THEMIS_CONTEXT_KIND=$2 ;;
          --path) THEMIS_CONTEXT_PATH=$2 ;;
        esac
        shift
        ;;
      --help|-h) usage; exit 0 ;;
      *) return 1 ;;
    esac
    shift
  done
  case "${THEMIS_CONTEXT_KIND}" in all|item|catalog|bundle|signal) ;; *) return 1 ;; esac
  if [ "${THEMIS_CONTEXT_KIND}" = item ] && [ -z "${THEMIS_CONTEXT_PATH}" ]; then return 1; fi
  return 0
}

# 校验 Catalog 注册集合的唯一性、引用和每个 Item 的实时摘要。
lint_catalog_items() {
  local id
  local path
  local item
  local expected_item_digest
  local expected_content_digest
  local actual_category
  local actual_status
  local catalog_error=0

  if ! "${THEMIS_CONTEXT_YQ}" eval -e '
    ([.items[].path] | length) == ([.items[].path] | unique | length)
  ' "${THEMIS_CONTEXT_CATALOG}" >/dev/null 2>&1; then
    themis_context_add_error catalog_reference_or_path_invalid context/catalog.yaml
    catalog_error=1
  fi

  while IFS=$'\t' read -r id path expected_item_digest expected_content_digest actual_category actual_status; do
    [ -n "${id}" ] || continue
    if ! themis_context_item_id_valid "${id}"; then
      themis_context_add_error context_id_invalid "${id}"
      catalog_error=1
      continue
    fi
    item=$(themis_context_resolve_relative_path "context/${path}" "${THEMIS_CONTEXT_WORKSPACE}") || {
      themis_context_add_error context_item_path_invalid "context/${path}"
      catalog_error=1
      continue
    }
    case "${path}" in
      "${actual_category}"/*.md) ;;
      *) themis_context_add_error context_item_category_path_mismatch "context/${path}"; catalog_error=1 ;;
    esac
    if ! themis_context_load_item "${item}"; then
      themis_context_add_error context_item_invalid "context/${path}"
      catalog_error=1
      continue
    fi
    if [ "${THEMIS_CONTEXT_ITEM_ID}" != "${id}" ] || [ "${THEMIS_CONTEXT_ITEM_CATEGORY}" != "${actual_category}" ] || \
       [ "${THEMIS_CONTEXT_ITEM_STATUS}" != "${actual_status}" ] || [ "${THEMIS_CONTEXT_ITEM_DIGEST}" != "${expected_item_digest}" ] || \
       [ "${THEMIS_CONTEXT_ITEM_CONTENT_DIGEST}" != "${expected_content_digest}" ]; then
      themis_context_add_error context_item_catalog_drift "context/${path}"
      catalog_error=1
    fi
  done <<EOF
$("${THEMIS_CONTEXT_YQ}" eval -r '.items | to_entries[] | [.key, .value.path, .value.item_digest, .value.content_digest, .value.category, .value.status] | @tsv' "${THEMIS_CONTEXT_CATALOG}" 2>/dev/null)
EOF
  [ "${catalog_error}" -eq 0 ]
}

lint_single_path() {
  local resolved
  resolved=$(themis_context_resolve_relative_path "${THEMIS_CONTEXT_PATH}" "${THEMIS_CONTEXT_WORKSPACE}") || return 1
  case "${THEMIS_CONTEXT_KIND}" in
    item) themis_context_load_item "${resolved}" ;;
    catalog) themis_context_validate_catalog "${resolved}" ;;
    bundle) themis_context_validate_bundle_manifest "${resolved}" ;;
    signal) themis_context_validate_signal "${resolved}" ;;
    *) return 1 ;;
  esac
}

main() {
  local status=ok
  local checked=0
  if ! parse_arguments "$@"; then
    usage >&2
    themis_context_add_error invalid_arguments
    themis_context_emit invalid '{}'
    return $?
  fi
  themis_context_require_runtime || return $?
  themis_context_prepare_temp || {
    themis_context_add_error temporary_directory_failed
    themis_context_emit unavailable '{}'
    return $?
  }
  trap themis_context_cleanup EXIT HUP INT TERM
  themis_context_open_workspace
  case $? in
    0) ;;
    2) themis_context_emit unavailable '{}'; return $? ;;
    *) themis_context_emit invalid '{}'; return $? ;;
  esac

  if [ -n "${THEMIS_CONTEXT_PATH}" ]; then
    if lint_single_path; then checked=1; else themis_context_add_error context_artifact_invalid "${THEMIS_CONTEXT_PATH}"; status=invalid; fi
  else
    if ! themis_context_validate_catalog; then
      themis_context_add_error context_catalog_invalid context/catalog.yaml
      status=invalid
    elif [ "${THEMIS_CONTEXT_KIND}" = all ] || [ "${THEMIS_CONTEXT_KIND}" = catalog ] || [ "${THEMIS_CONTEXT_KIND}" = item ]; then
      if lint_catalog_items; then checked=$("${THEMIS_CONTEXT_YQ}" eval -r '.items | length' "${THEMIS_CONTEXT_CATALOG}"); else status=invalid; fi
    fi
  fi
  themis_context_emit "${status}" "{\"checked\":${checked},\"catalog_digest\":\"${THEMIS_CONTEXT_CATALOG_DIGEST}\"}"
}

main "$@"
