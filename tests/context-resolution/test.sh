#!/usr/bin/env bash
#
# Themis Context Resolution TAP 测试。
# 用途：覆盖 Catalog、Search、Bundle、Freshness、Navigation、路径、锁与事务恢复的最小闭环。
# 边界：所有写入都发生在隔离临时项目中，不修改源模板或仓库状态。
#
set -uo pipefail

TEST_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
TEMPLATE_ROOT="${TEST_ROOT}/templates/.themis"
CONTEXT_BIN="${TEMPLATE_ROOT}/core/bin"
TEST_TMP=${TMPDIR:-/tmp}/themis-context-resolution-$$
YQ_EXECUTABLE=${YQ:-yq}
TEST_COUNT=0
TEST_FAILURES=0
LAST_OUTPUT=
LAST_ERROR=
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

run_context() {
  local stdout_file="${TEST_TMP}/stdout"
  local stderr_file="${TEST_TMP}/stderr"
  : >"${stdout_file}"
  : >"${stderr_file}"
  "$@" >"${stdout_file}" 2>"${stderr_file}"
  LAST_STATUS=$?
  LAST_OUTPUT=$(cat "${stdout_file}")
  LAST_ERROR=$(cat "${stderr_file}")
}

assert_status() {
  if [ "${LAST_STATUS}" -eq "$1" ]; then
    pass "$2"
  else
    fail "$2" "expected status $1, got ${LAST_STATUS}; stdout: ${LAST_OUTPUT}; stderr: ${LAST_ERROR}"
  fi
}

assert_json_result() {
  local expected_status=$1
  local name=$2
  local lines
  lines=$(printf '%s\n' "${LAST_OUTPUT}" | wc -l | tr -d '[:space:]')
  if [ "${lines}" -eq 1 ] &&
     printf '%s' "${LAST_OUTPUT}" | "${YQ_EXECUTABLE}" -p=json eval -e ".schema == \"themis-context-result\" and .status == \"${expected_status}\"" - >/dev/null 2>&1; then
    pass "${name}"
  else
    fail "${name}" "invalid result envelope: ${LAST_OUTPUT}"
  fi
}

assert_json_value() {
  local expression=$1
  local expected=$2
  local name=$3
  local actual
  actual=$(printf '%s' "${LAST_OUTPUT}" | "${YQ_EXECUTABLE}" -p=json eval -r "${expression}" - 2>/dev/null || true)
  if [ "${actual}" = "${expected}" ]; then
    pass "${name}"
  else
    fail "${name}" "expected ${expected}, got ${actual}; result: ${LAST_OUTPUT}"
  fi
}

assert_result_error() {
  local error_id=$1
  local name=$2
  if printf '%s' "${LAST_OUTPUT}" | ERROR_ID=${error_id} "${YQ_EXECUTABLE}" -p=json eval -e '.errors[] | select(.id == env(ERROR_ID))' - >/dev/null 2>&1; then
    pass "${name}"
  else
    fail "${name}" "missing error ${error_id}: ${LAST_OUTPUT}"
  fi
}

make_project() {
  local name=$1
  local project="${TEST_TMP}/${name}"
  mkdir -p "${project}"
  cp -R "${TEMPLATE_ROOT}" "${project}/.themis"
  PROJECT_NAME=${name} "${YQ_EXECUTABLE}" eval -i '.project.name = strenv(PROJECT_NAME)' "${project}/.themis/workspace/manifest.yaml"
  printf '%s\n' "${project}"
}

body_digest() {
  printf '%s' "$1" | sha256sum | cut -d' ' -f1
}

write_item() {
  local workspace=$1
  local relative=$2
  local id=$3
  local title=$4
  local category=$5
  local status=$6
  local body=$7
  local scope=${8:-demo}
  local dependencies=${9:-[]}
  local supersedes=${10:-[]}
  local target="${workspace}/context/${relative}"
  local digest
  digest=$(body_digest "${body}")
  mkdir -p "$(dirname -- "${target}")"
  cat >"${target}" <<EOF
---
context_item_schema: themis-context-item
id: ${id}
title: ${title}
category: ${category}
kind: reference
authority: governed
status: ${status}
scope: [${scope}]
tags: [sample]
abstract: ${title} abstract
overview: ${title} overview
source_refs: []
dependencies: ${dependencies}
supersedes: ${supersedes}
content_digest: sha256:${digest}
---
${body}
EOF
}

catalog_digest() {
  "${YQ_EXECUTABLE}" eval -r '.catalog_digest' "$1/context/catalog.yaml"
}

bundle_id_from_result() {
  printf '%s' "${LAST_OUTPUT}" | "${YQ_EXECUTABLE}" -p=json eval -r '.data.bundle_id' -
}

rewrite_projection_digest() {
  local file=$1
  local frontmatter="${TEST_TMP}/projection-frontmatter.yaml"
  local body="${TEST_TMP}/projection-body.md"
  local digest
  awk 'NR == 1 { next } $0 == "---" { exit } { print }' "${file}" >"${frontmatter}"
  awk 'BEGIN { separators=0 } $0 == "---" { separators++; next } separators >= 2 { print }' "${file}" >"${body}"
  digest=$(
    {
      "${YQ_EXECUTABLE}" -o=json -I=0 'del(.projection_digest, .generated_at) | sort_keys(..)' "${frontmatter}"
      cat "${body}"
    } | sha256sum | cut -d' ' -f1
  )
  PROJECTION_DIGEST="sha256:${digest}" "${YQ_EXECUTABLE}" eval -i '.projection_digest = strenv(PROJECTION_DIGEST)' "${frontmatter}"
  {
    printf '%s\n' '---'
    cat "${frontmatter}"
    printf '%s\n' '---'
    cat "${body}"
  } >"${file}"
}

