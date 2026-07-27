# Specification — 规范

> 规范状态：正式设计。实现状态：P5 Requirement Questioning、Draft Spec 模板、policy 与批准证据合同已实现；确定性 Spec lint 和 `draft → specified` 执行器未实现。

## 职责边界

Specification 定义项目变更必须达成什么、为什么需要、批准范围及验收证据。它拥有意图、需求和 Acceptance Criteria，不拥有实施设计、Task 排序或机器生命周期状态。

## Draft Spec

新 Spec 从 `core/templates/spec.md` 创建，使用 `themis-spec/v1`。实例位于 `workspace/specs/<spec-id>/spec.md`，包含：

- Intent and Root Cause；
- Scope；
- Context, Constraints, and Evidence；
- Options and Decision；
- Requirements 与稳定 `AC-xxx`；
- Assumptions；
- Adversarial Validation 与稳定 `ADV-xxx`；
- Limitations and Deferred Work；
- Rollback；
- Approval。

Core Upgrade 不覆盖已创建的 Spec；旧 Artifact 的结构变化只能通过显式 Migration 处理。

## Requirement Questioning

P5 按 `core/policies/specification.yaml` 执行：

```text
Step 0 — Intent Discovery
Step 1 — Scope Assessment
Step 2 — Context Gathering
Step 3 — Design Convergence
Step 4 — Adversarial Validation
```

- low 使用精简 Step 0/3 和快速攻击检查；medium/high 增加上下文、证据、Option Zero 和更完整攻击。
- 每个 AC 描述可验证行为，并最终由至少一个 Task 和 Gate 追踪。
- 有效攻击使用 `cover`、`accept` 或 `defer` 处置；critical 安全、权限或数据完整性风险不能仅延期。
- 用户必须明确确认复杂度和最终 Draft。
- Step 0 提取初步 intent 与业务词汇后，Specification 必须请求 Context Resolution；显式 Context ID 优先，其次按 domain、entity、operation 和 state 查找。
- Spec 定义期望变化，不能自证既有业务事实。Context 缺失、冲突或与代码漂移时，相关内容必须保留为问题、假设或变更目标，不能静默写成已确认事实。

P5.4 的 Catalog、Bundle 和 Signal 执行器尚未实现；缺失时回退当前代码与人工确认，并明确记录证据限制。完整合同见 [Context](context.md)。

## Approval 与状态

`core/policies/transitions.yaml` 声明 `draft_to_specified` 所需的稳定 evidence 条件。P5 只记录这些 evidence，并保持 `status: draft`。

Approval decision 与 lifecycle status 是不同命名空间。Prompt、用户确认或完成的 Spec 都不能自行记录 `specified`；只有确定性 executor 可以评估 Gate 并写入 transition。

## Workspace 交互

```text
读取:
  workspace/context/
  workspace/specs/<spec-id>/spec.md

写入:
  workspace/specs/<spec-id>/spec.md
```

Specification 不写项目代码、Plan、Verification verdict、Review result 或 `workspace/state/transitions/`，也不把观察性结论直接提升为正式 Context。
