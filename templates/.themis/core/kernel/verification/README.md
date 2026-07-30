# Verification Package

## Responsibility

Verification 在 Impl 后以独立 invocation 读取实际实现，直接证明 Current Request 和 Plan 验收要求，核验 baseline/delta、external drift 与 simple-path 边界。它不得修改实现来使检查通过。

## Capability mapping

- `themis-verification`：独立 read-only 验证能力。
- `core/templates/verification.md`：断言、命令、stdout/stderr、delta 与 verdict 记录结构。

## Evidence

每次 attempt 记录实际 command/observation、cwd/environment、exit/result、stdout/stderr 或证据引用、覆盖范围和限制。没有配置的命令不得猜测；缺失证据不得 `passed`。

## Status contract

```text
passed
failed
needs-planning
needs-specification
escalate-full
blocked
```

`failed` 只表示有明确证据的 `implementation-defect`。隐藏合同、权限、数据、跨模块、状态或设计复杂度必须路由到 owning semantics，不能伪装为实现缺陷。

Impl 与 Verification 使用不同 Invocation Identity，但共享一个 Plan execution task identity 和累计三次失败预算。普通实现修复不修改 Plan，可直接重跑受影响 Verification；设计/需求/路径变化使 Approval 失效。

## Workspace interaction

invocation metadata belongs under `workspace/runs/<lifecycle-id>/`; direct evidence belongs under `workspace/evidence/<lifecycle-id>/`. Current templates do not prove machine persistence, currentness, or collection.

## Current status

Plan 35 provides the internal Verification Capability contract, fixed `independent-checker` Profile, and human-readable evidence template. Strict evidence/result contracts and fixtures belong to Plan 36; command execution, per-lifecycle attempt recording, completion markers, and reread verification belong to Plan 37. General transactions, locks, rollback journals, and automatic recovery are out of scope.
