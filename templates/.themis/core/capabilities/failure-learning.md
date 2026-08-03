# themis-failure-learning

## 身份与固定绑定

- Stable identity：`themis-failure-learning`。
- Authority scope：`request-intake | lifecycle`，每次 Invocation 只能选择其中一个。
- 固定 Agent Profile：`semantic-readonly`。
- Intake 合法绑定：`selected_path: null`、`profile: null`；lifecycle 合法绑定：`null/null`、`simple/lightweight` 或 `full/full`。
- Materialization target：对应 scope 下的固定 `failure-learning-pair` expected target；只有 `candidate-ready`/`not-reusable` 经 Policy control 形成 immutable paired Failure Learning revision，`needs-more-evidence` 只保留 bound proposal，`blocked` 只记录 unavailable observation。
- 结果只是 candidate proposal，不发布正式知识、不改变主流程，也不替换失败事实。
- 不调用其他 Capability 或 Agent；自身失败不递归触发 Failure Learning。

## 能力目标

每次 counted failure 记录后，或同一/显式关联 replacement Execution Identity 后续成功时，独立判断是否形成可治理的 scope-bound failure/correction/success experience candidate。

## 输入

- exactly one authority scope 与 scope identity；
- scope-local Execution Identity、Invocation/attempt 和 failure record；
- authoritative input bindings 与 direct evidence；
- 已采取动作和同一 identity 的 prior attempts；
- explicitly linked later-success reference/evidence（存在时）；
- scope-local main-route continuation；
- policy binding 和 remaining budget。

prose 相似不能建立 replacement linkage。request-intake 与 lifecycle 的 state、budget、continuation 和 completion 不得互用。

## 候选条件

只在背景和证据明确、可能形成可复用 warning/diagnostic/avoidance/correction practice 时提出。偶发环境噪声、猜测、仅会话信息和未脱敏敏感内容不得形成候选。

## 合法状态

| Selected path | Profile | Status | 语义 |
|---|---|---|---|
| `null` | `null` | `candidate-ready` | 形成 scope-bound reusable candidate proposal |
| `null` | `null` | `not-reusable` | 形成不可复用 disposition proposal 及其证据 |
| `null` | `null` | `needs-more-evidence` | 只保留 bound Learning proposal 与缺失证据说明，不形成 pair |
| `null` | `null` | `blocked` | 记录 Failure Learning unavailable 并恢复主流程，不形成 pair |
| `simple` | `lightweight` | `candidate-ready` | 形成 lifecycle scope-bound reusable candidate proposal |
| `simple` | `lightweight` | `not-reusable` | 形成不可复用 disposition proposal 及其证据 |
| `simple` | `lightweight` | `needs-more-evidence` | 只保留 bound Learning proposal 与缺失证据说明，不形成 pair |
| `simple` | `lightweight` | `blocked` | 记录 Failure Learning unavailable 并恢复主流程，不形成 pair |
| `full` | `full` | `candidate-ready` | 形成 lifecycle scope-bound reusable candidate proposal |
| `full` | `full` | `not-reusable` | 形成不可复用 disposition proposal 及其证据 |
| `full` | `full` | `needs-more-evidence` | 只保留 bound Learning proposal 与缺失证据说明，不形成 pair |
| `full` | `full` | `blocked` | 记录 Failure Learning unavailable 并恢复主流程，不形成 pair |

`null/null` 可用于 `request-intake` scope，或合同明确允许并由 Invocation 绑定的 scope-local continuation。只有 `candidate-ready` 与 `not-reusable` 形成 Failure Learning pair；全部状态均 non-blocking，Learning 自身失败不递归。

## 输出字段合同

Result 顶层字段固定为：`capability` = `themis-failure-learning`；`authority_scope` 必须是 Invocation 唯一绑定的 `request-intake | lifecycle`；`agent_profile` = `semantic-readonly`；`status` 必须是当前 selected path/profile 行中的一个合法终态。

### Input bindings

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `scope_identity` | 必填 | current request-intake 或 lifecycle scope identity |
| `execution_identity` | 必填 | 当前 scope-local Execution Identity |
| `invocation_identity` | 必填 | Failure Learning Invocation identity |
| `attempt_identity` | 必填 | Failure Learning attempt identity |
| `failure_reference` | 必填 | 已记录的 counted failure reference |
| `explicitly_linked_success_reference` | 有 later success 时必填 | 明确绑定原 failure/replacement relation 的 success reference；否则 `null` |
| `main_route_continuation` | 必填 | exact scope-local main-route continuation |
| `policy_identity` | 必填 | `themis-core-control` |
| `policy_digest` | 必填 | 已加载 Policy digest reference |
| `continuation_identity` | 必填 | current Failure Learning continuation |
| `selected_path` | 必填 | `null | simple | full`，与 scope/Profile 锁定 |
| `profile` | 必填 | `null | lightweight | full`，与 selected path 锁定 |

### Structured result

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `reuse_assessment` | 必填 | reusable、not-reusable、evidence gap 或 blocked 的判断依据 |
| `candidate` | `candidate-ready` 时必填 | scope-bound failure/correction/success experience candidate；否则为空对象 |
| `related_failure_and_success` | 必填 | durable failure 与 explicitly linked success refs，可为空 |

### Artifact refs 与 materialization

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `proposed_artifact_references` | 必填 | candidate/disposition/proposal/unavailable refs，可为空 |
| `materialization_target` | 必填 | 固定 `failure-learning-pair` expected target；只有 `candidate-ready`/`not-reusable` 由 Policy 完成 pair，`needs-more-evidence`/`blocked` 不创建虚假 candidate pair |

### Diagnostics 与 recommended route

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `gaps` | 必填 | evidence/linkage/binding gaps，可为空 |
| `evidence` | 必填 | failure、attempt、direct evidence 与 explicitly linked success refs |
| `affected_semantics` | 必填 | 固定 `knowledge_candidate` |
| `recommended_route` | 必填 | advisory `knowledge-governance | retain-for-later | none` |

## 权限与边界

- 只读 failure/success records 和 evidence；不得修改实现、原任务、attempt、budget、continuation 或 authority state。
- 不调用其他 Capability 或 Agent，只能提出候选，不能批准或发布正式知识。
- 该能力失败、blocked 或未物化不阻塞 main route。

## 停止条件

- scope、identity、failure reference 或 main-route continuation 缺失/交叉时停止。
- later success 未显式绑定原 failure/replacement relation 时不得形成 correction/success linkage。
- 自身 Invocation 失败只记录为非递归旁路失败，不再次调用本能力。
- materialization 失败不得改变已记录 failure、failure budget 或第三次终止决定。