if ! command -v "${YQ_EXECUTABLE}" >/dev/null 2>&1 || ! command -v sha256sum >/dev/null 2>&1; then
  printf '%s\n' 'Context Resolution tests require mikefarah/yq v4 and sha256sum.' >&2
  exit 2
fi
case "$("${YQ_EXECUTABLE}" --version 2>&1)" in
  *mikefarah/yq*version\ v4.*) ;;
  *) printf '%s\n' 'Context Resolution tests require mikefarah/yq v4.' >&2; exit 2 ;;
esac

PROJECT=$(make_project primary)
WORKSPACE="${PROJECT}/.themis/workspace"
CATALOG_EXEC="${CONTEXT_BIN}/themis-context-catalog.sh"
LINT_EXEC="${CONTEXT_BIN}/themis-context-lint.sh"
SEARCH_EXEC="${CONTEXT_BIN}/themis-context-search.sh"
ASSEMBLE_EXEC="${CONTEXT_BIN}/themis-context-assemble.sh"
FRESHNESS_EXEC="${CONTEXT_BIN}/themis-context-freshness.sh"
NAVIGATION_EXEC="${CONTEXT_BIN}/themis-context-navigation.sh"

run_context bash "${LINT_EXEC}" lint --workspace "${WORKSPACE}"
assert_status 0 'bootstrap Context lint succeeds'
assert_json_result ok 'bootstrap lint emits one valid JSON result'
assert_json_value '.data.checked' 0 'bootstrap Catalog contains no registered Items'

run_context bash "${NAVIGATION_EXEC}" status --workspace "${WORKSPACE}"
assert_status 0 'bootstrap navigation status succeeds'
assert_json_value '.data.current' true 'bootstrap navigation is current'

run_context bash "${SEARCH_EXEC}" query --workspace "${WORKSPACE}" --term missing
assert_status 0 'empty Catalog search succeeds'
assert_json_value '.data.count' 0 'empty Catalog search returns no candidates'
assert_json_value '.warnings[0].id' missing_context_candidate 'empty Catalog search reports stable missing warning'

run_context bash "${CATALOG_EXEC}" bind --workspace "${WORKSPACE}" --project-root "${PROJECT}"
assert_status 0 'non-Git Catalog bind succeeds'
assert_json_result ok 'Catalog bind emits one valid JSON result'
assert_json_value '.data.binding' bound 'Catalog bind records bound state'
if [ "$("${YQ_EXECUTABLE}" eval -r '.revision.kind' "${WORKSPACE}/context/catalog.yaml")" = unavailable ]; then
  pass 'non-Git Catalog bind records unavailable revision'
else
  fail 'non-Git Catalog bind records unavailable revision'
fi

BOUND_DIGEST=$(catalog_digest "${WORKSPACE}")
run_context bash "${CATALOG_EXEC}" bind --workspace "${WORKSPACE}" --project-root "${PROJECT}"
assert_status 0 'binding the same logical Workspace is idempotent'
assert_json_value '.data.catalog_digest' "${BOUND_DIGEST}" 'idempotent bind preserves Catalog digest'

CLONE_PROJECT="${TEST_TMP}/portable-clone"
cp -R "${PROJECT}" "${CLONE_PROJECT}"
run_context bash "${CATALOG_EXEC}" bind --workspace "${CLONE_PROJECT}/.themis/workspace" --project-root "${CLONE_PROJECT}"
assert_status 0 'bound Catalog remains valid after project clone'
assert_json_value '.data.catalog_digest' "${BOUND_DIGEST}" 'clone-portable Workspace identity preserves Catalog digest'

run_context bash "${CATALOG_EXEC}" check --workspace "${WORKSPACE}" --project-root "${CLONE_PROJECT}"
assert_status 2 'Catalog check rejects a different explicit project root'
assert_result_error project_workspace_mismatch 'project mismatch reports stable error ID'

printf -v UNICODE_BODY '%s\n' '# 术语' '' '字节匹配。'
write_item "${CLONE_PROJECT}/.themis/workspace" 'glossary/unicode.md' CTX-010 术语 glossary active "${UNICODE_BODY}"
run_context bash "${CATALOG_EXEC}" register --workspace "${CLONE_PROJECT}/.themis/workspace" --item context/glossary/unicode.md --expected-catalog-digest "$(catalog_digest "${CLONE_PROJECT}/.themis/workspace")"
assert_status 0 'non-ASCII search fixture registers successfully'
run_context bash "${SEARCH_EXEC}" query --workspace "${CLONE_PROJECT}/.themis/workspace" --term 术语
assert_status 0 'non-ASCII byte term search succeeds'
assert_json_value '.data.candidates[0].id' CTX-010 'non-ASCII byte term search returns the matching Item'

printf -v BODY_ONE '%s\n' '# Alpha' '' 'Governed alpha fact.'
printf -v BODY_TWO '%s\n' '# Zeta' '' 'Governed zeta fact.'
write_item "${WORKSPACE}" 'domain/zeta.md' CTX-002 Zeta domain active "${BODY_TWO}"
write_item "${WORKSPACE}" 'domain/alpha.md' CTX-001 Alpha domain active "${BODY_ONE}"

