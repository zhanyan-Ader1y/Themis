#!/usr/bin/env bash
#
# Themis 显式迁移执行器。
# 用途：在 P4 Upgrade 因 Schema 不兼容而拒绝升级后，由用户显式触发 Workspace/Artifact 迁移。
# 边界：迁移是独立于 Upgrade 事务的用户决策；不修改任何 Core 内容，也不跳过备份或用户确认。
# 兼容性：保持 Bash 3.2 兼容；独立要求 mikefarah/yq v4；不加载 P0 或 Init。
#
set -euo pipefail

THEMIS_MIGRATE_TARGET=.
THEMIS_MIGRATE_ACTION=
THEMIS_MIGRATE_MIGRATION_ID=
THEMIS_MIGRATE_BACKUP_PATH=
THEMIS_MIGRATE_DRY_RUN=0

# 输出一条可操作的迁移失败诊断。
themis_migrate_error() {
  printf '%s\n' "Themis Migrate failed: ${1-unknown error}" "  Fix: ${2-Review the migration state and retry.}" >&2
  return 1
}

# 输出稳定的命令帮助。
themis_migrate_usage() {
  cat <<'EOF'
Usage: themis-migrate.sh <target> <action> [options]

Execute an explicit Workspace and Artifact migration when Upgrade refuses
an incompatible Schema.  Migrations require user confirmation and a
complete Workspace backup before any change.

Actions:
  --check               List available migration descriptors, output JSON.
  --backup              Create a full Workspace backup under a persistent path.
  --run                 Execute one migration script.
    --migration-id <id>   Migration identifier (format "from→to").
  --verify              Verify post-migration Workspace integrity.
  --rollback            Restore Workspace from a backup.
    --backup-path <path>  Path to the backup directory.
  --dry-run             Report planned actions without writing anything.
  --help                Show this help text.

All actions operate on <target> (default: current directory).
EOF
}

# 要求选项携带非空值。
themis_migrate_option_value() {
  if [ -z "${2-}" ]; then
    themis_migrate_error "missing value for ${1}" "Pass a value after ${1}."
    return 1
  fi
  return 0
}

# 独立校验 mikefarah/yq v4，不加载 P0。
themis_migrate_require_yq() {
  local themis_migrate_yq_version
  if ! command -v yq >/dev/null 2>&1; then
    themis_migrate_error 'yq not found' 'Install mikefarah/yq v4 (https://github.com/mikefarah/yq).'
    return 1
  fi
  themis_migrate_yq_version=$(yq --version 2>&1 || true)
  case "${themis_migrate_yq_version}" in
    *mikefarah/yq*version\ v4.*) ;;
    *)
      themis_migrate_error 'unsupported yq implementation' 'Install mikefarah/yq v4.'
      return 1
      ;;
  esac
  return 0
}

# 解析命令行参数。
themis_migrate_parse_arguments() {
  local themis_migrate_positional_seen=0

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --check|--backup|--verify|--rollback|--dry-run)
        if [ -n "${THEMIS_MIGRATE_ACTION}" ]; then
          themis_migrate_error "only one action allowed" "Pass a single action from the supported list."
          return 1
        fi
        THEMIS_MIGRATE_ACTION=$1
        ;;
      --run)
        if [ -n "${THEMIS_MIGRATE_ACTION}" ]; then
          themis_migrate_error "only one action allowed" "Pass a single action from the supported list."
          return 1
        fi
        THEMIS_MIGRATE_ACTION=$1
        ;;
      --migration-id)
        themis_migrate_option_value "$1" "${2-}" || return 1
        THEMIS_MIGRATE_MIGRATION_ID=$2
        shift
        ;;
      --backup-path)
        themis_migrate_option_value "$1" "${2-}" || return 1
        THEMIS_MIGRATE_BACKUP_PATH=$2
        shift
        ;;
      --help)
        themis_migrate_usage
        exit 0
        ;;
      --*)
        themis_migrate_error "unknown option: $1" 'Run with --help to see supported options.'
        return 1
        ;;
      *)
        if [ "${themis_migrate_positional_seen}" -eq 1 ]; then
          themis_migrate_error "unexpected argument: $1" 'Pass at most one target directory.'
          return 1
        fi
        THEMIS_MIGRATE_TARGET=$1
        themis_migrate_positional_seen=1
        ;;
    esac
    shift
  done

  if [ -z "${THEMIS_MIGRATE_ACTION}" ]; then
    themis_migrate_error 'no action specified' 'Pass --check, --backup, --run, --verify, --rollback, --dry-run, or --help.'
    return 1
  fi
  return 0
}

