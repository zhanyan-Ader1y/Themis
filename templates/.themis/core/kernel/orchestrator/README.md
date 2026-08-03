# Orchestrator 包

## 职责

Orchestrator 保存唯一 always-loaded [Global Control Rule](rules.md) 与六个按 durable gate 加载的通用控制 references。它解释唯一 [自然语言 Policy](../../policies/README.md)，协调一次一个 temporary Capability Invocation，验证 proposal、请求 Policy control action、消费 observed materialization，并从 durable facts 恢复。

它不拥有 Capability 推理、legal status、route、用户 claims、实现事实、artifact content 或 recorder 行为，也不建立第二份 Policy。

## 文件角色

- [rules.md](rules.md)：常驻最小入口，拥有 Intake-first、scope isolation、ownership、reference loading、唯一规则匹配、materialization 门禁与 fail-closed 边界。
- [references/intake-entry.md](references/intake-entry.md)：Source Event、attachment、Current Request confirmation、assignment 与 retention。
- [references/invocation-and-materialization.md](references/invocation-and-materialization.md)：preflight、temporary Invocation、proposed result、Policy rule 与 complete materialization。
- [references/lifecycle-continuation.md](references/lifecycle-continuation.md)：Questioning、Grounding、Assessment、simple/full、Plan 与 Plan Check。
- [references/review-and-completion.md](references/review-and-completion.md)：Review、Approval、Verify、Acceptance、Summary、completion 与 Intake dormancy。
- [references/failure-invalidation-recovery.md](references/failure-invalidation-recovery.md)：sticky escalation、currentness、invalidation、failure budget、Failure Learning 与 recovery。
- [references/safe-degradation.md](references/safe-degradation.md)：unavailable runtime guarantee 与禁止模拟执行。

六个 references 只解释通用控制顺序；Capability 的 legal scope/Profile/status、具体 control action、guard、invalidation 与 failure class 由 Policy entry 及其 references 唯一拥有。

## 加载顺序

```text
public themis governance entry
→ rules.md
→ policies/README.md
→ current gate 对应的 orchestrator reference
→ current decision 所需的 Policy shared-topic reference
→ current Capability 对应的唯一 Policy phase route reference
→ one Capability contract + fixed Agent Profile
→ one temporary Invocation
```

同一 durable gate 可需要多个 orchestrator references，例如 Acceptance 用户消息同时需要 Intake interception 与 Review/完成控制；但一次 Invocation 仍只允许一个 Capability、一个 Agent 与一个 Policy phase route reference。

## 权威边界

- Source Event 拥有 exact external bytes。
- User-confirmed Current Request 拥有 lifecycle target semantics。
- Code/configuration/Schema/observed behavior 拥有 current implementation facts。
- Capability 只拥有一个 semantic proposal。
- Agent Profile 拥有 tools、permissions 与 isolation。
- Policy 拥有 route legality 与 control semantics。
- Observed recorder result 加完整重读才能证明 materialization。
- Workspace 保存 durable scope records、immutable revisions、evidence 与 separate current pointers。

`request-intake` 与 `lifecycle` 只可互引 stable immutable references，不得共享 dynamic state、Execution Identity、failure budget、continuation authority、current pointer 或 completion state。

## 关键不变量

- Every external message is Source Event and Intake first。
- Confirmed assignment precedes lifecycle creation/update。
- Simple/full paths create one Plan family and converge before Review。
- Plan Check precedes Review；current explicit Approval precedes Impl。
- Verify 是 `Impl → independent Verification`，使用 separate Invocations 与 shared Plan task budget。
- Acceptance requires current Verification `passed`；Summary also requires Acceptance `accepted`。
- `full_path_required` lifecycle-local、sticky、one-way。
- Third counted failure terminates the scope-local Execution Identity and forbids a fourth Invocation。
- Failure Learning scope-bound、non-blocking、non-recursive、candidate-only。
- `dormant-read-only` Intake 不可 attachment、Invocation、mutation、reactivation 或 recovery。

## Materialization 与 recovery

Capability result、Markdown draft、successful write、Agent report 与 file existence 都不是 authority。Authority 要求 proposed result validation、exactly-one Policy rule、declared control action、complete persistence、observation、reread、immutable revision observation 与 separate pointer update。

Recovery 重读 scope state、pointers、markers、artifact components、attempts 与 applicable Git facts，只从 last proven gate 的 exact continuation 恢复。不得从 chat、summary、temporary Specification 或 inferred completion 恢复，也不得自动 repair、rollback、merge 或 replay completed target。

## 当前状态

Plan 35 只提供 Prompt-level Rule、自然语言 Policy、Capability、template、Workspace、人工 parity review 与 replay 合同。Strict contracts/validation 仍属未实施的 Plan 36；evaluator、Invocation host、recorder、deterministic writes 与 command execution 仍属未实施的 Plan 37。

当前没有已批准并已实现的 Themis Go CLI 文档合同检查命令。自动检查记为 `unavailable`；不得以 Python、Shell、临时 parser 或虚构命令替代，也不得声称不存在的 runtime guarantee 已实现。
