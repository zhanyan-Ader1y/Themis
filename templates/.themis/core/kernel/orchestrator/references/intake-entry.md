# Intake 入口控制

> 本文件属于 [Themis Global Control Rule](../rules.md) 的按 gate 加载 reference。它只解释 Source Event、Intake attachment、Current Request confirmation 与 assignment materialization 的通用顺序；合法 status、control action、failure class 与 route 由唯一 [自然语言 Policy](../../../policies/README.md) 决定。

## 加载条件

出现任一情况时加载本文件：

- 收到新的外部用户消息；
- 当前 durable gate 等待 request confirmation、restart 或 unblock Source Event；
- `themis-current-request-dialogue` proposed result 等待验证与物化；
- assignment target materialization 未完成，需要从已记录观察恢复；
- lifecycle completion 后需要执行 Intake retention 后置控制时，同时加载 Review 与完成 reference。

## Source Event 与 attachment

每条外部消息必须先请求记录 exact original bytes、immutable Source Event identity、actor/transport metadata 与 exact fragment references，再进行任何 lifecycle 语义处理。Agent summary、normalized text、chat adjacency 或文件存在不能替代 Source Event authority。

Attachment 只能来自 durable control facts：

1. 匹配的 active Intake confirmation continuation；
2. 匹配的 active terminated-Intake restart/unblock continuation；
3. 否则创建新的 Intake identity。

`dormant-read-only` Intake 永远不可 attachment、恢复、重激活或调度 Invocation。仅有 open Intake、措辞相似、相邻消息或 Agent 推断都不能建立 attachment。

完成 Source Event 与 attachment 判断后，控制权返回 `request-intake` scope 的 exact durable continuation；在 assignment decision 完整物化前不得读取 lifecycle continuation。

## Current Request 确认

Current Request Dialogue 只返回 proposal。Claims 或 assignment 发生变化时，通用顺序为：

```text
Source Event
→ Current Request Dialogue proposal
→ 物化 immutable Intake proposal
→ human request confirmation continuation
→ 新 confirmation Source Event
→ Current Request Dialogue confirmed proposal
→ 唯一 Policy rule
→ assignment materialization
```

Intake proposal 必须绑定 stable diff item identities、触发原 lifecycle dialogue 的 Source Event identity 与 exact fragments、原 durable lifecycle continuation、允许的 item dispositions、complete diff digest、proposed claim revisions、target operations 和 confirmation continuation。Whole-diff confirmation 必须绑定 complete diff digest；silence、omitted item、ambiguous approval 或 stale proposal 均不能确认。

Confirmation Source Event 只证明 governance diff 的 confirmation disposition，不自动替代 proposal 中保存的原 lifecycle-bearing Source Event。Assignment 与 Current Request materialization 完成后，控制面必须把原 Source Event 及其 exact fragments 交回原 durable lifecycle continuation；confirmation Source Event 继续只作为确认决定的 source authority。若 confirmation 消息另含独立 lifecycle 内容，也必须通过其自身 Intake/assignment control 显式绑定，不能隐式覆盖原消息。

Claims 与 assignment 未变化时，只有 Policy 允许的 `no-change` 控制结果可以在 Intake decision 完整物化后，把原消息 Source Event 交回原 lifecycle dialogue continuation；不得跳过 Intake decision，也不得用 decision/confirmation prose 替换原消息。

## Assignment 物化

只有 fully validated、persisted、observed 且 reread 的 immutable assignment decision 才能授权 lifecycle target。每个 target 只能执行 decision 中已确认的 operation，并绑定各自 target identity 与 decision-bound continuation。

多 target 必须逐项执行、观察和记录。部分成功时：

- 保留已完成 target；
- Intake 保持 `open + incomplete`；
- 记录 `remaining_target_identities`；
- 不回滚或重放已完成 target；
- 恢复时只执行 `resume-remaining-target-operations-only`。

全部 target 完成后，按 Policy 记录 Intake `assigned`，再分别把控制权交给每个 decision-bound continuation。不得由 Global Rule、Capability prose 或 `recommended_route` 自行选择 lifecycle。

`rejected` 必须绑定 explicit rejection Source Event。`abandoned` 只能来自 explicit host-observed termination/leave event 和 Policy 后置控制，不能由 silence 或 Capability status 推断。

## 返回与停止

- 等待用户 confirmation 时返回已持久化的 Intake-local human continuation。
- Assignment 完成后，把 proposal 绑定的原 lifecycle-bearing Source Event 与 exact fragments 交给 decision 中已绑定的原 lifecycle continuation；confirmation Source Event 不替代它。
- 部分 target 完成后返回同一 Intake 的 remaining-target recovery continuation。
- 任一 Source Event、attachment、proposal、decision、target observation、Policy binding 或 materialization 不能唯一证明时，停在 last proven gate。
- Invocation 前 Policy package/reference unavailable 或 ambiguous 时不创建 attempt、不消耗 failure budget；Invocation 已开始或 result 返回后的无效情况交给 failure reference 与 Policy invalid-result 处理。
