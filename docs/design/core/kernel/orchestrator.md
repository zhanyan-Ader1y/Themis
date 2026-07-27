# Orchestrator — 编排器

> 规范状态：正式设计。实现状态：部分实现；常驻路由 rules 与领域 import 已落地，通用 lifecycle transition、Task routing、Acceptance、Summary 和 recovery 执行器尚未实现。

## 职责边界

Orchestrator 根据持久工件、机器状态和有效策略决定下一阶段，并把工作路由到对应领域。它不拥有 Spec、Plan、代码、Review finding、Verification verdict、Acceptance decision 或 Summary 内容。

- 只处理何时执行、路由到哪里和缺失能力时如何停止。
- 不替代各领域判断，也不从对话声明推断生命周期状态。
- Human Acceptance 与 Summary 是 `verified → archived` 的门禁，不是新的 lifecycle 状态。

## 生命周期

```text
Draft → Specified → Planned → Reviewed → Implemented → Verified → Archived
```

完整阶段顺序为：

```text
Draft → Specified → Planned → Reviewed → Implemented → Verified
      → Human Acceptance → Summary → Archived
```

阶段语义和返工路由以 [完整工作流程](../../workflow.md) 为准。

## Transition

确定性 transition executor 必须：

1. 读取当前持久状态和目标 transition policy。
2. 校验来源状态、目标状态和所有 hard gate evidence。
3. 拒绝非法跳转、缺失 evidence 或弱化后的 override。
4. 原子写入 `workspace/state/transitions/`。
5. 返回机器可读结果，失败时不伪造新状态。

当前只有 `draft_to_specified` 的声明式条件，没有通用执行器。

## Routing 与 Recovery

- `specified → planned`：需要 current Spec pair 与可追踪 Plan。
- `planned → reviewed`：Review 审查 Spec/Plan/设计/风险/实施边界和验收方案；只有 current `approved` result 才可迁移。
- `reviewed → implemented`：只执行批准 Review 所绑定的 Plan 和 scope lock；Spec、Plan 或设计变化使批准失效并返回 Review。
- `implemented → verified`：执行确定性 Gate 并保存 evidence；Verification 不重新批准设计。
- `verified → archived`：必须先有 human acceptance evidence 和 final `summary.md`，并满足 Outcome/Knowledge 门禁。
- 瞬态失败可以按 policy 重试；代码失败返回当前 Task；Plan 不足返回 Planning；范围超出 Spec 返回 Specification；配置或策略冲突请求人工裁决。
- Verification blocking Gate 首次失败后，只按持久 repair state 路由到修复者；修复后路由 `resume`，不得重置最多 3 次的 repair 预算或跳过失败 Gate。
- repair 预算耗尽时路由持久化 escalation 和 Knowledge candidate 请求；Knowledge 不可用时保留 Run 中的 `candidate_pending`，并以 exit `2` 暴露 exhaustion。
- Acceptance 拒绝时按证据返回 Specification、Planning 或 Implementation；任何实现变化都会使受影响 Verification evidence 失效。
- 所需 Command、Skill、Agent、Adapter 或脚本不存在时停留当前阶段并报告缺口，不能手写机器状态作为替代。

## Workspace 交互

目标合同：

```text
读取:
  workspace/manifest.yaml
  workspace/specs/<spec-id>/
  workspace/state/
  workspace/runs/ 与 evidence/

写入:
  workspace/state/transitions/
  workspace/state/tasks/
  workspace/state/retries/
  workspace/state/sessions/
```

这些状态目录当前主要是骨架；在确定性执行器落地前，不得声称 transition、Task routing、Acceptance 或 Summary 已被机器记录。
