#!/usr/bin/env bash
#
# Themis Migrate TAP 测试。
# 用途：验证显式迁移执行器（--check、--backup、--run、--verify、--rollback、--dry-run）
#       以及迁移失败时的回滚行为。
# 边界：所有夹具在临时目录中创建，不修改当前源仓库。
#
TEST_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
INIT_PATH="${TEST_ROOT}/bin/themis-init.sh"
MIGRATE_PATH="${TEST_ROOT}/bin/themis-migrate.sh"
YQ_EXECUTABLE=${YQ:-yq}
TEST_TMP=${TMPDIR:-/tmp}/themis-migrate-test-$$
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

# 输出一条失败的 TAP 断言。
fail() {
  TEST_COUNT=$((TEST_COUNT + 1))
  TEST_FAILURES=$((TEST_FAILURES + 1))
  printf 'not ok %s - %s\n' "${TEST_COUNT}" "$1"
  if [ -n "${2-}" ]; then
    printf '  %s\n' "$2"
  fi
}

# 捕获命令输出与退出状态。
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

# 断言稳定诊断包含预期片段。
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

# 生成目录树指纹。
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

# 通过 P3 Init 创建一个带有完整 Workspace 的测试项目。
make_project() {
  local name=$1
  local project="${TEST_TMP}/${name}"

  mkdir -p "${project}"
  run_command bash "${INIT_PATH}" "${project}" --yes --project-name "${name}"
  if [ "${LAST_STATUS}" -ne 0 ]; then
    printf '%s\n' "Unable to create migrate fixture: ${LAST_OUTPUT}" >&2
    exit 2
  fi
  printf '%s\n' "${project}"
}

# 在 core.yaml 中添加一个模拟的 Workspace 迁移描述符。
add_migration_descriptor() {
  local project=$1
  local from_schema=$2
  local to_schema=$3
  local migration_script_path="${project}/.themis/core/migrations/workspace/v1-to-v2.sh"

  # 创建迁移脚本目录
  mkdir -p "$(dirname "${migration_script_path}")"

  # 写入一个无害的迁移脚本
  cat >"${migration_script_path}" <<'SCRIPT_EOF'
#!/usr/bin/env bash
# 测试用迁移桩：向 workspace 添加一个标记文件。
WORKSPACE_PATH=$1
printf '{"status":"%s","changed_files":["%s/migration-marker.txt"],"errors":[]}\n' \
  "success" "${WORKSPACE_PATH}"
touch "${WORKSPACE_PATH}/migration-marker.txt"
SCRIPT_EOF
  chmod +x "${migration_script_path}"

  # 在 core.yaml 中添加迁移描述符
  "${YQ_EXECUTABLE}" eval -i \
    ".compatibility.workspace.migrations += [{\"from\":\"${from_schema}\",\"to\":\"${to_schema}\",\"path\":\"migrations/workspace/v1-to-v2.sh\",\"reversible\":true}]" \
    "${project}/.themis/core/core.yaml"
}

if ! command -v "${YQ_EXECUTABLE}" >/dev/null 2>&1; then
  printf '%s\n' 'Migrate tests require mikefarah/yq v4.' >&2
  exit 2
fi
case "$("${YQ_EXECUTABLE}" --version 2>&1)" in
  *mikefarah/yq*version\ v4.*) ;;
  *)
    printf '%s\n' 'Migrate tests require mikefarah/yq v4.' >&2
    exit 2
    ;;
esac

printf '1..30\n'

# 1: --help
run_command bash "${MIGRATE_PATH}" --help
assert_status 0 '--help exits successfully'
assert_output_contains 'Usage:' '--help shows usage'

# 2: 缺少 action
run_command bash "${MIGRATE_PATH}" "${TEST_TMP}"
assert_status 1 'missing action fails'

# 3: --check on compatible schema (无迁移描述符)
COMPAT_PROJECT=$(make_project compatible)
run_command bash "${MIGRATE_PATH}" "${COMPAT_PROJECT}" --check
assert_status 0 '--check on compatible schema succeeds'
assert_output_contains '"workspace_migrations":[]' '--check returns empty workspace migrations when none exist'

