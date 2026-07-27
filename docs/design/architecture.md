# Themis 总体架构

> 规范状态：正式设计。实现状态：部分实现；模板所有权、加载基线、Specification 与 fresh Init 已落地，P5.4 Context Trust、完整状态机、领域 Agent 和多数运行时执行器尚未实现。

## Core 与 Workspace

- `.themis/core/` 是 Themis 管理的能力层：Kernel rules、policies、protocols、templates、adapters 和确定性执行器。
- `.themis/workspace/` 是项目持有的内容与运行数据：manifest、Context、Spec、Plan、状态、runs、evidence、outcomes 和知识治理记录。
- Core 定义能力和控制规则，不保存项目特定事实或工作工件。
- Workspace 保存项目内容，不实现控制逻辑。
- 当前版本只支持 fresh Init，不提供 Core 原地更新或 Workspace/Artifact Schema 转换能力。
- `core.yaml` 只声明固定 supported/writable allow-list；不支持的 Schema 必须 fail closed，不能由 Prompt、脚本或目录复制隐式转换。

Workspace 的目录与数据合同见 [Workspace](workspace/overview.md)。项目事实的双轴可信模型见 [设计治理](governance.md#项目事实可信模型)。

## 三层执行模型

每个运行时模块必须分离确定性策略、语义工作和可重复操作。

### YAML Policy

- YAML 是步骤顺序、阈值、路由条件、Gate、兼容条件、限制、稳定标识符和允许处置的权威声明。
- Prompt 引用 YAML policy，不得复制或独立重新定义确定性逻辑。
- Policy identifier 必须稳定、ASCII-safe，并适合脚本解析。

### Prompt

- Prompt 定义阶段目的、Agent 角色、语义推理、用户交互和脚本结果解读。
- 每个 Prompt 必须列出可用脚本、用途和缺失时的回退方式。
- Domain `rules.md` 必须通过显式 `MUST Read` 指令要求读取所需 Prompt、policy、template 或 checklist。
- 意图发现、追问、方案取舍、Task 拆分、对抗场景、Review 判断和知识候选提取保持 Prompt 驱动。

### Shell

- 生命周期迁移、Gate 执行、格式校验、策略分类、DAG/覆盖校验、文件操作、备份、索引更新和 evidence 骨架等确定性操作应实现为脚本。
- 适用时脚本必须幂等；Agent 消费的接口优先使用机器可读 JSON。
- Agent 调用前必须验证脚本存在，解析真实输出并遵循声明的 fallback；不得发明脚本、跳过必需步骤或伪造结果。
- Shell 只执行可确定验证的结构、状态和副作用，不判断需求是否合理、知识是否有价值或两个事实是否语义等价。

## 执行器职责与位置

- 脚本复杂度按职责和事务边界控制，不按任意行数阈值控制；一个 executor 只拥有一个协议操作或一组不可分割的原子处置。
- 需要不同批准、锁、回滚或 evidence 合同的操作必须拆分；仅共享参数解析或文件读写不构成合并职责的理由。
- Context、Knowledge 等跨生命周期的数据服务执行器位于 `core/bin/`。
- Verification、Review 等生命周期领域 runner 位于 `core/kernel/<domain>/`，与其 `rules.md` 共置。
- 文件位置不改变三层边界：稳定控制仍归 Policy，语义判断仍归 Prompt，确定性执行仍归 Shell。

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
| Orchestrator | 生命周期路由、状态迁移检查、任务调度与恢复 | [Orchestrator](core/kernel/orchestrator.md) |
| Specification | 意图、范围、需求、AC、对抗验证与批准证据 | [Specification](core/kernel/specification.md) |
| Context | 项目事实解析、Catalog、渐进披露、Bundle 与 Signal | [Context](core/kernel/context.md) |
| Planning | Plan、Task、依赖、完成标准、定位与 AC traceability | [Planning](core/kernel/planning.md) |
| Implementation | 一次执行一个依赖就绪 Task，并记录实现 evidence | [Workflow](workflow.md#planned--implemented) |
| Verification | Implementation 后的命令 Gate、失败分类与 durable evidence | [Verification](core/kernel/verification.md) |
| Human Acceptance / Summary | 用户验收决定与接受后的最终交付投影；由 Orchestrator 执行门禁路由 | [Workflow](workflow.md#verified--human-acceptance--summary--archived) |
| Review | Implementation 前审查 Spec、Plan、设计、风险、实施边界与验收方案 | [Review](core/kernel/review.md) |
| Attribution | Spec、Task、commit、run、deployment 与 outcome 的关联 | [Attribution](core/kernel/attribution.md) |
| Knowledge | 候选、事实核验、审核、提升、冲突与废弃 | [Knowledge](core/kernel/knowledge.md) |

领域不得吸收其他领域的所有权。完整阶段顺序和返工路由见 [完整工作流程](workflow.md)。

## Workspace 数据边界

- `context/` 保存正式项目知识；`catalog.yaml` 是 Context Item 的目标唯一持久注册表。
- `specs/` 保存人工或 Agent 编写的生命周期工件；`state/` 保存机器状态，两者不得互相替代。
- `runs/` 描述执行，`evidence/` 支撑声明，`outcomes/` 记录交付后结果。
- `knowledge/` 保存治理过程数据；只有经批准的处置可以写入正式 Context。
- `cache/` 保存可删除重建的索引、Bundle 和派生元数据，不能成为事实源。

具体路径、当前模板状态和 P5.4 目标结构见 [Workspace](workspace/overview.md)。

## Adapter 与能力边界

Adapter 是 Core 与项目工具之间的接口层。当前模板中的 Adapter 目录主要是接口和目录骨架；Git、Command、Testing、Schema、CI 与 Agent Adapter 的完整执行实现尚不存在。任何设计页中的接口示例都不得被解释为当前已安装能力。详见 [Adapters](core/adapters.md) 与 [Protocols](core/protocols.md)。

## 专用 Agent 与命名

- 每个领域使用唯一专用 Agent，避免单一 god Agent 携带无关上下文。
- 专用 Agent 必须遵守领域所有权；确定性操作即使由 Agent 调用，仍由脚本实现。
- Commands、Skills 和专用 Agents 使用 `Themis-` 能力前缀。
- 专用 Agent、Command 与 Skill 执行层属于已确认但未实现的设计；文件不存在时不得假定可用。
