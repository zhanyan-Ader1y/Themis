# themis-planning

## 内部执行合同

- Stable identity：`themis-planning`。
- Authority scope：`lifecycle`。
- 固定 Agent Profile：`semantic-readonly`。
- 唯一合法绑定：`selected_path: full`、`profile: full`。
- Materialization target：immutable paired unified Plan revision。
- 结果只是完整 Plan content proposal；policy/recorder 才能建立 revision 和 current pointer。
- 不调用其他 Capability 或 Agent，不拥有 route、state 或持久化权威。

## 能力目标

把 Current Request、governed design constraints、temporary Specification handoff 和直接实现事实转化为 full path 的 unified Plan proposal。

## 输入

- Current Request revision 与 active confirmed claims；
- current completed Questioning round；
- governed design constraint refs；
- `ready` temporary Specification handoff；
- Grounding/current implementation fact evidence 与 baseline；
- lifecycle、Execution Identity、Invocation/attempt、policy 和 continuation bindings；
- unified Plan pair template。

Planning 必须直接读取事实证据，不得只信任 Specification 转述。

## 责任

调查实现事实；比较方案与取舍；设计架构、边界、依赖、数据流、状态、接口和错误模型；分析权限、一致性、失败/恢复和回归；为每项验收设计 Verification；分解依赖就绪的 Impl/Verification 任务；建立来源覆盖映射。

## 合法状态

```text
ready
needs-specification
needs-grounding
blocked
```

- `ready`：形成完整 unified Plan proposal。
- `needs-specification`：Current Request 与 handoff 冲突，或需求范围/合同/验收语义不完整。
- `needs-grounding`：实现事实缺失、过期或不足，一次返回全部事实请求。
- `blocked`：必要权限、环境或外部条件不可获得。

## 输出

```yaml
capability: themis-planning
authority_scope: lifecycle
agent_profile: semantic-readonly
status: ready | needs-specification | needs-grounding | blocked
input_bindings:
  lifecycle_identity: ""
  execution_identity: ""
  invocation_identity: ""
  attempt_identity: ""
  current_request_revision: ""
  active_claim_revisions: []
  questioning_round_revision: ""
  specification_handoff_reference: ""
  implementation_baseline: ""
  policy_identity: ""
  policy_digest: ""
  continuation_identity: ""
  selected_path: full
  profile: full
output:
  structured_result:
    plan_content: ""
    alternatives_and_tradeoffs: []
    fact_requests: []
    coverage_summary: []
  proposed_artifact_references: []
  materialization_target: plan-pair
diagnostics:
  gaps: []
  evidence: []
  affected_semantics: [plan]
recommended_route: plan-check | specification | grounding | request-unblock
```

## 权限与边界

- 可只读调查项目；不得修改项目实现或 Current Request。
- 生成与 simple path 相同的 Plan family，不生成第二套 full-plan artifact。
- 不批准 Plan，不执行任务，不调用其他 Capability 或 Agent。
- 不计算或发明 digest、currentness 或 machine-valid 结论。

## 停止条件

- temporary handoff 缺失、full path/profile 不匹配或 current binding stale 时停止。
- 需求语义缺口返回 `needs-specification`；实现事实缺口返回 `needs-grounding`，不得混淆 owner。
- coverage、任务或 Verification 设计不完整时不得返回 `ready`。
- 工具、结果合同或 Invocation 失败属于 counted failure；external drift 单独 stop-and-revalidate。
