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

## 事实来源与生命周期

按以下优先级使用权威来源：

1. 当前代码、配置、结构化产物和已观察到的命令输出。
2. 持久化的 Workspace 状态和已记录的证据。
3. Core 策略、协议和确定性工具输出。
4. 已导入的规则和 Prompt 指引。
5. 对话记忆或 Agent 推断。

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

## 领域边界

### Specification

- Specification 拥有意图、范围、假设、需求、Acceptance Criteria、对抗验证和显式批准证据。
- 每个行为变更请求都需要 Spec；低复杂度可使用较短路径，但不得跳过对抗验证。
- P5 使用五个阶段：Step 0 意图发现、Step 1 范围评估、Step 2 上下文收集、Step 3 设计收敛、Step 4 对抗验证。
- P5 创建并完成 Draft Spec。必须保持 `status: draft`；只有确定性状态执行器才能记录 `draft → specified`。
- Acceptance Criteria 和对抗发现需要稳定标识符。

### Context

- Context 拥有已验证的项目事实、来源、冲突报告和新鲜度；不决定需求或实施方案。
- AI 可提出知识候选，但未经治理审批不得将观察性结论直接写入正式 Context。
- Behavior Map 是派生 Context 数据，需要代码证据锚点。缺失 Map 时回退到源码检查，但不得将低置信度推断作为事实呈现。

### Planning

- Planning 将已批准 Spec 转化为有边界的 Task、依赖关系、完成标准、证据要求和 AC 可追溯性。
- Planning 不得修改源码或将 Task 标记为完成。
- 每个行为变更 Task 必须明确其所覆盖的 AC、范围、依赖、预期证据和完成条件。

### Implementation

- Implementation 一次执行一个依赖已满足的已规划 Task。
- 必须仅加载当前 Task 的 AC、约束、Context 和相关代码。
- 将 Plan 声明的文件和行业边界视为连续范围锁；在做出范围外变更前检查并停止。
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