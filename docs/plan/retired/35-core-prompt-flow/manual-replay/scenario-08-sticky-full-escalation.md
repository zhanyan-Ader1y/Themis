# 场景 08：Sticky full 单向升级

## 初始 durable facts

- Lifecycle 当前为 `simple/lightweight`，`full_path_required = false`，已有 quick Plan 前或后的 durable gate。
- 使用同一 lifecycle identity；已有 failure count、Questioning、Assessment 和 continuation 不能因升级被重置。

## 选择的 Capability / Profile / scope

- 触发点可来自 `themis-complexity-assessment`、`themis-simple-plan`、lightweight `themis-plan-check`、simple Review Dialogue、`themis-impl`、`themis-verification` 或 `themis-acceptance-dialogue`。
- 所有触发都属于 `lifecycle` scope；触发 Capability 使用其 fixed Profile。

## proposed status

- 合法升级信号包括 `full-required`、`escalate-full`，以及 simple delivery/review 中指向 full-only owner 的 `needs-planning` 或 `needs-specification`。
- 升级后的 Assessment 即使再次返回 `simple-qualified`，sticky guard 仍选择 full path。

## 适用的自然语言控制规则及其标题

- [Guard、失效与恢复 · Sticky `full_path_required`](../../../../templates/.themis/core/policies/references/guards-invalidation-and-recovery.md#sticky-full_path_required)：flag 只允许 `false → true`。
- [Failure、失效与恢复控制 · 粘性升级](../../../../templates/.themis/core/kernel/orchestrator/references/failure-invalidation-recovery.md#粘性升级)：物化 finding、设置 sticky、失效 quick downstream 并返回 full path。
- [Understanding 路由 · Complexity Assessment](../../../../templates/.themis/core/policies/references/routes/understanding.md#themis-complexity-assessment--semantic-readonly)：`simple-qualified` 受 sticky guard 约束。

## control action

- 物化触发升级的 Assessment/finding/Feedback/result。
- 设置 `full_path_required = true`，保存原 lifecycle identity、failure count 与相关 continuation evidence。
- 失效 quick Plan、Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream。
- 返回 full-path `themis-spec`，随后 Planning、full Plan Check 和完整 Review。

## materialized record/revision

触发点对应的 immutable result/structured record、sticky state observation、invalidation observations，以及后续 full-path artifacts；不创建第二个 Plan family。

## current pointer/gate

升级后 last proven gate 位于 full-path continuation。任何 retry、restart、resume、model/Agent/worktree change 或新 Intake interception 都不能把同一 lifecycle 的 sticky flag 改回 false。

## invalidation

所有 quick downstream 失效；已经独立存在的 Intake state 和其他 lifecycle 不受影响。旧 quick Approval 不可复活。

## failure class

合法 `full-required`、`escalate-full`、full-only owner return 和 sticky guard failure均为 `non-counted`；升级不清零已有 counted failure budget。

## 缺失 machine guarantees

Sticky state recorder、guard evaluator、invalidation propagation、current pointer 和 path selector runtime 均为 `unavailable`。

## replay result

**PASS（人工合同重放）**：任一合法 complexity signal 都使同一 lifecycle 单向进入 full path；后续 `simple-qualified`、retry 或恢复不能降级，也不能重置失败预算。
