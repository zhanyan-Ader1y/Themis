# Policies Package

## Responsibility

Policies 保存 Global Control Rule 与未来 runtime 共同遵守的稳定状态、门禁、路由和失效声明。`transitions.yaml` 是 Capability 合法状态和后继路由的唯一声明源；Global Rule 只解释这份策略，Capability 只生成自身语义结果，Workspace 保存每个 lifecycle 的实际记录。

## Owned assets

- `transitions.yaml`：闭集 vocabulary、十五个固定 Agent Profile 映射、91 条唯一合法路由、双路径门禁、粘性升级、动态 continuation、失效规则和共享三次失败预算。

## Boundaries

- Policy 不保存项目事实、用户需求、Plan 内容、临时 Agent 推理或命令输出。
- Global Rule 不复制 Capability 状态表或 Capability-specific 路由；零条或多条 route match 都进入全局 `invalid_result`。
- Capability 不选择下一路由，`recommended_route` 只可作为 diagnostics，不具控制权。
- `profile` 表示 lifecycle 的 `lightweight | full | null` Plan profile；执行权限使用独立字段 `agent_profile`。
- `full_path_required` 在同一 lifecycle 中只能由 `false` 变为 `true`，重新追问和重新评估都不能清除它。
- Project override 不得绕过追问、Plan Check、Review、独立 Verification、Human Acceptance、Summary 或失败上限。
- 不包含功能版本、upgrade、migration、Shell executor、多 Agent 编排或 Attribution gate。

## Safe degradation

当前 YAML 是 Prompt-level contract input。没有 evaluator、state recorder、validator、digest service 或 invocation runtime 时，Agent 只能遵循其语义并报告 assurance unavailable；不得声称 transition、persistence、currentness、attempt、invalidation 或 termination 已由机器执行。

## Current status

Plan 35 提供声明式控制语义和人工可重放路由。严格 Schema、accepted/rejected vectors 与 contract fixtures 属于 Plan 36；实际 evaluator、state recorder、原子替换、完成标记和重读核验属于 Plan 37。Plan 37 不拥有通用锁、事务、回滚日志或自动恢复规划。
