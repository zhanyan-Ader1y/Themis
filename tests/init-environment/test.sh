#!/usr/bin/env bash
#
# Themis Init 环境前置条件 TAP 测试。
# 用途：使用受控 PATH 和命令桩覆盖版本比较、Git、yq 与组合校验的成功和失败分支。
# 边界：所有夹具均在临时目录中创建，不依赖宿主机已安装的 Git 或 yq 行为。
#
TEST_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
LIBRARY_PATH="${TEST_ROOT}/bin/_themis-init-env.sh"
TEST_TMP=${TMPDIR:-/tmp}/themis-init-environment-$$
TEST_COUNT=0
TEST_FAILURES=0
LAST_OUTPUT=
LAST_STATUS=0

mkdir -p "${TEST_TMP}"
trap 'rm -rf "${TEST_TMP}"' EXIT HUP INT TERM

# shellcheck disable=SC1090,SC1091
. "${LIBRARY_PATH}"

# 输出一条成功的 TAP 断言。
pass() {
  TEST_COUNT=$((TEST_COUNT + 1))
  printf 'ok %s - %s\n' "${TEST_COUNT}" "$1"
}

# 输出一条失败的 TAP 断言，并保留简洁诊断。
fail() {
  TEST_COUNT=$((TEST_COUNT + 1))
  TEST_FAILURES=$((TEST_FAILURES + 1))
  printf 'not ok %s - %s\n' "${TEST_COUNT}" "$1"
  if [ -n "${2-}" ]; then
    printf '  %s\n' "$2"
  fi
}

# 断言最近一次受控调用的退出状态。
assert_status() {
  local expected=$1
  local name=$2

  if [ "${LAST_STATUS}" -eq "${expected}" ]; then
    pass "${name}"
  else
    fail "${name}" "expected status ${expected}, got ${LAST_STATUS}; output: ${LAST_OUTPUT}"
  fi
}

# 断言稳定诊断包含预期片段，不依赖完整文案。
assert_output_contains() {
  local expected=$1
  local name=$2

  case "${LAST_OUTPUT}" in
    *"${expected}"*) pass "${name}" ;;
    *) fail "${name}" "expected output to contain '${expected}', got: ${LAST_OUTPUT}" ;;
  esac
}

# 断言成功路径保持静默。
assert_output_empty() {
  local name=$1

  if [ -z "${LAST_OUTPUT}" ]; then
    pass "${name}"
  else
    fail "${name}" "expected no output, got: ${LAST_OUTPUT}"
  fi
}

# 使用受控 PATH 调用公开环境校验函数，避免使用宿主机的 Git 或 yq。
run_function() {
  local function_name=$1
  local function_path=$2

  LAST_OUTPUT=$(PATH="${function_path}" "${function_name}" 2>&1)
  LAST_STATUS=$?
}

# 创建模拟版本命令的可执行桩，以确定性覆盖解析与失败分支。
write_command() {
  local path=$1
  local output=$2
  local status=${3:-0}

  {
    printf '%s\n' '#!/bin/sh'
    printf "printf '%%s\\n' '%s'\n" "${output}"
    printf 'exit %s\n' "${status}"
  } >"${path}"
  chmod +x "${path}"
}

# 单独调用纯语义版本比较辅助函数。
run_version_comparison() {
  local actual=$1
  local minimum=$2

  LAST_OUTPUT=$(themis_init_version_at_least "${actual}" "${minimum}" 2>&1)
  LAST_STATUS=$?
}

printf '1..31\n'

run_version_comparison '3.2.0' '3.2.0'
assert_status 0 'equal versions are accepted'
run_version_comparison '4.0.0' '3.2.0'
assert_status 0 'newer major version is accepted'
run_version_comparison '3.10.0' '3.2.0'
assert_status 0 'newer minor version is compared numerically'
run_version_comparison '3.2.1' '3.2.0'
assert_status 0 'newer patch version is accepted'
run_version_comparison '3.2' '3.2.0'
assert_status 0 'missing patch is normalized to zero'
run_version_comparison '3.1.9' '3.2.0'
assert_status 1 'older version is rejected'
run_version_comparison '3.x.0' '3.2.0'
assert_status 2 'non-numeric version is unreadable'
run_version_comparison '3..0' '3.2.0'
assert_status 2 'empty version component is unreadable'

EMPTY_PATH="${TEST_TMP}/empty"
mkdir -p "${EMPTY_PATH}"
run_function themis_init_check_git "${EMPTY_PATH}"
assert_status 1 'missing Git fails validation'
assert_output_contains 'Detected: not found' 'missing Git reports not found'

