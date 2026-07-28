#!/usr/bin/env bash
#
# Themis 模板契约 TAP 测试。
# 用途：在隔离模板副本中验证 YAML、固定 Schema allow-list、退役资产、导入图和 P2 指引约束。
# 边界：仅修改临时夹具；源模板不会被测试写入。
#
TEST_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
CHECKER_PATH="${TEST_ROOT}/bin/themis-template-check.sh"
SOURCE_TEMPLATE_ROOT="${TEST_ROOT}/templates/.themis"
SOURCE_SKILL_ROOT="${TEST_ROOT}/templates/.claude/skills/Themis-Q"
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

  mkdir -p "${fixture_parent}/.claude/skills"
  cp -R "${SOURCE_TEMPLATE_ROOT}" "${fixture_parent}/.themis"
  cp -R "${SOURCE_SKILL_ROOT}" "${fixture_parent}/.claude/skills/Themis-Q"
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

printf '1..88\n'

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
set_yaml '.workspace_schema = "themis-workspace/v1"' "${UNSUPPORTED_WORKSPACE_FIXTURE}/workspace/manifest.yaml"
run_checker "${UNSUPPORTED_WORKSPACE_FIXTURE}"
assert_status 1 'versioned Workspace schema fails validation'
assert_output_contains 'module version identifier forbidden' 'versioned Workspace schema reports module version diagnostic'

WORKSPACE_MIGRATION_METADATA_FIXTURE=$(make_fixture workspace-migration-metadata)
set_yaml '.compatibility.workspace.migrations = []' "${WORKSPACE_MIGRATION_METADATA_FIXTURE}/core/core.yaml"
run_checker "${WORKSPACE_MIGRATION_METADATA_FIXTURE}"
assert_status 1 'Workspace migration metadata fails validation'
assert_output_contains 'workspace migration metadata present' 'Workspace migration metadata reports retired contract'

MIGRATION_ROOTS_METADATA_FIXTURE=$(make_fixture migration-roots-metadata)
set_yaml '.migration_roots = {"workspace": "migrations/workspace"}' "${MIGRATION_ROOTS_METADATA_FIXTURE}/core/core.yaml"
run_checker "${MIGRATION_ROOTS_METADATA_FIXTURE}"
assert_status 1 'Migration roots metadata fails validation'
assert_output_contains 'Migration roots metadata present' 'Migration roots metadata reports retired contract'

LEGACY_PATH_FIXTURE=$(make_fixture legacy-path)
mkdir -p "${LEGACY_PATH_FIXTURE}/core/migations"
run_checker "${LEGACY_PATH_FIXTURE}"
assert_status 1 'legacy misspelled path fails validation'
assert_output_contains 'legacy template path present' 'legacy path reports spelling diagnostic'

LEGACY_SPEC_TEMPLATE_FIXTURE=$(make_fixture legacy-spec-template)
printf '%s\n' '# Obsolete Spec Markdown template.' >"${LEGACY_SPEC_TEMPLATE_FIXTURE}/core/templates/spec.md"
run_checker "${LEGACY_SPEC_TEMPLATE_FIXTURE}"
assert_status 1 'legacy Spec Markdown template fails validation'
assert_output_contains 'legacy Spec compatibility asset present' 'legacy Spec template reports compatibility diagnostic'

RETIRED_CAPABILITY_ASSET_FIXTURE=$(make_fixture retired-capability-asset)
mkdir -p "${RETIRED_CAPABILITY_ASSET_FIXTURE}/core/migrations"
run_checker "${RETIRED_CAPABILITY_ASSET_FIXTURE}"
assert_status 1 'retired capability namespace fails validation'
assert_output_contains 'retired capability asset present' 'retired capability namespace reports contract diagnostic'

