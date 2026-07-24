#!/usr/bin/env bash
#
# Themis 模板契约 TAP 测试。
# 用途：在隔离模板副本中验证 YAML、Schema、迁移描述符、导入图和 P2 指引约束。
# 边界：仅修改临时夹具；源模板不会被测试写入。
#
TEST_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
CHECKER_PATH="${TEST_ROOT}/bin/themis-template-check.sh"
SOURCE_TEMPLATE_ROOT="${TEST_ROOT}/templates/.themis"
TEST_TMP=${TMPDIR:-/tmp}/themis-template-contract-$$
YQ_EXECUTABLE=${YQ:-yq}
TEST_COUNT=0
TEST_FAILURES=0
LAST_OUTPUT=
LAST_STATUS=0

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

# 创建完全隔离的模板副本夹具。
make_fixture() {
  local name=$1
  local fixture_parent="${TEST_TMP}/${name}"

  mkdir -p "${fixture_parent}"
  cp -R "${SOURCE_TEMPLATE_ROOT}" "${fixture_parent}/.themis"
  printf '%s\n' "${fixture_parent}/.themis"
}

# 通过已验证的 yq v4 可执行文件运行模板检查器。
run_checker() {
  local fixture_root=$1

  LAST_OUTPUT=$(YQ="${YQ_EXECUTABLE}" bash "${CHECKER_PATH}" "${fixture_root}" 2>&1)
  LAST_STATUS=$?
}

# 只在临时夹具中使用 yq 安全修改 YAML。
set_yaml() {
  local expression=$1
  local file=$2

  "${YQ_EXECUTABLE}" eval -i "${expression}" "${file}"
}

if ! command -v "${YQ_EXECUTABLE}" >/dev/null 2>&1; then
  printf '%s\n' 'Template Contract tests require mikefarah/yq v4.' >&2
  exit 2
fi

case "$("${YQ_EXECUTABLE}" --version 2>&1)" in
  *mikefarah/yq*version\ v4.*) ;;
  *)
    printf '%s\n' 'Template Contract tests require mikefarah/yq v4.' >&2
    exit 2
    ;;
esac

printf '1..34\n'

CLEAN_FIXTURE=$(make_fixture clean)
run_checker "${CLEAN_FIXTURE}"
assert_status 0 'clean template passes the contract check'
assert_output_empty 'clean template check is silent'

MALFORMED_CORE_FIXTURE=$(make_fixture malformed-core)
printf '%s\n' 'core_schema: [broken' >"${MALFORMED_CORE_FIXTURE}/core/core.yaml"
run_checker "${MALFORMED_CORE_FIXTURE}"
assert_status 1 'malformed Core YAML fails validation'
assert_output_contains 'YAML unreadable' 'malformed Core YAML reports YAML diagnostic'

MISSING_MANIFEST_FIELD_FIXTURE=$(make_fixture missing-manifest-field)
set_yaml 'del(.workspace_schema)' "${MISSING_MANIFEST_FIELD_FIXTURE}/workspace/manifest.yaml"
run_checker "${MISSING_MANIFEST_FIELD_FIXTURE}"
assert_status 1 'missing Workspace schema fails validation'
assert_output_contains 'Workspace schema invalid' 'missing Workspace schema reports field diagnostic'

VERSION_MISMATCH_FIXTURE=$(make_fixture version-mismatch)
printf '%s\n' '9.9.9' >"${VERSION_MISMATCH_FIXTURE}/VERSION"
run_checker "${VERSION_MISMATCH_FIXTURE}"
assert_status 1 'bundle and Core version mismatch fails validation'
assert_output_contains 'Bundle/Core version mismatch' 'version mismatch reports version diagnostic'

UNSUPPORTED_WORKSPACE_FIXTURE=$(make_fixture unsupported-workspace)
set_yaml '.workspace_schema = "themis-workspace/v9"' "${UNSUPPORTED_WORKSPACE_FIXTURE}/workspace/manifest.yaml"
run_checker "${UNSUPPORTED_WORKSPACE_FIXTURE}"
assert_status 1 'unsupported Workspace schema fails validation'
assert_output_contains 'unsupported Workspace schema' 'unsupported Workspace schema reports compatibility diagnostic'

