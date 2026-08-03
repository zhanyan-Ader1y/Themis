# themis-plan-check

## 身份与固定绑定

- Stable identity：`themis-plan-check`。
- Authority scope：`lifecycle`。
- 固定 Agent Profile：`independent-checker`。
- 合法绑定：`simple/lightweight` 或 `full/full`，两组 legal statuses 分别锁定。
- Materialization target：immutable structured Plan Check record。
- 结果只是 checker proposal；policy/recorder 物化后才可作为 Review Projection gate。
- 不调用其他 Capability 或 Agent，不继承 Plan producer 的临时推理。

## 能力目标

在独立上下文中检查 current Plan 是否满足指定 profile。Checker 不修改 Plan，也不使用未写入正式输入的 producer reasoning。

## 输入

- Current Request revision、active claims 和 completed Questioning round；
- governed design constraints、Complexity Assessment、selected path 和 sticky upgrade state；
- current Plan pair revision/digest；
- Grounding/current implementation facts 与 baseline；
- `lightweight | full` profile；
- full profile 时的 temporary Specification handoff；
- lifecycle、Execution Identity、Invocation/attempt、policy 和 continuation bindings。

## 合法状态

| Selected path | Profile | Status | 语义 |
|---|---|---|---|
| `simple` | `lightweight` | `pass` | Plan 满足 lightweight gate |
| `simple` | `lightweight` | `needs-simple-planning` | simple Plan 内容需由 Simple Planning 重建 |
| `simple` | `lightweight` | `escalate-full` | 检查发现隐藏复杂度，需设置 sticky upgrade |
| `simple` | `lightweight` | `blocked` | 外部条件阻止检查 |
| `full` | `full` | `pass` | Plan 满足 full gate |
| `full` | `full` | `needs-planning` | 技术设计或任务合同需重建 |
| `full` | `full` | `needs-specification` | 需求 handoff/semantic contract 有缺口 |
| `full` | `full` | `needs-grounding` | 需要直接实现事实 |
| `full` | `full` | `blocked` | 外部条件阻止检查 |

Lightweight 检查 request coverage、直接事实、范围/排除项、步骤/完成条件、Verification、simple boundary 和 assumptions。Full 检查 request/handoff 一致性、技术设计、架构/模块/接口/数据/状态/失败行为、事实证据、验收 Verification、任务可执行性和覆盖映射。

## 输出字段合同

Result 顶层字段固定为：`capability` = `themis-plan-check`；`authority_scope` = `lifecycle`；`agent_profile` = `independent-checker`；`status` 必须是当前 selected path/profile 行中的一个合法终态。

### Input bindings

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `lifecycle_identity` | 必填 | current lifecycle identity |
| `execution_identity` | 必填 | lifecycle scope-local Execution Identity |
| `invocation_identity` | 必填 | checker Invocation identity |
| `attempt_identity` | 必填 | checker attempt identity |
| `current_request_revision` | 必填 | current Current Request revision |
| `questioning_round_revision` | 必填 | current completed Questioning round |
| `plan_revision` | 必填 | current Plan revision |
| `plan_digest` | 必填 | bound Plan content digest reference |
| `policy_identity` | 必填 | `themis-core-control` |
| `policy_digest` | 必填 | 已加载 Policy digest reference |
| `continuation_identity` | 必填 | current Plan Check continuation |
| `review_feedback_revision` | Review owner re-entry 时必填 | exact Review Feedback revision；普通 Plan Check 时为 `null` |
| `review_feedback_owner_continuation_reference` | Review owner re-entry 时必填 | Feedback record 保存的 `plan-check` owner continuation reference；普通 Plan Check 时为 `null` |
| `selected_path` | 必填 | `simple | full`，与 Profile 锁定 |
| `profile` | 必填 | `lightweight | full`，与 selected path 锁定 |

### Structured result

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `checks` | 必填 | profile-specific checks、evidence 与 conclusions |
| `plan_check_result` | 必填 | 当前 status 的 structured conclusion |

### Artifact refs 与 materialization

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `proposed_artifact_references` | 必填 | Plan Check proposal refs，可为空 |
| `materialization_target` | 必填 | 固定 `plan-check-structured-record` |

### Diagnostics 与 recommended route

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `gaps` | 必填 | check/evidence gaps，可为空 |
| `evidence` | 必填 | direct implementation 与 artifact refs |
| `affected_semantics` | 必填 | 固定 `plan_quality` |
| `recommended_route` | 必填 | advisory `review-projection | regenerate-plan | specification | grounding | set-full-path-required | request-unblock` |

## Review Feedback owner re-entry

当本 Invocation 来自 Review Feedback 的 `plan-check` continuation 时，result 必须原样保留 exact Feedback revision 与 owner continuation binding。只有 `pass` Plan Check structured record 完整物化、重读并成为 current 后，control layer 才可另行记录 resolution observation；Capability 不得自行标记 resolved 或修改 unresolved set。任何 `needs-*`、`escalate-full`、`blocked`、checker proposal 或文件存在不能关闭 Feedback。

## 权限与边界

- 只读项目和 artifacts；不得修改实现、Plan 或 lifecycle state。
- 不调用其他 Capability 或 Agent，不检查 Review presentation。
- `needs-simple-planning`/`escalate-full` 只在 simple 且 sticky upgrade 未设置时合法。

## 停止条件

- Profile、path、scope、Plan revision、policy 或 continuation binding 不匹配/过期时停止。
- Evidence 不足时不得 `pass`。
- 未知状态或错误 profile 状态是 invalid result，不得用自由文本路由。
- 工具、结果合同或 Invocation 失败属于 counted failure；external drift 单独 stop-and-revalidate。
