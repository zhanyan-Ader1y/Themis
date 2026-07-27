# 项目

AGENTS.md 优先于 CLAUDE.md 及所有模块计划文档。本文件是仓库级设计契约的权威来源。

Themis 是一个 SDD 框架，将本地 AI 编码系统安装到工程项目中，并实现受治理的项目知识积累。

## 设计治理

- 每项已确认的 Themis 设计规范，都必须在确立或修改该规范的同一次变更中记录到本文件。
- 模块 `README.md`、`impl.md`、Wiki 页面、策略和模板可以包含详细设计，但不得成为仓库级规则的唯一来源。
- 若其他设计文档与本文件冲突，以 `AGENTS.md` 为准并同步修正冲突文档。
- 计划文档不是实现授权。用户必须明确发起计划。
- 计划实施的第一步是在该计划自身目录创建或更新 `docs/plan/<priority>-<slug>/impl.md`，将设计决策、任务拆分、目标文件和验证矩阵落地。
- 在用户确认 `impl.md` 之前，不得修改该计划涉及的实现文件。
- 每个计划拥有自己的目录和自己的 `impl.md`。大型模块设计应在该目录中拆分为聚焦的实施段落。
- `AGENTS.CN.md` 是本契约的中文镜像。每次变更必须同步更新两个文件；若语义不同，以 `AGENTS.md` 为准。

## 仓库文档

- `README.md` 是项目介绍与 Wiki 导航，不是完整的设计规范。
- 将长期文档以模块化 Wiki 形式组织在 `docs/` 下；每个模块一个文件或目录。
- 非模块细节应作为所属模块文档的章节。
- 保持工作流、计划索引、模块 Wiki、模板契约和发布元数据与已实现的行为同步。

## Core 与 Workspace 所有权

- `.themis/core/` 是 Themis 管理的能力内容：kernel 规则、策略、协议、模板、适配器、迁移和确定性执行器。
- `.themis/workspace/` 是项目持有的内容与运行时数据：manifest、Context、Spec、Plan、状态、运行记录、证据、交付结果和知识治理记录。
- Core 定义能力和控制规则，绝不存储项目特定事实或工作产物。
- Workspace 存储项目内容，绝不实现控制逻辑。
- Core 升级绝不复制、替换、删除、恢复或以其他方式修改 `.themis/workspace/`。
- Workspace 或 Artifact Schema 的演进需要显式的、经用户授权的迁移，并具备备份、验证和回滚能力。
- 正式项目知识只有一个权威位置：`workspace/context/`。`workspace/knowledge/` 存储候选、审核、拒绝和归档等治理记录，不构成第二套正式知识库。

## 仓库层级

使用以下已安装项目层级。`templates/.themis/` 下的路径是这些安装位置的源模板，不是第二套运行时层级。

```text
.themis/
├── CLAUDE.themis.md
├── core/
│   ├── kernel/       # 领域规则和路由边界
│   ├── policies/     # 声明式默认值、阈值、Gate 和处置
│   ├── protocols/    # 版本化数据与工具接口契约
│   ├── templates/    # 工件骨架和按需 Prompt 模板
│   ├── adapters/     # 语言及外部工具的规范化接口
│   └── migrations/   # 显式 Workspace/Artifact Schema 转换
└── workspace/
    ├── manifest.yaml # 项目标识、路径、命令、Gate 和 Adapter
    ├── policies/     # Core 契约允许的项目策略覆盖
    ├── context/      # 唯一权威项目知识树
    │   ├── catalog.yaml       # 唯一持久 Context Item 注册表
    │   ├── .abstract.md       # L1 派生导航
    │   ├── .overview.md       # L2 派生导航
    │   ├── architecture/
    │   │   └── behavior-map/ # 派生的 B1/B2/B3 代码行为 Context
    │   ├── domain/           # L3 业务规则、不变量和领域模型
    │   ├── engineering/      # L3 项目工程约定与约束
    │   ├── decisions/        # L3 持久决策及理由
    │   ├── pitfalls/         # L3 已验证陷阱和已知失败模式
    │   ├── glossary/         # L3 项目术语
    │   └── external/         # L3 受治理的外部来源引用
    ├── specs/        # 人工/Agent 编写的 Spec、Plan、Review、Verify 等工件
    ├── state/        # 机器可读迁移、Task/Session 状态、锁和 Context Signal
    ├── runs/         # 执行外壳和持久 Run 裁决
    ├── evidence/     # 支撑 Gate 事实的证明材料或引用
    ├── outcomes/     # 测量到的交付后结果
    ├── knowledge/    # 候选、审核、处置、拒绝和归档治理记录
    └── cache/        # 可丢弃的 Context 索引、Bundle 和派生元数据
```