EXPECTED=$(catalog_digest "${WORKSPACE}")
run_context bash "${CATALOG_EXEC}" register --workspace "${WORKSPACE}" --item context/domain/zeta.md --expected-catalog-digest "${EXPECTED}"
assert_status 0 'first governed Item registration succeeds'
assert_json_value '.data.binding' bound 'registration preserves Catalog binding'

STALE_EXPECTED=${EXPECTED}
EXPECTED=$(catalog_digest "${WORKSPACE}")
run_context bash "${CATALOG_EXEC}" register --workspace "${WORKSPACE}" --item context/domain/alpha.md --expected-catalog-digest "${EXPECTED}"
assert_status 0 'second governed Item registration succeeds'
assert_json_value '.data.catalog_digest' "$(catalog_digest "${WORKSPACE}")" 'registration returns current Catalog digest'

CURRENT_DIGEST=$(catalog_digest "${WORKSPACE}")
run_context bash "${CATALOG_EXEC}" register --workspace "${WORKSPACE}" --item context/domain/alpha.md --expected-catalog-digest "${CURRENT_DIGEST}"
assert_status 0 'identical Item registration is idempotent'
assert_json_value '.data.catalog_digest' "${CURRENT_DIGEST}" 'idempotent registration preserves Catalog digest'

run_context bash "${CATALOG_EXEC}" register --workspace "${WORKSPACE}" --item context/domain/alpha.md --expected-catalog-digest "${STALE_EXPECTED}"
assert_status 2 'stale expected Catalog digest requires adjudication'
assert_json_result needs_adjudication 'optimistic conflict uses adjudication result status'
assert_result_error catalog_digest_conflict 'optimistic conflict reports stable error ID'

run_context bash "${SEARCH_EXEC}" query --workspace "${WORKSPACE}" --category domain --term GOVERNED
assert_status 0 'ASCII case-fold search succeeds'
assert_json_value '.data.count' 2 'ASCII case-fold search finds both Items'
assert_json_value '.data.candidates[0].id' CTX-001 'search sorts candidates by category, path, and ID'
assert_json_value '.warnings[0].id' navigation_stale 'Catalog search remains available when navigation is stale'

run_context bash "${SEARCH_EXEC}" query --workspace "${WORKSPACE}" --id CTX-002 --limit 1
assert_status 0 'exact-ID search succeeds'
assert_json_value '.data.candidates[0].id' CTX-002 'exact-ID search returns the requested Item'

run_context bash "${LINT_EXEC}" lint --workspace "${WORKSPACE}" --kind item --path ../manifest.yaml
assert_status 1 'parent path escape is rejected'
assert_result_error context_artifact_invalid 'parent path escape reports stable invalid artifact error'

run_context bash "${LINT_EXEC}" lint --workspace "${WORKSPACE}" --kind item --path "${WORKSPACE}/context/domain/alpha.md"
assert_status 1 'absolute path is rejected'

run_context bash "${LINT_EXEC}" lint --workspace "${WORKSPACE}" --kind item --path context//domain/alpha.md
assert_status 1 'empty path segment is rejected'

OUTSIDE_FILE="${TEST_TMP}/outside.md"
printf '%s\n' 'outside' >"${OUTSIDE_FILE}"
if ln -s "${OUTSIDE_FILE}" "${WORKSPACE}/context/domain/link.md" 2>/dev/null; then
  run_context bash "${LINT_EXEC}" lint --workspace "${WORKSPACE}" --kind item --path context/domain/link.md
  assert_status 1 'symbolic-link Item escape is rejected'
else
  pass 'symbolic-link escape test unavailable on this platform'
fi

MALFORMED_PROJECT=$(make_project malformed-item)
MALFORMED_WORKSPACE="${MALFORMED_PROJECT}/.themis/workspace"
run_context bash "${CATALOG_EXEC}" bind --workspace "${MALFORMED_WORKSPACE}" --project-root "${MALFORMED_PROJECT}"
printf -v BAD_BODY '%s\n' '# Bad' '' 'Bad fact.'
write_item "${MALFORMED_WORKSPACE}" 'domain/bad.md' CTX-010 $'Bad\tTitle' domain active "${BAD_BODY}"
run_context bash "${CATALOG_EXEC}" register --workspace "${MALFORMED_WORKSPACE}" --item context/domain/bad.md --expected-catalog-digest "$(catalog_digest "${MALFORMED_WORKSPACE}")"
assert_status 1 'Item metadata control characters are rejected'
assert_result_error context_item_invalid 'invalid Item metadata reports stable error ID'

GRAPH_PROJECT=$(make_project catalog-graph)
GRAPH_WORKSPACE="${GRAPH_PROJECT}/.themis/workspace"
run_context bash "${CATALOG_EXEC}" bind --workspace "${GRAPH_WORKSPACE}" --project-root "${GRAPH_PROJECT}"
printf -v GRAPH_BODY_A '%s\n' '# Graph A' '' 'Graph A fact.'
printf -v GRAPH_BODY_B '%s\n' '# Graph B' '' 'Graph B fact.'
write_item "${GRAPH_WORKSPACE}" 'domain/a.md' CTX-020 GraphA domain active "${GRAPH_BODY_A}" demo '[CTX-999]'
run_context bash "${CATALOG_EXEC}" register --workspace "${GRAPH_WORKSPACE}" --item context/domain/a.md --expected-catalog-digest "$(catalog_digest "${GRAPH_WORKSPACE}")"
assert_status 1 'Catalog registration rejects dangling Context references'
assert_result_error catalog_reference_or_cycle_invalid 'dangling reference reports stable Catalog graph error'

