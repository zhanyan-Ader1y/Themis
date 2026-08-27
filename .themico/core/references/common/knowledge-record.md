# knowledge-record

## Knowledge Record 是什么

Knowledge Record 是独立治理、修订、引用、失效和替代的最小原子单位。它不是项目、领域、架构、组件或 feature 的层级划分；一个 Knowledge Record 只承载一条可独立成立的知识结论。聚合内容（例如把多条结论合并写进一份长文档）不能成为第二份语义权威——权威只在逐条 Knowledge Record 上。

## 闭集知识类型与 Zone

首批知识类型闭集固定为三种：`design_decision`、`development_standard`、`development_experience`。

Zone 闭集固定为两种：`project_knowledge`、`project_experience`。类型与 Zone 的绑定固定且不可选择：

| `knowledge_type` | 唯一 Zone |
| --- | --- |
| `design_decision` | `project_knowledge` |
| `development_standard` | `project_knowledge` |
| `development_experience` | `project_experience` |

## L1/L2/L3 只表示读取深度

L1、L2、L3 不表示项目、领域、架构、组件或 feature 层级，只表示对同一条 Knowledge Record 的三种递进读取深度：

- **L1**：发现层。三种类型共享同一个 L1 形状（`title`、`summary`、`triggers`、`tags`），只用于确定性筛选与发现，不携带结论或证据本身。
- **L2**：规划层。三种类型共享同一个公共头部（`core_conclusion`、`applicable_when`、`not_applicable_when`、`impact`、`evidence_summary`、`upgrade_when`），并各自携带一个严格类型化的 `payload`。公共头部与各类型 payload 字段的完整定义在对应 `.themico/core/references/types/<type>/l2.md`。
- **L3**：完整正文层。三种类型各自使用固定的 Markdown 章节集合，完整定义在对应 `.themico/core/references/types/<type>/l3.md`。

三种类型共享同一套治理外壳（candidate 生命周期、Human gate、result envelope）与同一个 L1 形状；L2 共享公共头部但使用类型化 payload；L3 完全按类型固定章节，三种类型互不相同、不可混用。

## 类型一旦固化不可原地改型

新候选由 Agent 提出 `proposed_type` 和 `classification_rationale`，经 Human 在类型确认 gate 明确确认后由 CLI 固化为 `knowledge_type`。类型固化后（候选进入 `type_confirmed` 及之后状态）不得原地改型；`themico candidate revise` 对已确认候选修改 `proposed_type` 会被 CLI 拒绝。跨类型提炼必须创建新的 candidate/record，不属于本计划范围内可用的能力。
