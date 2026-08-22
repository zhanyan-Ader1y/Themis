# 场景 06：Review / Acceptance 消息先经过 Intake

## 初始 durable facts

- Variant A：lifecycle 停在 `human-review`，保存 exact Review Dialogue continuation。
- Variant B：lifecycle 停在 Human Acceptance，保存 exact Acceptance Dialogue continuation，且 current Verification 为 `passed`。
- 新用户消息尚未成为 Source Event。

## 选择的 Capability / Profile / scope

1. 两个 variant 都先记录 Source Event，并调用 `themis-current-request-dialogue` / `human-dialogue` / `request-intake` / `null/null`。
2. Intake Decision current 后，分别恢复 `themis-review-dialogue` / `human-dialogue` / `lifecycle` 或 `themis-acceptance-dialogue` / `human-dialogue` / `lifecycle`。

## proposed status

- Claims/assignment 未变：`assignment-confirmed` + `no-change`。
- 若消息改变 claims/assignment：先 `needs-request-confirmation`，确认后 `assignment-confirmed` + 对应 changed operation。
- Lifecycle Capability 只有在 Intake 后才返回自己的 legal status。

## 适用的自然语言控制规则及其标题

- [Intake 与保留 · 外部消息 interception](../../../../templates/.themis/core/policies/references/intake-and-retention.md#外部消息-interception)：所有 Review/Acceptance 消息统一先过 Intake。
- [Review 与完成控制 · 加载条件](../../../../templates/.themis/core/kernel/orchestrator/references/review-and-completion.md#加载条件)：Review 或 Acceptance 用户消息先加载 Intake reference。
- [Intake 路由 · `assignment-confirmed`](../../../../templates/.themis/core/policies/references/routes/intake.md#assignment-confirmed)：Decision current 后才恢复原 dialogue。

## control action

- 记录消息原始 bytes 和 exact fragments。
- 物化 no-change 或 changed assignment decision。
- 把原消息 Source Event 交回原 lifecycle continuation；confirmation Source Event 仅证明 governance decision。
- Review Feedback/Approval 或 Human Acceptance 只能在 lifecycle continuation 恢复后产生。

## materialized record/revision

- Source Event 与 Intake Decision；changed variant 还包含 Intake Proposal、confirmation Source Event 和新的 Current Request pair。
- Lifecycle 恢复后才可能物化 Review Feedback/Approval 或 Human Acceptance pair。

## current pointer/gate

- Intake materialization 前，Review/Acceptance gate 保持不动。
- Changed claim 使原 lifecycle gate stale；no-change 保持原 gate和 current artifacts。

## invalidation

- No-change：无 lifecycle invalidation。
- Changed Current Request：按 Policy 失效 Questioning、Assessment、Plan 与 unfinished downstream，旧 Review/Approval/Acceptance 不可复用。

## failure class

等待用户 disposition、review 或 acceptance：`non-counted`；合法 no-change/assignment：`none`。

## 缺失 machine guarantees

Source Event recorder、semantic comparison、continuation binding、gate currentness 和 materialization runtime 均为 `unavailable`。

## replay result

**PASS（人工合同重放）**：Review 与 Acceptance 都没有绕过 Intake；原 lifecycle continuation 只在 durable Intake Decision 后恢复。