MIGRATABLE_WORKSPACE_FIXTURE=$(make_fixture migratable-workspace)
set_yaml '.workspace_schema = "themis-workspace/v0"' "${MIGRATABLE_WORKSPACE_FIXTURE}/workspace/manifest.yaml"
printf '%s\n' '# Placeholder migration fixture.' >"${MIGRATABLE_WORKSPACE_FIXTURE}/core/migrations/workspace/from-v0.sh"
set_yaml '.compatibility.workspace.migrations = [{"from_schema": "themis-workspace/v0", "to_schema": "themis-workspace/v1", "script": "migrations/workspace/from-v0.sh"}]' "${MIGRATABLE_WORKSPACE_FIXTURE}/core/core.yaml"
run_checker "${MIGRATABLE_WORKSPACE_FIXTURE}"
assert_status 1 'migratable Workspace schema still requires explicit migration'
assert_output_contains 'requires explicit migration' 'migratable Workspace schema reports explicit migration'

INVALID_MIGRATION_PATH_FIXTURE=$(make_fixture invalid-migration-path)
set_yaml '.workspace_schema = "themis-workspace/v0"' "${INVALID_MIGRATION_PATH_FIXTURE}/workspace/manifest.yaml"
printf '%s\n' '# Wrong-root migration fixture.' >"${INVALID_MIGRATION_PATH_FIXTURE}/core/migrations/artifacts/from-v0.sh"
set_yaml '.compatibility.workspace.migrations = [{"from_schema": "themis-workspace/v0", "to_schema": "themis-workspace/v1", "script": "migrations/artifacts/from-v0.sh"}]' "${INVALID_MIGRATION_PATH_FIXTURE}/core/core.yaml"
run_checker "${INVALID_MIGRATION_PATH_FIXTURE}"
assert_status 1 'wrong-root migration descriptor fails validation'
assert_output_contains 'migration script path invalid' 'wrong-root migration reports path diagnostic'

LEGACY_PATH_FIXTURE=$(make_fixture legacy-path)
mkdir -p "${LEGACY_PATH_FIXTURE}/core/migations"
run_checker "${LEGACY_PATH_FIXTURE}"
assert_status 1 'legacy misspelled path fails validation'
assert_output_contains 'legacy template path present' 'legacy path reports spelling diagnostic'

MISSING_IMPORT_FIXTURE=$(make_fixture missing-import)
rm "${MISSING_IMPORT_FIXTURE}/core/kernel/planning/rules.md"
run_checker "${MISSING_IMPORT_FIXTURE}"
assert_status 1 'missing Core import target fails validation'
assert_output_contains 'required path missing' 'missing Core import target reports required path diagnostic'

ESCAPING_IMPORT_FIXTURE=$(make_fixture escaping-import)
printf '%s\n' '# Outside-Core import fixture.' >"${ESCAPING_IMPORT_FIXTURE}/core/outside.md"
awk '{ if ($0 == "@import ../planning/rules.md") print "@import ../../../outside.md"; else print }' "${ESCAPING_IMPORT_FIXTURE}/core/kernel/orchestrator/rules.md" >"${ESCAPING_IMPORT_FIXTURE}/core/kernel/orchestrator/rules.md.tmp"
mv "${ESCAPING_IMPORT_FIXTURE}/core/kernel/orchestrator/rules.md.tmp" "${ESCAPING_IMPORT_FIXTURE}/core/kernel/orchestrator/rules.md"
run_checker "${ESCAPING_IMPORT_FIXTURE}"
assert_status 1 'Core import escape fails validation'
assert_output_contains 'Core import escapes Core' 'Core import escape reports Core-boundary diagnostic'

MISSING_TOP_LEVEL_IMPORT_FIXTURE=$(make_fixture contained-guidance-import)
printf '%s\n' '@import core/kernel/missing/rules.md' >>"${MISSING_TOP_LEVEL_IMPORT_FIXTURE}/CLAUDE.themis.md"
run_checker "${MISSING_TOP_LEVEL_IMPORT_FIXTURE}"
assert_status 1 'contained guidance import fails validation'
assert_output_contains 'contained guidance import count invalid' 'contained guidance import reports count diagnostic'

OBSOLETE_ROOT_GUIDANCE_FIXTURE=$(make_fixture obsolete-root-guidance)
printf '%s\n' '# Obsolete root-level guidance fixture.' >"${OBSOLETE_ROOT_GUIDANCE_FIXTURE%/.themis}/CLAUDE.themis.md"
run_checker "${OBSOLETE_ROOT_GUIDANCE_FIXTURE}"
assert_status 1 'obsolete root guidance fails validation'
assert_output_contains 'obsolete root guidance present' 'obsolete root guidance reports layout diagnostic'

