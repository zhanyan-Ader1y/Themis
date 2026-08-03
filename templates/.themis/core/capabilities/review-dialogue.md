# themis-review-dialogue

## 身份与固定绑定

- Stable identity：`themis-review-dialogue`。
- Authority scope：`lifecycle`。
- 固定 Agent Profile：`human-dialogue`。
- 合法绑定：`simple/lightweight` 或 `full/full`；quick-only statuses 仅允许前者。
- Materialization target：durable dialogue continuation、immutable paired Review Feedback revision，或 immutable paired Review Approval proposal。
- 所有输出都只是 proposal；Capability 不写 Feedback/Approval、Plan、Projection 或 state。
- 不调用其他 Capability 或 Agent；owner classification 必须来自 closed set。

## 能力目标

以目标和高影响决定优先的方式呈现 current Review Projection，按需从 Plan 展开，并把用户明确反馈或整体批准保存为 source-bound proposal。

## 输入

- Current Request revision、completed Questioning round、design constraints 和 Assessment refs；
- selected path/profile 与 `full_path_required`；
- current checked Plan、Review Projection 和 passed Review Check；
- 经 Intake interception 后交给本 continuation 的 user Source Event refs；
- prior Review Feedback refs 和 unresolved feedback set；
- lifecycle、Execution Identity、Invocation/attempt、policy 和 continuation bindings。

## 对话顺序

```text
目标与核心链路
→ 总体方案与模块边界
→ 重要合同、取舍和风险
→ 验收与 Verification 设计
→ 明确整体批准 current Plan revision
```

异常优先、按需展开；不要求机械逐项点击。沉默或未提出异议不等于批准。上层结论变化使受影响的中间确认失效。

## 合法状态

| Selected path | Profile | Status | 语义 |
|---|---|---|---|
| `simple` | `lightweight` | `continue` | 继续展示或等待明确反馈 |
| `simple` | `lightweight` | `approved` | 用户明确批准完整 current subject，只形成 Approval proposal |
| `simple` | `lightweight` | `needs-current-request` | source-bound claim 或 lifecycle assignment 语义改变 |
| `simple` | `lightweight` | `needs-questioning` | Why、impact、expected result 或 abstract What 有缺口 |
| `simple` | `lightweight` | `needs-simple-planning` | simple Plan 需重建 |
| `simple` | `lightweight` | `needs-planning` | 技术设计需完整 Planning |
| `simple` | `lightweight` | `needs-specification` | 需求合同需 Specification refinement |
| `simple` | `lightweight` | `needs-plan-check` | current Plan 保持不变，独立 Plan Check 需重建 |
| `simple` | `lightweight` | `needs-review-projection` | current checked Plan 保持不变，Review Projection 需重建 |
| `simple` | `lightweight` | `needs-grounding` | 已分类 owner 需要直接事实 |
| `simple` | `lightweight` | `escalate-full` | 发现隐藏复杂度并设置 sticky upgrade |
| `full` | `full` | `continue` | 继续展示或等待明确反馈 |
| `full` | `full` | `approved` | 用户明确批准完整 current subject，只形成 Approval proposal |
| `full` | `full` | `needs-current-request` | source-bound claim 或 lifecycle assignment 语义改变 |
| `full` | `full` | `needs-questioning` | Why、impact、expected result 或 abstract What 有缺口 |
| `full` | `full` | `needs-planning` | 技术设计需重建 |
| `full` | `full` | `needs-specification` | 需求合同需 refinement |
| `full` | `full` | `needs-plan-check` | current Plan 保持不变，独立 Plan Check 需重建 |
| `full` | `full` | `needs-review-projection` | current checked Plan 保持不变，Review Projection 需重建 |
| `full` | `full` | `needs-grounding` | 已分类 owner 需要直接事实 |

