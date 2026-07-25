#!/usr/bin/env bash
#
# Themis 受管内容升级器。
# 用途：以事务方式替换 .themis/ 中除 workspace/ 外的受管内容，并永久保留升级前备份。
# 边界：绝不复制、删除、迁移或恢复 Workspace，也不修改 CLAUDE.md 或 AGENTS.md；Upgrade 不加载 P0。
# 兼容性：保持 Bash 3.2 兼容，并独立要求 mikefarah/yq v4。
#
THEMIS_UPGRADE_GUIDANCE_START='<!-- themis:guidance:start -->'
THEMIS_UPGRADE_GUIDANCE_END='<!-- themis:guidance:end -->'
THEMIS_UPGRADE_GUIDANCE_BLOCK='<!-- themis:guidance:start -->
@import .themis/CLAUDE.themis.md
@import .themis/core/kernel/orchestrator/rules.md
<!-- themis:guidance:end -->'
THEMIS_UPGRADE_TARGET=.
THEMIS_UPGRADE_DRY_RUN=0
THEMIS_UPGRADE_YQ=${YQ:-yq}
# 将候选内容先暂存，再移动旧受管内容到持久备份，最后才替换；Workspace 始终被排除。
THEMIS_UPGRADE_BACKUP=
THEMIS_UPGRADE_STAGE=
# 事务开始前记录 Workspace 与 CLAUDE.md 指纹；后续比较用于证明所有权边界未被突破。
THEMIS_UPGRADE_WORKSPACE_FINGERPRINT=
THEMIS_UPGRADE_CLAUDE_FINGERPRINT=
THEMIS_UPGRADE_TRANSACTION=0

# 输出一条可操作的 Upgrade 失败诊断。
themis_upgrade_error() {
  printf '%s\n' "Themis Upgrade failed: ${1-unknown error}" "  Fix: ${2-Review the target project and retry.}" >&2
  return 1
}

# 输出命令帮助，不读取或修改目标项目。
themis_upgrade_usage() {
  cat <<'EOF'
Usage: themis-upgrade.sh [target] [--dry-run]

Upgrade the Themis-managed content in target (default: current directory).

Options:
  --dry-run  Validate and describe the upgrade without writing files.
  --help     Show this help text.
EOF
}

# 在访问候选模板或目标路径前解析参数；仅允许一个目标目录。
themis_upgrade_parse_arguments() {
  local themis_upgrade_positional_seen=0

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dry-run) THEMIS_UPGRADE_DRY_RUN=1 ;;
      --help)
        themis_upgrade_usage
        exit 0
        ;;
      --*)
        themis_upgrade_error "unknown option: $1" 'Run with --help to see supported options.'
        return 1
        ;;
      *)
        if [ "${themis_upgrade_positional_seen}" -eq 1 ]; then
          themis_upgrade_error "unexpected target: $1" 'Pass at most one target directory.'
          return 1
        fi
        THEMIS_UPGRADE_TARGET=$1
        themis_upgrade_positional_seen=1
        ;;
    esac
    shift
  done
  return 0
}

# 独立确认本地存在 mikefarah/yq v4；Upgrade 不加载仅供 Init 的 P0。
themis_upgrade_require_yq() {
  local themis_upgrade_yq_version

  if ! command -v "${THEMIS_UPGRADE_YQ}" >/dev/null 2>&1; then
    themis_upgrade_error 'yq unavailable' 'Install mikefarah/yq v4 or set YQ to its executable path.'
    return 1
  fi
  themis_upgrade_yq_version=$("${THEMIS_UPGRADE_YQ}" --version 2>&1) || {
    themis_upgrade_error 'yq version unreadable' 'Install a working mikefarah/yq v4 executable.'
    return 1
  }
  case "${themis_upgrade_yq_version}" in
    *mikefarah/yq*version\ v4.*) return 0 ;;
    *)
      themis_upgrade_error 'unsupported yq implementation' 'Use mikefarah/yq v4 for Upgrade metadata validation.'
      return 1
      ;;
  esac
}

