# themis-acceptance-dialogue

## 身份与固定绑定

- Stable identity：`themis-acceptance-dialogue`。
- Authority scope：`lifecycle`。
- 固定 Agent Profile：`human-dialogue`。
- 合法绑定：`simple/lightweight` 或 `full/full`；`escalate-full` 仅允许前者。
- Materialization target：immutable paired Human Acceptance revision。
- 结果只是 source-bound Acceptance proposal；policy/recorder 物化后才可成为 current Acceptance。
- 不调用其他 Capability 或 Agent；只有 current Verification `passed` 后才可调用。

## 能力目标

向用户展示实际交付和精简验收证据，保存用户对 actual result 的明确观察与分类，而不是重复技术 Verification。

## 输入

- Current Request revision、selected path/profile 和 `full_path_required`；
- approved Plan、Review Approval 和 current Verification passed pair/evidence；
- 精简 acceptance view；
- 经 Intake interception 后交给本 continuation 的 user Source Event refs；
- lifecycle、Execution Identity、Invocation/attempt、policy 和 continuation bindings。

保持用户原话与 Source Event refs，不把 Agent 解释写成用户结论。

## 合法状态

| Selected path | Profile | Status | 语义 |
|---|---|---|---|
| `simple` | `lightweight` | `accepted` | 用户明确接受 current actual result |
| `simple` | `lightweight` | `implementation-defect` | Plan 仍有效，在 approved scope 内使用同一 Plan Task Execution Identity 与 failure budget 返回 Impl repair，随后必须重新 independent Verification |
| `simple` | `lightweight` | `needs-planning` | 技术设计或任务合同需改变 |
| `simple` | `lightweight` | `needs-specification` | 需求语义需 Specification refinement |
| `simple` | `lightweight` | `escalate-full` | 发现隐藏复杂度并设置 sticky upgrade |
| `full` | `full` | `accepted` | 用户明确接受 current actual result |
| `full` | `full` | `implementation-defect` | Plan 仍有效，在 approved scope 内使用同一 Plan Task Execution Identity 与 failure budget 返回 Impl repair，随后必须重新 independent Verification |
| `full` | `full` | `needs-planning` | 技术设计或任务合同需改变 |
| `full` | `full` | `needs-specification` | 需求语义需 Specification refinement |

Full path 不得返回 `escalate-full`。

## 输出字段合同

Result 顶层字段固定为：`capability` = `themis-acceptance-dialogue`；`authority_scope` = `lifecycle`；`agent_profile` = `human-dialogue`；`status` 必须是当前 selected path/profile 行中的一个合法终态。

### Input bindings

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `lifecycle_identity` | 必填 | current lifecycle identity |
| `execution_identity` | 必填 | lifecycle scope-local Execution Identity；repair 时保持原 Plan Task Execution Identity |
| `invocation_identity` | 必填 | Human Acceptance Invocation identity |
| `attempt_identity` | 必填 | acceptance dialogue attempt identity |
| `current_request_revision` | 必填 | current Current Request revision |
| `approval_revision` | 必填 | current Review Approval revision |
| `plan_revision` | 必填 | approved Plan revision |
| `verification_revision` | 必填 | current `passed` Verification revision |
| `acceptance_source_event_references` | 必填 | 经 Intake interception 的用户观察/决定 Source Event refs |
| `policy_identity` | 必填 | `themis-core-control` |
| `policy_digest` | 必填 | 已加载 Policy digest reference |
| `continuation_identity` | 必填 | current Human Acceptance continuation |
| `selected_path` | 必填 | `simple | full`，与 Profile 锁定 |
| `profile` | 必填 | `lightweight | full`，与 selected path 锁定 |

### Structured result

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `acceptance_view` | 必填 | 展示给用户的 actual delivery 与精简 evidence view |
| `preserved_user_feedback` | 必填 | 用户 exact Source Event fragments |
| `observed_difference` | 必填 | 用户观察到的 actual-result difference |
| `classification_reason` | 必填 | 对 closed status 的 source-bound 分类依据 |

### Artifact refs 与 materialization

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `proposed_artifact_references` | 必填 | Human Acceptance proposal refs，可为空 |
| `materialization_target` | 必填 | 固定 `human-acceptance-pair` |

### Diagnostics 与 recommended route

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `gaps` | 必填 | acceptance/binding gaps，可为空 |
| `evidence` | 必填 | Plan、Approval、Verification 与 Source Event refs |
| `affected_semantics` | 必填 | 受影响语义列表，可为空 |
| `recommended_route` | 必填 | advisory `summary | impl-repair | planning | specification | set-full-path-required` |

## 权限与边界

- 可以与用户交互并解释 acceptance evidence。
- 不得修改项目实现、Plan、Review、Approval、Verification 或 acceptance requirements。
- 不调用其他 Capability 或 Agent，不记录 machine state 或 failure count。
- 不从沉默、模糊肯定或没有 Source Event 的聊天推断 accepted/rejection classification。

## 停止条件

- Verification 非 current `passed` 或任一 binding stale 时停止。
- 用户没有明确观察/决定时不得返回 `accepted` 或 defect classification。
- full path 返回 `escalate-full` 是 invalid result。
- 工具、结果合同或 Invocation 失败属于 counted failure；external drift 单独 stop-and-revalidate。
