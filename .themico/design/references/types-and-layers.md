# 知识类型与 L1/L2/L3 合同

## 1. 主题责任

本文定义首批知识类型、Zone compatibility，以及 L1、L2、L3 的固定表达合同。L1/L2/L3 只表示同一 Knowledge Record 的读取深度，不表示项目、领域、架构、组件或 feature 层级。

## 2. 类型与 Zone 闭集

首批 registry 只包含三个知识类型：

| `knowledge_type` | 语义 | 唯一 Zone |
| --- | --- | --- |
| `design_decision` | 已确认的设计选择、理由、约束、备选方案和后果 | `project_knowledge` |
| `development_standard` | 在明确触发条件下必须或禁止执行的开发规则及验证方法 | `project_knowledge` |
| `development_experience` | 在特定背景中观察、验证并可复用的开发经验、风险或恢复方法 | `project_experience` |

Zone 闭集固定为 `project_knowledge` 与 `project_experience`。CLI 必须拒绝未注册类型、未注册 Zone 和不兼容组合，不能用自由文本类型、目录名或标签扩展闭集。

类型选择依据如下：

- 回答“项目已决定什么以及为什么”时，提出 `design_decision`；
- 回答“满足哪些条件时必须、禁止或需要验证什么”时，提出 `development_standard`；
- 回答“在什么背景下观察到什么、采取什么行动、证据强度如何”时，提出 `development_experience`。

同一材料可以产生多个不同类型的 candidate，但每个 candidate 必须有独立分类依据，并分别经过 Human 类型确认和后续治理。

## 3. 类型确认与不可变性

新 candidate 首先保存 Agent 提出的 `proposed_type` 和分类依据。Human 明确确认后，CLI 根据 registry 校验类型与 Zone，并把 `knowledge_type` 固化到新的 candidate revision。

固化后的规则为：

- revise 只能保留已固化 `knowledge_type`；
- publish 后的 record factory 只能由持久化 `knowledge_type` 查 registry 获得；
- Agent、Skill 和 Human Review 都不能根据标题、摘要、标签或 L3 正文重新解释正式类型；
- 需要改变知识类型时，必须创建新 candidate 或 record，并使用 `derived_from` 连接原记录；
- 原记录继续保留原类型、历史和独立生命周期。

## 4. 通用 L1

三种类型共享同一个 L1 payload：

| 字段 | 类型 | 含义 |
| --- | --- | --- |
| `title` | string | 简短、可区分的知识标题 |
| `summary` | string | 忠实概括核心内容的发现摘要 |
| `triggers` | string[] | 何时应考虑读取该知识 |
| `tags` | string[] | 用于确定性过滤的受控或项目内标签 |

CLI 查询结果在 L1 payload 外附带 record ID、revision、`knowledge_type`、Zone、scope、status 和投影绑定，使候选能够追溯到原子记录。L1 不保存完整理由、规则步骤或经验证据，也不能代替 L3 被引用为完整语义。

## 5. L2 公共头部

三种类型共享以下 L2 公共头部，并在 `payload` 中使用 registry-selected factory 的类型化结构：

| 字段 | 类型 | 含义 |
| --- | --- | --- |
| `core_conclusion` | string | 该知识最重要的结论 |
| `applicable_when` | string[] | 适用条件 |
| `not_applicable_when` | string[] | 明确不适用条件 |
| `impact` | string[] | 对代码、设计、流程或风险的影响 |
| `evidence_summary` | string[] | 证据和来源的简明概括 |
| `upgrade_when` | string[] | 何时必须继续读取 L3 |
| `payload` | object | 与已固化类型唯一匹配的类型化 payload |

L2 用于理解和规划，不是独立语义权威。公共头部和 payload 都必须绑定同一 record revision 与 L3 digest。

### 5.1 `design_decision` payload

| 字段 | 类型 | 含义 |
| --- | --- | --- |
| `affected_units` | string[] | 受影响领域、架构单元或 feature |
| `constraints` | string[] | 决策必须满足的约束 |
| `alternatives` | string[] | 已考虑的替代方案 |
| `consequences` | string[] | 已接受的正面、负面和运维后果 |
| `reevaluate_when` | string[] | 触发重新评估的条件 |

### 5.2 `development_standard` payload

| 字段 | 类型 | 含义 |
| --- | --- | --- |
| `lifecycle_stages` | string[] | 标准适用的开发生命周期阶段 |
| `trigger` | string[] | 触发该标准的条件 |
| `required_actions` | string[] | 必须执行的动作 |
| `prohibited_actions` | string[] | 明确禁止的动作 |
| `verification` | string[] | 证明遵循标准的方法 |
| `exception_policy` | string[] | 例外申请、授权和记录要求 |

### 5.3 `development_experience` payload

| 字段 | 类型 | 含义 |
| --- | --- | --- |
| `symptoms` | string[] | 可识别的现象或信号 |
| `preconditions` | string[] | 经验成立的背景和前置条件 |
| `observed_facts` | string[] | 与推断分离的已观察事实 |
| `recommended_action` | string[] | 建议采取的行动 |
| `evidence_strength` | string | 证据强度及其限制 |
| `risks` | string[] | 复用该经验时的风险 |
| `stop_conditions` | string[] | 应停止尝试或升级处理的条件 |

CLI 必须拒绝 payload 未知字段和类型错配。例如，`design_decision` payload 出现 `symptoms` 时不能通过校验。

## 6. L3 固定 Markdown 章节

L3 使用中文 Markdown。第一个非空行必须是且只能是一个 H1；禁止 YAML frontmatter。每个类型的 H2 必须按下列顺序各出现一次，允许在 H2 下增加 H3 及更深标题，但不能增加其他 H2。

### 6.1 `design_decision`

```text
# <标题>
## 背景与问题
## 决策
## 约束
## 备选方案
## 后果
## 证据与来源
## 重新评估条件
```

### 6.2 `development_standard`

```text
# <标题>
## 目的与适用范围
## 触发条件
## 必须执行
## 禁止行为
## 验证方法
## 例外策略
## 证据与来源
```

### 6.3 `development_experience`

```text
# <标题>
## 背景与前置条件
## 观察到的现象
## 已确认事实
## 建议行动
## 风险与停止条件
## 证据与强度
## 适用与不适用条件
```

空章节不能用来规避内容要求。CLI 只验证章节存在、唯一、顺序和结构；章节内容是否忠实、充分和正确由 semantic assessment 与 Human Review 判断。

## 7. 表达格式边界

- L1 和 L2 只有在由 `themico` CLI 实际读取或写出时才使用 machine JSON；
- machine JSON 使用 UTF-8，拒绝未知字段、重复键和浮点数；
- L3、Skill 流程、factory 指引和产品语义使用中文 Markdown；
- 不使用 YAML 表达产品合同；`SKILL.md` 仅可保留宿主发现所需的最小 frontmatter。
