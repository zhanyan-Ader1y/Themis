# themis-summary

## 身份与固定绑定

- Stable identity：`themis-summary`。
- Authority scope：`lifecycle`。
- 固定 Agent Profile：`semantic-readonly`。
- 合法绑定：`simple/lightweight` 或 `full/full`。
- Materialization target：immutable paired Summary revision。
- 结果只是 bound delivery projection proposal；policy/recorder 物化后才可成为 current Summary。
- 不调用其他 Capability 或 Agent；只有 current Verification `passed` 且 current Human Acceptance `accepted` 后才可调用。

## 能力目标

描述 actual delivered result 并提供可选 governed knowledge candidates。Summary 不是中间阶段摘要，不产生新的需求、设计、实现、完成或知识 authority。

## 输入

- Current Request revision；
- approved Plan revision/digest 和 Review Approval；
- current Verification passed pair/evidence；
- current Human Acceptance accepted pair；
- actual implementation locations、limitations 和 explicit non-deliverables；
- lifecycle、Execution Identity、Invocation/attempt、policy 和 continuation bindings；
- Summary pair template。

## 合法状态

| Selected path | Profile | Status | 语义 |
|---|---|---|---|
| `simple` | `lightweight` | `ready` | 全部 gates 和 bindings current，形成完整 Summary proposal |
| `simple` | `lightweight` | `blocked` | 必要 record、evidence 或 binding 不可访问或失效 |
| `full` | `full` | `ready` | 全部 gates 和 bindings current，形成完整 Summary proposal |
| `full` | `full` | `blocked` | 必要 record、evidence 或 binding 不可访问或失效 |

`completed` 不是合法 Capability status。Summary pair 完整物化、reread 并成为 current 后，Policy 才另行记录 lifecycle completion observation；不得回写 immutable Summary。

## 输出字段合同

Result 顶层字段固定为：`capability` = `themis-summary`；`authority_scope` = `lifecycle`；`agent_profile` = `semantic-readonly`；`status` 必须是当前 selected path/profile 行中的一个合法终态。

### Input bindings

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `lifecycle_identity` | 必填 | current lifecycle identity |
| `execution_identity` | 必填 | lifecycle scope-local Execution Identity |
| `invocation_identity` | 必填 | Summary Invocation identity |
| `attempt_identity` | 必填 | Summary attempt identity |
| `current_request_revision` | 必填 | current Current Request revision |
| `approval_revision` | 必填 | current Review Approval revision |
| `plan_revision` | 必填 | approved Plan revision |
| `verification_revision` | 必填 | current `passed` Verification revision |
| `acceptance_revision` | 必填 | current `accepted` Human Acceptance revision |
| `policy_identity` | 必填 | `themis-core-control` |
| `policy_digest` | 必填 | 已加载 Policy digest reference |
| `continuation_identity` | 必填 | current Summary continuation |
| `selected_path` | 必填 | `simple | full`，与 Profile 锁定 |
| `profile` | 必填 | `lightweight | full`，与 selected path 锁定 |

### Structured result

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `summary_content` | `ready` 时必填 | actual delivered result、locations、limitations 与 explicit non-deliverables |
| `experience_candidates` | 必填 | 可选 governed experience candidates，可为空 |
| `project_knowledge_candidates` | 必填 | 可选 governed project knowledge candidates，可为空 |

### Artifact refs 与 materialization

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `proposed_artifact_references` | 必填 | Summary proposal refs，可为空 |
| `materialization_target` | 必填 | 固定 `summary-pair` |

### Diagnostics 与 recommended route

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `gaps` | 必填 | Summary/binding gaps，可为空 |
| `evidence` | 必填 | Plan、Approval、Verification、Acceptance 与 actual-result refs |
| `affected_semantics` | 必填 | 固定 `delivery_summary` |
| `recommended_route` | 必填 | advisory `complete-lifecycle | request-unblock` |

## 权限与边界

- 只读 approved Plan、actual implementation、Verification 和 Acceptance。
- 不得修改项目实现或 upstream artifacts，不调用其他 Capability 或 Agent。
- 不把 Summary 当作实现事实源、完成替代或知识发布动作。
- knowledge candidate 治理失败不改变 completed delivery。

## 停止条件

- Verification 非 current `passed`、Acceptance 非 current `accepted` 或 evidence/binding stale 时停止。
- actual result 与 records 无法追溯时不得返回 `ready`。
- 工具、结果合同或 Invocation 失败属于 counted failure；不得凭旧 Summary 推断完成。
