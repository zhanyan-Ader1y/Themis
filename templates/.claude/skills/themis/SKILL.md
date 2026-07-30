---
name: themis
description: 启动、继续或恢复受治理的 Themis 生命周期，加载唯一控制 Rule，并通过内部 Capability、固定 Agent Profile 与声明式路由推进当前交付。
---

# themis

## Public entry responsibility

本 Skill 是 Claude Code 环境中唯一公共 Themis 入口。它接收用户启动、继续或恢复 lifecycle 的请求，定位当前 lifecycle 控制上下文，并加载：

- `.themis/core/kernel/orchestrator/rules.md`；
- `.themis/core/policies/transitions.yaml`；
- 当前 route 选择的一个 `.themis/core/capabilities/*.md`；
- 该 Capability 固定绑定的一个 `.themis/core/agent-profiles/*.md`。

## Execution boundary

```text
user request
→ public themis Skill
→ Global Control Rule
→ transitions.yaml
→ one internal Capability + fixed Agent Profile
→ one temporary Agent invocation
→ structured Capability Invocation Result
→ transitions.yaml next route
```

- 一次 invocation 只加载一个 Capability。
- Capability、Profile 和临时 Agent 不得自行调度另一 Capability 或 Agent。
- 本 Skill 不拥有 Questioning、Grounding、Complexity Assessment、Planning、Review、Impl、Verification、Acceptance、Failure Learning 或 Summary 的语义判断。
- 本 Skill 不拥有 status route、lifecycle state、artifact persistence、digest/currentness、Approval、failure count 或 invalidation。
- 对话型 Capability 生成当前展示或问题后，由 Global Rule 向用户呈现；用户原始回答由实际 recorder 操作写入 lifecycle record。
- validator、recorder、runtime、policy binding 或必要 Core contract 不可用时，停在当前 gate，明确报告 unavailable；不得声称 transition、persistence、digest、currentness、invalidation、attempt、rollback 或 automatic recovery 已执行。
- mutating invocation 必须遵守 `implementation-writer` 的写入边界：并发时绑定独占 worktree，限制 allowed paths，写前核验 baseline，适用时完整临时写后原子替换，记录 completion/incomplete marker 并重读核验。缺少任一必要支持时禁止模拟成功。

## Start, continue, and resume from records

1. 确认项目 fresh template 中存在 Global Rule、policy、Capability 和 Profile contracts。
2. 定位或建立当前 lifecycle identity 与 Current Request binding。
3. 读取 lifecycle 实际记录和其 `policy_binding`，不从聊天摘要推断 current state。
4. 将控制权交给 Global Control Rule；后续 route 只来自 `transitions.yaml`。
5. 若中断，重新读取实际记录并 fail closed；不根据部分文件猜测完成或自动回滚。
