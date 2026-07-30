# Planning Package

## Responsibility

Planning 在完整路径中调查当前实现、比较技术方案并生成统一 Plan。简单路径由 `themis-simple-plan` 生成同一工件；不存在第二套 Plan authority。

## Capability mapping

- `themis-simple-plan`：在已证明简单的边界内形成统一 Plan。
- `themis-planning`：完整技术设计、方案取舍、任务分解与 Verification 设计。
- `themis-plan-check`：按 lightweight/full profile 独立检查当前 Plan。

## Unified Plan

`workspace/changes/<lifecycle-id>/plan.md` 是首个完整持久化执行合同，至少包含：

- Current Request、范围和核心链路；
- 行为、合同和验收要求；
- 当前实现事实、假设与不变量；
- 技术方案、取舍和实现设计；
- technical impact, failure handling, interruption boundaries, and bounded fallback;
- dependency-ready Impl/Verification tasks、scope、done conditions 和证据要求；
- Current Request、设计约束、直接实现事实、临时 Specification refinement 的分类覆盖映射。

Plan 始终从属于 Current Request。简单路径中不适用的深层设计项必须有证据化 `not-applicable`，不能省略需求覆盖、事实证据、验证或可执行性。

## Boundaries

Planning 不批准需求、不授权 Impl、不修改实现、不判断 Verification。Plan Check 与生成过程隔离；Plan 变化使 Check、Review 和 Approval 失效。

## Current status

Plan 35 provides internal Simple Planning, Planning, and Plan Check Capability contracts plus the shared Markdown template. Strict Plan Schema, DAG/currentness validation, canonical projection, and fixtures belong to Plan 36; policy evaluation, invocation, per-lifecycle recording, atomic replacement, completion markers, and reread verification belong to Plan 37. General transactions, locks, rollback journals, and automatic recovery are out of scope.