ARTIFACT_V1_SUPPORT_FIXTURE=$(make_fixture artifact-version-support)
set_yaml '.compatibility.artifact.supported = ["themis-artifact/v2", "themis-artifact"]' "${ARTIFACT_V1_SUPPORT_FIXTURE}/core/core.yaml"
run_checker "${ARTIFACT_V1_SUPPORT_FIXTURE}"
assert_status 1 'versioned Artifact identifier fails validation'
assert_output_contains 'module version identifier forbidden' 'versioned Artifact identifier reports module version diagnostic'

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

MISSING_P5_POLICY_FIXTURE=$(make_fixture missing-p5-policy)
rm "${MISSING_P5_POLICY_FIXTURE}/core/policies/specification.yaml"
run_checker "${MISSING_P5_POLICY_FIXTURE}"
assert_status 1 'missing Specification policy fails validation'
assert_output_contains 'required path missing' 'missing Specification policy reports path diagnostic'

MALFORMED_P5_POLICY_FIXTURE=$(make_fixture malformed-p5-policy)
printf '%s\n' 'specification: [broken' >"${MALFORMED_P5_POLICY_FIXTURE}/core/policies/specification.yaml"
run_checker "${MALFORMED_P5_POLICY_FIXTURE}"
assert_status 1 'malformed Specification policy fails validation'
assert_output_contains 'YAML unreadable' 'malformed Specification policy reports YAML diagnostic'

MISSING_THEMIS_Q_FIXTURE=$(make_fixture missing-themis-q)
rm -rf "${MISSING_THEMIS_Q_FIXTURE%/.themis}/.claude/skills/Themis-Q"
run_checker "${MISSING_THEMIS_Q_FIXTURE}"
assert_status 1 'missing Themis-Q Skill fails validation'
assert_output_contains 'required path missing' 'missing Themis-Q Skill reports path diagnostic'

MISSING_QUESTIONING_STYLE_FIXTURE=$(make_fixture missing-questioning-style)
awk '$0 != "## Questioning style"' "${MISSING_QUESTIONING_STYLE_FIXTURE%/.themis}/.claude/skills/Themis-Q/SKILL.md" >"${MISSING_QUESTIONING_STYLE_FIXTURE%/.themis}/.claude/skills/Themis-Q/SKILL.md.tmp"
mv "${MISSING_QUESTIONING_STYLE_FIXTURE%/.themis}/.claude/skills/Themis-Q/SKILL.md.tmp" "${MISSING_QUESTIONING_STYLE_FIXTURE%/.themis}/.claude/skills/Themis-Q/SKILL.md"
run_checker "${MISSING_QUESTIONING_STYLE_FIXTURE}"
assert_status 1 'missing Themis-Q questioning style fails validation'
assert_output_contains 'Themis-Q questioning coverage missing' 'missing Themis-Q questioning style reports coverage diagnostic'

MISSING_FOCUSED_QUESTION_FIXTURE=$(make_fixture missing-focused-question)
awk '$0 != "- Ask one focused question at a time."' "${MISSING_FOCUSED_QUESTION_FIXTURE%/.themis}/.claude/skills/Themis-Q/SKILL.md" >"${MISSING_FOCUSED_QUESTION_FIXTURE%/.themis}/.claude/skills/Themis-Q/SKILL.md.tmp"
mv "${MISSING_FOCUSED_QUESTION_FIXTURE%/.themis}/.claude/skills/Themis-Q/SKILL.md.tmp" "${MISSING_FOCUSED_QUESTION_FIXTURE%/.themis}/.claude/skills/Themis-Q/SKILL.md"
run_checker "${MISSING_FOCUSED_QUESTION_FIXTURE}"
assert_status 1 'missing focused-question rule fails validation'
assert_output_contains 'Themis-Q focused questioning rule missing' 'missing focused-question rule reports guidance diagnostic'

