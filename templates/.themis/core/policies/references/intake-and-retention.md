# Intake 与保留

> 本文件属于 [`themis-core-control`](../README.md) 唯一 Policy，拥有外部消息 interception、多目标 assignment、lifecycle completion 与 Intake retention 控制。它不是独立 Policy。

## 外部消息 interception

每条外部用户消息在任何 lifecycle 语义处理前必须先记录为 immutable Source Event。只有 active durable Intake-local continuation 明确等待当前 proposal 的 confirmation，或明确等待 terminated Intake Execution 的 restart/unblock decision 时，新消息才可附加到该 Intake；其他消息一律创建新 Intake。

消息措辞、聊天相邻性、存在 open Intake、聊天历史、Agent summary 或 `dormant-read-only` Intake 都不能作为 attachment signal。所有 lifecycle Questioning、Review、Acceptance 或其他用户消息同样先经过 Intake interception。

Intake decision 完整物化后：`no-change` 必须恢复原 durable dialogue continuation；changed assignment 必须只沿 confirmed decision 中逐 target 绑定的 continuation 继续。控制面不得自行构造 continuation。

## Target operations 与多目标 assignment

每个 target operation 必须拥有 stable identity，且闭合枚举只有 `create-lifecycle | update-current-request | no-change`。

Assignment decision 必须不可变。每个 target 独立执行、观察和记录；只有全部 target 完成时 Intake 才变为 `assigned`。部分成功时保持 `open + incomplete`，不得自动 rollback 已成功 target；恢复时重读实际 target 状态，只继续 `remaining_target_identities`。

同一 Source Event 片段可以显式绑定多个 target，但每个共享关系都必须出现在 confirmed assignment decision 中。不得因语义相似而隐式分流，也不得把没有 lifecycle identity 的 target 虚构为 lifecycle。

## Rejection 与 abandonment

用户明确 rejection 由 `themis-current-request-dialogue` 的 `rejected` route 记录。`abandoned` 不来自 Capability status，只能由宿主观察到明确 session termination 或 leave event 后记录；沉默不能推断 abandonment。

## Lifecycle completion 后置控制

只有 Summary pair 完整物化并重读，且 recorder 已观察并记录 lifecycle completion，才允许执行 retention 后置控制。Summary 内容本身不创建 completion 事实。

控制面必须按 completed lifecycle identity 找出所有 immutable assignment decision 和匹配 target identity，为每个 target 记录 completion observation 并冻结其 binding 为 read-only。该动作不改变其他 target，也不改变 Intake disposition。

若某 Intake 仍有任一 lifecycle-bearing target 未观察完成，其 retention mode 保持 `active`，未完成 target 的 continuation、Execution Identity 和 failure budget 继续独立有效。

只有某 Intake 的全部关联 lifecycle target 都已观察完成时，才保持 disposition `assigned`、把 retention mode 设为 `dormant-read-only`，并停用全部 Intake-local continuations。该 transition 不是 Capability、status、route-key 维度或第五种 disposition。

## `dormant-read-only`

进入 `dormant-read-only` 后，禁止附加 Source Event、调度 Invocation、恢复、重激活或修改。Source Events、proposals、confirmation/assignment decisions、target observations、completion observations、historical bindings 和 continuations 必须只读保留；不删除 authority，只允许清理可重建 cache。未来外部消息必须创建新 Intake。

跨 scope 只传递 stable immutable references，不共享 lifecycle completion state 或 Intake dynamic state。

## 必须停止的情况

若 assignment decision、target identity、completion observation 或 whole-Intake gate 无法从 durable records 唯一证明，控制面必须停在 last proven gate，不得手写 state、根据目录存在推断完成或从 prose 猜测 retention。缺少 recorder/runtime 时必须报告 assurance unavailable。
