#!/usr/bin/env bash
#
# Themis 项目初始化器。
# 用途：向尚未安装 Themis 的项目复制已验证模板和 Themis-Q Project Skill，并向 CLAUDE.md 追加受管直接 import 块。
# 边界：仅支持全新 `.themis` 安装；安全合并 `.claude/skills/Themis-Q/`，同名冲突在写入前失败，不执行项目命令、不创建 SDD 产物，也不修改 AGENTS.md。
# 兼容性：保持 Bash 3.2 兼容，仅在 P0 前置条件通过后使用 mikefarah/yq v4。
#
THEMIS_INIT_GUIDANCE_START='<!-- themis:guidance:start -->'
THEMIS_INIT_GUIDANCE_END='<!-- themis:guidance:end -->'
THEMIS_INIT_GUIDANCE_BLOCK='<!-- themis:guidance:start -->
@import .themis/CLAUDE.themis.md
@import .themis/core/kernel/orchestrator/rules.md
<!-- themis:guidance:end -->'
THEMIS_INIT_GITIGNORE_START='# Themis — derived data (managed by themis-init)'
THEMIS_INIT_GITIGNORE_END='# Themis end'
THEMIS_INIT_GITIGNORE_BLOCK='# Themis — derived data (managed by themis-init)
.themis/workspace/cache/
.themis/workspace/state/sessions/
# Themis end'
THEMIS_INIT_TARGET=.
THEMIS_INIT_PROJECT_NAME=
THEMIS_INIT_LINT_COMMAND=
THEMIS_INIT_BUILD_COMMAND=
THEMIS_INIT_TEST_COMMAND=
THEMIS_INIT_PROJECT_NAME_SET=0
THEMIS_INIT_LINT_COMMAND_SET=0
THEMIS_INIT_BUILD_COMMAND_SET=0
THEMIS_INIT_TEST_COMMAND_SET=0
THEMIS_INIT_ASSUME_YES=0
THEMIS_INIT_CLAUDE_ACTION=append
THEMIS_INIT_GITIGNORE_ACTION=append
THEMIS_INIT_CLAUDE_BACKUP=
THEMIS_INIT_GITIGNORE_BACKUP=
THEMIS_INIT_CLAUDE_EXISTED=0
THEMIS_INIT_GITIGNORE_EXISTED=0
THEMIS_INIT_CREATED_TEMPLATE=0
THEMIS_INIT_CREATED_SKILL=0
THEMIS_INIT_CREATED_SKILLS_DIRECTORY=0
THEMIS_INIT_CREATED_CLAUDE_DIRECTORY=0

# 输出一条可操作的 Init 失败诊断。参数为简短主题和修复建议。
themis_init_error() {
  printf '%s\n' "Themis Init failed: ${1-unknown error}" "  Fix: ${2-Review the target project and retry.}" >&2
  return 1
}

# 输出稳定的命令帮助，不读取或修改目标项目。
themis_init_usage() {
  cat <<'EOF'
Usage: themis-init.sh [target] [options]

Initialize a fresh Themis installation in target (default: current directory).

Options:
  --yes                 Accept default project configuration values.
  --project-name <name> Set the Workspace project name.
  --lint <command>      Set the Workspace lint command.
  --build <command>     Set the Workspace build command.
  --test <command>      Set the Workspace test command.
  --help                Show this help text.
EOF
}

# 要求选项携带非空值，避免命令行参数产生歧义。
themis_init_option_value() {
  if [ -z "${2-}" ]; then
    themis_init_error "missing value for ${1}" "Pass a value after ${1}."
    return 1
  fi
  return 0
}

# 统计精确的受管标记行，在写入前发现局部或重复块。
themis_init_marker_count() {
  local themis_init_marker=$1
  local themis_init_file=$2

  sed -n "\|^${themis_init_marker}$|p" "${themis_init_file}" | wc -l | tr -d '[:space:]'
}