MISSING_CONVERGENCE_FIXTURE=$(make_fixture missing-convergence)
awk '$0 != "## Convergence"' "${MISSING_CONVERGENCE_FIXTURE%/.themis}/.claude/skills/Themis-Q/SKILL.md" >"${MISSING_CONVERGENCE_FIXTURE%/.themis}/.claude/skills/Themis-Q/SKILL.md.tmp"
mv "${MISSING_CONVERGENCE_FIXTURE%/.themis}/.claude/skills/Themis-Q/SKILL.md.tmp" "${MISSING_CONVERGENCE_FIXTURE%/.themis}/.claude/skills/Themis-Q/SKILL.md"
run_checker "${MISSING_CONVERGENCE_FIXTURE}"
assert_status 1 'missing Themis-Q convergence guidance fails validation'
assert_output_contains 'Themis-Q questioning coverage missing' 'missing Themis-Q convergence reports coverage diagnostic'

LEGACY_QUESTIONING_ASSET_FIXTURE=$(make_fixture legacy-questioning-asset)
printf '%s\n' '# Retired questioning Prompt.' >"${LEGACY_QUESTIONING_ASSET_FIXTURE}/core/templates/spec-questioning.md"
run_checker "${LEGACY_QUESTIONING_ASSET_FIXTURE}"
assert_status 1 'retired questioning Prompt fails validation'
assert_output_contains 'retired Specification questioning asset present' 'retired questioning Prompt reports contract diagnostic'

MISSING_SKILL_INVOCATION_FIXTURE=$(make_fixture missing-skill-invocation)
awk '$0 != "Before creating or modifying a Spec candidate, invoke the `Themis-Q` Skill with the Skill tool unless it has already clarified the current request in this conversation."' "${MISSING_SKILL_INVOCATION_FIXTURE}/core/kernel/specification/rules.md" >"${MISSING_SKILL_INVOCATION_FIXTURE}/core/kernel/specification/rules.md.tmp"
mv "${MISSING_SKILL_INVOCATION_FIXTURE}/core/kernel/specification/rules.md.tmp" "${MISSING_SKILL_INVOCATION_FIXTURE}/core/kernel/specification/rules.md"
run_checker "${MISSING_SKILL_INVOCATION_FIXTURE}"
assert_status 1 'missing Specification Skill invocation fails validation'
assert_output_contains 'Specification Themis-Q invocation missing' 'missing Specification Skill invocation reports contract diagnostic'

MISSING_TRANSITION_FIXTURE=$(make_fixture missing-transition)
set_yaml 'del(.transitions.draft_to_specified)' "${MISSING_TRANSITION_FIXTURE}/core/policies/transitions.yaml"
run_checker "${MISSING_TRANSITION_FIXTURE}"
assert_status 1 'missing draft-to-specified transition fails validation'
assert_output_contains 'Draft-to-specified transition missing' 'missing transition reports structure diagnostic'

WRONG_CONDITION_COUNT_FIXTURE=$(make_fixture wrong-condition-count)
set_yaml 'del(.transitions.draft_to_specified.conditions[7])' "${WRONG_CONDITION_COUNT_FIXTURE}/core/policies/transitions.yaml"
run_checker "${WRONG_CONDITION_COUNT_FIXTURE}"
assert_status 1 'wrong transition condition count fails validation'
assert_output_contains 'Draft-to-specified condition count invalid' 'wrong transition condition count reports diagnostic'

UNKNOWN_CONDITION_ID_FIXTURE=$(make_fixture unknown-condition-id)
set_yaml '.transitions.draft_to_specified.conditions[0].id = "unknown_condition"' "${UNKNOWN_CONDITION_ID_FIXTURE}/core/policies/transitions.yaml"
run_checker "${UNKNOWN_CONDITION_ID_FIXTURE}"
assert_status 1 'unknown transition condition identifier fails validation'
assert_output_contains 'Draft-to-specified condition missing' 'unknown transition condition identifier reports diagnostic'

MISSING_QUICK_CHECK_FIXTURE=$(make_fixture missing-quick-check)
set_yaml 'del(.specification.adversarial_validation.quick_checklist[4])' "${MISSING_QUICK_CHECK_FIXTURE}/core/policies/specification.yaml"
run_checker "${MISSING_QUICK_CHECK_FIXTURE}"
assert_status 1 'missing quick-check item fails validation'
assert_output_contains 'Specification quick checklist invalid' 'missing quick-check item reports diagnostic'

