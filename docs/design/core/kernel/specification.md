# Specification — 规范

> 规范状态：正式设计。实现状态：P5 Requirement Questioning、Spec v2 双视图模板、policy、确定性 executor 与批准证据合同已实现；持久 `draft → specified` 状态执行器仍未实现。

## 职责边界

Specification 定义项目变更必须达成什么、为什么需要、批准范围及验收证据。它拥有意图、需求和 Acceptance Criteria，不拥有实施设计、Task 排序或机器生命周期状态。

## Spec 双视图

每个活动 Spec 都是位于 `workspace/specs/<spec-id>/` 的配对工件：

```text
spec.yaml  # themis-spec/v2；唯一权威、Agent-readable 语义源
spec.md    # 确定性生成的 Human-readable 审阅投影
```

- `spec.yaml` 是唯一权威源。Agent、Planning、状态转换和 Verification 只消费其稳定对象、引用和 validator JSON；不得把 Markdown 标题或正文作为机器证据。
- `spec.md` 是可重建、不可反向同步的审阅投影。source/body OID、marker 损坏或任意手改都构成投影漂移，必须由 executor 从 YAML 重建。
- Canonical pair 仅可由 `core/kernel/specification/themis-spec.sh publish` 写入。P5 仅修改 `workspace/cache/spec-candidates/<spec-id>.yaml` candidate。
- `validate`、`render` 与 `publish` 均 fail closed；`publish` 在 staging 中验证、渲染和校验配对后，以备份与恢复避免留下半套活动工件。

`spec.yaml` 使用 map key 作为稳定对象身份，并以 `SCP-`、`EVD-`、`ASM-`、`OPT-`、`DEC-`、`REQ-`、`IFC-`、`CTR-`、`INV-`、`AC-`、`ADV-`、`RSK-`、`DGM-` 等 ID 表达引用。其语义包含 intent、scope、evidence、assumptions、options、decisions、requirements、interfaces、contracts、invariants、AC、对抗发现、风险、回滚与批准。当前原生合同为 `themis-artifact/v2` / `themis-spec/v2`，不提供 Artifact v1 或 Spec v1 兼容及迁移路径。

Human 投影固定展示 Review Summary、Architecture at a Glance、Key Decisions、Contracts and Invariants、Acceptance Criteria、Risks/Limitations/Rollback、Approval 与 Appendix。摘要、主决策、主风险和图选择由 YAML 明确提供；渲染器只排版，不推断语义。

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

结构有效的 Draft 可持久化但不代表已满足 lifecycle gate。`core/policies/transitions.yaml` 将 `draft_to_specified` 固定为 executor 输出的八个 readiness check：

```text
spec_intent_complete
spec_scope_complexity_confirmed
spec_context_complete
spec_design_acceptance_complete
spec_adversarial_resolved
spec_self_check_passed
spec_user_approval_recorded
spec_projection_current
```

P5 记录证据并保持 `status: draft`。Approval decision 与 lifecycle status 是不同命名空间；Prompt、用户确认或完成的 Spec 都不能自行记录 `specified`。未来 P8 必须复用 `themis-spec.sh validate` 的稳定 JSON，不得实现第二个 Spec 解析器。

## Workspace 交互

```text
读取:
  workspace/context/
  workspace/specs/<spec-id>/spec.yaml
  workspace/specs/<spec-id>/spec.md       # 仅供人类审阅

写入:
  workspace/cache/spec-candidates/<spec-id>.yaml
  workspace/specs/<spec-id>/{spec.yaml,spec.md}  # 仅 publisher
```

Specification 不写项目代码、Plan、Verification verdict、Review result 或 `workspace/state/transitions/`，也不把观察性结论直接提升为正式 Context。
