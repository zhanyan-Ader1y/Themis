# Plan 80：Multi-Agent Execution

> 状态：可选实施设计，待用户单独确认。Plan 80 不阻塞 Plans 35–37，也不阻塞核心生命周期、Verification、Human Acceptance、Summary 或交付完成。

## 1. 目标

定义 Themis 在具备合适宿主能力时的多 Agent 执行拓扑，使可并行或需隔离的语义工作拥有清晰的 orchestration、isolation、handoff、aggregation 和 evidence boundaries，同时保持现有领域所有权：

- Prompt/Agent 行为拥有语义推理和领域判断；
- governed deterministic executors 拥有状态、校验、事务、文件、命令和 evidence 骨架；
- Orchestrator 拥有生命周期路由和调度；
- 多 Agent 只是执行拓扑，不是新的事实源、状态机或授权机制。

## 2. 确认与依赖

- Plan 80 是可选增强，不是 Plan 35、36 或 37 的依赖。
- 若 Plan 37 尚未实施，Plan 80 只能设计/使用实际存在的确定性能力，不能假定 native runtime 可用。
- 若 Plan 37 已实施，Plan 80 应通过 `themis` CLI/协议调用确定性操作，不复制执行器逻辑。
- 实施前必须由用户针对 Plan 80 单独授权。
- 多 Agent 支持缺失时，核心生命周期必须可在单主会话中继续；不得降级为虚构并行或伪造 handoff。

## 3. 不变所有权

### Orchestrator

- 判断是否值得并行、选择允许的 worker 类型、分配 read/write scope、等待结果、处理冲突和决定返工路由。
- 只能基于持久工件和实际 worker result 推进，不根据“已启动”推断“已完成”。

### Domain Agent

- 只在被授权的领域和 Task 内进行语义工作。
- 不记录 lifecycle transition，不批准自己的 Review，不计算不属于其领域的 verdict。
- 引用所读 artifacts/revisions，并报告不确定性、缺失能力和偏差。

### Deterministic executor

- 验证 handoff、scope、bindings、locks、state 和 evidence references。
- 执行文件、命令、事务和持久记录。
- 不选择架构方案、不决定 Review approval、不代替 Human Acceptance。

### Human

- 保留计划实施确认、重大裁决、Review/Acceptance 中正式设计规定的人类职责，以及 Knowledge promotion 批准。

## 4. 何时使用多 Agent

只有在满足以下条件时才应拆分：

- 子任务边界可用 artifact/Task/scope 明确表达；
- 并行收益超过协调成本；
- worker 可获得完成任务所需且不过量的 Context；
- write ownership 不重叠，或能通过工作树/事务隔离；
- 结果可通过 deterministic checks 或独立 Review 聚合；
- 失败不会使核心流程丢失可恢复状态。

以下情况保持单 Agent：

- 一个小型、强耦合语义判断；
- 需要持续用户对话的 Specification 收敛；
- 无法安全划分 write scope；
- 缺少 worker/隔离/聚合能力；
- 调度本身会成为 Verification 或 Delivery 的阻塞依赖。

## 5. 执行拓扑

### 5.1 主会话

主会话负责：

- 读取 current lifecycle artifacts 和项目事实；
- 创建 execution graph；
- 为每个 worker 生成完整、自包含、最小必要 handoff；
- 维护 worker identity、status 和 expected outputs；
- 聚合实际结果并触发领域 owner 的最终语义判断；
- 把任何写入交给已批准 Task 和 governed executor。

主会话不得把“综合理解”全部委托给 worker 后直接转述；它必须核验 sources、bindings、diff/evidence 和冲突。

### 5.2 Worker 类型

可按能力存在性定义 worker，而不是预设一定安装：

- Context investigator：只读查找双事实根、Signal 和 source refs；
- Specification analyst：分析 intent/risks/AC，但不拥有最终确认和 publish；
- Planning worker：提出 Task/traceability 分片；
- Review worker：独立只读检查某一风险面；
- Implementation worker：只执行一个 reviewed、依赖就绪 Task；
- Verification worker：执行被分配的 Gate 或分析实际 evidence，不修改实现；
- Knowledge analyst：提取/核验 candidate，不批准或直接 promotion；
- Aggregator：只做结构化合并和冲突呈现，不覆盖 owner decision。

