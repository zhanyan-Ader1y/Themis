#!/usr/bin/env bash
#
# Themis Upgrade TAP 测试。
# 用途：验证兼容升级、dry-run、Workspace 不可变性、持久备份和替换后回滚。
# 边界：候选版本仅复制到临时目录，绝不修改当前源仓库。
#
TEST_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
INIT_PATH="${TEST_ROOT}/bin/themis-init.sh"
TEST_TMP=${TMPDIR:-/tmp}/themis-upgrade-test-$$
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

# 捕获命令输出与退出状态，使预期失败场景不会中止测试。
run_command() {
  LAST_OUTPUT=$("$@" 2>&1)
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

# 断言两个文件逐字一致。
assert_same_file() {
  if cmp -s "$1" "$2"; then
    pass "$3"
  else
    fail "$3" "files differ: $1 and $2"
  fi
}

# 生成目录树指纹，覆盖空目录、普通文件内容与符号链接目标。
tree_fingerprint() {
  local root=$1
  local path
  local relative

  find -P "${root}" -mindepth 1 -print | LC_ALL=C sort | while IFS= read -r path; do
    relative=${path#"${root}"/}
    if [ -d "${path}" ]; then
      printf 'directory %s\n' "${relative}"
    elif [ -f "${path}" ]; then
      printf 'file %s %s\n' "${relative}" "$(cksum "${path}")"
    elif [ -L "${path}" ]; then
      printf 'symlink %s %s\n' "${relative}" "$(readlink "${path}")"
    else
      printf 'other %s\n' "${relative}"
    fi
  done
}

# 通过 P3 Init 创建基线项目，再写入 Upgrade 绝不可使用的项目拥有数据。
make_project() {
  local name=$1
  local project="${TEST_TMP}/${name}"

  mkdir -p "${project}"
  run_command bash "${INIT_PATH}" "${project}" --yes --project-name "${name}"
  if [ "${LAST_STATUS}" -ne 0 ]; then
    printf '%s\n' "Unable to create Upgrade fixture: ${LAST_OUTPUT}" >&2
    exit 2
  fi
  mkdir -p "${project}/.themis/workspace/specs/demo/empty" "${project}/.themis/workspace/evidence"
  printf '%s\n' 'project-owned plan' >"${project}/.themis/workspace/specs/demo/plan.md"
  printf '%s\n' 'project-owned evidence' >"${project}/.themis/workspace/evidence/result.txt"
  printf '%s\n' 'unknown project data' >"${project}/.themis/workspace/custom.txt"
  printf '%s\n' '# Project agents' >"${project}/AGENTS.md"
  printf '%s\n' "${project}"
}

# 复制完整源仓库，仅用于构造受控 Upgrade 候选版本。
make_candidate_repo() {
  local name=$1
  local repository="${TEST_TMP}/${name}-repo"

  cp -R "${TEST_ROOT}" "${repository}"
  printf '%s\n' "${repository}"
}

# 同步提升候选 Bundle/Core 版本，使 Upgrade 进入事务路径。
bump_candidate_version() {
  local repository=$1
  local version=$2

  printf '%s\n' "${version}" >"${repository}/templates/.themis/VERSION"
  "${YQ_EXECUTABLE}" eval -i ".core_version = \"${version}\"" "${repository}/templates/.themis/core/core.yaml"
}

# 运行候选仓库的 Upgrade，确保相对路径解析到测试夹具。
run_upgrade() {
  local repository=$1
  shift
  run_command bash "${repository}/bin/themis-upgrade.sh" "$@"
}

if ! command -v "${YQ_EXECUTABLE}" >/dev/null 2>&1; then
  printf '%s\n' 'Upgrade tests require mikefarah/yq v4.' >&2
  exit 2
fi
case "$("${YQ_EXECUTABLE}" --version 2>&1)" in
  *mikefarah/yq*version\ v4.*) ;;
  *)
    printf '%s\n' 'Upgrade tests require mikefarah/yq v4.' >&2
    exit 2
    ;;
esac

printf '1..37\n'

