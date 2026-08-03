# Impl Result Record 模板

> 本文件是活动 Prompt-level paired semantic artifact 控制记录模板，用于形成候选 Impl Result `record.md`。具体 revision 只有经适用 Policy control action 完整物化 record/content、记录完成观察并重读 identity、digest 与 bindings，且更新并重读独立 current pointer 后，才能成为 current Impl Result authority。它记录 approved Plan task 的实际实现结果，不提供 Verification verdict。

## Revision identity 与执行绑定

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Template status | 必填 | `prompt-level-not-machine-validated` | 模板固定值 | 不声称机器校验 |
| Record class | 必填 | `paired-semantic-artifact` | 模板固定值 | 与 `content.md` 不可分割 |
| Authority scope | 必填 | `lifecycle` | current lifecycle | lifecycle-local result |
| Family | 必填 | `impl-result` | stable identity | artifact family |
| Revision identity | 必填 | opaque immutable identity | materialization action | Impl Result revision |
| Lifecycle identity | 必填 | opaque lifecycle identity | Invocation binding | 所属 lifecycle |
| Plan Task Execution Identity | 必填 | current shared task identity | Approval/Plan task | 与 Verification/repair 共享 budget |
| Invocation identity | 必填 | current Impl Invocation | Invocation contract | writer invocation |
| Attempt identity | 必填 | current task attempt identity | Invocation contract | counted attempt binding |
| Capability | 必填 | `themis-impl` | fixed binding | writer identity |
| Agent Profile | 必填 | `implementation-writer` | fixed binding | 唯一实现写入 Profile |
| Status | 必填 | path/profile 对应合法状态 | writer result | Policy route input |

## Path/profile 锁定状态

| Selected path / Profile | Legal status |
|---|---|
| `simple` / `lightweight` | `implemented`、`needs-planning`、`escalate-full`、`blocked` |
| `full` / `full` | `implemented`、`needs-planning`、`blocked` |

Full path 不得返回 `escalate-full`。Started tool/command/write 或 result contract 失败属于 shared task counted failure，不能伪装成 `blocked`。

## Input bindings 记录

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Current Request revision | 必填 | current immutable revision | lifecycle pointer | objective authority |
| Review Approval revision | 必填 | current complete pair | Approval pointer | implementation authorization |
| Plan revision/digest | 必填 | Approval-bound checked Plan | Plan pair | execution contract |
| Plan task identity | 必填 | dependency-ready task | Plan content | current task |
| Approved implementation baseline | 必填 | observed pre-Impl identity | Approval | delta baseline |
| Expected delta reference | 必填 | approved exact delta | Plan task | allowed result |
| Allowed write/command scope | 必填 | explicit paths/resources/commands | Approval + Plan | permission boundary |
| Remaining failure budget | 必填 | current shared budget observation | failure control | 第三次后禁止第四次 Invocation |
| Selected path/profile | 必填 | `simple/lightweight` 或 `full/full` | current route | status domain |
| Full path required | 必填 | `false` 或 `true` | sticky lifecycle state | escalation guard |
| Policy identity/digest | 必填 | current observed binding | Invocation preflight | route/currentness |
| Continuation identity | 必填 | exact durable continuation | lifecycle control | Verification/repair return |

## Actual result 记录

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Started at / Finished at | `implemented` 时必填 | observed time references | Invocation evidence | execution window |
| Actual delta references | `implemented` 时必填 | one or more exact refs | project observation | actual changed paths/resources |
| Command/evidence references | 执行过时必填 | immutable evidence refs | operational evidence | commands/results |
| Observed post-state | `implemented` 时必填 | baseline-relative observation | reread/inspection | actual state |
| Deviations | 必填 | zero or more approved/unapproved items | writer observation | Plan difference |
| External drift | 必填 | zero or more observed items | currentness check | non-writer changes |
| Remaining work | 必填 | empty or explicit items | task completion check | unfinished scope |

## Blocker/finding 记录

`needs-planning`、`escalate-full` 或 `blocked` 时逐项记录；`implemented` 时为空集合：

| Finding identity | Classification | Evidence | Affected Plan/task semantics | Human-unblock requirement | Preserved continuation |
|---|---|---|---|---|---|
|  | `planning-gap`、`hidden-complexity` 或 `external-blocker` |  |  | `blocked` 时必填 | exact continuation |

## Content 与物化观察

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Content path/digest | 必填 | 同 revision `content.md` + digest reference | paired artifact | governed human semantics |
| Operation identity | 必填 | opaque operation identity | control action | pair 写入操作 |
| Recorder result reference | 必填 | immutable result reference | recorder observation | 写入结果 |
| Observed complete | 必填 | `true` 或 `false` | control observation | pair 是否完整 |
| Reread record/content references | `true` 时必填 | immutable reread evidence | observed reread | identity/content/bindings 重读 |
| Observed disposition | 必填 | `candidate`、`current`、`stale`、`superseded` 或 `invalid` | lifecycle control | revision disposition |
| Current pointer observation reference | current 时必填 | separate pointer observation；否则 `none` | pointer update | 文件存在不证明 current |

## 停止边界

Approval、task、baseline、scope 或 Policy stale 时停止。Expected delta 以外的 workspace/dependency/config/Schema/behavior drift 必须 stop-and-revalidate；writer 不得自验、修改 governance authority 或把 implementation 写入成功等同于 Impl Result/current state。
