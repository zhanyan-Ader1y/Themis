# 场景 03：多 target assignment 与整体 dormancy

## 初始 durable facts

- 一个 Intake Proposal 显式列出多个 stable target identities、各自 operation 与 decision-bound continuation。
- Target A 与 lifecycle A 绑定，Target B 与 lifecycle B 绑定；两者可共享明确记录的 Source Event fragments，但不共享动态 lifecycle state。

## 选择的 Capability / Profile / scope

- Assignment：`themis-current-request-dialogue` / `human-dialogue` / `request-intake` / `null/null`。
- 每个 lifecycle 后续使用自身 fixed Capability/Profile 和独立 Plan Task Execution Identity。
- Completion retention 是 Policy 后置控制，不是新 Capability Invocation。

## proposed status

- `needs-request-confirmation`，随后 `assignment-confirmed`。
- 每个 target operation 只能是 `create-lifecycle | update-current-request | no-change`。
- Lifecycle completion 与 `dormant-read-only` 都不是 Capability status。

## 适用的自然语言控制规则及其标题

- [Intake 与保留 · Target operations 与多目标 assignment](../../../../templates/.themis/core/policies/references/intake-and-retention.md#target-operations-与多目标-assignment)：逐 target 执行、观察和记录。
- [Review 与完成控制 · Lifecycle completion 与 Intake retention](../../../../templates/.themis/core/kernel/orchestrator/references/review-and-completion.md#lifecycle-completion-与-intake-retention)：逐 target freeze，全部完成后才 dormant。
- [完成与 Intake 保留 · 保留模式](../../../../templates/.themis/workspace/references/completion-retention.md#保留模式)：disposition 保持 `assigned`，retention 独立派生。

## control action

- 完整物化 assignment decision 后，独立执行并观察 A/B target。
- Lifecycle A 完成后只记录并冻结与 A 绑定的 target；B 继续 active。
- Lifecycle B 完成且同一 Intake 的全部 lifecycle-bearing targets 均 completed 后，停用所有 Intake-local continuations，设置 retention `dormant-read-only`。

## materialized record/revision

- 一份 immutable Intake Decision。
- 每 target 的 materialization 与 completion observations。
- 每 lifecycle 的 Current Request、Summary pairs 和 separate completion observation。
- Intake state 中引用 immutable decision/completion observations 的 retention fact。

## current pointer/gate

- Assignment 全部 target 完成后 Intake 才成为 `assigned`。
- A/B lifecycle 各自推进 current gate。
- A 完成而 B 未完成时 Intake retention 仍为 `active`；全部完成后才 dormant。

## invalidation

- Target-local change 只失效对应 lifecycle dependents。
- A 的完成不回滚、不阻塞、不修改 B。
- Retention transition 不改写 assignment decision。

## failure class

- 合法 assignment/completion：`none`。
- 等待其他 target 完成和 retention gating：`non-counted`。

## 缺失 machine guarantees

Target identity validation、逐 target writes、cross-reference completion discovery、retention persistence 和 continuation deactivation 均为 `unavailable`。

## replay result

**PASS（人工合同重放）**：Markdown contracts 保持逐 target freeze 与 all-target dormancy，且 `dormant-read-only` 没有被提升为 route/status/disposition。