# 验证既有受管块，并把指定动作变量设为 append 或 skip；修改过的块必须由用户先处理。
themis_init_prepare_managed_block() {
  local themis_init_file=$1
  local themis_init_start=$2
  local themis_init_end=$3
  local themis_init_expected=$4
  local themis_init_action_name=$5
  local themis_init_start_count
  local themis_init_end_count
  local themis_init_actual_file
  local themis_init_expected_file

  if [ ! -e "${themis_init_file}" ]; then
    eval "${themis_init_action_name}=append"
    return 0
  fi
  if [ ! -f "${themis_init_file}" ]; then
    themis_init_error "managed file is not regular: ${themis_init_file}" 'Replace the path with a regular file or remove the conflicting path.'
    return 1
  fi

  themis_init_start_count=$(themis_init_marker_count "${themis_init_start}" "${themis_init_file}")
  themis_init_end_count=$(themis_init_marker_count "${themis_init_end}" "${themis_init_file}")
  if [ "${themis_init_start_count}" = 0 ] && [ "${themis_init_end_count}" = 0 ]; then
    eval "${themis_init_action_name}=append"
    return 0
  fi
  if [ "${themis_init_start_count}" != 1 ] || [ "${themis_init_end_count}" != 1 ]; then
    themis_init_error "invalid Themis markers in ${themis_init_file}" 'Keep exactly one complete, unmodified Themis block or remove all of its markers.'
    return 1
  fi

  themis_init_actual_file=$(mktemp "${THEMIS_INIT_TARGET}/.themis-init-block.XXXXXX") || return 1
  themis_init_expected_file=$(mktemp "${THEMIS_INIT_TARGET}/.themis-init-expected.XXXXXX") || {
    rm -f -- "${themis_init_actual_file}"
    return 1
  }
  sed -n "\|^${themis_init_start}$|,\|^${themis_init_end}$|p" "${themis_init_file}" >"${themis_init_actual_file}"
  printf '%s\n' "${themis_init_expected}" >"${themis_init_expected_file}"
  if ! cmp -s "${themis_init_actual_file}" "${themis_init_expected_file}"; then
    rm -f -- "${themis_init_actual_file}" "${themis_init_expected_file}"
    themis_init_error "modified Themis block in ${themis_init_file}" 'Restore the expected managed block or remove both markers before running Init.'
    return 1
  fi
  rm -f -- "${themis_init_actual_file}" "${themis_init_expected_file}"
  eval "${themis_init_action_name}=skip"
  return 0
}

# 在文件末尾追加完整受管块，并以空行隔开用户已有内容，保持既有内容为不变前缀。
themis_init_append_block() {
  local themis_init_file=$1
  local themis_init_block=$2

  if [ -e "${themis_init_file}" ] && [ -s "${themis_init_file}" ]; then
    printf '\n\n' >>"${themis_init_file}" || return 1
  fi
  printf '%s\n' "${themis_init_block}" >>"${themis_init_file}"
}

# 在 Init 修改文件前创建备份；缺失文件会单独记录，供回滚时仅删除本次新建的文件。
themis_init_backup_file() {
  local themis_init_file=$1
  local themis_init_backup_name=$2
  local themis_init_backup

  if [ -e "${themis_init_file}" ]; then
    themis_init_backup=$(mktemp "${THEMIS_INIT_TARGET}/.themis-init-backup.XXXXXX") || return 1
    cp -p -- "${themis_init_file}" "${themis_init_backup}" || {
      rm -f -- "${themis_init_backup}"
      return 1
    }
    eval "${themis_init_backup_name}=\"${themis_init_backup}\""
    eval "${themis_init_backup_name%_BACKUP}_EXISTED=1"
  fi
  return 0
}

# 恢复本次调用修改的文件，并仅删除本次创建的模板、Skill 与仍为空的父目录。
themis_init_rollback() {
  if [ "${THEMIS_INIT_CREATED_SKILL}" -eq 1 ]; then
    rm -rf -- "${THEMIS_INIT_TARGET}/.claude/skills/Themis-Q"
  fi
  if [ "${THEMIS_INIT_CREATED_SKILLS_DIRECTORY}" -eq 1 ]; then
    rmdir -- "${THEMIS_INIT_TARGET}/.claude/skills" 2>/dev/null || true
  fi
  if [ "${THEMIS_INIT_CREATED_CLAUDE_DIRECTORY}" -eq 1 ]; then
    rmdir -- "${THEMIS_INIT_TARGET}/.claude" 2>/dev/null || true
  fi
  if [ "${THEMIS_INIT_CREATED_TEMPLATE}" -eq 1 ]; then
    rm -rf -- "${THEMIS_INIT_TARGET}/.themis"
  fi
  if [ -n "${THEMIS_INIT_CLAUDE_BACKUP}" ]; then
    cp -p -- "${THEMIS_INIT_CLAUDE_BACKUP}" "${THEMIS_INIT_TARGET}/CLAUDE.md"
  elif [ "${THEMIS_INIT_CLAUDE_EXISTED}" -eq 0 ]; then
    rm -f -- "${THEMIS_INIT_TARGET}/CLAUDE.md"
  fi
  if [ -n "${THEMIS_INIT_GITIGNORE_BACKUP}" ]; then
    cp -p -- "${THEMIS_INIT_GITIGNORE_BACKUP}" "${THEMIS_INIT_TARGET}/.gitignore"
  elif [ "${THEMIS_INIT_GITIGNORE_EXISTED}" -eq 0 ]; then
    rm -f -- "${THEMIS_INIT_TARGET}/.gitignore"
  fi
  rm -f -- "${THEMIS_INIT_CLAUDE_BACKUP}" "${THEMIS_INIT_GITIGNORE_BACKUP}"
}

