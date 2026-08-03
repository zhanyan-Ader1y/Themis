# Core 控制 Policy

## 身份与职责

本文件是 `themis-core-control` 的唯一 Policy entry。`references/` 中的主题文件和阶段 route 文件共同构成同一份自然语言 Policy，只按当前 authority scope、durable gate、Capability 和 continuation 按需加载，不形成第二份 Policy。

本 Policy 同时治理 `request-intake` 与 `lifecycle` 两个隔离 authority scope。Global Rule 只能解释本 Policy、验证 Invocation/result bindings、请求 control action 并消费 observed recorder result；Capability 只返回 proposed semantic result；Workspace 只保存 observed state、records、evidence 和 current pointers。

## 控制规则定位

自然语言控制规则通过以下四项定位：

```text
capability + selected_path + profile + status
```

`authority_scope` 不是第五个 route 维度。每个 Capability 的 legal scope 和 fixed Agent Profile 由 [Capability bindings](references/capability-bindings.md) 唯一约束。`recommended_route` 只用于 diagnostics，不能覆盖本 Policy。

旧 `transitions.yaml` 中观察到 98 个合法结果组合；该数字只用于本次表示迁移的人工覆盖核对，不是产品 identity、永久常量、固定 Markdown 行数、Go CLI 输入或可解析 DSL。

## Global Rule 的加载顺序

Global Rule 必须先读取 current authority scope、Policy identity/digest、Execution Identity、durable gate、current pointers、exact continuation 和待调用 Capability，再按以下顺序加载：

1. 总是加载与当前决定直接相关的共享主题 reference；
2. 根据当前 Capability 只加载一个对应的阶段 route reference；
3. `themis-failure-learning` 根据 Invocation 已验证的 scope/path/profile 加载 Learning route，不跨 scope 搬运动动态状态；
4. 在 Invocation 开始前，任一必需 reference 缺失、不可读、冲突、无法唯一定位或不能与 observed current Policy binding 对齐时，必须停在 last proven gate，报告 Policy package unavailable/ambiguous，且不创建 attempt、不计入 failure budget；不得从聊天、Agent summary 或自由文本补全规则；
5. 只有 Invocation 已开始，或 proposed result 返回后出现 zero/multiple rule match、Policy binding mismatch 或其他 invalid-result 原因时，才进入 counted invalid-result control。

## Reference 选择

### 共享主题

- [Authority scopes](references/authority-scopes.md)：Policy binding、authority owner、双 scope 与跨 scope 隔离。
- [Intake and retention](references/intake-and-retention.md)：外部消息 interception、多目标 assignment、completion 与 `dormant-read-only`。
- [Capability bindings](references/capability-bindings.md)：closed vocabulary、十六个 Capability、fixed Profile、legal status 和 materialization target。
- [Materialization and currentness](references/materialization-and-currentness.md)：proposal、完整物化、currentness checkpoint、paired/structured record。
- [Guards, invalidation and recovery](references/guards-invalidation-and-recovery.md)：sticky full guard、Review/Verify gates、invalidation 与 interruption recovery。
- [Failure control](references/failure-control.md)：双预算、counted/non-counted、Failure Learning 和 invalid result。
- [Assurance boundary](references/assurance-boundary.md)：Plan 35 Prompt-level 边界与 unavailable guarantees。

### 阶段 route

- [Intake](references/routes/intake.md)：`themis-current-request-dialogue`。
- [Understanding](references/routes/understanding.md)：`themis-q`、`themis-grounding`、`themis-complexity-assessment`。
- [Planning](references/routes/planning.md)：`themis-simple-plan`、`themis-spec`、`themis-planning`、`themis-plan-check`。
- [Review](references/routes/review.md)：`themis-review-projection`、`themis-review-check`、`themis-review-dialogue`。
- [Delivery](references/routes/delivery.md)：`themis-impl`、`themis-verification`、`themis-acceptance-dialogue`、`themis-summary`。
- [Learning](references/routes/learning.md)：scope/path-bound `themis-failure-learning`。

## 每条自然语言规则的完整性

每个 route 规则组必须用完整中文句子共同说明：合法 status；current bindings、guard 和 durable facts；需要物化或记录的对象；成功后的 Capability、Human Dialogue 或 gate；guard failure action 与 next；失效范围；`none | non-counted | counted` failure class；以及必须停止且不得从自由文本猜测 route 的条件。

Capability Invocation Result 永远只是 proposal。只有结果通过唯一规则匹配、control action 完整执行、所有组件持久化、completion/incomplete 被观察、内容与 identity/digest/bindings 被重读、immutable revision 被观察且独立 current pointer 更新成功后，才可能成为 current authority。

## 表示与接受边界

本 Markdown package 是唯一活动 Policy 表示；旧 YAML 表示在全局 authority cutover 中删除，不再形成迁移对照或第二份设计权威。该切换本身不证明 Markdown-first 静态一致性、人工 replay 或用户重新接受，也不产生 machine enforcement。

当前没有已批准并已实现的 Go parser、Policy evaluator、validator、recorder 或 deterministic write runtime。Global Rule 和 guidance 不得声称这些自然语言规则已被机器执行。
