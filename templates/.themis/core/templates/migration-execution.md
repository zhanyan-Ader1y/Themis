# Themis 迁移执行引导

本文档定义 Agent 在显式迁移流程中的角色和可用脚本。Agent 负责引导用户确认，脚本负责执行确定性操作。

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
    {
      "from": "themis-workspace/v1",
      "to": "themis-workspace/v2",
      "path": "core/migrations/workspace/v1-to-v2.sh",
      "reversible": true
    }
  ],
  "artifact_migrations": []
}
```

如果没有匹配的迁移，告知用户无可用迁移路径。如果匹配，列出所有可用的迁移并进入步骤 2。

### 步骤 2 — 用户确认（门禁）

展示完整的迁移计划：
- 当前 Schema 版本 → 目标 Schema 版本
- 每个迁移脚本的路径
- 备份路径（将创建）
- 迁移是否可逆

要求用户明确输入确认词（如 "YES-MIGRATE"）才能继续。浅度确认（"ok"/"yes"/"y"）不通过，防止误触发。

### 步骤 3 — 备份

调用 `themis-migrate.sh --backup <target>`。向用户输出备份绝对路径。确认备份完成后才能进入步骤 4。

### 步骤 4 — 执行迁移

对每个迁移描述符调用：

```bash
themis-migrate.sh --run <target> --migration-id <from>→<to>
```

解析 JSON 输出：
- `status: "success"` → 展示 changed_files，继续下一个迁移
- `status: "skipped"` → 提示已应用，继续下一个迁移
- `status: "failure"` → 展示 errors，进入回滚

每个迁移完成后，如果用户要求暂停审核，可以暂停。但不得在迁移失败后继续执行下一个迁移。

### 步骤 5 — 验证

调用 `themis-migrate.sh --verify <target>`。

展示验证结果：
- 所有步骤通过 → 进入步骤 6
- 任一步骤失败 → 展示失败项，建议回滚，要求用户决定

### 步骤 6 — 完成

提示迁移日志已记录到 `workspace/state/migration_log/`。提示备份路径，建议用户在确认迁移成功后手动删除。

## 回滚引导

如果用户选择回滚或验证失败：

调用 `themis-migrate.sh --rollback <target> --backup-path <path>`。

确认 Workspace 已恢复，展示回滚完成信息。备份仍然保留，用户可审核后手动删除。
