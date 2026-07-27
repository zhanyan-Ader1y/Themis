# P6.5 实施索引

本文档是 P6.5（验证增强）的实施总索引。每个子模块的详细设计与实施规范见独立文件。

## 子模块段落

| 段落 | 文件 | 覆盖任务 | 说明 |
|---|---|---|---|
| 验证策略 | impl-01-policies.md | verification.yaml | Gate 类型、失败分类规则、对抗检查维度 |
| 失败分类 | impl-02-classification.md | failure-classification.md | 6 种失败分类的判定 Prompt |
| 规则引擎 | impl-03-rules.md | verification/rules.md 更新 | 从占位内容更新为完整验证规则 |
| 文档同步 | impl-04-docs.md | verification.md 文档更新 | WIKI 同步 |

## 目标文件清单

| # | 文件 | 操作 | 所属段落 |
|---|---|---|---|
| 1 | `templates/.themis/core/policies/verification.yaml` | 新建 | impl-01 |
| 2 | `templates/.themis/core/templates/failure-classification.md` | 新建 | impl-02 |
| 3 | `templates/.themis/core/kernel/verification/rules.md` | 更新 | impl-03 |
| 4 | `docs/design/core/kernel/verification.md` | 更新 | impl-04 |

## 执行顺序

1. **impl-01**（验证策略）— 策略基础
2. **impl-02**（失败分类）— 依赖 impl-01
3. **impl-03**（规则引擎）— 依赖 impl-01、impl-02
4. **impl-04**（文档）— 依赖 impl-03

## 验证矩阵

| # | 验证项 | 验证方式 | 预期结果 |
|---|---|---|---|
| V1 | verification.yaml 定义 3 种 Gate 类型 | `yq eval '.'` | blocking/warning/info |
| V2 | verification.yaml 含 6 种失败分类 | `yq eval '.failure_categories \| length'` | 6 |
| V3 | failure-classification.md 每类有判定 Prompt | 手动检查 | 全部存在 |
| V4 | verification/rules.md 不再含占位内容 | grep | 无匹配 |
| V5 | docs 与 rules 描述一致 | 手动对比 | 无矛盾 |

> 详细实施规范待用户发起 P6.5 后在各 impl 子文件中落地。
