# Verification — 验证

> 规范状态：正式设计。实现状态：已确认但未实现；当前没有通用 Gate runner、evidence recorder、verdict executor 或 `verify.md` renderer。

## 职责边界

Verification 在 Implementation 之后执行命令驱动的 Gate、保存证据、分类失败并计算单次 Run 的 verdict。它只陈述可观察事实，不修改实现代码、不重新审查已批准设计，也不代表人工验收。

Spec 定义需要验证的目标；approved Review 证明实施边界已在落地前获准；Context 与当前代码定义不同类型的项目事实；命令 Evidence 定义 Gate 实际观察。四者不得互相替代。

## 输入与 Run 身份

每个 Verification Run 至少绑定：

- Spec ID、`spec.yaml` revision/digest；
- approved Plan 与 Review evidence revision/digest；
- Implementation revision/digest、Task evidence 与变更范围；
- effective policy、manifest commands、Gate 顺序与 blocking 语义；
- 执行环境、工具版本与开始/结束时间。

绑定工件发生变化时，旧 Run 仍保留为历史，但不能支撑当前实现的 `verified`。

## Gate 与 Evidence

Gate execution status：

```text
pending | running | passed | failed | skipped | error
```

Gate 可以是 blocking、warning 或 informational。每次 attempt 保存：

- Gate ID、类型、policy source 和覆盖的 AC；
- 精确命令、参数、工作目录和必要环境摘要；
- exit code、stdout/stderr evidence refs；
- source revision/digest、开始/结束时间与执行状态；
- 失败或 unavailable 原因、分类和可复现 scenario；
- 旧 evidence 的失效关系及 rerun 结果。

manifest command 为 `null` 时不得发明命令。`skipped` 只有在 effective policy 明确允许时才不阻塞；不得把 `error`、缺失或未知状态聚合为 `pass`。

## Verdict

```text
pass | fail | inconclusive
```

- `pass`：所有 blocking Gate 都是 `passed` 且 AC/evidence 覆盖充分。
- `fail`：至少一个 blocking Gate 失败。
- `inconclusive`：命令不可用、evidence 缺失/不可访问或不足以判断。

Verdict 是单次 Run 的结论，不是 Review result、Human Acceptance 或最终 Outcome。任何代码、配置或相关工件变化都会使受影响 evidence 失效。

## 失败修复与 Escalation

Verification 按 Policy 顺序执行 blocking Gate，并在首个失败处 fail fast：

1. 持久化失败 Gate 的命令、exit code、stdout/stderr refs、revision/digest 和 attempt；
2. 分类失败并生成 bounded repair handoff；
3. 由外部 Agent 或用户修改实现，Verification 自身不写代码；
4. `resume` 使受影响 evidence 失效并重跑失败 Gate；
5. 初次失败后默认最多执行 3 个 repair/rerun cycle，计数跨进程和 Agent 会话保持；
6. 预算耗尽后持久化 escalation、返回稳定 JSON 并以 exit `2` 结束。

失败分类至少包含 `transient`、`code_failure`、`configuration_failure`、`policy_conflict`、`evidence_insufficient`、`assumption_violated` 和 `unknown`。`transient` 自动 retry 使用独立预算；`policy_conflict`、`evidence_insufficient`、`unknown` 和能力 unavailable 默认 fail closed。

Escalation 只能向 Knowledge 提交带 Run evidence 的 candidate 请求，不能直接写 Context；recorder 缺失时在 Run 中保存 `candidate_pending`。

## Human 投影与后续路由

`verify.md` 从 Run 与 Evidence 确定性生成，只供人类查看，不是机器 verdict 来源。它至少展示：

- 实现 revision、Spec/Plan/Review 绑定；
- AC → Gate → evidence 覆盖；
- Gate 结果、不可用检查、失败分类与 repair/rerun 历史；
- 最终 verdict、证据缺口、残余限制；
- 供人工验收执行的步骤和引用。

`pass` 只允许进入 Human Acceptance。Verification 不生成 `summary.md`，也不记录接受决定。

## Workspace 交互

目标合同：

```text
读取:
  workspace/manifest.yaml
  workspace/policies/
  workspace/specs/<spec-id>/{spec.yaml,plan.md,review.md}
  workspace/evidence/review/
  Implementation 与 Task evidence

写入:
  workspace/runs/<run-id>/
  workspace/evidence/
  workspace/specs/<spec-id>/verify.md
```

只有 Gate 通过并有充分 evidence 时，未来 lifecycle executor 才能记录 `verified`。runner、repair state、escalation Protocol 与 renderer 属于 P6.5 已确认但未实现的能力。
