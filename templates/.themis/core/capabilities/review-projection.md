# themis-review-projection

## 身份与固定绑定

- Stable identity：`themis-review-projection`。
- Authority scope：`lifecycle`。
- 固定 Agent Profile：`semantic-readonly`。
- 合法绑定：`simple/lightweight` 或 `full/full`。
- Materialization target：immutable paired Review Projection revision。
- 结果只是完整 projection content proposal；policy/recorder 才能建立 revision 和 current pointer。
- 不调用其他 Capability 或 Agent；Review Projection 始终是 checked Plan 的只读投影。

## 能力目标

把 current checked Plan 压缩为低负担 Human Review 投影，帮助理解和导航，不替代 Plan，也不重新评价技术设计。

## 输入

- Current Request revision；
- selected path、profile 和 `full_path_required`；
- current Plan pair revision/digest；
- current passed Plan Check record；
- lifecycle、Execution Identity、Invocation/attempt、policy 和 continuation bindings；
- Review Projection pair template。

## 投影规则

按实际需要生成流程图或时序图 Overview，并覆盖目标/总体方案、架构/模块边界、重要行为/合同/不变量、关键取舍/风险、验收/Verification。Review 项由抽象到具体、影响由高到低；每项包含精简结论、推荐、依据、影响/取舍和 Plan 追溯位置。

## 合法状态

| Selected path | Profile | Status | 语义 |
|---|---|---|---|
| `simple` | `lightweight` | `ready` | 生成忠实、完整且低负担的 projection proposal |
| `simple` | `lightweight` | `blocked` | Plan、Plan Check 或必要 binding 不可访问 |
| `full` | `full` | `ready` | 生成忠实、完整且低负担的 projection proposal |
| `full` | `full` | `blocked` | Plan、Plan Check 或必要 binding 不可访问 |

## 输出字段合同

Result 顶层字段固定为：`capability` = `themis-review-projection`；`authority_scope` = `lifecycle`；`agent_profile` = `semantic-readonly`；`status` 必须是当前 selected path/profile 行中的一个合法终态。

### Input bindings

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `lifecycle_identity` | 必填 | current lifecycle identity |
| `execution_identity` | 必填 | lifecycle scope-local Execution Identity |
| `invocation_identity` | 必填 | producer Invocation identity |
| `attempt_identity` | 必填 | producer attempt identity |
| `current_request_revision` | 必填 | current Current Request revision |
| `plan_revision` | 必填 | current checked Plan revision |
| `plan_digest` | 必填 | bound Plan content digest reference |
| `plan_check_reference` | 必填 | current `pass` Plan Check reference |
| `policy_identity` | 必填 | `themis-core-control` |
| `policy_digest` | 必填 | 已加载 Policy digest reference |
| `continuation_identity` | 必填 | current Review Projection continuation |
| `review_feedback_revision` | Review owner re-entry 时必填 | exact Review Feedback revision；普通 Projection 时为 `null` |
| `review_feedback_owner_continuation_reference` | Review owner re-entry 时必填 | Feedback record 保存的 `review-projection` owner continuation reference；普通 Projection 时为 `null` |
| `selected_path` | 必填 | `simple | full`，与 Profile 锁定 |
| `profile` | 必填 | `lightweight | full`，与 selected path 锁定 |

### Structured result

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `review_content` | `ready` 时必填 | checked Plan 的 human projection content |
| `projection_map` | `ready` 时必填 | 每项 projection 到 Plan location/digest 的追溯表 |
| `diagram_rationale` | 必填 | 图形使用理由；不需要图形时说明 `not-required` 依据 |

### Artifact refs 与 materialization

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `proposed_artifact_references` | 必填 | Review proposal refs，可为空 |
| `materialization_target` | 必填 | 固定 `review-projection-pair` |

### Diagnostics 与 recommended route

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `gaps` | 必填 | projection gaps，可为空 |
| `evidence` | 必填 | Plan/Plan Check/projection evidence refs |
| `affected_semantics` | 必填 | 固定 `review_projection` |
| `recommended_route` | 必填 | advisory `review-check | request-unblock` |

## Review Feedback owner re-entry

当本 Invocation 来自 Review Feedback 的 `review-projection` continuation 时，result 必须原样保留 exact Feedback revision 与 owner continuation binding。只有 `ready` Review Projection pair 完整物化、重读并成为 current 后，control layer 才可另行记录 resolution observation；Capability 不得自行标记 resolved 或修改 unresolved set。`blocked`、projection proposal 或文件存在不能关闭 Feedback。

## 权限与边界

- 只读 Plan 和 bindings；不得修改实现或 Plan。
- 不引入 Plan 中不存在的决定、风险或推荐，不默认展示低价值内部细节。
- 不调用其他 Capability 或 Agent，不批准 Plan，不计算或发明 digest/currentness。

## 停止条件

- Plan Check 非 current `pass`、Plan/binding stale 或 path/profile 不匹配时停止。
- projection map 无法追溯关键 Review 内容时不得返回 `ready`。
- 工具、结果合同或 Invocation 失败属于 counted failure；external drift 单独 stop-and-revalidate。
