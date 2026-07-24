#!/usr/bin/env bash
#
# Themis Init 环境前置条件库。
# 用途：在安装开始前无副作用地校验 Bash、Git 与 mikefarah/yq v4。
# 边界：仅供 Init source；不得由 Upgrade、Core、Workspace 或常规 SDD 流程加载，也不安装依赖或修改文件。
# 兼容性：保持 Bash 3.2 兼容，不使用关联数组、mapfile、coproc 等 Bash 4+ 特性。
#
if [ -z "${BASH_VERSION-}" ]; then
  printf '%s\n' \
    'Themis Init prerequisite failed: Bash' \
    '  Required: Bash 3.2.0 or newer' \
    '  Detected: not Bash' \
    '  Reason: unsupported implementation' \
    '  Install: Install Bash 3.2 or newer and run Themis Init with it.' >&2
  return 1 2>/dev/null || exit 1
fi

if [ "${BASH_VERSINFO[0]}" -lt 3 ] ||
  { [ "${BASH_VERSINFO[0]}" -eq 3 ] && [ "${BASH_VERSINFO[1]}" -lt 2 ]; }; then
  printf '%s\n' \
    'Themis Init prerequisite failed: Bash' \
    '  Required: Bash 3.2.0 or newer' \
    "  Detected: ${BASH_VERSION}" \
    '  Reason: version too old' \
    '  Install: Install Bash 3.2 or newer and run Themis Init with it.' >&2
  return 1 2>/dev/null || exit 1
fi

# 输出稳定的五行依赖诊断。参数依次为工具、要求、检测结果、失败原因和安装建议，供 Init 与测试复用。
themis_init_print_dependency_error() {
  local themis_init_error_tool="${1-}"
  local themis_init_error_required="${2-}"
  local themis_init_error_detected="${3-}"
  local themis_init_error_reason="${4-}"
  local themis_init_error_install="${5-}"

  printf '%s\n' \
    "Themis Init prerequisite failed: ${themis_init_error_tool}" \
    "  Required: ${themis_init_error_required}" \
    "  Detected: ${themis_init_error_detected}" \
    "  Reason: ${themis_init_error_reason}" \
    "  Install: ${themis_init_error_install}" >&2
}

# 比较实际版本与最低版本。接受 major.minor[.patch]；返回 0 表示满足、1 表示过旧、2 表示格式不可读。
themis_init_version_at_least() {
  local themis_init_actual="${1-}"
  local themis_init_minimum="${2-}"
  local themis_init_actual_major
  local themis_init_actual_minor
  local themis_init_actual_patch
  local themis_init_actual_rest
  local themis_init_minimum_major
  local themis_init_minimum_minor
  local themis_init_minimum_patch
  local themis_init_minimum_rest

  case "${themis_init_actual}" in
    *.*) ;;
    *) return 2 ;;
  esac

  themis_init_actual_major=${themis_init_actual%%.*}
  themis_init_actual_rest=${themis_init_actual#*.}
  case "${themis_init_actual_rest}" in
    *.*)
      themis_init_actual_minor=${themis_init_actual_rest%%.*}
      themis_init_actual_patch=${themis_init_actual_rest#*.}
      case "${themis_init_actual_patch}" in
        *.*) return 2 ;;
      esac
      ;;
    *)
      themis_init_actual_minor=${themis_init_actual_rest}
      themis_init_actual_patch=0
      ;;
  esac

  case "${themis_init_minimum}" in
    *.*) ;;
    *) return 2 ;;
  esac

  themis_init_minimum_major=${themis_init_minimum%%.*}
  themis_init_minimum_rest=${themis_init_minimum#*.}
  case "${themis_init_minimum_rest}" in
    *.*)
      themis_init_minimum_minor=${themis_init_minimum_rest%%.*}
      themis_init_minimum_patch=${themis_init_minimum_rest#*.}
      case "${themis_init_minimum_patch}" in
        *.*) return 2 ;;
      esac
      ;;
    *)
      themis_init_minimum_minor=${themis_init_minimum_rest}
      themis_init_minimum_patch=0
      ;;
  esac

  if [ -z "${themis_init_actual_major}" ] ||
    [ -z "${themis_init_actual_minor}" ] ||
    [ -z "${themis_init_actual_patch}" ] ||
    [ -z "${themis_init_minimum_major}" ] ||
    [ -z "${themis_init_minimum_minor}" ] ||
    [ -z "${themis_init_minimum_patch}" ]; then
    return 2
  fi

  case "${themis_init_actual_major}:${themis_init_actual_minor}:${themis_init_actual_patch}:${themis_init_minimum_major}:${themis_init_minimum_minor}:${themis_init_minimum_patch}" in
    *[!0-9:]*) return 2 ;;
  esac

  if [ "${themis_init_actual_major}" -gt "${themis_init_minimum_major}" ]; then
    return 0
  fi
  if [ "${themis_init_actual_major}" -lt "${themis_init_minimum_major}" ]; then
    return 1
  fi
  if [ "${themis_init_actual_minor}" -gt "${themis_init_minimum_minor}" ]; then
    return 0
  fi
  if [ "${themis_init_actual_minor}" -lt "${themis_init_minimum_minor}" ]; then
    return 1
  fi
  if [ "${themis_init_actual_patch}" -ge "${themis_init_minimum_patch}" ]; then
    return 0
  fi

  return 1
}