# 4: --check on schema with migration descriptor
MIGRATABLE_PROJECT=$(make_project migratable)
add_migration_descriptor "${MIGRATABLE_PROJECT}" "themis-workspace/v1" "themis-workspace/v2"
run_command bash "${MIGRATE_PATH}" "${MIGRATABLE_PROJECT}" --check
assert_status 0 '--check finds migration descriptor'
assert_output_contains '"from":"themis-workspace/v1"' '--check output includes from schema'
assert_output_contains '"to":"themis-workspace/v2"' '--check output includes to schema'

# 5: --check on missing .themis/
run_command bash "${MIGRATE_PATH}" "${TEST_TMP}/nonexistent" --check
assert_status 1 '--check on missing .themis fails'

# 6: --backup creates backup
BACKUP_PROJECT=$(make_project backup-test)
WORKSPACE_BEFORE_BACKUP=$(tree_fingerprint "${BACKUP_PROJECT}/.themis/workspace")
run_command bash "${MIGRATE_PATH}" "${BACKUP_PROJECT}" --backup
assert_status 0 '--backup succeeds'
assert_output_contains '"backup_path"' '--backup outputs backup path'

# 7: Workspace fingerprint unchanged after --backup
WORKSPACE_AFTER_BACKUP=$(tree_fingerprint "${BACKUP_PROJECT}/.themis/workspace")
if [ "${WORKSPACE_BEFORE_BACKUP}" = "${WORKSPACE_AFTER_BACKUP}" ]; then
  pass '--backup does not alter Workspace'
else
  fail '--backup does not alter Workspace' 'Workspace fingerprint changed'
fi

# 8: --run executes a migration script
RUN_PROJECT=$(make_project run-test)
add_migration_descriptor "${RUN_PROJECT}" "themis-workspace/v1" "themis-workspace/v2"
# 先备份
run_command bash "${MIGRATE_PATH}" "${RUN_PROJECT}" --backup
assert_status 0 'pre-run backup succeeds'
run_command bash "${MIGRATE_PATH}" "${RUN_PROJECT}" --run --migration-id "themis-workspace/v1→themis-workspace/v2"
assert_status 0 '--run executes migration'
assert_output_contains '"status":"success"' '--run reports success status'

# 9: migration marker was created
if find "${RUN_PROJECT}/.themis/workspace" -name 'migration-marker.txt' 2>/dev/null | grep -q .; then
  pass 'migration script created the expected marker file'
else
  fail 'migration script created the expected marker file' 'marker file not found'
fi

# 10: --run without --migration-id fails
run_command bash "${MIGRATE_PATH}" "${RUN_PROJECT}" --run
assert_status 1 '--run without --migration-id fails'

# 11: --run with nonexistent migration-id fails
run_command bash "${MIGRATE_PATH}" "${RUN_PROJECT}" --run --migration-id "nonexistent/v1→nonexistent/v2"
assert_status 1 '--run with nonexistent migration-id fails'

# 12: --verify passes on valid Workspace
VERIFY_PROJECT=$(make_project verify-ok)
add_migration_descriptor "${VERIFY_PROJECT}" "themis-workspace/v1" "themis-workspace/v2"
run_command bash "${MIGRATE_PATH}" "${VERIFY_PROJECT}" --verify
assert_status 0 '--verify passes on valid Workspace'

# 13: --verify fails on missing directories
VERIFY_FAIL_PROJECT=$(make_project verify-fail)
rm -rf "${VERIFY_FAIL_PROJECT}/.themis/workspace/specs"
run_command bash "${MIGRATE_PATH}" "${VERIFY_FAIL_PROJECT}" --verify
assert_status 1 '--verify fails on missing Workspace directory'

