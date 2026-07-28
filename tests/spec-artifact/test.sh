#!/usr/bin/env bash
#
# Themis Spec TAP 测试。
# 用途：验证结构、引用、readiness、确定性投影、漂移和事务式配对发布。
# 边界：只操作临时夹具，不修改模板或项目 Workspace。
#
TEST_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
SPEC_EXECUTOR="${TEST_ROOT}/templates/.themis/core/kernel/specification/themis-spec.sh"
SPEC_TEMPLATE="${TEST_ROOT}/templates/.themis/core/templates/spec.yaml"
TEST_TMP=${TMPDIR:-/tmp}/themis-spec-artifact-$$
TEST_COUNT=0
TEST_FAILURES=0
LAST_OUTPUT=
LAST_STATUS=0

mkdir -p "${TEST_TMP}"
trap 'rm -rf "${TEST_TMP}"' EXIT HUP INT TERM

pass() {
  TEST_COUNT=$((TEST_COUNT + 1))
  printf 'ok %s - %s\n' "${TEST_COUNT}" "$1"
}

fail() {
  TEST_COUNT=$((TEST_COUNT + 1))
  TEST_FAILURES=$((TEST_FAILURES + 1))
  printf 'not ok %s - %s\n' "${TEST_COUNT}" "$1"
  [ -z "${2-}" ] || printf '  %s\n' "$2"
}

run_command() {
  LAST_OUTPUT=$("$@" 2>&1)
  LAST_STATUS=$?
}

assert_status() {
  if [ "${LAST_STATUS}" -eq "$1" ]; then pass "$2"; else fail "$2" "expected status $1, got ${LAST_STATUS}; output: ${LAST_OUTPUT}"; fi
}

assert_output_contains() {
  case "${LAST_OUTPUT}" in *"$1"*) pass "$2" ;; *) fail "$2" "expected output to contain '$1', got: ${LAST_OUTPUT}" ;; esac
}

assert_same_file() {
  if cmp -s "$1" "$2"; then pass "$3"; else fail "$3" "files differ: $1 and $2"; fi
}

make_draft() {
  local path=$1
  local id=$2
  cp "${SPEC_TEMPLATE}" "${path}"
  yq eval -i ".id = \"${id}\" | .title = \"Spec ${id}\"" "${path}"
}

make_ready() {
  local path=$1
  local id=$2
  make_draft "${path}" "${id}"
  yq eval -i '
    .created_at = "2026-07-27T00:00:00Z" |
    .updated_at = "2026-07-27T00:00:00Z" |
    .author = "tester" |
    .complexity = {"level":"low","confirmed":true,"rationale":"bounded fixture","override_reason":null} |
    .review.summary = {"request":"Test request","intent":"Test intent","root_cause":"Test root cause","included":["one behavior"],"excluded":["unrelated behavior"],"success":"All AC pass","blockers":[]} |
    .review.primary_decisions = ["DEC-001"] |
    .review.primary_risks = ["RSK-001"] |
    .review.primary_diagrams = [] |
    .review.no_diagram_reason = "Low-complexity change has no architectural interaction." |
    .context_basis = {"disposition":"not_required","evidence_refs":[],"limitation_refs":[],"rationale":"Confirmed low-complexity fixture does not require project Context."} |
    .intent = {"request":"Test request","outcome":"Test intent","root_cause":"Test root cause"} |
    .scope."SCP-001" = {"kind":"include","statement":"one behavior","rationale":"fixture"} |
    .scope."SCP-002" = {"kind":"exclude","statement":"unrelated behavior","rationale":"fixture"} |
    .evidence."EVD-001" = {"kind":"user","source":"test fixture","summary":"Approved test input"} |
    .assumptions."ASM-001" = {"statement":"Fixture is isolated","validation":"temporary directory","status":"validated"} |
    .options."OPT-001" = {"summary":"Implement fixture","tradeoffs":"test only","disposition":"selected"} |
    .decisions."DEC-001" = {"summary":"Use deterministic fixture","rationale":"repeatable","tradeoffs":"none","option_refs":["OPT-001"]} |
    .requirements."REQ-001" = {"kind":"functional","statement":"Produce output","scope_refs":["SCP-001"],"evidence_refs":["EVD-001"]} |
    .interfaces."IFC-001" = {"name":"spec pair","kind":"file","description":"paired artifacts","contract_refs":["CTR-001"]} |
    .contracts."CTR-001" = {"statement":"The pair is current","applies_to":["IFC-001"],"requirement_refs":["REQ-001"]} |
    .invariants."INV-001" = {"statement":"YAML remains authoritative","scope_refs":["SCP-001"],"requirement_refs":["REQ-001"]} |
    .acceptance_criteria."AC-001" = {"requirement_refs":["REQ-001"],"given":"a valid source","when":"it is published","then":"both files are current","verification":"validate pair"} |
    .adversarial_findings."ADV-001" = {"dimension":"boundary_conditions","severity":"low","scenario":"missing projection","ac_refs":["AC-001"],"disposition":"cover","resolution_refs":["CTR-001"],"risk_refs":[]} |
    .risks."RSK-001" = {"severity":"low","statement":"fixture risk","mitigation":"isolated directory","status":"resolved","owner":"tester"} |
    .rollback = {"triggers":["publish failure"],"steps":["restore previous pair"],"impact":"No project impact"} |
    .approval = {"decision":"approved","approved_by":"tester","approved_at":"2026-07-27T00:00:00Z","record":"explicit fixture approval"}
  ' "${path}"
}

