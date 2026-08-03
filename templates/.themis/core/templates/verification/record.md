# Verification Record 模板

> 本文件是活动 Prompt-level paired semantic artifact 控制记录模板，用于形成候选 Verification `record.md`。具体 revision 只有经适用 Policy control action 完整物化 record/content、记录完成观察并重读 identity、digest 与 bindings，且更新并重读独立 current pointer 后，才能成为 current Verification authority。它记录 Impl 后的独立 Verification；checker 不继承 writer 的临时推理或写权限。

## Revision identity 与执行绑定

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Template status | 必填 | `prompt-level-not-machine-validated` | 模板固定值 | 不声称机器校验 |
| Record class | 必填 | `paired-semantic-artifact` | 模板固定值 | 与 `content.md` 不可分割 |
| Authority scope | 必填 | `lifecycle` | current lifecycle | lifecycle-local verdict |
| Family | 必填 | `verification` | stable identity | artifact family |
| Revision identity | 必填 | opaque immutable identity | materialization action | Verification revision |
| Lifecycle identity | 必填 | opaque lifecycle identity | Invocation binding | 所属 lifecycle |
| Plan Task Execution Identity | 必填 | 与 Impl/repair 相同的 task identity | Approval/Plan task | shared failure budget |
| Invocation identity | 必填 | independent Verification Invocation | checker contract | 与 Impl Invocation 不同 |
| Attempt identity | 必填 | current shared-task attempt identity | Invocation contract | counted attempt binding |
| Capability | 必填 | `themis-verification` | fixed binding | checker identity |
| Agent Profile | 必填 | `independent-checker` | fixed binding | writer/checker isolation |
| Status | 必填 | path/profile 对应合法状态 | checker result | Policy route input |
| Failure classification | 必填 | `implementation-defect` 或 `none` | evidence conclusion | 只在 `failed` 时为 defect |

## Path/profile 锁定状态

| Selected path / Profile | Legal status |
|---|---|
| `simple` / `lightweight` | `passed`、`failed`、`needs-planning`、`needs-specification`、`escalate-full`、`blocked` |
| `full` / `full` | `passed`、`failed`、`needs-planning`、`needs-specification`、`blocked` |

`failed` 只表示 evidence-backed `implementation-defect`。Hidden complexity 不能伪装成 `failed`；full path 不得返回 `escalate-full`。

## Input bindings 记录

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Current Request revision | 必填 | current immutable revision | lifecycle pointer | verification objective |
| Review Approval revision | 必填 | current complete pair | Approval pointer | authorization binding |
| Plan revision/digest | 必填 | Approval-bound checked Plan | Plan pair | expected behavior |
| Plan task identity | 必填 | current task | Plan content | verification target |
| Pre-Impl baseline | 必填 | Approval-bound observed identity | Approval | delta baseline |
| Expected delta reference | 必填 | approved exact delta | Plan task | comparison source |
| Impl Result revisions | 必填 | one or more current refs | Impl pointer | producer records |
| Implementation revision/delta reference | 必填 | exact actual implementation | direct observation | checker target |
| Allowed verification commands | 必填 | explicit command set | Plan/Approval | read-only execution boundary |
| Remaining failure budget | 必填 | current shared budget observation | failure control | retry gate |
| Selected path/profile | 必填 | `simple/lightweight` 或 `full/full` | current route | status domain |
| Full path required | 必填 | `false` 或 `true` | sticky lifecycle state | quick/full guard |
| Policy identity/digest | 必填 | current observed binding | Invocation preflight | route/currentness |
| Continuation identity | 必填 | exact durable continuation | lifecycle control | Acceptance/repair return |

## Assertions、evidence 与 coverage 记录

| Assertion identity | Current Request/Plan requirement | Expected | Actual | Evidence references | Conclusion |
|---|---|---|---|---|---|
|  |  |  |  |  | `pass`、`fail` 或 `unknown` |

| Command/observation | CWD | Environment | Exit/result | Raw stdout/stderr/evidence reference |
|---|---|---|---|---|

| Coverage item | Requirement/task location | Evidence | Covered | Residual risk |
|---|---|---|---|---|
|  |  |  | `true` 或 `false` |  |

## Delta、drift 与 simple boundary

- Expected approved delta：
- Observed actual delta：
- Unauthorized external drift：
- Baseline applicability：
- Simple boundary applicable：`yes | no`
- Still simple-qualified：
- Hidden contract/data/permission/state/cross-module complexity：

## Finding、failure 与 blocker 记录

非 `passed` 时逐项记录，`passed` 时为空集合：

| Finding identity | Classification | Failed assertion/blocked condition | Actual result | Evidence | Impacted scope | Human-unblock requirement | Preserved continuation |
|---|---|---|---|---|---|---|---|
|  | `implementation-defect`、`planning-gap`、`specification-gap`、`hidden-complexity` 或 `external-blocker` |  |  |  |  | `blocked` 时必填 | exact continuation |

## Content 与物化观察

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Content path/digest | 必填 | 同 revision `content.md` + digest reference | paired artifact | human verdict semantics |
| Operation identity | 必填 | opaque operation identity | control action | pair 写入操作 |
| Recorder result reference | 必填 | immutable result reference | recorder observation | 写入结果 |
| Observed complete | 必填 | `true` 或 `false` | control observation | pair 是否完整 |
| Reread record/content references | `true` 时必填 | immutable reread evidence | observed reread | identity/content/bindings 重读 |
| Observed disposition | 必填 | `candidate`、`current`、`stale`、`superseded` 或 `invalid` | lifecycle control | revision disposition |
| Current pointer observation reference | current 时必填 | separate pointer observation；否则 `none` | pointer update | 文件存在不证明 current |

## 停止边界

Evidence 不足不得 `passed`。Approval/Plan/Impl/baseline/delta/scope/Profile/Policy stale 时停止；external drift 为 non-counted stop-and-revalidate。Started command 或 result contract 失败计入同一 Plan Task Execution Identity；第三次后不得开始第四次 Invocation。
