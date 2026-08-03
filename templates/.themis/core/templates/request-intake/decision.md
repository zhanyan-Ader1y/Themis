# Request Intake Decision 记录模板

> 本文件是活动 Prompt-level Markdown 结构模板，用于形成候选 immutable assignment/rejection decision。具体 decision 只有经适用 Policy control action 完整物化、逐 target 记录 complete/incomplete observation，并重读 identity、fields 与 bindings 后，才构成 governed Intake decision authority；Capability prose、文件存在或部分成功不能代替完整 decision observation。

## Decision identity 与绑定

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Template status | 必填 | `prompt-level-not-machine-validated` | 模板固定值 | 不声称机器校验 |
| Record class | 必填 | `structured-semantic-decision` | 模板固定值 | request-intake decision |
| Authority scope | 必填 | `request-intake` | current Intake | 与 lifecycle 动态权威隔离 |
| Decision identity | 必填 | opaque immutable identity | materialization action | decision 身份 |
| Intake identity | 必填 | opaque Intake identity | current attachment | 所属 Intake |
| Execution identity | 必填 | request-intake scope identity | current control facts | 使用 Intake-local budget |
| Invocation identity | 必填 | current temporary Invocation | Invocation evidence | decision proposal 来源 |
| Attempt identity | 必填 | current request-intake attempt identity | Invocation contract | 与 Execution Identity 的 counted attempt 绑定 |
| Decision operation | 必填 | `confirmation-decision`、`no-change` 或 `rejection` | Capability structured result | 区分非空 diff 确认、空 diff 与明确拒绝 |
| Proposal identity | `confirmation-decision` 时必填 | immutable proposal identity | confirmed pending proposal | 被确认的非空 diff proposal；其他 operation 为 `none` |
| Proposal diff digest | `confirmation-decision` 时必填 | complete diff digest reference | proposal reread | whole-diff confirmation 绑定；其他 operation 为 `none` |
| Original lifecycle-bearing Source Event | `confirmation-decision` 或 `no-change` 时必填 | event identity + exact fragments | confirmed proposal 或当前 unchanged Source Event | target 完成后交回原 continuation |
| Original dialogue continuation | `confirmation-decision` 或 `no-change` 时必填 | exact durable continuation | proposal 或 current attachment | confirmation 消息不替代此 continuation |
| Confirmation Source Event reference | `confirmation-decision` 时必填 | immutable Source Event reference | 新确认消息 | 只证明 governance diff disposition；其他 operation 为 `none` |
| Rejection Source Event reference | `rejection` 时必填 | immutable explicit rejection event | 当前用户 decision | rejection 的 source authority；其他 operation 为 `none` |
| Status | 必填 | `assignment-confirmed` 或 `rejected` | Policy legal result | `confirmation-decision`/`no-change` 使用 `assignment-confirmed`；`rejection` 使用 `rejected` |

## Item dispositions 记录

| Item identity | Disposition | Correction Source Event fragments |
|---|---|---|
|  | `confirm`、`correct` 或 `keep-ambiguous` | `correct` 时必填，否则为空集合 |

`confirmation-decision` 时每个 disposition 必须对应 proposal 中的 stable diff item；不得用未列项的笼统确认补全缺失 disposition。`no-change` 与 `rejection` 的 item dispositions 必须为空集合。

## No-change 绑定

`no-change` 时下列字段全部必填，其他 operation 为 `none`：

| Current Source Event reference | Current confirmed assignment reference | Current Request references | Claims/assignment unchanged conclusion | Original dialogue continuation |
|---|---|---|---|---|
| immutable event + exact fragments | immutable current assignment | 一个或多个 current refs | 结构化 `unchanged` 结论 | exact durable continuation |

无变化时不要求用户重复确认，但仍必须完整物化 Intake decision；不得跳过 decision 或以 summary 替代原 Source Event。

## Assignment targets 记录

`confirmation-decision` 时逐项记录 confirmed target；`no-change` 时记录绑定 current assignment 的 `no-change` target；`rejection` 时必须为空集合：

| Target identity | Operation | Lifecycle identity | Claim revision references | Decision-bound continuation | Materialization status | Materialization observation reference |
|---|---|---|---|---|---|---|
|  | `create-lifecycle`、`update-current-request` 或 `no-change` | 允许在尚未创建时为 `none` | 零个或多个 confirmed refs | exact durable continuation | `pending`、`completed`、`incomplete` 或 `failed` | `completed`/`incomplete`/`failed` 时必填 |

## 部分恢复

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Remaining target identities | `assignment-confirmed` 时必填 | 未完成 target identity 集合；全部完成时为空 | per-target observations | 恢复范围 |
| Target recovery action | 有 remaining targets 时必填 | `resume-remaining-target-operations-only`；否则为 `none` | Policy | 禁止回滚或重放 completed targets |

部分成功时 Intake 保持 `open + incomplete`。只有全部 target 都已完整物化、观察并重读后，才能记录 `assigned` 并分别进入 decision-bound continuations。

## 拒绝记录

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Rejection reason Source Event fragments | `rejection` 时必填 | exact fragment bindings | explicit rejection Source Event | Silence 不能推断 rejection |
| Lifecycle operations | `rejection` 时必填 | 空集合 | rejection result | 禁止创建或更新 lifecycle |

`abandoned` 不由本 decision status 表示；它只能来自 explicit host-observed termination/leave event 与 Policy 后置控制。

## 物化观察

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Materialization target | 必填 | `request-intake-decision` | Policy | 记录类型 |
| Operation identity | 必填 | opaque operation identity | control action | 写入操作 |
| Recorder result reference | 必填 | immutable result reference | recorder observation | 写入结果 |
| Observed complete | 必填 | `true` 或 `false` | control observation | decision 是否完整形成 |
| Reread reference | `true` 时必填 | immutable reread evidence | observed reread | identity、digest、items 与 targets 重读证据 |

## 停止边界

任何 operation-specific binding、item disposition、target binding、原 Source Event、confirmation/rejection Source Event、remaining target、materialization observation 或 reread 无法唯一证明时，停在 last proven gate；不得从 summary、聊天或文件存在推断 assignment 已完成。
