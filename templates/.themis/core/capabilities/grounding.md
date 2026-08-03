# themis-grounding

## 身份与固定绑定

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

| Selected path | Profile | Status | 语义 |
|---|---|---|---|
| `null` | `null` | `ready` | 每项请求都有直接证据或明确否定证据 |
| `null` | `null` | `partial` | 只核验部分请求，逐项列出 unknown；不表示满足 |
| `null` | `null` | `blocked` | 权限、环境或外部条件使核验无法开始 |

## 输出字段合同

Result 顶层字段固定为：`capability` = `themis-grounding`；`authority_scope` = `lifecycle`；`agent_profile` = `semantic-readonly`；`status` 必须是当前 `null/null` 行中的一个合法终态。

### Input bindings

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `lifecycle_identity` | 必填 | current lifecycle identity |
| `execution_identity` | 必填 | lifecycle scope-local Execution Identity |
| `invocation_identity` | 必填 | 本次 Invocation identity |
| `attempt_identity` | 必填 | 本次 attempt identity |
| `current_request_revision` | 必填 | current Current Request revision |
| `requesting_capability` | 必填 | durable continuation 中的 requesting Capability identity |
| `baseline_identity` | 必填 | checkout/implementation baseline identity |
| `policy_identity` | 必填 | `themis-core-control` |
| `policy_digest` | 必填 | 已加载 Policy digest reference |
| `continuation_identity` | 必填 | return-to-requester continuation |
| `selected_path` | 必填 | 固定 `null` |
| `profile` | 必填 | 固定 `null` |

### Structured result

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `baseline` | 必填 | observed baseline reference |
| `facts` | 必填 | 逐项 proven/disproven/unknown facts 与直接证据 |
| `blocked_by` | 必填 | observed blockers，可为空 |

### Artifact refs 与 materialization

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `proposed_artifact_references` | 必填 | proposal references，可为空 |
| `materialization_target` | 必填 | 固定 `grounding-structured-record` |

### Diagnostics 与 recommended route

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `gaps` | 必填 | 未核验事实列表，可为空 |
| `evidence` | 必填 | code/config/Schema/command evidence references |
| `affected_semantics` | 必填 | 固定 `implementation_facts` |
| `recommended_route` | 必填 | advisory `return-to-continuation | request-unblock` |

## 权限与边界

- 只读项目文件；只执行 Invocation Contract 允许的观察命令。
- 不得修改项目实现或 lifecycle state，不评价复杂度、补充需求或选择方案。
- 不调用其他 Capability 或 Agent，不发明 digest、baseline 或 command output。

## 停止条件

- 事实请求、baseline、scope、Profile、policy 或 continuation binding 缺失/过期时停止。
- 任何请求 unknown 时不得返回 `ready`。
- 工具或命令已开始后失败属于 counted failure，不能改写为 `partial` 或 `blocked`。
- 外部 drift 使 baseline 不适用时停止并请求 control plane revalidate，不归责于本 Invocation。