write_item "${GRAPH_WORKSPACE}" 'domain/a.md' CTX-020 GraphA domain active "${GRAPH_BODY_A}"
run_context bash "${CATALOG_EXEC}" register --workspace "${GRAPH_WORKSPACE}" --item context/domain/a.md --expected-catalog-digest "$(catalog_digest "${GRAPH_WORKSPACE}")"
assert_status 0 'Catalog graph fixture registers first Item'
write_item "${GRAPH_WORKSPACE}" 'domain/b.md' CTX-021 GraphB domain active "${GRAPH_BODY_B}" demo '[]' '[CTX-020]'
run_context bash "${CATALOG_EXEC}" register --workspace "${GRAPH_WORKSPACE}" --item context/domain/b.md --expected-catalog-digest "$(catalog_digest "${GRAPH_WORKSPACE}")"
assert_status 0 'Catalog graph fixture registers one-way supersession'
write_item "${GRAPH_WORKSPACE}" 'domain/a.md' CTX-020 GraphA domain active "${GRAPH_BODY_A}" demo '[]' '[CTX-021]'
run_context bash "${CATALOG_EXEC}" register --workspace "${GRAPH_WORKSPACE}" --item context/domain/a.md --expected-catalog-digest "$(catalog_digest "${GRAPH_WORKSPACE}")"
assert_status 1 'Catalog registration rejects supersession cycles'
assert_result_error catalog_reference_or_cycle_invalid 'supersession cycle reports stable Catalog graph error'

write_item "${GRAPH_WORKSPACE}" 'domain/a.md' CTX-020 GraphA domain deprecated "${GRAPH_BODY_A}"
run_context bash "${CATALOG_EXEC}" register --workspace "${GRAPH_WORKSPACE}" --item context/domain/a.md --expected-catalog-digest "$(catalog_digest "${GRAPH_WORKSPACE}")"
assert_status 0 'Catalog permits governed status update at the same ID and path'
run_context bash "${CATALOG_EXEC}" remove --workspace "${GRAPH_WORKSPACE}" --id CTX-020 --expected-catalog-digest "$(catalog_digest "${GRAPH_WORKSPACE}")"
assert_status 2 'referenced deprecated Item still requires adjudication before removal'
assert_result_error context_remove_requires_adjudication 'referenced removal reports stable adjudication error'
write_item "${GRAPH_WORKSPACE}" 'domain/b.md' CTX-021 GraphB domain archived "${GRAPH_BODY_B}"
run_context bash "${CATALOG_EXEC}" register --workspace "${GRAPH_WORKSPACE}" --item context/domain/b.md --expected-catalog-digest "$(catalog_digest "${GRAPH_WORKSPACE}")"
run_context bash "${CATALOG_EXEC}" remove --workspace "${GRAPH_WORKSPACE}" --id CTX-021 --expected-catalog-digest "$(catalog_digest "${GRAPH_WORKSPACE}")"
assert_status 0 'unreferenced archived Item can be removed without deleting L3'
if [ -f "${GRAPH_WORKSPACE}/context/domain/b.md" ]; then
  pass 'Catalog removal preserves the governed L3 file'
else
  fail 'Catalog removal preserves the governed L3 file'
fi

REQUEST_PATH="${WORKSPACE}/cache/context-request.yaml"
cat >"${REQUEST_PATH}" <<'EOF'
intent: Resolve governed demo context
spec_ref: null
task_ref: TASK-001
scope: [demo]
filters:
  category: domain
  terms: [governed]
token_budget: 1000
content_budget_bytes: 4096
EOF
run_context bash "${ASSEMBLE_EXEC}" prepare --workspace "${WORKSPACE}" --request cache/context-request.yaml
assert_status 0 'Bundle prepare succeeds'
assert_json_result ok 'Bundle prepare emits one valid JSON result'
BUNDLE_ID=$(bundle_id_from_result)
if printf '%s' "${BUNDLE_ID}" | grep -E '^CBL-[0-9a-f]{64}$' >/dev/null 2>&1; then
  pass 'Bundle prepare returns stable content-derived ID'
else
  fail 'Bundle prepare returns stable content-derived ID' "unexpected ID: ${BUNDLE_ID}"
fi

cat >"${WORKSPACE}/cache/invalid-selection.yaml" <<'EOF'
selected:
  - id: CTX-999
    reason: outside prepared candidates
excluded: []
EOF
run_context bash "${ASSEMBLE_EXEC}" select --workspace "${WORKSPACE}" --bundle "${BUNDLE_ID}" --selection cache/invalid-selection.yaml
assert_status 1 'out-of-bounds Bundle selection fails closed'
assert_result_error context_selection_out_of_bounds 'out-of-bounds selection reports stable error ID'

cat >"${WORKSPACE}/cache/selection.yaml" <<'EOF'
selected:
  - id: CTX-001
    reason: required alpha rule
excluded:
  - id: CTX-002
    reason: unrelated zeta rule
