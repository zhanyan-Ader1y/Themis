# 完成与 Intake 保留

## Lifecycle 完成观察

只有 current Verification 为 `passed`、current Human Acceptance 为 `accepted`，且 Summary pair fully materialized、reread 并成为 current 后，Policy 才能另外记录 lifecycle completion observation。该 observation 不是 Summary 字段，也不得回写 immutable Summary。

## Target-bound 完成

Lifecycle completion 被观察后，必须在每个绑定该 lifecycle identity 的 immutable Intake assignment target 所属 `intakes/<intake-id>/state/` 下记录 completion observation。每个 matching target binding 独立变为 read-only，不改变其他 target。

## 保留模式

Intake disposition 的闭合枚举是：

```text
open | assigned | rejected | abandoned
```

Derived retention mode 的闭合枚举是：

```text
active | dormant-read-only
```

`dormant-read-only` 不是 disposition、Capability status 或 route dimension。Assigned Intake 只有在全部 associated lifecycle-bearing targets 都 observed completed 后才进入该模式；其 disposition 仍是 `assigned`。

## 只读保留

进入 `dormant-read-only` 后：

- 全部 Intake-local continuations inactive 且 non-attachable；
- Source Events、proposals、confirmation/assignment decisions、target materialization observations、completion observations 与 historical bindings 保持 immutable read-only；
- 不得删除、改写、调度 Invocation 或作为 execution recovery 来源；
- 只有 rebuildable cache 可以清理。

只要任一 associated target 未完成，Intake 就保持 `active`。已完成 target bindings 独立冻结，不能阻塞、回滚或修改未完成 target。未来 external message 不得附着到 `dormant-read-only` Intake，必须创建新 Intake identity。
