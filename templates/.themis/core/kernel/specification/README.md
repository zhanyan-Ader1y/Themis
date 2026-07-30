# Specification Package

## Responsibility

Specification 只在完整路径中细化已完成需求追问的 Current Request，形成临时、非权威 Planning handoff。它不持久化需求权威，不拥有复杂度判断、Plan、Review 或实现事实。

## Capability mapping

- `themis-q`：在路径选择前收敛 Why 与抽象 What；不属于 Specification 内部步骤。
- `themis-spec`：完整路径的范围、可观察行为、业务/外部合同、不变量、验收、风险和 Planning 不变量 refinement。

## Inputs and outputs

输入为 Requirement Input Bundle 与直接实现事实证据。`ready` 输出只存在于 active control context：

```markdown
## 动机与目标
## 核心链路
## 范围
## 行为与合同
## 验收要求
## 当前实现事实与证据
## 推导假设
## 风险与未解决事项
## Planning 不变量
```

中断后从相同 bundle 重新生成，不恢复为持久 authority。

## Authority boundary

- Current Request Revision 始终是目标语义来源。
- Specification 不能证明当前实现、覆盖用户纠正或被其他需求当事实引用。
- 不生成 `spec.yaml`、`spec.md`、独立批准或 Spec currentness。
- Planning 发现事实或语义缺口时必须回到 owning capability，不能静默补齐。

## Current status

Plan 35 provides the internal `themis-spec` Capability contract and its temporary handoff shape. There is no Specification artifact, public Specification Skill, validator, projector, publisher, approval recorder, or executable regression suite.
