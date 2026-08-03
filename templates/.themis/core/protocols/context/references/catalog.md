# Context 目录

旧合同文档 identity `themis-context-catalog-schema` 与 Catalog identity `themis-context-catalog` 仅作为描述词汇保留，不表示机器 Schema。共享枚举、revision、digest 与 path conventions 来自 [Context 公共字段](common-fields.md)；item 内容合同来自 [Context 条目](context-item.md)。

## 顶层字段

| 字段 | 必填 | 语义 |
|---|---|---|
| `catalog_schema` | 是 | 固定 descriptive identity `themis-context-catalog` |
| `binding` | 是 | `unbound | bound` |
| `project` | 是 | Project observation |
| `workspace_identity_digest` | 是 | Workspace identity digest 槽；未观察时 `unavailable` |
| `revision` | 是 | `kind`、`commit`、`worktree` observation |
| `catalog_digest` | 是 | Catalog digest 槽 |
| `items` | 是 | Context ID keyed item index，可为空 |

Catalog 顶层 allowed fields 与 required fields 都固定为 `catalog_schema`、`binding`、`project`、`workspace_identity_digest`、`revision`、`catalog_digest`、`items`。Project 的 allowed/required fields 固定为 `name`、`root`；Revision 的 allowed/required fields 固定为 `kind`、`commit`、`worktree`。

## 条目索引项

每个 item 的 allowed/required fields 都固定为以下字段：

```text
path
title
category
kind
authority
status
scope
tags
abstract
overview
source_refs
dependencies
supersedes
content_digest
item_digest
```

每个 source ref 的 allowed/required fields 固定为 project-relative `path` 与 `digest`。`category` 使用公共 `category` enum，`authority` 使用公共来源/治理性质 enum，`status` 使用 `active | deprecated | superseded | archived`。

## 完整性约束

- Context IDs unique。
- Item paths unique。
- `dependencies`、`supersedes` 与其他 references 必须指向 existing item。
- Dependency cycles forbidden。
- Catalog digest 的描述输入排除 `catalog_digest` 与 `revision`。

当前没有 strict validator、canonical digest 或 Catalog mutation runtime，因此这些约束只能人工核对，不能从一个 Markdown 文件的存在推断已满足。

## Authority 边界

Catalog index 不拥有 item 正文、当前实现事实、Current Request、Plan、lifecycle state 或 current pointer authority。`binding: bound` 也只表示治理绑定 observation，不把 Context 变成执行 authority。
