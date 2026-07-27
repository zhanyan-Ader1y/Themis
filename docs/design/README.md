# Themis 设计规范

本目录是**已确认 Themis 设计规范的唯一权威来源**。设计规则只能在 `docs/design/**` 中定义；其他文档可以链接、解释实施背景或记录历史，但不得成为规则的唯一来源，也不得覆盖本目录中的规范。

## 文档权威

| 位置 | 定位 |
|---|---|
| `docs/design/**` | 正式设计规范与长期契约 |
| `AGENTS.md`、`AGENTS.CN.md` | 仓库 Agent 工作约定与设计入口 |
| `docs/plan/**` | 提案、实施设计、任务与执行历史，非规范来源 |
| `docs/analysis/**` | 审计与分析快照，非规范来源 |
| `docs/references/**` | 外部参考材料，非规范来源 |
| `CHANGES.md` | 发布历史，非规范来源 |
| `templates/`、`bin/`、`tests/` | 当前实现事实与验证证据 |

设计规范描述 Themis **应当如何工作**；代码、模板、结构化工件、测试和实际命令输出证明当前 checkout **实际上能做什么**。两者不一致时必须明确记录设计—实现漂移，不得仅凭设计文档声称尚不存在的能力已经可用。

## 状态语义

每篇设计页必须标明实现状态：

- **已实现**：存在对应实现，并有可运行的验证证据。
- **部分实现**：部分规则、模板、Prompt、脚本或目录已落地，但完整运行能力尚不存在。
- **已确认但未实现**：规则已经确认，可以约束后续实现，但当前没有对应执行能力。

未确认的方案继续保留在 `docs/plan/**`，不得标记为正式设计。计划中的设计只有在用户确认并同步到本目录后，才成为长期规范。

## 设计导航

### 治理与架构

| 文档 | 内容 |
|---|---|
| [设计治理](governance.md) | 规则确认、事实优先级、证据、冲突与历史文档治理 |
| [总体架构](architecture.md) | Core/Workspace、三层执行模型、加载结构、领域边界与能力命名 |
| [完整工作流程](workflow.md) | 生命周期、阶段门禁、返工路由、Outcome 与知识治理 |
| [Init 运行环境](runtime-environment.md) | Init 专用 Bash、Git 与 mikefarah/yq v4 契约 |

### Core Kernel

| 模块 | 设计页 |
|---|---|
| Orchestrator | [生命周期路由与状态迁移](core/kernel/orchestrator.md) |
| Specification | [需求、AC 与 Draft Spec](core/kernel/specification.md) |
| Context | [项目事实、来源与新鲜度](core/kernel/context.md) |
| Planning | [Plan、Task、依赖与追踪](core/kernel/planning.md) |
| Verification | [Gate、证据与 Verdict](core/kernel/verification.md) |
| Review | [只读评审与结果合同](core/kernel/review.md) |
| Attribution | [追踪关联与 Outcome 分析](core/kernel/attribution.md) |
| Knowledge | [知识候选、审核、提升与废弃](core/kernel/knowledge.md) |

### Core 基础设施与 Workspace

| 模块 | 设计页 |
|---|---|
| Protocols | [数据与接口合同](core/protocols.md) |
| Policies | [默认策略与覆盖规则](core/policies.md) |
| Templates | [工件与 Prompt 模板](core/templates.md) |
| Adapters | [外部工具适配边界](core/adapters.md) |
| Migrations | [显式 Schema 迁移](core/migrations.md) |
| Workspace | [项目内容、工件与运行数据](workspace/overview.md) |

## 变更规则

1. 确认或修改长期设计时，在同一次变更中更新本目录的所属页面。
2. 不在 `AGENTS*`、计划、模板、Prompt、策略或变更日志中维护第二份设计正文；这些位置只保留必要摘要和规范链接。
3. 同一规则只在一个设计页完整定义，其他页面通过链接引用。
4. 设计页必须区分当前实现与目标能力；更新实现时同步更新相应状态和证据链接。
5. 历史计划保留原始决策过程。规则被替代时添加 superseded 注记并链接当前规范，不把历史改写成当前设计。
6. 旧 Wiki 路径只作为兼容指针保留，不得继续写入设计内容。
