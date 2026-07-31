# themis-complexity-assessment

## 内部执行合同

- Stable identity：`themis-complexity-assessment`。
- Authority scope：`lifecycle`。
- 固定 Agent Profile：`semantic-readonly`。
- 合法绑定：`selected_path: null`、`profile: null`。
- Materialization target：immutable structured Complexity Assessment record。
- 结果只是 proposal；`full_path_required` 只能由 policy control action 设置。
- 不调用其他 Capability 或 Agent，不拥有 route、state、pointer 或持久化权威。

## 能力目标

在 Questioning 收敛后独立判断当前需求能否跳过 temporary Specification 和 full Planning。只有全部简单条件被直接证明时才能返回 `simple-qualified`。

## 输入

- Requirement Input Bundle；
- Current Request revision 和 active confirmed claims；
- current completed Questioning round revision；
- governed design constraint refs；
- Grounding/current implementation fact evidence 与 baseline；
- lifecycle、Execution Identity、Invocation/attempt、policy 和 continuation bindings。

## 简单条件

逐项检查目标/范围/结果清晰、修改局部、无外部合同变化、无跨模块/权限/并发/数据/状态复杂度、验收与验证明确、无未核验事实或隐藏假设。文件数、代码行数和耗时只作辅助信息。

## 合法状态

```text
simple-qualified
full-required
blocked
```

- `simple-qualified`：全部条件均有直接证据且结论为 simple。
- `full-required`：任一条件 non-simple、uncertain 或缺少直接证据。
- `blocked`：必要读取权限、环境或外部条件不可获得。

## 输出

```yaml
capability: themis-complexity-assessment
authority_scope: lifecycle
agent_profile: semantic-readonly
status: simple-qualified | full-required | blocked
input_bindings:
  lifecycle_identity: ""
  execution_identity: ""
  invocation_identity: ""
  attempt_identity: ""
  current_request_revision: ""
  questioning_round_revision: ""
  grounding_references: []
  policy_identity: ""
  policy_digest: ""
  continuation_identity: ""
  selected_path: null
  profile: null
output:
  structured_result:
    criteria: []
    full_requirement_reasons: []
  proposed_artifact_references: []
  materialization_target: complexity-assessment-structured-record
diagnostics:
  gaps: []
  evidence: []
  affected_semantics: [path_selection]
recommended_route: simple-plan | full-path | request-unblock
```

## 权限与边界

- 使用只读上下文；不得修改实现、需求、Plan 或 lifecycle state。
- 不调用其他 Capability 或 Agent，不设置 `full_path_required`。
- 不从 Specification、设计文档或知识库推导当前实现事实。

## 停止条件

- Questioning 未收敛或任何 current binding 缺失/过期时停止。
- 任一简单条件无法证明时不得返回 `simple-qualified`。
- 工具、命令、结果合同或 binding 执行失败属于 counted failure，不得改写为 `full-required`。
- external drift 使 evidence/baseline 不适用时停止并请求 revalidation。