# 14: --rollback restores Workspace from backup
ROLLBACK_PROJECT=$(make_project rollback-test)
WORKSPACE_BEFORE=$(tree_fingerprint "${ROLLBACK_PROJECT}/.themis/workspace")
run_command bash "${MIGRATE_PATH}" "${ROLLBACK_PROJECT}" --backup
# 从 JSON 输出中提取备份路径
ROLLBACK_BACKUP_PATH=$(printf '%s' "${LAST_OUTPUT}" | sed -n 's/.*"backup_path":"\([^"]*\)".*/\1/p')
# 破坏 Workspace
rm -rf "${ROLLBACK_PROJECT}/.themis/workspace/specs"
run_command bash "${MIGRATE_PATH}" "${ROLLBACK_PROJECT}" --rollback --backup-path "${ROLLBACK_BACKUP_PATH}"
assert_status 0 '--rollback succeeds'
WORKSPACE_AFTER=$(tree_fingerprint "${ROLLBACK_PROJECT}/.themis/workspace")
if [ "${WORKSPACE_BEFORE}" = "${WORKSPACE_AFTER}" ]; then
  pass '--rollback restores Workspace fingerprint'
else
  fail '--rollback restores Workspace fingerprint' 'Workspace differs after rollback'
fi

# 15: --rollback with nonexistent backup path fails
run_command bash "${MIGRATE_PATH}" "${ROLLBACK_PROJECT}" --rollback --backup-path "/nonexistent/backup"
assert_status 1 '--rollback with nonexistent backup fails'

# 16: --dry-run does not write files
DRY_PROJECT=$(make_project dry-run)
add_migration_descriptor "${DRY_PROJECT}" "themis-workspace/v1" "themis-workspace/v2"
DRY_BEFORE=$(tree_fingerprint "${DRY_PROJECT}")
run_command bash "${MIGRATE_PATH}" "${DRY_PROJECT}" --dry-run
assert_status 0 '--dry-run succeeds'
DRY_AFTER=$(tree_fingerprint "${DRY_PROJECT}")
if [ "${DRY_BEFORE}" = "${DRY_AFTER}" ]; then
  pass '--dry-run leaves project unchanged'
else
  fail '--dry-run leaves project unchanged' 'project tree changed during dry-run'
fi

# 17: --dry-run does not create backup directories
DRY_BACKUP_COUNT=$(find "${DRY_PROJECT}" -maxdepth 1 -name '.themis-migration-backup.*' 2>/dev/null | wc -l | tr -d '[:space:]')
if [ "${DRY_BACKUP_COUNT}" -eq 0 ]; then
  pass '--dry-run creates no backup directory'
else
  fail '--dry-run creates no backup directory' "found ${DRY_BACKUP_COUNT} backup directories"
fi

# 18: --run is idempotent (exit 2 = skipped 由迁移桩返回)
# 使用已迁移的项目再执行一次 --run，桩脚本已经是 success 风格所以会再次成功
# 幂等性由迁移脚本自身实现，此处验证重复执行不报错
RERUN_PROJECT=$(make_project rerun-test)
add_migration_descriptor "${RERUN_PROJECT}" "themis-workspace/v1" "themis-workspace/v2"
run_command bash "${MIGRATE_PATH}" "${RERUN_PROJECT}" --backup
run_command bash "${MIGRATE_PATH}" "${RERUN_PROJECT}" --run --migration-id "themis-workspace/v1→themis-workspace/v2"
assert_status 0 'first --run succeeds'
run_command bash "${MIGRATE_PATH}" "${RERUN_PROJECT}" --run --migration-id "themis-workspace/v1→themis-workspace/v2"
assert_status 0 'second --run does not error (idempotent)'

# 19: P4 upgrade script source contains migration hint
if grep -F -q 'themis-migrate.sh' "${TEST_ROOT}/bin/themis-upgrade.sh"; then
  pass 'P4 upgrade script references themis-migrate.sh'
else
  fail 'P4 upgrade script references themis-migrate.sh' 'themis-migrate.sh not found in upgrade diagnostics'
fi

# 20: --check target resolves to absolute path
ABS_PROJECT=$(make_project abs-test)
run_command bash "${MIGRATE_PATH}" "${ABS_PROJECT}" --check
assert_status 0 '--check with absolute target path succeeds'

if [ "${TEST_FAILURES}" -ne 0 ]; then
  printf '%s of %s tests failed\n' "${TEST_FAILURES}" "${TEST_COUNT}" >&2
  exit 1
fi
printf 'All %s tests passed\n' "${TEST_COUNT}"
