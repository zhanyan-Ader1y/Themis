# themis-simple-plan

## 内部执行合同

- Stable identity：`themis-simple-plan`。
- Authority scope：`lifecycle`。
- 固定 Agent Profile：`semantic-readonly`。
- 唯一合法绑定：`selected_path: simple`、`profile: lightweight`。
- Materialization target：immutable paired unified Plan revision。
- 结果只是完整 Plan content proposal；policy/recorder 才能建立 revision 和 current pointer。
- 不调用其他 Capability 或 Agent，不拥有 route、state 或持久化权威。

## 能力目标

在 `simple-qualified` 且 `full_path_required = false` 时，形成与 full path 同结构、同语义地位的 unified Plan proposal。

## 输入

- Requirement Input Bundle；
- Current Request revision、active claims 和 completed Questioning round；
- Complexity Assessment record 与逐项证据；
- Grounding/current implementation fact evidence 与 baseline；
- governed design constraints；
- lifecycle、Execution Identity、Invocation/attempt、policy 和 continuation bindings；
- unified Plan pair template。

不得读取 temporary Specification handoff，也不得执行 full Planning。

## Plan 要求

至少包含目标、核心链路、范围/排除项、行为/验收、实现事实证据、拟修改位置、步骤/依赖/完成条件、Verification 方案、风险/失败/恢复、claim 覆盖映射，以及深层设计项 `not-applicable` 的直接证据。

## 合法状态

```text
ready
escalate-full
blocked
```

- `ready`：在已证明简单边界内形成完整 unified Plan proposal。
- `escalate-full`：需要合同、架构、跨模块、权限、数据、状态或其他完整设计。
- `blocked`：必要事实或访问条件不可获得。

## 输出

```yaml
capability: themis-simple-plan
authority_scope: lifecycle
agent_profile: semantic-readonly
status: ready | escalate-full | blocked
input_bindings:
  lifecycle_identity: ""
  execution_identity: ""
  invocation_identity: ""
  attempt_identity: ""
  current_request_revision: ""
  active_claim_revisions: []
  questioning_round_revision: ""
  complexity_assessment_reference: ""
  implementation_baseline: ""
  policy_identity: ""
  policy_digest: ""
  continuation_identity: ""
  selected_path: simple
  profile: lightweight
output:
  structured_result:
    plan_content: ""
    coverage_summary: []
    not_applicable_evidence: []
  proposed_artifact_references: []
  materialization_target: plan-pair
diagnostics:
  gaps: []
  evidence: []
  affected_semantics: [plan]
recommended_route: plan-check | set-full-path-required | request-unblock
```

## 权限与边界

- 可只读调查项目；不得修改项目实现、Current Request 或 Assessment。
- 不创建第二个 `simple-plan` artifact，不调用其他 Capability 或 Agent。
- 不批准 Plan，不执行实现，不计算或发明 digest/currentness。

## 停止条件

- Assessment 不是 current `simple-qualified`、`full_path_required = true` 或任一 binding stale 时停止。
- 形成 Plan 需要扩张简单边界时必须返回 `escalate-full`。
- Plan coverage 不完整时不得返回 `ready`。
- 工具、结果合同或 Invocation 失败属于 counted failure；external drift 单独 stop-and-revalidate。
