# themis-review-dialogue

## 内部执行合同

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

```text
continue
approved
needs-current-request
needs-questioning
needs-simple-planning
needs-planning
needs-specification
needs-grounding
escalate-full
```

- `continue`：需要继续展示或等待明确反馈。
- `approved`：用户明确批准完整 current subject，只形成 Approval proposal。
- `needs-current-request`：反馈改变 source-bound claim 或 lifecycle assignment 语义，owner 为 Current Request Dialogue。
- `needs-questioning`：反馈暴露 Why、impact、expected result 或 abstract What 缺口，owner 为 `themis-q`。
- 其余返工状态形成 source-bound Review Feedback proposal，并分类到真实 semantic owner。
- `needs-grounding` 只请求 owner 所需事实证据；`affected_owner` 仍必须是 approved semantic owner，不能是 Grounding。
- `needs-simple-planning`/`escalate-full` 只在 simple 且 sticky upgrade 未设置时合法；full path 不得返回。

## 输出

```yaml
capability: themis-review-dialogue
authority_scope: lifecycle
agent_profile: human-dialogue
status: <legal dialogue status>
input_bindings:
  lifecycle_identity: ""
  execution_identity: ""
  invocation_identity: ""
  attempt_identity: ""
  current_request_revision: ""
  questioning_round_revision: ""
  plan_revision: ""
  review_revision: ""
  review_check_reference: ""
  user_source_event_references: []
  unresolved_feedback_references: []
  policy_identity: ""
  policy_digest: ""
  continuation_identity: ""
  selected_path: simple | full
  profile: lightweight | full
output:
  structured_result:
    presented_sections: []
    expanded_plan_locations: []
    preserved_user_feedback: []
    classified_impact: ""
    affected_owner: current-request-dialogue | questioning | specification | simple-planning | planning | plan-check | review-projection | null
    owner_continuation: null
    approval_subject: null
    approval_decision_source_event_reference: null
  proposed_artifact_references: []
  materialization_target: review-dialogue-continuation | review-feedback-pair | review-approval-pair
diagnostics:
  gaps: []
  evidence: []
  affected_semantics: []
recommended_route: continue-review | record-approval | return-to-owner | set-full-path-required
```

## 权限与边界

- 可以解释、定位 Plan 并保持用户反馈原意；不得把 Agent 解释改写为用户结论。
- 不直接修改 Plan、Projection、Feedback、Approval、state 或项目实现。
- 不调用其他 Capability 或 Agent，不执行 owner route。
- Approval proposal 必须绑定完整 current subject、空 unresolved feedback 和明确 Source Event。

## 停止条件

- Review Check 非 current `pass`、unresolved feedback 非空却申请批准，或 bindings stale 时停止。
- 模糊肯定、沉默、遗漏或历史消息不得产生 `approved`。
- owner 无法从 closed set 确定时不得返回返工状态。
- 工具、结果合同或 Invocation 失败属于 counted failure；external drift 单独 stop-and-revalidate。
