# Agent Profiles Package

## Responsibility

Agent Profile 定义临时 Capability Invocation 的工具、读取、项目实现写入和上下文隔离边界。Profile 不拥有 Capability 语义、合法状态、route、authority state、artifact currentness 或 recorder 权威。

Capability 不能选择、替换或扩张 Profile。路由字段 `profile` 表示 Plan profile `lightweight | full | null`，与 `agent_profile` 不同。

## Fixed mapping

| Capability | Authority scope | agent_profile |
|---|---|---|
| `themis-current-request-dialogue` | `request-intake` | `human-dialogue` |
| `themis-q` | `lifecycle` | `human-dialogue` |
| `themis-grounding` | `lifecycle` | `semantic-readonly` |
| `themis-complexity-assessment` | `lifecycle` | `semantic-readonly` |
| `themis-simple-plan` | `lifecycle` | `semantic-readonly` |
| `themis-spec` | `lifecycle` | `semantic-readonly` |
| `themis-planning` | `lifecycle` | `semantic-readonly` |
| `themis-plan-check` | `lifecycle` | `independent-checker` |
| `themis-review-projection` | `lifecycle` | `semantic-readonly` |
| `themis-review-check` | `lifecycle` | `independent-checker` |
| `themis-review-dialogue` | `lifecycle` | `human-dialogue` |
| `themis-impl` | `lifecycle` | `implementation-writer` |
| `themis-verification` | `lifecycle` | `independent-checker` |
| `themis-acceptance-dialogue` | `lifecycle` | `human-dialogue` |
| `themis-failure-learning` | `request-intake | lifecycle` | `semantic-readonly` |
| `themis-summary` | `lifecycle` | `semantic-readonly` |

## Invocation invariants

- 一次 Invocation 只绑定一个 authority scope、Execution Identity、Invocation/attempt identity、Capability 和 fixed Profile。
- Profile 只能使用 Invocation Contract 显式允许的 reads/writes/commands。
- Agent 不调用其他 Capability 或 Agent，不执行 route，不保留跨 Invocation shared memory/authority。
- Chat、summary、temporary reasoning 和 filesystem existence 都不能证明 state/artifact 已物化。
- `human-dialogue` 只返回 proposal/structured decision；不直接写 Intake 或 lifecycle governance authority。
- 只有 `implementation-writer` 允许修改 current Approval 范围内的项目实现；它仍不能写 governance authority 或给 Verification verdict。
- recorder/runtime/validator 不可用时 fail closed，并明确报告 assurance unavailable。

不新增 `governance-writer` Profile。治理记录的 materialization 只能由 policy control action 调用的 recorder 完成并重读证明。
