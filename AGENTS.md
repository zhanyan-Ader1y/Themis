# Project

Themis 是一个 SDD Harness 框架，将本地 AI 编码系统安装到工程项目中，并实现受治理的项目知识积累。

以下所有限制仅对Themis设计生效，不参与Themis的实现与在实际项目中的运行时行为。

## 模块规范

本文件只放**跨模块**约定。模块专属的规范放在该模块自己的 `AGENTS.md` 中，改动某个模块前先读它：

| 模块 | 规范 |
| --- | --- |
| `.themis` | [`templates/.themis/AGENTS.md`](templates/.themis/AGENTS.md) —— spec 控制面写作、与 `core/` 的关系 |
| `.themico` | [`templates/.themico/AGENTS.md`](templates/.themico/AGENTS.md) —— 控制面/工作区分离、三方分权、类型路由 |

模块规范不重复本文件的内容，本文件也不下沉到模块——两处写同一条就是漂移。

## 产品身份

评估计划和变更时，必须保持 Themis 的四项核心特点：

- **Spec 前追问**：进入详细需求细化前，先澄清用户为何提出需求以及触发 → 必要抽象动作 → 结果的核心链路；范围、合同、边界和验收留给后续能力。
- **更轻松的 Plan Review**：从 checked Plan 按需生成时序/流程图 Overview，并将高影响 Review 项由抽象到具体精简呈现，降低评审者理解成本。
- **外部经验可沉淀**：让脱离Themis得出的经验能主动纳入知识库中，不随对话消失。
- **不断进化的项目知识库**：通过受治理的知识积累，将经过事实核验和人工批准的经验沉淀为可追溯的多层级的项目 Context。

## 计划执行

Themis自Loop

### 未MVP前

- 通过themis-q追问
- 将追问结果整理分析后通过superpower skill完成后续规划流程


## SKILL设计规范

### description

Skill 的 description 是 Agent 的发现与路由入口，应优先描述：

- 能完成什么任务
- 适用于什么场景
- 关键产出是什么

边界和“不做什么”应主要写在 Skill 正文中，不应占据 description 的核心位置。

## 安装包与项目工作区的边界

- `templates/` 下是**安装包源**，描述 Themis 安装到目标项目后应有的样子。仓库根目录的 `.claude/` 是**当前项目自身的工作区**，只放对本仓库开发生效的 Skill、command 与配置。
- 两者之间不做迁移，也不互为副本。安装包内的 `SKILL.md` 一律放在 `templates/.themis/skills/<name>/`，随包分发；把它安装到目标项目的 `.claude/skills/` 是安装动作的职责。
- 该安装动作目前由 Themis Go CLI 承担，能力尚未实现，标记为 unavailable。在其可用前由人工完成，不得用脚本替代，也不得声称安装已自动化。
- 因此 `templates/.claude/` 不应存在：在包源里保留安装产物形态即是漂移源。

## 描述格式

- 默认使用自然语言 Markdown 描述产品语义、流程、状态、合同、模板和示例。
- 只有内容确实需要由 Go CLI 解析或执行时，才允许使用 YAML；YAML 必须对应明确的 Go 读取入口和执行用途，不能仅为结构化展示而存在。
- 不需要 Go CLI 执行的场景禁止新增 YAML 文件、YAML 模板或 YAML 语义合同，也不得让 YAML 成为 Prompt 流程的权威源。
- 外部宿主强制要求的最小元数据格式不属于产品语义；例如 `SKILL.md` frontmatter 只能保留宿主发现所需字段，流程与合同仍必须写在 Markdown 正文中。
- 审查既有设计时，不能因为 YAML 已经存在就默认其合理；没有 Go CLI 消费者的 YAML 必须视为需要迁移到 Markdown 的设计债务。
- 项目不使用 Python；不得新增 Python 源码、脚本、一次性验证程序或以 Python 作为计划执行依赖。
- 需要自动执行的项目脚本必须由 Themis Go CLI 提供并通过其公开入口运行；在对应 CLI 能力尚未实现时，应明确标记 unavailable，不得用 Python、Shell 或其他临时脚本替代。

## 限制

- 所有WIKI类文件不允许记录任务状态等
- 项目中不允许添加版本概念，不允许出现版本形式的目录
- 项目不需要upgrade与migration
- 所有markdown内容使用中文呈现