if ! command -v yq >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1; then
  printf '%s\n' 'Spec artifact tests require mikefarah/yq v4 and Git.' >&2
  exit 2
fi

printf '1..74\n'

DRAFT="${TEST_TMP}/draft.yaml"
make_draft "${DRAFT}" draft
run_command "${SPEC_EXECUTOR}" validate --source "${DRAFT}"
assert_status 0 'minimal incomplete Draft is structurally valid'
assert_output_contains '"ready":false' 'minimal Draft is not lifecycle-ready'

UNKNOWN="${TEST_TMP}/unknown.yaml"
cp "${DRAFT}" "${UNKNOWN}"
yq eval -i '.unexpected = true' "${UNKNOWN}"
run_command "${SPEC_EXECUTOR}" validate --source "${UNKNOWN}"
assert_status 1 'unknown top-level key fails validation'
assert_output_contains 'top_level.unknown.unexpected' 'unknown top-level key reports stable error ID'

BAD_ID="${TEST_TMP}/bad-id.yaml"
cp "${DRAFT}" "${BAD_ID}"
yq eval -i '.requirements."BAD-001" = {"kind":"functional","statement":"bad","scope_refs":[],"evidence_refs":[]}' "${BAD_ID}"
run_command "${SPEC_EXECUTOR}" validate --source "${BAD_ID}"
assert_status 1 'wrong stable ID prefix fails validation'
assert_output_contains 'collection.requirements.id_invalid' 'wrong prefix reports collection error'

DANGLING="${TEST_TMP}/dangling.yaml"
cp "${DRAFT}" "${DANGLING}"
yq eval -i '.requirements."REQ-001" = {"kind":"functional","statement":"bad ref","scope_refs":["SCP-999"],"evidence_refs":[]}' "${DANGLING}"
run_command "${SPEC_EXECUTOR}" validate --source "${DANGLING}"
assert_status 1 'dangling reference fails validation'
assert_output_contains 'collection.requirements.dangling.scope_refs' 'dangling reference reports target field'

READY="${TEST_TMP}/ready.yaml"
make_ready "${READY}" ready
run_command "${SPEC_EXECUTOR}" validate --source "${READY}"
assert_status 0 'complete source without projection is structurally valid'
assert_output_contains '"ready":false' 'projection currency is required for readiness'

RENDER_ONE="${TEST_TMP}/render-one.md"
RENDER_TWO="${TEST_TMP}/render-two.md"
run_command "${SPEC_EXECUTOR}" render --source "${READY}" --output "${RENDER_ONE}"
assert_status 0 'renderer creates Human projection'
run_command "${SPEC_EXECUTOR}" render --source "${READY}" --output "${RENDER_TWO}"
assert_status 0 'renderer repeats successfully'
assert_same_file "${RENDER_ONE}" "${RENDER_TWO}" 'same source renders byte-identically'

