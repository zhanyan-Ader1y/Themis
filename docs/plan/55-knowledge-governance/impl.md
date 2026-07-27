# P5.5 实施索引

本文档是 P5.5（人机混合知识治理）的实施总索引。每个子模块的详细设计与实施规范见独立文件。

## 子模块段落

| 段落 | 文件 | 覆盖任务 | 说明 |
|---|---|---|---|
| 治理策略 | impl-01-policies.md | knowledge-governance.yaml | 审核维度、去重阈值、提升规则 |
| 候选提取 | impl-02-extraction.md | knowledge-candidate-extraction.md | 从执行/验证/评审/Outcome 中提取知识候选的 Prompt |
| 审核模板 | impl-03-review.md | knowledge-review.md | 结构化审核 Prompt（准确性、完整性、冲突、可操作性） |
| 规则引擎 | impl-04-rules.md | knowledge/rules.md 更新 | 从占位内容更新为完整治理规则 |
| 文档同步 | impl-05-docs.md | knowledge.md 文档更新 | WIKI 同步 |

## 目标文件清单

| # | 文件 | 操作 | 所属段落 |
|---|---|---|---|
| 1 | `templates/.themis/core/policies/knowledge-governance.yaml` | 新建 | impl-01 |
| 2 | `templates/.themis/core/templates/knowledge-candidate-extraction.md` | 新建 | impl-02 |
| 3 | `templates/.themis/core/templates/knowledge-review.md` | 新建 | impl-03 |
| 4 | `templates/.themis/core/kernel/knowledge/rules.md` | 更新 | impl-04 |
| 5 | `docs/design/core/kernel/knowledge.md` | 更新 | impl-05 |

## 执行顺序

1. **impl-01**（治理策略）— 策略基础
2. **impl-02**（候选提取）— 并行
3. **impl-03**（审核模板）— 并行
4. **impl-04**（规则引擎）— 依赖 impl-01、impl-02、impl-03
5. **impl-05**（文档）— 依赖 impl-04

## 验证矩阵

| # | 验证项 | 验证方式 | 预期结果 |
|---|---|---|---|
| V1 | knowledge-governance.yaml 语法合法 | `yq eval '.'` | 通过 |
| V2 | candidate-extraction.md 覆盖 ≥4 种来源 | 手动检查 | Task/Verification/Review/Outcome |
| V3 | review.md 含结构化审核框架 | 手动检查 | 4 维度的检查项 |
| V4 | knowledge/rules.md 不再含占位内容 | grep | 无匹配 |
| V5 | docs 与 rules 描述一致 | 手动对比 | 无矛盾 |

> 详细实施规范待用户发起 P5.5 后在各 impl 子文件中落地。