# 只有全部安装和校验成功后才删除临时备份。
themis_init_cleanup_backups() {
  rm -f -- "${THEMIS_INIT_CLAUDE_BACKUP}" "${THEMIS_INIT_GITIGNORE_BACKUP}"
}

# 在任何前置条件检查或文件系统操作前解析 CLI 参数。
themis_init_parse_arguments() {
  local themis_init_positional_seen=0

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --yes) THEMIS_INIT_ASSUME_YES=1 ;;
      --project-name)
        themis_init_option_value "$1" "${2-}" || return 1
        THEMIS_INIT_PROJECT_NAME=$2
        THEMIS_INIT_PROJECT_NAME_SET=1
        shift
        ;;
      --lint)
        themis_init_option_value "$1" "${2-}" || return 1
        THEMIS_INIT_LINT_COMMAND=$2
        THEMIS_INIT_LINT_COMMAND_SET=1
        shift
        ;;
      --build)
        themis_init_option_value "$1" "${2-}" || return 1
        THEMIS_INIT_BUILD_COMMAND=$2
        THEMIS_INIT_BUILD_COMMAND_SET=1
        shift
        ;;
      --test)
        themis_init_option_value "$1" "${2-}" || return 1
        THEMIS_INIT_TEST_COMMAND=$2
        THEMIS_INIT_TEST_COMMAND_SET=1
        shift
        ;;
      --help)
        themis_init_usage
        exit 0
        ;;
      --*)
        themis_init_error "unknown option: $1" 'Run with --help to see supported options.'
        return 1
        ;;
      *)
        if [ "${themis_init_positional_seen}" -eq 1 ]; then
          themis_init_error "unexpected target: $1" 'Pass at most one target directory.'
          return 1
        fi
        THEMIS_INIT_TARGET=$1
        themis_init_positional_seen=1
        ;;
    esac
    shift
  done
  return 0
}

# 仅收集项目特定设置；空命令保留 manifest 的 null 默认值，不虚构工具链。
themis_init_collect_inputs() {
  local themis_init_default_name
  local themis_init_response

  themis_init_default_name=$(basename -- "${THEMIS_INIT_TARGET}")
  if [ "${THEMIS_INIT_PROJECT_NAME_SET}" -eq 0 ]; then
    THEMIS_INIT_PROJECT_NAME=${themis_init_default_name}
  fi
  if [ "${THEMIS_INIT_ASSUME_YES}" -eq 1 ]; then
    return 0
  fi

  printf 'Project name [%s]: ' "${THEMIS_INIT_PROJECT_NAME}"
  IFS= read -r themis_init_response || return 1
  if [ -n "${themis_init_response}" ]; then
    THEMIS_INIT_PROJECT_NAME=${themis_init_response}
  fi

  if [ "${THEMIS_INIT_LINT_COMMAND_SET}" -eq 0 ]; then
    printf 'Lint command (leave empty for null): '
    IFS= read -r THEMIS_INIT_LINT_COMMAND || return 1
  fi
  if [ "${THEMIS_INIT_BUILD_COMMAND_SET}" -eq 0 ]; then
    printf 'Build command (leave empty for null): '
    IFS= read -r THEMIS_INIT_BUILD_COMMAND || return 1
  fi
  if [ "${THEMIS_INIT_TEST_COMMAND_SET}" -eq 0 ]; then
    printf 'Test command (leave empty for null): '
    IFS= read -r THEMIS_INIT_TEST_COMMAND || return 1
  fi
  return 0
}

