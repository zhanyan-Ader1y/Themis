# Themico 顶层设计 Spec

## 1. 权威范围

Themico 是一个独立、本地优先、无内置模型的受治理知识库，用于保存、修订、发布和渐进读取供 Human 与 Agent 共同使用的项目知识。

本文是 Themico 跨主题设计的唯一 current authority。本文确认产品定位、核心不变量、范围边界和主题责任；同目录下的八个 reference 细化单一主题，必须由本文索引解释，不能独立扩张范围、形成第二份 Spec，或覆盖其他 reference 的主题责任。

完整 Themico 目标与实施交付门槛必须分开解释。[首个可用交付范围](2026-07-29-themico-design/first-usable-delivery.md) 是本文授权的实施切片，只收敛首先必须形成的端到端闭环，不删除或改写本文及其他主题 reference 已确认的完整生命周期、关系、投影与集成边界。

## 2. 产品定位

Themico 解决的是受治理项目知识的长期权威问题，而不是通用 Agent Memory、文档 RAG 或对话历史保存：

- Human 能直接审阅完整知识及其来源、授权和历史；
- Agent 能先发现候选，再按需读取更深内容；
- 正式知识只能由确定性机器合同和明确 Human 授权共同发布；
- 权威记录与可重建查询投影严格分离；
- 核心能力不依赖外部知识库、模型服务、Embedding、向量数据库或 SQLite。

OpenViking 等外部项目只能作为设计经验来源，不构成 Themico 的架构、运行时或存储后端。

## 3. 已确认的核心不变量

### 3.1 原子记录与聚合边界

Knowledge Record 是独立治理、修订、引用、失效和替代的最小原子单位。每条记录具有稳定身份、可追溯 revision、生命周期、来源与授权、类型化关系，以及 L1、L2、L3 三层表达。

项目、领域、架构单元和 feature 只是记录的 scope 与可重建聚合维度，不是新的知识层级。任何聚合 view 都只能索引 current record ID，并通过该 ID 定位其绑定的 L1；`views.json` 不嵌入 L1 bytes，也不拥有独立叙事或语义权威。

详见 [Knowledge Record 与聚合模型](2026-07-29-themico-design/knowledge-model.md)。

### 3.2 类型与 Zone 闭集

首批知识类型固定为：

- `design_decision`；
- `development_standard`；
- `development_experience`。

Zone 固定为 `project_knowledge` 与 `project_experience`。`design_decision`、`development_standard` 只能进入 `project_knowledge`；`development_experience` 只能进入 `project_experience`。

新 candidate 的类型由 Agent 提案、Human 明确确认、CLI 固化。类型一旦固化不得原地改型；跨类型提炼必须创建新 candidate 或 record，并通过 `derived_from` 关系连接原记录。

详见 [知识类型与 L1/L2/L3 合同](2026-07-29-themico-design/types-and-layers.md)。

### 3.3 L1/L2/L3 仅表示读取深度

L1、L2、L3 是同一条 Knowledge Record 的读取深度，不表示项目、领域、架构、组件或 feature 层级：

- L1 用于发现和确定性筛选；
- L2 用于理解、规划和判断是否升级读取；
- L3 保存可由 Human 直接审阅的完整中文 Markdown 语义。

三种类型共享治理外壳和 L1。L2 共享公共头部并使用类型化 payload；L3 使用各类型固定 Markdown 章节。只有由 `themico` CLI 实际读取或写出的机器数据使用 JSON；L3、Skill 和产品语义合同使用中文 Markdown。

详见 [知识类型与 L1/L2/L3 合同](2026-07-29-themico-design/types-and-layers.md)。

### 3.4 Agent、Human 与 CLI 分权

- Agent 只能产生 proposal、candidate content、relevance decision、semantic assessment 和 explanation；
- Human 负责类型确认，以及 publication、supersede、deprecate、archive 的授权；
- `themico` Go CLI 是唯一 machine authority，负责结构、枚举、身份、revision、digest、source binding、registry、currentness、预算、关系完整性、可见提交、失效、重建和事实轨迹。

CLI 不判断自然语言内容是否正确，也不声称验证 Human 的真实身份；它只校验授权工件的结构，以及授权与确切 prepare identity 和 digest 的绑定。Agent 和 Human 的自然语言判断都不能自行写成 published、current 或 valid authority。

详见 [Agent、Human 与 CLI 权威边界](2026-07-29-themico-design/agent-cli-authority.md)。

### 3.5 本地存储与可见提交

正式 source 首批只支持 repository/root-relative 本地文件。CLI 直接读取 source bytes、校验路径 containment，并保存 digest 绑定；URL 抓取和未物化外部来源不在当前核心范围。

Themico 安装到仓库根目录的 `.themico/`，并把控制面与工作区分开：`core/` 保存 Skill references 与 type factories，`workspace/` 保存受治理 store。宿主发现入口 `SKILL.md` 留在 `.claude/skills/themico/`，只负责转发。

