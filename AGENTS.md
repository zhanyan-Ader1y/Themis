# Project

Themis 是一个 SDD Harness 框架，将本地 AI 编码系统安装到工程项目中，并实现受治理的项目知识积累。

以下所有限制仅对Themis设计生效，不参与Themis的实现与在实际项目中的运行时行为。

## 产品身份

评估计划和变更时，必须保持 Themis 的四项核心特点：

- **Spec 前追问**：发布 Spec 前，先澄清意图、范围、假设、约束和验收条件。
- **更轻松的 Spec Review**：通过提取plan将待review内容按需生成**时序/流程图**的overview，并将review项自顶向下地精简列出，降低评审者理解成本，提高效率。
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

## 限制

- 所有WIKI类文件不允许记录任务状态等
- 项目中不允许添加版本概念，不允许出现版本形式的目录
- 项目不需要upgrade与migration