DUPLICATE_TOP_LEVEL_IMPORT_FIXTURE=$(make_fixture duplicate-contained-guidance-import)
printf '%s\n' '@import core/kernel/orchestrator/rules.md' >>"${DUPLICATE_TOP_LEVEL_IMPORT_FIXTURE}/CLAUDE.themis.md"
run_checker "${DUPLICATE_TOP_LEVEL_IMPORT_FIXTURE}"
assert_status 1 'contained guidance import count fails validation'
assert_output_contains 'contained guidance import count invalid' 'contained guidance import count reports diagnostic'

MISSING_TOP_LEVEL_BOUNDARY_FIXTURE=$(make_fixture missing-top-level-boundary)
awk '$0 != "## Installation Boundary"' "${MISSING_TOP_LEVEL_BOUNDARY_FIXTURE}/CLAUDE.themis.md" >"${MISSING_TOP_LEVEL_BOUNDARY_FIXTURE}/CLAUDE.themis.md.tmp"
mv "${MISSING_TOP_LEVEL_BOUNDARY_FIXTURE}/CLAUDE.themis.md.tmp" "${MISSING_TOP_LEVEL_BOUNDARY_FIXTURE}/CLAUDE.themis.md"
run_checker "${MISSING_TOP_LEVEL_BOUNDARY_FIXTURE}"
assert_status 1 'missing installation boundary fails validation'
assert_output_contains 'installation boundary missing' 'missing installation boundary reports P2 diagnostic'

MISSING_ORCHESTRATOR_ROUTE_FIXTURE=$(make_fixture missing-orchestrator-route)
awk '$0 != "## Artifact-First Routing"' "${MISSING_ORCHESTRATOR_ROUTE_FIXTURE}/core/kernel/orchestrator/rules.md" >"${MISSING_ORCHESTRATOR_ROUTE_FIXTURE}/core/kernel/orchestrator/rules.md.tmp"
mv "${MISSING_ORCHESTRATOR_ROUTE_FIXTURE}/core/kernel/orchestrator/rules.md.tmp" "${MISSING_ORCHESTRATOR_ROUTE_FIXTURE}/core/kernel/orchestrator/rules.md"
run_checker "${MISSING_ORCHESTRATOR_ROUTE_FIXTURE}"
assert_status 1 'missing Orchestrator routing section fails validation'
assert_output_contains 'artifact-first routing missing' 'missing Orchestrator routing reports P2 diagnostic'

DUPLICATE_ORCHESTRATOR_IMPORT_FIXTURE=$(make_fixture duplicate-orchestrator-import)
printf '%s\n' '@import ../specification/rules.md' >>"${DUPLICATE_ORCHESTRATOR_IMPORT_FIXTURE}/core/kernel/orchestrator/rules.md"
run_checker "${DUPLICATE_ORCHESTRATOR_IMPORT_FIXTURE}"
assert_status 1 'duplicate Orchestrator import fails validation'
assert_output_contains 'Orchestrator import count invalid' 'duplicate Orchestrator import reports count diagnostic'

MISSING_DOMAIN_BOUNDARY_FIXTURE=$(make_fixture missing-domain-boundary)
awk '$0 != "## Boundaries"' "${MISSING_DOMAIN_BOUNDARY_FIXTURE}/core/kernel/planning/rules.md" >"${MISSING_DOMAIN_BOUNDARY_FIXTURE}/core/kernel/planning/rules.md.tmp"
mv "${MISSING_DOMAIN_BOUNDARY_FIXTURE}/core/kernel/planning/rules.md.tmp" "${MISSING_DOMAIN_BOUNDARY_FIXTURE}/core/kernel/planning/rules.md"
run_checker "${MISSING_DOMAIN_BOUNDARY_FIXTURE}"
assert_status 1 'missing domain boundary section fails validation'
assert_output_contains 'planning boundaries missing' 'missing domain boundary reports module diagnostic'

if [ "${TEST_FAILURES}" -ne 0 ]; then
  printf '%s of %s tests failed\n' "${TEST_FAILURES}" "${TEST_COUNT}" >&2
  exit 1
fi

printf 'All %s tests passed\n' "${TEST_COUNT}"
