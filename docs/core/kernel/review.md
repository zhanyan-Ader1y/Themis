# Review — 评审

## 职责边界

Review 约束只读评审过程并标准化评审结果。它确保评审是结构化的、可追溯的，但不代替人类或 Agent 做出评审判断。

**Review 定义"评审应该怎么进行"，不定义"什么算好"——好坏的判断由评审者（人或 Agent）做出。**

## 核心能力

| 能力 | 说明 |
|---|---|
| 评审模型定义 | 定义评审的维度、检查项和评审模板 |
| 评审策略 | 约束评审时机、参与者和通过标准 |
| 评审结果标准化 | 统一评审结果的格式和严重级别 |

## 子模块

### Review-Model — 评审模型

定义评审的结构化模型：

- **评审维度**：正确性、安全性、性能、可维护性、可测试性
- **检查项**：每个维度下的具体检查点
- **严重级别**：`critical | major | minor | suggestion`
- **评审状态**：`pending | in_review | approved | changes_requested | blocked`
- **必须解决**：critical 和 major 问题必须在合入前解决

**边界**：Review-Model 定义评审结构，不定义具体检查规则（规则在 `core/policies/` 中）。

### Review-Policy — 评审策略

定义评审的治理策略：

- 评审时机：在哪个生命周期阶段触发评审
- 参与者要求：需要哪些角色参与评审
- 通过标准：至少 N 个审批者通过，零 critical 问题
- 策略定义在 `core/policies/`，项目可在 `workspace/policies/review.yaml` 中收紧

**边界**：Review-Policy 是策略框架，不是具体评审内容。

### Review-Result — 评审结果

标准化评审结果：

- 统一的评审结果格式
- 结构化的问题描述（位置、严重级别、建议修复方案）
- 评审结果保存到 `workspace/specs/<spec-id>/review.md`
- 与 Verification 模块联动：评审结果可作为 Gate 的输入证据

**边界**：Review-Result 是结果的格式化，不是评审逻辑本身。

## 与 Workspace 的交互

```
Review 读取:
  workspace/specs/<spec-id>/spec.md   # 评审对象
  workspace/specs/<spec-id>/plan.md   # 实施计划
  workspace/policies/review.yaml      # 项目评审策略

Review 写入:
  workspace/specs/<spec-id>/review.md # 评审结果
  workspace/evidence/review/          # 评审证据
```

## 输入/输出协议

- **输入**：通过 Spec Artifact Protocol 和 Plan Artifact Protocol 读取评审对象
- **输出**：评审结果通过 Review Result Protocol 标准化输出