run_command "${SPEC_EXECUTOR}" validate --source "${READY}" --projection "${RENDER_ONE}" --readiness
assert_status 0 'complete pair passes readiness'
assert_output_contains '"ready":true' 'readiness JSON reports success'

printf '%s\n' 'manual edit' >>"${RENDER_ONE}"
run_command "${SPEC_EXECUTOR}" validate --source "${READY}" --projection "${RENDER_ONE}"
assert_status 1 'manual projection edit fails drift check'
assert_output_contains '"projection_current":false' 'manual edit reports stale projection'

run_command "${SPEC_EXECUTOR}" render --source "${READY}" --output "${RENDER_ONE}"
yq eval -i '.review.summary.success = "Changed source"' "${READY}"
run_command "${SPEC_EXECUTOR}" validate --source "${READY}" --projection "${RENDER_ONE}"
assert_status 1 'source change fails projection drift check'
assert_output_contains '"projection_current":false' 'source drift reports stale projection'

yq eval -i '.review.summary.success = "All AC pass"' "${READY}"
TARGET="${TEST_TMP}/specs/publish"
mkdir -p "$(dirname "${TARGET}")"
yq eval -i '.id = "publish" | .title = "Spec publish"' "${READY}"
run_command "${SPEC_EXECUTOR}" publish --candidate "${READY}" --target "${TARGET}"
assert_status 0 'publisher creates canonical pair'
if [ -f "${TARGET}/spec.yaml" ] && [ -f "${TARGET}/spec.md" ]; then pass 'publisher leaves both canonical files'; else fail 'publisher leaves both canonical files'; fi

cp "${TARGET}/spec.yaml" "${TEST_TMP}/published-before.yaml"
cp "${TARGET}/spec.md" "${TEST_TMP}/published-before.md"
PUBLISHED_SOURCE_INODE=$(stat -c '%i' "${TARGET}/spec.yaml")
PUBLISHED_PROJECTION_INODE=$(stat -c '%i' "${TARGET}/spec.md")
yq eval -i '.review.summary.success = "Replacement"' "${READY}"
run_command env THEMIS_SPEC_TEST_FAIL_AFTER_BACKUP=1 "${SPEC_EXECUTOR}" publish --candidate "${READY}" --target "${TARGET}"
assert_status 1 'failure after backup rejects publication'
assert_same_file "${TEST_TMP}/published-before.yaml" "${TARGET}/spec.yaml" 'failed publish restores prior source'
assert_same_file "${TEST_TMP}/published-before.md" "${TARGET}/spec.md" 'failed publish restores prior projection'
if [ "$(stat -c '%i' "${TARGET}/spec.yaml")" = "${PUBLISHED_SOURCE_INODE}" ] && [ "$(stat -c '%i' "${TARGET}/spec.md")" = "${PUBLISHED_PROJECTION_INODE}" ]; then pass 'failure after backup leaves canonical pair untouched'; else fail 'failure after backup leaves canonical pair untouched'; fi

BEFORE_SOURCE_INODE=$(stat -c '%i' "${TARGET}/spec.yaml")
BEFORE_PROJECTION_INODE=$(stat -c '%i' "${TARGET}/spec.md")
run_command env THEMIS_SPEC_TEST_INTERRUPT_BEFORE_SOURCE=1 "${SPEC_EXECUTOR}" publish --candidate "${READY}" --target "${TARGET}"
assert_status 1 'interruption before source rename rejects publication'
assert_same_file "${TEST_TMP}/published-before.yaml" "${TARGET}/spec.yaml" 'interruption before source rename preserves prior source'
assert_same_file "${TEST_TMP}/published-before.md" "${TARGET}/spec.md" 'interruption before source rename preserves prior projection'
if [ "$(stat -c '%i' "${TARGET}/spec.yaml")" = "${BEFORE_SOURCE_INODE}" ] && [ "$(stat -c '%i' "${TARGET}/spec.md")" = "${BEFORE_PROJECTION_INODE}" ]; then pass 'interruption before source rename leaves canonical pair untouched'; else fail 'interruption before source rename leaves canonical pair untouched'; fi
if ! compgen -G "${TEST_TMP}/specs/.themis-spec-publish.*" >/dev/null; then pass 'interruption before source rename cleans staging'; else fail 'interruption before source rename cleans staging'; fi

