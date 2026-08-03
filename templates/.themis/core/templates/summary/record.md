# Summary Record 模板

> 本文件是活动 Prompt-level paired semantic artifact 控制记录模板，用于形成候选 Summary `record.md`。具体 revision 只有经适用 Policy control action 完整物化 record/content、记录完成观察并重读 identity、digest 与 bindings，且更新并重读独立 current pointer 后，才能成为 current Summary authority。Summary 只有在 current Verification `passed` 且 current Human Acceptance `accepted` 后才可形成。

## Revision identity 与执行绑定

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Template status | 必填 | `prompt-level-not-machine-validated` | 模板固定值 | 不声称机器校验 |
| Record class | 必填 | `paired-semantic-artifact` | 模板固定值 | 与 `content.md` 不可分割 |
| Authority scope | 必填 | `lifecycle` | current lifecycle | lifecycle-local summary |
| Family | 必填 | `summary` | stable identity | artifact family |
| Revision identity | 必填 | opaque immutable identity | materialization action | Summary revision |
| Lifecycle identity | 必填 | opaque lifecycle identity | Invocation binding | 所属 lifecycle |
| Execution identity | 必填 | current lifecycle Execution Identity | Invocation contract | failure control 绑定 |
| Invocation identity | 必填 | current Summary Invocation | producer contract | summary proposal |
| Attempt identity | 必填 | current attempt identity | Invocation contract | counted attempt binding |
| Capability | 必填 | `themis-summary` | fixed binding | producer identity |
| Agent Profile | 必填 | `semantic-readonly` | fixed binding | read-only delivery projection |
| Producer status | 必填 | `ready` | legal pair-producing result | `blocked` 不形成 Summary pair |

旧 `completed` 不再是 Summary status。`ready` pair 完整物化并重读后，Policy 才能另行记录 lifecycle completion observation。

## Gate 与 source bindings

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Current Request revision | 必填 | current immutable revision | lifecycle pointer | original objective |
| Plan revision/digest | 必填 | current approved Plan | Plan pointer | delivery design |
| Review Approval revision | 必填 | current complete pair | Approval pointer | authorization |
| Verification revision/evidence | 必填 | current `passed` pair + refs | Verification pointer | technical gate |
| Human Acceptance revision | 必填 | current `accepted` pair | Acceptance pointer | human gate |
| Actual delta references | 必填 | exact current implementation refs | delivery evidence | delivered result |
| Current artifact revisions | 必填 | complete bound set | lifecycle pointers | summary source set |
| Source evidence references | 必填 | direct immutable refs | Verification/Acceptance | traceability |
| Selected path/profile | 必填 | `simple/lightweight` 或 `full/full` | current route | route binding |
| Policy identity/digest | 必填 | current observed binding | Invocation preflight | route/currentness |
| Continuation identity | 必填 | exact durable continuation | lifecycle control | completion return |

## Optional governed candidate bindings 可选治理候选绑定

| Candidate identity | Kind | Source references | Governance destination | Published |
|---|---|---|---|---|
|  | project experience 或 project knowledge change |  |  | 固定 `false` |

Candidate governance/publish failure 不改变 current `passed`、`accepted` 或已观察交付；Summary 自身不发布知识。

## Content、物化与 completion 观察

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Content path/digest | 必填 | 同 revision `content.md` + digest reference | paired artifact | bound delivery projection |
| Operation identity | 必填 | opaque operation identity | control action | pair 写入操作 |
| Recorder result reference | 必填 | immutable result reference | recorder observation | 写入结果 |
| Observed complete | 必填 | `true` 或 `false` | control observation | pair 是否完整 |
| Reread record/content references | `true` 时必填 | immutable reread evidence | observed reread | identity/content/bindings 重读 |
| Observed disposition | 必填 | `candidate`、`current`、`stale`、`superseded` 或 `invalid` | lifecycle control | revision disposition |
| Current pointer observation reference | current 时必填 | separate pointer observation；否则 `none` | pointer update | 文件存在不证明 current |

Lifecycle completion observation 是 Summary pair 成为 current 后由 Policy 另行记录的 operational fact，不属于 immutable Summary revision，也不能回写本 record。

## Blocked 与停止边界

`blocked` 只保留 observed blocker evidence、human-unblock requirement 与 exact Summary continuation，不形成空 Summary pair，也不记录 lifecycle completion。Verification/Acceptance 非 current gate、actual result 不可追溯或任一 binding stale 时不得返回 `ready`。
