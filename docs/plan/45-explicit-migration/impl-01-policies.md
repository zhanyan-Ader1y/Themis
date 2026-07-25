# P4.5 子模块：迁移策略与规则

## 覆盖任务

- 任务 1：`templates/.themis/core/policies/migration.yaml`（新建）
- 任务 3：`templates/.themis/core/kernel/migrations.md`（新建，当前不存在）

## 设计依据

- D2：备份、迁移调用、验证、回滚 → 脚本；用户确认 → Prompt
- D4：幂等性 → migration.yaml 中的 `idempotency_check` 字段

## 目标文件 1：`migration.yaml`

**路径**：`templates/.themis/core/policies/migration.yaml`

### 字段定义

```yaml
# Themis 显式迁移策略配置
# 由 P4.5 Explicit Migration 安装。

migration:
  # 备份配置
  backup:
    enabled: true                   # 是否强制备份（不可跳过）
    path_pattern: ".themis-migration-backup"  # mktemp 模板前缀
    retention: keep                 # keep | auto-delete-after-days
    verify_before_proceed: true     # 备份后验证完整性

  # 安全约束
  safety:
    atomic: true                    # 全部成功或全部回滚
    require_user_confirmation: true # 每步迁移前要求用户确认
    allow_partial: false            # 不允许部分迁移
    rollback_on_any_failure: true   # 任一步失败则回滚全部
    idempotency_check: true         # 迁移前检查目标状态，已完成则跳过

  # 迁移脚本调用约定
  script_convention:
    input_arg: "workspace_path"     # 迁移脚本接收 workspace 绝对路径
    output_format: "json"           # 迁移脚本输出 JSON
    output_schema:
      status: ["success", "failure", "skipped"]
      changed_files: ["list"]
      errors: ["list"]
    exit_codes:
      0: "success"
      1: "failure"
      2: "skipped (already applied)"

  # 验证步骤
  verification:
    steps:
      - id: "directory_integrity"
        description: "检查 Workspace 目录结构完整性"
        type: script                 # 脚本化
      - id: "artifact_format"
        description: "检查工件格式正确性（yq 语法检查）"
        type: script
      - id: "index_consistency"
        description: "检查 context-map 引用有效性"
        type: script
      - id: "manifest_version"
        description: "确认 manifest.yaml 中 workspace_schema/artifact_schema 已更新"
        type: script
    fail_action: rollback           # 任一步失败 → 回滚

  # 迁移日志
  log:
    path: "workspace/state/migration_log/"
    format: "json"
    fields:
      - timestamp
      - migration_id (from → to)
      - script_path
      - status
      - changed_files
      - errors
      - backup_path
```

## 目标文件 2：`kernel/migrations.md`

**路径**：`templates/.themis/core/kernel/migrations.md`

当前该文件不存在。`docs/core/migrations.md` 有完整的理论描述，但 `templates/.themis/core/kernel/` 下缺少对应的规则文件。需新建。

### 结构设计

与已有 kernel 规则文件（`specification/rules.md`、`planning/rules.md` 等）格式一致：

```markdown
# Themis Migrations

## Responsibility

Execute explicit Workspace Schema and Artifact format migrations when the
user chooses to upgrade to a Core version whose allow-list does not include
the currently installed Schema. Migrations owns the migration execution
pipeline, not the Upgrade transaction.

## Inputs

- installed `workspace/manifest.yaml` (current workspace_schema, artifact_schema);
- candidate `core/core.yaml` (compatibility.*.migrations[]);
- available migration scripts under `core/migrations/`.

## Outputs

Write migration logs only beneath `workspace/state/migration_log/` and update
`workspace/manifest.yaml` version fields. Preserve pre-migration backup at
`<target>/.themis-migration-backup.XXXXXX/`.

## Boundaries

- Do not run automatically. Migration requires explicit user confirmation.
- Do not execute migration scripts whose `from` field does not match the
  currently installed Schema.
- Do not delete migration backups until the user confirms success.
- Roll back all changes if any migration step fails.
- Do not modify Core content or the Upgrade transaction.

## Migration Pipeline

1. Compatibility check — locate a matching migration descriptor.
2. User confirmation — show the migration plan and require approval.
3. Workspace backup — full copy of `workspace/` to a persistent backup.
4. Execute migration scripts — run each in dependency order, collect JSON output.
5. Verification — directory integrity, artifact format, index consistency.
6. Completion — update manifest, write migration log, retain backup.

## Script Convention

Migration scripts must accept the workspace path as their first argument
and output a JSON object with `status`, `changed_files`, and `errors` fields.
Exit code 0 = success, 1 = failure, 2 = skipped (already applied).

## References

- Migration policy: `core/policies/migration.yaml`
- Migration prompt: `core/templates/migration-execution.md`
```

## 验证要求

- `migration.yaml` 通过 `yq eval '.'` 语法检查
- `migration.yaml` 定义 5 项安全约束（backup → atomic → confirm → rollback → idempotency）
- `kernel/migrations.md` 的格式与已有 kernel 规则文件一致
- `kernel/migrations.md` 不再有占位声明
