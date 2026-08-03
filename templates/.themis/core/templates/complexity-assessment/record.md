# Complexity Assessment Record 模板

> 本文件是活动 Prompt-level immutable structured record 模板，用于形成候选 Complexity Assessment 记录。具体记录只有经适用 Policy control action 完整物化、记录完成观察并重读 identity、fields 与 bindings 后，才构成 governed assessment record；它记录 `themis-complexity-assessment` 的 proposal，只有 Policy control action 能选择 path 或设置 sticky `full_path_required`。

## Record identity 与执行绑定

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Template status | 必填 | `prompt-level-not-machine-validated` | 模板固定值 | 不声称自动判断 |
| Record class | 必填 | `structured-semantic-result` | 模板固定值 | structured assessment |
| Authority scope | 必填 | `lifecycle` | current lifecycle | lifecycle-local result |
| Record identity | 必填 | opaque immutable identity | materialization action | assessment identity |
| Lifecycle identity | 必填 | opaque lifecycle identity | Invocation binding | 所属 lifecycle |
| Execution identity | 必填 | current lifecycle Execution Identity | Invocation contract | failure budget 绑定 |
| Invocation identity | 必填 | current temporary Invocation | Invocation contract | proposal 来源 |
| Attempt identity | 必填 | current lifecycle attempt identity | Invocation contract | 与 Execution Identity 的 counted attempt 绑定 |
| Capability | 必填 | `themis-complexity-assessment` | fixed binding | Capability identity |
| Agent Profile | 必填 | `semantic-readonly` | fixed binding | 只读执行身份 |
| Status | 必填 | `simple-qualified`、`full-required` 或 `blocked` | Capability legal result | closed result status |

## Input bindings 记录

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Current Request revision | 必填 | current immutable revision | lifecycle pointer | confirmed claims |
| Questioning round revision | 必填 | current completed round | lifecycle pointer | converged Why/What |
| Grounding references | 必填 | 零个或多个 current records | Requirement Input Bundle | implementation facts |
| Governed design constraint references | 必填 | 零个或多个 current refs | governance inputs | 方案约束，不是事实 |
| Full path required | 必填 | `false` 或 `true` | durable sticky state | `true` 时禁止 simple path |
| Policy identity/digest | 必填 | current observed binding | Policy preflight | route/currentness 绑定 |
| Continuation identity | 必填 | exact durable continuation | lifecycle control | 后续 control 位置 |
| Selected path/profile | 必填 | 均为 `none` | Capability binding | assessment 只提出候选 |

## Simple condition evidence 记录

每个条件逐项记录直接证据：

| Condition | Conclusion | Direct evidence references | Unknowns | Full requirement reason |
|---|---|---|---|---|
| Goal/scope/result clarity | `simple`、`non-simple` 或 `uncertain` |  |  |  |
| Localized change | `simple`、`non-simple` 或 `uncertain` |  |  |  |
| No external contract change | `simple`、`non-simple` 或 `uncertain` |  |  |  |
| No cross-module/permission/concurrency/data/state complexity | `simple`、`non-simple` 或 `uncertain` |  |  |  |
| Acceptance and Verification clarity | `simple`、`non-simple` 或 `uncertain` |  |  |  |
| No unverified facts or hidden assumptions | `simple`、`non-simple` 或 `uncertain` |  |  |  |

## Proposed path 记录

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Selected path proposal | 必填 | `simple`、`full` 或 `none` | evidence conclusion | 只供 Policy control action 使用 |
| Full requirement reasons | `full-required` 时必填 | 一项或多项 source/evidence-bound reasons | condition table | 说明 non-simple/uncertain/unknown |

只有所有条件均直接证明为 `simple` 且 sticky flag 为 `false` 时，status 才能为 `simple-qualified`。任一 non-simple、uncertain 或缺少直接证据时必须为 `full-required`；必要读取能力不可获得时为 `blocked`。

## Blocker 证据记录

`blocked` 时逐项记录，其他状态为空集合：

| Blocker identity | Blocked permission/environment/external condition | Observed evidence reference | Human-unblock requirement | Preserved Assessment continuation |
|---|---|---|---|---|

`blocked` 不选择 simple/full，也不伪造 Assessment；执行失败不能冒充 blocker evidence。

## 物化观察

| Operation identity | Recorder result reference | Observed complete | Reread reference |
|---|---|---|---|
|  |  | `true` 或 `false` | `true` 时必填 |

## 停止边界

文件数量、代码行数和耗时不能单独证明 simple。执行失败属于 counted failure，不能伪装成 `full-required`；本记录不得自行更新 sticky flag、path、pointer 或 lifecycle state。
