# Plan 35：Core Prompt Flow

> 状态：实施设计，待用户单独确认。本文存在不构成实施授权；本次计划队列清理尤其**不授权实施 Plan 35**。

## 1. 目标

建立 Themis 的 Prompt-first 语义主流程，使当前 Agent 环境在缺少完整确定性运行时的前提下，仍能按明确领域边界完成一次可人工审阅的端到端变更流程。基线覆盖八个领域：

1. Context
2. Specification
3. Planning
4. Review
5. Implementation
6. Verification
7. Delivery
8. Knowledge

本计划优先完成语义阶段、用户交互、handoff 和失败边界，不把尚未实现的机器保证包装为现有能力。正式生命周期、事实与证据语义继续以 [完整工作流程](../../design/workflow.md)、[总体架构](../../design/architecture.md) 和 [设计治理](../../design/governance.md) 为准。

## 2. 确认与依赖

- 前置计划：无。
- 实施前置：用户必须针对 Plan 35 明确授权实施。
- Plan 35 的接受只允许 Plan 36 进入单独评审，不自动授权 Plan 36。
- 若实施中发现需要改变长期设计，应先更新所属 `docs/design/**` 页面并取得确认，不能用本计划正文建立第二套规范。

## 3. 当前基线

实施开始时必须重新核验 checkout；本计划编写时可见的相关基线包括：

- Orchestrator、Specification、Context、Planning、Review、Verification、Knowledge 与 Attribution 的领域 `rules.md` 骨架或部分规则。
- 已存在的 themis-q Project Skill、Draft Spec 发布能力和 Context 检索/装配脚本。
- Planning、Review、Implementation、完整 Verification、Delivery 与 Knowledge 的端到端执行能力尚不完整。
- 当前缺少能够可靠记录完整 lifecycle transition 的通用生产执行器。

以上只是定位依据。实施不得从文件名推断能力已可用，必须读取实际内容并验证可调用接口。

## 4. 范围

### 4.1 Prompt-first 生命周期

为八个领域建立可从 Orchestrator 按需到达的 Prompt 流程。每个领域 Prompt 至少明确：

- 阶段目标、owner、允许的语义判断和禁止越界事项；
- 必需输入、currentness 检查、缺失输入的停止条件；
- 必须读取的正式设计、policy、template、checklist 与项目事实；
- 实际可用的工具或命令、调用前存在性检查和失败 fallback；
- 人工确认点、结构化 handoff 和下一阶段条件；
- 不足证据、冲突、能力缺失和返工时的稳定输出；
- 该阶段可以生成的人工工件，以及不得宣称的机器状态或证据。

### 4.2 领域行为

#### Context

- 解析显式 Context ID 和请求 scope。
- 读取受治理 Context 与当前代码、配置、Schema 两个项目事实根。
- 使用实际存在的 Catalog、Search、Bundle、Freshness 与 Signal 能力；缺失时进行有界人工读取并明确降低保证等级。
- 对缺失、冲突、过期和 `context_code_drift` 建立可见处理，不静默选择来源。

#### Specification

- 在需要澄清时使用实际存在的 themis-q 方法，但由 Specification 拥有流程、收敛、确认和工件。
- 形成 intent、scope、constraints、assumptions、Acceptance Criteria、adversarial cases、risks 与 approval evidence。
- 只有用户明确同意生成 Draft Spec 后才调用真实存在的发布能力。
- 不把 Draft Spec 发布冒充 `draft → specified` transition。

#### Planning

- 基于 approved/current Spec、Context 和当前代码事实生成 Plan。
- 定义稳定 Task ID、依赖 DAG、scope lock、AC traceability、预期 evidence、Gate 和人工验收步骤。
- 直接核验代码位置，不从旧计划、摘要或模型记忆推断当前结构。
- Planning 不修改实现文件，不授权 Implementation。

#### Review

- 固定在 Implementation 前，只读审查 current Spec、Plan、Context/代码依据、设计、接口、风险、回滚和验收方案。
- 只输出 `approved`、`changes_requested` 或 `blocked` 语义结果，并记录其引用范围。
- 未解决的 critical/major finding、过期绑定或不足证据不能得到 `approved`。
- Review 不读取“已经完成的实现 diff”来倒置流程，也不替代 Verification。

#### Implementation

- 只在 Review 已批准的前提下，一次执行一个依赖就绪 Task。
- 持续执行 Task scope、Plan scope lock 和 Review authorization。
- 计划不足但仍在 Spec 内时返回 Planning；超出 Spec 时返回 Specification；Review 绑定变化后必须重新 Review。
- 保存 Task、AC、变更文件、偏差和已观察完成信息，但不计算 Verification verdict。

#### Verification

