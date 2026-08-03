# Failure Learning Record 模板

> 本文件是活动 Prompt-level paired semantic artifact 控制记录模板，用于形成 Failure Learning candidate pair。具体 revision 只有经适用 Policy control action 完整物化 record/content、记录完成观察并重读 identity、digest 与 bindings 后，才构成 governed knowledge candidate；它不会成为 lifecycle authority 或 current pointer target。Failure Learning 永远 scope-bound、candidate-only、non-blocking、non-recursive。

## Revision identity 与 scope 绑定

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Template status | 必填 | `prompt-level-not-machine-validated` | 模板固定值 | 不声称机器校验 |
| Record class | 必填 | `paired-semantic-artifact` | 模板固定值 | 与 `content.md` 不可分割 |
| Authority scope | 必填 | `request-intake` 或 `lifecycle` | Invocation binding | 每次只能选一个 scope |
| Family | 必填 | `failure-learning` | stable identity | artifact family |
| Revision identity | 必填 | opaque immutable identity | materialization action | Learning revision |
| Scope identity | 必填 | current Intake 或 lifecycle identity | scope binding | dynamic state 隔离 |
| Execution identity | 必填 | scope-local Execution Identity | failure record | Intake 或 Plan Task identity |
| Invocation identity | 必填 | current Failure Learning Invocation | Invocation contract | sidecar execution |
| Attempt identity | 必填 | triggering/linked attempt identity | failure/success binding | source attempt |
| Capability | 必填 | `themis-failure-learning` | fixed binding | producer identity |
| Agent Profile | 必填 | `semantic-readonly` | fixed binding | read-only candidate analysis |
| Status | 必填 | `candidate-ready` 或 `not-reusable` | pair-producing legal result | 其他状态不形成 pair |

`needs-more-evidence` 只保留 bound proposal 与 gaps；`blocked` 只记录 unavailable 并立即恢复 main route。二者不形成虚假 candidate pair，能力自身失败不递归。

## Scope 与 evidence bindings

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Failure reference/evidence | 必填 | current scope-local refs | counted failure record | original failure |
| Main-route continuation | 必填 | exact scope-local continuation | Global Rule | sidecar return |
| Explicitly linked success reference | 必填 | immutable ref 或 `none` | observed replacement linkage | prose similarity 不成立 linkage |
| Prior attempts/actions | 必填 | zero or more scope-local refs | Execution Identity | learning context |
| Remaining failure budget | 必填 | current scope-local observation | failure control | Learning 不修改 budget |
| Policy identity/digest | 必填 | current observed binding | Invocation preflight | route/currentness |
| Continuation identity | 必填 | exact Learning continuation | sidecar control | materialization return |
| Selected path/profile | 必填 | Intake 为 `none/none`；lifecycle 为 `none/none`、`simple/lightweight` 或 `full/full` | scope binding | legal route domain |

Request Intake 与 lifecycle 不得共享 dynamic state、budget、continuation、completion 或 current pointer。

## Reuse assessment 与 candidate 记录

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Failed assertion / actual result | 必填 | evidence-bound text | failure record | failure context |
| Actions taken | 必填 | source-bound actions | attempt records | prior response |
| Cause or unknown portions | 必填 | evidence-bound conclusion | analysis | 不伪造 certainty |
| Reusable practice | 必填 | warning/diagnostic/avoidance/correction 或 `none` | evidence conclusion | candidate content |
| Applicable/non-applicable conditions | 必填 | explicit scope conditions | evidence | reuse boundary |
| Sensitive material excluded | 必填 | observed redaction statement | candidate review | privacy boundary |
| Candidate type | 必填 | `failure-experience`、`correction-experience`、`success-practice` 或 `none` | status conclusion | governed kind |
| Governance destination | 必填 | actual existing governance target 或 `none` | caller | 不自动发布 |

`candidate-ready` 的 Candidate type 不能为 `none`；`not-reusable` 必须为 `none` 并保存 disposition evidence。

## Content 与物化观察

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Content path/digest | 必填 | 同 revision `content.md` + digest reference | paired artifact | governed candidate semantics |
| Operation identity | 必填 | opaque operation identity | control action | pair 写入操作 |
| Recorder result reference | 必填 | immutable result reference | recorder observation | 写入结果 |
| Observed complete | 必填 | `true` 或 `false` | control observation | pair 是否完整 |
| Reread record/content references | `true` 时必填 | immutable reread evidence | observed reread | identity/content/bindings 重读 |
| Observed disposition | 必填 | `candidate`、`stale`、`superseded` 或 `invalid` | scope control | candidate disposition |
| Current pointer observation reference | 必填 | 固定 `none`，除非未来独立治理另有 current pointer | package boundary | Learning 不拥有主流程 current authority |

## 停止边界

Scope/identity/failure/main-route continuation 交叉或缺失时停止。Learning 不修改原任务、attempt、budget、third-failure termination、Verification、Acceptance、assignment 或 completion；candidate 必须经过独立治理才能发布，materialization 失败也不得阻塞 main route。