MISSING_DIMENSION_FIXTURE=$(make_fixture missing-dimension)
set_yaml 'del(.specification.adversarial_validation.dimensions[5])' "${MISSING_DIMENSION_FIXTURE}/core/policies/specification.yaml"
run_checker "${MISSING_DIMENSION_FIXTURE}"
assert_status 1 'missing adversarial dimension fails validation'
assert_output_contains 'Specification adversarial dimensions invalid' 'missing adversarial dimension reports diagnostic'

BROKEN_SPEC_TEMPLATE_FIXTURE=$(make_fixture broken-spec-template)
set_yaml '.template_version = 1' "${BROKEN_SPEC_TEMPLATE_FIXTURE}/core/templates/spec.yaml"
run_checker "${BROKEN_SPEC_TEMPLATE_FIXTURE}"
assert_status 1 'retired Spec template version field fails validation'
assert_output_contains 'retired Spec field present' 'retired Spec template version reports diagnostic'

MISSING_ATTACK_HEADING_FIXTURE=$(make_fixture missing-attack-heading)
awk '$0 != "## Data integrity"' "${MISSING_ATTACK_HEADING_FIXTURE%/.themis}/.claude/skills/Themis-Q/references/adversarial-checklist.md" >"${MISSING_ATTACK_HEADING_FIXTURE%/.themis}/.claude/skills/Themis-Q/references/adversarial-checklist.md.tmp"
mv "${MISSING_ATTACK_HEADING_FIXTURE%/.themis}/.claude/skills/Themis-Q/references/adversarial-checklist.md.tmp" "${MISSING_ATTACK_HEADING_FIXTURE%/.themis}/.claude/skills/Themis-Q/references/adversarial-checklist.md"
run_checker "${MISSING_ATTACK_HEADING_FIXTURE}"
assert_status 1 'missing Themis-Q attack dimension fails validation'
assert_output_contains 'Themis-Q attack dimension missing' 'missing Themis-Q attack dimension reports diagnostic'

OVERSIZED_SPECIFICATION_RULES_FIXTURE=$(make_fixture oversized-specification-rules)
while [ "$(wc -l < "${OVERSIZED_SPECIFICATION_RULES_FIXTURE}/core/kernel/specification/rules.md")" -le 50 ]; do
  printf '%s\n' 'padding for line-limit fixture' >>"${OVERSIZED_SPECIFICATION_RULES_FIXTURE}/core/kernel/specification/rules.md"
done
run_checker "${OVERSIZED_SPECIFICATION_RULES_FIXTURE}"
assert_status 1 'oversized Specification rules fail validation'
assert_output_contains 'specification guidance too large' 'oversized Specification rules report budget diagnostic'

MISSING_CONTEXT_PROTOCOL_FIXTURE=$(make_fixture missing-context-protocol)
rm "${MISSING_CONTEXT_PROTOCOL_FIXTURE}/core/protocols/context/signal-schema.yaml"
run_checker "${MISSING_CONTEXT_PROTOCOL_FIXTURE}"
assert_status 1 'missing Context Protocol fails validation'
assert_output_contains 'required path missing' 'missing Context Protocol reports path diagnostic'

NON_EXECUTABLE_CONTEXT_FIXTURE=$(make_fixture non-executable-context)
rm "${NON_EXECUTABLE_CONTEXT_FIXTURE}/core/bin/themis-context-search.sh"
mkdir "${NON_EXECUTABLE_CONTEXT_FIXTURE}/core/bin/themis-context-search.sh"
run_checker "${NON_EXECUTABLE_CONTEXT_FIXTURE}"
assert_status 1 'non-executable Context command fails validation'
assert_output_contains 'required executor is not executable' 'non-executable Context command reports mode diagnostic'

