# Context 条目

## 表示

Context item 使用纯 Markdown，不使用 YAML frontmatter。旧合同文档 identity `themis-context-item-schema` 与 item identity `themis-context-item` 仅作为描述词汇保留，不表示机器 Schema。固定章节为“字段”“摘要”“概览”“来源与关系”“正文”。所有字段值必须来自已核验来源；当前没有 strict validator、digest generator 或 Catalog apply runtime。

共享 identity patterns、枚举、digest 与 path conventions 来自 [Context 公共字段](common-fields.md)。

## 字段

| 字段 | 必填 | 语义 |
|---|---|---|
| `context_item_schema` | 是 | 固定 descriptive identity `themis-context-item` |
| `id` | 是 | 符合 Context ID pattern |
| `title` | 是 | 条目标题 |
| `category` | 是 | Common `category` enum |
| `kind` | 是 | 项目定义的经验/背景/约束类型 |
| `authority` | 是 | Common 来源/治理性质 enum；不授予当前事实 authority |
| `status` | 是 | `active | deprecated | superseded | archived` |
| `scope` | 是 | 适用范围 sequence，可为空 |
| `tags` | 是 | Tags sequence，可为空 |
| `abstract` | 是 | L1-safe 摘要 |
| `overview` | 是 | L2-safe 概览 |
| `source_refs` | 是 | Source ref sequence，可为空但不能伪造来源 |
| `dependencies` | 是 | Context item ID sequence |
| `supersedes` | 是 | Context item ID sequence |
| `content_digest` | 是 | 正文 digest 槽；未计算时写 `unavailable` |

以上字段同时构成 allowed fields 闭集。`context_item_schema`、`id`、`title`、`category`、`kind`、`authority`、`status`、`abstract`、`overview`、`content_digest` 按单值字符串解释；不得附加 YAML frontmatter 或隐藏字段。

`scope`、`tags`、`source_refs`、`dependencies` 与 `supersedes` 始终按 sequence 解释。`dependencies` 与 `supersedes` 只能引用 Context item。

## Source 引用

每个 source ref 的 allowed fields 与 required fields 都固定为 `path`、`digest`。

| 字段 | 必填 | 语义 |
|---|---|---|
| `path` | 是 | Project-relative file path |
| `digest` | 是 | Source bytes 的 `sha256` digest 槽；无实现时写 `unavailable` |

## 固定 Markdown 结构

```text
# <title>

## 字段

| 字段 | 值 |
|---|---|
| context_item_schema | themis-context-item |
| id | <CTX-ID> |
| category | <category> |
| kind | <kind> |
| authority | <source/governance nature> |
| status | <status> |
| scope | <list or 未配置> |
| tags | <list or 未配置> |
| content_digest | <digest or unavailable> |

## 摘要

<abstract>

## 概览

<overview>

## 来源与关系

### 来源引用

| path | digest |
|---|---|
| <project-relative path> | <sha256 digest or unavailable> |

没有来源引用时写 `未配置`，不得省略该小节。

### Dependencies

- <Context item ID，或 `未配置`>

### Supersedes

- <Context item ID，或 `未配置`>

`source_refs`、`dependencies` 与 `supersedes` 是三个独立必填 sequence；空 sequence 以 `未配置` 表示，不得合并为一个自由文本占位符。

## 正文

<governed reusable experience, background, constraint, or evidence lead>
```

正文必须存在，并与 `content_digest` 槽关联。即使 `category` 是 `architecture` 或 `decisions`，条目也只能保存有来源的经验、背景、约束或检索线索，不得复制项目当前架构、批准设计或代码结构并宣称 Context authority。
