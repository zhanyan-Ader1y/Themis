# Migrations — 迁移

## 职责边界

Migrations 负责 Core 升级时的兼容性处理。迁移必须是显式行为，不能在加载项目时静默重写 Workspace。

**Migrations 是"升级助手"，不是"自动升级"——它告诉用户需要做什么，由用户决定是否执行。**

## 设计原则

1. **显式执行**：迁移不会自动运行，必须由用户显式触发
2. **不静默覆盖**：迁移前备份当前 Workspace 状态
3. **可回滚**：每次迁移应可回滚到迁移前状态
4. **版本检查**：迁移前检查 Core Version、Workspace Schema Version、Artifact Schema Version 的兼容性

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
   ├── 可迁移 → 提示用户执行迁移
   └── 不兼容 → 拒绝运行，给出诊断

2. 执行迁移（用户确认后）
   ├── 备份当前 Workspace
   ├── 执行 Workspace Schema 迁移
   ├── 执行 Artifact 格式迁移
   ├── 更新 manifest.yaml 版本号
   └── 生成迁移报告

3. 验证迁移
   ├── 检查目录结构完整性
   ├── 检查工件格式正确性
   └── 检查索引一致性
```

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
artifact_schema: themis-artifact/v1
```

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