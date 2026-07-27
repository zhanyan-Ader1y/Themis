# Review — 评审

> 规范状态：正式设计。实现状态：已确认但未实现；当前只有领域 rules，没有 Review template、policy 或结果执行器。

## 职责边界

Review 在 Verification 之后只读检查 Spec、Plan、implementation diff 和 Verification evidence。它形成结构化判断，但不修改实现代码、不执行 lifecycle transition，也不替代命令驱动的 Gate。

## 评审合同

评审至少覆盖 correctness、security、performance、maintainability 和 testability，并记录：

- 具体文件、位置或 evidence；
- 可复现的 failure scenario；
- 严重级别：`critical | major | minor | suggestion`；
- 修正要求或 disposition；
- 最终 Review result。

Review result 只使用：

```text
approved | changes_requested | blocked
```

`pending`、`in_review` 可以描述流程进度，但不是最终结果。

## 通过与阻塞

- 未解决的 `critical` 或 `major` finding 阻止 `approved`。
- 缺失、不完整或无法解释的 Verification evidence 产生 `blocked`，不能批准。
- 需要代码变更时返回 `changes_requested`；变更完成后必须重新运行受影响 Gate，再重新 Review。
- Review 不能把 unavailable、error 或 inconclusive Gate 解释为成功。
- 涉及项目意图的 finding 必须引用 Context ID；涉及当前实现的 finding 必须引用当前代码位置及可复核 revision/digest。Spec/Plan 只用于范围与符合性判断，不能替代项目事实来源。
- Context Bundle 为 conflict/unavailable，或 Behavior Map Anchor 非 `current` 时，Review 必须回退源文件核验；无法核验则返回 `blocked`。

未来若需要允许 major waiver，必须先设计独立、持久、可审计的 disposition 合同；当前不得以“已知债务”绕过普通 approval 条件。

## Workspace 交互

目标合同：

```text
读取:
  workspace/specs/<spec-id>/spec.md
  workspace/specs/<spec-id>/plan.md
  workspace/specs/<spec-id>/verify.md
  workspace/runs/ 与 evidence/
  implementation diff

写入:
  workspace/specs/<spec-id>/review.md
  workspace/evidence/review/
```

只有 `approved` 且前置 Verification 有效时，未来 lifecycle executor 才能记录 `reviewed`。