# 从候选 core.yaml 中查找匹配已安装 Schema 的迁移描述符。
# 输出 JSON: {"workspace_migrations":[...],"artifact_migrations":[...]}
themis_migrate_find_descriptors() {
  local themis_migrate_manifest
  local themis_migrate_core
  local themis_migrate_workspace_schema
  local themis_migrate_artifact_schema
  local themis_migrate_workspace_migrations
  local themis_migrate_artifact_migrations
  local themis_migrate_migration
  local themis_migrate_from
  local themis_migrate_to
  local themis_migrate_path
  local themis_migrate_reversible
  local themis_migrate_count

  themis_migrate_manifest="${THEMIS_MIGRATE_TARGET}/.themis/workspace/manifest.yaml"
  themis_migrate_core="${THEMIS_MIGRATE_TARGET}/.themis/core/core.yaml"

  if [ ! -f "${themis_migrate_manifest}" ]; then
    themis_migrate_error 'manifest not found' "Ensure ${themis_migrate_manifest} exists."
    return 1
  fi
  if [ ! -f "${themis_migrate_core}" ]; then
    themis_migrate_error 'core.yaml not found' "Ensure ${themis_migrate_core} exists."
    return 1
  fi

  THEMIS_MIGRATE_WORKSPACE_SCHEMA=$(yq eval '.workspace_schema' "${themis_migrate_manifest}")
  THEMIS_MIGRATE_ARTIFACT_SCHEMA=$(yq eval '.artifact_schema' "${themis_migrate_manifest}")

  # 收集 Workspace 迁移
  themis_migrate_workspace_migrations='[]'
  themis_migrate_count=$(yq eval '.compatibility.workspace.migrations | length' "${themis_migrate_core}")
  if [ "${themis_migrate_count}" -gt 0 ]; then
    themis_migrate_workspace_migrations='['
    local themis_migrate_first_ws=1
    local themis_migrate_i=0
    while [ "${themis_migrate_i}" -lt "${themis_migrate_count}" ]; do
      themis_migrate_from=$(yq eval ".compatibility.workspace.migrations[${themis_migrate_i}].from" "${themis_migrate_core}")
      if [ "${themis_migrate_from}" = "${THEMIS_MIGRATE_WORKSPACE_SCHEMA}" ]; then
        themis_migrate_to=$(yq eval ".compatibility.workspace.migrations[${themis_migrate_i}].to" "${themis_migrate_core}")
        themis_migrate_path=$(yq eval ".compatibility.workspace.migrations[${themis_migrate_i}].path" "${themis_migrate_core}")
        themis_migrate_reversible=$(yq eval ".compatibility.workspace.migrations[${themis_migrate_i}].reversible" "${themis_migrate_core}")
        if [ "${themis_migrate_first_ws}" -eq 0 ]; then
          themis_migrate_workspace_migrations="${themis_migrate_workspace_migrations},"
        fi
        themis_migrate_first_ws=0
        themis_migrate_workspace_migrations="${themis_migrate_workspace_migrations}{\"from\":\"${themis_migrate_from}\",\"to\":\"${themis_migrate_to}\",\"path\":\"${themis_migrate_path}\",\"reversible\":${themis_migrate_reversible}}"
      fi
      themis_migrate_i=$((themis_migrate_i + 1))
    done
    themis_migrate_workspace_migrations="${themis_migrate_workspace_migrations}]"
  fi

  # 收集 Artifact 迁移
  themis_migrate_artifact_migrations='[]'
  themis_migrate_count=$(yq eval '.compatibility.artifact.migrations | length' "${themis_migrate_core}")
  if [ "${themis_migrate_count}" -gt 0 ]; then
    themis_migrate_artifact_migrations='['
    local themis_migrate_first_ar=1
    local themis_migrate_j=0
    while [ "${themis_migrate_j}" -lt "${themis_migrate_count}" ]; do
      themis_migrate_from=$(yq eval ".compatibility.artifact.migrations[${themis_migrate_j}].from" "${themis_migrate_core}")
      if [ "${themis_migrate_from}" = "${THEMIS_MIGRATE_ARTIFACT_SCHEMA}" ]; then
        themis_migrate_to=$(yq eval ".compatibility.artifact.migrations[${themis_migrate_j}].to" "${themis_migrate_core}")
        themis_migrate_path=$(yq eval ".compatibility.artifact.migrations[${themis_migrate_j}].path" "${themis_migrate_core}")
        themis_migrate_reversible=$(yq eval ".compatibility.artifact.migrations[${themis_migrate_j}].reversible" "${themis_migrate_core}")
        if [ "${themis_migrate_first_ar}" -eq 0 ]; then
          themis_migrate_artifact_migrations="${themis_migrate_artifact_migrations},"
        fi
        themis_migrate_first_ar=0
        themis_migrate_artifact_migrations="${themis_migrate_artifact_migrations}{\"from\":\"${themis_migrate_from}\",\"to\":\"${themis_migrate_to}\",\"path\":\"${themis_migrate_path}\",\"reversible\":${themis_migrate_reversible}}"
      fi
      themis_migrate_j=$((themis_migrate_j + 1))
    done
    themis_migrate_artifact_migrations="${themis_migrate_artifact_migrations}]"
  fi

  printf '{"workspace_migrations":%s,"artifact_migrations":%s}\n' \
    "${themis_migrate_workspace_migrations}" "${themis_migrate_artifact_migrations}"
  return 0
}

