---
name: themis
description: 接收任意需要 Themis 治理的新消息或续接消息，先记录不可变 Source Event 与 Request Intake，再通过唯一控制 Rule、内部 Capability 和声明式 policy 启动、继续或恢复交付。
---

# themis

## Public entry responsibility

本 Skill 是唯一公共 Themis 入口。每条外部用户消息必须先进入 Request Intake，不能先定位、创建或继续 lifecycle。

它只负责：

- 请求记录用户消息的原始 bytes 和 immutable Source Event metadata；
- 从 durable Intake confirmation/restart continuation 选择 attachment，否则建立新 Intake；
- 加载 `.themis/core/kernel/orchestrator/rules.md` 和 current `.themis/core/policies/transitions.yaml`；
- 按 Rule/policy 加载一个 internal Capability 与 fixed Agent Profile；
- 运输用户 Source Event、Capability proposed result 和 durable continuation；
- 请求从 durable facts 恢复中断流程。

## Intake-first execution boundary

```text
external user message
→ immutable Source Event
→ request-intake
→ themis-current-request-dialogue
   ├─ needs-request-confirmation → wait for new confirmation Source Event
   ├─ rejected → persist rejection and close Intake
   └─ assignment-confirmed → policy-controlled assignment materialization
→ create/update lifecycle Current Request revision
→ resume decision-bound lifecycle continuation
```

只有 fully materialized and reread assignment decision 才能创建、更新、拆分、合并或继续 lifecycle。不存在 provisional lifecycle。

## Internal execution

Assignment 后仍只通过同一 Rule/policy 推进：

```text
Global Control Rule
→ current transitions.yaml
→ one internal Capability + fixed Agent Profile
→ one temporary Invocation in one authority scope
→ proposed Capability Invocation Result
→ exactly one policy route and control action
→ observed materialization and reread
```

- 一次 Invocation 只加载一个 Capability；Capability/Agent 不得嵌套调用。
- Internal Capability contracts under `.themis/core/capabilities/` are not public Skills.
- 本 Skill 不拥有 claims、assignment、Questioning、Grounding、Assessment、Plan、Review、Impl、Verification、Acceptance、Failure Learning 或 Summary 的语义判断。
- 本 Skill 不拥有 route lookup、authority state、artifact currentness、Approval、failure count、invalidation 或 completion。
- `recommended_route`、Agent prose、chat history 和 file existence 不能推进 gate。

## Start, continue, and resume

1. 确认唯一 Rule、唯一 policy、十六个 Capability contracts 和四个 Profile contracts 可读。
2. 对当前消息请求 Source Event recording，并绑定 `request-intake`。
3. 只从 active durable Intake continuation 决定 attachment；`dormant-read-only` Intake 不可附加，否则创建新 Intake。
4. 将控制权交给 Global Rule；所有 route/control 只来自 current policy。
5. Assignment materialized 后，才读取 lifecycle state 和 decision-bound continuation。
6. 中断后重读 scope state、pointers、markers、artifact components、attempts 和 applicable Git facts，仅从 `last proven gate` 恢复；`dormant-read-only` Intake 只可用于历史来源/决定核验，不可恢复、重激活或调度 Invocation。
7. lifecycle 完成后只请求执行 policy 声明的 Intake retention 后置控制；全部关联 lifecycle target 完成时休眠并失活 continuation，未来消息创建新 Intake。

## Safe degradation

当前 Plan 35 不含 strict validator、evaluator、recorder、digest service、Invocation host 或 deterministic write runtime。缺少某项实际支持时：

- 停在当前 proven gate；
- 指明 unavailable assurance；
- 不声称 Source Event、transition、persistence、digest、currentness、invalidation、attempt、termination、recovery 或 completion 已由机器执行；
- 不手写 machine-owned state 来模拟成功；
- 不自动 repair、rollback、merge 或推断完成。

Implementation mutation 只允许由 `themis-impl` 的 `implementation-writer` 在 current Approval/Plan task/baseline/allowed paths 范围内执行。成功写文件不等于治理 artifact/state 已物化。
