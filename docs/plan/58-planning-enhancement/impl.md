# P5.8 实施索引

本文档是 P5.8（Planning Enhancement）的实施总索引。每个子模块的详细设计与实施规范见独立文件。

## 子模块段落

| 段落 | 文件 | 覆盖任务 | 说明 |
|---|---|---|---|
| 计划策略 | impl-01-policies.md | planning.yaml | Task 类型、粒度规则、DoD 模板、校验规则 |
| 计划生成 | impl-02-generation.md | plan-generation.md | Spec → Task 拆分 → 依赖 DAG 的生成 Prompt |
| 计划校验 | impl-03-validation.md | plan-validation.md | AC 覆盖、依赖、粒度、可行性 5 维校验 Prompt |
| 规则引擎 | impl-04-rules.md | planning/rules.md 更新 | 从占位更新为完整计划规则 |
| 文档同步 | impl-05-docs.md | planning.md 更新 | WIKI 同步 |

## 目标文件清单

| # | 文件 | 操作 | 所属段落 |
|---|---|---|---|
| 1 | `templates/.themis/core/policies/planning.yaml` | 新建 | impl-01 |
| 2 | `templates/.themis/core/templates/plan-generation.md` | 新建 | impl-02 |
| 3 | `templates/.themis/core/templates/plan-validation.md` | 新建 | impl-03 |
| 4 | `templates/.themis/core/kernel/planning/rules.md` | 更新 | impl-04 |
| 5 | `docs/core/kernel/planning.md` | 更新 | impl-05 |

## 执行顺序

1. **impl-01**（计划策略）— 策略基础
2. **impl-02**（计划生成）— 并行
3. **impl-03**（计划校验）— 并行
4. **impl-04**（规则引擎）— 依赖 impl-01、impl-02、impl-03
5. **impl-05**（文档）— 依赖 impl-04

## 验证矩阵

| # | 验证项 | 验证方式 | 预期结果 |
|---|---|---|---|
| V1 | planning.yaml 定义 ≥4 种 Task 类型 | `yq eval '.task_types \| length'` | ≥4 |
| V2 | plan-generation.md 含依赖构建规则 | 手动检查 | 存在 |
| V3 | plan-validation.md 含 5 维检查表 | 手动检查 | 5 维度完整 |
| V4 | planning/rules.md 不再含占位内容 | grep "later Themis" | 无匹配 |
| V5 | docs 与 rules 描述一致 | 手动对比 | 无矛盾 |

> 详细实施规范待用户发起 P5.8 后在各 impl 子文件中落地。
