# Migrations — 迁移

## 职责边界

Migrations 负责 Core 升级时的兼容性处理。迁移必须是显式行为，不能在加载项目时静默重写 Workspace。

**Migrations 是"升级助手"，不是"自动升级"——它告诉用户需要做什么，由用户决定是否执行。**

## 设计原则

1. **显式执行**：迁移不会自动运行，必须由用户显式触发
2. **不静默覆盖**：迁移前备份当前 Workspace 状态
3. **可回滚**：每次迁移应可回滚到迁移前状态
4. **版本检查**：迁移前检查 Core Version、Workspace Schema Version、Artifact Schema Version 的兼容性
5. **脚本/Prompt 拆分**：备份、迁移调用、验证、回滚为确定性脚本；用户确认和报告解读为 Prompt 引导

## 迁移类型

### Workspace Schema 迁移

当 Workspace Schema 版本升级时，需要迁移 Workspace 目录结构：

- 目录重命名或重组
- 文件格式变更（如 YAML → JSON）
- 新增必需文件或目录
- 迁移脚本路径：`core/migrations/workspace/`

**示例**：
```
workspace-schema v1 → v2:
  - 新增 workspace/outcomes/ 目录
  - workspace/state.json → workspace/state/ 目录结构
  - manifest.yaml 新增 workspace_schema 字段
```

### Artifact 格式迁移

当工件格式版本升级时，需要迁移已有 Spec、Plan 等工件：

- 新增必需字段
- 字段重命名
- 结构重组
- 迁移脚本路径：`core/migrations/artifacts/`

**示例**：
```
artifact-schema v1 → v2:
  - Spec 新增 "constraints" 字段
  - Plan 新增 "milestones" 字段
  - AC 格式从 "checklist" 迁移到 "given-when-then"
```

## 迁移流程

```
1. 检查兼容性
   ├── 兼容 → 正常加载，无需迁移
   ├── 可迁移 → 提示用户执行迁移（themis-migrate.sh）
   └── 不兼容 → 拒绝运行，给出诊断

2. 执行迁移（用户确认后）
   ├── themis-migrate.sh --check 查询可用迁移描述符
   ├── 用户确认（人工门禁）
   ├── themis-migrate.sh --backup 创建 Workspace 完整备份
   ├── themis-migrate.sh --run 执行迁移脚本
   ├── themis-migrate.sh --verify 验证迁移后完整性
   └── 失败回滚：themis-migrate.sh --rollback

3. 完成迁移
   ├── 更新 manifest.yaml 版本号
   ├── 记录迁移日志到 workspace/state/migration_log/
   └── 保留备份直到用户确认迁移成功
```

### 脚本/Prompt 拆分

| 步骤 | 实现方式 | 入口 |
|---|---|---|
| 兼容性检查（migration descriptor 查询） | 脚本 | `themis-migrate.sh --check` |
| Workspace 备份 | 脚本 | `themis-migrate.sh --backup` |
| 执行迁移脚本（v1-to-v2.sh 等） | 脚本 | `themis-migrate.sh --run` |
| 迁移后验证 | 脚本 | `themis-migrate.sh --verify` |
| Workspace 恢复（回滚） | 脚本 | `themis-migrate.sh --rollback` |
| 用户确认门禁 | Prompt | `migration-execution.md` |
| 迁移报告解读 | Prompt | `migration-execution.md` |

详见 [P4.5 实施设计](../plan/45-explicit-migration/README.md)。

## 兼容性矩阵

```yaml
# core/core.yaml
core_version: 0.3.0
supported_workspace_schemas:
  - themis-workspace/v1
  - themis-workspace/v2
```

```yaml
# workspace/manifest.yaml
workspace_schema: themis-workspace/v1
artifact_schema: themis-artifact/v2
```

当前 0.3.0 首次发布只支持上述原生 Schema，Artifact migration descriptor 为空。未来 Schema 演进时，Core 才可在 `compatibility.*.migrations` 中声明显式转换；在此之前不应虚构历史版本或兼容模式。

Core 在加载时检查：
- `workspace_schema` 是否在 `supported_workspace_schemas` 列表中
- 如果不在，是否可迁移（有对应的迁移脚本）
- 如果不可迁移，拒绝运行并给出诊断信息

## 与 Workspace 的交互

```
Migrations 读取:
  core/core.yaml                    # Core 版本和兼容性信息
  workspace/manifest.yaml           # 当前 Workspace 版本
  workspace/                        # 需要迁移的 Workspace 内容

Migrations 写入:
  workspace/manifest.yaml           # 更新版本号
  workspace/                        # 迁移后的 Workspace 内容
  workspace/state/migration_log/    # 迁移记录
```

## 迁移安全

1. **备份优先**：迁移前完整备份 `workspace/` 目录
2. **原子性**：迁移要么全部成功，要么全部回滚
3. **幂等性**：同一迁移脚本多次执行结果相同
4. **记录**：每次迁移记录到 `workspace/state/migration_log/`