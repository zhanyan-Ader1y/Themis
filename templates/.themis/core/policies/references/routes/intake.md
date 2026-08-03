# Intake 路由

> 本文件属于 [`themis-core-control`](../../README.md) 唯一 Policy，拥有 `themis-current-request-dialogue` 的三个合法控制结果。它不是 route table、DSL 或独立 Policy。

## `themis-current-request-dialogue` · `null/null`

本组只适用于 `request-intake` scope、fixed Profile `human-dialogue`、current `themis-core-control` binding、current Intake Execution Identity、唯一 Invocation/attempt、current Source Event refs、active Intake-local continuation 和 `selected_path/profile: null/null` 全部匹配的 proposed result。任何 lifecycle 创建或更新都必须等待 confirmed assignment decision 完整物化。

### `needs-request-confirmation`

当 legal status 为 `needs-request-confirmation` 时，control plane 必须完整持久化 source-bound claim/assignment proposal 与等待 confirmation 的 durable Intake-local continuation；成功后进入 `human-request-confirmation`，不创建或更新 lifecycle，也不失效既有 lifecycle authority。该结果是等待用户决定的 `non-counted` control result。

若 proposal 的 Source Event、claim fragments、target identities、Policy binding 或 continuation 不 current，control plane 必须拒绝 proposal并停止，不得从对话内容重建 diff 或把当前消息当作 confirmation；该错误按 global invalid-result 处理。

### `assignment-confirmed`

当 legal status 为 `assignment-confirmed` 时，control plane 必须验证用户确认 decision、逐 target operation、target identity 和 decision-bound continuation，完整物化 immutable assignment decision，并按每个 target 独立执行、观察和记录；成功后只沿 `decision-bound-continuation` 创建或更新 lifecycle，或恢复 `no-change` 所绑定的原 dialogue。该物化动作使同一 Intake 中依赖旧 proposal 的 pending `intake-decision` current binding 失效，但不删除或改写任何 immutable 历史 decision，也不隐式改写其他 Intake 或 lifecycle；合法成功的 failure class 为 `none`。

若 confirmation 未绑定 current proposal，任一 target operation 不属于 `create-lifecycle | update-current-request | no-change`，或无法唯一证明 decision-bound continuation，必须停在 last proven gate，不得自行选择 target、rollback 已成功 target 或根据 prose 推断 assignment；该错误按 global invalid-result 处理。

### `rejected`

当 legal status 为 `rejected` 时，control plane 必须验证 rejection 来自明确用户 decision Source Event，持久化 Intake rejection 并关闭该 Intake；成功后进入 `intake-closed`，不创建 lifecycle assignment，也不失效其他 Intake/lifecycle authority。合法成功的 failure class 为 `none`。

若 rejection 只是由沉默、宿主离开事件、Agent interpretation 或不匹配的 Source Event 推断，必须停止；宿主观察到的 abandonment 应走独立 post-control record，而不是伪造 `rejected` status。

## 共同停止条件

Unknown status、wrong scope/Profile、非 `null/null` path/profile、stale/duplicate/late result、competing terminal results、zero/multiple rule match、invalid binding 或 recorder/materialization failure 都必须拒绝结果，进入 [Failure control](../failure-control.md) 的 counted invalid-result；不得从 `recommended_route` 或自由文本猜测 route。
