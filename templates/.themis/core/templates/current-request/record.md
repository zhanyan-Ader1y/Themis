# Current Request Record 模板

> 本文件是活动 Prompt-level paired semantic artifact 的 `record.md` 模板，用于形成候选 Current Request revision。具体 revision 只有经适用 Policy control action 完整物化 record/content、记录完成观察并重读 identity、digest、scope 与 source bindings，且更新并重读独立 current pointer 后，才能成为 current Current Request authority。它与同一 revision 的 `content.md` 不可分割；任一组件缺失或 binding 不一致时，整个 revision invalid。

## Artifact identity 与绑定

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Template status | 必填 | `prompt-level-not-machine-validated` | 模板固定值 | 不声称 strict validation |
| Record class | 必填 | `paired-semantic-artifact` | 模板固定值 | paired revision record |
| Authority scope | 必填 | `lifecycle` | assignment target | lifecycle-local authority |
| Family | 必填 | `current-request` | 模板固定值 | artifact family |
| Revision identity | 必填 | opaque immutable identity | materialization action | Current Request revision |
| Lifecycle identity | 必填 | opaque lifecycle identity | assignment decision | 所属 lifecycle |
| Intake decision reference | 必填 | immutable assignment decision | confirmed target | Current Request 的治理来源 |
| Prior revision identity | 必填 | prior revision 或 `none` | current pointer reread | revision 链 |

## Claim revisions 记录

每个 confirmed claim revision 独立记录：

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Claim identity | 每项必填 | stable claim identity | Intake decision | claim 身份 |
| Claim revision identity | 每项必填 | immutable revision identity | confirmed decision | 当前 revision 引用 |
| Disposition | 每项必填 | `active`、`ambiguous` 或 `superseded` | confirmation disposition | claim 治理状态 |
| Supersedes | 条件必填 | prior claim revision 或 `none` | rewrite/supersede relation | 被替代 revision |
| Split from | 条件必填 | source claim identity 或 `none` | split relation | 拆分来源 |
| Merged from | 必填 | 零个或多个 claim identities | merge relation | 合并来源 |

每个 claim 的 Source Event fragments 逐项记录：

| Event identity | UTF-8 byte start | UTF-8 byte end | Quoted fragment digest placeholder |
|---|---:|---:|---|

## Content 绑定

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Content path | 必填 | `current-request/<opaque-revision-id>/content.md` | paired artifact layout | 同 revision 人类语义文件 |
| Content digest | 必填 | digest placeholder/reference | content observation | 本模板不计算 canonical digest |

## 物化观察

| Operation identity | Recorder result reference | Observed complete | Reread record reference | Reread content reference |
|---|---|---|---|---|
|  |  | `true` 或 `false` | `true` 时必填 | `true` 时必填 |

## Disposition 与 current pointer

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Observed disposition | 必填 | `candidate`、`current`、`stale`、`superseded` 或 `invalid` | control observation | revision 自身 disposition |
| Current pointer observation reference | 条件必填 | immutable pointer observation 或 `none` | separate pointer update | 只有成功更新并重读 pointer 后才能为 current |

## 停止边界

`record.md` 或 `content.md` 单独存在都不构成 authority。内容变化必须创建新 revision；不得原地覆盖，不得从目录顺序、文件名或聊天内容推断 currentness。