NOOP_PROJECT=$(make_project noop)
NOOP_REPO=$(make_candidate_repo noop)
NOOP_BEFORE=$(tree_fingerprint "${NOOP_PROJECT}")
run_upgrade "${NOOP_REPO}" "${NOOP_PROJECT}"
assert_status 0 'current version exits successfully without upgrade'
assert_output_contains 'already current' 'current version reports no-op'
if [ "$(tree_fingerprint "${NOOP_PROJECT}")" = "${NOOP_BEFORE}" ]; then
  pass 'current version leaves complete project tree unchanged'
else
  fail 'current version leaves complete project tree unchanged' 'project tree changed during no-op'
fi
assert_file_absent "${NOOP_PROJECT}/.themis-upgrade-backup.000000" 'no-op does not create a predictable backup path'

UPGRADE_PROJECT=$(make_project compatible)
UPGRADE_REPO=$(make_candidate_repo compatible)
bump_candidate_version "${UPGRADE_REPO}" 0.4.0
printf '%s\n' 'candidate managed guidance' >>"${UPGRADE_REPO}/templates/.themis/CLAUDE.themis.md"
printf '%s\n' 'candidate core marker' >"${UPGRADE_REPO}/templates/.themis/core/upgrade-marker.txt"
printf '%s\n' 'candidate workspace must not copy' >"${UPGRADE_REPO}/templates/.themis/workspace/candidate-only.txt"
WORKSPACE_BEFORE=$(tree_fingerprint "${UPGRADE_PROJECT}/.themis/workspace")
cp "${UPGRADE_PROJECT}/.themis/workspace/manifest.yaml" "${TEST_TMP}/compatible-manifest-before.yaml"
cp "${UPGRADE_PROJECT}/CLAUDE.md" "${TEST_TMP}/compatible-claude-before.md"
cp "${UPGRADE_PROJECT}/AGENTS.md" "${TEST_TMP}/compatible-agents-before.md"
run_upgrade "${UPGRADE_REPO}" "${UPGRADE_PROJECT}"
assert_status 0 'compatible candidate upgrades successfully'
assert_file_contains 'candidate managed guidance' "${UPGRADE_PROJECT}/.themis/CLAUDE.themis.md" 'upgrade refreshes contained managed guidance'
assert_file_contains 'candidate core marker' "${UPGRADE_PROJECT}/.themis/core/upgrade-marker.txt" 'upgrade copies new managed Core content'
assert_file_absent "${UPGRADE_PROJECT}/.themis/workspace/candidate-only.txt" 'upgrade never copies candidate Workspace content'
if [ "$(tree_fingerprint "${UPGRADE_PROJECT}/.themis/workspace")" = "${WORKSPACE_BEFORE}" ]; then
  pass 'upgrade preserves complete Workspace fingerprint'
else
  fail 'upgrade preserves complete Workspace fingerprint' 'Workspace fingerprint changed'
fi
assert_same_file "${TEST_TMP}/compatible-manifest-before.yaml" "${UPGRADE_PROJECT}/.themis/workspace/manifest.yaml" 'upgrade preserves manifest bytes'
assert_same_file "${TEST_TMP}/compatible-claude-before.md" "${UPGRADE_PROJECT}/CLAUDE.md" 'upgrade preserves CLAUDE.md bytes'
assert_same_file "${TEST_TMP}/compatible-agents-before.md" "${UPGRADE_PROJECT}/AGENTS.md" 'upgrade preserves AGENTS.md bytes'
if [ "$("${YQ_EXECUTABLE}" eval -r '.artifact_schema' "${UPGRADE_PROJECT}/.themis/workspace/manifest.yaml")" = 'themis-artifact/v2' ]; then
  pass 'upgrade preserves native Artifact v2 schema'
else
  fail 'upgrade preserves native Artifact v2 schema' 'Upgrade mutated Workspace manifest'
fi
if [ ! -e "${UPGRADE_PROJECT}/.themis/core/templates/spec.md" ] && \
   [ ! -e "${UPGRADE_PROJECT}/.themis/core/migrations/artifacts/v1-to-v2.sh" ]; then
  pass 'upgrade installs no legacy Spec compatibility assets'
else
  fail 'upgrade installs no legacy Spec compatibility assets' 'Obsolete Spec template or migration script was installed'