- 不存在独立的 `workspace/domain/`；权威领域知识属于 `workspace/context/domain/`。
- `workspace/specs/` 保存编写的生命周期工件；`workspace/state/` 保存机器状态。两者不得互相替代。
- Run 描述执行，Evidence 支撑声明，Review 进行独立判断，Outcome 记录真实交付后结果；不得合并为单一工件。
- Cache 不是权威来源，可以重新生成或删除而不改变项目语义。

## 项目事实可信源与生命周期

项目事实只有两个职责不同的可信根：

1. `workspace/context/` 下受治理且有效的条目定义项目“应当表达什么”：业务概念、规则、不变量、术语、持久决策、外部约束和工程约定。
2. 绑定当前 revision 的代码、配置、Schema 和其他版本化实现工件定义项目“现在实现了什么”。

两个可信根不存在全局覆盖顺序。项目意图声明必须引用 Context ID；当前实现声明必须引用仓库相对路径以及 revision 或内容摘要。两者冲突时必须持久化 `context_code_drift` Signal，并保持依赖结论未决，不得静默选择任一来源。Context 在代码不可读时不能证明已经实现；代码在缺少 Context 时不能证明业务意图。

- Spec 定义已批准的期望变化、范围和 Acceptance Criteria；Plan 定义任务组织和证据要求。二者都不是项目事实来源。
- State 只对机器生命周期和 Task 事实具有权威；Run 与 Evidence 只对其记录的命令、观察、Gate 结果和裁决具有权威；Outcome 只对测量到的交付后结果具有权威。
- Core Policy、Protocol、规则、Prompt 和确定性输出定义或执行 Themis 控制契约，不包含项目特定事实。
- Knowledge 记录在批准处置写入已校验 Context Item 之前，只是提案和治理历史。
- 直接外部材料、对话、模型记忆、摘要、搜索排名、Cache 和 Agent 推断都不能独立建立项目事实。外部约束只有作为受治理的 `external_reference` Context Item 后才可信。
- State、Run、Evidence、Review、Attribution 或 Outcome 中可复用的观察，必须经 Context 或当前代码核验并通过 Knowledge Governance 后才能提升。

默认生命周期为：

```text
Draft → Specified → Planned → Implemented → Verified → Reviewed → Archived
```

- 从持久化产物和机器状态路由，而非从对话声明路由。
- 缺失证据不是成功证据。无法访问或不确定的检查不能通过。
- 除非持久化状态或确定性执行器记录了生命周期迁移，否则不得声称迁移已完成。
- 用户批准、Prompt 输出或完成的 Markdown 产物是迁移门禁的证据，而非机器迁移本身。
- 任何代码变更都会使受影响的验证证据失效，需要重新运行相关 Gate。
- Review 是只读的，不能替代命令驱动的 Verification。
- 当 Plan 不足但工作仍在已批准 Spec 范围内时，返回 Planning。
- 当请求或发现的工作超出已批准 Spec 时，返回 Specification。

## 三层执行模型

每个运行时模块必须分离策略、语义工作和确定性操作。

### YAML 策略

- YAML 是步骤顺序、阈值、路由条件、Gate、迁移要求、限制、稳定标识符和允许处置的单一权威声明。
- Prompt 文件引用 YAML 策略，不得重复或独立重新定义确定性策略逻辑。
- 策略标识符必须稳定、ASCII 安全，并适合确定性解析。

### Prompt

