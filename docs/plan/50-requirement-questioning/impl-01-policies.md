# P5 子模块：策略与工件契约

## 覆盖内容

- 新建 `templates/.themis/core/policies/specification.yaml`
- 新建 `templates/.themis/core/policies/transitions.yaml`
- 新建 `templates/.themis/core/templates/spec.md`

## 目标

使需求追问的确定性部分具备稳定、可检查、可供未来 P8 读取的协议，而不将根因、方案质量或批准语义错误地下沉到 Shell。

## `specification.yaml`

策略根为 `specification`，Schema 为 `themis-specification-policy/v1`。它定义：

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

它包含七个稳定条件：`intent_documented`、`scope_and_complexity_confirmed`、`context_documented`、`design_and_ac_documented`、`adversarial_validation_resolved`、`spec_self_check_completed` 和 `user_approval_recorded`。

`context_documented` 仅对 medium/high 为必需；使用 `required_for: [medium, high]`，不引入 YAML 表达式语言。策略声明未决攻击阻止迁移，限制延期数量，并禁止将 critical 安全/权限或数据完整性风险只以 `defer` 通过。

这是一份声明式证据契约，不是 P5 已实现的状态机。P8 才能读取、判定并写入机器迁移记录。

## `spec.md`

新模板使用 `themis-spec/v1` YAML front matter，初始 `status: draft`。前置字段记录复杂度、各阶段状态、对抗模式/状态与审批信息；正文有固定章节：

```text
Intent and Root Cause
Scope
Context, Constraints, and Evidence
Options and Decision
Requirements
Acceptance Criteria
Assumptions
Adversarial Validation
Limitations and Deferred Work
Rollback
Approval
```

AC 使用 `AC-xxx`，对抗发现使用 `ADV-xxx`。每个发现必须关联 AC、攻击维度、场景、处置和 Spec 位置；`accept`/`defer` 还要写入限制表。P5 只能更新 Draft 与批准证据，不能设置 `specified` 或写状态历史。

## 验证

- 两份 YAML 都能由 yq v4 解析。
- 复杂度 precedence 有三项，攻击维度有六项，快速检查有五项。
- `draft_to_specified` 是 map 且有七项条件和稳定 ID。
- `spec.md` 保留 schema、Draft 状态、模板版本和全部固定标题。
