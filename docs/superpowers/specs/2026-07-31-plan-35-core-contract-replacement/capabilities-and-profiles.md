# Capability 与 Agent Profile

> 本文件属于 [Plan 35：Core Contract Replacement](../2026-07-31-plan-35-core-contract-replacement-design.md) 的功能 reference，拥有十六个 Capability、四个 Agent Profile 和 temporary Invocation 合同。它不是第二份设计权威。十六个 Capability identity 与四个 Profile identity 固定；核心不变量是一次 Invocation 只绑定一个 scope、一个 Capability 及其 fixed Profile，且任何 Capability result 都只是 proposal。

## 固定十六个 Capability

| Capability | Agent Profile | Authority scope | 核心职责 |
|---|---|---|---|
| `themis-current-request-dialogue` | `human-dialogue` | `request-intake` | Source Event、claim diff、assignment 和用户确认 |
| `themis-q` | `human-dialogue` | `lifecycle` | Why、impact、expected result 与 abstract What 追问 |
| `themis-grounding` | `semantic-readonly` | `lifecycle` | 读取代码、配置、Schema 与 observed behavior 当前事实 |
| `themis-complexity-assessment` | `semantic-readonly` | `lifecycle` | 证明 simple 条件或要求 full path |
| `themis-simple-plan` | `semantic-readonly` | `lifecycle` | 在已证明简单边界内生成统一 Plan |
| `themis-spec` | `semantic-readonly` | `lifecycle` | full path 临时需求细化 handoff |
| `themis-planning` | `semantic-readonly` | `lifecycle` | full path 技术设计、取舍、任务与验证方案 |
| `themis-plan-check` | `independent-checker` | `lifecycle` | 隔离检查 lightweight/full Plan |
| `themis-review-projection` | `semantic-readonly` | `lifecycle` | 从 checked Plan 生成低负担 Review Projection |
| `themis-review-check` | `independent-checker` | `lifecycle` | 检查 projection 忠实度和呈现负担 |
| `themis-review-dialogue` | `human-dialogue` | `lifecycle` | 展示、解释、分类反馈和批准 proposal |
| `themis-impl` | `implementation-writer` | `lifecycle` | 按 current Approval 绑定的 Plan 修改实现 |
| `themis-verification` | `independent-checker` | `lifecycle` | 独立验证 current implementation 与交付证据 |
| `themis-acceptance-dialogue` | `human-dialogue` | `lifecycle` | 展示验收视图并形成 acceptance proposal |
| `themis-failure-learning` | `semantic-readonly` | `request-intake` 或 `lifecycle` | 生成 scope-bound 非阻塞经验候选 |
| `themis-summary` | `semantic-readonly` | `lifecycle` | 在 passed + accepted 后生成交付投影 |

原十五个 Capability 的职责和 legal status 边界保持不重组，只允许以下 replacement 扩展：

- `themis-q` 输入改为 user-confirmed Current Request claims/revision；
- `themis-failure-learning` 支持两个 authority scope；
- 所有 Capability 明确 materialization target 和 immutable revision requirement；
- 所有用户消息先经过 Intake interception，再恢复 lifecycle continuation。

## `semantic-readonly`

允许语义分析、候选生成和只读事实引用，不得修改项目实现或 Workspace authority。

## `independent-checker`

在隔离上下文中检查输入和直接证据，不继承 producer 的临时推理，不得修改被检查对象。

## `human-dialogue`

允许与用户交互，生成 semantic diff、feedback、approval 或 acceptance proposal。不得直接写 Intake/lifecycle state、artifact、route 或项目实现。

## `implementation-writer`

唯一可以修改 current Approval 所允许项目实现范围的 Profile。它仍不得：

- 修改 Core Policy 或 Workspace governance state；
- 自行扩张 scope；
- 给出 Verification verdict；
- 将实现写入成功等同于 artifact/state 持久化成功。

不新增 governance-writer Profile。只有 `themis-impl` 使用 `implementation-writer`。

## Temporary Invocation

每次 Invocation 只能绑定：

```text
one authority scope
+ one Execution Identity
+ one Invocation/attempt identity
+ one Capability
+ its fixed Agent Profile
+ selected path/profile
+ current Policy binding
+ current source/artifact bindings
+ exact continuation
+ allowed reads/writes/commands
```

Intake Capability 固定使用 `selected_path: null` 和 `profile: null`。

任何 Capability 或 Agent 都不得：

- 调用其他 Capability 或 Agent；
- 选择或扩张自身 Profile；
- 保留跨 Invocation shared memory 或 authority；
- 直接执行 route；
- 把 chat、summary 或 temporary reasoning 作为 state；
- 返回多个相互竞争的终态结果。

## Proposal 与 materialization

Capability 拥有语义判断，但 Capability Invocation Result 永远只是 proposal。Profile 的工具权限不赋予治理写入权。只有 Global Rule 按唯一 Policy rule 验证 bindings、请求 control action，并观察 recorder 完整写入与重读后，结果才可能成为 current candidate。

Capability 的 `recommended_route` 只能用于 diagnostics，不能覆盖 Policy 或提供隐藏 status。