WRONG_CONTEXT_RESULT_FIXTURE=$(make_fixture wrong-context-result)
set_yaml '.result_schema = "themis-context-result-versioned"' "${WRONG_CONTEXT_RESULT_FIXTURE}/core/protocols/context/common-schema.yaml"
run_checker "${WRONG_CONTEXT_RESULT_FIXTURE}"
assert_status 1 'wrong Context result protocol fails validation'
assert_output_contains 'Context result protocol invalid' 'wrong Context result protocol reports identifier diagnostic'

VERSIONED_MODULE_IDENTIFIER_FIXTURE=$(make_fixture versioned-module-identifier)
printf '%s\n' 'schema: themis-review/v1' >"${VERSIONED_MODULE_IDENTIFIER_FIXTURE}/core/protocols/review-schema.yaml"
run_checker "${VERSIONED_MODULE_IDENTIFIER_FIXTURE}"
assert_status 1 'module-level version identifier fails validation'
assert_output_contains 'module version identifier forbidden' 'module-level version identifier reports contract diagnostic'

VERSIONED_MODULE_DIRECTORY_FIXTURE=$(make_fixture versioned-module-directory)
mkdir -p "${VERSIONED_MODULE_DIRECTORY_FIXTURE}/core/protocols/review/v1"
printf '%s\n' 'schema: themis-review' >"${VERSIONED_MODULE_DIRECTORY_FIXTURE}/core/protocols/review/v1/review-schema.yaml"
run_checker "${VERSIONED_MODULE_DIRECTORY_FIXTURE}"
assert_status 1 'module-level version directory fails validation'
assert_output_contains 'module version directory forbidden' 'module-level version directory reports contract diagnostic'

BOUND_BOOTSTRAP_CATALOG_FIXTURE=$(make_fixture bound-bootstrap-catalog)
set_yaml '.binding = "bound" | .project.name = "fixture" | .workspace_identity_digest = "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"' "${BOUND_BOOTSTRAP_CATALOG_FIXTURE}/workspace/context/catalog.yaml"
run_checker "${BOUND_BOOTSTRAP_CATALOG_FIXTURE}"
assert_status 1 'bound bootstrap Context Catalog fails validation'
assert_output_contains 'Bootstrap Context Catalog binding invalid' 'bound bootstrap Context Catalog reports binding diagnostic'

MISSING_CONTEXT_PROJECTION_FIXTURE=$(make_fixture missing-context-projection)
rm "${MISSING_CONTEXT_PROJECTION_FIXTURE}/workspace/context/external/.overview.md"
run_checker "${MISSING_CONTEXT_PROJECTION_FIXTURE}"
assert_status 1 'missing Context projection fails validation'
assert_output_contains 'required path missing' 'missing Context projection reports path diagnostic'

MISSING_CONTEXT_ROUTING_FIXTURE=$(make_fixture missing-context-routing)
awk '$0 != "- Before semantic selection, MUST Read `core/templates/context-resolution.md` and the Context Protocols, then use the installed deterministic Search and Assemble executors."' "${MISSING_CONTEXT_ROUTING_FIXTURE}/core/kernel/context/rules.md" >"${MISSING_CONTEXT_ROUTING_FIXTURE}/core/kernel/context/rules.md.tmp"
mv "${MISSING_CONTEXT_ROUTING_FIXTURE}/core/kernel/context/rules.md.tmp" "${MISSING_CONTEXT_ROUTING_FIXTURE}/core/kernel/context/rules.md"
run_checker "${MISSING_CONTEXT_ROUTING_FIXTURE}"
assert_status 1 'missing Context resolution routing fails validation'
assert_output_contains 'Context resolution routing missing' 'missing Context resolution routing reports boundary diagnostic'

if [ "${TEST_FAILURES}" -ne 0 ]; then
  printf '%s of %s tests failed\n' "${TEST_FAILURES}" "${TEST_COUNT}" >&2
  exit 1
fi

printf 'All %s tests passed\n' "${TEST_COUNT}"