专用 Agent 文件只有在宿主支持且该能力确实需要时创建；文件不存在时必须使用主会话 fallback。

## 6. Isolation

### 6.1 Read isolation

- 每个 worker 得到显式 artifact refs、source revision、Context bundle 和 allowed paths。
- 不默认加载整个对话或全仓历史。
- worker 报告所有额外读取来源，避免不可审计的隐式 Context。

### 6.2 Write isolation

Implementation worker 必须满足至少一种安全模型：

- 独立 worktree/branch，绑定 reviewed Task；
- governed transaction/staging area，限定 allowed paths；
- 串行唯一 writer，加 scope precondition checks。

同一路径不得由多个 worker 并行写。Scope 变化必须返回 Planning/Review，不能由 aggregator 自动合并授权。

### 6.3 Secret 与权限

- Handoff 只包含最小必要数据，不复制 secrets。
- worker permissions 按工具、路径和命令最小化。
- child commands 仍通过 governed executor；Agent 不因隔离环境而获得绕过 policy 的权限。

## 7. Handoff contract

每个 handoff 至少包含：

- handoff ID、worker role、domain owner；
- lifecycle state 和 operation purpose；
- Spec/Plan/Review/Task IDs、revisions 和 digests；
- Context/source refs 与 code revision；
- allowed read/write paths；
- required inputs 与 expected outputs；
- actual available tools/executors；
- prohibited actions；
- stop/escalation conditions；
- evidence requirements；
- deadline/cancellation 或 retry policy。

Worker result 至少包含：

- handoff ID 和 observed input bindings；
- status：completed/blocked/failed/cancelled 等稳定值；
- findings、decisions proposed、changed paths 或 evidence refs；
- commands actually run 和 outputs refs（如适用）；
- assumptions、limitations、deviations 和 unresolved conflicts；
- post-state revision/digest。

Handoff 是调度工件，不是 lifecycle transition 或事实根。

## 8. Aggregation

### 8.1 结构化聚合

Aggregator 必须：

- 验证每个 result 对应已知 handoff；
- 检查 input binding/currentness；
- 拒绝重复、过期、越权或缺失来源的结果；
- 按 stable ID 合并 findings、Task outputs 和 evidence refs；
- 保留冲突，不以多数票或模型置信度静默消解；
- 将需要语义裁决的内容交回领域 owner 或用户。

### 8.2 Review independence

- Implementation worker 不得作为自己 Task 的唯一 Review/Verification 结论来源。
- 前置 Review 必须发生在实现前，并绑定 current Plan；并行 reviewer 可提供 findings，但最终 Review disposition 仍由 Review owner 形成。
- Verification 只使用实际命令 evidence；worker 文本“测试通过”不是 Gate evidence。

### 8.3 Partial results

部分成功不得提升为整体成功：

- 未返回 worker → blocked/incomplete；
- stale result → discard with reason and rerun if authorized；
- conflicting result → unresolved；
- required evidence missing → Verification `inconclusive`；
- write worker failed → preserve/recover isolation, no Task completion。

## 9. Evidence boundaries

- Agent transcript、summary 和 confidence 不是独立 evidence。
- 代码事实来自 current revision；Context 事实来自 governed Context；冲突需 Signal。
- 实现 evidence 绑定 Task、changed paths 和 post revision。
- Verification evidence 绑定 exact command、attempt、outputs 和 implementation revision。
- Human Acceptance 必须独立持久记录；多 Agent 不能代替 actor decision。
- Summary 仍只允许在 Verification `pass` 且 Acceptance durable `accepted` 后生成。
- Knowledge promotion 仍要求人工批准、actual apply 和 reread verification。

## 10. 失败、取消与恢复

- Orchestrator 保存 durable execution graph 或在执行器缺失时明确说明仅有会话内状态。
- worker 启动失败、超时、取消或崩溃不得伪造 completed result。
- 重试沿用同一 handoff lineage，并验证输入仍 current。
- writer 中断时由 governed transaction/worktree recovery 处理；主会话不凭推断继续。
- 预算耗尽或必要 worker 不可用时，回退单 Agent 或稳定阻塞，不影响核心生命周期定义。

## 11. 明确非目标