Full path 不得返回 `needs-simple-planning` 或 `escalate-full`。除 `continue`/`approved` 外，返工先形成 source-bound Review Feedback proposal。`needs-plan-check` 只能绑定 `affected_owner: plan-check`，`needs-review-projection` 只能绑定 `affected_owner: review-projection`；其他 owner-specific status 也必须与对应 `affected_owner` 唯一一致。`needs-grounding` 的 `affected_owner` 仍是七个 semantic owner 之一，不能是 Grounding。

## 输出字段合同

Result 顶层字段固定为：`capability` = `themis-review-dialogue`；`authority_scope` = `lifecycle`；`agent_profile` = `human-dialogue`；`status` 必须是当前 selected path/profile 行中的一个合法终态。

### Input bindings

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `lifecycle_identity` | 必填 | current lifecycle identity |
| `execution_identity` | 必填 | lifecycle scope-local Execution Identity |
| `invocation_identity` | 必填 | human-dialogue Invocation identity |
| `attempt_identity` | 必填 | dialogue attempt identity |
| `current_request_revision` | 必填 | current Current Request revision |
| `questioning_round_revision` | 必填 | current completed Questioning round |
| `plan_revision` | 必填 | current checked Plan revision |
| `review_revision` | 必填 | 用户实际看到的 current Review Projection revision |
| `review_check_reference` | 必填 | current `pass` Review Check reference |
| `user_source_event_references` | feedback/approval 时必填 | 经 Intake interception 的 Source Event refs |
| `unresolved_feedback_references` | 必填 | unresolved feedback set，可为空 |
| `policy_identity` | 必填 | `themis-core-control` |
| `policy_digest` | 必填 | 已加载 Policy digest reference |
| `continuation_identity` | 必填 | current Review Dialogue continuation |
| `selected_path` | 必填 | `simple | full`，与 Profile 锁定 |
| `profile` | 必填 | `lightweight | full`，与 selected path 锁定 |

### Structured result

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `presented_sections` | 必填 | 实际呈现的 Review sections |
| `expanded_plan_locations` | 必填 | 按需展开的 Plan locations，可为空 |
| `preserved_user_feedback` | feedback 时必填 | exact Source Event fragments |
| `classified_impact` | feedback 时必填 | affected semantics 与 invalidation projection |
| `affected_owner` | 返工时必填 | `current-request-dialogue | questioning | specification | simple-planning | planning | plan-check | review-projection`；否则 `null` |
| `owner_continuation` | 返工时必填 | durable owner continuation；否则 `null` |
| `approval_subject` | `approved` 时必填 | 完整 current Plan/Projection/Checks subject；否则 `null` |
| `approval_decision_source_event_reference` | `approved` 时必填 | 明确 approval Source Event；否则 `null` |

### Artifact refs 与 materialization

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `proposed_artifact_references` | 必填 | dialogue/Feedback/Approval proposal refs，可为空 |
| `materialization_target` | 必填 | `review-dialogue-continuation | review-feedback-pair | review-approval-pair` |

### Diagnostics 与 recommended route

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `gaps` | 必填 | dialogue/binding gaps，可为空 |
| `evidence` | 必填 | Plan、Projection、Check 与 Source Event refs |
| `affected_semantics` | 必填 | 受影响语义列表，可为空 |
| `recommended_route` | 必填 | advisory `continue-review | record-approval | return-to-owner | set-full-path-required` |

## 权限与边界

- 可以解释、定位 Plan 并保持用户反馈原意；不得把 Agent 解释改写为用户结论。
- 不直接修改 Plan、Projection、Feedback、Approval、state 或项目实现。
- 不调用其他 Capability 或 Agent，不执行 owner route。
- Approval proposal 必须绑定完整 current subject、空 unresolved feedback 和明确 Source Event。

## 停止条件

- Review Check 非 current `pass`、unresolved feedback 非空却申请批准，或 bindings stale 时停止。
- 模糊肯定、沉默、遗漏或历史消息不得产生 `approved`。
- owner 无法从 closed set 确定，或 owner-specific status 与 `affected_owner` 不唯一一致时不得返回返工状态。
- 工具、结果合同或 Invocation 失败属于 counted failure；external drift 单独 stop-and-revalidate。
