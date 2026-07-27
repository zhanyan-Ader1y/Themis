# P6.8 — Review Enhancement（评审增强）

**优先级**：P6.8（在 P6.5 验证增强之后、P7 集成审计之前）
**依赖**：[P1 Template Contract](../10-template-contract/README.md)、[P5 Requirement Questioning](../50-requirement-questioning/README.md)、[P6.5 Verification Enhancement](../65-verification-enhancement/README.md)
**状态**：待用户主动发起

> **历史提案注记**：以下“`major` 可记录为已知债务后通过”的方案已被 [Review 正式规范](../../design/core/kernel/review.md) 取代。未解决的 `critical` 或 `major` finding 阻止 `approved`；实施本计划时以正式规范为准，原文仅保留为历史提案。

## 背景

Review 是 SDD 生命周期中 Verified → Reviewed 的关键阶段。它提供独立于 Verification 的第二层质量保障——Verification 回答"Gate 是否通过"，Review 回答"证据是否真的支撑 Spec 和 Plan 的完成"。当前基线：

- `review/rules.md` 定义了模块边界，但内容为基线占位
- 无 Review 策略配置（评审维度、严重级别、通过标准）
- 无 Review 执行 Prompt 模板
- 无标准化的评审结果格式

P5 需求追问引入的"对抗式验证"用于攻击需求完整性，Review 的"独立评审"用于攻击实现证据的充分性。两者是不同阶段的对抗。

## 目标

将 Review 从文档化的理论模型落地为可执行的能力层：

1. 定义 Review 策略配置（评审维度、严重级别、通过标准）
2. 编写 Review 执行 Prompt 模板（从 Spec + Plan + Diff + Evidence 生成评审结果）
3. 更新 `review/rules.md` 使其不再为占位状态
4. 同步更新 WIKI 文档

## 核心设计

### 评审维度

| 维度 | 关注点 | 严重级别阈值 |
|---|---|---|
| correctness | 行为是否符合 Spec AC | 任何偏差 → critical |
| security | 是否引入安全漏洞 | 任何漏洞 → critical |
| performance | 是否引入性能退化 | 显著退化 → major |
| maintainability | 代码可读性、结构合理性 | 混乱 → minor |
| testability | 是否有足够测试覆盖 | 缺失关键路径 → major |

### 严重级别

| 级别 | 含义 | 处理 |
|---|---|---|
| critical | 必须在合入前解决 | 返回 Implementation |
| major | 应在合入前解决 | 返回 Implementation 或记录为已知债务 |
| minor | 建议改进 | 可记录、不阻塞 |
| suggestion | 可选优化 | 可忽略 |

### 评审结果

| 结果 | 条件 |
|---|---|
| approved | 零 critical、零 major |
| changes_requested | 存在 critical 或 major |
| blocked | 证据不足、无法做出判断 |

### 与 P5 对抗验证的关系

| 维度 | P5 Step 4 对抗验证 | Review |
|---|---|---|
| 对象 | Spec（需求） | 实现 + 证据 |
| 立场 | 攻击需求完整性 | 攻击证据充分性 |
| 时机 | Draft → Specified | Verified → Reviewed |
| 输出 | 加固后的 Spec + Limitation | review.md + 评审结果 |

## 目标文件

| # | 文件 | 操作 | 说明 |
|---|---|---|---|
| 1 | `templates/.themis/core/policies/review.yaml` | 新建 | 评审维度、严重级别、通过标准 |
| 2 | `templates/.themis/core/templates/review-execution.md` | 新建 | Review 执行 Prompt（Spec + Plan + Diff + Evidence → 评审结果） |
| 3 | `templates/.themis/core/kernel/review/rules.md` | 更新 | 从占位内容更新为完整评审规则 |
| 4 | `docs/design/core/kernel/review.md` | 更新 | 同步 WIKI |

## 验收条件

- `review.yaml` 定义 ≥5 个评审维度，每个有严重级别阈值
- `review-execution.md` 含结构化的评审 Prompt（输入、维度扫描、结果生成）
- `review/rules.md` 不再包含占位内容
- Review 与 Verification 的职责边界清晰（Review 不执行 Gate）
- Review 与 P5 对抗验证的角色差异有明确文档

## 非范围

- 不实现确定性 Shell 脚本（`themis-review-summary.sh` 留待 P8）
- 不实现多评审者协作机制
- 不修改 Workspace 目录结构

## 风险与回滚

- **风险**：Review 过于严格导致开发停滞 → **缓解**：允许记录已知债务后通过
- **回滚**：移除新增文件，恢复 rules.md 到基线