NEW_TARGET="${TEST_TMP}/specs/new"
yq eval -i '.id = "new" | .title = "Spec new"' "${READY}"
run_command env THEMIS_SPEC_TEST_FAIL_AFTER_SOURCE=1 "${SPEC_EXECUTOR}" publish --candidate "${READY}" --target "${NEW_TARGET}"
assert_status 1 'new-pair failure rejects publication'
if [ ! -e "${NEW_TARGET}/spec.yaml" ] && [ ! -e "${NEW_TARGET}/spec.md" ]; then pass 'new-pair failure leaves no half pair'; else fail 'new-pair failure leaves no half pair'; fi

RETIRED_SPEC_SCHEMA="${TEST_TMP}/retired-spec-schema.yaml"
make_ready "${RETIRED_SPEC_SCHEMA}" retired-spec-schema
yq eval -i '.spec_schema = "legacy-versioned-spec"' "${RETIRED_SPEC_SCHEMA}"
run_command "${SPEC_EXECUTOR}" validate --source "${RETIRED_SPEC_SCHEMA}"
assert_status 1 'retired Spec schema field fails validation'
assert_output_contains 'top_level.unknown.spec_schema' 'retired Spec schema reports unknown-key error'

CRITICAL_DEFER="${TEST_TMP}/critical-defer.yaml"
make_ready "${CRITICAL_DEFER}" critical-defer
yq eval -i '.adversarial_findings."ADV-001".dimension = "data_integrity" | .adversarial_findings."ADV-001".severity = "critical" | .adversarial_findings."ADV-001".disposition = "defer" | .adversarial_findings."ADV-001".resolution_refs = [] | .adversarial_findings."ADV-001".risk_refs = ["RSK-001"]' "${CRITICAL_DEFER}"
run_command "${SPEC_EXECUTOR}" validate --source "${CRITICAL_DEFER}"
assert_status 0 'critical defer remains structurally valid'
assert_output_contains '"id":"spec_adversarial_resolved","status":"fail"' 'critical data defer blocks readiness check'

FORGED_PROJECTION="${TEST_TMP}/forged-projection.md"
make_ready "${TEST_TMP}/forged-source.yaml" forged
run_command "${SPEC_EXECUTOR}" render --source "${TEST_TMP}/forged-source.yaml" --output "${FORGED_PROJECTION}"
assert_status 0 'forged-projection fixture renders successfully'
printf '%s\n' 'forged body' >>"${FORGED_PROJECTION}"
FORGED_BODY="${TEST_TMP}/forged-body.md"
sed '1d' "${FORGED_PROJECTION}" >"${FORGED_BODY}"
FORGED_BODY_OID=$(git hash-object -- "${FORGED_BODY}")
FORGED_MARKER=$(sed -n '1p' "${FORGED_PROJECTION}")
FORGED_SOURCE_OID=$(printf '%s\n' "${FORGED_MARKER}" | sed -n 's/.* source_oid=\([^ ]*\) body_oid=.*/\1/p')
{
  printf '<!-- themis-projection source=spec.yaml source_oid=%s body_oid=%s -->\n' "${FORGED_SOURCE_OID}" "${FORGED_BODY_OID}"
  cat "${FORGED_BODY}"
} >"${FORGED_PROJECTION}"
run_command "${SPEC_EXECUTOR}" validate --source "${TEST_TMP}/forged-source.yaml" --projection "${FORGED_PROJECTION}"
assert_status 1 'rehashed manual projection edit fails drift check'
assert_output_contains '"projection_current":false' 'rehashed edit cannot impersonate renderer output'

