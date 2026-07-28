# Plan 90：Attribution Analytics

> 状态：可选、交付后实施设计，待用户单独确认。Plan 90 不阻塞核心生命周期，也不是 Verification、Human Acceptance、Summary 或核心完成的前置条件。

## 1. 目标

在交付流程已经完成后，建立可追溯的 Attribution 与 Outcome analytics，将 Spec、Plan、Review、Task、代码 revision/commit、Verification Run、deployment、Human Acceptance 和真实 Outcome 关联起来，用于回答“交付了什么、哪些工作与结果相关、证据质量如何、后续是否达到预期”。

本计划严格区分：

- Verification verdict：一次命令/evidence Run 对当前实现的验证结论；
- Human Acceptance decision：验收者是否接受当前交付；
- Outcome：交付后在真实环境中观察到的业务或工程结果；
- Attribution analysis：基于可追溯关联评估哪些变更可能与 Outcome 有关。

Analytics 不改写上述原始记录，也不把相关性包装成因果性。

## 2. 确认、时序与非阻塞性

- 实施前必须由用户针对 Plan 90 单独授权。
- Plan 90 是可选 post-delivery 能力，可在核心 Plan 35–37 之后或独立于 Plan 80 实施。
- Plan 90 运行时必须发生在 Delivery 之后；它不能成为以下事项的 prerequisite：
  - Verification；
  - Human Acceptance；
  - Summary；
  - 核心 lifecycle completion。
- Summary 仍只依赖 current Verification `pass` 和 durable Human Acceptance `accepted`，不得等待 Outcome 数据或 Attribution score。
- Archived Gate 若正式设计仍要求 Outcome/Attribution 处置，允许记录明确的 `not_configured`、`not_due` 或无数据处置，但不得把 analytics 计算成功变为核心交付成功的条件。

## 3. 权威与数据边界

### 原始来源

- Spec/Plan/Review/Task：说明批准目标、方案、风险、scope 和 traceability。
- Git revision/commit/change set：说明实际版本化实现变化。
- Verification Run/Evidence：说明在特定 revision 上实际执行的命令和 verdict。
- Deployment/release record：说明何时、何处部署了什么 revision。
- Human Acceptance：说明验收者接受或拒绝哪个 current delivery。
- Outcome observations：说明交付后指标、事件或人工调查结果。

### 派生数据

- attribution links；
- coverage/traceability metrics；
- lead/cycle time；
- defect/rework indicators；
- outcome delta/correlation；
- confidence、data quality 和 caveats；
- analytics projections。

派生 analytics 不能替换或修改原始事实。搜索排名、模型解释和 score 不是独立事实源。

## 4. Attribution graph

定义稳定 node/reference，而不是建立功能版本模型：

- Spec 与 AC；
- Plan 与 Task；
- Review decision/finding；
- implementation revision/commit/change set；
- Verification Run/Gate/attempt/evidence；
- deployment/release/environment；
- Human Acceptance record；
- Outcome observation/window；
- Knowledge candidate/disposition（仅用于后续学习关联）。

边至少区分：

- `defines` / `covers`；
- `planned_by` / `implements`；
- `approved_by`；
- `verified_by`；
- `deployed_as`；
- `accepted_by`；
- `observed_in`；
- `derived_from`；
- `supersedes` / `invalidates`。

每条边必须有 source refs、digests/revisions、recorded time 和来源类型。无法确定的关联保持 unknown/unlinked，不由模型补齐。

## 5. Outcome contract

Outcome observation 至少记录：

- Outcome ID、project/workspace identity；
- related delivery/deployment refs；
- metric/event/qualitative observation definition；
- baseline window、observation window 和 timezone；
- source system/evidence refs；
- observed value、unit、aggregation；
- collection status 和 data quality；
- confounders、external changes 和 limitations；
- observer/collector 与时间；
- immutable raw observation digest。

Outcome 允许 positive/negative/neutral/unknown 等派生解释，但原始数据必须保留。尚未到观察窗口时返回 `not_due`，数据缺失返回 `insufficient_data`，不得推断成功。

## 6. 分析范围

### 6.1 Traceability analytics

- AC → Task → change → Gate → Acceptance 完整度；
- orphan Task/change/evidence；
- stale 或 invalidated links；
- approved deviations 与未批准 deviations；
- Review finding 到修复/验证的 closure。

### 6.2 Flow analytics

