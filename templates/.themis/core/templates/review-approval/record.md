# Review Approval Record 模板

> 本文件是活动 Prompt-level paired semantic artifact 控制记录模板，用于形成候选 Review Approval `record.md`。具体 revision 只有经适用 Policy control action 完整物化 record/content、记录完成观察并重读 identity、digest 与 bindings，且更新并重读独立 current pointer 后，才能成为 current Approval authority。Approval 批准的是 checked Plan；绑定实际展示的 Review Projection 只证明用户批准时看到的内容。

## Revision identity 与执行绑定

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Template status | 必填 | `prompt-level-not-machine-validated` | 模板固定值 | 不声称机器校验 |
| Record class | 必填 | `paired-semantic-artifact` | 模板固定值 | 与 `content.md` 不可分割 |
| Authority scope | 必填 | `lifecycle` | current lifecycle | lifecycle-local approval |
| Family | 必填 | `review-approval` | stable identity | artifact family |
| Revision identity | 必填 | opaque immutable identity | materialization action | Approval revision |
| Lifecycle identity | 必填 | opaque lifecycle identity | Invocation binding | 所属 lifecycle |
| Execution identity | 必填 | current lifecycle Execution Identity | Dialogue Invocation | failure control 绑定 |
| Invocation identity | 必填 | current Review Dialogue Invocation | producer proposal | approval 来源 |
| Attempt identity | 必填 | current attempt identity | Invocation contract | 与 Execution Identity 绑定 |
| Capability | 必填 | `themis-review-dialogue` | fixed binding | proposal producer |
| Agent Profile | 必填 | `human-dialogue` | fixed binding | human decision owner |
| Decision | 必填 | `approved` | explicit Source Event | 唯一合法 Approval decision |

## Approval bindings 记录

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Intake assignment decision reference | 必填 | current confirmed decision | lifecycle origin | assignment authority |
| Current Request revision | 必填 | current immutable revision | lifecycle pointer | approved objective |
| Active claim revisions | 必填 | one or more current refs | Current Request record | exact active claims |
| Questioning round revision | 必填 | current completed round | lifecycle pointer | Why/What binding |
| Governed design constraint references | 必填 | zero or more current refs | governance inputs | solution constraints |
| Grounding reference | 必填 | relevant current ref 或 `none` | requirement bundle | implementation facts |
| Complexity Assessment reference | 必填 | current record | path gate | route evidence |
| Selected path/profile | 必填 | `simple/lightweight` 或 `full/full` | current route | authorization domain |
| Full path required | 必填 | `false` 或 `true` | sticky lifecycle state | quick/full guard |
| Plan revision/digest | 必填 | current checked Plan | Plan pointer | approved execution contract |
| Plan Check reference | 必填 | current `pass` result | checker record | Plan quality gate |
| Review Projection revision/digest | 必填 | exact shown pair | Review pointer | actual human subject |
| Review Check reference | 必填 | current `pass` record | checker record | projection fidelity gate |
| Unresolved feedback references | 必填 | empty set | Review Dialogue | Approval 前必须为空 |
| Approval decision Source Event reference | 必填 | immutable event + exact fragments | Intake interception | explicit user decision |
| Approved at | 必填 | observed timestamp reference | decision observation | approval time |
| Pre-Impl implementation baseline | 必填 | observed baseline identity | preflight | expected delta applicability |
| Policy identity/digest | 必填 | current observed binding | Invocation preflight | route/currentness |
| Continuation identity | 必填 | exact durable continuation | lifecycle control | Impl entry |

## Content 与物化观察

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Content path | 必填 | 同 revision 的 `content.md` | paired artifact | 人类 decision half |
| Content digest | 必填 | digest placeholder/reference | complete content | 本模板不计算 digest |
| Operation identity | 必填 | opaque operation identity | control action | pair 写入操作 |
| Recorder result reference | 必填 | immutable result reference | recorder observation | 写入结果 |
| Observed complete | 必填 | `true` 或 `false` | control observation | pair 是否完整 |
| Reread record/content references | `true` 时必填 | immutable reread evidence | observed reread | identity/content/bindings 重读 |
| Observed disposition | 必填 | `candidate`、`current`、`stale`、`superseded` 或 `invalid` | lifecycle control | revision disposition |
| Current pointer observation reference | current 时必填 | separate pointer observation；否则 `none` | pointer update | 文件存在不证明 current |

## 停止边界

模糊肯定、沉默、历史消息、unresolved feedback、任一 stale binding 或文件存在不能形成 Approval。Approval 不修改 Plan/Projection；除 Plan 明确授权的 expected implementation delta 外，bound input、Policy、baseline 或 external drift 改变均使旧 Approval stale。
