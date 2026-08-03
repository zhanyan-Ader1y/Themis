# Context Bundle

旧合同文档 identity `themis-context-bundle-schema` 与 Bundle identity `themis-context-bundle` 仅作为描述词汇保留，不表示机器 Schema。共享 ID patterns、status、revision 与 digest conventions 来自 [Context 公共字段](common-fields.md)；Context refs 对应 [Context 条目](context-item.md) 与 [Context 目录](catalog.md)。

## 顶层字段

| 字段 | 必填 | 语义 |
|---|---|---|
| `bundle_schema` | 是 | 固定 descriptive identity `themis-context-bundle` |
| `id` | 是 | Bundle ID |
| `request` | 是 | 有界 selection request |
| `catalog_digest` | 是 | 观察到的 Catalog digest 槽 |
| `revision` | 是 | `kind`、`commit`、`worktree` observation |
| `candidates` | 是 | Candidate Context refs，可为空 |
| `selected` | 是 | Selected refs，可为空 |
| `excluded` | 是 | Excluded refs，可为空 |
| `code_refs` | 是 | 直接 code evidence refs，可为空；Context 不能替代其内容 |
| `signal_refs` | 是 | Context signal refs，可为空 |
| `token_budget` | 是 | Selection token budget |
| `content_budget_bytes` | 是 | Content byte budget |
| `content_bytes` | 是 | 实际 selected content bytes |
| `status` | 是 | `complete | partial | conflict | unavailable` |

Bundle 顶层 allowed fields 与 required fields 都固定为 `bundle_schema`、`id`、`request`、`catalog_digest`、`revision`、`candidates`、`selected`、`excluded`、`code_refs`、`signal_refs`、`token_budget`、`content_budget_bytes`、`content_bytes`、`status`。

## Request 字段

Request 的 allowed fields 与 required fields 都固定为：

| 字段 | 必填 | 语义 |
|---|---|---|
| `intent` | 是 | 当前有界目的 |
| `spec_ref` | 是 | Invocation-local Specification handoff ref；没有时值为 `未配置`，不创建持久 Spec authority |
| `task_ref` | 是 | 当前 task/reference |
| `scope` | 是 | 允许选择的 Context 范围 |
| `filters` | 是 | 显式 selection filters |

字段名 `spec_ref` 为迁移 parity 保留；字段必须存在，但值可以是 `未配置`，不得发明持久 Spec artifact。

## Context 引用

每个 candidate、selected 或 excluded ref 的 required fields 固定为 `id`、`path`、`digest`、`freshness`；allowed fields 额外允许 `reason`。

## 选择约束

- `selected` 必须是 `candidates` 的 subset。
- `excluded` 必须是 `candidates` 的 subset。
- `selected` 与 `excluded` disjoint。
- `content_bytes` 不得超过 `content_budget_bytes`。
- 空 candidate set 表示没有可用 Context，不授权推断事实。

Bundle 只是有界选择与限制 observation，不拥有 Catalog、item、Current Request、Plan 或 implementation authority。Deterministic search、assembly、freshness 与 budget enforcement 当前 `unavailable`。