SAME_FILE="${TEST_TMP}/same-file.yaml"
make_ready "${SAME_FILE}" same-file
cp "${SAME_FILE}" "${TEST_TMP}/same-file-before.yaml"
run_command "${SPEC_EXECUTOR}" render --source "${SAME_FILE}" --output "${SAME_FILE}"
assert_status 1 'renderer rejects source and output as the same file'
assert_same_file "${TEST_TMP}/same-file-before.yaml" "${SAME_FILE}" 'same-file rejection preserves authoritative YAML'

TRAILING_ID="${TEST_TMP}/trailing-id.yaml"
make_draft "${TRAILING_ID}" trailing-id
yq eval -i '.requirements."REQ-001junk" = {"kind":"functional","statement":"bad suffix","scope_refs":[],"evidence_refs":[]}' "${TRAILING_ID}"
run_command "${SPEC_EXECUTOR}" validate --source "${TRAILING_ID}"
assert_status 1 'stable IDs reject trailing non-digits'
assert_output_contains 'collection.requirements.id_invalid' 'strict ID failure reports stable collection error'

WRONG_SCALAR="${TEST_TMP}/wrong-scalar.yaml"
make_ready "${WRONG_SCALAR}" wrong-scalar
yq eval -i '.acceptance_criteria."AC-001".then = []' "${WRONG_SCALAR}"
run_command "${SPEC_EXECUTOR}" validate --source "${WRONG_SCALAR}"
assert_status 1 'collection scalar with sequence type fails validation'
assert_output_contains 'collection.acceptance_criteria.type.then' 'collection scalar type reports stable error'

EMPTY_AC="${TEST_TMP}/empty-ac.yaml"
make_ready "${EMPTY_AC}" empty-ac
yq eval -i '.acceptance_criteria."AC-001".then = ""' "${EMPTY_AC}"
run_command "${SPEC_EXECUTOR}" validate --source "${EMPTY_AC}"
assert_status 0 'empty AC prose remains structurally valid Draft'
assert_output_contains '"id":"spec_design_acceptance_complete","status":"fail"' 'empty AC prose blocks design readiness'

QUESTIONING_FIELD="${TEST_TMP}/questioning-field.yaml"
make_ready "${QUESTIONING_FIELD}" questioning-field
yq eval -i '.questioning = {"intent_status":"complete"}' "${QUESTIONING_FIELD}"
run_command "${SPEC_EXECUTOR}" validate --source "${QUESTIONING_FIELD}"
assert_status 1 'questioning process state fails validation'
assert_output_contains 'top_level.unknown.questioning' 'questioning process state reports unknown-key error'

SUMMARY_MISMATCH="${TEST_TMP}/summary-mismatch.yaml"
make_ready "${SUMMARY_MISMATCH}" summary-mismatch
yq eval -i '.review.summary.intent = "Different intent"' "${SUMMARY_MISMATCH}"
run_command "${SPEC_EXECUTOR}" validate --source "${SUMMARY_MISMATCH}"
assert_status 0 'summary mismatch remains structurally valid Draft'
assert_output_contains '"id":"spec_self_check_passed","status":"fail"' 'summary mismatch blocks semantic consistency'

PLACEHOLDER="${TEST_TMP}/placeholder.yaml"
make_ready "${PLACEHOLDER}" placeholder
yq eval -i '.requirements."REQ-001".statement = "TODO implement output"' "${PLACEHOLDER}"
run_command "${SPEC_EXECUTOR}" validate --source "${PLACEHOLDER}"
assert_status 0 'placeholder remains structurally valid Draft'
assert_output_contains '"id":"spec_self_check_passed","status":"fail"' 'placeholder blocks semantic consistency'

GROUNDED="${TEST_TMP}/grounded.yaml"
make_ready "${GROUNDED}" grounded
yq eval -i '.context_basis = {"disposition":"grounded","evidence_refs":["EVD-001"],"limitation_refs":[],"rationale":"Verified from project evidence."} | .evidence."EVD-001".kind = "code"' "${GROUNDED}"
run_command "${SPEC_EXECUTOR}" validate --source "${GROUNDED}"
assert_status 0 'grounded Context basis is structurally valid'
assert_output_contains '"id":"spec_context_complete","status":"pass"' 'grounded Context evidence passes readiness'

