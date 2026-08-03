# Context 目录

## 绑定

| 字段 | 当前值 | 语义 |
|---|---|---|
| `catalog_schema` | `themis-context-catalog` | 描述标识；不是已实现机器 Schema |
| `binding` | `unbound` | 尚未绑定具体项目 identity |
| `workspace_identity_digest` | 未配置 | 仅保留 digest placeholder 槽，不证明 currentness |

`binding` 的合法描述值为 `unbound | bound`。从 `unbound` 变为 `bound` 需要未来 accepted governance/runtime；不得由手工编辑或目录位置推断。

## 项目

| 字段 | 当前值 |
|---|---|
| `project.name` | 未配置 |
| `project.root` | `.` |

## Revision 观察

| 字段 | 当前值 | 合法描述值或边界 |
|---|---|---|
| `revision.kind` | `unavailable` | `git | unavailable` |
| `revision.commit` | 未配置 | 实际观察到的 commit；未观察时保持未配置 |
| `revision.worktree` | `unknown` | `clean | dirty | unknown` |
| `catalog_digest` | `sha256:f6042b7d830e0aadfd689311f55051bc7dccdce3d2aaad24d384473fe72a6222` | 迁移来源中的 placeholder；当前没有 canonical digest 实现，不得当作已验证值 |

## 条目索引

当前 `items`：未配置。

未来每个 item index entry 必须符合 [Context Catalog 描述合同](../../core/protocols/context/references/catalog.md)，并保持 unique ID/path、existing references 与 acyclic dependency 约束。Catalog 只能索引受治理经验、背景、约束或核验线索，不拥有当前实现事实、Current Request、Plan、lifecycle state 或 current pointer authority。
