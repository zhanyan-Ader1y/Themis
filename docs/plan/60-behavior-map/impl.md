# P6 实施索引

本文档是 P6（Behavior Map & Change Localization）的实施总索引。每个子模块的详细设计与实施规范见独立文件。

## 子模块段落

| 段落 | 文件 | 覆盖任务 | 说明 |
|---|---|---|---|
| 三层模型 | `impl-01-model.md` | Schema 定义、存储结构 | L1/L2/L3 的精确字段、关联关系和 Facts-First 规则 |
| 静态分析 | `impl-02-extractor.md` | tree-sitter Adapter 接口 | 支持语言、解析器选择、function inventory + call graph 格式 |
| 变更定位 | `impl-03-localization.md` | Planner 模式、AC → Code 映射 | 只读定位、按需读源码、Traceability 集成 |
| 策略与规则 | `impl-04-policies.md` | context.yaml、rules.md 更新 | Behavior Map 生成策略、新鲜度规则 |
| 文档同步 | `impl-05-docs.md` | WIKI 更新 | context.md、planning.md 文档同步 |

## 目标文件清单

| # | 文件 | 操作 | 所属段落 |
|---|---|---|---|
| 1 | `templates/.themis/workspace/context/architecture/behavior-map/schema.yaml` | 新建 | impl-01 |
| 2 | `templates/.themis/core/adapters/schema/behavior-extractor/interface.md` | 新建 | impl-02 |
| 3 | `templates/.themis/core/policies/context.yaml` | 新建 | impl-04 |
| 4 | `templates/.themis/core/kernel/context/rules.md` | 更新 | impl-04 |
| 5 | `templates/.themis/core/kernel/planning/rules.md` | 更新 | impl-03 |
| 6 | `docs/design/core/kernel/context.md` | 更新 | impl-05 |
| 7 | `docs/design/core/kernel/planning.md` | 更新 | impl-05 |

## 执行顺序

1. **impl-01**（三层模型 Schema）— 数据基础
2. **impl-02**（静态分析接口）— 并行
3. **impl-03**（变更定位）— 依赖 impl-01
4. **impl-04**（策略与规则）— 依赖 impl-01、impl-02
5. **impl-05**（文档）— 依赖 impl-04

## 验证矩阵

| # | 验证项 | 验证方式 | 预期结果 |
|---|---|---|---|
| V1 | schema.yaml 定义 L1/L2/L3 字段 | yq 语法检查 | 通过 |
| V2 | 静态分析接口定义支持 ≥4 种语言 | 手动检查 | Python/TS/Rust/Go |
| V3 | Facts-First 规则在 context.yaml 中有明确字段 | 手动检查 | 存在 |
| V4 | rules.md 不再含占位内容 | grep | 无匹配 |
| V5 | AC → Code → Task 追踪链路完整 | 手动检查 | 所有环节有定义 |
| V6 | docs 与 rules 描述一致 | 手动对比 | 无矛盾 |

## 相关文档

- [模块概述](README.md)
- [Themis 完整工作流程](../../design/workflow.md)
- [P5 需求追问](../50-requirement-questioning/README.md)
