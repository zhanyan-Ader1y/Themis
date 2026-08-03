# Request Intake Proposal 记录模板

> 本文件是活动 Prompt-level Markdown 结构模板，用于持久化 `themis-current-request-dialogue` 的 changed-only proposal。具体 proposal 只有经适用 Policy control action 完整写入、记录观察并重读 identity、fields 与 bindings 后，才构成 governed durable proposal；它仍不是 assignment decision，也不能推进 lifecycle。

## Proposal identity 与绑定

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Template status | 必填 | `prompt-level-not-machine-validated` | 模板固定值 | 不声称机器校验 |
| Record class | 必填 | `structured-semantic-proposal` | 模板固定值 | request-intake proposal |
| Authority scope | 必填 | `request-intake` | current Intake | 禁止绑定 lifecycle Execution Identity |
| Proposal identity | 必填 | opaque immutable identity | materialization proposal | proposal 身份 |
| Intake identity | 必填 | opaque Intake identity | current attachment | 所属 Intake |
| Execution identity | 必填 | request-intake scope identity | current control facts | 与 lifecycle budget 隔离 |
| Invocation identity | 必填 | current temporary Invocation | Invocation contract | proposal 来源 |
| Attempt identity | 必填 | current request-intake attempt identity | Invocation contract | 与 Execution Identity 的 counted attempt 绑定 |
| Capability | 必填 | `themis-current-request-dialogue` | fixed Capability binding | 唯一 semantic owner |
| Agent Profile | 必填 | `human-dialogue` | fixed Profile binding | 执行隔离 |
| Status | 必填 | `needs-request-confirmation` | Capability result | 仅允许进入确认 continuation |
| Source Event references | 必填 | 一个或多个 immutable references | recorded external events | 形成 proposal 的 source authority |
| Original lifecycle-bearing Source Event | 条件必填 | event identity + exact fragment references | 被 Intake interception 的原消息 | confirmation Source Event 不得替代它 |
| Original dialogue continuation | 必填 | exact durable continuation identity | interception 前 control fact | assignment 后把原 Source Event 交回此 continuation |

## Claim 变化

只列发生变化的 claim；无变化项不得复制进 diff。

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Item identity | 每项必填 | stable diff item identity | proposal construction | confirmation 的逐项绑定 |
| Short original quote reference | 每项必填 | exact Source Event fragment 的精简引用 | original Source Events | 用户可识别的原文锚点 |
| Operation | 每项必填 | `add`、`rewrite`、`supersede`、`ambiguity` | Current Request comparison | claim 变化类型 |
| Prior claim revision | 条件必填 | revision reference 或 `none` | current Current Request | 被变化的 prior revision |
| Prior governed semantic | 条件必填 | source-bound semantic 或 `none` | prior claim revision | 用户看到的旧语义 |
| Proposed claim revision | 每项必填 | proposed revision identity/content reference | dialogue result | 待确认的新 revision |
| Proposed governed semantic | 每项必填 | source-bound proposed semantic | dialogue result | 用户看到的建议新语义 |
| Affected lifecycle identities | 每项必填 | 零个或多个 lifecycle identities | current assignment comparison | 受影响 lifecycle；新建且未分配时为空 |
| Source fragments | 每项必填 | 一组 exact fragment bindings | original Source Events | claim source authority |
| Allowed dispositions | 每项必填 | `confirm`、`correct`、`keep-ambiguous` 的适用子集 | Policy | 人类可选择的闭合集合 |

每个 Source fragment 逐项记录：

| Event identity | UTF-8 byte start | UTF-8 byte end | Quoted fragment digest placeholder |
|---|---:|---:|---|

## Assignment 变化

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Item identity | 每项必填 | stable diff item identity | proposal construction | confirmation 的逐项绑定 |
| Short original quote reference | 每项必填 | exact Source Event fragment 的精简引用 | original Source Events | 用户可识别的原文锚点 |
| Operation | 每项必填 | `assignment-change` | fixed value | assignment 变化 |
| Prior assignment semantic | 条件必填 | current target/operation semantic 或 `none` | current assignment | 用户看到的旧 assignment |
| Proposed assignment semantic | 每项必填 | proposed target/operation semantic | dialogue result | 用户看到的建议新 assignment |
| Affected lifecycle identities | 每项必填 | 零个或多个 lifecycle identities | current/proposed targets | 受影响 lifecycle；纯新建时可为空 |
| Allowed dispositions | 每项必填 | `confirm`、`correct`、`keep-ambiguous` 的适用子集 | Policy | 人类确认闭合集合 |

每个 proposed target operation 逐项记录：

| Target identity | Operation | Lifecycle identity | Decision-bound continuation |
|---|---|---|---|
|  | `create-lifecycle`、`update-current-request` 或 `no-change` | 新建时可为 `none` | exact durable continuation |

## Whole-diff 绑定

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Full diff digest | 必填 | complete diff digest placeholder/reference | 全部 stable diff items | whole-diff confirmation 绑定；本模板不计算 digest |
| User-visible concise diff | 必填 | 只呈现 changed items 的完整精简视图 | 全部 item 的原文、旧/新语义、affected lifecycle 与 allowed disposition | 人类实际确认的整体内容；必须与 full diff digest 同一 proposal 绑定 |
| Materialization target | 必填 | `request-intake-proposal` | Policy | proposal 记录类型 |
| Confirmation continuation | 必填 | durable human confirmation continuation | Policy control action | 等待新的 confirmation Source Event |

## 物化观察

| Operation identity | Recorder result reference | Observed complete | Reread reference |
|---|---|---|---|
|  |  | `true` 或 `false` | `true` 时必填 |

## 停止边界

Silence、omitted item、ambiguous approval、stale proposal 或不匹配的 complete diff digest 都不能确认 proposal。Confirmation Source Event 只确认 governance diff；assignment 完成后必须把保存的原 lifecycle-bearing Source Event、exact fragments 与原 durable continuation交回 lifecycle。
