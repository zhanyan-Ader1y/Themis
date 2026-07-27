# Verification — 验证

> 规范状态：正式设计。实现状态：已确认但未实现；当前没有通用 Gate runner、evidence recorder 或 verdict executor。

## 职责边界

Verification 执行命令驱动的 Gate、保存证据、分类失败并计算单次 Run 的 verdict。它只陈述可观察事实，不修改实现代码，也不代替 Review 判断设计与代码质量。

## Gate

Gate 从 `workspace/manifest.yaml` 和 effective policy 读取。manifest command 为 `null` 时不得发明命令。

Gate execution status：

```text
pending | running | passed | failed | skipped | error
```

Gate 可以是 blocking、warning 或 informational。具体检查由 Adapter 或确定性脚本执行；Verification 负责编排与证据合同。

## Evidence 与失败分类

每个 Gate 保存：

- 精确命令和参数；
- 退出码、stdout、stderr；
- 执行状态和时间信息；
- evidence 引用；
- 不可用或失败原因。

失败至少区分 transient、code failure、configuration failure 和 policy conflict。Verification 只分类并路由，不直接修复。

## Verdict

```text
pass | fail | inconclusive
```

- `pass`：所有 blocking Gate 都是 `passed` 且 evidence 充分。
- `fail`：至少一个 blocking Gate 失败。
- `inconclusive`：命令不可用、evidence 缺失/不可访问或不足以判断。

`skipped` 只有在 effective policy 明确允许时才不阻塞；不得把 `error`、缺失或未知状态聚合为 `pass`。

Verdict 是单次 Run 的结论，不代表最终交付 Outcome。任何代码变更都会使受影响 evidence 失效。

## Workspace 交互

目标合同：

```text
读取:
  workspace/manifest.yaml
  workspace/policies/
  workspace/specs/<spec-id>/

写入:
  workspace/runs/<run-id>/
  workspace/evidence/
  workspace/specs/<spec-id>/verify.md
```

只有 Gate 通过并有充分 evidence 时，未来 lifecycle executor 才能记录 `verified`。
