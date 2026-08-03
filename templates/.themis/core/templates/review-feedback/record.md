# Review Feedback Record 模板

> 本文件是活动 Prompt-level source-bound paired semantic artifact 控制记录模板，用于形成候选 Review Feedback pair。具体 revision 只有经适用 Policy control action 完整物化 record/content、记录完成观察并重读 identity、digest 与 bindings 后，才构成 governed immutable Feedback authority；它不会因后续 resolution 而被改写。Review Dialogue 只分类反馈；反馈必须先形成 immutable pair，再返回 owner。

## Revision identity 与执行绑定

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Template status | 必填 | `prompt-level-not-machine-validated` | 模板固定值 | 不声称机器校验 |
| Record class | 必填 | `paired-semantic-artifact` | 模板固定值 | 与 `content.md` 不可分割 |
| Authority scope | 必填 | `lifecycle` | current lifecycle | lifecycle-local feedback |
| Family | 必填 | `review-feedback` | stable identity | artifact family |
| Revision identity | 必填 | opaque immutable identity | materialization action | feedback revision |
| Lifecycle identity | 必填 | opaque lifecycle identity | Invocation binding | 所属 lifecycle |
| Execution identity | 必填 | current lifecycle Execution Identity | Dialogue Invocation | failure control 绑定 |
| Invocation identity | 必填 | current Review Dialogue Invocation | producer proposal | feedback 来源 |
| Attempt identity | 必填 | current attempt identity | Invocation contract | 与 Execution Identity 绑定 |
| Capability | 必填 | `themis-review-dialogue` | fixed binding | producer identity |
| Agent Profile | 必填 | `human-dialogue` | fixed binding | human feedback owner |
| Status | 必填 | `feedback-recorded` | artifact fixed status | feedback revision disposition |

## Feedback bindings 记录

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Source Event references | 必填 | one or more immutable refs + exact fragments | Intake interception | preserved user feedback |
| Shown Review revision/digest | 必填 | exact Review Projection shown | current Review | human context |
| Current Plan revision | 必填 | checked Plan bound to Review | Plan pointer | affected authority |
| Affected owner | 必填 | `current-request-dialogue`、`questioning`、`specification`、`simple-planning`、`planning`、`plan-check` 或 `review-projection` | closed classification | semantic repair owner |
| Owner continuation | 必填 | exact durable continuation | Review Dialogue | owner return point |
| Selected path/profile | 必填 | `simple/lightweight` 或 `full/full` | current route | legal owner/status domain |
| Policy identity/digest | 必填 | current observed binding | Invocation preflight | route/currentness |

`grounding` 不是 affected owner。`needs-grounding` 只为已分类 owner 收集事实，并保存同一个 owner continuation。

## Content 与物化观察

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Content path | 必填 | 同 revision 的 `content.md` | paired artifact | human feedback half |
| Content digest | 必填 | digest placeholder/reference | complete content | 本模板不计算 digest |
| Operation identity | 必填 | opaque operation identity | control action | pair 写入操作 |
| Recorder result reference | 必填 | immutable result reference | recorder observation | 写入结果 |
| Observed complete | 必填 | `true` 或 `false` | control observation | pair 是否完整 |
| Reread record/content references | `true` 时必填 | immutable reread evidence | observed reread | identity/content/bindings 重读 |
| Observed disposition | 必填 | `candidate`、`current`、`stale`、`superseded` 或 `invalid` | lifecycle control | revision disposition |
| Current pointer observation reference | current 时必填 | separate pointer observation；否则 `none` | pointer update | 文件存在不证明 current |

## Resolution observation

Review Feedback pair 保持 immutable。若其 owner 完成修复，控制层必须另行记录 resolution observation，至少绑定 Feedback revision、exact owner continuation、owner Capability/result、产生的新 revision 或 checker record、完整物化与重读 evidence，以及记录时仍包含该 Feedback 的 unresolved-set state reference。Resolution observation 完整记录并重读后，控制层才可另行记录引用它的 unresolved-set update observation；该 state update 完整记录并重读后，新 state view 才能移除 exact Feedback revision。两种 observation 都不是新的 semantic artifact family，也不改写本 pair。

## 停止边界

Owner 无法从 closed set 唯一确定、Source Event/Review/Plan/Policy/continuation stale 时不得形成 pair。Feedback 不得直接 patch Plan 或 Projection，也不能自行执行 owner route。Owner Invocation 开始、候选文件存在或相似内容不得推断 resolved；缺少已记录并重读的 separate resolution observation 或后续 unresolved-set update observation 时，该 Feedback 继续留在 unresolved set。
