# P5 子模块：策略与工件契约

## 覆盖内容

- 新建 `templates/.themis/core/policies/specification.yaml`
- 新建 `templates/.themis/core/policies/transitions.yaml`
- 新建 `templates/.themis/core/templates/spec.yaml`
- 新建 `templates/.themis/core/protocols/artifact/v2/spec-schema.yaml`
- 新建 `templates/.themis/core/protocols/artifact/v2/spec-projection.yaml`

## 目标

使需求追问的确定性部分具备稳定、可检查、可供未来 P8 读取的协议，而不将根因、方案质量或批准语义错误地下沉到 Shell。

## `specification.yaml`

策略根为 `specification`，Schema 为 `themis-specification-policy/v2`。它定义：

- 有序复杂度判定：先匹配 low 的全部条件；再匹配 medium 上限；其余为 high。
- 强制 high 信号：多子系统、架构变更、安全敏感、性能敏感。
- Step 0–4 的 low/medium/high 路由；low 跳过详细 Step 2，但不跳过 Step 4。
- 每段最多三个 AC 与用户明确确认要求。
- Option Zero 开关、六维攻击库、五项快速检查、三档迭代上限与三种处置。
- 六条 Red Flag ID，四项结构自检和六项对抗自检 ID。

`allows_state_change` 是允许型字段，不使用 `state_change: true` 这种会误作必需谓词的表达。YAML 不包含自然语言提问或语义判断规则；这些属于 Prompt。

## `transitions.yaml`

P5 仅定义一个映射：

```yaml
transitions:
  draft_to_specified:
    from: draft
    to: specified
    hard_gate: true
```

它包含八个稳定条件：`spec_intent_complete`、`spec_scope_complexity_confirmed`、`spec_context_complete`、`spec_design_acceptance_complete`、`spec_adversarial_resolved`、`spec_self_check_passed`、`spec_user_approval_recorded` 和 `spec_projection_current`。

Context 条件按复杂度由 validator 确定性评估；策略声明未决攻击阻止门禁，限制延期数量，并禁止将 critical 安全/权限或数据完整性风险只以 `defer` 通过。

这是一份声明式证据契约，不是 P5 已实现的状态机。P8 才能读取、判定并写入机器迁移记录。

## `spec.yaml` 与 `spec.md`

P5.2 使用 `themis-spec/v2` YAML 作为唯一权威源，初始 `status: draft`。结构化字段记录复杂度、五阶段状态、自检、意图、范围、证据、方案、需求、契约、不变量、AC、攻击发现、风险、回滚和批准。

语义对象使用稳定 map key：`SCP-*`、`EVD-*`、`ASM-*`、`OPT-*`、`DEC-*`、`REQ-*`、`IFC-*`、`CTR-*`、`INV-*`、`AC-*`、`ADV-*`、`RSK-*` 和 `DGM-*`。关系只使用 ID 引用；P5 只能更新临时 candidate，再由 `themis-spec.sh publish` 写入活动 pair。

`spec.md` 没有独立创建模板。executor 从有效 YAML 确定性生成 Review Summary、Architecture at a Glance、Key Decisions、Contracts and Invariants、Acceptance Criteria、Risks/Limitations/Rollback、Approval 和 Appendix，并用 source/body OID 检测漂移。

## 验证

- 两份 YAML 都能由 yq v4 解析。
- 复杂度 precedence 有三项，攻击维度有六项，快速检查有五项。
- `draft_to_specified` 是 map 且有八项条件和稳定 validator ID。
- `spec.yaml` 保留 schema、Draft 状态、模板版本和完整语义结构；`spec.md` 只能由 executor 生成并通过 OID 漂移检查。