LIMITED="${TEST_TMP}/limited.yaml"
make_ready "${LIMITED}" limited
yq eval -i '.complexity.level = "medium" | .context_basis = {"disposition":"limited","evidence_refs":["EVD-001"],"limitation_refs":["ASM-001"],"rationale":"Available evidence has a validated limitation."}' "${LIMITED}"
run_command "${SPEC_EXECUTOR}" validate --source "${LIMITED}"
assert_status 1 'medium fixture without required diagram remains invalid'
assert_output_contains '"id":"spec_context_complete","status":"pass"' 'limited resolved evidence passes Context readiness'

DANGLING_CONTEXT="${TEST_TMP}/dangling-context.yaml"
make_ready "${DANGLING_CONTEXT}" dangling-context
yq eval -i '.context_basis = {"disposition":"grounded","evidence_refs":["EVD-999"],"limitation_refs":[],"rationale":"invalid fixture"}' "${DANGLING_CONTEXT}"
run_command "${SPEC_EXECUTOR}" validate --source "${DANGLING_CONTEXT}"
assert_status 1 'dangling Context evidence fails validation'
assert_output_contains 'context_basis.dangling.evidence_refs' 'dangling Context evidence reports stable error'

MIGRATION_FIELD="${TEST_TMP}/migration-field.yaml"
make_ready "${MIGRATION_FIELD}" migration-field
yq eval -i '.migration = {"status":"review_required"}' "${MIGRATION_FIELD}"
run_command "${SPEC_EXECUTOR}" validate --source "${MIGRATION_FIELD}"
assert_status 1 'Spec migration field fails validation'
assert_output_contains 'top_level.unknown.migration' 'Spec migration field reports unknown-key error'

BACKUP_FAILURE_SOURCE="${TEST_TMP}/backup-failure.yaml"
make_ready "${BACKUP_FAILURE_SOURCE}" backup-failure
BACKUP_FAILURE_TARGET="${TEST_TMP}/specs/backup-failure"
run_command "${SPEC_EXECUTOR}" publish --candidate "${BACKUP_FAILURE_SOURCE}" --target "${BACKUP_FAILURE_TARGET}"
assert_status 0 'backup-failure fixture publishes initial pair'
cp "${BACKUP_FAILURE_TARGET}/spec.yaml" "${TEST_TMP}/backup-failure-before.yaml"
cp "${BACKUP_FAILURE_TARGET}/spec.md" "${TEST_TMP}/backup-failure-before.md"
yq eval -i '.review.summary.success = "replacement should fail"' "${BACKUP_FAILURE_SOURCE}"
run_command env THEMIS_SPEC_TEST_FAIL_PROJECTION_BACKUP=1 "${SPEC_EXECUTOR}" publish --candidate "${BACKUP_FAILURE_SOURCE}" --target "${BACKUP_FAILURE_TARGET}"
assert_status 1 'projection backup failure rejects publication'
assert_same_file "${TEST_TMP}/backup-failure-before.yaml" "${BACKUP_FAILURE_TARGET}/spec.yaml" 'projection backup failure preserves prior source'
assert_same_file "${TEST_TMP}/backup-failure-before.md" "${BACKUP_FAILURE_TARGET}/spec.md" 'projection backup failure preserves prior projection'