# 创建 workspace/ 完整备份。输出 JSON: {"backup_path":"...","files_count":N}
themis_migrate_create_backup() {
  local themis_migrate_backup
  local themis_migrate_workspace
  local themis_migrate_file_count

  themis_migrate_workspace="${THEMIS_MIGRATE_TARGET}/.themis/workspace"

  if [ ! -d "${themis_migrate_workspace}" ]; then
    themis_migrate_error 'workspace directory missing' "Ensure ${themis_migrate_workspace} exists before backup."
    return 1
  fi

  themis_migrate_backup=$(mktemp -d "${THEMIS_MIGRATE_TARGET}/.themis-migration-backup.XXXXXX") || {
    themis_migrate_error 'backup directory creation failed' 'Check target write access and available disk space.'
    return 1
  }

  if [ "${THEMIS_MIGRATE_DRY_RUN}" -eq 1 ]; then
    printf '{"backup_path":"%s","files_count":0,"dry_run":true}\n' "${themis_migrate_backup}"
    rm -rf "${themis_migrate_backup}"
    return 0
  fi

  cp -R "${themis_migrate_workspace}" "${themis_migrate_backup}/workspace" || {
    rm -rf "${themis_migrate_backup}"
    themis_migrate_error 'backup copy failed' 'Check available disk space and permissions.'
    return 1
  }

  themis_migrate_file_count=$(find "${themis_migrate_backup}/workspace" -type f | wc -l | tr -d '[:space:]')
  printf '{"backup_path":"%s","files_count":%s}\n' "${themis_migrate_backup}" "${themis_migrate_file_count}"
  return 0
}

