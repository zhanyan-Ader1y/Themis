# type-registry

本 reference 提供两张表：分类问题表（lightweight classification registry）用于 Agent 在 create-candidate 时提出唯一 `proposed_type`；identity routing table 用于把已固化的 `knowledge_type` 路由到唯一 type factory。两张表都不复制任何 factory 的详细 L2/L3 合同——完整合同只在各自的 `.themico/core/references/types/<type>/` 下。

## 分类问题表（lightweight classification registry）

Agent 提出 `proposed_type` 前，逐条对照下表判断材料主要回答哪一个分类问题；三者互斥，Agent 只能提出唯一一个 `proposed_type`。

| `knowledge_type` | 分类问题 | 排除提示 |
| --- | --- | --- |
| `design_decision` | 材料是否主要回答"项目已决定什么以及为什么" | 若主要规定必须/禁止动作或复用观察经验，则不选 |
| `development_standard` | 材料是否主要回答"触发后必须、禁止或验证什么" | 若只是一次设计取舍或条件化观察，则不选 |
| `development_experience` | 材料是否主要回答"在何种背景下观察到什么、证据多强、建议如何行动" | 若内容是 current 设计决定或强制规则，则不选 |

## identity routing table

已有 `knowledge_type`（来自 CLI 的 `candidate inspect`、`query` 或 `inspect` 输出）时，直接按下表路由到唯一 factory，不得重新解释或猜测：

| `knowledge_type` | factory | Zone |
| --- | --- | --- |
| `design_decision` | `types/design-decision/factory.md` | `project_knowledge` |
| `development_standard` | `types/development-standard/factory.md` | `project_knowledge` |
| `development_experience` | `types/development-experience/factory.md` | `project_experience` |

上表 factory 列的路径为仓库安装后的运行时路径前缀 `.themico/core/references/`（例如 `.themico/core/references/types/design-decision/factory.md`）。
