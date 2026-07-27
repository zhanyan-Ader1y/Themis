# P6.8 实施索引

本文档是 P6.8（Review Enhancement）的实施总索引。每个子模块的详细设计与实施规范见独立文件。

## 子模块段落

| 段落 | 文件 | 覆盖任务 | 说明 |
|---|---|---|---|
| 评审策略 | impl-01-policies.md | review.yaml | 评审维度、严重级别阈值、通过标准 |
| 评审执行 | impl-02-execution.md | review-execution.md | 结构化评审 Prompt（Spec+Plan+Diff+Evidence→Review） |
| 规则引擎 | impl-03-rules.md | review/rules.md 更新 | 从占位更新为完整评审规则 |
| 文档同步 | impl-04-docs.md | review.md 更新 | WIKI 同步 |

## 目标文件清单

| # | 文件 | 操作 | 所属段落 |
|---|---|---|---|
| 1 | `templates/.themis/core/policies/review.yaml` | 新建 | impl-01 |
| 2 | `templates/.themis/core/templates/review-execution.md` | 新建 | impl-02 |
| 3 | `templates/.themis/core/kernel/review/rules.md` | 更新 | impl-03 |
| 4 | `docs/design/core/kernel/review.md` | 更新 | impl-04 |

## 执行顺序

1. **impl-01**（评审策略）— 策略基础
2. **impl-02**（评审执行）— 依赖 impl-01
3. **impl-03**（规则引擎）— 依赖 impl-01、impl-02
4. **impl-04**（文档）— 依赖 impl-03

## 验证矩阵

| # | 验证项 | 验证方式 | 预期结果 |
|---|---|---|---|
| V1 | review.yaml 定义 ≥5 个评审维度 | `yq eval '.dimensions \| length'` | ≥5 |
| V2 | review.yaml 含 4 种严重级别 | yq 检查 | critical/major/minor/suggestion |
| V3 | review-execution.md 含完整输入声明 | 手动检查 | Spec+Plan+Diff+Evidence |
| V4 | review/rules.md 不再含占位内容 | grep "later Themis" | 无匹配 |
| V5 | docs 与 rules 描述一致 | 手动对比 | 无矛盾 |

> 详细实施规范待用户发起 P6.8 后在各 impl 子文件中落地。
