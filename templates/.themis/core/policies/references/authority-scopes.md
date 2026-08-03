# 权威范围

> 本文件属于 [`themis-core-control`](../README.md) 唯一 Policy，拥有 Policy binding、authority model、双 authority scope 和跨 scope 隔离规则。它不是独立 Policy。

## Policy 绑定

Policy identity 固定为 `themis-core-control`。每次 Invocation 必须绑定控制面已观察到的 current Policy digest；digest 改变时必须停在 last proven gate，重新验证 current bindings 和唯一 legal continuation，旧 proposed result 不得在新 Policy 下自动物化。

Route decision identity 固定使用 `capability + selected_path + profile + status`。固定 route 数量不是产品 identity，authority scope 由 Capability contract 唯一约束而不是加入 route key。

## 权威模型

- 外部输入 authority 是 immutable Source Event 的原始 bytes 及其精确片段引用。
- 目标语义 authority 是 user-confirmed、source-bound Current Request claims。
- 当前实现事实只来自 code、configuration、schema 和 observed executable behavior。
- governed design constraints 只约束可选方案，不替代当前实现事实。
- Specification handoff 是 full path 的 temporary non-authoritative input，不拥有持久 current pointer。
- current approved Plan 是 execution contract；Review Projection 只证明用户实际看到的 checked Plan 投影。
- Capability result 永远是 proposed output，不直接成为 authority。
- Authority 只有在唯一 Policy control、完整 persistence、completion observation、reread 和 separate current pointer update 全部成功后成立。

## `request-intake` scope

`request-intake` 唯一拥有：Source Event references；claim/assignment proposals；用户 confirmation decisions；Intake Execution Identity；Intake-local continuation；Intake current pointers；Intake disposition；以及 post-completion retention facts。

Intake disposition 的闭合枚举只有 `open | assigned | rejected | abandoned`。Retention mode 的闭合枚举只有 `active | dormant-read-only`；`dormant-read-only` 不是 disposition、Capability status 或 route-key 维度。

Intake Capability 固定使用 `selected_path: null` 与 `profile: null`。Confirmed assignment 完整物化前禁止创建 provisional lifecycle。

## `lifecycle` scope

`lifecycle` 唯一拥有：Current Request revisions；Questioning rounds；path/Plan state；Review/Approval state；Plan Task Execution Identity；Verification/Acceptance/Summary state；lifecycle-local continuations；以及 lifecycle current pointers。

Lifecycle durable gate 依次覆盖 Questioning、Complexity Assessment、Plan formation、Plan Check、Review、Verify、Human Acceptance、Summary 和 completed。路径只在 Plan 形成前不同，Plan Check 后共用 Review、Approval、Impl、independent Verification、Acceptance 和 Summary。

## 范围隔离

两个 scope 之间禁止共享 dynamic state、Execution Identity、failure budget、continuation authority、current pointer 和 completion state。跨 scope 只允许通过 stable immutable references 关联。

同一 Source Event 可以被两个 scope 引用，但引用不转移 ownership。Failure Learning 可以在两个 scope 运行，但每次 Invocation 只能绑定一个 scope、一个 scope-local execution identity 和一个 scope-local main continuation；它不能跨 scope 修改动态状态。

## 必须停止的情况

若 Invocation 未唯一绑定一个合法 scope，Capability 与 scope 不匹配，或 control action 试图共享被禁止的动态 authority，Global Rule 必须停止，拒绝结果并按 [Failure control](failure-control.md) 的 invalid-result 规则处理；不得根据消息含义、目录位置或 Agent prose 推断 scope。