# 只写入 Init 拥有的 manifest 字段，并用环境变量避免 YAML 引号问题。
themis_init_write_manifest() {
  local themis_init_manifest=$1

  export THEMIS_INIT_PROJECT_NAME THEMIS_INIT_LINT_COMMAND THEMIS_INIT_BUILD_COMMAND THEMIS_INIT_TEST_COMMAND
  yq eval -i '.project.name = strenv(THEMIS_INIT_PROJECT_NAME)' "${themis_init_manifest}" || return 1
  if [ -n "${THEMIS_INIT_LINT_COMMAND}" ]; then
    yq eval -i '.commands.lint = strenv(THEMIS_INIT_LINT_COMMAND)' "${themis_init_manifest}" || return 1
  fi
  if [ -n "${THEMIS_INIT_BUILD_COMMAND}" ]; then
    yq eval -i '.commands.build = strenv(THEMIS_INIT_BUILD_COMMAND)' "${themis_init_manifest}" || return 1
  fi
  if [ -n "${THEMIS_INIT_TEST_COMMAND}" ]; then
    yq eval -i '.commands.test = strenv(THEMIS_INIT_TEST_COMMAND)' "${themis_init_manifest}" || return 1
  fi
  return 0
}

# 相对脚本定位源仓库，并在复制前加载 P0 与执行完整源模板检查。
THEMIS_INIT_SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd) || exit 1
THEMIS_INIT_REPOSITORY_ROOT=$(CDPATH='' cd -- "${THEMIS_INIT_SCRIPT_DIR}/.." && pwd) || exit 1
THEMIS_INIT_TEMPLATE_SOURCE="${THEMIS_INIT_REPOSITORY_ROOT}/templates/.themis"
THEMIS_INIT_SKILL_SOURCE="${THEMIS_INIT_REPOSITORY_ROOT}/templates/.claude/skills/Themis-Q"
THEMIS_INIT_CHECKER="${THEMIS_INIT_REPOSITORY_ROOT}/bin/themis-template-check.sh"
# shellcheck source=bin/_themis-init-env.sh
. "${THEMIS_INIT_SCRIPT_DIR}/_themis-init-env.sh"

# 以下主流程先完成前置校验，再收集输入、备份、安装、验证；任一步失败均回滚可变内容。
themis_init_parse_arguments "$@" || exit 1
themis_init_require_environment || exit 1

if [ ! -d "${THEMIS_INIT_TARGET}" ]; then
  themis_init_error "target directory missing: ${THEMIS_INIT_TARGET}" 'Create the target directory before running Init.'
  exit 1
fi
THEMIS_INIT_TARGET=$(CDPATH='' cd -- "${THEMIS_INIT_TARGET}" && pwd) || exit 1
if [ ! -w "${THEMIS_INIT_TARGET}" ]; then
  themis_init_error "target directory is not writable: ${THEMIS_INIT_TARGET}" 'Choose a writable project directory.'
  exit 1
fi
if [ -e "${THEMIS_INIT_TARGET}/.themis" ]; then
  themis_init_error 'existing .themis installation' 'In-place updates are not supported. Preserve the existing Workspace and do not run Init over it.'
  exit 1
fi
if [ -e "${THEMIS_INIT_TARGET}/.claude/skills/Themis-Q" ]; then
  themis_init_error 'existing Themis-Q Skill path' 'Move or remove the conflicting .claude/skills/Themis-Q path before running Init; Init never overwrites project Skills.'
  exit 1
fi
if [ -e "${THEMIS_INIT_TARGET}/.claude" ] && [ ! -d "${THEMIS_INIT_TARGET}/.claude" ]; then
  themis_init_error 'conflicting .claude path' 'Replace the path with a directory or choose another project.'
  exit 1
fi
if [ -e "${THEMIS_INIT_TARGET}/.claude/skills" ] && [ ! -d "${THEMIS_INIT_TARGET}/.claude/skills" ]; then
  themis_init_error 'conflicting .claude/skills path' 'Replace the path with a directory or choose another project.'
  exit 1
fi
if ! bash "${THEMIS_INIT_CHECKER}" "${THEMIS_INIT_TEMPLATE_SOURCE}"; then
  themis_init_error 'source template contract invalid' 'Repair the source template before initializing a project.'
  exit 1
fi