EOF
run_context bash "${ASSEMBLE_EXEC}" select --workspace "${WORKSPACE}" --bundle "${BUNDLE_ID}" --selection cache/selection.yaml
assert_status 0 'bounded Bundle selection succeeds'
run_context bash "${ASSEMBLE_EXEC}" finalize --workspace "${WORKSPACE}" --bundle "${BUNDLE_ID}"
assert_status 0 'non-Git Bundle finalize succeeds'
assert_json_value '.data.status' unavailable 'non-Git Bundle does not claim complete status'
if grep -F 'Governed alpha fact.' "${WORKSPACE}/cache/resolved-context/${BUNDLE_ID}/context.md" >/dev/null 2>&1 &&
   ! grep -F 'Governed zeta fact.' "${WORKSPACE}/cache/resolved-context/${BUNDLE_ID}/context.md" >/dev/null 2>&1; then
  pass 'Bundle context contains only selected governed L3 bodies'
else
  fail 'Bundle context contains only selected governed L3 bodies'
fi

rm -rf "${WORKSPACE}/cache/resolved-context/${BUNDLE_ID}"
run_context bash "${ASSEMBLE_EXEC}" prepare --workspace "${WORKSPACE}" --request cache/context-request.yaml
REBUILT_ID=$(bundle_id_from_result)
run_context bash "${ASSEMBLE_EXEC}" select --workspace "${WORKSPACE}" --bundle "${REBUILT_ID}" --selection cache/selection.yaml
run_context bash "${ASSEMBLE_EXEC}" finalize --workspace "${WORKSPACE}" --bundle "${REBUILT_ID}"
assert_status 0 'deleted Bundle Cache can be rebuilt'
if [ "${REBUILT_ID}" = "${BUNDLE_ID}" ]; then
  pass 'Bundle rebuild preserves deterministic ID'
else
  fail 'Bundle rebuild preserves deterministic ID' "expected ${BUNDLE_ID}, got ${REBUILT_ID}"
fi

cp "${WORKSPACE}/cache/resolved-context/${BUNDLE_ID}/manifest.yaml" "${WORKSPACE}/cache/malformed-bundle.yaml"
"${YQ_EXECUTABLE}" eval -i '.status = "broken"' "${WORKSPACE}/cache/malformed-bundle.yaml"
run_context bash "${LINT_EXEC}" lint --workspace "${WORKSPACE}" --kind bundle --path cache/malformed-bundle.yaml
assert_status 1 'shared Bundle validator rejects a malformed manifest'
assert_result_error context_artifact_invalid 'malformed Bundle reports stable lint error ID'
rm "${WORKSPACE}/cache/malformed-bundle.yaml"

cat >"${WORKSPACE}/cache/tiny-context-request.yaml" <<'EOF'
intent: Exceed deterministic content budget
spec_ref: null
task_ref: TASK-001
scope: [demo]
filters:
  category: domain
  terms: [governed]
token_budget: 1000
content_budget_bytes: 1
EOF
run_context bash "${ASSEMBLE_EXEC}" prepare --workspace "${WORKSPACE}" --request cache/tiny-context-request.yaml
TINY_BUNDLE_ID=$(bundle_id_from_result)
run_context bash "${ASSEMBLE_EXEC}" select --workspace "${WORKSPACE}" --bundle "${TINY_BUNDLE_ID}" --selection cache/selection.yaml
assert_status 0 'tiny-budget Bundle accepts a bounded selection'
run_context bash "${ASSEMBLE_EXEC}" finalize --workspace "${WORKSPACE}" --bundle "${TINY_BUNDLE_ID}"
assert_status 1 'Bundle finalization enforces content budget bytes'
assert_result_error context_budget_exceeded 'content budget overflow reports stable error ID'

cp "${WORKSPACE}/context/catalog.yaml" "${TEST_TMP}/catalog-before-freshness.yaml"
printf '%s\n' 'drifted body' >>"${WORKSPACE}/context/domain/alpha.md"
run_context bash "${FRESHNESS_EXEC}" check --workspace "${WORKSPACE}" --id CTX-001
assert_status 0 'Freshness check reports drift without failing execution'
assert_json_value '.data.items[0].signal_kind' stale 'Freshness check classifies Item digest drift as stale'
if cmp -s "${WORKSPACE}/context/catalog.yaml" "${TEST_TMP}/catalog-before-freshness.yaml" &&
   ! compgen -G "${WORKSPACE}/state/context-signals/*.yaml" >/dev/null; then
  pass 'Freshness check is read-only for Catalog, L3, and Signal state'
else
  fail 'Freshness check is read-only for Catalog, L3, and Signal state'
fi
printf '%s' "${LAST_OUTPUT}" | "${YQ_EXECUTABLE}" -p=json eval '.data' - >"${WORKSPACE}/cache/freshness-report.yaml"
SIGNAL_ID=$(printf '%s' "${LAST_OUTPUT}" | "${YQ_EXECUTABLE}" -p=json eval -r '.data.items[0].signal_id' -)
run_context bash "${FRESHNESS_EXEC}" record --workspace "${WORKSPACE}" --report cache/freshness-report.yaml
assert_status 0 'Freshness report records a persistent Signal'
if [ -f "${WORKSPACE}/state/context-signals/${SIGNAL_ID}.yaml" ]; then
  pass 'Freshness record writes the deterministic Signal ID'
else
  fail 'Freshness record writes the deterministic Signal ID'
fi

