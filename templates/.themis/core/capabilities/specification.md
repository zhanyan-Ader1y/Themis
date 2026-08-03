# themis-spec

## 身份与固定绑定

- Stable identity：`themis-spec`。
- Authority scope：`lifecycle`。
- 固定 Agent Profile：`semantic-readonly`。
- 唯一合法绑定：`selected_path: full`、`profile: null`。
- Materialization target：temporary Invocation handoff plus immutable raw result evidence；不创建持久 Specification semantic artifact。
- 结果是非权威、可重建的 Planning handoff，不能覆盖 Current Request 或实现事实。
- 不调用其他 Capability 或 Agent，不拥有 route、state、pointer 或持久化权威。

## 能力目标

只在 full path 中，把已完成 Why/abstract What 追问的 Current Request 细化为 Planning 可消费的临时需求 handoff。

## 输入

- Requirement Input Bundle；
- Current Request revision 与 active confirmed claims；
- current completed Questioning round；
- governed design constraint refs；
- Grounding/current implementation fact evidence；
- lifecycle、Execution Identity、Invocation/attempt、policy 和 continuation bindings。

Specification 对事实的转述、结论或假设不是当前实现事实。

## 细化范围

动机/目标/核心链路一致性、范围/排除项、可观察行为、业务/领域/外部合同、实现无关不变量、验收要求、交付风险、显式推导假设和 Planning 约束。它不选择技术设计。

## 合法状态

| Selected path | Profile | Status | 语义 |
|---|---|---|---|
| `full` | `null` | `ready` | 返回完整 replacement handoff |
| `full` | `null` | `needs-questioning` | Why 或 abstract What 仍有真实缺口 |
| `full` | `null` | `needs-grounding` | 需要直接实现事实，一次返回全部事实请求 |
| `full` | `null` | `blocked` | 事实、权限或来源无法获得 |

## 输出字段合同

Result 顶层字段固定为：`capability` = `themis-spec`；`authority_scope` = `lifecycle`；`agent_profile` = `semantic-readonly`；`status` 必须是当前 `full/null` 行中的一个合法终态。

### Input bindings

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `lifecycle_identity` | 必填 | current lifecycle identity |
| `execution_identity` | 必填 | lifecycle scope-local Execution Identity |
| `invocation_identity` | 必填 | 本次 Invocation identity |
| `attempt_identity` | 必填 | 本次 attempt identity |
| `current_request_revision` | 必填 | current Current Request revision |
| `active_claim_revisions` | 必填 | active confirmed claims |
| `questioning_round_revision` | 必填 | current completed Questioning round |
| `policy_identity` | 必填 | `themis-core-control` |
| `policy_digest` | 必填 | 已加载 Policy digest reference |
| `continuation_identity` | 必填 | current specification continuation |
| `review_feedback_revision` | Review owner re-entry 时必填 | exact Review Feedback revision；普通 Specification 时为 `null` |
| `review_feedback_owner_continuation_reference` | Review owner re-entry 时必填 | Feedback record 保存的 `specification` owner continuation reference；普通 Specification 时为 `null` |
| `selected_path` | 必填 | 固定 `full` |
| `profile` | 必填 | 固定 `null` |

### Structured result

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `handoff` | `ready` 时必填 | non-authoritative temporary Specification handoff |
| `fact_requests` | `needs-grounding` 时必填 | 一次返回的全部直接事实请求；否则可为空 |
| `request_conflicts` | 必填 | Current Request/handoff conflicts，可为空 |

### Artifact refs 与 materialization

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `proposed_artifact_references` | 必填 | raw result/proposal refs，可为空 |
| `materialization_target` | 必填 | 固定 `temporary-specification-handoff`；不创建 semantic artifact/current pointer |

### Diagnostics 与 recommended route

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `gaps` | 必填 | requirement/fact gaps，可为空 |
| `evidence` | 必填 | Current Request、Questioning 与 Grounding refs |
| `affected_semantics` | 必填 | 固定 `requirement_refinement` |
| `recommended_route` | 必填 | advisory `planning | questioning | grounding | request-unblock` |

## Review Feedback owner re-entry

当本 Invocation 来自 Review Feedback 的 `specification` continuation 时，result 必须原样保留 exact Feedback revision 与 owner continuation binding。只有 `ready` temporary handoff result evidence 完整记录并重读后，control layer 才可另行记录 resolution observation；Capability 不得自行标记 resolved 或修改 unresolved set。`needs-questioning`、`needs-grounding`、`blocked` 或 handoff 草稿不能关闭 Feedback。

## 权限与边界

- 可只读调查相关事实；不得修改项目实现。
- 不写 `spec.yaml`、`spec.md` 或其他持久 Specification 工件。
- handoff 只存在于 active Invocation/control context；恢复时从 current bindings 重建。
- 不批准需求，不选择技术实现，不调用其他 Capability 或 Agent。

## 停止条件

- Questioning 未收敛、full path 未选定或 current bindings 缺失/过期时停止。
- 事实缺口存在时不得把假设写成实现事实；返回 `needs-grounding`。
- Why/abstract What 缺口存在时返回 `needs-questioning`，不得自行修改 claims。
- 工具、结果合同或 Invocation 失败属于 counted failure；temporary handoff 不得被标记为 persisted authority。
