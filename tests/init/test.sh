#!/usr/bin/env bash
#
# Themis Init TAP 测试。
# 用途：验证全新安装、受管 import 块、manifest 配置与对既有项目内容的保护。
# 边界：每个场景均在独立临时项目中执行。
#
TEST_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
INIT_PATH="${TEST_ROOT}/bin/themis-init.sh"
TEST_TMP=${TMPDIR:-/tmp}/themis-init-test-$$
YQ_EXECUTABLE=${YQ:-yq}
TEST_COUNT=0
TEST_FAILURES=0
LAST_OUTPUT=
LAST_STATUS=0
EXPECTED_BLOCK='<!-- themis:guidance:start -->
@import .themis/CLAUDE.themis.md
@import .themis/core/kernel/orchestrator/rules.md
<!-- themis:guidance:end -->'

mkdir -p "${TEST_TMP}"
trap 'rm -rf "${TEST_TMP}"' EXIT HUP INT TERM

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

# 运行 Init 并保存输出和状态，以测试预期拒绝场景。
run_init() {
  LAST_OUTPUT=$(bash "${INIT_PATH}" "$@" 2>&1)
  LAST_STATUS=$?
}

# 断言最近一次受控调用的退出状态。
assert_status() {
  if [ "${LAST_STATUS}" -eq "$1" ]; then
    pass "$2"
  else
    fail "$2" "expected status $1, got ${LAST_STATUS}; output: ${LAST_OUTPUT}"
  fi
}

# 断言稳定诊断包含预期片段，不依赖完整文案。
assert_output_contains() {
  case "${LAST_OUTPUT}" in
    *"$1"*) pass "$2" ;;
    *) fail "$2" "expected output to contain '$1', got: ${LAST_OUTPUT}" ;;
  esac
}

# 断言文件包含预期的稳定内容片段。
assert_file_contains() {
  if grep -F -q -- "$1" "$2"; then
    pass "$3"
  else
    fail "$3" "expected $2 to contain '$1'"
  fi
}

# 断言指定路径不存在。
assert_file_absent() {
  if [ ! -e "$1" ]; then
    pass "$2"
  else
    fail "$2" "unexpected path: $1"
  fi
}

# 断言指定路径存在。
assert_file_exists() {
  if [ -e "$1" ]; then
    pass "$2"
  else
    fail "$2" "missing path: $1"
  fi
}

if ! command -v "${YQ_EXECUTABLE}" >/dev/null 2>&1; then
  printf '%s\n' 'Init tests require mikefarah/yq v4.' >&2
  exit 2
fi
case "$("${YQ_EXECUTABLE}" --version 2>&1)" in
  *mikefarah/yq*version\ v4.*) ;;
  *)
    printf '%s\n' 'Init tests require mikefarah/yq v4.' >&2
    exit 2
    ;;
esac

printf '1..24\n'

FRESH_PROJECT="${TEST_TMP}/fresh"
mkdir -p "${FRESH_PROJECT}"
run_init "${FRESH_PROJECT}" --yes --project-name demo --lint 'npm run lint' --build 'npm run build' --test 'npm test'
assert_status 0 'fresh non-interactive installation succeeds'
assert_file_exists "${FRESH_PROJECT}/.themis/CLAUDE.themis.md" 'contained guidance is installed'
assert_file_exists "${FRESH_PROJECT}/.themis/core/policies/specification.yaml" 'P5 Specification policy is installed'
assert_file_exists "${FRESH_PROJECT}/.themis/core/templates/spec-questioning.md" 'P5 questioning Prompt is installed'
assert_file_absent "${FRESH_PROJECT}/CLAUDE.themis.md" 'root-level guidance is not installed'
if [ "$(cat "${FRESH_PROJECT}/CLAUDE.md")" = "${EXPECTED_BLOCK}" ]; then
  pass 'new CLAUDE.md contains the exact direct-import block'
else
  fail 'new CLAUDE.md contains the exact direct-import block' 'unexpected CLAUDE.md content'
fi
assert_file_contains '@import .themis/core/kernel/orchestrator/rules.md' "${FRESH_PROJECT}/CLAUDE.md" 'CLAUDE.md imports the Orchestrator directly'
assert_file_contains '.themis/workspace/cache/' "${FRESH_PROJECT}/.gitignore" 'derived cache path is ignored'
if [ "$("${YQ_EXECUTABLE}" eval '.project.name' "${FRESH_PROJECT}/.themis/workspace/manifest.yaml")" = demo ]; then
  pass 'manifest project name is configured'
else
  fail 'manifest project name is configured' 'project name did not match'
