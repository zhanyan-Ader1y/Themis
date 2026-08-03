# themis-current-request-dialogue

## 身份与固定绑定

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

| Selected path | Profile | Status | 语义 |
|---|---|---|---|
| `null` | `null` | `needs-request-confirmation` | 返回完整 changed-only proposal、stable diff item identities、source fragments、允许 dispositions、full diff digest 和 confirmation continuation |
| `null` | `null` | `assignment-confirmed` | 非空 diff 绑定 pending proposal、confirmation Source Event、逐项 disposition 与 full diff digest；空 diff 绑定 current assignment、claims unchanged 与 `no-change` operation |
| `null` | `null` | `rejected` | 只在用户明确拒绝时返回 rejection decision proposal，不产生 lifecycle operations |

## 输出字段合同

Result 顶层字段固定为：`capability` = `themis-current-request-dialogue`；`authority_scope` = `request-intake`；`agent_profile` = `human-dialogue`；`status` 必须是当前 `null/null` 行中的一个合法终态。

### Input bindings

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `intake_identity` | 必填 | current Intake identity |
| `execution_identity` | 必填 | request-intake scope-local Execution Identity |
| `invocation_identity` | 必填 | 本次 Invocation identity |
| `attempt_identity` | 必填 | 本次 attempt identity |
| `source_event_reference` | 必填 | 当前 immutable Source Event reference |
| `pending_proposal_reference` | confirmation 时必填 | pending proposal reference；否则 `null` |
| `current_request_references` | 必填 | 相关 Current Request revisions，可为空 |
| `current_claim_revisions` | 必填 | source-bound confirmed claim revisions，可为空 |
| `original_dialogue_continuation` | 必填 | 不可替换的原 dialogue continuation |
| `policy_identity` | 必填 | `themis-core-control` |
| `policy_digest` | 必填 | 已加载 Policy digest reference |
| `continuation_identity` | 必填 | current Intake continuation |
| `review_feedback_revision` | Review owner re-entry 时必填 | exact lifecycle Review Feedback revision；普通 Intake 时为 `null` |
| `review_feedback_owner_continuation_reference` | Review owner re-entry 时必填 | Feedback record 保存的 `current-request-dialogue` owner continuation reference；普通 Intake 时为 `null` |
| `selected_path` | 必填 | 固定 `null` |
| `profile` | 必填 | 固定 `null` |

### Structured result

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `operation` | 必填 | `changed-diff | confirmation-decision | no-change | rejection` |
| `changed_only_diff` | 必填 | source-bound changed-only diff；无变化时为空 |
| `user_visible_diff` | 必填 | 可供用户确认的 changed-only 内容 |
| `item_dispositions` | 必填 | 每个必需 diff item 的 disposition，可为空 |
| `assignment_operations` | 必填 | 逐目标 operations，可为空 |
| `assignment_decision` | 必填 | confirmation/no-change/rejection decision proposal |
| `confirmation_continuation` | 需要确认时必填 | durable confirmation continuation；否则 `null` |
| `original_dialogue_continuation` | 必填 | 与 input binding 完全一致 |

### Artifact refs 与 materialization

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `proposed_artifact_references` | 必填 | proposal references，可为空 |
| `materialization_target` | 必填 | `request-intake-proposal | request-intake-decision` |

### Diagnostics 与 recommended route

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `gaps` | 必填 | gaps 列表，可为空 |
| `evidence` | 必填 | Source Event 与 assignment evidence references |
| `affected_semantics` | 必填 | 固定只来自 `request_claims | lifecycle_assignment` |
| `recommended_route` | 必填 | advisory `await-confirmation | materialize-assignment | close-intake` |

## Review Feedback owner re-entry

当本 Invocation 来自 Review Feedback 的 `current-request-dialogue` continuation 时，result 必须原样保留 exact Feedback revision 与 owner continuation binding。只有 `assignment-confirmed` 且对应 Current Request/assignment control action 完整物化并重读后，control layer 才可另行记录 lifecycle-local resolution observation；Capability 不得自行标记 resolved 或修改 unresolved set。`needs-request-confirmation`、`rejected`、Invocation 开始或 Intake proposal 存在均不能关闭 Feedback。

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
