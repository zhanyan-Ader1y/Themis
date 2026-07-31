# themis-acceptance-dialogue

## 内部执行合同

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

```text
accepted
implementation-defect
needs-planning
needs-specification
escalate-full
```

- `accepted`：用户明确接受 current actual result。
- `implementation-defect`：Plan 仍有效，返回 approved scope 内 Impl repair 并重新 Verification；计入 shared task budget。
- `needs-planning`/`needs-specification`：对应技术或需求语义需改变。
- `escalate-full`：只在 simple 且 sticky upgrade 未设置时合法。

## 输出

```yaml
capability: themis-acceptance-dialogue
authority_scope: lifecycle
agent_profile: human-dialogue
status: accepted | implementation-defect | needs-planning | needs-specification | escalate-full
input_bindings:
  lifecycle_identity: ""
  execution_identity: ""
  invocation_identity: ""
  attempt_identity: ""
  current_request_revision: ""
  approval_revision: ""
  plan_revision: ""
  verification_revision: ""
  acceptance_source_event_references: []
  policy_identity: ""
  policy_digest: ""
  continuation_identity: ""
  selected_path: simple | full
  profile: lightweight | full
output:
  structured_result:
    acceptance_view: {}
    preserved_user_feedback: []
    observed_difference: ""
    classification_reason: ""
  proposed_artifact_references: []
  materialization_target: human-acceptance-pair
diagnostics:
  gaps: []
  evidence: []
  affected_semantics: []
recommended_route: summary | impl-repair | planning | specification | set-full-path-required
```

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