- Prompt 模板定义每个步骤的目的、Agent 角色、语义推理、用户交互，以及如何解读策略或脚本结果。
- 每个 Prompt 必须包含 `Available Scripts` 表格，列明脚本路径、用途及缺失时的回退方案。
- 在执行模块之前，其已导入的 `rules.md` 必须对每个必需的 Prompt 和策略文件使用显式的 `MUST Read` 指令。
- 在 Prompt 阶段使用另一个模板或检查清单之前，必须显式要求读取该资产；不得依赖模型记忆或通用知识。
- 创造性和语义工作保持 Prompt 驱动：意图发现、追问、方案分析、Task 拆分、对抗场景生成、评审判断和知识候选提取。

### Shell 脚本

- 可重复的确定性操作必须实现为 Shell 脚本，而非由 Agent 反复执行。
- 脚本候选包括：生命周期迁移、Gate 执行、格式校验、从策略推导的分类、DAG 和覆盖验证、文件操作、备份、迁移、索引更新和 evidence 骨架生成。
- 适用时脚本必须幂等：相同输入必须产生相同结果，且不产生重复副作用。
- 运行时脚本接口在被 Agent 消费时应使用机器可读的 JSON 输入和输出。
- Agent 在调用声明的脚本前必须检查其存在性，解析其真实输出，并在缺失时遵循 Prompt 声明的回退方案。
- Agent 绝不自行发明脚本、跳过必需脚本或伪造脚本输出。

## Kernel 规则与加载

- 项目 `CLAUDE.md` 通过 Init 管理的 import 块加载 `.themis/CLAUDE.themis.md` 和 Core Orchestrator。
- Orchestrator 维护一个由简洁领域 `rules.md` 文件组成的浅层 import 图。
- 已导入的领域规则定义职责、输入、输出、边界和强制的按需资产读取；详细流程属于 Prompt 模板。
- 将已导入的领域 `rules.md` 文件保持在模板契约的 50 行预算内，除非该契约被有意修订。
- 不得全局导入大型 Prompt、策略、检查清单或参考文件。领域规则必须通过显式的 `MUST Read` 指令按需要求它们。
- 每个已实现的生命周期领域必须可从 Orchestrator import 图中访问。
- 在调用 Command、Skill、Agent、适配器或脚本之前，验证其文件或能力是否存在。
- 若所需能力缺失，停留在当前阶段，报告缺失的能力，不得伪造状态、证据或执行结果。

## Core 模块边界

### Kernel 领域

- **Orchestrator** 从持久工件和生效策略选择下一个符合条件的领域。它不执行领域语义、Gate 或迁移，不编辑生命周期工件，也不伪造状态迁移。
- **Specification** 拥有意图、根因、范围、假设、需求、Acceptance Criteria、对抗验证和显式批准证据。它不拆分 Task、不修改代码、不裁决 Gate，也不记录机器迁移。
- **Context** 拥有已验证项目事实、来源、发现、解析、冲突报告、索引和新鲜度。它不决定需求、Plan、实施或知识提升。
- **Planning** 将已批准 Spec 转化为有边界的 Task、依赖、范围、完成标准、证据要求和 AC 可追溯性。它不修改源码、不执行 Task，也不标记 Task 完成。
- **Implementation** 在连续范围锁内一次执行一个依赖已满足的 Task，并记录 Task evidence。其专用 P5.9 Core 资产仍处于计划状态，需该计划获批并实施后才存在。
- **Verification** 执行已配置 Gate，记录精确命令和输出，分类失败，并持久化 Run evidence 和 verdict。它不修改实现代码，也不替代 Review 判断。
- **Review** 对 Spec、Plan、实现 diff 和 Verification 证据进行独立、只读评估。它不执行 Gate、不修复代码，也不批准缺失证据。
- **Attribution** 关联 Spec、Plan、Task、commit、run、部署和测量到的 outcome。它不推断无证据因果、不改写源证据，也不路由生命周期阶段。
- **Knowledge Governance** 管理候选提取、重复/冲突评估、审核、批准、提升、拒绝、修订和废弃。它不建立第二套权威知识库，也不提升未经批准的观察结论。

### Core 基础设施

