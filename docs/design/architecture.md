# Themis 总体架构

> 规范状态：正式设计。实现状态：部分实现；模板所有权、加载基线、Specification、Init、Upgrade 与 Migration 执行入口已落地，完整状态机、领域 Agent 和多数运行时执行器尚未实现。

## Core 与 Workspace

- `.themis/core/` 是 Themis 管理的能力层：Kernel rules、policies、protocols、templates、adapters、migrations 和确定性执行器。
- `.themis/workspace/` 是项目持有的内容与运行数据：manifest、Context、Spec、Plan、状态、runs、evidence、outcomes 和知识治理记录。
- Core 定义能力和控制规则，不保存项目特定事实或工作工件。
- Workspace 保存项目内容，不实现控制逻辑。
- Core Upgrade 不得复制、替换、删除、恢复或以其他方式修改 `.themis/workspace/`。
- Workspace 或 Artifact Schema 只能通过显式、经用户授权且可回滚的 [Migration](core/migrations.md) 演进。

Workspace 的完整目录和数据合同见 [Workspace 设计](workspace/overview.md)。

## 三层执行模型

每个运行时模块必须分离确定性策略、语义工作和可重复操作。

### YAML Policy

- YAML 是步骤顺序、阈值、路由条件、Gate、迁移条件、限制、稳定标识符和允许处置的权威声明。
- Prompt 引用 YAML policy，不得复制或独立重新定义确定性逻辑。
- Policy identifier 必须稳定、ASCII-safe，并适合脚本解析。

### Prompt

- Prompt 定义阶段目的、Agent 角色、语义推理、用户交互和脚本结果解读。
- 每个 Prompt 必须列出可用脚本、用途和缺失时的回退方式。
- Domain `rules.md` 必须通过显式 `MUST Read` 指令要求读取所需 Prompt、policy、template 或 checklist。
- 意图发现、追问、方案取舍、Task 拆分、对抗场景、Review 判断和知识候选提取保持 Prompt 驱动。

### Shell

- 生命周期迁移、Gate 执行、格式校验、策略分类、DAG/覆盖校验、文件操作、备份、迁移、索引更新和 evidence 骨架等确定性操作应实现为脚本。
- 适用时脚本必须幂等；Agent 消费的接口优先使用机器可读 JSON。
- Agent 调用前必须验证脚本存在，解析真实输出并遵循声明的 fallback；不得发明脚本、跳过必需步骤或伪造结果。

## 加载结构

- 项目根 `CLAUDE.md` 通过 Init 管理的 import 块加载 `.themis/CLAUDE.themis.md` 和 Core Orchestrator。
- Orchestrator 维护由简洁领域 `rules.md` 组成的浅层 import 图。
- 常驻 rules 只定义职责、输入、输出、边界和强制的按需读取；详细流程属于 Prompt、policy、template 或 checklist。
- 不全局导入大型 Prompt、policy、checklist 或 reference。
- 每个已实现生命周期领域必须可从 Orchestrator import 图到达。
- 调用 Command、Skill、Agent、Adapter 或脚本前必须验证能力存在；缺失时停留在当前阶段并报告，不得伪造状态或证据。

## 领域边界

| 领域 | 所有权 | 详细设计 |
|---|---|---|
| Orchestrator | 生命周期路由、迁移检查、任务调度与恢复 | [Orchestrator](core/kernel/orchestrator.md) |
| Specification | 意图、范围、需求、AC、对抗验证与批准证据 | [Specification](core/kernel/specification.md) |
| Context | 已验证项目事实、来源、冲突与新鲜度 | [Context](core/kernel/context.md) |
| Planning | Plan、Task、依赖、完成标准与 AC traceability | [Planning](core/kernel/planning.md) |
| Implementation | 一次执行一个依赖就绪 Task，并记录实现 evidence | [Workflow](workflow.md#planned--implemented) |
| Verification | 命令驱动的 Gate 事实、失败分类与 durable evidence | [Verification](core/kernel/verification.md) |
| Review | 只读检查 Spec、Plan、diff 与 Verification evidence | [Review](core/kernel/review.md) |
| Attribution | Spec、Task、commit、run、deployment 与 outcome 的关联 | [Attribution](core/kernel/attribution.md) |
| Knowledge | 候选、审核、提升、冲突、去重与废弃 | [Knowledge](core/kernel/knowledge.md) |

领域不得吸收其他领域的所有权。完整阶段顺序和返工路由见 [完整工作流程](workflow.md)。

## Adapter 与能力边界

Adapter 是 Core 与项目工具之间的接口层。当前模板中的 Adapter 目录主要是接口和目录骨架；Git、Command、Testing、Schema、CI 与 Agent Adapter 的完整执行实现尚不存在。任何设计页中的接口示例都不得被解释为当前已安装能力。详见 [Adapters](core/adapters.md) 与 [Protocols](core/protocols.md)。

## 专用 Agent 与命名

- 每个领域使用唯一专用 Agent，避免单一 god Agent 携带无关上下文。
- 专用 Agent 必须遵守领域所有权；确定性操作即使由 Agent 调用，仍由脚本实现。
- Commands、Skills 和专用 Agents 使用 `Themis-` 能力前缀。
- 专用 Agent、Command 与 Skill 执行层属于已确认但未实现的设计；文件不存在时不得假定可用。
