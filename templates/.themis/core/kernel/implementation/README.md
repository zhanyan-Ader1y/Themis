# Implementation Package

## Responsibility

Implementation 只按当前 Review Approval 绑定的统一 Plan 执行一个 dependency-ready task，记录实际 delta、完成条件、偏差和 external drift。它是 Verify 阶段的执行部分，不拥有 Verification verdict。

## Capability mapping

- `themis-impl`：使用固定 `implementation-writer` Profile、唯一可在批准范围内修改项目实现的内部 Capability。
- `core/templates/impl-result.md`：一次 Impl invocation 的人工记录结构。

## Inputs and outputs

输入为 Current Request、Review Approval、approved Plan/task、Task Execution Identity、Invocation Identity、attempt、baseline、expected delta 和允许写入范围。输出状态：

```text
implemented
needs-planning
escalate-full
blocked
```

`implemented` only reports that the internal Capability completed its authorized work and recorded the observed delta; it does not prove Verification passed.

## Boundaries

- 不修改 Plan、Review、Approval 或验收要求。
- 不做无关重构或扩大批准范围。
- simple path 发现隐藏复杂度必须 `escalate-full` 并停止。
- 未授权 workspace/dependency/configuration/Schema/behavior 变化属于 external drift。
- 工具、命令或 result contract 失败计入共享 Plan task 失败预算，不能包装成 blocked。

## Write isolation

A mutating invocation binds lifecycle/task/invocation identities, an exclusive worktree when concurrency is enabled, approved paths, pre-Impl baseline, and expected state. If exclusive worktree ownership is unavailable, execution must use one serial writer or stop fail closed. Writes require pre-write validation, complete temporary write and atomic single-file replacement where applicable, completion/incomplete markers for critical multi-step records, and reread of files plus Git status/diff.

The package does not claim cross-worktree locks, general transactions, rollback journals, automatic recovery, cross-worktree merge, or conflict adjudication.

## Current status

Plan 35 provides the internal Impl Capability contract, its fixed `implementation-writer` Profile, a record template, and Prompt-level worktree/write-safety boundaries. Machine task ledgers, scope enforcement, per-lifecycle recording, atomic replacement, completion markers, and reread verification are unavailable until Plans 36/37 define and implement them.
