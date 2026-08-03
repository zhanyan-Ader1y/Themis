# themis-simple-plan

## 身份与固定绑定

- Stable identity：`themis-simple-plan`。
- Authority scope：`lifecycle`。
- 固定 Agent Profile：`semantic-readonly`。
- 唯一合法绑定：`selected_path: simple`、`profile: lightweight`。
- Materialization target：immutable paired unified Plan revision。
- 结果只是完整 Plan content proposal；policy/recorder 才能建立 revision 和 current pointer。
- 不调用其他 Capability 或 Agent，不拥有 route、state 或持久化权威。

## 能力目标

在 `simple-qualified` 且 `full_path_required = false` 时，形成与 full path 同结构、同语义地位的 unified Plan proposal。

## 输入

- Requirement Input Bundle；
- Current Request revision、active claims 和 completed Questioning round；
- Complexity Assessment record 与逐项证据；
- Grounding/current implementation fact evidence 与 baseline；
- governed design constraints；
- lifecycle、Execution Identity、Invocation/attempt、policy 和 continuation bindings；
- unified Plan pair template。

不得读取 temporary Specification handoff，也不得执行 full Planning。

## Plan 要求

至少包含目标、核心链路、范围/排除项、行为/验收、实现事实证据、拟修改位置、步骤/依赖/完成条件、Verification 方案、风险/失败/恢复、claim 覆盖映射，以及深层设计项 `not-applicable` 的直接证据。

## 合法状态

| Selected path | Profile | Status | 语义 |
|---|---|---|---|
| `simple` | `lightweight` | `ready` | 在已证明简单边界内形成完整 unified Plan proposal |
| `simple` | `lightweight` | `escalate-full` | 需要合同、架构、跨模块、权限、数据、状态或其他完整设计 |
| `simple` | `lightweight` | `blocked` | 必要事实或访问条件不可获得 |

## 输出字段合同

Result 顶层字段固定为：`capability` = `themis-simple-plan`；`authority_scope` = `lifecycle`；`agent_profile` = `semantic-readonly`；`status` 必须是当前 `simple/lightweight` 行中的一个合法终态。

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
| `complexity_assessment_reference` | 必填 | current `simple-qualified` Assessment |
| `implementation_baseline` | 必填 | direct implementation baseline reference |
| `policy_identity` | 必填 | `themis-core-control` |
| `policy_digest` | 必填 | 已加载 Policy digest reference |
| `continuation_identity` | 必填 | current simple-planning continuation |
| `review_feedback_revision` | Review owner re-entry 时必填 | exact Review Feedback revision；普通 Simple Planning 时为 `null` |
| `review_feedback_owner_continuation_reference` | Review owner re-entry 时必填 | Feedback record 保存的 `simple-planning` owner continuation reference；普通 Simple Planning 时为 `null` |
| `selected_path` | 必填 | 固定 `simple` |
| `profile` | 必填 | 固定 `lightweight` |

### Structured result

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `plan_content` | `ready` 时必填 | 完整 unified Plan content proposal |
| `coverage_summary` | 必填 | source/claim/acceptance coverage map |
| `not_applicable_evidence` | 必填 | deep-design 项不适用的直接证据 |

### Artifact refs 与 materialization

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `proposed_artifact_references` | 必填 | Plan proposal references，可为空 |
| `materialization_target` | 必填 | 固定 `plan-pair` |

### Diagnostics 与 recommended route

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `gaps` | 必填 | Plan/evidence gaps，可为空 |
| `evidence` | 必填 | Assessment、Grounding 与 implementation evidence refs |
| `affected_semantics` | 必填 | 固定 `plan` |
| `recommended_route` | 必填 | advisory `plan-check | set-full-path-required | request-unblock` |

## Review Feedback owner re-entry

当本 Invocation 来自 Review Feedback 的 `simple-planning` continuation 时，result 必须原样保留 exact Feedback revision 与 owner continuation binding。只有 `ready` Plan pair 完整物化、重读并成为 current 后，control layer 才可另行记录 resolution observation；Capability 不得自行标记 resolved 或修改 unresolved set。`escalate-full`、`blocked`、Plan proposal 或文件存在不能关闭 Feedback。

## 权限与边界

- 可只读调查项目；不得修改项目实现、Current Request 或 Assessment。
- 不创建第二个 `simple-plan` artifact，不调用其他 Capability 或 Agent。
- 不批准 Plan，不执行实现，不计算或发明 digest/currentness。

## 停止条件

- Assessment 不是 current `simple-qualified`、`full_path_required = true` 或任一 binding stale 时停止。
- 形成 Plan 需要扩张简单边界时必须返回 `escalate-full`。
- Plan coverage 不完整时不得返回 `ready`。
- 工具、结果合同或 Invocation 失败属于 counted failure；external drift 单独 stop-and-revalidate。