fi
if [ "$("${YQ_EXECUTABLE}" eval '.compatibility.artifact.supported | length' "${UPGRADE_PROJECT}/.themis/core/core.yaml")" -eq 1 ] && \
   [ "$("${YQ_EXECUTABLE}" eval -r '.compatibility.artifact.supported[0]' "${UPGRADE_PROJECT}/.themis/core/core.yaml")" = 'themis-artifact/v2' ]; then
  pass 'upgrade installs Artifact v2 as the sole supported schema'
else
  fail 'upgrade installs Artifact v2 as the sole supported schema' 'Artifact compatibility list contains another schema'
fi
if [ "$("${YQ_EXECUTABLE}" eval '.compatibility.artifact.migrations | length' "${UPGRADE_PROJECT}/.themis/core/core.yaml")" -eq 0 ]; then
  pass 'upgrade installs no Artifact migration descriptor'
else
  fail 'upgrade installs no Artifact migration descriptor' 'Artifact migration list is not empty'
fi
if ls "${UPGRADE_PROJECT}"/.themis-upgrade-backup.* >/dev/null 2>&1; then
  pass 'successful upgrade retains persistent backup'
else
  fail 'successful upgrade retains persistent backup' 'backup directory missing'
fi
if [ "$(cat "${UPGRADE_PROJECT}/.themis/VERSION")" = 0.4.0 ]; then
  pass 'upgrade refreshes Bundle version'
else
  fail 'upgrade refreshes Bundle version' 'Bundle version did not change'
fi

DRY_PROJECT=$(make_project dry-run)
DRY_REPO=$(make_candidate_repo dry-run)
bump_candidate_version "${DRY_REPO}" 0.4.0
DRY_BEFORE=$(tree_fingerprint "${DRY_PROJECT}")
run_upgrade "${DRY_REPO}" "${DRY_PROJECT}" --dry-run
assert_status 0 'compatible dry-run succeeds'
assert_output_contains 'Compatibility: compatible' 'dry-run reports compatibility result'
if [ "$(tree_fingerprint "${DRY_PROJECT}")" = "${DRY_BEFORE}" ]; then
  pass 'dry-run leaves complete project tree unchanged'
else
  fail 'dry-run leaves complete project tree unchanged' 'project tree changed during dry-run'
fi
if ls "${DRY_PROJECT}"/.themis-upgrade-* >/dev/null 2>&1; then
  fail 'dry-run creates no backup or stage directory' 'found transaction directory after dry-run'
else
  pass 'dry-run creates no backup or stage directory'
fi

INCOMPATIBLE_PROJECT=$(make_project incompatible)
INCOMPATIBLE_REPO=$(make_candidate_repo incompatible)
bump_candidate_version "${INCOMPATIBLE_REPO}" 0.4.0
"${YQ_EXECUTABLE}" eval -i '.compatibility.workspace.supported = ["themis-workspace/v9"]' "${INCOMPATIBLE_REPO}/templates/.themis/core/core.yaml"
INCOMPATIBLE_BEFORE=$(tree_fingerprint "${INCOMPATIBLE_PROJECT}")
run_upgrade "${INCOMPATIBLE_REPO}" "${INCOMPATIBLE_PROJECT}"
assert_status 1 'incompatible Workspace schema rejects upgrade'
assert_output_contains 'candidate template contract invalid' 'unsupported candidate schema reports source-contract diagnostic'
if [ "$(tree_fingerprint "${INCOMPATIBLE_PROJECT}")" = "${INCOMPATIBLE_BEFORE}" ]; then
  pass 'incompatible schema leaves complete project unchanged'
else
  fail 'incompatible schema leaves complete project unchanged' 'project tree changed after rejection'
fi
if ls "${INCOMPATIBLE_PROJECT}"/.themis-upgrade-* >/dev/null 2>&1; then
  fail 'incompatible schema creates no transaction directory' 'found transaction directory after rejection'
else
  pass 'incompatible schema creates no transaction directory'
fi

