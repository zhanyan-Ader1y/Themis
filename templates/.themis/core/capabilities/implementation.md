# themis-impl

## 内部执行合同

- Stable identity：`themis-impl`。
- Authority scope：`lifecycle`。
- 固定 Agent Profile：`implementation-writer`。
- 合法绑定：`simple/lightweight` 或 `full/full`；`escalate-full` 仅允许前者。
- Materialization target：approved implementation delta、immutable paired Impl Result revision 和 operational evidence records。
- 这是唯一允许在 current Review Approval 与 Plan Task 范围内修改项目实现的 Capability；文件变化本身不等于 governance artifact/state 已物化。
- 不调用其他 Capability 或 Agent，不拥有 route、governance state、pointer 或 Verification authority。

## 能力目标

在 Review Approval current 且 bindings 完整时执行 approved Plan 中一个依赖就绪的 Impl task。Plan 是执行合同，Current Request 的目标和验收语义不得降低。

## 输入

- Current Request revision、selected path/profile 和 `full_path_required`；
- current Review Approval pair 及全部 bindings；
- approved Plan revision/digest 与一个依赖就绪 task identity；
- shared Plan Task Execution Identity、Impl Invocation/attempt 和 remaining failure budget；
- approved pre-Impl implementation baseline、expected delta、allowed write/command scope；
- lifecycle、policy 和 continuation bindings。

`review.md`、Review 对话和 temporary Specification handoff 不是执行输入。

## 执行规则

只完成批准任务；不做无关重构、不扩张需求、不修改 Plan。记录 actual changes、completion evidence、deviations、commands 和 external drift。simple path 持续核验简单边界。批准的 expected delta 不自行使 Approval stale；未授权工作区、依赖、配置、Schema 或行为变化立即停止。

## 合法状态

```text
implemented
needs-planning
escalate-full
blocked
```

- `implemented`：任务完成并形成 Impl Result proposal；不代表 Verification passed。
- `needs-planning`：approved Plan 在 full path 中不足或不可执行。
- `escalate-full`：simple path 发现隐藏复杂度。
- `blocked`：权限、环境或外部条件阻止开始/继续。

## 输出

```yaml
capability: themis-impl
authority_scope: lifecycle
agent_profile: implementation-writer
status: implemented | needs-planning | escalate-full | blocked
input_bindings:
  lifecycle_identity: ""
  execution_identity: ""
  invocation_identity: ""
  attempt_identity: ""
  current_request_revision: ""
  approval_revision: ""
  plan_revision: ""
  plan_task_identity: ""
  approved_implementation_baseline: ""
  expected_delta_reference: ""
  policy_identity: ""
  policy_digest: ""
  continuation_identity: ""
  selected_path: simple | full
  profile: lightweight | full
output:
  structured_result:
    actual_changes: []
    completion_results: []
    deviations: []
    external_drift: []
    command_evidence_references: []
  proposed_artifact_references: []
  materialization_target: implementation-delta-and-impl-result-pair
diagnostics:
  gaps: []
  evidence: []
  affected_semantics: [implementation]
recommended_route: verification | planning | set-full-path-required | request-unblock
```

## 权限与边界

- 只按 Approval、Plan task、allowed paths/commands 修改项目实现。
- 不得修改 Current Request、Plan、Review、Approval、Core policy 或 Workspace governance authority。
- 不调用其他 Capability 或 Agent，不给 Verification verdict，不生成 Acceptance/Summary。
- 不把写入成功等同于 Impl Result pair、state 或 pointer 已持久化。

## 停止条件

- Approval stale、task 非依赖就绪、baseline/bindings 不匹配、scope 不明或写权限不足时停止。
- external drift 触发 non-counted stop-and-revalidate，不继续写入。
- started tool/command/write 或 result contract 失败属于 shared task counted failure，不得用 `blocked` 隐藏。
- 第三次 counted failure 后不得开始第四次 Invocation。
