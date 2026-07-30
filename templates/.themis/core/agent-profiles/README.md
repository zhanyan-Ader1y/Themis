# Agent Profiles Package

## Responsibility

Agent Profile 定义临时 Capability invocation 的执行权限、上下文隔离和 evidence 边界。Profile 不拥有 Capability 语义、合法状态、路由、lifecycle state 或持久化权威。

Capability 不能选择、替换或扩张 Profile；Invocation 也不能覆盖固定映射。路由字段 `profile` 表示 Plan profile `lightweight | full | null`，与本包的 `agent_profile` 不同。

## Fixed mapping

| Capability | agent_profile |
|---|---|
| `themis-q` | `human-dialogue` |
| `themis-grounding` | `semantic-readonly` |
| `themis-complexity-assessment` | `semantic-readonly` |
| `themis-simple-plan` | `semantic-readonly` |
| `themis-spec` | `semantic-readonly` |
| `themis-planning` | `semantic-readonly` |
| `themis-plan-check` | `independent-checker` |
| `themis-review-projection` | `semantic-readonly` |
| `themis-review-check` | `independent-checker` |
| `themis-review-dialogue` | `human-dialogue` |
| `themis-impl` | `implementation-writer` |
| `themis-verification` | `independent-checker` |
| `themis-acceptance-dialogue` | `human-dialogue` |
| `themis-failure-learning` | `semantic-readonly` |
| `themis-summary` | `semantic-readonly` |

## Invocation invariants

- 一次 invocation 只加载一个 Capability 与其固定 Profile。
- Agent 不能调用另一个 Agent 或 Capability。
- 临时推理、聊天内容和 Agent summary 不成为 lifecycle state。
- Profile 权限不能被 Capability Invocation Result 或 `recommended_route` 扩张。
- Invocation 完成后丢弃临时上下文，只保留实际结构化结果和已观察 evidence references。
- 只有 `implementation-writer` 允许修改项目实现。