- Specification、Planning、Review、Implementation、Verification、Acceptance 的阶段时长；
- Review rework、Verification rerun、Acceptance rejection cycle；
- blocking time 与 evidence collection delay；
- 多 Agent 情况下的 handoff/coordination 成本，但 Plan 80 不存在时 analytics 仍可运行。

时长必须基于 durable timestamps；缺失状态 recorder 时返回 unavailable，不从对话估算。

### 6.3 Quality analytics

- Gate pass/fail/inconclusive 分布；
- flaky/transient 与稳定 code/configuration failure；
- evidence coverage 和 stale rate；
- escaped defect/incident 与相关 delivery links；
- residual risk 接受后的实际结果。

这些指标不回写改变原 Verification verdict 或 Acceptance decision。

### 6.4 Outcome analytics

- baseline 与 observation window 的 delta；
- release cohort/environment 对比；
- 与 AC target 或 expected outcome 对比；
- data quality、sample size、confounder 和 confidence；
- 建议后续调查或 Knowledge candidate。

默认只能表述关联或时间上的伴随变化。只有存在经批准的实验/因果设计时才允许因果措辞，并必须引用该设计。

## 7. Analytics 输出

### Machine output

- query/analysis ID；
- input refs、digests 和 time window；
- metric definitions；
- results、status、data quality、unlinked counts；
- caveats 和 unsupported claims；
- deterministic computation metadata。

### Human projection

可生成 delivery attribution report 或 outcome report，包含：

- 分析范围和数据截止时间；
- traceability map；
- observed outcomes；
- evidence quality 和缺口；
- correlation/attribution explanation；
- residual uncertainty；
- 后续行动或 Knowledge candidate。

Analytics report 不是 `summary.md`，不能回填或替换交付 Summary，也不能改变 archived delivery 的历史判断。

## 8. Knowledge 反馈

Analytics 可以提出 candidate，例如：

- 重复失败模式；
- 经多次交付验证的工程约束；
- 预期与 Outcome 持续偏差；
- 需要记录的外部合同或事故经验。

但进入 governed Context 仍必须经过：

1. 读取当前 Context 和相关代码/配置；
2. 来源、重复、冲突和 freshness 核验；
3. human decision；
4. actual apply；
5. reread verification。

Analytics score 或模型信心不能自动 promotion。

## 9. Privacy、security 与保留

- 明确允许采集的 project、deployment 和 outcome source；默认不抓取未批准外部系统。
- 最小化 actor、customer、environment 和 telemetry 中的个人/敏感数据。
- source credential 不进入 Workspace artifacts 或 analytics output。
- 对 raw evidence、派生 metrics 和 Human projection 分别定义 retention/redaction。
- 删除或访问限制不能通过篡改 digest/history 掩盖；应留下允许的 tombstone/status。
- 跨项目 aggregation 必须显式 opt-in，并防止项目事实泄漏。

## 10. 执行设计

### 10.1 Ingestion

- 只从明确 connector/adapter 或 Workspace artifacts 读取。
- 验证 source identity、schema、time、revision 和 digest。
- 保留 immutable raw observation ref，派生层可重建。
- ingestion failure 不影响已完成 delivery。

### 10.2 Linking

- 优先使用显式 stable IDs 和 refs。
- 可提出 heuristic candidate link，但必须标记 `proposed`，不能自动成为 authoritative edge。
- ambiguous/multiple matches 保持 unresolved。
- artifact stale 或 superseded 时保留历史边并标记 currentness。

### 10.3 Computation

- 可确定指标由 governed executor 计算，算法、窗口、过滤和分母可审计。
- 语义解释、confounder 分析和建议由 Prompt/Agent 完成，并引用 machine result。
- 相同 inputs 和 definitions 产生相同 deterministic metrics。

### 10.4 Scheduling

Outcome observation 可按一次性或周期性窗口运行，但调度是可选 adapter：

- 未配置 scheduler 时支持手动运行；
- task missed/delayed 时记录实际采集时间；
- 不因 scheduler 不可用阻塞 Summary 或核心完成；
- late-arriving data 可生成新 analytics run，不改写旧 run。

## 11. 明确非目标

- 不执行或替代 Verification。
- 不记录或替代 Human Acceptance。
- 不生成交付 `summary.md`。
- 不成为核心 lifecycle completion 的 Gate。
- 不以 Outcome 反向修改历史 verdict、Acceptance 或 accepted scope。
- 不自动证明因果关系。
- 不自动 promotion Knowledge。
- 不要求 Plan 80 多 Agent 能力。
- 不建立第二套 Context、evidence 或 Outcome 权威库。
- 不引入功能版本目录。