- 不重新设计核心 lifecycle。
- 不使 Plan 80 成为 Plans 35–37 或 Delivery 的依赖。
- 不把语义 ownership 转给调度器、aggregator 或 deterministic executor。
- 不把确定性 ownership 转给 Agent Prompt。
- 不实现新的事实数据库或第二套 Knowledge authority。
- 不允许并行绕过 Review、scope lock、Verification、Acceptance 或 Knowledge approval。
- 不要求所有领域都必须有专用 Agent。
- 不引入功能版本目录。

## 12. 拟议文件类别

具体路径在实施时按宿主能力和 current checkout 确认：

- Orchestrator Prompt/rules：调度决策、fallback 和聚合边界。
- 可选 `.claude/agents/Themis-*` 或宿主对应 agent definitions：仅为确认需要的专用 worker。
- Core protocols/policies/templates：handoff、worker result、execution graph、scope 和 aggregation contracts。
- Workspace state/runs/evidence：仅在已有 deterministic recorder 支持时存储执行和 evidence refs。
- Runtime adapter/CLI integration：调用实际存在的 isolation、worktree、process 和 transaction 能力。
- Tests：handoff validation、conflict aggregation、stale result、writer isolation、fallback 和 failure recovery。

若宿主没有专用 Agent 或 worktree API，不创建冒充能力的文件；使用主会话路径。

## 13. 任务拆分

### T80-01 能力与用例审计

- 枚举实际宿主 Agent、worktree、permission、message 和 cancellation 能力。
- 选择有明确收益的用例，定义单 Agent fallback。

### T80-02 Execution graph 与 handoff

- 定义 graph、worker lifecycle、handoff/result schema 和 currentness。
- 建立稳定 issue/status 和 retry lineage。

### T80-03 Isolation

- 实现 read context minimization、write ownership 和安全 worktree/transaction adapter。
- 验证重叠写入被拒绝。

### T80-04 Domain workers

- 仅为已确认用例增加专用 worker Prompt/definitions。
- 对每个 worker验证 owner、禁止事项和实际工具清单。

### T80-05 Aggregation

- 实现 result validation、conflict preservation、partial failure 和 owner handback。
- 不使用多数投票覆盖语义冲突。

### T80-06 Evidence 与 lifecycle integration

- 绑定 Task、revision、Gate attempt 和 evidence refs。
- 确认 Review/Verification/Acceptance/Summary 顺序不被 topology 改变。

### T80-07 Recovery 与 fallback

- 覆盖 timeout、cancel、stale、worker unavailable、writer crash 和 budget exhaustion。
- 验证单 Agent 核心流程保持可用。

## 14. 验证矩阵

| 场景 | 必需结果 |
|---|---|
| 无多 Agent 宿主 | 单 Agent fallback，核心流程不阻塞 |
| 并行只读调查 | 来源/binding 可追踪，冲突被保留 |
| 重叠 write scope | 调度前或 executor 校验时拒绝 |
| stale handoff result | 不聚合为 current，明确 rerun/blocked |
| worker 超时/崩溃 | 不报告 completed；可取消/重试/恢复 |
| Implementation worker 越界 | 写入拒绝或 Task 失败，不自动扩 scope |
| reviewer 分歧 | 交 Review owner/用户裁决，不多数票 |
| worker 声称测试通过但无 evidence | Verification 不得 `pass` |
| partial Gate results | blocking evidence 不足则 `inconclusive`/fail |
| Acceptance 未持久化 | 无 Summary，即使所有 workers 声称完成 |
| Knowledge worker 建议 promotion | 无人工批准和 apply+reread 时不更新 Context |

还应运行相关 contract/runtime tests、宿主集成测试、并发/取消测试和 `git diff --check`。

## 15. 完成与接受条件

- 多 Agent topology 是可选能力，单 Agent 核心生命周期保持完整。
- Orchestration、isolation、handoff、aggregation 和 evidence boundaries 均有严格实现和测试。
- 每个 worker 的领域 owner、read/write scope、输入 binding 和禁止事项可审计。
- 冲突、部分失败、stale result 和 worker unavailable 不会被包装为成功。
- Review、Implementation、Verification、Acceptance、Summary 和 Knowledge Gate 未被并行化绕过。
- Agent 未吸收确定性执行器职责，执行器未吸收语义判断。
- 没有功能版本目录或虚构宿主能力。
- 用户审阅实际验证 evidence 并单独接受 Plan 80。
