# Orchestrator — 编排器

## 职责边界

Orchestrator 是 SDD 生命周期的中央调度器。它负责驱动 Spec 从创建到归档的完整状态流转，但不拥有任何 Spec 的具体内容——内容始终属于 Workspace。

**Orchestrator 只处理"何时做、做什么"，不处理"怎么做"。**

## 核心能力

| 能力 | 说明 |
|---|---|
| 生命周期驱动 | 按定义的状态机推进 Spec 阶段 |
| 状态迁移 | 校验迁移前置条件，执行迁移，记录历史 |
| 任务路由 | 根据当前状态和策略决定下一步执行的任务 |
| 失败恢复 | 检测失败状态，执行重试或回滚策略 |

## 子模块

### Lifecycle — 生命周期

定义 SDD 工作单元的标准生命周期阶段：

```
Draft → Specified → Planned → Implemented → Verified → Reviewed → Archived
```

- 每个阶段有明确的进入条件和退出条件
- 阶段间的迁移由 Transitions 子模块强制执行
- 生命周期策略定义在 `core/policies/lifecycle.yaml`，项目可在 `workspace/policies/workflow.yaml` 中扩展

**边界**：Lifecycle 只定义阶段语义，不定义具体阶段内的执行逻辑（那是 Specification、Planning 等模块的职责）。

### Transitions — 状态迁移

执行并记录状态迁移：

- 校验迁移合法性（当前状态是否允许迁移到目标状态）
- 执行迁移前置条件检查（如：进入 Verified 前必须通过所有 Gate）
- 记录迁移历史到 `workspace/state/transitions/`
- 迁移失败时触发 Recovery 子模块

**边界**：Transitions 是状态机执行器，不定义迁移规则本身（规则在 `core/policies/transitions.yaml`）。

### Task-Routing — 任务路由

根据当前状态和上下文决定下一步执行的任务：

- 读取当前 Spec 状态
- 查询有效策略（Core 默认 + 项目覆盖）
- 决定下一步应执行的任务类型（如：规划、验证、评审）
- 将任务调度到对应的 Kernel 模块

**边界**：Task-Routing 只负责"路由到哪个模块"，不负责模块内部的具体执行。

### Recovery — 失败恢复

处理执行过程中的失败：

- 分类失败类型（瞬态、持久、策略冲突）
- 按失败分类决定恢复策略（重试、跳过、回滚、人工介入）
- 记录失败和恢复历史
- 失败分类定义在 `core/policies/failure-categories.yaml`

**边界**：Recovery 不执行具体的修复操作（修复由开发者或 Agent 完成），它只负责识别失败并决定恢复策略。

## 与 Workspace 的交互

```
Orchestrator 读取:
  workspace/manifest.yaml          # 项目配置
  workspace/policies/workflow.yaml # 项目策略覆盖
  workspace/state/                 # 当前状态
  workspace/specs/<spec-id>/       # 工件状态

Orchestrator 写入:
  workspace/state/transitions/     # 迁移历史
  workspace/state/tasks/           # 当前任务
  workspace/state/retries/         # 重试记录
  workspace/state/sessions/        # 执行会话
```

## 输入/输出协议

- **输入**：通过 Context Protocol 读取项目状态，通过 Spec Artifact Protocol 读取工件状态
- **输出**：通过 Outcome Protocol 记录迁移和任务执行结果