# 执行一个迁移脚本。
# 调用 core/migrations/<path>.sh <workspace_path>，收集 JSON 输出。
themis_migrate_run_one() {
  local themis_migrate_id=$1
  local themis_migrate_core
  local themis_migrate_workspace
  local themis_migrate_from
  local themis_migrate_to
  local themis_migrate_path
  local themis_migrate_count
  local themis_migrate_i
  local themis_migrate_candidate_from
  local themis_migrate_script
  local themis_migrate_result
  local themis_migrate_status

  themis_migrate_core="${THEMIS_MIGRATE_TARGET}/.themis/core/core.yaml"
  themis_migrate_workspace="${THEMIS_MIGRATE_TARGET}/.themis/workspace"

  # 从 migration_id 解析 from→to
  themis_migrate_from="${themis_migrate_id%%→*}"
  themis_migrate_to="${themis_migrate_id##*→}"

  # 在 Workspace migrations 中查找匹配的迁移描述符
  themis_migrate_path=
  themis_migrate_count=$(yq eval '.compatibility.workspace.migrations | length' "${themis_migrate_core}")
  themis_migrate_i=0
  while [ "${themis_migrate_i}" -lt "${themis_migrate_count}" ]; do
    themis_migrate_candidate_from=$(yq eval ".compatibility.workspace.migrations[${themis_migrate_i}].from" "${themis_migrate_core}")
    if [ "${themis_migrate_candidate_from}" = "${themis_migrate_from}" ]; then
      themis_migrate_path=$(yq eval ".compatibility.workspace.migrations[${themis_migrate_i}].path" "${themis_migrate_core}")
      break
    fi
    themis_migrate_i=$((themis_migrate_i + 1))
  done

  if [ -z "${themis_migrate_path}" ]; then
    # 在 Artifact migrations 中查找
    themis_migrate_count=$(yq eval '.compatibility.artifact.migrations | length' "${themis_migrate_core}")
    themis_migrate_i=0
    while [ "${themis_migrate_i}" -lt "${themis_migrate_count}" ]; do
      themis_migrate_candidate_from=$(yq eval ".compatibility.artifact.migrations[${themis_migrate_i}].from" "${themis_migrate_core}")
      if [ "${themis_migrate_candidate_from}" = "${themis_migrate_from}" ]; then
        themis_migrate_path=$(yq eval ".compatibility.artifact.migrations[${themis_migrate_i}].path" "${themis_migrate_core}")
        break
      fi
      themis_migrate_i=$((themis_migrate_i + 1))
    done
  fi

  if [ -z "${themis_migrate_path}" ]; then
    themis_migrate_error "no migration descriptor found for ${themis_migrate_id}" 'Run --check to see available migrations.'
    return 1
  fi

  themis_migrate_script="${THEMIS_MIGRATE_TARGET}/.themis/core/${themis_migrate_path}"

  if [ ! -f "${themis_migrate_script}" ]; then
    themis_migrate_error "migration script not found: ${themis_migrate_script}" 'Ensure the migration script exists under core/migrations/ .'
    return 1
  fi

  if [ ! -x "${themis_migrate_script}" ]; then
    themis_migrate_error "migration script not executable: ${themis_migrate_script}" 'Ensure the script has execute permission.'
    return 1
  fi

  if [ "${THEMIS_MIGRATE_DRY_RUN}" -eq 1 ]; then
    printf '{"status":"dry_run","migration_id":"%s","script":"%s"}\n' "${themis_migrate_id}" "${themis_migrate_path}"
    return 0
  fi

  themis_migrate_result=$("${themis_migrate_script}" "${themis_migrate_workspace}" 2>&1)
  themis_migrate_status=$?

  case "${themis_migrate_status}" in
    0)
      printf '%s\n' "${themis_migrate_result}"
      ;;
    2)
      printf '%s\n' "${themis_migrate_result}"
      return 0
      ;;
    *)
      themis_migrate_error "migration script failed with exit code ${themis_migrate_status}" "Script output: ${themis_migrate_result}"
      return 1
      ;;
  esac
  return 0
}

# 验证迁移后 Workspace 完整性。
themis_migrate_verify() {
  local themis_migrate_manifest
  local themis_migrate_errors

  themis_migrate_manifest="${THEMIS_MIGRATE_TARGET}/.themis/workspace/manifest.yaml"
  themis_migrate_errors=0

  # 检查 manifest 可读且包含必需的 schema 字段
  if ! yq eval '.workspace_schema' "${themis_migrate_manifest}" >/dev/null 2>&1; then
    printf '{"step":"manifest_schema","status":"fail","detail":"workspace_schema field missing or unreadable"}\n'
    themis_migrate_errors=$((themis_migrate_errors + 1))
  else
    printf '{"step":"manifest_schema","status":"pass"}\n'
  fi

  # 检查必需的 Workspace 目录
  for themis_migrate_dir in specs context state runs evidence outcomes knowledge policies; do
    if [ ! -d "${THEMIS_MIGRATE_TARGET}/.themis/workspace/${themis_migrate_dir}" ]; then
      printf '{"step":"directory_%s","status":"fail","detail":"missing directory"}\n' "${themis_migrate_dir}"
      themis_migrate_errors=$((themis_migrate_errors + 1))
    else
      printf '{"step":"directory_%s","status":"pass"}\n' "${themis_migrate_dir}"
    fi
  done

  if [ "${themis_migrate_errors}" -gt 0 ]; then
    return 1
  fi
  return 0
}