RESTORE_FAILURE_SOURCE="${TEST_TMP}/restore-failure.yaml"
make_ready "${RESTORE_FAILURE_SOURCE}" restore-failure
RESTORE_FAILURE_TARGET="${TEST_TMP}/specs/restore-failure"
run_command "${SPEC_EXECUTOR}" publish --candidate "${RESTORE_FAILURE_SOURCE}" --target "${RESTORE_FAILURE_TARGET}"
assert_status 0 'restore-failure fixture publishes initial pair'
cp "${RESTORE_FAILURE_TARGET}/spec.yaml" "${TEST_TMP}/restore-failure-before.yaml"
cp "${RESTORE_FAILURE_TARGET}/spec.md" "${TEST_TMP}/restore-failure-before.md"
yq eval -i '.review.summary.success = "replacement triggers failed recovery"' "${RESTORE_FAILURE_SOURCE}"
run_command env THEMIS_SPEC_TEST_FAIL_AFTER_SOURCE=1 THEMIS_SPEC_TEST_FAIL_RESTORE_PROJECTION=1 "${SPEC_EXECUTOR}" publish --candidate "${RESTORE_FAILURE_SOURCE}" --target "${RESTORE_FAILURE_TARGET}"
assert_status 1 'pair restore failure rejects publication'
RESTORE_RECOVERY_PATH=$(printf '%s' "${LAST_OUTPUT}" | sed -n 's/.*"recovery_path":"\([^"]*\)".*/\1/p')
if [ -n "${RESTORE_RECOVERY_PATH}" ] && cmp -s "${TEST_TMP}/restore-failure-before.yaml" "${RESTORE_RECOVERY_PATH}/backup/spec.yaml" && cmp -s "${TEST_TMP}/restore-failure-before.md" "${RESTORE_RECOVERY_PATH}/backup/spec.md"; then pass 'pair restore failure preserves complete prior pair backup'; else fail 'pair restore failure preserves complete prior pair backup' "output: ${LAST_OUTPUT}"; fi

INTERRUPTED_SOURCE="${TEST_TMP}/interrupted.yaml"
make_ready "${INTERRUPTED_SOURCE}" interrupted
INTERRUPTED_TARGET="${TEST_TMP}/specs/interrupted"
run_command "${SPEC_EXECUTOR}" publish --candidate "${INTERRUPTED_SOURCE}" --target "${INTERRUPTED_TARGET}"
assert_status 0 'interruption fixture publishes initial pair'
cp "${INTERRUPTED_TARGET}/spec.yaml" "${TEST_TMP}/interrupted-before.yaml"
cp "${INTERRUPTED_TARGET}/spec.md" "${TEST_TMP}/interrupted-before.md"
yq eval -i '.review.summary.success = "replacement interrupted after source"' "${INTERRUPTED_SOURCE}"
run_command env THEMIS_SPEC_TEST_INTERRUPT_AFTER_SOURCE=1 "${SPEC_EXECUTOR}" publish --candidate "${INTERRUPTED_SOURCE}" --target "${INTERRUPTED_TARGET}"
assert_status 1 'interruption after source rename rejects publication'
assert_same_file "${TEST_TMP}/interrupted-before.yaml" "${INTERRUPTED_TARGET}/spec.yaml" 'interruption restores prior source'
assert_same_file "${TEST_TMP}/interrupted-before.md" "${INTERRUPTED_TARGET}/spec.md" 'interruption restores prior projection'

INTERRUPTED_NEW_SOURCE="${TEST_TMP}/interrupted-new.yaml"
make_ready "${INTERRUPTED_NEW_SOURCE}" interrupted-new
INTERRUPTED_NEW_TARGET="${TEST_TMP}/specs/interrupted-new"
run_command env THEMIS_SPEC_TEST_INTERRUPT_AFTER_SOURCE=1 "${SPEC_EXECUTOR}" publish --candidate "${INTERRUPTED_NEW_SOURCE}" --target "${INTERRUPTED_NEW_TARGET}"
assert_status 1 'first publication interruption rejects publication'
if [ ! -e "${INTERRUPTED_NEW_TARGET}/spec.yaml" ] && [ ! -e "${INTERRUPTED_NEW_TARGET}/spec.md" ]; then pass 'first publication interruption leaves no half pair'; else fail 'first publication interruption leaves no half pair'; fi

if [ "${TEST_FAILURES}" -ne 0 ]; then
  printf '%s of %s tests failed\n' "${TEST_FAILURES}" "${TEST_COUNT}" >&2
  exit 1
fi
printf 'All %s tests passed\n' "${TEST_COUNT}"
