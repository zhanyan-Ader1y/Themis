# themis-planning

## 身份与固定绑定

- Stable identity：`themis-planning`。
- Authority scope：`lifecycle`。
- 固定 Agent Profile：`semantic-readonly`。
- 唯一合法绑定：`selected_path: full`、`profile: full`。
- Materialization target：immutable paired unified Plan revision。
- 结果只是完整 Plan content proposal；policy/recorder 才能建立 revision 和 current pointer。
- 不调用其他 Capability 或 Agent，不拥有 route、state 或持久化权威。

## 能力目标

把 Current Request、governed design constraints、temporary Specification handoff 和直接实现事实转化为 full path 的 unified Plan proposal。

## 输入

- Current Request revision 与 active confirmed claims；
- current completed Questioning round；
- governed design constraint refs；
- `ready` temporary Specification handoff；
- Grounding/current implementation fact evidence 与 baseline；
- lifecycle、Execution Identity、Invocation/attempt、policy 和 continuation bindings；
- unified Plan pair template。

Planning 必须直接读取事实证据，不得只信任 Specification 转述。

## 责任

调查实现事实；比较方案与取舍；设计架构、边界、依赖、数据流、状态、接口和错误模型；分析权限、一致性、失败/恢复和回归；为每项验收设计 Verification；分解依赖就绪的 Impl/Verification 任务；建立来源覆盖映射。

## 合法状态

| Selected path | Profile | Status | 语义 |
|---|---|---|---|
| `full` | `full` | `ready` | 形成完整 unified Plan proposal |
| `full` | `full` | `needs-specification` | Current Request/handoff 冲突或需求范围、合同、验收语义不完整 |
| `full` | `full` | `needs-grounding` | 实现事实缺失、过期或不足，一次返回全部事实请求 |
| `full` | `full` | `blocked` | 必要权限、环境或外部条件不可获得 |

## 输出字段合同

Result 顶层字段固定为：`capability` = `themis-planning`；`authority_scope` = `lifecycle`；`agent_profile` = `semantic-readonly`；`status` 必须是当前 `full/full` 行中的一个合法终态。

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
| `specification_handoff_reference` | 必填 | current `ready` temporary handoff |
| `implementation_baseline` | 必填 | direct implementation baseline reference |
| `policy_identity` | 必填 | `themis-core-control` |
| `policy_digest` | 必填 | 已加载 Policy digest reference |
| `continuation_identity` | 必填 | current planning continuation |
| `review_feedback_revision` | Review owner re-entry 时必填 | exact Review Feedback revision；普通 Planning 时为 `null` |
| `review_feedback_owner_continuation_reference` | Review owner re-entry 时必填 | Feedback record 保存的 `planning` owner continuation reference；普通 Planning 时为 `null` |
| `selected_path` | 必填 | 固定 `full` |
| `profile` | 必填 | 固定 `full` |

### Structured result

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `plan_content` | `ready` 时必填 | 完整 unified Plan content proposal |
| `alternatives_and_tradeoffs` | 必填 | evaluated approaches and trade-offs |
| `fact_requests` | `needs-grounding` 时必填 | 一次返回的全部事实请求；否则可为空 |
| `coverage_summary` | 必填 | sources、claims、constraints 与 acceptance coverage |

### Artifact refs 与 materialization

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `proposed_artifact_references` | 必填 | Plan proposal references，可为空 |
| `materialization_target` | 必填 | 固定 `plan-pair` |

### Diagnostics 与 recommended route

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `gaps` | 必填 | design/fact/coverage gaps，可为空 |
| `evidence` | 必填 | handoff、Grounding 与 implementation evidence refs |
| `affected_semantics` | 必填 | 固定 `plan` |
| `recommended_route` | 必填 | advisory `plan-check | specification | grounding | request-unblock` |

## Review Feedback owner re-entry

当本 Invocation 来自 Review Feedback 的 `planning` continuation 时，result 必须原样保留 exact Feedback revision 与 owner continuation binding。只有 `ready` Plan pair 完整物化、重读并成为 current 后，control layer 才可另行记录 resolution observation；Capability 不得自行标记 resolved 或修改 unresolved set。`needs-specification`、`needs-grounding`、`blocked`、Plan proposal 或文件存在不能关闭 Feedback。

## 权限与边界

- 可只读调查项目；不得修改项目实现或 Current Request。
- 生成与 simple path 相同的 Plan family，不生成第二套 full-plan artifact。
- 不批准 Plan，不执行任务，不调用其他 Capability 或 Agent。
- 不计算或发明 digest、currentness 或 machine-valid 结论。

## 停止条件

- temporary handoff 缺失、full path/profile 不匹配或 current binding stale 时停止。
- 需求语义缺口返回 `needs-specification`；实现事实缺口返回 `needs-grounding`，不得混淆 owner。
- coverage、任务或 Verification 设计不完整时不得返回 `ready`。
- 工具、结果合同或 Invocation 失败属于 counted failure；external drift 单独 stop-and-revalidate。
