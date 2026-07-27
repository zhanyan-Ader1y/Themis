# Themis 文档

本目录汇总 Themis 的正式设计、实施计划、分析记录和外部参考。

## 文档权威

只有 [`design/`](design/) 可以定义已确认的 Themis 设计规范。其他目录用于执行、分析或历史记录；发生冲突时按 [设计治理](design/governance.md) 处理。

| 分类 | 定位 | 入口 |
|---|---|---|
| Design | 正式设计规范与长期契约 | [设计规范](design/README.md) |
| Plan | 提案、实施设计、任务和执行历史，非规范来源 | [实施计划](plan/README.md) |
| Analysis | 审计与分析快照，非规范来源 | [Loading Chain Audit](analysis/loading-chain.md) |
| References | 外部方法和参考材料，非规范来源 | [`references/`](references/) |

## 常用设计入口

- [设计治理](design/governance.md)
- [总体架构](design/architecture.md)
- [完整工作流程](design/workflow.md)
- [Core 与 Workspace 模块索引](design/README.md#设计导航)
- [Init Environment](design/runtime-environment.md)

## 兼容路径

以下旧路径仅保留短链接，用于兼容历史计划、变更日志和外部引用：

- `workflow.md`
- `runtime-environment.md`
- `core/**`
- `workspace/overview.md`

不要在兼容文件中新增或修改设计规则；直接编辑 `design/**` 下的所属页面。