- 固定在 Implementation 后。
- 只运行 manifest、Plan、policy 或批准方案中实际存在且允许的命令；不得发明替代命令。
- 收集精确命令、环境、exit code、stdout/stderr 引用、覆盖范围、失败和限制。
- 只有证据充分且 current 时才能返回 `pass`；明确失败返回 `fail`；命令缺失、证据不可访问、覆盖不足或判断不确定时返回 `inconclusive`。
- Verification 在本计划中可以形成语义报告，但不得伪造 durable Run、Evidence 或 machine transition。

#### Delivery

Delivery Prompt 必须强制以下顺序：

1. current Verification 返回 `pass`；
2. Human Acceptance 已持久记录为 `accepted`；
3. 仅在以上两项均满足后生成 Summary。

`fail` 或 `inconclusive` 不得进入 Acceptance。`rejected` 必须按原因返回 Specification、Planning 或 Implementation；实现变化后重新 Verification。若缺少持久 Acceptance recorder，本计划不得用聊天中的“接受”冒充 durable `accepted`，也不得生成正式 Summary。

#### Knowledge

- 从 Review、Implementation、Verification、Acceptance 或 Outcome 中提出候选，不直接写入正式 Context。
- 判断候选价值、稳定性和语义归属由 Prompt/Agent 与人负责。
- 任何 Knowledge 变更必须依次满足：
  1. 人工批准具体变更；
  2. 将批准内容实际应用到受治理来源；
  3. 重新读取该来源并核验已应用内容。
- 缺少批准、写入能力或 read-after-write 核验时，保持 candidate/pending，不宣称 promotion 成功。

### 4.3 Orchestrator 串联

- 建立浅层、按需加载的领域导航；不全局导入大 Prompt。
- 明确每个阶段的进入条件、停止条件、返工目标和 handoff 字段。
- 在能力不存在时停留当前语义阶段并报告，不推演不存在的 machine transition。
- 对只读研究与受管理变更进行入口区分，避免无须生命周期的请求被强制写工件。

## 5. 明确非目标

Plan 35 不实现或承诺以下基线能力：

- production installer；
- Spec executor；
- Context executor；
- deterministic projector；
- state recorder；
- regression suite；
- fresh Init；
- production deterministic runtime；
- Plan 36 的严格合同或 `tests/contracts`；
- Plan 37 的 Go CLI、包和跨平台运行时；
- 多 Agent 拓扑或 Attribution analytics。

本计划也不重写现有脚本以制造“已完成运行时”的表象，不新增生产 shell fallback，不扩大为测试套件建设。

## 6. 拟议工件布局

实施时应优先编辑现有文件；最终路径需在开始实施时根据 checkout 确认。预期变更类别：

- `templates/.themis/core/kernel/orchestrator/`：入口路由、按需读取和返工规则。
- `templates/.themis/core/kernel/<domain>/`：八个领域的精简 `rules.md` 与 Prompt 工件；Delivery 可在确认长期所有权后落入所属现有领域结构，不因计划自行建立规范。
- `templates/.themis/core/policies/`：仅补 Prompt 需要引用的稳定语义标识和控制声明，不实现执行器。
- `templates/.themis/core/templates/`：人工 handoff、Review、Verification、Acceptance、Summary 或 Knowledge candidate 的模板，仅在 Prompt 流程确有需要时增加。
- 项目加载 guidance：仅做使已实现领域可达的最小更新。
- `docs/design/**`：只有实施揭示规范需调整并另获确认时才更新，不属于默认范围。

不得创建功能版本目录，也不得把全部领域逻辑堆入单个常驻规则文件。

## 7. 任务拆分

### T35-01 基线与能力清单

- 读取当前 import 图、所有领域 rules、Prompt、policy、template、Skill 和脚本。
- 记录真实存在的能力、命令接口、缺失项和 fallback。
- 建立八领域输入/输出/owner/禁止事项矩阵。

完成标准：后续 Prompt 的每个能力引用都能对应当前文件或明确 unavailable 路径。

### T35-02 共用 Prompt 合同

- 统一 currentness、事实来源、工具存在性、停止/返工、non-fabrication 和 handoff 要求。
- 定义语义结果与 machine state/evidence 的显式区分。
- 保持控制标识稳定且无模块版本。

完成标准：各领域无需复制完整治理正文，但能通过明确 MUST Read 与稳定字段遵循同一边界。

### T35-03 Context 与 Specification

- 串联 Context resolution、漂移处理、themis-q、规范化摘要、Draft 确认和现有 Spec 发布能力。
- 为缺失 executor 与 transition 提供 fail-closed 输出。

完成标准：可以人工演练从请求到 Draft Spec；输出不会声称不存在的 `specified` transition。

