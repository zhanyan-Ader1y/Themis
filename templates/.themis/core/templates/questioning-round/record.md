# Questioning Round Record 模板

> 本文件是活动 Prompt-level paired semantic artifact 的 `record.md` 模板，用于形成候选 completed Questioning round。具体 revision 只有经适用 Policy control action 完整物化 record/content、记录完成观察并重读 identity、digest 与 bindings，且更新并重读 Current Questioning Pointer 后，才能成为 current completed round authority。只有一次已完成的问答 exchange 才能形成此 revision；unanswered question 只保存在 durable proposal/continuation 中。

## Artifact identity 与绑定

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Template status | 必填 | `prompt-level-not-machine-validated` | 模板固定值 | 不声称机器校验 |
| Record class | 必填 | `paired-semantic-artifact` | 模板固定值 | completed exchange pair |
| Authority scope | 必填 | `lifecycle` | current lifecycle | lifecycle-local authority |
| Family | 必填 | `questioning-round` | 模板固定值 | artifact family |
| Revision identity | 必填 | opaque immutable identity | materialization action | completed round revision |
| Lifecycle identity | 必填 | opaque lifecycle identity | current bindings | 所属 lifecycle |
| Previous round revision | 必填 | prior revision 或 `none` | current Questioning pointer | round 链 |
| Question proposal reference | 必填 | durable proposal identity | human-questioning continuation | 被回答的问题 proposal |
| Dialogue continuation | 必填 | exact durable continuation | proposal | answer 后恢复位置 |
| Answer Source Event references | 必填 | 一个或多个 immutable references | Intake-intercepted answer | 回答 source authority |
| Post-answer Current Request revision | 必填 | immutable revision reference | assignment/Current Request materialization | 回答后的 current semantic binding |
| Status | 必填 | `converged` | `themis-q` legal result | 只有 converged 才能形成 completed round；`needs-questioning` 仅保存 proposal/continuation |

## Content 绑定

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Content path | 必填 | `questioning/<opaque-round-revision>/content.md` | paired layout | 人类语义部分 |
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

Question proposal 尚未得到 source-bound answer、post-answer Current Request 尚未形成，或 record/content/pointer 任一观察不完整时，不得创建 completed round 或从 chat 拼接问答。
