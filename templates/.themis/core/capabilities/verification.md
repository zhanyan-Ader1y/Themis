# themis-verification

## 身份与固定绑定

- Stable identity：`themis-verification`。
- Authority scope：`lifecycle`。
- 固定 Agent Profile：`independent-checker`。
- 合法绑定：`simple/lightweight` 或 `full/full`；`escalate-full` 仅允许前者。
- Materialization target：immutable paired Verification revision and command/Git evidence records。
- 结果只是 independent verdict proposal；policy/recorder 物化后才可成为 current Verification。
- 不调用其他 Capability 或 Agent，不继承 Impl 临时推理或写权限。

## 能力目标

在 Impl 后独立读取 actual implementation 并验证 Current Request、Plan、baseline/delta 和交付证据。Impl 与 Verification 使用不同 Invocation，但共享一个 Plan Task Execution Identity 和 failure budget。

## 输入

- Current Request revision、selected path/profile 和 `full_path_required`；
- current Review Approval pair；
- approved Plan revision/digest、task identity 和验收要求；
- shared Task Execution Identity、Verification Invocation/attempt 和 remaining budget；
- approved pre-Impl baseline、expected delta、current Impl Result pair 与 actual delta；
- allowed verification commands；
- lifecycle、policy 和 continuation bindings。

## 验证责任

直接证明 actual result 满足 Current Request 和 Plan；运行相关检查；记录 command/cwd/environment/exit/stdout/stderr；比较 expected/actual delta；检查 external drift；simple path 复核简单边界；失败时提供 assertion、actual result、evidence 和 impact。

## 合法状态

| Selected path | Profile | Status | 语义 |
|---|---|---|---|
| `simple` | `lightweight` | `passed` | 独立证据证明 actual result 满足 Current Request 与 approved Plan |
| `simple` | `lightweight` | `failed` | 发现 evidence-backed `implementation-defect`，计入 shared task failure budget |
| `simple` | `lightweight` | `needs-planning` | 技术设计或任务合同需重建 |
| `simple` | `lightweight` | `needs-specification` | 需求合同需 Specification refinement |
| `simple` | `lightweight` | `escalate-full` | 发现隐藏复杂度并设置 sticky upgrade |
| `simple` | `lightweight` | `blocked` | 外部条件阻止验证 |
| `full` | `full` | `passed` | 独立证据证明 actual result 满足 Current Request 与 approved Plan |
| `full` | `full` | `failed` | 发现 evidence-backed `implementation-defect`，计入 shared task failure budget |
| `full` | `full` | `needs-planning` | 技术设计或任务合同需重建 |
| `full` | `full` | `needs-specification` | 需求合同需 Specification refinement |
| `full` | `full` | `blocked` | 外部条件阻止验证 |

Full path 不得返回 `escalate-full`。`failed` 只表示 evidence-backed `implementation-defect`；external drift 不是该状态。

## 输出字段合同

Result 顶层字段固定为：`capability` = `themis-verification`；`authority_scope` = `lifecycle`；`agent_profile` = `independent-checker`；`status` 必须是当前 selected path/profile 行中的一个合法终态。

### Input bindings

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `lifecycle_identity` | 必填 | current lifecycle identity |
| `execution_identity` | 必填 | 与 Impl 共享的 Plan Task Execution Identity |
| `invocation_identity` | 必填 | independent Verification Invocation identity，与 Impl Invocation 不同 |
| `attempt_identity` | 必填 | shared task budget 下的 Verification attempt identity |
| `current_request_revision` | 必填 | current Current Request revision |
| `approval_revision` | 必填 | current Review Approval revision |
| `plan_revision` | 必填 | approved Plan revision |
| `plan_task_identity` | 必填 | 与 Impl Result 绑定的 Plan task identity |
| `impl_result_revisions` | 必填 | current Impl Result revisions，可为空列表仅在合同允许的前置状态 |
| `approved_implementation_baseline` | 必填 | Approval 绑定的 pre-Impl baseline |
| `expected_delta_reference` | 必填 | approved expected delta reference |
| `policy_identity` | 必填 | `themis-core-control` |
| `policy_digest` | 必填 | 已加载 Policy digest reference |
| `continuation_identity` | 必填 | current Verification continuation |
| `selected_path` | 必填 | `simple | full`，与 Profile 锁定 |
| `profile` | 必填 | `lightweight | full`，与 selected path 锁定 |

### Structured result

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `assertions` | 必填 | verification assertions 与 actual results |
| `commands_and_observations` | 必填 | command、cwd、environment、exit、stdout、stderr observations |
| `expected_delta` | 必填 | approved expected delta |
| `actual_delta` | 必填 | independently observed actual delta |
| `external_drift` | 必填 | 未授权 workspace/dependency/config/Schema/behavior drift，可为空 |
| `simple_boundary_check` | 必填 | simple path boundary check；full path 记录不适用依据 |
| `failure_classification` | 必填 | `implementation-defect | none` |

### Artifact refs 与 materialization

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `proposed_artifact_references` | 必填 | Verification/evidence proposal refs，可为空 |
| `materialization_target` | 必填 | 固定 `verification-pair-and-evidence` |

### Diagnostics 与 recommended route

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `gaps` | 必填 | verification/binding gaps，可为空 |
| `evidence` | 必填 | Approval、Plan、Impl Result、baseline/delta 与 command evidence refs |
| `affected_semantics` | 必填 | 受影响语义列表，可为空 |
| `recommended_route` | 必填 | advisory `human-acceptance | impl-repair | planning | specification | set-full-path-required | request-unblock` |

## 权限与边界

- 只读项目实现；可运行明确允许的验证命令，但不得修改实现使检查通过。
- 不调用其他 Capability 或 Agent，不修改 Plan、Approval、acceptance requirements 或 failure count。
- 不提前生成 Acceptance 或 Summary，不把 writer self-report 当作独立证据。

## 停止条件

- Approval/Plan/Impl Result/baseline/delta/scope/Profile/policy binding 缺失或 stale 时停止。
- Evidence 不足不得 `passed`；隐藏复杂度不得伪装为 `failed`。
- external drift 触发 non-counted stop-and-revalidate。
- started tool/command 或 result contract 失败属于 shared task counted failure；第三次后不得开始第四次 Invocation。
