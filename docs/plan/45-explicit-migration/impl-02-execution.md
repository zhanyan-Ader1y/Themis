# P4.5 子模块：迁移执行

## 覆盖任务

- 任务 2：`templates/.themis/core/templates/migration-execution.md`（新建）
- 任务 4：`bin/themis-migrate.sh`（新建）

## 设计依据

- D1：独立脚本，不修改 P4 的事务逻辑
- D2：备份、迁移调用、验证、回滚 → 脚本；用户确认、报告解读 → Prompt
- D4：幂等性检查在脚本中实现（迁移前检查目标状态）

## 目标文件 1：`migration-execution.md`

**路径**：`templates/.themis/core/templates/migration-execution.md`

该文件是 Prompt 模板，告诉 Agent 如何引导用户完成迁移流程。它引用策略文件和脚本，但不自己执行迁移。

### 结构设计

```markdown
# Themis 迁移执行引导

本文档定义 Agent 在显式迁移流程中的角色和可用脚本。
Agent 负责引导用户确认，脚本负责执行确定性操作。

## 角色

你是迁移引导者。你的任务是：
1. 向用户解释当前 Schema 与候选 Core 的不兼容性
2. 展示可用的迁移路径
3. 在每个确定性操作前确认用户意图
4. 调用脚本执行备份、迁移和验证
5. 解读验证结果并给出建议

严格的硬约束：
- 不得跳过用户确认
- 不得在备份完成前执行迁移
- 不得在验证失败后继续
- 不得修改脚本的输出

## Available Scripts

| Script | Purpose | Fallback if Missing |
|---|---|---|
| `themis-migrate.sh --check <target>` | 查询候选 Core 中是否有匹配当前 Schema 的迁移描述符，输出 JSON | Stop; report "Migration capability not installed" |
| `themis-migrate.sh --backup <target>` | 创建 workspace/ 的完整持久备份，输出备份路径 JSON | Stop; 不允许无备份迁移 |
| `themis-migrate.sh --run <target> --migration-id <id>` | 执行指定迁移脚本，调用 core/migrations/<path>.sh，输出 JSON | Stop; 拒绝手动执行迁移 |
| `themis-migrate.sh --verify <target>` | 验证迁移后的 Workspace 结构完整性 | Stop; 验证必须通过脚本 |
| `themis-migrate.sh --rollback <target> --backup-path <path>` | 从备份恢复 Workspace | Stop; 回滚必须通过脚本 |
| — | 迁移报告解读 | 无脚本，Agent 解读 JSON 输出并给出建议 |
| — | 用户确认门禁 | 无脚本，Agent 展示信息并等待用户输入 |

## 流程引导

### 步骤 1 — 兼容性检查

调用 `themis-migrate.sh --check <target>` 获取可用的迁移描述符。
输出示例：
```json
{
  "workspace_migrations": [
    {"from": "themis-workspace/v1", "to": "themis-workspace/v2",
     "path": "core/migrations/workspace/v1-to-v2.sh", "reversible": true}
  ],
  "artifact_migrations": []
}
```

如果没有匹配的迁移，告知用户无可用迁移路径。
如果匹配，列出所有可用的迁移并进入步骤 2。

### 步骤 2 — 用户确认（门禁）

展示完整的迁移计划：
- 当前 Schema 版本 → 目标 Schema 版本
- 每个迁移脚本的路径
- 备份路径（将创建）
- 迁移是否可逆

要求用户明确输入确认词（如 "YES-MIGRATE"）才能继续。
浅度确认（"ok"/"yes"/"y"）不通过，防止误触发。

### 步骤 3 — 备份

调用 `themis-migrate.sh --backup <target>`。
向用户输出备份绝对路径。
确认备份完成后才能进入步骤 4。

### 步骤 4 — 执行迁移

对每个迁移描述符调用：
`themis-migrate.sh --run <target> --migration-id <from>→<to>`

解析 JSON 输出：
- `status: "success"` → 展示 changed_files，继续下一个迁移
- `status: "skipped"` → 提示已应用，继续下一个迁移
- `status: "failure"` → 展示 errors，进入回滚

每个迁移完成后，如果用户要求暂停审核，可以暂停。
但不得在迁移失败后继续执行下一个迁移。

### 步骤 5 — 验证

调用 `themis-migrate.sh --verify <target>`。
展示验证结果：
- 所有步骤通过 → 进入步骤 6
- 任一步骤失败 → 展示失败项，建议回滚，要求用户决定

### 步骤 6 — 完成

调用 `themis-migrate.sh --rollback <target> --backup-path <path>` 进行回滚。
之后提示迁移日志已记录到 `workspace/state/migration_log/`。
提示备份路径，建议用户在确认迁移成功后手动删除。

## 回滚引导

如果用户选择回滚或验证失败：
调用 `themis-migrate.sh --rollback <target> --backup-path <path>`。
之后确认 Workspace 已恢复，展示回滚完成信息。
```