# 校验当前执行 Init 的 Bash 是否至少为 3.2；不启动子 Shell，避免检查到与实际解释器不同的版本。
themis_init_check_bash() {
  local themis_init_bash_version
  local themis_init_bash_install
  local themis_init_bash_status

  case "${OSTYPE-}" in
    darwin*) themis_init_bash_install='Install a newer Bash with Homebrew and run Init with it.' ;;
    linux*) themis_init_bash_install='Install Bash 3.2 or newer with your system package manager.' ;;
    msys*|cygwin*|win32*) themis_init_bash_install='Upgrade Git for Windows to update Git Bash.' ;;
    *) themis_init_bash_install='Install Bash 3.2 or newer.' ;;
  esac

  if [ -z "${BASH_VERSION-}" ]; then
    themis_init_print_dependency_error \
      'Bash' \
      'Bash 3.2.0 or newer' \
      'not Bash' \
      'unsupported implementation' \
      "${themis_init_bash_install}"
    return 1
  fi

  if [ -n "${BASH_VERSINFO[0]-}" ] && [ -n "${BASH_VERSINFO[1]-}" ] && [ -n "${BASH_VERSINFO[2]-}" ]; then
    themis_init_bash_version="${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}.${BASH_VERSINFO[2]}"
  elif [[ "${BASH_VERSION}" =~ ^([0-9]+)\.([0-9]+)(\.([0-9]+))? ]]; then
    themis_init_bash_version="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[4]:-0}"
  else
    themis_init_print_dependency_error \
      'Bash' \
      'Bash 3.2.0 or newer' \
      'version output unreadable' \
      'version unreadable' \
      "${themis_init_bash_install}"
    return 1
  fi

  themis_init_version_at_least "${themis_init_bash_version}" '3.2.0'
  themis_init_bash_status=$?
  if [ "${themis_init_bash_status}" -eq 0 ]; then
    return 0
  fi

  if [ "${themis_init_bash_status}" -eq 2 ]; then
    themis_init_print_dependency_error \
      'Bash' \
      'Bash 3.2.0 or newer' \
      "${themis_init_bash_version}" \
      'version unreadable' \
      "${themis_init_bash_install}"
  else
    themis_init_print_dependency_error \
      'Bash' \
      'Bash 3.2.0 or newer' \
      "${themis_init_bash_version}" \
      'version too old' \
      "${themis_init_bash_install}"
  fi
  return 1
}

# 校验 Git 命令存在且版本不低于 2.0；此前置阶段只读取身份与版本，不执行仓库操作。
themis_init_check_git() {
  local themis_init_git_output
  local themis_init_git_status
  local themis_init_git_version
  local themis_init_git_install

  case "${OSTYPE-}" in
    darwin*) themis_init_git_install='Install Git with Homebrew: brew install git' ;;
    linux*) themis_init_git_install='Install Git 2.0 or newer with your system package manager.' ;;
    msys*|cygwin*|win32*) themis_init_git_install='Install or upgrade Git for Windows.' ;;
    *) themis_init_git_install='Install Git 2.0 or newer.' ;;
  esac

  if ! command -v git >/dev/null 2>&1; then
    themis_init_print_dependency_error \
      'Git' \
      'Git 2.0.0 or newer' \
      'not found' \
      'missing' \
      "${themis_init_git_install}"
    return 1
  fi

  themis_init_git_output=$(git --version 2>&1)
  themis_init_git_status=$?
  if [ "${themis_init_git_status}" -ne 0 ]; then
    themis_init_print_dependency_error \
      'Git' \
      'Git 2.0.0 or newer' \
      'version command failed' \
      'version unreadable' \
      "${themis_init_git_install}"
    return 1
  fi

  if [[ "${themis_init_git_output}" =~ ^git[[:space:]]version[[:space:]]([0-9]+)\.([0-9]+)(\.([0-9]+))?([^0-9].*)?$ ]]; then
    themis_init_git_version="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[4]:-0}"
  else
    themis_init_print_dependency_error \
      'Git' \
      'Git 2.0.0 or newer' \
      'version output unreadable' \
      'version unreadable' \
      "${themis_init_git_install}"
    return 1
  fi

  themis_init_version_at_least "${themis_init_git_version}" '2.0.0'
  themis_init_git_status=$?
  if [ "${themis_init_git_status}" -eq 0 ]; then
    return 0
  fi

  if [ "${themis_init_git_status}" -eq 2 ]; then
    themis_init_print_dependency_error \
      'Git' \
      'Git 2.0.0 or newer' \
      "${themis_init_git_version}" \
      'version unreadable' \
      "${themis_init_git_install}"
  else
    themis_init_print_dependency_error \
      'Git' \
      'Git 2.0.0 or newer' \
      "${themis_init_git_version}" \
      'version too old' \
      "${themis_init_git_install}"
  fi
  return 1
}

