# Plan Record 模板

> 本文件是活动 Prompt-level unified Plan paired artifact 的 `record.md` 模板，simple 与 full path 共用。具体 revision 只有经适用 Policy control action 完整物化 record/content、记录完成观察并重读 identity、digest 与 bindings，且更新并重读独立 current pointer 后，才能成为 current Plan authority；它与同一 revision 的 `content.md` 共同构成不可分割的执行合同。

## Artifact identity 与输入绑定

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Template status | 必填 | `prompt-level-not-machine-validated` | 模板固定值 | 不声称 strict validation |
| Record class | 必填 | `paired-semantic-artifact` | 模板固定值 | paired Plan revision |
| Authority scope | 必填 | `lifecycle` | current lifecycle | lifecycle-local authority |
| Family | 必填 | `plan` | 模板固定值 | unified Plan family |
| Revision identity | 必填 | opaque immutable identity | materialization action | Plan revision |
| Lifecycle identity | 必填 | opaque lifecycle identity | current bindings | 所属 lifecycle |
| Confirmed Intake assignment decision | 必填 | immutable decision + target reference | lifecycle assignment | Plan 所属 target 的治理来源 |
| Current Request revision | 必填 | current immutable revision | lifecycle pointer | objective authority |
| Active claim revisions | 必填 | 一个或多个 current claim refs | Current Request record | Plan 覆盖目标 |
| Questioning round revision | 必填 | current completed round | lifecycle pointer | converged Why/What |
| Governed design constraint references | 必填 | 零个或多个 current refs | governance input | 约束方案，不替代 facts |
| Grounding reference | 条件必填 | current record 或 `none` | Requirement Input Bundle | implementation facts |
| Complexity Assessment reference | 必填 | current immutable record | path selection gate | simple/full 依据 |
| Selected path | 必填 | `simple` 或 `full` | Policy control fact | Plan producer path |
| Profile | 必填 | `lightweight` 或 `full` | Policy route binding | Plan/Plan Check profile |
| Full path required | 必填 | `false` 或 `true` | durable sticky state | `true` 时禁止 simple/lightweight |
| Temporary Specification handoff reference | full path 必填 | current temporary handoff 或 `none` | `themis-spec` Invocation | non-authoritative refinement；不可恢复为 authority |
| Implementation fact baseline | 必填 | observed baseline identity/evidence | Grounding/preflight | 当前事实适用边界 |

合法组合仅为：

| Selected path | Profile | Full path required | Temporary Specification handoff |
|---|---|---|---|
| `simple` | `lightweight` | `false` | `none` |
| `full` | `full` | `false` 或 `true` | 必填 |

## Content 绑定

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Content path | 必填 | `plan/<opaque-revision-id>/content.md` | paired layout | execution semantics |
| Content digest | 必填 | digest placeholder/reference | content observation | 当前模板不计算 canonical digest |

## 物化观察

| Operation identity | Recorder result reference | Observed complete | Reread record reference | Reread content reference |
|---|---|---|---|---|
|  |  | `true` 或 `false` | `true` 时必填 | `true` 时必填 |

## Disposition 与 current pointer

| Observed disposition | Current pointer observation reference |
|---|---|
| `candidate`、`current`、`stale`、`superseded` 或 `invalid` | current 时必须绑定 separate pointer update/reread；否则可为 `none` |

## 停止边界

不得创建 `simple-plan` 或持久化 Specification authority。Plan 内容或任何 source binding 变化都创建新 revision；Review、Approval 或 dialogue 不得原地修改 Plan。任一 pair、baseline、path/profile、sticky guard、materialization 或 pointer 无法证明时停止。
