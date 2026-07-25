# P4.5 子模块：测试与文档

## 覆盖任务

- 任务 6：`docs/core/migrations.md` 更新（WIKI 同步）
- 任务 7：`tests/migrate/test.sh` 新建（集成测试）

## 目标文件 1：`tests/migrate/test.sh`

**路径**：`tests/migrate/test.sh`

### 测试设计

参考现有 `tests/upgrade/test.sh` 的结构（TAP 格式、辅助函数、隔离夹具），但独立测试迁移执行器。

### 辅助函数

```bash
# 复用现有测试的夹具模式
TEST_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
INIT_PATH="${TEST_ROOT}/bin/themis-init.sh"
UPGRADE_PATH="${TEST_ROOT}/bin/themis-upgrade.sh"
MIGRATE_PATH="${TEST_ROOT}/bin/themis-migrate.sh"
TEST_TMP=${TMPDIR:-/tmp}/themis-migrate-test-$$

# TAP 辅助（与现有测试相同）
pass() { ... }
fail() { ... }
run_command() { ... }
assert_status() { ... }
assert_output_contains() { ... }
assert_file_contains() { ... }
assert_file_absent() { ... }
assert_same_file() { ... }
tree_fingerprint() { ... }
```

### 测试矩阵

| # | 测试场景 | 预期结果 |
|---|---|---|
| 1 | `--help` 输出帮助信息 | 退出 0，含 Usage |
| 2 | 缺少 action 参数 | 退出非零，诊断 |
| 3 | `--check` on compatible schema（无迁移可用） | 退出 0，JSON 输出 `workspace_migrations: []` |
| 4 | `--check` on schema with migration descriptor | 退出 0，JSON 含迁移路径 |
| 5 | `--check` on missing `.themis/` | 退出非零，诊断 |
| 6 | `--backup` 创建完整 Workspace 备份 | 退出 0，备份目录存在，文件数等于 workspace/ 文件数 |
| 7 | `--backup` 后的 Workspace 指纹不变 | 备份前后 fingerprint 一致 |
| 8 | `--run` 执行有效迁移脚本 | 退出 0，JSON 含 status: success 和 changed_files |
| 9 | `--run` 执行已应用迁移（幂等） | 退出 0，JSON 含 status: skipped |
| 10 | `--run` 未先备份时拒绝 | 退出非零，诊断 "backup required" |
| 11 | `--verify` 通过：目录结构 + 工件格式正确 | 退出 0 |
| 12 | `--verify` 失败：结构缺失 | 退出非零，诊断列出缺失项 |
| 13 | `--rollback` 从备份恢复 Workspace | 退出 0，Workspace 指纹与备份一致 |
| 14 | `--rollback` 备份路径不存在 | 退出非零，诊断 |
| 15 | `--dry-run` 不写入任何文件 | 退出 0，文件系统不变 |
| 16 | 完整迁移流程（backup → run → verify） | 全部成功，manifest 版本已更新 |
| 17 | 迁移失败 → 回滚 → Workspace 不变 | Workspace 指纹与迁移前一致 |
| 18 | 任意缺失 action 的脚本调用被拒绝 | 退出非零，诊断 |
| 19 | P4 不兼容诊断含迁移提示 | 退出非零，输出含 "themis-migrate" |
| 20 | P4 的 33 项测试保持通过 | 33/33（回归） |

### 测试执行

```bash
# 语法检查
bash -n bin/themis-migrate.sh tests/migrate/test.sh

# ShellCheck
shellcheck bin/themis-migrate.sh tests/migrate/test.sh

# 运行
bash tests/migrate/test.sh

# 回归验证
bash tests/upgrade/test.sh
```

## 目标文件 2：`docs/core/migrations.md`

**路径**：`docs/core/migrations.md`

### 变更内容

1. **设计原则段**：增加一行 "**脚本与 Prompt 拆分**"，说明执行模型的四类操作归属
2. **迁移流程段**：更新为 6 步流程（与 P4.5 一致）
3. **迁移安全段**：增加 `themis-migrate.sh` 的引用
4. **目标文件段**（新增）：列出 P4.5 新增的 3 个文件

### 变更对比

| 段 | 变更类型 | 说明 |
|---|---|---|
| 设计原则 | 追加 | 增加脚本/Prompt 拆分说明 |
| 迁移流程 | 重写 | 从 3 步扩展为 6 步 |
| 迁移安全 | 更新 | 增加 `themis-migrate.sh` 入口引用 |
| 目标文件 | **新增** | 列出 migration.yaml、migration-execution.md、themis-migrate.sh |

## 验证要求

- `tests/migrate/test.sh` 通过 `bash -n` 语法检查
- ShellCheck 无 findings
- 全部 20 项测试通过
- P4 的 33 项回归测试保持通过
- `docs/core/migrations.md` 与 `migration.yaml`、`kernel/migrations.md` 描述一致
- `git diff --check` 通过