OLD_GIT_PATH="${TEST_TMP}/old-git"
mkdir -p "${OLD_GIT_PATH}"
write_command "${OLD_GIT_PATH}/git" 'git version 1.9.9'
run_function themis_init_check_git "${OLD_GIT_PATH}"
assert_status 1 'old Git fails validation'
assert_output_contains 'Reason: version too old' 'old Git reports version reason'

VALID_GIT_PATH="${TEST_TMP}/valid-git"
mkdir -p "${VALID_GIT_PATH}"
write_command "${VALID_GIT_PATH}/git" 'git version 2.0.0'
run_function themis_init_check_git "${VALID_GIT_PATH}"
assert_status 0 'minimum Git version is accepted'
assert_output_empty 'valid Git check is silent'

WINDOWS_GIT_PATH="${TEST_TMP}/windows-git"
mkdir -p "${WINDOWS_GIT_PATH}"
write_command "${WINDOWS_GIT_PATH}/git" 'git version 2.51.0.windows.1'
run_function themis_init_check_git "${WINDOWS_GIT_PATH}"
assert_status 0 'Git for Windows version suffix is accepted'

UNREADABLE_GIT_PATH="${TEST_TMP}/unreadable-git"
mkdir -p "${UNREADABLE_GIT_PATH}"
write_command "${UNREADABLE_GIT_PATH}/git" 'custom git wrapper'
run_function themis_init_check_git "${UNREADABLE_GIT_PATH}"
assert_status 1 'unreadable Git version fails validation'
assert_output_contains 'Reason: version unreadable' 'unreadable Git reports version reason'

run_function themis_init_check_yq "${EMPTY_PATH}"
assert_status 1 'missing yq fails validation'
assert_output_contains 'Detected: not found' 'missing yq reports not found'

PYTHON_YQ_PATH="${TEST_TMP}/python-yq"
mkdir -p "${PYTHON_YQ_PATH}"
write_command "${PYTHON_YQ_PATH}/yq" 'yq 3.4.3'
run_function themis_init_check_yq "${PYTHON_YQ_PATH}"
assert_status 1 'Python yq fails validation'
assert_output_contains 'Reason: unsupported implementation' 'Python yq reports unsupported implementation'

OLD_YQ_PATH="${TEST_TMP}/old-yq"
mkdir -p "${OLD_YQ_PATH}"
write_command "${OLD_YQ_PATH}/yq" 'yq (https://github.com/mikefarah/yq/) version 3.4.1'
run_function themis_init_check_yq "${OLD_YQ_PATH}"
assert_status 1 'mikefarah/yq v3 fails validation'
assert_output_contains 'Reason: version too old' 'mikefarah/yq v3 reports version reason'

VALID_YQ_PATH="${TEST_TMP}/valid-yq"
mkdir -p "${VALID_YQ_PATH}"
write_command "${VALID_YQ_PATH}/yq" 'yq (https://github.com/mikefarah/yq/) version v4.0.0'
run_function themis_init_check_yq "${VALID_YQ_PATH}"
assert_status 0 'minimum mikefarah/yq v4 version is accepted'
assert_output_empty 'valid yq check is silent'

FUTURE_YQ_PATH="${TEST_TMP}/future-yq"
mkdir -p "${FUTURE_YQ_PATH}"
write_command "${FUTURE_YQ_PATH}/yq" 'yq (https://github.com/mikefarah/yq/) version v5.0.0'
run_function themis_init_check_yq "${FUTURE_YQ_PATH}"
assert_status 1 'unverified future yq major version fails validation'
assert_output_contains 'Reason: unsupported implementation' 'future yq major reports unsupported implementation'

VALID_ENV_PATH="${TEST_TMP}/valid-env"
mkdir -p "${VALID_ENV_PATH}"
write_command "${VALID_ENV_PATH}/git" 'git version 2.45.1'
write_command "${VALID_ENV_PATH}/yq" 'yq (https://github.com/mikefarah/yq/) version v4.44.3'
run_function themis_init_require_environment "${VALID_ENV_PATH}"
assert_status 0 'complete compatible environment is accepted'
assert_output_empty 'complete compatible environment is silent'

run_function themis_init_require_environment "${EMPTY_PATH}"
assert_status 1 'combined validation stops on the first missing dependency'
assert_output_contains 'prerequisite failed: Git' 'combined validation reports Git before yq'

if [ "${TEST_FAILURES}" -ne 0 ]; then
  printf '%s of %s tests failed\n' "${TEST_FAILURES}" "${TEST_COUNT}" >&2
  exit 1
fi

printf 'All %s tests passed\n' "${TEST_COUNT}"
