# Context 公共字段

## 描述性 identities

这些 patterns 只保留字段约束词汇，当前没有 validator 或 ID/digest generator：

| 身份 | Pattern |
|---|---|
| Context ID | `^CTX-[0-9]{3,}$` |
| Bundle ID | `^CBL-[0-9a-f]{64}$` |
| Signal ID | `^CSG-[0-9a-f]{64}$` |
| Digest | `^sha256:[0-9a-f]{64}$` |
| Transaction ID | `^CTXTX-[0-9a-f]{64}$` |

## 共享枚举

| 字段 | 闭合描述值 |
|---|---|
| `category` | `domain | glossary | decisions | architecture | engineering | pitfalls | external` |
| `authority` | `declared | governed | external_reference | derived_fact | derived_navigation` |
| `item_status` | `active | deprecated | superseded | archived` |
| `bundle_status` | `complete | partial | conflict | unavailable` |
| `signal_kind` | `missing | stale | context_conflict | context_code_drift` |
| `signal_status` | `open | resolved | accepted | superseded` |
| `result_status` | `ok | invalid | needs_adjudication | unavailable` |
| `revision_kind` | `git | unavailable` |
| `worktree_status` | `clean | dirty | unknown` |

分类与 `authority` 值不能扩大 Context 范围：它们只描述条目来源或治理状态，不证明当前项目架构、设计决策、代码事实或 lifecycle state。

## 公共 result

旧合同保留两个描述 identity：公共合同文档 `themis-context-common-schema`，Context result `themis-context-result`。它们不是已实现机器 Schema。

| 字段 | 必填 | 语义 |
|---|---|---|
| `schema` | 是 | 固定 `themis-context-result` descriptive identity；非机器 Schema 证明 |
| `command` | 是 | 实际调用入口；不存在时必须写 `unavailable` |
| `status` | 是 | `result_status` 中的合法值 |
| `workspace` | 是 | 有界 Workspace/revision observation |
| `data` | 是 | 命令或人工过程观察到的 structured payload |
| `warnings` | 是 | 非阻塞限制，可为空 |
| `errors` | 是 | 失败事实，可为空 |

Result 的 allowed fields 与 required fields 都固定为 `schema`、`command`、`status`、`workspace`、`data`、`warnings`、`errors`；不得增加隐藏字段。

## Revision 观察

Revision 固定包含 `kind`、`commit`、`worktree`。未观察到 commit 或 worktree 时必须显式保持未配置或 `unknown`，不得猜测。

## Digest、timestamp 与 path

旧合同保留以下 descriptive conventions：

- Digest algorithm：`sha256`，prefix：`sha256:`。
- 旧 YAML canonicalization token：`recursive-key-sort-compact-json-lf`。
- Markdown body convention：`utf8-no-bom-lf-single-final-newline`。
- File convention：`raw-bytes`。
- Timestamp：`utc-rfc3339-seconds`。
- Path separator：`/`；只允许 relative path；拒绝 `''`、`.`、`..` segment、反斜杠与 symlink ancestor。

这些 conventions 当前没有 approved Go CLI 实现，不能用于宣称 canonical digest、safe path 或 machine validation 已完成。旧 YAML token 只作为迁移 parity 记录，不授权继续使用 YAML 产品合同。