- **Policies** 声明稳定顺序、阈值、路由条件、Gate、限制和允许处置；不执行操作，也不保存项目事实。
- **Protocols** 对数据形状、引用和 Adapter 接口进行版本化；定义有效数据的结构，不决定语义质量。
- **Templates** 提供初始工件结构和按需 Prompt 流程；模板实例属于 Workspace，不受 Core Upgrade 覆盖。
- **Adapters** 将外部工具和语言事实提取或转换为规范化协议结果；必须报告不支持能力，绝不做领域决策。
- **Migrations** 是转换 Workspace 或 Artifact Schema 的唯一授权机制；需要显式授权、完整备份、确定性验证和回滚。
- **确定性执行器** 负责可重复的解析、校验、分类、文件操作、索引、Gate 执行和状态变更；消费策略、输出机器可读结果，不进行开放式语义判断。

## Workspace 模块边界

- **Manifest** 声明项目身份、根路径、受管路径、已配置命令、Gate、Context 入口、Adapter 和允许的策略覆盖；它是配置，不是执行历史。
- **Workspace Policies** 只能在声明的覆盖规则内特化 Core 默认值；不得削弱不可变的安全、所有权、批准、迁移或证据要求。
- **Context** 是唯一权威项目知识树。其分类为 `architecture/`、`domain/`、`engineering/`、`decisions/`、`pitfalls/`、`glossary/` 和 `external/`；这些是知识分类，不是控制模块。正式知识使用 L3 Context Item，目录级 L1 `.abstract.md` 和 L2 `.overview.md` 是可追溯的 `derived_navigation` 投影，不得引入独立事实。
- **Context Catalog** 位于 `workspace/context/catalog.yaml`，是 Context Item 身份、路径、分类、Scope、authority、状态、来源、摘要、新鲜度、依赖和 supersession 的唯一持久注册表。其他索引、摘要和解析 Bundle 均为派生且可重建。
- **Specs** 保存编写的生命周期工件及附件。工件内容是人工/Agent 编写的意图与证据；机器生命周期状态仍属于 State。
- **State** 保存机器可读迁移、活动引用、Task/Session 状态、重试、锁，以及持久的 Context 缺失、冲突、过期和漂移 Signal。State 必须引用源工件与证据，不得成为并行需求库或知识库。
- **Runs** 保存一次执行的输入、生效策略快照、Gate 结果和 verdict 外壳。没有 Evidence，Run 本身不能证明正确性。
- **Evidence** 保存或引用命令输出、报告、日志、评审、漂移记录和部署证明。Evidence 是不可变的支撑材料，不作出其所支持的裁决。
- **Outcomes** 记录成功、返工、逃逸缺陷、事故和回滚等测量到的交付结果；与交付前 Verification verdict 相互独立。
- **Knowledge** 保存追加式治理流程记录。只有经批准的提升才能把正式知识写入 Context。
- **Cache** 保存可丢弃的索引、解析后的 Context 快照和派生元数据。Cache 丢失不得破坏权威状态或项目知识。

## 领域边界

### Specification

- Specification 拥有意图、范围、假设、需求、Acceptance Criteria、对抗验证和显式批准证据。
- 每个行为变更请求都需要 Spec；低复杂度可使用较短路径，但不得跳过对抗验证。
- P5 使用五个阶段：Step 0 意图发现、Step 1 范围评估、Step 2 上下文收集、Step 3 设计收敛、Step 4 对抗验证。
- P5 创建并完成 Draft Spec。必须保持 `status: draft`；只有确定性状态执行器才能记录 `draft → specified`。
- 每个活动 Spec 是一个配对工件：`spec.yaml` 是唯一权威语义源，`spec.md` 是确定性生成、可重建的人类审阅投影。
- Agent、Planning、状态转换与 Verification 必须消费 `spec.yaml` 中的稳定对象和引用；Markdown 标题与正文永远不是机器证据。
- `spec.md` 必须由已安装的 Spec 执行器生成并检查漂移；不得把 Markdown 手改反向同步到 `spec.yaml`。
- Acceptance Criteria 和对抗发现需要稳定标识符。

### Context