themis_init_collect_inputs || {
  themis_init_error 'interactive input unavailable' 'Run with --yes or provide standard input for project settings.'
  exit 1
}
themis_init_prepare_managed_block "${THEMIS_INIT_TARGET}/CLAUDE.md" "${THEMIS_INIT_GUIDANCE_START}" "${THEMIS_INIT_GUIDANCE_END}" "${THEMIS_INIT_GUIDANCE_BLOCK}" THEMIS_INIT_CLAUDE_ACTION || exit 1
themis_init_prepare_managed_block "${THEMIS_INIT_TARGET}/.gitignore" "${THEMIS_INIT_GITIGNORE_START}" "${THEMIS_INIT_GITIGNORE_END}" "${THEMIS_INIT_GITIGNORE_BLOCK}" THEMIS_INIT_GITIGNORE_ACTION || exit 1

themis_init_backup_file "${THEMIS_INIT_TARGET}/CLAUDE.md" THEMIS_INIT_CLAUDE_BACKUP || exit 1
themis_init_backup_file "${THEMIS_INIT_TARGET}/.gitignore" THEMIS_INIT_GITIGNORE_BACKUP || {
  themis_init_cleanup_backups
  exit 1
}

if ! cp -R "${THEMIS_INIT_TEMPLATE_SOURCE}" "${THEMIS_INIT_TARGET}/.themis"; then
  themis_init_rollback
  themis_init_error 'template copy failed' 'Check target write access and available disk space.'
  exit 1
fi
THEMIS_INIT_CREATED_TEMPLATE=1
if [ ! -d "${THEMIS_INIT_TARGET}/.claude" ]; then
  if ! mkdir "${THEMIS_INIT_TARGET}/.claude"; then
    themis_init_rollback
    themis_init_error 'Skill parent creation failed' 'Check target write access for .claude/.'
    exit 1
  fi
  THEMIS_INIT_CREATED_CLAUDE_DIRECTORY=1
fi
if [ ! -d "${THEMIS_INIT_TARGET}/.claude/skills" ]; then
  if ! mkdir "${THEMIS_INIT_TARGET}/.claude/skills"; then
    themis_init_rollback
    themis_init_error 'Skill directory creation failed' 'Check target write access for .claude/skills/.'
    exit 1
  fi
  THEMIS_INIT_CREATED_SKILLS_DIRECTORY=1
fi
if ! cp -R "${THEMIS_INIT_SKILL_SOURCE}" "${THEMIS_INIT_TARGET}/.claude/skills/Themis-Q"; then
  themis_init_rollback
  themis_init_error 'Themis-Q Skill copy failed' 'Check target write access and the source Skill bundle.'
  exit 1
fi
THEMIS_INIT_CREATED_SKILL=1
if [ "${THEMIS_INIT_TEST_FAIL_AFTER_SKILL:-0}" -eq 1 ]; then
  themis_init_rollback
  themis_init_error 'injected failure after Skill copy' 'Disable the test failure injection and retry.'
  exit 1
fi
if ! themis_init_write_manifest "${THEMIS_INIT_TARGET}/.themis/workspace/manifest.yaml"; then
  themis_init_rollback
  themis_init_error 'manifest update failed' 'Check yq output and the copied Workspace manifest.'
  exit 1
fi
if [ "${THEMIS_INIT_CLAUDE_ACTION}" = append ] && ! themis_init_append_block "${THEMIS_INIT_TARGET}/CLAUDE.md" "${THEMIS_INIT_GUIDANCE_BLOCK}"; then
  themis_init_rollback
  themis_init_error 'CLAUDE.md update failed' 'Check project guidance file permissions.'
  exit 1
fi
if [ "${THEMIS_INIT_GITIGNORE_ACTION}" = append ] && ! themis_init_append_block "${THEMIS_INIT_TARGET}/.gitignore" "${THEMIS_INIT_GITIGNORE_BLOCK}"; then
  themis_init_rollback
  themis_init_error '.gitignore update failed' 'Check project ignore file permissions.'
  exit 1
fi
if ! bash "${THEMIS_INIT_CHECKER}" --installed "${THEMIS_INIT_TARGET}/.themis"; then
  themis_init_rollback
  themis_init_error 'installed template contract invalid' 'Inspect the source template and retry the installation.'
  exit 1
fi

themis_init_cleanup_backups
printf 'Themis initialized in %s\n' "${THEMIS_INIT_TARGET}"
