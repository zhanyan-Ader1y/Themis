# Plan 80：Multi-Agent Execution

> 状态：可选实施设计，待用户单独确认。Plan 80 不阻塞 Plans 35–37，也不阻塞 Verification、Human Acceptance、Summary 或 lifecycle completion。

## 1. 目标

在宿主确实支持多 Agent 与 worktree 时，为可并行或需独立检查的工作提供 optional execution topology，同时保持 Plan 35 的所有权：

- Capability 拥有语义判断；
- Agent Profile 拥有权限与隔离合同；
- `transitions.yaml` 拥有合法 route；
- Global Rule 拥有通用协调；
- Plan 37 runtime 只提供 policy evaluation、temporary invocation、per-lifecycle recording 与 minimal write safety；
- Workspace 保存 lifecycle-scoped actual records。

多 Agent 不是新的事实源、状态机、授权机制或核心门禁。

## 2. 前提与降级

- 实施前必须由用户单独授权 Plan 80。
- 必须先盘点实际宿主的 Agent、worktree、permission、message、cancellation 与 result 能力。
- 缺少任一必要能力时，使用单 Agent/单 invocation 核心路径或稳定 blocked；不得伪造并行、隔离、handoff 或完成。
- Plan 80 不要求 persistent Agent、shared Agent memory、Agent-to-Agent delegation、voting 或 consensus。
- Plan 80 不引入跨 worktree locks、通用 transactions、rollback journals、automatic recovery、cross-worktree merge 或 conflict adjudication。

## 3. 适用场景

只有同时满足以下条件才拆分：

- 子任务可以用 lifecycle、Plan Task、Capability、scope 和 expected output 明确表达；
- 并行收益高于协调成本；
- 每个 worker 能获得最小且充分的 Context；
- read/write ownership 不重叠；
- mutating worker 可获得独占 worktree；
- 结果可被 strict contract、直接 evidence 或独立 checker 验证；
- partial/failed result 不会被包装为整体成功。

Questioning、Review Dialogue、Acceptance Dialogue、小型强耦合语义判断、无法划分写入权的任务保持单 Agent。

## 4. 拓扑

```text
Global Rule / host coordinator
→ selects independent work items
→ creates lifecycle-bound handoffs
→ one Capability + fixed Profile per temporary worker invocation
→ validates each Capability Invocation Result
→ preserves conflicts and partial results
→ routes through transitions.yaml
```

Coordinator 不把综合理解、Review Approval、Verification verdict、Human Acceptance 或 conflict decision 交给多数票或 aggregator。

## 5. Handoff contract

每个 handoff 至少绑定：

- handoff、lifecycle、Task Execution、Invocation identity；
- selected Capability and fixed Agent Profile；
- Current Request、Questioning、Plan、Approval and policy bindings；
- selected path/profile and continuation；
- source/Git baseline；
- allowed read/write paths and explicit commands；
- worktree identity for mutating work；
- required inputs, expected outputs and evidence destination；
- attempt/failure budget；
- prohibited actions and stop conditions。

Worker result 使用 Capability Invocation Result envelope，并额外记录 observed bindings、changed paths/commands/evidence、limitations、deviation 与 post-state observations。

Handoff 与 worker result 都不是 lifecycle transition；只有合法 route 和实际 recorder operation 才能推进状态。

## 6. Read and write isolation

### Read-only workers

- 获得显式 source refs 与 allowed paths；
- 不默认加载完整聊天、全部历史或其他 worker temporary context；
- 报告额外读取来源；
- checker 不继承 producer 临时推理。

### Mutating workers

- 只使用 `implementation-writer`；
- 一个 mutating lifecycle/task invocation 独占一个 worktree；
- 不同并行 writer 的 allowed paths 不得重叠；
- 写前验证 lifecycle/task/invocation/worktree、baseline、scope 和 expected state；
- 适用时使用完整临时写、atomic single-file replacement、completion/incomplete marker 和 reread verification；
- 不支持 worktree 时，退回串行唯一 writer 或 fail closed。

Plan 80 不自动合并 worktrees。最终整合由显式的人类/宿主流程完成，冲突必须被呈现而不是自动裁决。

## 7. Aggregation

Aggregator 只执行结构化合并：

- verify known handoff and current bindings；
- reject duplicate、stale、wrong-profile、out-of-scope or missing-source results；
- merge findings/evidence by stable identity；
- preserve disagreement and overlapping-scope conflict；
- report incomplete required work；
- return semantic conflict to owning Capability or user。

Aggregator 不生成新的 semantic status，不以多数票覆盖 owner decision，不修改 Plan/Approval，也不把 worker prose 当 evidence。

## 8. Evidence and gates

