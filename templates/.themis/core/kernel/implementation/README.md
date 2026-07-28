# Implementation Package

## Responsibility

Implementation 在 current approved Review 和 Plan scope 内一次执行一个 dependency-ready Task，并把执行事实持久化，避免 Agent 计划和进度只留在会话中。

## Owned assets

- 未来 `rules.md`、Implementation Prompt、task ledger 和 deviation/repair protocols。

## Inputs and outputs

输入为 current approved Spec、Plan、Review、Task dependencies、allowed scope 和 done/evidence requirements。输出为 changed files、covered ACs、observations、evidence references、deviations、Task status 和 resume cursor。

## Prompt flow and handoff

1. 选择最低序且 dependency-ready 的一个 Task。
2. 核对批准、scope 和当前代码事实。
3. 只实施该 Task 需要的变化。
4. 记录实际修改、命令观察、偏差和恢复位置。
5. Plan 不足但仍在 Spec 内时返回 Planning；超出 Spec 时返回 Specification。
6. 所有 planned Tasks 完成后 handoff 到 Verification。

## Assurance boundary

Agent 拥有具体实现选择。未来 runtime 可校验 readiness、scope、ledger/currentness 和 evidence shape，但不编写实现或判定 Verification success。

## Safe degradation

批准、Task、依赖、scope 或必要工具不可用时不开始/不继续 Task，并保存真实 blocker。不得伪造 Task completion、command output 或 evidence。

## Workspace interaction

修改仅限 approved project scope；ledger 和 cursor 写入声明的 Workspace artifact/state paths。不得修改 Core、Spec/Plan/Review-owned semantics。

## Non-ownership

不批准 Plan、不扩展 Spec、不计算 Verification verdict、不记录 Human Acceptance 或 Summary。

## Current status

该 package 当前只有目录，无 `rules.md`、Prompt、ledger schema、runtime 或 tests。Plan 35 将建立 Prompt-first contract；Plans 36/37 分别提供 assurance 与实现。
