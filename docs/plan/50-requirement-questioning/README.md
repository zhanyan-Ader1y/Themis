# P5 — Requirement Questioning（需求追问）

**优先级**：P5
**依赖**：[P1 Template Contract](../10-template-contract/README.md)、[P2 Top-level Guidance](../20-top-level-guidance/README.md)
**状态**：待用户主动发起

## 背景

AI 编码 Agent 倾向于直接写代码而非先理解需求。Themis 当前的 Specification 模块只定义了 Spec 的结构校验，缺少**需求澄清对话流程**——即从用户的模糊意图到一份可执行 Spec 之前的追问与收敛机制。

## 参考来源

obra/superpowers 的 brainstorming skill（`skills/brainstorming/SKILL.md`）定义了完整的追问工作流，其核心模式经过超过 26 万 GitHub star 的社区验证。

## 目标

将 superpowers 的追问策略适配到 Themis，作为 Specification 模块的**前置对话流程**，嵌入 SDD 生命周期的 `Draft → Specified` 阶段。

## Themis 追问策略设计

### 核心原则

| 原则 | superpowers 来源 | Themis 适配 |
|---|---|---|
| 一次只问一个问题 | 避免认知过载，每个回答影响后续问题 | 保留，由 Orchestrator 驱动单轮对话 |
| 优先选择题 | 降低用户认知负担 | 保留，允许开放式追问 |
| 先评估范围再深入 | 多子系统项目先分解再细化 | 保留，与 Planning 的分解能力对齐 |
| 硬门禁：无 Spec 批准不写代码 | HARD-GATE 标记 | 映射为 Orchestrator 的 `Draft → Specified` 迁移条件 |
| 设计分段验证 | 每段设计后询问"这样对吗" | 保留，AC 分段确认 |

### 三步追问流程

```
Step 1 — Scope Assessment（范围评估）
  ├── 识别是否多子系统
  ├── 若是：帮助分解为子项目，先追问第一个
  └── 若否：进入详细追问

Step 2 — Context Gathering（上下文收集）
  ├── 目标：解决什么问题？给谁用？
  ├── 约束：技术栈、时间、依赖、兼容性
  ├── 成功标准：怎样算"做完"？
  └── "Option Zero"：能否不改代码解决？

Step 3 — Design Convergence（设计收敛）
  ├── 提出 2-3 种方案 + 取舍 + 推荐
  ├── AC 分段确认（每段 1-3 个 AC）
  ├── 写入 workspace/specs/<spec-id>/spec.md
  ├── Spec 自检（占位符、矛盾、歧义、范围）
  └── 用户批准后触发 Draft → Specified 迁移
```

### 防绕过机制（Red Flags）

Themis 需要内置类似的"Agent 自我合理化"检查表，拦截常见的跳过追问行为：

| Agent 的想法 | Themis 的约束 |
|---|---|
| "这个需求很简单，直接写就行" | 没有 Spec 的代码变更不进入 Implemented 阶段 |
| "我先看看代码再理解需求" | 先读 Context，再追问，再看代码 |
| "这个不需要正式 Spec" | 所有需求变更都必须有 Spec，简单需求 Spec 可以短 |
| "我先改一行试试" | 迁移到 Implemented 之前必须 Specified |

### 与 SDD 生命周期的整合

```
Draft
  │
  ├── P5 追问流程执行（Specification 模块驱动）
  │     ├── Scope Assessment
  │     ├── Context Gathering
  │     └── Design Convergence
  │
  ▼
Specified（硬门禁：用户批准 Spec 后才迁移）
  │
  ▼
Planned（Planning 模块接管）
```

### 实现位置

- **规则引擎**：`core/kernel/specification/rules.md` — 追问流程的定义规则
- **策略配置**：`core/policies/specification.yaml` — 追问深度、范围阈值、AC 分段策略
- **模板**：`core/templates/spec-questioning.md` — 追问提示词模板
- **Orchestrator 集成**：`core/policies/transitions.yaml` — `Draft → Specified` 增加硬门禁条件

## 范围

- 适配 superpowers 的一次一问、选择题优先、范围评估、分段验证、硬门禁机制
- 对 Themis 的 SDD 生命周期增加 `Draft → Specified` 的前置追问流程
- 定义防绕过的 Red Flags 检查表
- 与 Orchestrator 的 Transitions 子模块集成

## 非范围

- 不实现 superpowers 的 Visual Companion 功能
- 不实现 superpowers 的 Subagent-Driven-Development 分发模式
- 不改变 Specification 模块已有的结构校验能力
- 不实现多轮对话的状态持久化（由 Orchestrator 的 sessions 子模块负责）

## 目标文件

- `core/kernel/specification/rules.md`
- `core/policies/specification.yaml`（新增）
- `core/templates/spec-questioning.md`（新增）
- `core/policies/transitions.yaml`（更新：增加硬门禁条件）
- `docs/core/kernel/specification.md`（更新：增加追问流程说明）

## 执行前置步骤

当用户主动发起本计划时，**第一步**必须在本计划目录创建或更新 `impl.md`（`docs/plan/50-requirement-questioning/impl.md`），至少记录：

1. 追问流程的精确规则定义（何时分步、何时跳步）
2. Red Flags 检查表的完整条目
3. Specification 策略文件的精确字段和默认值
4. 追问模板的精确提示词结构
5. Transitions 硬门禁的实现方式
6. 与现有 Spec-Validation 的关系（追问在 Validate 之前还是并行）

`impl.md` 经用户确认前，不得修改目标文件。

## 验收条件

- `Draft` 状态的 Spec 在追问流程完成前不能迁移到 `Specified`
- 简单需求（单功能、单文件、无歧义）的追问不强制走过全部三步
- 多子系统需求在范围评估阶段被识别并建议分解
- Spec 自检能发现占位符、矛盾、歧义、范围问题
- Agent 不能以"需求简单"为由跳过 Spec 创建

## 风险与回滚

- **风险**：过度追问降低体验，用户觉得繁琐
- **缓解**：复杂度自适应——简单需求可跳过详细追问；提供 `--quick` 模式
- **回滚**：移除 transitions 中的硬门禁条件即恢复原有行为；策略文件和规则文件可整体移除