LEGACY_PROJECT=$(make_project legacy)
LEGACY_REPO=$(make_candidate_repo legacy)
bump_candidate_version "${LEGACY_REPO}" 0.4.0
printf '%s\n' '# obsolete companion' >"${LEGACY_PROJECT}/CLAUDE.themis.md"
LEGACY_BEFORE=$(tree_fingerprint "${LEGACY_PROJECT}")
run_upgrade "${LEGACY_REPO}" "${LEGACY_PROJECT}"
assert_status 1 'root-level legacy guidance rejects upgrade'
assert_output_contains 'legacy root guidance present' 'legacy root guidance reports manual migration diagnostic'
if [ "$(tree_fingerprint "${LEGACY_PROJECT}")" = "${LEGACY_BEFORE}" ]; then
  pass 'legacy layout rejection leaves project unchanged'
else
  fail 'legacy layout rejection leaves project unchanged' 'project tree changed after legacy rejection'
fi

MODIFIED_PROJECT=$(make_project modified-block)
MODIFIED_REPO=$(make_candidate_repo modified-block)
bump_candidate_version "${MODIFIED_REPO}" 0.4.0
printf '%s\n' '<!-- themis:guidance:start -->' '@import modified.md' '<!-- themis:guidance:end -->' >"${MODIFIED_PROJECT}/CLAUDE.md"
MODIFIED_BEFORE=$(tree_fingerprint "${MODIFIED_PROJECT}")
run_upgrade "${MODIFIED_REPO}" "${MODIFIED_PROJECT}"
assert_status 1 'modified guidance block rejects upgrade'
assert_output_contains 'modified Themis guidance block' 'modified guidance block reports diagnostic'
if [ "$(tree_fingerprint "${MODIFIED_PROJECT}")" = "${MODIFIED_BEFORE}" ]; then
  pass 'modified guidance rejection leaves project unchanged'
else
  fail 'modified guidance rejection leaves project unchanged' 'project tree changed after marker rejection'
fi

ROLLBACK_PROJECT=$(make_project rollback)
ROLLBACK_REPO=$(make_candidate_repo rollback)
bump_candidate_version "${ROLLBACK_REPO}" 0.4.0
printf '%s\n' 'candidate marker before simulated failure' >"${ROLLBACK_REPO}/templates/.themis/core/rollback-marker.txt"
ROLLBACK_WORKSPACE_BEFORE=$(tree_fingerprint "${ROLLBACK_PROJECT}/.themis/workspace")
cp "${ROLLBACK_PROJECT}/CLAUDE.md" "${TEST_TMP}/rollback-claude-before.md"
LAST_OUTPUT=$(THEMIS_UPGRADE_TEST_FAIL_AFTER_REPLACEMENT=1 bash "${ROLLBACK_REPO}/bin/themis-upgrade.sh" "${ROLLBACK_PROJECT}" 2>&1)
LAST_STATUS=$?
assert_status 1 'post-replacement failure triggers rollback'
assert_output_contains 'simulated post-replacement failure' 'rollback path reports post-replacement diagnostic'
if [ "$(tree_fingerprint "${ROLLBACK_PROJECT}/.themis/workspace")" = "${ROLLBACK_WORKSPACE_BEFORE}" ]; then
  pass 'rollback preserves Workspace fingerprint'
else
  fail 'rollback preserves Workspace fingerprint' 'Workspace changed during rollback'
fi
assert_same_file "${TEST_TMP}/rollback-claude-before.md" "${ROLLBACK_PROJECT}/CLAUDE.md" 'rollback preserves CLAUDE.md bytes'
if [ "$(cat "${ROLLBACK_PROJECT}/.themis/VERSION")" = 0.3.0 ] && [ ! -e "${ROLLBACK_PROJECT}/.themis/core/rollback-marker.txt" ] && [ -f "${ROLLBACK_PROJECT}/.themis/core/kernel/orchestrator/rules.md" ]; then
  pass 'rollback restores original managed Core and Bundle content'
else
  fail 'rollback restores original managed Core and Bundle content' 'managed content differs after rollback'
fi

if [ "${TEST_FAILURES}" -ne 0 ]; then
  printf '%s of %s tests failed\n' "${TEST_FAILURES}" "${TEST_COUNT}" >&2
  exit 1
fi
printf 'All %s tests passed\n' "${TEST_COUNT}"
