# Migrations — 显式迁移

> 规范状态：正式设计。实现状态：部分实现；迁移的 `--check`、`--backup`、`--run`、`--verify`、`--rollback` 入口及 policy、Prompt、Kernel rule 和测试已落地，但脚本尚未强制确认/备份前置条件，也不会在验证失败后自动回滚。当前模板没有具体 migration descriptor 或 Schema 转换脚本，因此没有可执行的版本转换。

## 职责边界

Migration 是唯一允许转换 Workspace Schema 或 Artifact Schema 的机制。它与 Upgrade 分离，必须由用户显式授权，不能在安装、加载或 Upgrade 中静默运行。

当前发布的 `themis-artifact/v2` / `themis-spec/v2` 是首次使用的原生合同，不存在 Spec v1→v2 转换脚本、兼容 descriptor 或 runtime read-only 模式。通用迁移框架保留给未来经设计确认的 Schema 演进。

## 安全规则

1. **显式执行**：用户选择迁移后才可执行。
2. **备份优先**：修改 Workspace 前创建完整、持久的备份。
3. **确定性操作**：descriptor 查询、备份、脚本调用、验证和回滚由 Shell 执行。
4. **Prompt 边界**：Prompt 负责确认、解释和下一步引导，不伪造脚本结果。
5. **可回滚**：验证失败时恢复迁移前 Workspace。
6. **幂等与可追溯**：迁移脚本检查目标状态并输出机器可读结果。
7. **Upgrade 隔离**：Upgrade 只诊断兼容性并提示迁移入口，不自动调用 Migration。

## 执行流程

```text
兼容性检查
  ├─ 直接兼容 → 无需迁移
  ├─ descriptor 可用 → 用户确认后执行显式迁移
  └─ 无兼容或 descriptor → 拒绝并给出诊断

显式迁移
  --check → 用户确认 → --backup → --run → --verify
                                         └─ 失败 → --rollback
```

| 操作 | 确定性入口 |
|---|---|
| 查询 descriptor | `bin/themis-migrate.sh --check` |
| 备份 Workspace | `bin/themis-migrate.sh --backup` |
| 运行指定迁移 | `bin/themis-migrate.sh --run --migration-id <migration-id>` |
| 验证迁移结果 | `bin/themis-migrate.sh --verify` |
| 从备份恢复 | `bin/themis-migrate.sh --rollback --backup-path <path>` |

当前入口把确认、备份、运行、验证和回滚拆为独立命令。Prompt 规定调用顺序，但 `--run` 尚未检查确认或备份凭据，`--verify` 失败也只返回非零状态；调用方必须显式执行 `--rollback`。完整安全编排在脚本强制这些前置条件前仍属于部分实现。

用户确认和报告解读由 `core/templates/migration-execution.md` 引导。

## 兼容性合同

`core/core.yaml` 分别声明 Workspace 和 Artifact 的：

- `supported` allow-list；
- `migrations` descriptor 列表；
- migration root。

`workspace/manifest.yaml` 分别声明 `workspace_schema` 和 `artifact_schema`。版本是否兼容由 allow-list 与 descriptor 决定，不要求与 Core Version 相等。

当前模板状态：

```yaml
core_version: 0.3.0
compatibility:
  workspace:
    supported: [themis-workspace/v1]
    migrations: []
  artifact:
    supported: [themis-artifact/v2]
    migrations: []
```

因此 P4.5 的分步执行组件已经存在，但端到端安全顺序仍由 Prompt 和调用方保证，脚本尚未强制编排；当前 release 也没有任何具体版本转换可运行。只有 descriptor 和对应可执行脚本同时存在时，才可声称某条迁移路径可用。

## 实现证据

- [`bin/themis-migrate.sh`](../../../bin/themis-migrate.sh)
- [`templates/.themis/core/policies/migration.yaml`](../../../templates/.themis/core/policies/migration.yaml)
- [`templates/.themis/core/templates/migration-execution.md`](../../../templates/.themis/core/templates/migration-execution.md)
- [`templates/.themis/core/kernel/migrations.md`](../../../templates/.themis/core/kernel/migrations.md)
- [`tests/migrate/test.sh`](../../../tests/migrate/test.sh)
- [P4.5 实施记录](../../plan/45-explicit-migration/)