# 从备份恢复 Workspace。
themis_migrate_restore_backup() {
  local themis_migrate_backup=$1
  local themis_migrate_workspace

  if [ ! -d "${themis_migrate_backup}" ]; then
    themis_migrate_error "backup directory not found: ${themis_migrate_backup}" 'Provide a valid backup path with --backup-path.'
    return 1
  fi

  if [ ! -d "${themis_migrate_backup}/workspace" ]; then
    themis_migrate_error "invalid backup: no workspace/ inside ${themis_migrate_backup}" 'The backup does not contain a workspace directory.'
    return 1
  fi

  themis_migrate_workspace="${THEMIS_MIGRATE_TARGET}/.themis/workspace"

  if [ "${THEMIS_MIGRATE_DRY_RUN}" -eq 1 ]; then
    printf '{"action":"rollback","backup_path":"%s","target":"%s","dry_run":true}\n' \
      "${themis_migrate_backup}" "${themis_migrate_workspace}"
    return 0
  fi

  rm -rf "${themis_migrate_workspace}"
  cp -R "${themis_migrate_backup}/workspace" "${themis_migrate_workspace}" || {
    themis_migrate_error 'rollback restore failed' "Backup is still available at ${themis_migrate_backup}. Retry or restore manually."
    return 1
  }

  printf '{"action":"rollback","status":"success","backup_path":"%s"}\n' "${themis_migrate_backup}"
  return 0
}

# 主入口。
themis_migrate_main() {
  case "${THEMIS_MIGRATE_ACTION}" in
    --help)
      themis_migrate_usage
      exit 0
      ;;
    --dry-run)
      THEMIS_MIGRATE_DRY_RUN=1
      themis_migrate_find_descriptors
      ;;
    --check)
      themis_migrate_find_descriptors
      ;;
    --backup)
      themis_migrate_create_backup
      ;;
    --run)
      if [ -z "${THEMIS_MIGRATE_MIGRATION_ID}" ]; then
        themis_migrate_error '--migration-id required for --run' 'Pass --migration-id "from→to".'
        exit 1
      fi
      themis_migrate_run_one "${THEMIS_MIGRATE_MIGRATION_ID}"
      ;;
    --verify)
      themis_migrate_verify
      ;;
    --rollback)
      if [ -z "${THEMIS_MIGRATE_BACKUP_PATH}" ]; then
        themis_migrate_error '--backup-path required for --rollback' 'Pass the backup directory path.'
        exit 1
      fi
      themis_migrate_restore_backup "${THEMIS_MIGRATE_BACKUP_PATH}"
      ;;
    *)
      themis_migrate_error "unknown action: ${THEMIS_MIGRATE_ACTION}" 'Run --help for supported actions.'
      exit 1
      ;;
  esac
}

# 从脚本位置定位源仓库。
THEMIS_MIGRATE_SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd) || exit 1

themis_migrate_parse_arguments "$@" || exit 1
themis_migrate_require_yq || exit 1

if [ ! -d "${THEMIS_MIGRATE_TARGET}" ]; then
  themis_migrate_error "target directory missing: ${THEMIS_MIGRATE_TARGET}" 'Create or specify an installed Themis project.'
  exit 1
fi
THEMIS_MIGRATE_TARGET=$(CDPATH='' cd -- "${THEMIS_MIGRATE_TARGET}" && pwd) || exit 1

if [ ! -d "${THEMIS_MIGRATE_TARGET}/.themis" ]; then
  themis_migrate_error 'no .themis installation found' 'Run Themis Init before attempting migration.'
  exit 1
fi

themis_migrate_main
