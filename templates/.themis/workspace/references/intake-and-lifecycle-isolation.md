# Intake 与 Lifecycle 隔离

## Authority scopes

`request-intake` 与 `lifecycle` 可以引用同一 immutable Source Event 或 assignment decision，但不得共享 dynamic state、Execution Identity、failure budget、continuation authority、current pointer 或 completion state。跨 scope 只能通过 stable immutable reference 关联。

## Assignment gate

创建 lifecycle 或更新 Current Request 前，必须存在 confirmed 且 fully materialized 的 Intake assignment decision。合法 target operation 只有：

```text
create-lifecycle | update-current-request | no-change
```

每个 target 拥有独立的 decision-bound continuation、materialization status 与 observation。不得创建 provisional lifecycle，也不得因一个 target 成功而推断其他 target 成功。

## Partial materialization

- 部分成功时 Intake 保持 `open + incomplete`。
- 已成功 target 保持 authoritative，不回滚、不重放。
- `remaining_target_identities` 只列未完成 target。
- Recovery 只恢复未完成 target，不自动 rollback、merge 或重新执行已完成 target。

## Scope-local control

Intake state、Intake disposition、retention 与 Intake continuation 只能写入 `intakes/<intake-id>/`。Lifecycle 的 Current Request、Plan、Review、Verify、Acceptance、Summary 与 Plan Task Execution Identity 只能写入对应 lifecycle roots。目录邻近、相同文本或 Agent prose 都不能转移 ownership。
