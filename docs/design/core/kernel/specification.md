# Specification — 规范

> 规范状态：正式设计。实现状态：Themis-Q 追问方法 Skill、无版本 Spec 双视图模板、policy、确定性 executor、最终语义 readiness 与批准证据合同已实现；持久 `draft → specified` 状态执行器尚未实现。

## 职责边界

Specification 定义项目变更必须达成什么、为什么需要、批准范围及验收证据。它拥有意图、需求和 Acceptance Criteria，不拥有实施设计、Task 排序或机器生命周期状态。

## Spec 双视图

每个活动 Spec 都是位于 `workspace/specs/<spec-id>/` 的配对工件：

```text
spec.yaml  # 当前唯一、无独立版本号的 Agent-readable 语义源
spec.md    # 确定性生成的 Human-readable 审阅投影
```

- `spec.yaml` 是唯一权威源。Agent、Planning、状态转换和 Verification 只消费其稳定对象、引用和 validator JSON；不得把 Markdown 标题或正文作为机器证据。
- `spec.md` 是可重建、不可反向同步的审阅投影。source/body OID、marker 损坏或任意手改都构成投影漂移，必须由 executor 从 YAML 重建。
- Canonical pair 仅可由 `core/kernel/specification/themis-spec.sh publish` 写入。P5 仅修改 `workspace/cache/spec-candidates/<spec-id>.yaml` candidate。
- `validate`、`render` 与 `publish` 均 fail closed；`publish` 在 staging 中验证、渲染和校验配对后，以备份与恢复避免留下半套活动工件。

`spec.yaml` 使用 map key 作为稳定对象身份，并以 `SCP-`、`EVD-`、`ASM-`、`OPT-`、`DEC-`、`REQ-`、`IFC-`、`CTR-`、`INV-`、`AC-`、`ADV-`、`RSK-`、`DGM-` 等 ID 表达引用。其语义包含 intent、scope、context basis、evidence、assumptions、options、decisions、requirements、interfaces、contracts、invariants、AC、对抗发现、风险、回滚与批准。Artifact 合同仍为 `themis-artifact`；Themis 尚未正式发布，当前唯一 Spec 合同不保存独立 `spec_schema` 或 `template_version`，也不提供历史转换能力。

Human 投影固定展示 Review Summary、Architecture at a Glance、Key Decisions、Contracts and Invariants、Acceptance Criteria、Risks/Limitations/Rollback、Approval 与 Appendix。摘要、主决策、主风险和图选择由 YAML 明确提供；渲染器只排版，不推断语义。

## Requirement Questioning

Requirement Questioning 使用 Init 安装到 `.claude/skills/Themis-Q/` 的 Project Skill，并且发生在任何 Spec candidate 创建之前。`Themis-Q` 只定义提问方式、适应性深度、需求覆盖、假设挑战、Acceptance Criteria 组织与对抗问题；它不定义生命周期、执行上下文、工具边界、持久化、确认 gate、handoff 或 Spec 序列化。

Specification 在当前请求仍有重要不确定性时，必须通过 Skill 工具调用精确名称 `Themis-Q`。Skill 缺失或调用失败时停留 Specification，不得读取退役 Prompt 或创建 candidate 作为 fallback。若当前会话已经用该指导澄清请求，则无需机械重复调用；用户改变需求或纠正规范化摘要后，可再次调用以补充追问方法。

Specification 独立拥有以下职责：

- 读取 `core/policies/specification.yaml`、相关 Context、既有 Specs 和必要的当前代码或配置；
- 分类复杂度，并按不确定性和影响选择适当追问深度；
- 判断重要不确定性是否已解决，规范化最终需求并请求用户纠正；
- 请求是否生成 Draft Spec 的明确确认；
- 确认后将当前对话中的最终语义映射到唯一 `workspace/cache/spec-candidates/<spec-id>.yaml`；
- 调用 `themis-spec.sh publish` 校验、渲染并发布 canonical pair，后续校验和批准继续使用同一路径。

- low 使用精简追问和快速攻击检查；medium/high 增加上下文、证据、Option Zero 和更完整攻击。
- 每个 AC 描述可验证行为，并最终由至少一个 Task 和 Gate 追踪。
- 有效攻击应明确覆盖、接受为已知风险或延期为独立工作；critical 安全、权限或数据完整性风险必须解决或阻断。
- 用户必须明确确认复杂度、分段 AC 和最终 Draft 生成。
- Context/代码只作为需求证据；缺失、冲突或漂移必须进入 assumption、risk 或 limitation，不能静默写成事实。

最终 Spec 不保存 `questioning` step status、逐轮问答或 Agent 自报 self-check。`context_basis` 使用 `grounded | not_required | limited` 记录最终依据、证据引用、限制引用与理由；`spec_self_check_passed` 由 validator 对摘要/意图、scope 投影、resolved assumption/option、selected option 引用、Requirement/AC traceability、占位符和 rollback 完整性执行确定性聚合。

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