fi
if [ "$("${YQ_EXECUTABLE}" eval '.commands.lint' "${FRESH_PROJECT}/.themis/workspace/manifest.yaml")" = 'npm run lint' ]; then
  pass 'manifest lint command is configured'
else
  fail 'manifest lint command is configured' 'lint command did not match'
fi

EXISTING_GUIDANCE_PROJECT="${TEST_TMP}/existing-guidance"
mkdir -p "${EXISTING_GUIDANCE_PROJECT}"
printf '%s\n' '# Project Guidance' 'Keep this content.' >"${EXISTING_GUIDANCE_PROJECT}/CLAUDE.md"
run_init "${EXISTING_GUIDANCE_PROJECT}" --yes
assert_status 0 'installation with existing CLAUDE.md succeeds'
if sed -n '1,2p' "${EXISTING_GUIDANCE_PROJECT}/CLAUDE.md" | cmp -s - <(printf '%s\n' '# Project Guidance' 'Keep this content.'); then
  pass 'existing CLAUDE.md remains an unchanged prefix'
else
  fail 'existing CLAUDE.md remains an unchanged prefix' 'existing prefix changed'
fi
if tail -n 4 "${EXISTING_GUIDANCE_PROJECT}/CLAUDE.md" | cmp -s - <(printf '%s\n' "${EXPECTED_BLOCK}"); then
  pass 'Themis block is appended at end of CLAUDE.md'
else
  fail 'Themis block is appended at end of CLAUDE.md' 'managed block was not final'
fi

PREEXISTING_BLOCK_PROJECT="${TEST_TMP}/preexisting-block"
mkdir -p "${PREEXISTING_BLOCK_PROJECT}"
printf '%s\n' "${EXPECTED_BLOCK}" >"${PREEXISTING_BLOCK_PROJECT}/CLAUDE.md"
run_init "${PREEXISTING_BLOCK_PROJECT}" --yes
assert_status 0 'existing exact Themis block permits fresh installation'
if [ "$(grep -F -c '<!-- themis:guidance:start -->' "${PREEXISTING_BLOCK_PROJECT}/CLAUDE.md")" -eq 1 ]; then
  pass 'existing exact Themis block is not duplicated'
else
  fail 'existing exact Themis block is not duplicated' 'marker count was not one'
fi

MALFORMED_MARKER_PROJECT="${TEST_TMP}/malformed-marker"
mkdir -p "${MALFORMED_MARKER_PROJECT}"
printf '%s\n' '<!-- themis:guidance:start -->' >"${MALFORMED_MARKER_PROJECT}/CLAUDE.md"
run_init "${MALFORMED_MARKER_PROJECT}" --yes
assert_status 1 'one-sided Themis marker rejects installation'
assert_output_contains 'invalid Themis markers' 'one-sided marker reports a diagnostic'
assert_file_absent "${MALFORMED_MARKER_PROJECT}/.themis" 'marker rejection creates no template directory'

MODIFIED_BLOCK_PROJECT="${TEST_TMP}/modified-block"
mkdir -p "${MODIFIED_BLOCK_PROJECT}"
printf '%s\n' '<!-- themis:guidance:start -->' '@import wrong-path.md' '<!-- themis:guidance:end -->' >"${MODIFIED_BLOCK_PROJECT}/CLAUDE.md"
run_init "${MODIFIED_BLOCK_PROJECT}" --yes
assert_status 1 'modified Themis block rejects installation'
assert_output_contains 'modified Themis block' 'modified block reports a diagnostic'
assert_file_absent "${MODIFIED_BLOCK_PROJECT}/.themis" 'modified block rejection creates no template directory'

EXISTING_INSTALL_PROJECT="${TEST_TMP}/existing-install"
mkdir -p "${EXISTING_INSTALL_PROJECT}/.themis/workspace"
printf '%s\n' 'preserve me' >"${EXISTING_INSTALL_PROJECT}/.themis/workspace/project-data.txt"
run_init "${EXISTING_INSTALL_PROJECT}" --yes
assert_status 1 'existing installation is rejected'
assert_output_contains 'Use Themis Upgrade' 'existing installation points to Upgrade'
assert_file_contains 'preserve me' "${EXISTING_INSTALL_PROJECT}/.themis/workspace/project-data.txt" 'existing Workspace remains unchanged after rejection'

if [ "${TEST_FAILURES}" -ne 0 ]; then
  printf '%s of %s tests failed\n' "${TEST_FAILURES}" "${TEST_COUNT}" >&2
  exit 1
fi
printf 'All %s tests passed\n' "${TEST_COUNT}"
