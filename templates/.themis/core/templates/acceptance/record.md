# Human Acceptance Record 模板

> 本文件是活动 Prompt-level paired semantic artifact 控制记录模板，用于形成候选 Human Acceptance `record.md`。具体 revision 只有经适用 Policy control action 完整物化 record/content、记录完成观察并重读 identity、digest 与 bindings，且更新并重读独立 current pointer 后，才能成为 current Human Acceptance authority。它保存用户对 current actual result 的明确观察与分类，不重复技术 Verification。

## Revision identity 与执行绑定

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Template status | 必填 | `prompt-level-not-machine-validated` | 模板固定值 | 不声称机器校验 |
| Record class | 必填 | `paired-semantic-artifact` | 模板固定值 | 与 `content.md` 不可分割 |
| Authority scope | 必填 | `lifecycle` | current lifecycle | lifecycle-local acceptance |
| Family | 必填 | `acceptance` | stable identity | artifact family |
| Revision identity | 必填 | opaque immutable identity | materialization action | Acceptance revision |
| Lifecycle identity | 必填 | opaque lifecycle identity | Invocation binding | 所属 lifecycle |
| Plan Task Execution Identity | 必填 | current shared task identity | Approval/Plan task | defect repair 共享 budget |
| Invocation identity | 必填 | current Acceptance Dialogue Invocation | dialogue contract | human interaction |
| Attempt identity | 必填 | current shared-task attempt identity | Invocation contract | counted attempt binding |
| Capability | 必填 | `themis-acceptance-dialogue` | fixed binding | dialogue owner |
| Agent Profile | 必填 | `human-dialogue` | fixed binding | user decision capture |
| Status | 必填 | path/profile 对应合法状态 | explicit user observation | Policy route input |

## Path/profile 锁定状态

| Selected path / Profile | Legal status |
|---|---|
| `simple` / `lightweight` | `accepted`、`implementation-defect`、`needs-planning`、`needs-specification`、`escalate-full` |
| `full` / `full` | `accepted`、`implementation-defect`、`needs-planning`、`needs-specification` |

Full path 不得返回 `escalate-full`。`implementation-defect` 使用同一 Plan Task Execution Identity/budget，repair 后必须重新 independent Verification。

## Input 与 decision bindings

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Source Event references | 必填 | immutable event refs + exact fragments | Intake interception | explicit user observation |
| Current Request revision | 必填 | current immutable revision | lifecycle pointer | acceptance objective |
| Plan revision/digest | 必填 | current approved Plan | Plan pointer | expected result |
| Review Approval revision | 必填 | current complete pair | Approval pointer | authorization |
| Verification revision/evidence | 必填 | current `passed` pair + refs | Verification pointer | Acceptance gate |
| Actual delivered delta/evidence | 必填 | exact current refs | implementation observation | user-visible result |
| Selected path/profile | 必填 | `simple/lightweight` 或 `full/full` | current route | status domain |
| Full path required | 必填 | `false` 或 `true` | sticky lifecycle state | quick/full guard |
| Remaining failure budget | 必填 | current shared budget observation | failure control | defect repair gate |
| Policy identity/digest | 必填 | current observed binding | Invocation preflight | route/currentness |
| Continuation identity | 必填 | exact durable continuation | lifecycle control | Summary/repair return |
| Classified at | 必填 | observed timestamp reference | decision observation | classification time |

## Human observation 记录

| Acceptance requirement | Delivered observation | Preserved user fragments | Evidence entry point | Conclusion |
|---|---|---|---|---|
|  |  |  |  |  |

- Observed difference：
- Affected semantics：
- Classification reason：
- Known limitations：

## Content 与物化观察

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Content path/digest | 必填 | 同 revision `content.md` + digest reference | paired artifact | human acceptance semantics |
| Operation identity | 必填 | opaque operation identity | control action | pair 写入操作 |
| Recorder result reference | 必填 | immutable result reference | recorder observation | 写入结果 |
| Observed complete | 必填 | `true` 或 `false` | control observation | pair 是否完整 |
| Reread record/content references | `true` 时必填 | immutable reread evidence | observed reread | identity/content/bindings 重读 |
| Observed disposition | 必填 | `candidate`、`current`、`stale`、`superseded` 或 `invalid` | lifecycle control | revision disposition |
| Current pointer observation reference | current 时必填 | separate pointer observation；否则 `none` | pointer update | 文件存在不证明 current |

## 停止边界

Verification 非 current `passed`、用户无明确 Source Event observation、或任一 binding stale 时不得形成 pair。沉默、模糊肯定或 Agent interpretation 不能成为 `accepted`；Acceptance 不修改实现、Plan、Approval 或 Verification。