- Context 拥有受治理的项目含义、来源、Catalog 注册、渐进发现、解析、冲突报告和新鲜度；不决定需求、Plan、实施或知识提升。
- 知识分类与披露深度是正交维度。Context 使用 `L1 Abstract → L2 Overview → L3 Detail`；L1/L2 是带引用的导航投影，只有有效 L3 Item 或 current 的代码派生事实可以独立支撑项目事实声明。
- Spec 相关业务知识查找先使用显式 Context ID，再按 bounded context、实体、操作和状态过滤 `domain/`，依次读取 L1、相关 L2 和选定 L3；随后按需查找 Glossary、Decisions、External、Pitfalls、Architecture、Behavior Map 和当前代码。
- Context Resolution 生成可丢弃且可追溯的 Context Bundle，并在 State 下持久化 missing、stale、Context conflict 或 Context/code drift Signal。Bundle、摘要、搜索排名和 Cache 索引都不是第三个事实源。
- AI 可提出知识候选，但未经治理审批不得将观察性结论直接写入权威 Context。
- Behavior Map 是代码派生 Context，使用 `B1 System`、`B2 Behavior Unit` 和 `B3 Evidence`，避免与 Context 披露层冲突。只有 current 且绑定 revision 的 B3 Anchor 可以支撑代码事实声明；其他 Map 内容均为导航，必须回退源码检查。

### Behavior Map 与变更定位

P6 是已确认的设计契约，但在其自身 `impl.md` 获批并完成实施前仍属于未实现能力。

- Behavior Map 是 Context 治理拥有的、可重新生成的派生 Context，只能存储在 `workspace/context/architecture/behavior-map/` 下；它不是人工提升的 Knowledge，也不是第二套源码权威。
- 输入包括限定范围的源码、配置、Schema、路由、构建元数据、manifest include/exclude 规则、源码 revision 或内容摘要，以及真实 Adapter 能力结果。变更定位还读取已批准 AC 和相关 Context。
- 生成模型使用 `B1 System` 描述边界和生命周期路径，`B2 Behavior Unit` 描述职责、输入、输出、状态和关系，`B3 Evidence` 描述绑定 revision 的文件、符号、分支、副作用、路径和 Anchor。B1/B2 是派生导航；只有 current 且受支持的 B3 事实可以支撑实现声明。
- 生成工件还包括符号/函数清单、规范化关系或调用图、锚点索引，以及 Schema、源码 revision、Adapter 版本、语言覆盖、置信度、生成时间和新鲜度元数据。
- 每条事实性自然语言声明必须引用稳定 evidence-anchor ID。锚点记录仓库相对路径、符号或工件类型、源码范围、源码 revision 或摘要、提取方法、关系类型和置信度。行号和片段只用于导航，不构成持久身份。
- 无支持的声明必须标记为 `hypothesis` 或 `unknown`，不得标记为事实。语言 Adapter 必须区分解析、符号清单、关系提取、调用图和 Schema/SQL lineage，不能笼统声称“支持某语言”。
- 新鲜度使用 `current`、`stale`、`unknown` 或 `unsupported`。锚点或相关依赖变化会使受影响条目失效；无法计算影响时标记 `unknown`。P6 首版采用手动重生成和过期标记，不承诺自动增量同步。
- Map 缺失、过期、未知或不支持时必须回退到直接源码检查；消费者不得把低置信度推断呈现为已验证项目事实。
- Change Localization 生成建议性链路 `AC → behavior unit → candidate file/symbol → Task → Gate`。每个候选记录角色、理由、锚点 ID、源码 revision、置信度和未决区域。
- Planning 只读消费定位结果，并继续拥有 Task 范围；定位不能修改代码、扩大 Plan 或标记工作完成。Verification 可使用锚点寻找相关检查，但锚点不是 Gate evidence 或 verdict。
- 支持范围内的 Adapter 提取必须确定性执行；LLM 辅助的行为归类和解释属于保留来源的语义步骤。对不支持的动态分派、反射、生成代码或仅二进制行为必须报告未知，不得编造。
- P6 不包含交互式 UI、运行时行为的保证解析、自动 Plan/代码修改、Gate verdict 生成或自动全量重同步。

### Planning

- Planning 将已批准 Spec 转化为有边界的 Task、依赖关系、完成标准、证据要求和 AC 可追溯性。
- Planning 不得修改源码或将 Task 标记为完成。
- 每个行为变更 Task 必须明确其所覆盖的 AC、范围、依赖、预期证据和完成条件。