# 读取 YAML 值并将解析失败转换为稳定的 Upgrade 诊断。
themis_upgrade_yq_read() {
  local themis_upgrade_yq_file=$1
  local themis_upgrade_yq_expression=$2
  local themis_upgrade_yq_value

  if ! themis_upgrade_yq_value=$("${THEMIS_UPGRADE_YQ}" eval -r "${themis_upgrade_yq_expression}" "${themis_upgrade_yq_file}" 2>/dev/null); then
    themis_upgrade_error "YAML unreadable: ${themis_upgrade_yq_file}" 'Repair the installed metadata or candidate template before upgrading.'
    return 1
  fi
  printf '%s\n' "${themis_upgrade_yq_value}"
}

# 统计精确标记行，复用 Init 的严格识别语义而不导入 Init。
themis_upgrade_marker_count() {
  local themis_upgrade_marker=$1
  local themis_upgrade_file=$2

  sed -n "\|^${themis_upgrade_marker}$|p" "${themis_upgrade_file}" | wc -l | tr -d '[:space:]'
}

# 确认唯一、精确的 P3 直接 import 块；旧布局必须人工迁移，Upgrade 不重写项目指引。
themis_upgrade_validate_guidance_layout() {
  local themis_upgrade_claude="${THEMIS_UPGRADE_TARGET}/CLAUDE.md"
  local themis_upgrade_start_count
  local themis_upgrade_end_count
  local themis_upgrade_actual

  if [ ! -f "${themis_upgrade_claude}" ]; then
    themis_upgrade_error 'legacy project guidance layout' 'Manually add the current Themis direct-import block to CLAUDE.md before upgrading.'
    return 1
  fi
  if [ -e "${THEMIS_UPGRADE_TARGET}/CLAUDE.themis.md" ]; then
    themis_upgrade_error 'legacy root guidance present' 'Manually remove or migrate root-level CLAUDE.themis.md; Upgrade will not rewrite project guidance.'
    return 1
  fi
  if [ ! -f "${THEMIS_UPGRADE_TARGET}/.themis/CLAUDE.themis.md" ]; then
    themis_upgrade_error 'contained guidance missing' 'Restore .themis/CLAUDE.themis.md or migrate the installation manually before upgrading.'
    return 1
  fi

  themis_upgrade_start_count=$(themis_upgrade_marker_count "${THEMIS_UPGRADE_GUIDANCE_START}" "${themis_upgrade_claude}")
  themis_upgrade_end_count=$(themis_upgrade_marker_count "${THEMIS_UPGRADE_GUIDANCE_END}" "${themis_upgrade_claude}")
  if [ "${themis_upgrade_start_count}" != 1 ] || [ "${themis_upgrade_end_count}" != 1 ]; then
    themis_upgrade_error 'legacy project guidance layout' 'Keep exactly one complete current Themis block in CLAUDE.md or migrate it manually before upgrading.'
    return 1
  fi

  themis_upgrade_actual=$(sed -n "\|^${THEMIS_UPGRADE_GUIDANCE_START}$|,\|^${THEMIS_UPGRADE_GUIDANCE_END}$|p" "${themis_upgrade_claude}")
  if [ "${themis_upgrade_actual}" != "${THEMIS_UPGRADE_GUIDANCE_BLOCK}" ]; then
    themis_upgrade_error 'modified Themis guidance block' 'Restore the current direct-import block or migrate project guidance manually before upgrading.'
    return 1
  fi
  return 0
}

