# 物化与当前性

> 本文件属于 [`themis-core-control`](../README.md) 唯一 Policy，拥有 Capability proposal、完整物化、paired/structured record、currentness checkpoint 和 pointer 更新规则。它不是独立 Policy。

## Capability result 不是 authority

Capability Invocation Result 永远只是 proposal。Profile 的工具权限不赋予 Workspace 治理写入权，文件存在也不证明成功。

Control plane 必须按顺序完成：验证 proposed result 的 identity、scope、Profile、status 和 bindings；精确匹配一条 Policy rule；执行该规则声明的 control action；持久化全部 required components；记录 completion 或 incomplete observation；重读 record/content/identity/digest/bindings；观察 immutable revision；最后更新独立 current pointer。

任一步骤缺失都不得推进 gate、声称 persistence 或从 Agent summary 推断成功。

## 成对语义工件

Paired artifact 的不可分割组件是同一 immutable revision 下的 `record.md` 与 `content.md`。任一组件缺失，或 identity、digest、authority scope、source binding、artifact binding 不一致时，整个 revision invalid。

`record.md` 保存 identity、revision、typed fields、source/current bindings、content path/digest、disposition/currentness 和 materialization observation；`content.md` 保存 governed human semantics。两者都不能单独成为 authority。

## 结构化记录

Structured semantic record 使用独立 immutable Markdown record，不机械生成无语义的 `content.md`。它仍必须拥有 stable identity、typed bindings、closed status、source refs 和 materialization observation。

Temporary Specification handoff 是唯一临时例外：它不拥有 semantic authority 或 persistent current pointer；恢复时必须从 current bindings 重新生成，不能从旧 handoff 续接。

## Incomplete 与 pointer failure

若 paired artifact 只完成部分组件或 recorder/materialization 失败，必须记录 incomplete operation，保持 last proven gate，不创建完整 revision。

若 revision 已完整形成但 pointer update 失败，revision 可以保持 valid，但不能成为 current。恢复时必须重读 revision 与 current bindings，再决定是否重试 pointer update；不能以 revision 存在推断 pointer 已更新。

Stale、duplicate、late、cancelled、wrong-scope 或 wrong-binding result 一律拒绝，不得成为 current，并按 invalid-result 计入对应 scope 的 failure control。

## Review Feedback resolution observation

当 Invocation 由 durable Review Feedback owner continuation 恢复时，result input bindings 必须携带 exact `review_feedback_revision` 与 `review_feedback_owner_continuation_reference`。Capability 不得自行声明 Feedback resolved。

只有 owner-specific 成功结果及其控制动作产物全部完成 ordered materialization 并重读后，control plane 才能在 lifecycle state 记录 separate immutable resolution observation。该 observation 至少绑定 Feedback revision、owner continuation、owner Capability/result、产生的新 Current Request/Questioning/Plan/Plan Check/Review Projection revision 或 temporary Specification result evidence、materialization/reread evidence，以及记录时该 Feedback 仍属于 unresolved set 的 state reference。Resolution observation 完整记录并重读后，control plane 才能另行记录引用该 observation 的 unresolved-set update observation；只有该 state update 也完成记录和重读，新 state view 才能排除 exact Feedback revision。

合法 owner-specific 成功结果固定为：`themis-current-request-dialogue` 的 `assignment-confirmed` 且对应 Current Request control action 完成；`themis-q` 的 `converged`；`themis-spec` 的 `ready`；`themis-simple-plan` 的 `ready`；`themis-planning` 的 `ready`；`themis-plan-check` 的 `pass`；`themis-review-projection` 的 `ready`。等待、确认中、blocked、needs-*、grounding、escalation、rejection、Invocation 开始、文件存在或相似内容都不能创建 resolution observation。

Resolution observation 不是 semantic artifact family、Capability status、route-key dimension 或 current pointer；它不改写 immutable Feedback pair。Owner result 可能解决 Feedback，但其上游变化仍按 invalidation rules 使 Review/Approval downstream 保持 stale，直到完整重建并重新进入 Review。

## 当前性要求

至少在 Invocation 前、Capability result 返回后、control action 前和 current pointer 更新前验证：observed Policy binding；current source/artifact bindings；authority scope；Execution/Invocation identities；fixed Agent Profile；selected path/profile；observed recorder result；以及重读后的 identity/content/digest/bindings。

Policy 改变时 stop-and-revalidate。Source Event、claim、artifact 或 governed fact 改变时按 [Guards, invalidation and recovery](guards-invalidation-and-recovery.md) 失效 dependents。

Invocation 完成后若由独立 external drift 导致 currentness 失效，丢弃 proposed result、记录 drift，并以 `non-counted` stop-and-revalidate；不得把外部漂移计作该 Invocation failure。

## 结果唯一性

一个 Invocation 只接受一个终态 result。Duplicate、late、cancelled 或 competing terminal results 永远不能成为 current。Pending Intake proposal 在 Source Event、claim set、assignment target 或 Policy 改变后 stale，旧 confirmation Source Event 不能复活它。

## 必须停止的情况

若无法证明完整 ordered materialization、唯一 current pointer、current bindings 或 recorder observation，Global Rule 必须停在 last proven gate。不得根据文件名、目录存在、时间顺序、聊天内容或自由文本补全缺失事实。