### Implementation

- Implementation 一次执行一个依赖已满足的已规划 Task。
- 必须仅加载当前 Task 的 AC、约束、Context 和相关代码。
- 将 Plan 声明的文件和行为边界视为连续范围锁；在做出范围外变更前检查并停止。
- 若 Plan 不足但变更仍在 Spec 内，返回 Planning。若超出 Spec，返回 Specification。
- 记录 Task evidence，包括 Task ID、覆盖的 AC、变更文件、变更摘要、偏差和完成证据。
- Implementation 不拥有 Spec 或 Plan 的修改权、Verification 的裁决权或生命周期状态迁移权。
- 不得将无关重构或多个 Task 混合到一个实施单元中。

### Verification

- Verification 拥有命令驱动的 Gate 事实、失败分类和持久运行证据；不修改实现代码。
- 从 `workspace/manifest.yaml` 和生效策略中读取配置的命令和 Gate。
- 当 manifest 条目为 `null` 时不得发明命令；按策略报告不可用的 Gate。
- 在 Workspace 运行记录和证据中保存精确命令、输出、状态和不可用检查。

### Review

- Review 独立评估 Spec、Plan、实现 diff 和 Verification 证据。
- Review 对实现代码是只读的。
- 缺失证据产生 blocked 或 inconclusive 结果，绝不产生 approval。
- Review 发现必须区分严重级别并链接到具体证据。

### Attribution 与 Outcomes

- Attribution 记录 Spec、Plan、Task、commit、run、部署和 outcome 之间的可追溯关联。
- 必须区分测量到的相关性与因果解释，不得改写源证据。

### Knowledge Governance

- 知识候选可来自实施经验、Verification 失败、Review 发现和交付结果。
- 提升、拒绝、修订、去重、冲突解决和废弃需要受治理的决策。
- AI 可结构化并建议候选；正式 Context 提升需要人工或策略授权的审批。

## 专用 Agent 与命名

- 每个领域使用一个唯一的专用 Agent，避免 god Agent 携带过多或无关上下文。
- 领域 Agent 必须尊重领域所有权，不得吸收分配给其他 Agent 的职责。
- 确定性操作即使由专用 Agent 调用，也仍保持为脚本。
- Command、Skill 和专用 Agent 使用 `Themis-` 能力前缀。

## Init、Upgrade 与 Migration

- Init 仅校验 Bash、Git 和 mikefarah/yq v4。这些检查仅限 Init 使用，Upgrade 或已安装的 SDD 运行流程不得 source 或调用。
- Init 安装 `.themis`，配置 Workspace manifest，并向目标项目根 `CLAUDE.md` 追加可逆的受管 import 块。
- `.themis/CLAUDE.themis.md` 是容器化指引。不得在已安装项目中创建根级 `CLAUDE.themis.md`。
- Upgrade 仅替换 `.themis/workspace/` 之外的 Themis 管理内容，并保持项目指引字节不变。
- Migration 与 Upgrade 分离，是唯一允许转换 Workspace 或 Artifact Schema 的机制。
- Migration 需要显式授权、兼容描述符、完整备份、确定性验证和回滚能力。

## 脚本文档

- 每个 Shell 脚本必须包含中文注释，解释其用途、操作边界及非显而易见的行为原因。
- 公共函数和主要的验证或控制流段落必须记录其功能、适用时的预期输入或输出，以及该行为的必要性。
- 实现变更时保持注释准确。
- 保持 Bash 3.2 兼容性以保证仓库脚本可移植性，除非某个计划明确变更了运行时契约。
- 对修改的 Shell 脚本运行 Bash 语法检查和 ShellCheck。

## 验证要求

- 每当 Core 契约新增必需文件、标识符、标题、策略形状、import 或行数预算规则时，同步扩展确定性模板检查和隔离回归夹具。
- 在 Core 变更后运行受影响的模板、Init、Upgrade、Migration 和模块特定套件。
- 实现工作完成后执行 `git diff --check` 并检查最终工作树。
- 未实际观察到输出，不得声称某项检查通过。