cp "${WORKSPACE}/state/context-signals/${SIGNAL_ID}.yaml" "${TEST_TMP}/valid-signal.yaml"
printf '%s\n' 'broken: [yaml' >"${WORKSPACE}/state/context-signals/${SIGNAL_ID}.yaml"
run_context bash "${FRESHNESS_EXEC}" record --workspace "${WORKSPACE}" --report cache/freshness-report.yaml
assert_status 2 'recording over a malformed existing Signal fails closed'
assert_result_error context_signal_invalid 'malformed existing Signal reports stable error ID'
if grep -F 'broken: [yaml' "${WORKSPACE}/state/context-signals/${SIGNAL_ID}.yaml" >/dev/null 2>&1; then
  pass 'malformed existing Signal is preserved for adjudication'
else
  fail 'malformed existing Signal is preserved for adjudication'
fi
mv "${TEST_TMP}/valid-signal.yaml" "${WORKSPACE}/state/context-signals/${SIGNAL_ID}.yaml"
cp "${WORKSPACE}/state/context-signals/${SIGNAL_ID}.yaml" "${WORKSPACE}/cache/malformed-signal.yaml"
"${YQ_EXECUTABLE}" eval -i '.kind = "broken"' "${WORKSPACE}/cache/malformed-signal.yaml"
run_context bash "${LINT_EXEC}" lint --workspace "${WORKSPACE}" --kind signal --path cache/malformed-signal.yaml
assert_status 1 'shared Signal validator rejects a malformed Signal'
assert_result_error context_artifact_invalid 'malformed Signal reports stable lint error ID'
rm "${WORKSPACE}/cache/malformed-signal.yaml"
printf '%s\n' 'accepted stale context for fixture' >"${WORKSPACE}/cache/note.txt"
run_context bash "${FRESHNESS_EXEC}" resolve --workspace "${WORKSPACE}" --signal "${SIGNAL_ID}" --status accepted --actor tester --note cache/note.txt
assert_status 0 'Signal can be explicitly accepted with evidence note'
FIRST_OBSERVED=$("${YQ_EXECUTABLE}" eval -r '.first_observed_at' "${WORKSPACE}/state/context-signals/${SIGNAL_ID}.yaml")
run_context bash "${FRESHNESS_EXEC}" record --workspace "${WORKSPACE}" --report cache/freshness-report.yaml
assert_status 0 'repeated Signal record is idempotent'
if [ "$("${YQ_EXECUTABLE}" eval -r '.status' "${WORKSPACE}/state/context-signals/${SIGNAL_ID}.yaml")" = accepted ] &&
   [ "$("${YQ_EXECUTABLE}" eval -r '.first_observed_at' "${WORKSPACE}/state/context-signals/${SIGNAL_ID}.yaml")" = "${FIRST_OBSERVED}" ]; then
  pass 'repeated Signal record preserves disposition and first observation'
else
  fail 'repeated Signal record preserves disposition and first observation'
fi

# Restore the governed Item bytes so subsequent Bundle and Navigation checks use current Catalog content.
printf '%s' "${BODY_ONE}" >"${WORKSPACE}/context/domain/alpha.body"
write_item "${WORKSPACE}" 'domain/alpha.md' CTX-001 Alpha domain active "${BODY_ONE}"

cat >"${WORKSPACE}/state/context-signals/CSG-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.yaml" <<EOF
signal_schema: themis-context-signal
id: CSG-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
kind: context_conflict
status: open
project: primary
workspace_identity_digest: $("${YQ_EXECUTABLE}" eval -r '.workspace_identity_digest' "${WORKSPACE}/context/catalog.yaml")
revision:
  kind: unavailable
  commit: null
  worktree: unknown
scope: [unrelated]
sources: []
evidence_refs: []
first_observed_at: "2026-01-01T00:00:00Z"
last_observed_at: "2026-01-01T00:00:00Z"
disposition: null
EOF
run_context bash "${ASSEMBLE_EXEC}" finalize --workspace "${WORKSPACE}" --bundle "${BUNDLE_ID}"
assert_status 0 'unrelated open Signal does not block Bundle finalization'
assert_json_value '.data.status' unavailable 'unrelated Signal preserves non-Git unavailable status'
"${YQ_EXECUTABLE}" eval -i '.scope = ["demo"]' "${WORKSPACE}/state/context-signals/CSG-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.yaml"
run_context bash "${ASSEMBLE_EXEC}" finalize --workspace "${WORKSPACE}" --bundle "${BUNDLE_ID}"
assert_status 0 'relevant open Signal is represented in Bundle status'
assert_json_value '.data.status' conflict 'relevant open Signal marks Bundle conflict'
if "${YQ_EXECUTABLE}" eval -e '(.signal_refs | length) == 1 and .signal_refs[0] == "CSG-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"' "${WORKSPACE}/cache/resolved-context/${BUNDLE_ID}/manifest.yaml" >/dev/null 2>&1; then
  pass 'Bundle records only relevant open Signal IDs'
else
  fail 'Bundle records only relevant open Signal IDs'
fi