# 校验 yq 为 mikefarah/yq v4.0.0+；同名实现和未经验证的未来大版本均不可接受。
themis_init_check_yq() {
  local themis_init_yq_output
  local themis_init_yq_status
  local themis_init_yq_version
  local themis_init_yq_major
  local themis_init_yq_install

  case "${OSTYPE-}" in
    darwin*) themis_init_yq_install='Install mikefarah/yq v4 with Homebrew: brew install yq' ;;
    linux*) themis_init_yq_install='Install mikefarah/yq v4 from https://github.com/mikefarah/yq/releases or a verified distribution package.' ;;
    msys*|cygwin*|win32*) themis_init_yq_install='Download mikefarah/yq v4 from https://github.com/mikefarah/yq/releases and add it to PATH.' ;;
    *) themis_init_yq_install='Install mikefarah/yq v4 from https://github.com/mikefarah/yq/releases.' ;;
  esac

  if ! command -v yq >/dev/null 2>&1; then
    themis_init_print_dependency_error \
      'yq' \
      'mikefarah/yq v4.0.0 or newer within major version 4' \
      'not found' \
      'missing' \
      "${themis_init_yq_install}"
    return 1
  fi

  themis_init_yq_output=$(yq --version 2>&1)
  themis_init_yq_status=$?
  if [ "${themis_init_yq_status}" -ne 0 ]; then
    themis_init_print_dependency_error \
      'yq' \
      'mikefarah/yq v4.0.0 or newer within major version 4' \
      'version command failed' \
      'version unreadable' \
      "${themis_init_yq_install}"
    return 1
  fi

  case "${themis_init_yq_output}" in
    *mikefarah/yq*) ;;
    *)
      if ! [[ "${themis_init_yq_output}" =~ ^yq.*[[:space:]]version[[:space:]]v4\. ]]; then
        themis_init_print_dependency_error \
          'yq' \
          'mikefarah/yq v4.0.0 or newer within major version 4' \
          'non-mikefarah yq' \
          'unsupported implementation' \
          "${themis_init_yq_install}"
        return 1
      fi
      ;;
  esac

  if [[ "${themis_init_yq_output}" =~ version[[:space:]]v?([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
    themis_init_yq_major=${BASH_REMATCH[1]}
    themis_init_yq_version="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
  else
    themis_init_print_dependency_error \
      'yq' \
      'mikefarah/yq v4.0.0 or newer within major version 4' \
      'version output unreadable' \
      'version unreadable' \
      "${themis_init_yq_install}"
    return 1
  fi

  if [ "${themis_init_yq_major}" -lt 4 ]; then
    themis_init_print_dependency_error \
      'yq' \
      'mikefarah/yq v4.0.0 or newer within major version 4' \
      "v${themis_init_yq_version}" \
      'version too old' \
      "${themis_init_yq_install}"
    return 1
  fi

  if [ "${themis_init_yq_major}" -gt 4 ]; then
    themis_init_print_dependency_error \
      'yq' \
      'mikefarah/yq v4.0.0 or newer within major version 4' \
      "v${themis_init_yq_version}" \
      'unsupported implementation' \
      "${themis_init_yq_install}"
    return 1
  fi

  themis_init_version_at_least "${themis_init_yq_version}" '4.0.0'
  themis_init_yq_status=$?
  if [ "${themis_init_yq_status}" -eq 0 ]; then
    return 0
  fi

  themis_init_print_dependency_error \
    'yq' \
    'mikefarah/yq v4.0.0 or newer within major version 4' \
    "v${themis_init_yq_version}" \
    'version too old' \
    "${themis_init_yq_install}"
  return 1
}

# 按 Bash、Git、yq 的依赖顺序执行环境检查；首个失败即停止，避免多个诊断掩盖主要阻塞项。
themis_init_require_environment() {
  themis_init_check_bash || return 1
  themis_init_check_git || return 1
  themis_init_check_yq || return 1
}
