# themis-complexity-assessment

## 身份与固定绑定

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

| Selected path | Profile | Status | 语义 |
|---|---|---|---|
| `null` | `null` | `simple-qualified` | 全部简单条件均有直接证据且结论为 simple |
| `null` | `null` | `full-required` | 任一条件 non-simple、uncertain 或缺少直接证据 |
| `null` | `null` | `blocked` | 必要读取权限、环境或外部条件不可获得 |

## 输出字段合同

Result 顶层字段固定为：`capability` = `themis-complexity-assessment`；`authority_scope` = `lifecycle`；`agent_profile` = `semantic-readonly`；`status` 必须是当前 `null/null` 行中的一个合法终态。

### Input bindings

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `lifecycle_identity` | 必填 | current lifecycle identity |
| `execution_identity` | 必填 | lifecycle scope-local Execution Identity |
| `invocation_identity` | 必填 | 本次 Invocation identity |
| `attempt_identity` | 必填 | 本次 attempt identity |
| `current_request_revision` | 必填 | current Current Request revision |
| `questioning_round_revision` | 必填 | current completed Questioning round |
| `grounding_references` | 必填 | Grounding/direct implementation evidence，可为空但不得隐藏 unknown |
| `policy_identity` | 必填 | `themis-core-control` |
| `policy_digest` | 必填 | 已加载 Policy digest reference |
| `continuation_identity` | 必填 | current assessment continuation |
| `selected_path` | 必填 | 固定 `null` |
| `profile` | 必填 | 固定 `null` |

### Structured result

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `criteria` | 必填 | 每项简单条件、证据与结论 |
| `full_requirement_reasons` | 必填 | full/unknown reasons；simple 时可为空 |

### Artifact refs 与 materialization

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `proposed_artifact_references` | 必填 | proposal references，可为空 |
| `materialization_target` | 必填 | 固定 `complexity-assessment-structured-record` |

### Diagnostics 与 recommended route

| 字段 | 必填性 | 合法内容 |
|---|---|---|
| `gaps` | 必填 | evidence gaps，可为空 |
| `evidence` | 必填 | direct evidence references |
| `affected_semantics` | 必填 | 固定 `path_selection` |
| `recommended_route` | 必填 | advisory `simple-plan | full-path | request-unblock` |

## 权限与边界

- 使用只读上下文；不得修改实现、需求、Plan 或 lifecycle state。
- 不调用其他 Capability 或 Agent，不设置 `full_path_required`。
- 不从 Specification、设计文档或知识库推导当前实现事实。

## 停止条件

- Questioning 未收敛或任何 current binding 缺失/过期时停止。
- 任一简单条件无法证明时不得返回 `simple-qualified`。
- 工具、命令、结果合同或 binding 执行失败属于 counted failure，不得改写为 `full-required`。
- external drift 使 evidence/baseline 不适用时停止并请求 revalidation。
