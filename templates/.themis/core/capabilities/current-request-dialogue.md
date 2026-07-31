# themis-current-request-dialogue

## 内部执行合同

- Stable identity：`themis-current-request-dialogue`。
- Authority scope：`request-intake`。
- 固定 Agent Profile：`human-dialogue`。
- 唯一合法绑定：`selected_path: null`、`profile: null`。
- Materialization target：按状态生成 structured Intake proposal 或 decision；任何 Current Request paired revision 只能由后续 policy control action 物化。
- 结果只是 proposal，不得修改 Intake/lifecycle state、创建 lifecycle、写 Current Request 或执行 route。
- 不调用其他 Capability 或 Agent，不从沉默、模糊肯定、邻近消息或聊天历史推断确认。

## 能力目标

处理每条不可变外部 Source Event，比较 source-bound confirmed claims，提出 changed-only claim/assignment diff，并在独立的后续确认 Invocation 中形成 assignment decision proposal，同时保留原 durable dialogue continuation。

## 输入

- Intake identity、Intake Execution Identity、Invocation identity 和 attempt identity；
- 当前不可变 Source Event 的 raw-byte metadata 与 fragment references；
- durable attachment decision 和 continuation identity；
- pending proposal identity/digest 与 prior confirmation refs（存在时）；
- 相关 lifecycle 的 Current Request revision、confirmed claim revisions 与 assignment refs；
- original dialogue continuation；
- policy identity/digest、remaining failure budget、允许读取范围和禁止写入声明。

Source fragment 必须使用 `event identity + UTF-8 byte range + quoted fragment digest`。不得以归一化文本、Agent summary、Specification、Plan 或历史对话替代用户来源。

## 对话协议

存在 claim 或 assignment 变化时必须使用两次 Invocation：

```text
Source Event
→ first Invocation
→ needs-request-confirmation
→ persist proposal and wait
→ confirmation Source Event
→ second Invocation
→ assignment-confirmed
→ policy-controlled materialization
```

无变化时可以返回 `assignment-confirmed` 和结构化 `no-change` operation，不要求用户重复确认。

## 合法状态

```text
needs-request-confirmation
assignment-confirmed
rejected
```

- `needs-request-confirmation`：返回完整 changed-only proposal、stable diff item identities、source fragments、允许 dispositions、full diff digest 和 confirmation continuation。
- `assignment-confirmed`：非空 diff 必须绑定 pending proposal、确认 Source Event、每个必需 item 的明确 disposition 和完整 diff digest；空 diff 必须绑定 current confirmed assignment、claims unchanged 结论和 `no-change` operation。
- `rejected`：只在用户明确拒绝时返回，绑定拒绝 Source Event、空 lifecycle operations 和 rejection decision proposal。

## 输出

```yaml
capability: themis-current-request-dialogue
authority_scope: request-intake
agent_profile: human-dialogue
status: needs-request-confirmation | assignment-confirmed | rejected
input_bindings:
  intake_identity: ""
  execution_identity: ""
  invocation_identity: ""
  attempt_identity: ""
  source_event_reference: ""
  pending_proposal_reference: null
  current_request_references: []
  current_claim_revisions: []
  original_dialogue_continuation: ""
  policy_identity: ""
  policy_digest: ""
  continuation_identity: ""
  selected_path: null
  profile: null
output:
  structured_result:
    operation: changed-diff | confirmation-decision | no-change | rejection
    changed_only_diff: {}
    user_visible_diff: ""
    item_dispositions: []
    assignment_operations: []
    assignment_decision: {}
    confirmation_continuation: null
    original_dialogue_continuation: ""
  proposed_artifact_references: []
  materialization_target: request-intake-proposal | request-intake-decision
diagnostics:
  gaps: []
  evidence: []
  affected_semantics: [request_claims, lifecycle_assignment]
recommended_route: await-confirmation | materialize-assignment | close-intake
```

## 权限与边界

- 可以向用户展示精简语义 diff，并逐项接收 `confirm | correct | keep-ambiguous`。
- 不得直接写 Source Event、Intake proposal/decision、Current Request、pointer 或任何 state。
- 不得创建、更新、拆分或合并 lifecycle；只能提出逐目标 operation。
- 不得改变 original dialogue continuation，也不得把 Intake 失败计入 lifecycle budget。
- 不调用其他 Capability 或 Agent，不执行 policy control action。

## 停止条件

- Source Event、Intake identity、scope、Profile、policy 或 continuation binding 缺失/过期时停止并返回非法结果诊断。
- 非空 diff 未覆盖每个必需 item、缺少 source fragment 或 full diff digest 时不得返回 `assignment-confirmed`。
- 用户决定模糊、遗漏或沉默时保持 `needs-request-confirmation`，不得推断完成。
- 工具、结果合同或 Invocation 执行失败属于 request-intake counted failure，不得包装为合法状态。
