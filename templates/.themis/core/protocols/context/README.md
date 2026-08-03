# Context 描述合同

## 职责

本 package 用自然语言 Markdown 描述 Context result、item、catalog、bundle 与 signal 的字段词汇、关系和约束。它只服务受治理经验、背景、设计约束与核验线索，不拥有 current implementation facts 或 lifecycle authority。

## 参考合同

| 参考 | 内容 |
|---|---|
| [Common fields](references/common-fields.md) | 共享 identity patterns、enums、result、revision、digest、timestamp 与 path 描述 |
| [Context item](references/context-item.md) | 纯 Markdown item 固定章节、字段、source refs 与 item relationships |
| [Catalog](references/catalog.md) | Catalog binding、project/revision observation、item index 与完整性约束 |
| [Bundle](references/bundle.md) | 有界 Context selection request、candidate/selected/excluded refs 与 budgets |
| [Signal](references/signal.md) | missing、stale、conflict 与 context-code drift observation/disposition |

## 使用边界

- 文档中的 `*_schema` 字段只保留旧合同的 descriptive identity vocabulary，不表示 validator 已存在。
- `authority` 等历史字段只描述来源/治理性质，不能授予当前事实、目标语义、Plan、state 或 currentness authority。
- 当前实现事实必须直接读取 code、configuration、Schema 或 observed executable behavior。
- Canonical serialization、digest、strict validation、Catalog mutation、search/assembly 与 governed apply 当前均为 `unavailable`。
- 不得用 Python、Shell 临时 parser、自由文本推断或手工 state 写入冒充 machine enforcement。

本入口及五个 references 是活动 descriptive Markdown 表示；它们不构成 strict Schema、parser 输入或 runtime authority。
