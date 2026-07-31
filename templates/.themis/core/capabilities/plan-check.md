# themis-plan-check

## 内部执行合同

- Stable identity：`themis-plan-check`。
- Authority scope：`lifecycle`。
- 固定 Agent Profile：`independent-checker`。
- 合法绑定：`simple/lightweight` 或 `full/full`，两组 legal statuses 分别锁定。
- Materialization target：immutable structured Plan Check record。
- 结果只是 checker proposal；policy/recorder 物化后才可作为 Review Projection gate。
- 不调用其他 Capability 或 Agent，不继承 Plan producer 的临时推理。

## 能力目标

在独立上下文中检查 current Plan 是否满足指定 profile。Checker 不修改 Plan，也不使用未写入正式输入的 producer reasoning。

## 输入

- Current Request revision、active claims 和 completed Questioning round；
- governed design constraints、Complexity Assessment、selected path 和 sticky upgrade state；
- current Plan pair revision/digest；
- Grounding/current implementation facts 与 baseline；
- `lightweight | full` profile；
- full profile 时的 temporary Specification handoff；
- lifecycle、Execution Identity、Invocation/attempt、policy 和 continuation bindings。

## 合法状态

### Lightweight profile

```text
pass
needs-simple-planning
escalate-full
blocked
```

检查 request coverage、直接事实、范围/排除项、步骤/完成条件、Verification、simple boundary 和 assumptions。

### Full profile

```text
pass
needs-planning
needs-specification
needs-grounding
blocked
```

检查 request/handoff 一致性、技术设计、架构/模块/接口/数据/状态/失败行为、事实证据、验收 Verification、任务可执行性和覆盖映射。

## 输出

```yaml
capability: themis-plan-check
authority_scope: lifecycle
agent_profile: independent-checker
status: <profile-legal status>
input_bindings:
  lifecycle_identity: ""
  execution_identity: ""
  invocation_identity: ""
  attempt_identity: ""
  current_request_revision: ""
  questioning_round_revision: ""
  plan_revision: ""
  plan_digest: ""
  policy_identity: ""
  policy_digest: ""
  continuation_identity: ""
  selected_path: simple | full
  profile: lightweight | full
output:
  structured_result:
    checks: []
    plan_check_result: ""
  proposed_artifact_references: []
  materialization_target: plan-check-structured-record
diagnostics:
  gaps: []
  evidence: []
  affected_semantics: [plan_quality]
recommended_route: review-projection | regenerate-plan | specification | grounding | set-full-path-required | request-unblock
```

## 权限与边界

- 只读项目和 artifacts；不得修改实现、Plan 或 lifecycle state。
- 不调用其他 Capability 或 Agent，不检查 Review presentation。
- `needs-simple-planning`/`escalate-full` 只在 simple 且 sticky upgrade 未设置时合法。

## 停止条件

- Profile、path、scope、Plan revision、policy 或 continuation binding 不匹配/过期时停止。
- Evidence 不足时不得 `pass`。
- 未知状态或错误 profile 状态是 invalid result，不得用自由文本路由。
- 工具、结果合同或 Invocation 失败属于 counted failure；external drift 单独 stop-and-revalidate。