rm "${WORKSPACE}/state/context-signals/CSG-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.yaml"
run_context bash "${NAVIGATION_EXEC}" render --workspace "${WORKSPACE}" --candidate cache/context-index/candidate
assert_status 0 'Navigation candidate render succeeds'
printf '%s\n' 'Injected ungoverned statement.' >>"${WORKSPACE}/cache/context-index/candidate/.overview.md"
rewrite_projection_digest "${WORKSPACE}/cache/context-index/candidate/.overview.md"
run_context bash "${NAVIGATION_EXEC}" publish --workspace "${WORKSPACE}" --candidate cache/context-index/candidate --expected-catalog-digest "$(catalog_digest "${WORKSPACE}")"
assert_status 1 'self-consistent but ungoverned Navigation candidate is rejected'
assert_result_error context_navigation_candidate_invalid 'forged Navigation candidate reports stable error ID'

run_context bash "${NAVIGATION_EXEC}" render --workspace "${WORKSPACE}" --candidate cache/context-index/candidate
run_context bash "${NAVIGATION_EXEC}" publish --workspace "${WORKSPACE}" --candidate cache/context-index/candidate --expected-catalog-digest "$(catalog_digest "${WORKSPACE}")"
assert_status 0 'validated Navigation candidate publishes successfully'
run_context bash "${NAVIGATION_EXEC}" status --workspace "${WORKSPACE}"
assert_status 0 'published Navigation status succeeds'
assert_json_value '.data.current' true 'published Navigation is current with Catalog'
if grep -F 'Alpha overview' "${WORKSPACE}/context/domain/.overview.md" >/dev/null 2>&1; then
  pass 'category Navigation copies governed overview metadata'
else
  fail 'category Navigation copies governed overview metadata'
fi

run_context bash "${NAVIGATION_EXEC}" rebuild-index --workspace "${WORKSPACE}"
assert_status 0 'deletable Context index rebuild succeeds'
assert_json_result ok 'Context index rebuild emits one valid JSON result'
if [ "$("${YQ_EXECUTABLE}" eval -r '.items | length' "${WORKSPACE}/cache/context-index/index.yaml")" -eq 2 ]; then
  pass 'rebuilt Context index covers registered Catalog Items'
else
  fail 'rebuilt Context index covers registered Catalog Items'
fi

mkdir "${WORKSPACE}/state/locks/context.lock"
printf '%s\n' 'malformed owner' >"${WORKSPACE}/state/locks/context.lock/owner.yaml"
run_context bash "${NAVIGATION_EXEC}" rebuild-index --workspace "${WORKSPACE}"
assert_status 2 'existing malformed Context lock requires adjudication'
assert_result_error context_lock_present 'existing Context lock reports stable error ID'
if [ -f "${WORKSPACE}/state/locks/context.lock/owner.yaml" ]; then
  pass 'unknown Context lock is never deleted automatically'
else
  fail 'unknown Context lock is never deleted automatically'
fi
rm -rf "${WORKSPACE}/state/locks/context.lock"

mkdir "${WORKSPACE}/state/transactions/context/unknown-residue"
run_context bash "${NAVIGATION_EXEC}" rebuild-index --workspace "${WORKSPACE}"
assert_status 2 'unknown Context transaction residue blocks writes'
assert_result_error context_transaction_residue 'unknown transaction residue reports stable error ID'
rm -rf "${WORKSPACE}/state/transactions/context/unknown-residue"

RECOVERY_PROJECT=$(make_project recovery)
RECOVERY_WORKSPACE="${RECOVERY_PROJECT}/.themis/workspace"
run_context bash "${CATALOG_EXEC}" bind --workspace "${RECOVERY_WORKSPACE}" --project-root "${RECOVERY_PROJECT}"
printf -v RECOVERY_BODY '%s\n' '# Recovery' '' 'Recovery fact.'
write_item "${RECOVERY_WORKSPACE}" 'domain/recovery.md' CTX-100 Recovery domain active "${RECOVERY_BODY}"
RECOVERY_DIGEST=$(catalog_digest "${RECOVERY_WORKSPACE}")
run_context env THEMIS_CONTEXT_FAIL_PHASE=after_replace THEMIS_CONTEXT_FAIL_RESTORE=1 bash "${CATALOG_EXEC}" register --workspace "${RECOVERY_WORKSPACE}" --item context/domain/recovery.md --expected-catalog-digest "${RECOVERY_DIGEST}"
assert_status 2 'failed Catalog restore retains recovery transaction'
assert_result_error context_restore_failed 'failed Catalog restore reports stable recovery error'
TRANSACTION_DIR=
for candidate in "${RECOVERY_WORKSPACE}"/state/transactions/context/CTXTX-*; do
  if [ -d "${candidate}" ]; then TRANSACTION_DIR=${candidate}; break; fi
done
if [ -n "${TRANSACTION_DIR}" ]; then
  pass 'failed Catalog restore preserves transaction data'
else
  fail 'failed Catalog restore preserves transaction data'
fi
TRANSACTION_ID=$(basename -- "${TRANSACTION_DIR}")
run_context bash "${CATALOG_EXEC}" recover --workspace "${RECOVERY_WORKSPACE}" --transaction "${TRANSACTION_ID}"
assert_status 0 'explicit Catalog recovery succeeds'
if ! "${YQ_EXECUTABLE}" eval -e '.items | has("CTX-100")' "${RECOVERY_WORKSPACE}/context/catalog.yaml" >/dev/null 2>&1 && [ ! -e "${TRANSACTION_DIR}" ]; then
  pass 'explicit Catalog recovery restores previous state and removes residue'
else
  fail 'explicit Catalog recovery restores previous state and removes residue'
fi