## 目标文件 2：`themis-migrate.sh`

**路径**：`bin/themis-migrate.sh`

### 命令行接口

```text
Usage: themis-migrate.sh <target> <action> [options]

Actions:
  --check              查询可用的迁移描述符，输出 JSON
  --backup             创建 Workspace 完整备份
  --run                执行指定迁移脚本
    --migration-id <id>  迁移标识符（from→to）
  --verify             验证迁移后的 Workspace 完整性
  --rollback           从备份恢复 Workspace
    --backup-path <path> 备份目录路径
  --dry-run            只读检查，不写入
  --help               输出帮助
```

### 函数设计

```bash
# 输出稳定诊断并退出
themis_migrate_error() { ... }

# 输出帮助信息
themis_migrate_usage() { ... }

# 解析命令行参数
themis_migrate_parse_arguments() { ... }

# 要求 mikefarah/yq v4（独立于 P0，与 Upgrade 一致）
themis_migrate_require_yq() { ... }

# 从 core.yaml 的 compatibility.*.migrations[] 中
# 查找匹配已安装 Schema 的迁移描述符
themis_migrate_find_descriptors() { ... }

# 创建 workspace/ 完整备份
# 输出 JSON: {"backup_path": "...", "files_count": N}
themis_migrate_create_backup() { ... }

# 执行一个迁移脚本
# 调用 core/migrations/<path>.sh <workspace_path>
# 收集 JSON 输出
themis_migrate_run_one() { ... }

# 验证迁移后 Workspace（目录结构 + 工件格式 + 索引）
themis_migrate_verify() { ... }

# 从备份恢复 Workspace
themis_migrate_restore_backup() { ... }

# 将迁移记录写入 workspace/state/migration_log/
themis_migrate_write_log() { ... }

# 主入口：按 action 路由到对应函数
themis_migrate_main() {
  case "${THEMIS_MIGRATE_ACTION}" in
    check)   themis_migrate_find_descriptors ;;
    backup)  themis_migrate_create_backup ;;
    run)     themis_migrate_run_one "${THEMIS_MIGRATE_MIGRATION_ID}" ;;
    verify)  themis_migrate_verify ;;
    rollback) themis_migrate_restore_backup "${THEMIS_MIGRATE_BACKUP_PATH}" ;;
    *)       themis_migrate_error "unknown action" ;;
  esac
}
```

### 关键实现约束

1. **不 source P0**：与 Upgrade 相同，独立检查 yq
2. **Bash 3.2 兼容**
3. **JSON 输出**：所有脚本输出为 JSON 格式，Agent 可解析
4. **幂等性**：`--run` 检查迁移是否已应用（exit 2 = skipped），重复执行安全
5. **原子回滚**：`--rollback` 从备份完整恢复 `workspace/`
6. **安全保护**：备份不存在时 `--run` 拒绝执行
7. **信号处理**：`trap` 捕获中断信号，确保备份保留

## 验证要求

- `migration-execution.md` 含脚本声明块（4 个脚本 + 2 个无脚本行）
- 脚本声明块每行有 Fallback 列
- `themis-migrate.sh` 通过 `bash -n` 语法检查
- `themis-migrate.sh` 通过 ShellCheck
- `themis-migrate.sh` 不 source P0 或 Init
- 所有 JSON 输出可通过 `jq` 或 `yq` 解析
