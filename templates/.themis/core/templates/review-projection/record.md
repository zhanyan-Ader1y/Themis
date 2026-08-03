# Review Projection Record 模板

> 本文件是活动 Prompt-level paired semantic artifact 控制记录模板，用于形成候选 Review Projection `record.md`。具体 revision 只有经适用 Policy control action 完整物化 record/content、记录完成观察并重读 identity、digest 与 bindings，且更新并重读独立 current pointer 后，才能成为 current Review Projection authority。它绑定 checked Plan 的只读投影；`blocked` 只保留 blocker evidence/continuation，不创建空 pair。

## Revision identity 与执行绑定

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Template status | 必填 | `prompt-level-not-machine-validated` | 模板固定值 | 不声称机器校验 |
| Record class | 必填 | `paired-semantic-artifact` | 模板固定值 | 与同 revision `content.md` 不可分割 |
| Authority scope | 必填 | `lifecycle` | current lifecycle | lifecycle-local projection |
| Family | 必填 | `review` | stable legacy identity | 目录拆分不改变 family identity |
| Revision identity | 必填 | opaque immutable identity | materialization action | Review Projection revision |
| Lifecycle identity | 必填 | opaque lifecycle identity | Invocation binding | 所属 lifecycle |
| Execution identity | 必填 | current lifecycle Execution Identity | Invocation contract | failure control 绑定 |
| Invocation identity | 必填 | current temporary Invocation | producer proposal | producer 来源 |
| Attempt identity | 必填 | current attempt identity | Invocation contract | 与 Execution Identity 绑定 |
| Capability | 必填 | `themis-review-projection` | fixed binding | producer identity |
| Agent Profile | 必填 | `semantic-readonly` | fixed binding | 只读投影 producer |
| Producer status | 必填 | `ready` | legal result | `blocked` 不形成 pair |

## Input bindings 记录

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Current Request revision | 必填 | current immutable revision | lifecycle pointer | 目标语义 |
| Selected path | 必填 | `simple` 或 `full` | current Plan | path binding |
| Profile | 必填 | `lightweight` 或 `full` | current route | projection depth |
| Full path required | 必填 | `false` 或 `true` | sticky lifecycle state | quick/full guard |
| Plan revision | 必填 | current checked Plan revision | Plan pointer | source authority |
| Plan content digest | 必填 | current digest reference | paired Plan | checked content |
| Plan Check reference | 必填 | current `pass` result | checker record | projection gate |
| Projection profile | 必填 | selected path/profile 对应的人类审阅深度 | Capability result | presentation contract |
| Policy identity/digest | 必填 | current observed binding | Invocation preflight | route/currentness |
| Continuation identity | 必填 | exact durable continuation | lifecycle control | Review Check return |

## Projection map 记录

每个呈现项逐项追溯 checked Plan，不得用笼统 summary 替代：

| Projection item identity | Content location | Source Plan location | Source digest/binding | Compression rationale | Semantics preserved |
|---|---|---|---|---|---|
|  |  |  |  |  | `true` 或 `false` |

## Content 与物化观察

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Content path | 必填 | 同 revision 的 `content.md` | paired artifact | 人类语义 half |
| Content digest | 必填 | digest placeholder/reference | complete content | 本模板不计算 digest |
| Operation identity | 必填 | opaque operation identity | control action | pair 写入操作 |
| Recorder result reference | 必填 | immutable result reference | recorder observation | 写入结果 |
| Observed complete | 必填 | `true` 或 `false` | control observation | 两个 half 是否完整 |
| Reread record reference | `true` 时必填 | immutable reread evidence | observed reread | record 重读 |
| Reread content reference | `true` 时必填 | immutable reread evidence | observed reread | content 重读 |
| Observed disposition | 必填 | `candidate`、`current`、`stale`、`superseded` 或 `invalid` | lifecycle control | revision disposition |
| Current pointer observation reference | current 时必填 | separate pointer observation；否则 `none` | pointer update | 文件存在不证明 current |

## 停止边界

Plan Check 非 current `pass`、projection map 无法追溯、path/profile 或任一 binding stale 时不得形成 `ready` pair。任一 half 缺失或 identity、digest、scope、source/artifact binding mismatch 时整个 revision invalid；Review Projection 不是 execution input，也不得引入 Plan 中不存在的语义。
