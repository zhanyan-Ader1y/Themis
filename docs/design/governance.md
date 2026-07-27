# 设计治理

> 规范状态：正式设计。实现状态：治理规则已生效；P5.4 Context Trust 的 Protocol、检索、装配与 Signal 执行器尚未实现。

本文定义 Themis 设计规范、项目事实、流程事实、持久证据和非规范文档之间的权威关系。文档分类与状态语义见 [设计规范入口](README.md)。

## 设计权威

- `docs/design/**` 是已确认 Themis 设计规范的唯一权威来源。
- `AGENTS.md` 与 `AGENTS.CN.md` 只定义仓库协作方式，并将 Agent 引导到本目录。
- 模块计划、实施记录、分析报告、模板、Prompt、策略和变更日志不得成为长期规则的唯一来源。
- 其他文档与本目录冲突时，先按本目录执行；随后修正冲突文档或明确记录设计—实现漂移。
- 新规则必须归入一个明确的设计页。跨模块文档只能链接该规则，不得复制完整正文。

## 设计确认与变更

1. 未确认的方案保留在 `docs/plan/**`，状态为提案或实施设计。
2. 用户确认长期设计后，在同一次变更中更新对应 `docs/design/**` 页面。
3. 计划不是实施授权。Themis 源仓库的计划仍按 `AGENTS*` 中的 `impl.md` 与用户确认协议执行。
4. 实现完成后，根据实际资产与验证结果更新设计页的实现状态。
5. 规则被替代或退役时，在当前设计页记录新结论；历史计划只添加 superseded 注记，不改写原始过程。

## 项目事实可信模型

项目事实只有两个职责不同的可信根：

```text
受治理的 workspace/context/  → 项目应当表达什么
当前代码、配置与 Schema       → 项目现在实现什么
```

- Context 对业务概念、规则、不变量、术语、持久决策、外部约束和工程约定负责。
- 当前 revision 的代码、配置、Schema 和其他版本化实现工件对当前实现路径、值、结构和行为负责。
- 两个可信根不存在全局覆盖顺序；声明必须按类型引用相应来源。
- Context 与当前实现冲突时，必须记录 `context_code_drift`，不能静默选择任一方。
- Context 缺失时，代码只能证明当前实现，不能自动证明业务意图；代码不可读时，Context 不能证明行为已实现。

以下内容不独立建立项目事实：

- Spec 只定义已批准的期望变化、范围和 Acceptance Criteria；
- Plan 只定义任务组织、范围和证据要求；
- State 只记录机器生命周期、Task 和其他流程状态；
- Run/Evidence 只证明命令、Gate 和观察结果；
- Outcome 只记录交付后的测量结果；
- Core policy、protocol、rules 和 Prompt 只定义 Themis 控制合同；
- Knowledge 只保存候选和治理历史；
- Human projection（包括 `spec.md`、`review.md`、`verify.md`、`summary.md`）只用于审阅和交付表达，不独立建立机器事实或状态；
- 对话、模型记忆、搜索排名、摘要、Cache 和 Agent 推断均不能独立建立事实。

代码变更使受影响的 Verification evidence 失效，相关 Gate 必须重新执行。

State、Run、Evidence 和 Outcome 可以是各自命名空间中的权威记录，但其中可复用的观察必须经 Context 或当前代码核验并通过 Knowledge Governance，才能成为正式项目知识。详细读取和冲突合同见 [Context](core/kernel/context.md)。

## 知识候选来源与准入

CLAUDE/AGENTS 文件、验收测试、代码与配置、对话、决策表、Implementation 经验、Verification escalation、Review finding、Outcome 和人工输入都可以提供 candidate 或 evidence，但不能因其形式、出现频率或模型置信度而直接成为正式知识。

进入受治理 Context 的知识至少必须满足：

- 有可解析的来源 artifact 或 evidence，且可以归因到目标项目、Workspace 与 source revision；
- 是项目特定且会跨需求重复影响判断的规则、约束、术语、决策、事故经验或外部合同；
- 在预期生命周期内足够稳定，提前提供能够防止“能运行但不符合项目意图”的实现；
- 已读取当前 Context 和相关代码、配置或 Schema，完成重复、冲突和新鲜度检查；
- Scope 与表述清楚，不把临时讨论、大段源码、泛化 Prompt 技巧或一次性修复步骤提升为长期规则；
- 已审核敏感信息，并经过持久化人工批准和确定性处置。

候选不满足任一条件时应保留为治理记录、要求 revise 或 reject，不得直接污染 `workspace/context/`。

## 实现事实与证据

判断当前实现能力时，优先使用：

1. 当前代码、配置、结构化工件和已观察到的命令输出；
2. 持久化 Workspace 状态与记录的 Evidence；
3. Core policy、protocol 和确定性脚本输出；
4. 已加载的规则与 Prompt 指引；
5. 对话记忆或 Agent 推断。

设计规范定义目标契约，但不能替代实现证据。没有观察到文件、能力或命令输出时，不得推断其存在或成功。

## 状态与门禁证据

- 生命周期路由必须来自持久工件和机器状态，而不是对话声明。
- 用户批准、Prompt 输出或完成的 Markdown 工件可以成为门禁证据，但不是机器状态迁移本身。
- 只有持久状态或确定性执行器可以记录状态迁移。
- 缺失、不可访问或不确定的证据不构成成功；前置 Review 必须返回 `blocked` 或 `changes_requested`，Verification 必须返回 `inconclusive` 或失败。
- Review 是 Implementation 前的只读设计与计划批准，不能代替命令驱动的 Verification。
- Human Acceptance 只能在 current Verification `pass` 后记录；`summary.md` 只能在 `accepted` 后生成，并且不是机器状态或证据源。

生命周期与返工路由的完整定义见 [完整工作流程](workflow.md)。

## 设计与实现漂移

发现设计与当前实现不一致时：

1. 以代码、模板、结构化工件、测试和实际输出描述当前能力。
2. 判断是实现缺失、文档过时还是设计已经变更。
3. 在所属设计页修正实现状态或规范；需要实施时创建或更新对应计划。
4. 不通过删除失败证据、改写历史记录或降低状态语义来掩盖漂移。

## 知识权威

正式项目知识只有一个权威位置：`workspace/context/`。`workspace/knowledge/` 保存候选、审核、拒绝、修订和归档等治理过程数据，不构成第二套正式知识库。详细流程见 [Knowledge](core/kernel/knowledge.md) 与 [Workspace](workspace/overview.md)。