## 12. 拟议文件类别

实施时根据 current runtime 和正式设计确认具体路径：

- Attribution/Outcome protocols、schemas 和 policies；
- Workspace `outcomes/` 与必要的 attribution/analytics run records；
- deterministic link validation、metric computation 和 projection operations；
- connector/adapters：Git、deployment、CI/incident/telemetry，仅按批准 source 增加；
- Attribution Prompt/rules：语义解释、confounders、candidate extraction；
- contract fixtures 与 runtime tests；
- privacy/redaction/retention 配置。

不得让 analytics 文件成为原始 Spec、Verification、Acceptance 或 Context 的替代来源。

## 13. 任务拆分

### T90-01 Use cases 与数据治理

- 确认需要回答的问题、允许 sources、metrics、retention 和 privacy。
- 将不可获得的数据明确标为 out-of-scope/unavailable。

### T90-02 Attribution/Outcome contracts

- 定义 nodes、edges、Outcome observation、analytics run 和 status。
- 增加 strict valid/invalid/stale/unlinked fixtures。

### T90-03 Ingestion 与 linking

- 实现 approved adapters 和 Workspace ingestion。
- 优先 explicit refs，保留 proposed/unresolved link 状态。

### T90-04 Deterministic metrics

- 实现 traceability、flow、quality 和 outcome delta 的可重放计算。
- 固定 definitions、window、denominator 和 data-quality handling。

### T90-05 Semantic analysis 与 projection

- 实现 Attribution Prompt，区分事实、correlation、hypothesis 和 causal claim。
- 生成独立 post-delivery report，不修改 Summary。

### T90-06 Knowledge candidate handoff

- 将经来源绑定的观察提交 Knowledge Governance。
- 验证没有自动 Context write。

### T90-07 Optional scheduling

- 如有实际 scheduler adapter，增加 observation windows、late data 和 retry。
- 验证 scheduler unavailable 不阻塞核心流程。

### T90-08 End-to-end validation

- 用完整、部分、冲突、无数据和 late data 场景验证。
- 对照原始 records 复算 metrics，审查隐私与因果措辞。

## 14. 验证矩阵

| 场景 | 必需结果 |
|---|---|
| 未配置 analytics | 核心 delivery 与 Summary 正常完成 |
| Verification `fail`/`inconclusive` | 原 verdict 保持，不能由 Outcome 覆盖 |
| Acceptance `rejected` | 不存在 accepted delivery；analytics 不改成 accepted |
| 已 `pass` + durable `accepted` | Summary 可先生成，无需等待 Plan 90 |
| 缺少 explicit links | 标记 unlinked/proposed，不由模型补事实 |
| stale artifact binding | 保留历史并报告 stale，不归到 current delivery |
| Outcome 尚未到窗口 | `not_due`，不判断成败 |
| source/metric 数据不足 | `insufficient_data`，不推断结果 |
| 有相关性无实验设计 | 只允许 correlation/association 措辞 |
| raw input 相同 | deterministic metrics 与 digest 相同 |
| late-arriving data | 新 run/observation，不改写旧报告 |
| Knowledge candidate | 无 human approval + apply + reread 时不 promotion |
| scheduler/connector unavailable | analytics 失败或 pending，不影响核心完成 |
| sensitive data | redaction/retention 和 access checks 生效 |

还需执行 contract/runtime tests、fixture replay、source-to-report traceability audit、privacy review 和 `git diff --check`。

## 15. 完成与接受条件

- Attribution graph 和 Outcome records 能追溯到 durable source refs。
- Verification verdict、Human Acceptance decision、Outcome observation 和 Attribution analysis 在 schema、runtime、Prompt 与 projection 中保持不同概念。
- Analytics 明确运行在 delivery 后，且不是 Verification、Acceptance、Summary 或核心完成的前置条件。
- deterministic metrics 可复算；缺失/stale/conflict 数据不会产生成功结论。
- 语义报告明确区分事实、相关性、假设和因果声明。
- Analytics report 不替换或修改 Summary 和历史记录。
- Knowledge 反馈仍经过完整治理事务。
- 可选 connector/scheduler 不可用时核心流程不受影响。
- privacy、security、retention 和 cross-project isolation 已验证。
- 用户审阅实际 evidence 并单独接受 Plan 90。
