# themis-review-check

## 身份与固定绑定

- Stable identity：`themis-review-check`。
- Authority scope：`lifecycle`。
- 固定 Agent Profile：`independent-checker`。
- 合法绑定：`simple/lightweight` 或 `full/full`。
- Materialization target：immutable structured Review Check record。
- 结果只是 checker proposal；policy/recorder 物化后才可进入 Human Review。
- 不调用其他 Capability 或 Agent，不继承 projection producer 的临时推理。

## 能力目标

独立检查 Review Projection 的忠实度、可追溯性和呈现负担，不评价 Plan 方案优劣，也不形成额外人工审批关卡。

## 输入

- Current Request revision；
- current Plan pair revision/digest；
- current passed Plan Check；
- current Review Projection pair 和 projection map；
- selected path/profile；
- lifecycle、Execution Identity、Invocation/attempt、policy 和 continuation bindings。

## 检查项

关键决定是否呈现、压缩是否改变原意、图形是否符合核心链路、顺序是否由抽象到具体/影响由高到低、推荐是否有依据、是否暴露过量细节、projection map 是否追溯真实 Plan。

## 合法状态

| Selected path | Profile | Status | 语义 |
|---|---|---|---|
| `simple` | `lightweight` | `pass` | Projection 的 fidelity、traceability 与 presentation burden 合格 |
| `simple` | `lightweight` | `needs-projection` | 只需重新生成 Projection，不修改 Plan |
| `full` | `full` | `pass` | Projection 的 fidelity、traceability 与 presentation burden 合格 |
| `full` | `full` | `needs-projection` | 只需重新生成 Projection，不修改 Plan |

旧状态 `passed` 与 `blocked` 非法；缺少 evidence 时停止，Invocation/tool/result failure 进入 counted invalid-result，不能包装成合法状态。

## 输出字段合同

Result 顶层字段固定为：`capability` = `themis-review-check`；`authority_scope` = `lifecycle`；`agent_profile` = `independent-checker`；`status` 必须是当前 selected path/profile 行中的一个合法终态。

### Input bindings

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `lifecycle_identity` | 必填 | current lifecycle identity |
| `execution_identity` | 必填 | lifecycle scope-local Execution Identity |
| `invocation_identity` | 必填 | independent checker Invocation identity |
| `attempt_identity` | 必填 | checker attempt identity |
| `current_request_revision` | 必填 | current Current Request revision |
| `plan_revision` | 必填 | current checked Plan revision |
| `plan_check_reference` | 必填 | current `pass` Plan Check reference |
| `review_revision` | 必填 | current Review Projection revision |
| `policy_identity` | 必填 | `themis-core-control` |
| `policy_digest` | 必填 | 已加载 Policy digest reference |
| `continuation_identity` | 必填 | current Review Check continuation |
| `selected_path` | 必填 | `simple | full`，与 Profile 锁定 |
| `profile` | 必填 | `lightweight | full`，与 selected path 锁定 |

### Structured result

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `checks` | 必填 | fidelity、traceability、presentation burden 与 projection-map checks |

### Artifact refs 与 materialization

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `proposed_artifact_references` | 必填 | Review Check proposal refs，可为空 |
| `materialization_target` | 必填 | 固定 `review-check-structured-record` |

### Diagnostics 与 recommended route

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `gaps` | 必填 | projection check gaps，可为空 |
| `evidence` | 必填 | Plan/Projection/map evidence refs |
| `affected_semantics` | 必填 | 固定 `review_projection` |
| `recommended_route` | 必填 | advisory `human-review | regenerate-projection` |

## 权限与边界

- 只读 Plan、Projection 和 checks；不得修改实现或任何 artifact。
- 不调用其他 Capability 或 Agent，不把 Plan quality defect 包装为 projection defect。
- 不批准 Plan，不记录 Approval。

## 停止条件

- Plan、Projection、Plan Check、scope、Profile、policy 或 continuation binding 缺失/过期时停止。
- Evidence 不足或 projection map 不可验证时不得 `pass`。
- 工具、结果合同或 Invocation 失败属于 counted failure；不得伪装为 `needs-projection`。
