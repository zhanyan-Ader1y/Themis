# P7.5 实施索引

本文档是 P7.5（Attribution & Outcome）的实施总索引。每个子模块的详细设计与实施规范见独立文件。

## 子模块段落

| 段落 | 文件 | 覆盖任务 | 说明 |
|---|---|---|---|
| 结果策略 | impl-01-policies.md | outcome.yaml | Outcome 分类、记录规则、观察期配置 |
| 归因分析 | impl-02-analysis.md | attribution-analysis.md | 关联模型 + 分析维度 Prompt |
| 规则引擎 | impl-03-rules.md | attribution/rules.md 更新 | 从占位更新为完整归因规则 |
| 文档同步 | impl-04-docs.md | attribution.md 更新 | WIKI 同步 |

## 目标文件清单

| # | 文件 | 操作 | 所属段落 |
|---|---|---|---|
| 1 | `templates/.themis/core/policies/outcome.yaml` | 新建 | impl-01 |
| 2 | `templates/.themis/core/templates/attribution-analysis.md` | 新建 | impl-02 |
| 3 | `templates/.themis/core/kernel/attribution/rules.md` | 更新 | impl-03 |
| 4 | `docs/design/core/kernel/attribution.md` | 更新 | impl-04 |

## 执行顺序

1. **impl-01**（结果策略）— 策略基础
2. **impl-02**（归因分析）— 依赖 impl-01
3. **impl-03**（规则引擎）— 依赖 impl-01、impl-02
4. **impl-04**（文档）— 依赖 impl-03

## 验证矩阵

| # | 验证项 | 验证方式 | 预期结果 |
|---|---|---|---|
| V1 | outcome.yaml 定义 5 种 Outcome 类型 | yq 检查 | success/rework/defect/incident/rollback |
| V2 | attribution-analysis.md 含关联模型 | 手动检查 | Spec→Task→Commit→Run→Deploy→Outcome |
| V3 | attribution-analysis.md 含 ≥3 个分析维度 | 手动检查 | 返工率/缺陷逃逸率/Gate有效性 |
| V4 | attribution/rules.md 不再含占位内容 | grep "later Themis" | 无匹配 |
| V5 | 现有 Attribution import 保持不变 | grep `@import ../attribution/rules.md` | 存在 |
| V6 | docs 与 rules 描述一致 | 手动对比 | 无矛盾 |

> 详细实施规范待用户发起 P7.5 后在各 impl 子文件中落地。
