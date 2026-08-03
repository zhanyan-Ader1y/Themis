# Plan Check Record 模板

> 本文件是活动 Prompt-level immutable structured record 模板，用于形成候选 Plan Check 记录。具体记录只有经适用 Policy control action 完整物化、记录完成观察并重读 identity、fields 与 bindings 后，才构成 governed Plan Check record；它记录 independent `themis-plan-check` proposal，checker 不修改 Plan，也不继承 producer 的临时推理。

## Record identity 与执行绑定

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Template status | 必填 | `prompt-level-not-machine-validated` | 模板固定值 | 不声称自动校验 |
| Record class | 必填 | `structured-semantic-result` | 模板固定值 | structured checker result |
| Authority scope | 必填 | `lifecycle` | current lifecycle | lifecycle-local result |
| Record identity | 必填 | opaque immutable identity | materialization action | Plan Check revision |
| Lifecycle identity | 必填 | opaque lifecycle identity | Invocation binding | 所属 lifecycle |
| Execution identity | 必填 | current lifecycle Execution Identity | Invocation contract | failure budget 绑定 |
| Invocation identity | 必填 | current temporary Invocation | Invocation contract | checker proposal 来源 |
| Attempt identity | 必填 | current lifecycle attempt identity | Invocation contract | 与 Execution Identity 的 counted attempt 绑定 |
| Capability | 必填 | `themis-plan-check` | fixed binding | Capability identity |
| Agent Profile | 必填 | `independent-checker` | fixed binding | producer/checker isolation |
| Selected path | 必填 | `simple` 或 `full` | current Plan/Policy | path binding |
| Profile | 必填 | `lightweight` 或 `full` | Policy route | checker depth |
| Status | 必填 | 当前 path/profile 对应闭合集中的一个 legal status | checker result + Policy binding | 本次 Plan Check 的唯一终态，供 exactly-one Policy rule 匹配 |

## Profile 锁定的合法状态

| Selected path / Profile | Legal status |
|---|---|
| `simple` / `lightweight` | `pass`、`needs-simple-planning`、`escalate-full`、`blocked` |
| `full` / `full` | `pass`、`needs-planning`、`needs-specification`、`needs-grounding`、`blocked` |

Quick-only `needs-simple-planning` 和 `escalate-full` 不得出现在 full path。旧模板中的合并状态 `passed` 不再使用；current Policy 与 Capability 的成功状态是 `pass`。

## Input bindings 记录

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Plan revision | 必填 | current immutable Plan revision | Plan pointer reread | checker target |
| Plan digest | 必填 | current content digest reference | paired Plan record | checked content binding |
| Current Request revision | 必填 | current immutable revision | lifecycle pointer | objective authority |
| Questioning round revision | 必填 | current completed round | lifecycle pointer | Why/What binding |
| Complexity Assessment reference | 必填 | current structured record | path gate | path evidence |
| Grounding/current fact references | 必填 | 零个或多个 current refs | Requirement Input Bundle | implementation evidence |
| Implementation fact baseline | 必填 | observed baseline identity | Plan record/preflight | fact applicability |
| Governed design constraint references | 必填 | 零个或多个 current refs | Plan bindings | design constraints |
| Temporary Specification handoff | full 时必填 | current temporary reference；simple 时 `none` | Plan production | full refinement input |
| Policy identity/digest | 必填 | current observed binding | Policy preflight | legal-status route binding |
| Continuation identity | 必填 | exact durable continuation | lifecycle control | checker completion return |

## Check findings 记录

每个检查项逐项记录：

| Check identity | Requirement/profile rule | Result | Evidence | Affected Plan location | Recommended semantic owner |
|---|---|---|---|---|---|
|  |  | `pass`、`gap` 或 `blocked` |  |  | simple planning、Planning、Specification、Grounding 或 `none` |

Lightweight profile 检查 request coverage、直接事实、范围/排除项、步骤/完成条件、Verification、simple boundary 与 assumptions。Full profile 检查 request/handoff 一致性、技术设计、架构/模块/接口/数据/状态/失败行为、事实证据、acceptance/Verification、任务可执行性与 coverage mapping。

## Blocker 记录

`blocked` 时逐项记录，其他状态为空集合：

| Blocker identity | Blocked permission/environment/external condition | Observed evidence reference | Human-unblock requirement | Preserved Plan Check continuation |
|---|---|---|---|---|

Blocker record 必须绑定 checked Plan、path/profile 与 current checker Invocation；不得把 evidence gap 或工具执行失败伪装成 `blocked`。

## 物化观察

| Operation identity | Recorder result reference | Observed complete | Reread reference |
|---|---|---|---|
|  |  | `true` 或 `false` | `true` 时必填 |

## 停止边界

Profile、path、scope、Plan revision/digest、Policy、continuation 或 producer/checker isolation 无法证明时停止。Evidence 不足不得返回 `pass`；未知状态或错误 profile 状态是 invalid result，不能用 prose 猜测 route。