# 先构造 20 Item Catalog；进程预算只统计后续 prepare、select、finalize 正常主流程。
PERFORMANCE_PROJECT=$(make_project performance)
PERFORMANCE_WORKSPACE="${PERFORMANCE_PROJECT}/.themis/workspace"
run_context bash "${CATALOG_EXEC}" bind --workspace "${PERFORMANCE_WORKSPACE}" --project-root "${PERFORMANCE_PROJECT}"
item_number=1
while [ "${item_number}" -le 20 ]; do
  item_id=$(printf 'CTX-%03d' "$((200 + item_number))")
  item_title=$(printf 'Performance%02d' "${item_number}")
  item_path=$(printf 'domain/performance-%02d.md' "${item_number}")
  printf -v item_body '%s\n' "# ${item_title}" '' "Governed performance fact ${item_number}."
  write_item "${PERFORMANCE_WORKSPACE}" "${item_path}" "${item_id}" "${item_title}" domain active "${item_body}" performance
  run_context bash "${CATALOG_EXEC}" register --workspace "${PERFORMANCE_WORKSPACE}" --item "context/${item_path}" --expected-catalog-digest "$(catalog_digest "${PERFORMANCE_WORKSPACE}")"
  if [ "${LAST_STATUS}" -ne 0 ]; then
    break
  fi
  item_number=$((item_number + 1))
done

cat >"${PERFORMANCE_WORKSPACE}/cache/performance-request.yaml" <<'EOF'
intent: Measure deterministic Context assembly
spec_ref: null
task_ref: TASK-PERFORMANCE
scope: [performance]
filters:
  category: domain
token_budget: 10000
content_budget_bytes: 131072
EOF

cat >"${PERFORMANCE_WORKSPACE}/cache/performance-selection.yaml" <<'EOF'
selected:
  - id: CTX-201
    reason: required performance fixture
excluded:
EOF
item_number=2
while [ "${item_number}" -le 20 ]; do
  item_id=$(printf 'CTX-%03d' "$((200 + item_number))")
  cat >>"${PERFORMANCE_WORKSPACE}/cache/performance-selection.yaml" <<EOF
  - id: ${item_id}
    reason: excluded performance fixture
EOF
  item_number=$((item_number + 1))
done

YQ_SHIM="${TEST_TMP}/count-yq.sh"
YQ_COUNT_FILE="${TEST_TMP}/yq-count.log"
cat >"${YQ_SHIM}" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' yq >>"${THEMIS_YQ_COUNT_FILE}"
exec "${THEMIS_REAL_YQ}" "$@"
EOF
chmod +x "${YQ_SHIM}"
: >"${YQ_COUNT_FILE}"

run_context env YQ="${YQ_SHIM}" THEMIS_REAL_YQ="${YQ_EXECUTABLE}" THEMIS_YQ_COUNT_FILE="${YQ_COUNT_FILE}" bash "${ASSEMBLE_EXEC}" prepare --workspace "${PERFORMANCE_WORKSPACE}" --request cache/performance-request.yaml
assert_status 0 '20-Item Bundle prepare succeeds under yq counting shim'
PERFORMANCE_BUNDLE_ID=$(bundle_id_from_result)
run_context env YQ="${YQ_SHIM}" THEMIS_REAL_YQ="${YQ_EXECUTABLE}" THEMIS_YQ_COUNT_FILE="${YQ_COUNT_FILE}" bash "${ASSEMBLE_EXEC}" select --workspace "${PERFORMANCE_WORKSPACE}" --bundle "${PERFORMANCE_BUNDLE_ID}" --selection cache/performance-selection.yaml
assert_status 0 '20-Item Bundle selection succeeds under yq counting shim'
run_context env YQ="${YQ_SHIM}" THEMIS_REAL_YQ="${YQ_EXECUTABLE}" THEMIS_YQ_COUNT_FILE="${YQ_COUNT_FILE}" bash "${ASSEMBLE_EXEC}" finalize --workspace "${PERFORMANCE_WORKSPACE}" --bundle "${PERFORMANCE_BUNDLE_ID}"
assert_status 0 '20-Item Bundle finalization succeeds under yq counting shim'
YQ_PROCESS_COUNT=$(wc -l <"${YQ_COUNT_FILE}" | tr -d '[:space:]')
YQ_PROCESS_LIMIT=$((2 * 20 + 30))
if [ "${YQ_PROCESS_COUNT}" -le "${YQ_PROCESS_LIMIT}" ]; then
  pass '20-Item Bundle main flow stays within the 2N + 30 yq process limit'
else
  fail '20-Item Bundle main flow stays within the 2N + 30 yq process limit' "expected at most ${YQ_PROCESS_LIMIT}, got ${YQ_PROCESS_COUNT}"
fi

for shell_file in "${CONTEXT_BIN}/_themis-context-common.sh" "${CONTEXT_BIN}"/themis-context-*.sh; do
  if bash -n "${shell_file}"; then
    pass "$(basename -- "${shell_file}") passes Bash syntax"
  else
    fail "$(basename -- "${shell_file}") passes Bash syntax"
  fi
done

printf '1..%s\n' "${TEST_COUNT}"
if [ "${TEST_FAILURES}" -ne 0 ]; then
  printf '%s of %s tests failed\n' "${TEST_FAILURES}" "${TEST_COUNT}" >&2
  exit 1
fi
printf 'All %s tests passed\n' "${TEST_COUNT}"