- implementation evidence binds Plan Task、worktree、baseline、changed paths and post-state；
- Verification evidence binds exact command/observation、attempt、outputs and implementation revision；
- Implementation worker 不能验证自身；Verification 固定使用 independent checker context；
- missing required worker/evidence remains incomplete or blocked and cannot become `passed`；
- Human Acceptance remains an explicit user decision；
- Summary still requires current `passed + accepted`；
- Knowledge promotion still requires approved content, actual apply and reread verification。

## 9. Failure and interruption

- failed/timeout/cancelled worker never reports completed；
- retry preserves handoff lineage and failure count and requires current bindings；
- mutating interruption rereads worktree files, Git status/diff, lifecycle records and completion/incomplete markers；
- coordinator continues only from the last proven gate or stops fail closed；
- no automatic rollback、repair、merge or conflict adjudication；
- budget exhaustion or worker unavailability falls back to single invocation or stable blocked without redefining the lifecycle。

## 10. 任务拆分

1. 审计实际宿主 Agent/worktree/permission/cancellation 能力。
2. 选择有收益且 scope 可隔离的 use cases，定义单 Agent fallback。
3. 定义 strict handoff/result/currentness contracts and fixtures。
4. 实现 read minimization and fixed-Profile worker invocation。
5. 实现 exclusive-worktree write ownership and overlap rejection。
6. 实现 result validation、conflict preservation and partial aggregation。
7. 绑定 Plan 35 lifecycle/evidence/failure gates。
8. 覆盖 timeout、cancel、stale、worker unavailable and interruption。
9. 执行宿主集成、并发隔离、fallback and `git diff --check`。
10. 将实际证据交给用户并获得 Plan 80 单独接受。

## 11. 验证矩阵

| 场景 | 必需结果 |
|---|---|
| 无多 Agent 宿主 | 单 invocation fallback，核心流程不阻塞 |
| 并行只读调查 | source/binding 可追踪，冲突保留 |
| overlapping write scope | 调度前拒绝 |
| mutating worker 无独占 worktree | 串行唯一 writer 或 fail closed |
| stale/wrong-profile result | 不聚合为 current |
| worker timeout/crash | 不报告 completed |
| writer interruption | reread markers/Git facts，只从 proven gate 继续 |
| reviewer 分歧 | 返回 owner/用户，不多数票 |
| 无 direct evidence | Verification 不得 `passed` |
| Acceptance 未持久化 | 不得 Summary |
| Knowledge candidate | 无批准、apply、reread 时不 promotion |

## 12. 完成与接受条件

- Multi-Agent topology 保持可选，单 Agent 核心生命周期完整。
- 每个 worker 绑定一个 Capability、固定 Profile、lifecycle/task/invocation 和最小 Context。
- concurrent mutating work 使用 non-overlapping exclusive worktrees。
- conflicts、partial failures、stale results and unavailable workers 不会被包装为成功。
- Review、Verification、Acceptance、Summary、failure budget and knowledge gates 未被并行绕过。
- 不存在 general locks/transactions/rollback/automatic recovery、automatic merge、voting、consensus 或 persistent shared Agent authority。
- 用户审阅实际验证 evidence 并单独接受 Plan 80。

## 13. 启动前重基线声明

本节只登记当前审计发现，不修改、补充或批准上文设计。Plan 80 保持可选且未获实施授权；在其正式规划或实施启动时，必须以届时已接受的 Plan 35–37 合同和实际 runtime 为权威，对全文进行一次完整重基线，并在获得用户单独批准后再修改正文。

当前已知、不得直接沿用的候选漂移包括：

- worker aggregation 后必须只有一个可路由一次的权威 Capability Invocation Result，或将 workers 明确定义为各自独立路由的 Task Execution；
- budget exhaustion 必须终止对应 Task Execution Identity，不能降级、换 worker 或换执行拓扑后形成第四次 invocation；
- 并行只能跨不同 Task Execution Identity，同一 identity 的 active invocation、attempt reservation 和 duplicate/stale result 处理必须确定且唯一；
- worktree 最终整合必须受 current Approval、approved Plan Task、`implementation-writer`、baseline/delta 和独立 Verification 约束，否则作为 external drift 重新验证；
- “不阻塞 Plan 36/37”不得解释为“实施时不依赖 Plan 36/37”；生产实施所需的 strict contracts、evaluator、recorder 和 write-safety 依赖应在重基线时重新确认。

这些条目不是当前 Plan 80 的已批准需求、实现任务或验收条件，也不得用于提前实现 Plan 80。后续 Plan 35–37 的规划和落地变化只需在 Plan 80 启动时统一复核，不为保持本文件实时同步而反复改写上文。
