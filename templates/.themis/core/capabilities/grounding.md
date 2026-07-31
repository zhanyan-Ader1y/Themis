# themis-grounding

## 内部执行合同

- Stable identity：`themis-grounding`。
- Authority scope：`lifecycle`。
- 固定 Agent Profile：`semantic-readonly`。
- 合法绑定：`selected_path: null`、`profile: null`。
- Materialization target：immutable structured Grounding result record。
- 结果只是 proposal，不拥有 route、lifecycle state、pointer 或持久化权威。
- 不调用其他 Capability 或 Agent；return target 必须来自 durable lifecycle continuation。

## 能力目标

只读核验调用方明确列出的实现事实请求。代码、配置、Schema 和 observed executable behavior 是当前实现事实的唯一来源。

## 输入

- lifecycle、Execution Identity、Invocation/attempt、policy 和 continuation bindings；
- Current Request revision；
- requesting Capability 与事实请求列表；
- checkout/baseline identity；
- 允许读取的项目范围和观察命令。

## 核验规则

- 直接读取代码、配置和 Schema；行为断言必须执行允许命令或明确标记未执行。
- 记录位置，或 command、cwd、environment、exit/result 和原始输出引用。
- 分开记录 proven、disproven 和 unknown。
- 文档、Specification、Plan、Review、Summary、Themico、经验和 Agent 推断只能提供搜索线索。

## 合法状态

```text
ready
partial
blocked
```

- `ready`：每项请求都有直接证据或明确否定证据。
- `partial`：只核验部分请求，逐项列出 unknown；它不代表满足。
- `blocked`：权限、环境或外部条件使核验无法开始。

## 输出

```yaml
capability: themis-grounding
authority_scope: lifecycle
agent_profile: semantic-readonly
status: ready | partial | blocked
input_bindings:
  lifecycle_identity: ""
  execution_identity: ""
  invocation_identity: ""
  attempt_identity: ""
  current_request_revision: ""
  requesting_capability: ""
  baseline_identity: ""
  policy_identity: ""
  policy_digest: ""
  continuation_identity: ""
  selected_path: null
  profile: null
output:
  structured_result:
    baseline: ""
    facts: []
    blocked_by: []
  proposed_artifact_references: []
  materialization_target: grounding-structured-record
diagnostics:
  gaps: []
  evidence: []
  affected_semantics: [implementation_facts]
recommended_route: return-to-continuation | request-unblock
```

## 权限与边界

- 只读项目文件；只执行 Invocation Contract 允许的观察命令。
- 不得修改项目实现或 lifecycle state，不评价复杂度、补充需求或选择方案。
- 不调用其他 Capability 或 Agent，不发明 digest、baseline 或 command output。

## 停止条件

- 事实请求、baseline、scope、Profile、policy 或 continuation binding 缺失/过期时停止。
- 任何请求 unknown 时不得返回 `ready`。
- 工具或命令已开始后失败属于 counted failure，不能改写为 `partial` 或 `blocked`。
- 外部 drift 使 baseline 不适用时停止并请求 control plane revalidate，不归责于本 Invocation。