# 生成不写入 Workspace 的内容和结构指纹，用以验证所有权边界。
themis_upgrade_workspace_fingerprint() {
  local themis_upgrade_workspace=$1
  local themis_upgrade_path
  local themis_upgrade_relative
  local themis_upgrade_checksum

  find -P "${themis_upgrade_workspace}" -mindepth 1 -print | LC_ALL=C sort | while IFS= read -r themis_upgrade_path; do
    themis_upgrade_relative=${themis_upgrade_path#"${themis_upgrade_workspace}"/}
    if [ -d "${themis_upgrade_path}" ]; then
      printf 'directory %s\n' "${themis_upgrade_relative}"
    elif [ -f "${themis_upgrade_path}" ]; then
      themis_upgrade_checksum=$(cksum "${themis_upgrade_path}") || exit 1
      printf 'file %s %s\n' "${themis_upgrade_relative}" "${themis_upgrade_checksum}"
    elif [ -L "${themis_upgrade_path}" ]; then
      printf 'symlink %s %s\n' "${themis_upgrade_relative}" "$(readlink "${themis_upgrade_path}")"
    else
      printf 'other %s\n' "${themis_upgrade_relative}"
    fi
  done
}

# 仅复制非 Workspace 的顶层受管条目，回滚时同样排除 Workspace。
themis_upgrade_copy_managed_entries() {
  local themis_upgrade_source_root=$1
  local themis_upgrade_destination=$2
  local themis_upgrade_entry
  local themis_upgrade_name

  for themis_upgrade_entry in "${themis_upgrade_source_root}"/.[!.]* "${themis_upgrade_source_root}"/..?* "${themis_upgrade_source_root}"/*; do
    [ -e "${themis_upgrade_entry}" ] || [ -L "${themis_upgrade_entry}" ] || continue
    themis_upgrade_name=$(basename -- "${themis_upgrade_entry}")
    [ "${themis_upgrade_name}" = workspace ] && continue
    if [ -d "${themis_upgrade_entry}" ] && [ ! -L "${themis_upgrade_entry}" ]; then
      cp -R -- "${themis_upgrade_entry}" "${themis_upgrade_destination}/${themis_upgrade_name}" || return 1
    else
      cp -p -- "${themis_upgrade_entry}" "${themis_upgrade_destination}/${themis_upgrade_name}" || return 1
    fi
  done
  return 0
}

# 仅移动非 Workspace 的顶层受管条目，用于创建持久备份或提交候选替换。
themis_upgrade_move_managed_entries() {
  local themis_upgrade_source_root=$1
  local themis_upgrade_destination=$2
  local themis_upgrade_entry
  local themis_upgrade_name

  for themis_upgrade_entry in "${themis_upgrade_source_root}"/.[!.]* "${themis_upgrade_source_root}"/..?* "${themis_upgrade_source_root}"/*; do
    [ -e "${themis_upgrade_entry}" ] || [ -L "${themis_upgrade_entry}" ] || continue
    themis_upgrade_name=$(basename -- "${themis_upgrade_entry}")
    [ "${themis_upgrade_name}" = workspace ] && continue
    mv -- "${themis_upgrade_entry}" "${themis_upgrade_destination}/" || return 1
  done
  return 0
}

# 检查候选 Core allow-list 是否包含已安装 Schema；迁移描述符不影响 P4 决策。
themis_upgrade_schema_supported() {
  local themis_upgrade_core=$1
  local themis_upgrade_dimension=$2
  local themis_upgrade_schema=$3
  local themis_upgrade_candidate

  while IFS= read -r themis_upgrade_candidate; do
    if [ "${themis_upgrade_candidate}" = "${themis_upgrade_schema}" ]; then
      return 0
    fi
  done <<EOF
$(themis_upgrade_yq_read "${themis_upgrade_core}" ".compatibility.${themis_upgrade_dimension}.supported[]?")
EOF
  return 1
}

# 格式化候选支持列表供诊断使用，并显式表示空列表。
themis_upgrade_support_list() {
  local themis_upgrade_core=$1
  local themis_upgrade_dimension=$2
  local themis_upgrade_values

  themis_upgrade_values=$(themis_upgrade_yq_read "${themis_upgrade_core}" ".compatibility.${themis_upgrade_dimension}.supported[]?") || return 1
  if [ -z "${themis_upgrade_values}" ]; then
    printf '%s\n' '(empty)'
  else
    printf '%s\n' "${themis_upgrade_values}" | tr '\n' ',' | sed 's/,$//'
  fi
}

# 回滚时只移除替换可能写入的候选条目，其名称在移动前已记录。
themis_upgrade_remove_candidate_entries() {
  local themis_upgrade_name
  local themis_upgrade_names_file="${THEMIS_UPGRADE_STAGE}/managed-names"

  [ -n "${THEMIS_UPGRADE_STAGE}" ] || return 0
  [ -f "${themis_upgrade_names_file}" ] || return 0
  while IFS= read -r themis_upgrade_name; do
    [ -n "${themis_upgrade_name}" ] || continue
    [ "${themis_upgrade_name}" = workspace ] && continue
    rm -rf -- "${THEMIS_UPGRADE_TARGET}/.themis/${themis_upgrade_name}" || return 1
  done < "${themis_upgrade_names_file}"
  return 0
}

# 恢复备份的受管条目并保留备份，随后重新验证 Workspace 和 CLAUDE.md 边界。
themis_upgrade_rollback() {
  local themis_upgrade_workspace_after
  local themis_upgrade_claude_after

  themis_upgrade_remove_candidate_entries || return 1
  if [ -n "${THEMIS_UPGRADE_BACKUP}" ] && [ -d "${THEMIS_UPGRADE_BACKUP}/managed" ]; then
    themis_upgrade_copy_managed_entries "${THEMIS_UPGRADE_BACKUP}/managed" "${THEMIS_UPGRADE_TARGET}/.themis" || return 1
  fi
  rm -rf -- "${THEMIS_UPGRADE_STAGE}"
  THEMIS_UPGRADE_STAGE=
  themis_upgrade_workspace_after=$(themis_upgrade_workspace_fingerprint "${THEMIS_UPGRADE_TARGET}/.themis/workspace") || return 1
  themis_upgrade_claude_after=$(cksum "${THEMIS_UPGRADE_TARGET}/CLAUDE.md") || return 1
  if [ "${themis_upgrade_workspace_after}" != "${THEMIS_UPGRADE_WORKSPACE_FINGERPRINT}" ] || [ "${themis_upgrade_claude_after}" != "${THEMIS_UPGRADE_CLAUDE_FINGERPRINT}" ]; then
    themis_upgrade_error 'rollback boundary verification failed' "Workspace or CLAUDE.md changed unexpectedly; inspect persistent backup at ${THEMIS_UPGRADE_BACKUP}."
    return 1
  fi
  return 0
}

# 处理活动事务失败：执行自动恢复；恢复失败时报告持久备份位置。
themis_upgrade_transaction_failed() {
  local themis_upgrade_subject=$1
  local themis_upgrade_remediation=$2

  if ! themis_upgrade_rollback; then
    themis_upgrade_error 'automatic rollback failed' "Inspect the persistent backup at ${THEMIS_UPGRADE_BACKUP:-unknown} before retrying."
    exit 1
  fi
  THEMIS_UPGRADE_TRANSACTION=0
  themis_upgrade_error "${themis_upgrade_subject}" "${themis_upgrade_remediation} Backup retained at ${THEMIS_UPGRADE_BACKUP}."
  exit 1
}

# 在替换期间收到中断信号时仅恢复受管内容。
themis_upgrade_handle_signal() {
  if [ "${THEMIS_UPGRADE_TRANSACTION}" -eq 1 ]; then
    themis_upgrade_transaction_failed 'upgrade interrupted' 'The managed-content transaction was rolled back.'
  fi
  exit 1
}

# 相对脚本定位候选模板与检查器，并登记信号处理，以保证事务中断时可以恢复。
THEMIS_UPGRADE_SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd) || exit 1
THEMIS_UPGRADE_REPOSITORY_ROOT=$(CDPATH='' cd -- "${THEMIS_UPGRADE_SCRIPT_DIR}/.." && pwd) || exit 1
THEMIS_UPGRADE_TEMPLATE_SOURCE="${THEMIS_UPGRADE_REPOSITORY_ROOT}/templates/.themis"
THEMIS_UPGRADE_CHECKER="${THEMIS_UPGRADE_REPOSITORY_ROOT}/bin/themis-template-check.sh"

trap 'themis_upgrade_handle_signal' HUP INT TERM

# 以下主流程在启动事务前完成元数据、指引布局和 Schema 兼容性预检。
themis_upgrade_parse_arguments "$@" || exit 1

themis_upgrade_require_yq || exit 1

if [ ! -d "${THEMIS_UPGRADE_TARGET}" ]; then
  themis_upgrade_error "target directory missing: ${THEMIS_UPGRADE_TARGET}" 'Choose an existing initialized project directory.'
  exit 1
fi
THEMIS_UPGRADE_TARGET=$(CDPATH='' cd -- "${THEMIS_UPGRADE_TARGET}" && pwd) || exit 1
if [ ! -w "${THEMIS_UPGRADE_TARGET}" ]; then
  themis_upgrade_error "target directory is not writable: ${THEMIS_UPGRADE_TARGET}" 'Choose a writable project directory.'
  exit 1
fi
if [ ! -d "${THEMIS_UPGRADE_TARGET}/.themis" ] || [ ! -d "${THEMIS_UPGRADE_TARGET}/.themis/workspace" ]; then
  themis_upgrade_error 'installed Workspace missing' 'Run Init for a new project or restore the existing .themis/workspace directory.'
  exit 1
fi
if [ ! -f "${THEMIS_UPGRADE_TARGET}/.themis/VERSION" ] || [ ! -f "${THEMIS_UPGRADE_TARGET}/.themis/core/core.yaml" ] || [ ! -f "${THEMIS_UPGRADE_TARGET}/.themis/workspace/manifest.yaml" ]; then
  themis_upgrade_error 'installed metadata missing' 'Restore VERSION, core/core.yaml, and workspace/manifest.yaml before upgrading.'
  exit 1
fi
if [ ! -d "${THEMIS_UPGRADE_TEMPLATE_SOURCE}" ] || [ ! -f "${THEMIS_UPGRADE_CHECKER}" ]; then
  themis_upgrade_error 'source template unavailable' 'Run Upgrade from a complete Themis source repository.'
  exit 1
fi
if ! YQ="${THEMIS_UPGRADE_YQ}" bash "${THEMIS_UPGRADE_CHECKER}" "${THEMIS_UPGRADE_TEMPLATE_SOURCE}"; then
  themis_upgrade_error 'candidate template contract invalid' 'Repair the source template before upgrading a project.'
  exit 1
fi
themis_upgrade_validate_guidance_layout || exit 1

THEMIS_UPGRADE_INSTALLED_BUNDLE_VERSION=$(sed -n '1p' "${THEMIS_UPGRADE_TARGET}/.themis/VERSION")
THEMIS_UPGRADE_CANDIDATE_BUNDLE_VERSION=$(sed -n '1p' "${THEMIS_UPGRADE_TEMPLATE_SOURCE}/VERSION")
THEMIS_UPGRADE_INSTALLED_CORE_VERSION=$(themis_upgrade_yq_read "${THEMIS_UPGRADE_TARGET}/.themis/core/core.yaml" '.core_version // ""') || exit 1
THEMIS_UPGRADE_CANDIDATE_CORE_VERSION=$(themis_upgrade_yq_read "${THEMIS_UPGRADE_TEMPLATE_SOURCE}/core/core.yaml" '.core_version // ""') || exit 1
THEMIS_UPGRADE_WORKSPACE_SCHEMA=$(themis_upgrade_yq_read "${THEMIS_UPGRADE_TARGET}/.themis/workspace/manifest.yaml" '.workspace_schema // ""') || exit 1
THEMIS_UPGRADE_ARTIFACT_SCHEMA=$(themis_upgrade_yq_read "${THEMIS_UPGRADE_TARGET}/.themis/workspace/manifest.yaml" '.artifact_schema // ""') || exit 1

case "${THEMIS_UPGRADE_WORKSPACE_SCHEMA}" in themis-workspace/v[0-9]*) ;; *) themis_upgrade_error 'installed Workspace schema invalid' 'Use a namespaced themis-workspace/v<number> schema before upgrading.'; exit 1 ;; esac
case "${THEMIS_UPGRADE_ARTIFACT_SCHEMA}" in themis-artifact/v[0-9]*) ;; *) themis_upgrade_error 'installed Artifact schema invalid' 'Use a namespaced themis-artifact/v<number> schema before upgrading.'; exit 1 ;; esac

if ! themis_upgrade_schema_supported "${THEMIS_UPGRADE_TEMPLATE_SOURCE}/core/core.yaml" workspace "${THEMIS_UPGRADE_WORKSPACE_SCHEMA}"; then
  THEMIS_UPGRADE_WORKSPACE_SUPPORTED=$(themis_upgrade_support_list "${THEMIS_UPGRADE_TEMPLATE_SOURCE}/core/core.yaml" workspace) || exit 1
  themis_upgrade_error 'incompatible Workspace schema' "Installed ${THEMIS_UPGRADE_WORKSPACE_SCHEMA}; candidate ${THEMIS_UPGRADE_CANDIDATE_CORE_VERSION} supports ${THEMIS_UPGRADE_WORKSPACE_SUPPORTED}. P4 does not run migrations. If a migration descriptor exists for this schema, run 'themis-migrate.sh <target> --check' to see available migration paths."
  exit 1
fi
if ! themis_upgrade_schema_supported "${THEMIS_UPGRADE_TEMPLATE_SOURCE}/core/core.yaml" artifact "${THEMIS_UPGRADE_ARTIFACT_SCHEMA}"; then
  THEMIS_UPGRADE_ARTIFACT_SUPPORTED=$(themis_upgrade_support_list "${THEMIS_UPGRADE_TEMPLATE_SOURCE}/core/core.yaml" artifact) || exit 1
  themis_upgrade_error 'incompatible Artifact schema' "Installed ${THEMIS_UPGRADE_ARTIFACT_SCHEMA}; candidate ${THEMIS_UPGRADE_CANDIDATE_CORE_VERSION} supports ${THEMIS_UPGRADE_ARTIFACT_SUPPORTED}. P4 does not run migrations. If a migration descriptor exists for this schema, run 'themis-migrate.sh <target> --check' to see available migration paths."
  exit 1
fi

if [ -z "${THEMIS_UPGRADE_INSTALLED_BUNDLE_VERSION}" ] || [ -z "${THEMIS_UPGRADE_INSTALLED_CORE_VERSION}" ]; then
  themis_upgrade_error 'installed version metadata invalid' 'Restore one non-empty Bundle and Core version before upgrading.'
  exit 1
fi

if [ "${THEMIS_UPGRADE_INSTALLED_BUNDLE_VERSION}" = "${THEMIS_UPGRADE_CANDIDATE_BUNDLE_VERSION}" ] && [ "${THEMIS_UPGRADE_INSTALLED_CORE_VERSION}" = "${THEMIS_UPGRADE_CANDIDATE_CORE_VERSION}" ]; then
  printf 'Themis already current in %s (Bundle/Core %s)\n' "${THEMIS_UPGRADE_TARGET}" "${THEMIS_UPGRADE_CANDIDATE_BUNDLE_VERSION}"
  exit 0
fi

if [ "${THEMIS_UPGRADE_DRY_RUN}" -eq 1 ]; then
  printf '%s\n' "Themis Upgrade dry run for ${THEMIS_UPGRADE_TARGET}" \
    "  Installed Bundle/Core: ${THEMIS_UPGRADE_INSTALLED_BUNDLE_VERSION}/${THEMIS_UPGRADE_INSTALLED_CORE_VERSION}" \
    "  Candidate Bundle/Core: ${THEMIS_UPGRADE_CANDIDATE_BUNDLE_VERSION}/${THEMIS_UPGRADE_CANDIDATE_CORE_VERSION}" \
    "  Workspace/Artifact schema: ${THEMIS_UPGRADE_WORKSPACE_SCHEMA}/${THEMIS_UPGRADE_ARTIFACT_SCHEMA}" \
    '  Compatibility: compatible' \
    "  Persistent backup pattern: ${THEMIS_UPGRADE_TARGET}/.themis-upgrade-backup.XXXXXX" \
    '  Replace: every .themis/ top-level entry except workspace/' \
    '  Preserve without writes: .themis/workspace/, CLAUDE.md, AGENTS.md'
  exit 0
fi

# 事务开始前记录 Workspace 与 CLAUDE.md 指纹；后续比较用于证明所有权边界未被突破。
THEMIS_UPGRADE_WORKSPACE_FINGERPRINT=$(themis_upgrade_workspace_fingerprint "${THEMIS_UPGRADE_TARGET}/.themis/workspace") || {
  themis_upgrade_error 'Workspace fingerprint failed' 'Ensure Workspace paths are readable before upgrading.'
  exit 1
}
THEMIS_UPGRADE_CLAUDE_FINGERPRINT=$(cksum "${THEMIS_UPGRADE_TARGET}/CLAUDE.md") || {
  themis_upgrade_error 'CLAUDE.md fingerprint failed' 'Ensure project guidance is readable before upgrading.'
  exit 1
}
# 将候选内容先暂存，再移动旧受管内容到持久备份，最后才替换；Workspace 始终被排除。
THEMIS_UPGRADE_BACKUP=$(mktemp -d "${THEMIS_UPGRADE_TARGET}/.themis-upgrade-backup.XXXXXX") || {
  themis_upgrade_error 'backup creation failed' 'Check target write access and available disk space.'
  exit 1
}
mkdir "${THEMIS_UPGRADE_BACKUP}/managed" || themis_upgrade_transaction_failed 'backup preparation failed' 'Check target write access and available disk space.'
THEMIS_UPGRADE_STAGE=$(mktemp -d "${THEMIS_UPGRADE_TARGET}/.themis-upgrade-stage.XXXXXX") || themis_upgrade_transaction_failed 'staging creation failed' 'Check target write access and available disk space.'
mkdir "${THEMIS_UPGRADE_STAGE}/managed" || themis_upgrade_transaction_failed 'staging preparation failed' 'Check target write access and available disk space.'
THEMIS_UPGRADE_TRANSACTION=1

themis_upgrade_copy_managed_entries "${THEMIS_UPGRADE_TEMPLATE_SOURCE}" "${THEMIS_UPGRADE_STAGE}/managed" || themis_upgrade_transaction_failed 'candidate staging failed' 'Check candidate readability and available disk space.'
for themis_upgrade_stage_entry in "${THEMIS_UPGRADE_STAGE}/managed"/.[!.]* "${THEMIS_UPGRADE_STAGE}/managed"/..?* "${THEMIS_UPGRADE_STAGE}/managed"/*; do
  [ -e "${themis_upgrade_stage_entry}" ] || [ -L "${themis_upgrade_stage_entry}" ] || continue
  themis_upgrade_stage_name=$(basename -- "${themis_upgrade_stage_entry}")
  [ "${themis_upgrade_stage_name}" = workspace ] && continue
  printf '%s\n' "${themis_upgrade_stage_name}"
done >"${THEMIS_UPGRADE_STAGE}/managed-names" || themis_upgrade_transaction_failed 'candidate staging inventory failed' 'Check target write access and available disk space.'
themis_upgrade_move_managed_entries "${THEMIS_UPGRADE_TARGET}/.themis" "${THEMIS_UPGRADE_BACKUP}/managed" || themis_upgrade_transaction_failed 'managed-content backup failed' 'Inspect target filesystem permissions and the retained backup.'
themis_upgrade_move_managed_entries "${THEMIS_UPGRADE_STAGE}/managed" "${THEMIS_UPGRADE_TARGET}/.themis" || themis_upgrade_transaction_failed 'managed-content replacement failed' 'Inspect target filesystem permissions and the retained backup.'
if [ "${THEMIS_UPGRADE_TEST_FAIL_AFTER_REPLACEMENT:-0}" = 1 ]; then
  themis_upgrade_transaction_failed 'simulated post-replacement failure' 'The previous managed content was restored.'
fi
if ! YQ="${THEMIS_UPGRADE_YQ}" bash "${THEMIS_UPGRADE_CHECKER}" --installed "${THEMIS_UPGRADE_TARGET}/.themis"; then
  themis_upgrade_transaction_failed 'upgraded template contract invalid' 'The previous managed content was restored.'
fi
THEMIS_UPGRADE_WORKSPACE_AFTER=$(themis_upgrade_workspace_fingerprint "${THEMIS_UPGRADE_TARGET}/.themis/workspace") || themis_upgrade_transaction_failed 'Workspace verification failed' 'The previous managed content was restored.'
THEMIS_UPGRADE_CLAUDE_AFTER=$(cksum "${THEMIS_UPGRADE_TARGET}/CLAUDE.md") || themis_upgrade_transaction_failed 'CLAUDE.md verification failed' 'The previous managed content was restored.'
if [ "${THEMIS_UPGRADE_WORKSPACE_AFTER}" != "${THEMIS_UPGRADE_WORKSPACE_FINGERPRINT}" ] || [ "${THEMIS_UPGRADE_CLAUDE_AFTER}" != "${THEMIS_UPGRADE_CLAUDE_FINGERPRINT}" ]; then
  themis_upgrade_transaction_failed 'ownership-boundary verification failed' 'The previous managed content was restored.'
fi

rm -rf -- "${THEMIS_UPGRADE_STAGE}"
THEMIS_UPGRADE_STAGE=
THEMIS_UPGRADE_TRANSACTION=0
printf '%s\n' "Themis upgraded in ${THEMIS_UPGRADE_TARGET}" "  Backup retained: ${THEMIS_UPGRADE_BACKUP}"