`.themico/workspace/` 使用不可变 payload 与 generation-directory commit。只有完整、合法且连续连接的新 generation directory 才能改变可见 current state；中断残留和未被合法 generation 引用的对象不构成 current authority。历史 revision 必须保留。store 的提交不修改 `core/`。

所有 machine JSON 使用 UTF-8，拒绝未知字段、重复键和浮点数；digest 使用项目定义的 canonical JSON，并带 `sha256:` 前缀。

详见 [存储、来源绑定与生命周期](2026-07-29-themico-design/storage-and-lifecycle.md)。

### 3.6 渐进查询与投影

查询固定为确定性 L1 过滤、Agent 相关性选择、受 byte budget 约束的 L2/L3 读取和有限关系扩展。CLI 只记录可重放的过滤、选择、读取、预算和关系事实；Agent 的语义解释是独立的非权威输出。

L1 和 L2 是绑定具体 record revision 的独立不可变投影；索引和聚合 view 可以从 current manifest、record scope 及现存有效 L1/L2 重建。投影失效不能改变记录权威；核心重建不得从 L3 自动生成新的 L1/L2 语义摘要，缺失 L1/L2 时必须另行形成并治理投影候选。

详见 [渐进查询、预算与投影](2026-07-29-themico-design/query-and-projection.md)。

### 3.7 单一 Skill 与 registry-selected factory

当前核心只定义一个公共 `themico` Skill。每次操作加载一个 operation reference；处理正式记录时，根据 CLI 返回的已固化 `knowledge_type`，通过 registry 选择且只选择一个 type factory。Skill 或 Agent 不得根据标题、摘要或正文重新解释正式类型。

详见 [Skill 与 reference 加载合同](2026-07-29-themico-design/skill-and-references.md)。

## 4. 生命周期原则

正式知识默认不物理删除：

- publish 创建 active record；
- supersede 原子地发布替代记录，并把旧 current revision 变为 superseded；
- deprecate 创建保留原内容的新状态 revision；
- archive 创建保留历史与内容的新状态 revision。

项目经验不会自动升级为项目知识。失败、恢复和成功必须各自保留证据与适用条件；不能证明因果时，只能使用符合事实的关系，不得把时间上的后续误写为修正结果。

具体状态、提交与历史合同见 [存储、来源绑定与生命周期](2026-07-29-themico-design/storage-and-lifecycle.md)。

## 5. 与 Themis、Context 和 MCP 的边界

当前范围只包含独立 Themico 核心 CLI 与单一 Skill/references：

- MCP adapter 必须另立计划，不得在本设计中隐式接线；
- Themis Global Rule、Capability、Workspace 和 lifecycle 的正式集成必须另立计划；
- Plan 35 的 Context 窄边界保持不变，Themico 的项目架构、正式设计和开发规范不得直接写入 `workspace/context/` 并声称 Context authority；
- 后续 adapter 只能调用领域化 Themico 操作，不能暴露绕过治理的任意路径写入、删除或原始存储操作。

Themico 可以独立使用，但本 Spec 不授权任何 MCP 或 Themis runtime 集成。

## 6. 非目标

当前核心范围不包含：

- OpenViking 或其他外部知识库存储依赖；
- 仓库自动扫描、自动架构推断、自动知识摄取或自动经验晋升；
- Claude API、内置 LLM、Embedding、向量数据库、GraphRAG 或通用对话记忆；
- SQLite、通用数据库、通用 transaction framework 或复杂存储引擎；
- URL 抓取、未物化外部来源、多租户、云同步或 Web 管理界面；
- 通用图查询语言；
- 功能版本、版本目录、compatibility、upgrade 或 migration；
- MCP adapter 或 Themis lifecycle integration。

## 7. Reference 索引

1. [Knowledge Record 与聚合模型](2026-07-29-themico-design/knowledge-model.md)：原子记录、scope、关系归属和聚合 view 边界。
2. [知识类型与 L1/L2/L3 合同](2026-07-29-themico-design/types-and-layers.md)：类型闭集、Zone compatibility、分层字段和固定 L3 章节。
3. [Agent、Human 与 CLI 权威边界](2026-07-29-themico-design/agent-cli-authority.md)：提案、授权、确定性执行和失败关闭。
4. [存储、来源绑定与生命周期](2026-07-29-themico-design/storage-and-lifecycle.md)：`.themico` 包布局、control-plane/workspace 分离、不可变对象、generation commit 和状态变化。
5. [渐进查询、预算与投影](2026-07-29-themico-design/query-and-projection.md)：过滤、升级读取、关系扩展、trace、失效和重建。
6. [Skill 与 reference 加载合同](2026-07-29-themico-design/skill-and-references.md)：单一 Skill、operation reference 和 registry-selected factory。
7. [验收标准](2026-07-29-themico-design/acceptance.md)：完整 Themico 目标与实施切片必须提供的可运行证据及各自完成判定。
8. [首个可用交付范围](2026-07-29-themico-design/first-usable-delivery.md)：首先交付的端到端闭环、延期能力和独立验收集合。
