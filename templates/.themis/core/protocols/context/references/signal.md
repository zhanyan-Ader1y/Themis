# Context Signal

旧合同文档 identity `themis-context-signal-schema` 与 Signal identity `themis-context-signal` 仅作为描述词汇保留，不表示机器 Schema。共享 ID patterns、enums、revision、timestamp 与 digest conventions 来自 [Context 公共字段](common-fields.md)。

## 顶层字段

| 字段 | 必填 | 语义 |
|---|---|---|
| `signal_schema` | 是 | 固定 descriptive identity `themis-context-signal` |
| `id` | 是 | Signal ID |
| `kind` | 是 | `missing | stale | context_conflict | context_code_drift` |
| `status` | 是 | `open | resolved | accepted | superseded` |
| `project` | 是 | Project reference/observation |
| `workspace_identity_digest` | 是 | Workspace identity digest 槽 |
| `revision` | 是 | `kind`、`commit`、`worktree` observation |
| `scope` | 是 | Signal 适用范围 |
| `sources` | 是 | 触发 signal 的来源 refs |
| `evidence_refs` | 是 | Direct evidence refs |
| `first_observed_at` | 是 | 首次 observation timestamp |
| `last_observed_at` | 是 | 最近 observation timestamp |
| `disposition` | 是 | Open 时为空；裁决后完整 |

Signal 顶层 allowed fields 与 required fields 都固定为 `signal_schema`、`id`、`kind`、`status`、`project`、`workspace_identity_digest`、`revision`、`scope`、`sources`、`evidence_refs`、`first_observed_at`、`last_observed_at`、`disposition`。

## Revision 与 disposition

Revision 的 allowed/required fields 固定为 `kind`、`commit`、`worktree`。非 `open` signal 的 disposition allowed/required fields 固定为：

```text
actor
note
decided_at
```

约束：

- `status: open` 时 `disposition` 必须为空。
- `resolved | accepted | superseded` 时 disposition 必须完整。

## 语义

- `missing`：所需 Context 或 evidence 不存在。
- `stale`：来源 freshness 不足。
- `context_conflict`：Context 条目之间存在未裁决冲突。
- `context_code_drift`：Context 叙述与直接观察到的 code/configuration/Schema/behavior 不一致。

`context_code_drift` 不表示 Context 有权裁决当前实现。当前事实以 direct implementation evidence 为准，同时保留冲突 observation；Signal 本身不修改 Context、代码、Plan 或 lifecycle state。

Signal detection、status transition、timestamp/digest generation 与 governed disposition runtime 当前 `unavailable`。