### T35-04 Planning 与前置 Review

- 实现 Task DAG、traceability、scope lock 和验证/验收方案的语义生成流程。
- 实现 Review 的 `approved/changes_requested/blocked` 判断与 revision binding 表达。

完成标准：人工案例能在任何实现修改前得到可审阅 Plan 和 Review 结果；变更 Plan 后需要重新 Review。

### T35-05 Implementation 与 Verification

- 实现单 Task、依赖就绪、范围约束和返工 handoff。
- 实现命令存在性检查、evidence sufficiency 与 `pass/fail/inconclusive` 语义。

完成标准：缺失命令或证据的场景稳定返回 `inconclusive`，不生成虚假 Run/Evidence 或 transition。

### T35-06 Delivery

- 实现 Verification `pass`、durable Acceptance `accepted`、Summary 的严格三段门禁。
- 为 Acceptance recorder 或 projector 缺失定义阻塞输出。

完成标准：任何 `fail`、`inconclusive`、未持久接受或 `rejected` 情况都不能生成 Summary。

### T35-07 Knowledge

- 实现 candidate 提取、来源核验、冲突/重复检查、人工批准请求、应用和 reread 核验的语义流程。
- 将缺失写入/事务能力映射为 pending，而不是成功。

完成标准：人工拒绝、应用失败和 reread 不一致均不会污染正式 Context 或宣称成功。

### T35-08 Orchestrator 集成与人工验收

- 串联八领域和返工路由。
- 检查按需加载，避免常驻上下文膨胀。
- 运行手工端到端场景并保存可审阅结果。

完成标准：核心 happy path 与关键失败路径均可人工重放；机器保证缺失处被明确标注。

## 8. 手工端到端验收

Plan 35 不新增 regression suite，以人工场景作为本阶段验收：

| 场景 | 预期 |
|---|---|
| 模糊需求 | 在 Draft Spec 前追问并等待明确确认 |
| Context 缺失或漂移 | 记录冲突/不足并请求证据或裁决 |
| Plan DAG 或 AC 覆盖不完整 | Review 前阻塞或返回 Planning |
| Review 请求变更 | 不进入 Implementation |
| Review binding 过期 | 必须重新 Review |
| 未批准 Task 或越界修改 | Implementation 停止并返工 |
| Verification 命令不存在 | 返回 `inconclusive`，不发明命令 |
| 证据不完整或 stale | 返回 `inconclusive` 或失败，不报告 `pass` |
| Verification `fail` | 不允许 Human Acceptance |
| Verification `pass` 但 Acceptance 未持久化 | 不生成 Summary |
| Acceptance `rejected` | 返回所属阶段；实现变化后重新 Verification |
| Acceptance durable `accepted` | 才允许 Summary 阶段 |
| Knowledge 获批但未实际写入 | 不报告 promotion 成功 |
| Knowledge 写入后 reread 不一致 | 保持 pending/failed 并报告差异 |

每个场景至少记录输入、所读依据、实际调用、输出、缺失保证和人工判断。对不存在的 recorder/projector，只验收 Prompt 的 fail-closed 行为。

## 9. 验证矩阵

实施完成后至少执行：

- 检查所有领域从 Orchestrator import 图可达且按需加载。
- 搜索并审查所有 Prompt 中的工具/命令引用，逐项确认实际存在或声明 unavailable fallback。
- 审查 Review 在 Implementation 前、Verification 在 Implementation 后的全部路由。
- 审查 Delivery 的 `pass` + durable `accepted` + Summary 顺序。
- 审查 Knowledge 的 human approval + actual apply + reread verification 顺序。
- 执行第 8 节人工场景，并保留实际观察结果。
- 运行仓库现有、与所改模板/加载合同直接相关的验证命令；不存在的测试不得替代或虚构。
- 运行 `git diff --check` 并确认变更范围符合已确认计划。

## 10. 完成与接受条件

Plan 35 只有在以下条件全部满足时才可报告实施完成：

- 八个领域均有明确、可达、边界一致的 Prompt-first 流程。
- Review 明确先于 Implementation，Verification 明确后于 Implementation。
- 不足证据稳定得到 `inconclusive` 或失败，而非成功。
- Delivery 无法绕过 current Verification `pass` 和 durable Acceptance `accepted`。
- Knowledge 无法绕过人工批准、实际应用和 reread 核验。
- 未实现的 production installer、executor、projector、recorder、runtime 和 regression suite 没有被宣称存在。
- 所有实际调用均经过存在性核验，没有虚构文件、状态、输出、命令、证据或成功。
- 人工端到端验收记录已交给用户审阅。
- 用户另行明确接受 Plan 35 的实施结果。

该接受只结束 Plan 35；Plan 36 仍需单独确认。
