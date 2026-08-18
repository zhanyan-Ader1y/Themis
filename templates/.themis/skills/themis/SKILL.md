---
name: themis
description: 唯一公共 `themis` 治理入口；接收任意新消息或续接消息，先执行 Source Event 与 Request Intake，再按 Global Rule、自然语言 Policy、内部 Capability 和 fixed Agent Profile 启动、继续或恢复治理流程。
---

# themis

## 公共治理入口职责

本 Skill 是唯一公共 `themis` 治理入口。每条外部用户消息必须先成为 immutable Source Event 并进入 Request Intake，不能先定位、创建或继续 lifecycle。

它只负责：

- 请求记录 exact original external bytes、Source Event identity、metadata 与 fragment references；
- 从 durable Intake confirmation/restart continuation 选择 attachment，否则建立新 Intake；
- 加载唯一 Global Rule、current natural-language Policy 和当前 gate 对应的 references；
- 加载一个 internal Capability contract 与其 fixed Agent Profile；
- 运输 Source Event、Capability proposed result 与 durable continuation；
- 请求从 durable facts 和 last proven gate 恢复。

本入口不拥有 claims、assignment、Questioning、Grounding、Assessment、Plan、Review、Impl、Verification、Acceptance、Failure Learning 或 Summary 的语义判断，也不拥有 route、currentness、Approval、failure count、invalidation、materialization 或 completion。

## 加载流程

```text
rules.md
→ policies/README.md
→ 当前 gate 对应的 orchestrator reference
→ 当前决定所需的 Policy shared-topic reference
→ 当前 Capability/Profile 对应的唯一 Policy phase route reference
→ one Capability contract + fixed Agent Profile
→ one temporary Invocation
```

稳定入口位置：

- `.themis/core/kernel/orchestrator/rules.md`
- `.themis/core/policies/README.md`
- `.themis/core/kernel/orchestrator/references/*.md`
- `.themis/core/policies/references/*.md`
- `.themis/core/capabilities/<selected>.md`
- `.themis/core/agent-profiles/<fixed>.md`

一次 Invocation 只加载一个 Capability 与一个 fixed Profile；Capability/Agent 不得嵌套调用。Policy route identity 为 `capability + selected_path + profile + status`，`authority_scope` 由 Capability/Policy binding 决定，不是第五维度。

## Intake-first 边界

```text
external user message
→ immutable Source Event
→ request-intake
→ themis-current-request-dialogue
→ Policy-controlled confirmation/assignment
→ fully materialized assignment decision
→ decision-bound lifecycle continuation
```

只有 fully materialized and reread assignment decision 才能创建、更新、拆分、合并或继续 lifecycle。Claims/assignment 改变时必须保存 proposal、触发原 lifecycle dialogue 的 Source Event binding 与原 durable continuation，并等待新的 confirmation Source Event；confirmation 只确认 governance diff，不替代原 lifecycle-bearing Source Event。`no-change` 也必须先物化 Intake decision。

`dormant-read-only` Intake 不可 attachment、Invocation、mutation、reactivation 或 recovery。未来消息创建新 Intake；历史记录只用于 source/decision verification。

## 启动、继续与恢复

1. 读取 `rules.md` 与 `policies/README.md`，确认当前 scope、Policy binding、durable gate、Execution Identity、pointers 与 exact continuation。
2. 对当前消息请求 Source Event recording，并完成 Intake attachment/interception。
3. 按 durable gate 加载最小 orchestrator reference 和 Policy shared-topic reference。
4. 只加载 current Capability 对应的一个 Policy phase route reference、一个 Capability contract 与 fixed Profile。
5. 将控制权交给 Global Rule 建立 one temporary Invocation。
6. Proposed result 只交给 Global Rule 按 current Policy 验证、唯一匹配与请求 control action。
7. Assignment materialized 后才读取 lifecycle state 和 decision-bound continuation。
8. 中断后只从 reread durable facts 得出的 last proven gate 恢复；不从 chat、summary、Agent report、temporary Specification 或 file existence 恢复。
9. Lifecycle completion observed 后只请求 Policy 声明的 Intake retention 后置控制。

`recommended_route`、Agent prose、chat history、summary 和 file existence 不能推进 gate。Capability result、successful write 或 Markdown draft 不能替代 complete materialization。

## Review 与交付门禁

Review 必须在 Impl 前完成并形成 current explicit Approval。Verify 固定包含：

```text
themis-impl
→ independent themis-verification
```

Impl 与 Verification 使用 separate Invocations，但共享 current Approval、Plan task、baseline、expected delta、Plan Task Execution Identity 与 failure budget。Acceptance 要求 current Verification `passed`；Summary 还要求 Human Acceptance `accepted`。

Implementation mutation 只允许 `themis-impl` 的 `implementation-writer` 在 current Approval、Plan task、baseline 与 allowed paths 范围内执行。Writer 不能验证自身。

## 安全降级

当前 Plan 35 不含 strict validator、canonical digest、Policy evaluator、state recorder、Invocation host 或 deterministic write runtime。缺少当前动作所需支持时：

- 停在 last proven gate；
- 指明 unavailable assurance；
- 保留 durable continuation；
- 不创建伪 attempt；
- 不手写 machine-owned state；
- 不声称 transition、persistence、digest、currentness、invalidation、termination、recovery 或 completion 已由机器执行。

Invocation 前 required Policy package/reference unavailable 或 ambiguous 时不消耗 failure budget。Invocation 已开始或 result 返回后的 invalid-result 由 Policy 进入 scope-local failure control。
