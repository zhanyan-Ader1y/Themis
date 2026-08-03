# Themis Global 控制 Rule

## 唯一常驻职责

本文件是唯一 always-loaded Themis 控制说明。它协调 `request-intake` 与 `lifecycle` 两个隔离 authority scope，每次只建立一个 temporary Capability Invocation，并解释唯一 [自然语言 Policy](../../policies/README.md)。

本 Rule 不拥有 Capability 推理、legal status、route、artifact 字段、用户 claims、实现事实或 recorder 行为，也不复制阶段控制规则。只有 `.claude/skills/themis/SKILL.md` 是公共治理入口；十六个 Capability contract 均为内部合同。

## Intake-first 边界

每条外部用户消息必须先成为 immutable Source Event，并经过 Request Intake interception。只有 fully materialized and reread assignment decision 才能创建、定位、继续、拆分、合并或更新 lifecycle；不存在 provisional lifecycle。

Source Event attachment 只能来自 active durable Intake confirmation/restart continuation。`dormant-read-only` Intake 永远不可 attachment、Invocation、mutation、reactivation 或 recovery；未来消息创建新 Intake。

具体 Source Event、confirmation、multi-target assignment 和 completion retention 顺序按当前 gate 加载 [Intake 入口控制](references/intake-entry.md)。

## Authority scope 隔离

`request-intake` 拥有 Source Event references、claim/assignment proposal、confirmation decision、Intake Execution Identity、Intake-local continuation、pointer、disposition 与 retention facts。

`lifecycle` 拥有 Current Request revisions、Questioning、path/Plan、Review/Approval、Plan Task Execution、Verification、Acceptance、Summary、lifecycle-local continuation 与 pointers。

两个 scope 只可互引 stable immutable references，不得共享 dynamic state、Execution Identity、failure budget、continuation authority、current pointer 或 completion state。Intake failure 不创建或消耗 lifecycle budget。

## 唯一 ownership

- Source Event：exact original external bytes 与 fragment references。
- Current Request：user-confirmed、source-bound lifecycle target claims。
- Capability：一个 semantic judgment 与 proposed result。
- Agent Profile：tool、permission 与 isolation boundary。
- Invocation：一个 scope、一个 Capability 的临时载体。
- [Policy](../../policies/README.md)：唯一 legal control rule、guard、invalidation 与 failure class owner。
- Global Rule：通用 preflight、Invocation、规则解释、control coordination 与 recovery。
- Workspace：observed durable records、artifacts、evidence 与 separate current pointers。

Code、configuration、Schema 与 observed executable behavior 是 current implementation facts 的唯一来源。Design、Plan、Review Projection、Summary、Themico、经验、外部参考、Agent prose 与 conversation memory 不能伪装成用户语义或实现事实。

## 按 durable gate 加载

每次控制只加载最小必要集合：

1. 本 `rules.md`；
2. `../../policies/README.md`；
3. 当前 gate 对应的一个或多个 orchestrator references；
4. 当前决定所需的 Policy shared-topic reference；
5. 当前 Capability 对应的唯一 Policy phase route reference；
6. 一个 Capability contract 与其 fixed Agent Profile；
7. 当前 gate 所需的最小 durable records/evidence。

| 当前 gate | Orchestrator reference |
|---|---|
| 外部消息、confirmation、assignment、retention | [Intake 入口控制](references/intake-entry.md) |
| Preflight、Invocation、result、materialization | [Invocation 与物化控制](references/invocation-and-materialization.md) |
| Questioning、Grounding、Assessment、Plan、Plan Check | [Lifecycle continuation 控制](references/lifecycle-continuation.md) |
| Review、Approval、Verify、Acceptance、Summary、completion | [Review 与完成控制](references/review-and-completion.md) |
| Sticky escalation、invalidation、failure、recovery | [Failure、失效与恢复控制](references/failure-invalidation-recovery.md) |
| Runtime guarantee unavailable | [安全降级控制](references/safe-degradation.md) |

同一 gate 可加载多个通用 reference，但只能加载一个与当前 Capability 对应的 Policy phase route reference。References 只解释通用控制顺序，不形成第二份 Policy。

## Invocation 与唯一规则

Invocation 前必须重读 scope state、Policy binding、Execution Identity、current pointers、markers、artifact components、attempt records、current bindings 与 exact continuation，并确定 last proven gate。

每次 Invocation 只绑定一个 authority scope、一个 scope-local Execution Identity、一个 Capability、一个 fixed Profile、一个新 Invocation/attempt identity、current Policy、selected path/profile、允许权限、materialization target 与 exact continuation。Nested Capability/Agent call 被禁止。

Capability result 永远只是 proposal。Global Rule 必须在 current Policy 中按以下 identity 匹配且只匹配一条自然语言控制规则：

```text
capability + selected_path + profile + status
```

`authority_scope` 不是第五维度。`recommended_route`、chat、summary、diagnostics、file existence 或相近 prose 不能选择或覆盖规则。

## Complete materialization 不可绕过

只有 proposed result 验证通过、exactly-one Policy rule 匹配、声明的 control action 执行、全部 components 持久化、complete/incomplete observation 被记录、identity/content/digest/bindings 被重读、immutable revision 被观察且 separate current pointer 更新并重读后，authority 才可能成立。Review Feedback owner re-entry 还必须绑定 exact Feedback revision 与 owner continuation；owner result 完整物化和重读后，控制层先另行记录并重读 resolution observation，再记录并重读引用它的 unresolved-set update observation，只有后一步完成后新 state view 才可移除该 revision。

任一 paired `record.md + content.md` component 缺失或 binding 不一致会使整个 revision 无效。Pointer update 失败时 revision 不 current。Successful write、Markdown draft、Agent statement 或文件存在都不等于 materialization。

## 不可绕过门禁

- Questioning 必须消费 confirmed Current Request；unknown 不默认为 simple。
- Simple/full 只在 Plan 前分叉，形成同一 Plan family并在 Review 前汇合。
- Review 与 current explicit Approval 必须先于 Impl。
- Verify 固定为 `themis-impl → independent themis-verification`。
- Acceptance 要求 current Verification `passed`；Summary 还要求 current Acceptance `accepted`。
- `full_path_required` lifecycle-local、sticky、单向，不能清零 failure budget。
- 每个 scope-local Execution Identity 最多三次 counted failure，第三次终止并禁止第四次 Invocation。
- Failure Learning scope-bound、non-blocking、non-recursive、candidate-only。

## 停止与安全降级

Invocation 前 required Policy package/reference unavailable、ambiguous 或无法与 observed binding 对齐时，停在 last proven gate，不创建 attempt、不消耗 failure budget。Invocation 已开始或 result 返回后的 invalid-result 按 Policy 进入 scope-local failure control。

当前缺少 strict validator、digest algorithm、evaluator、state recorder、Invocation host 与 deterministic write runtime。缺少动作所需支持时必须停止、报告具体 unavailable assurance，并保留 durable continuation；不得手写 machine-owned state、伪造执行证据或模拟成功。
