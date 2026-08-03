# Invocation 与物化控制

> 本文件属于 [Themis Global Control Rule](../rules.md) 的按 gate 加载 reference。它解释 preflight、一次性 Invocation、proposed result、唯一 Policy rule 匹配与完整 materialization；Capability 的 legal scope、Profile、status 和具体 control action 由唯一 [自然语言 Policy](../../../policies/README.md) 决定。

## 加载条件

当前 durable gate 准备调用任一 Capability、验证 proposed result、请求 control action、物化 record/artifact 或更新 current pointer 时加载本文件。恢复未完成物化时还必须加载 failure/invalidation/recovery reference。

## Invocation 前 preflight

按当前 authority scope 与 durable continuation 重读：

- scope state、Execution Identity 与 remaining budget；
- Policy identity/digest 与 current pointers；
- complete/incomplete/termination markers；
- 当前 gate 所需的 artifact components、Source Event、baseline 与 evidence；
- selected Capability contract、fixed Agent Profile、selected path/profile；
- exact continuation 与允许的 reads/writes/commands；
- 预期 materialization target。

随后读取 Policy entry、与当前决定直接相关的共享主题 reference，以及唯一对应的阶段 route reference。不得复制或缓存第二份 status/route mapping。

Invocation 前发现 required package/reference 缺失、不可读、冲突、无法唯一定位或不能与 observed Policy binding 对齐时，停在 last proven gate 并报告 unavailable/ambiguous。此时不创建 attempt、不消耗 failure budget，也不得从聊天、summary 或旧 Agent context 补全规则。

## 一次性 Invocation

每次 Invocation 必须唯一绑定：

- 一个 authority scope 与 scope identity；
- 一个 scope-local Execution Identity；
- 一个新的 Invocation identity 与 attempt identity；
- 一个 Capability 与其 fixed Agent Profile；
- current Policy identity/digest；
- selected path/profile；
- current Source Event、artifact、baseline 与 evidence bindings；
- exact durable continuation；
- allowed reads/writes/commands；
- expected materialization target 与 remaining failure budget。

当实际 recorder 存在时，started execution 前必须记录 attempt。一次 Invocation 只运行一个 temporary Agent；Capability 或 Agent 不得嵌套调用。Retry 可获得新的 Invocation/attempt identity，但 unchanged authoritative inputs 必须保留同一 scope-local Execution Identity 与 failure count。

## Proposed result 验证

Capability result 永远只是 proposal。只接受与 Invocation 唯一匹配的单个终态 result，并验证：Capability、scope、Profile、status、path/profile、identity、current bindings、payload、evidence、permissions、continuation 与 materialization target。

Stale、duplicate、late、wrong-scope、wrong-profile、incomplete、permission-expanding、illegal payload 或 competing terminal result 必须拒绝。

使用以下四项在 current Policy 阶段 reference 中匹配且只匹配一条自然语言控制规则：

```text
capability + selected_path + profile + status
```

`authority_scope` 不是第五维度。Zero/multiple match、Policy binding mismatch 或其他 post-Invocation/result invalid-result 进入 Policy 声明的 counted failure control；不得从 `recommended_route`、诊断 prose、相近 status 或旧上下文猜测替代 route。

## 完整物化顺序

只有按以下顺序完成，proposal 才可能成为 authority：

1. 验证 result identity、scope、Profile、status、bindings 与 payload；
2. 匹配 exactly one current Policy rule；
3. 请求且只请求该规则声明的 control action；
4. 持久化全部 required components；
5. 记录 complete 或 incomplete observation；
6. 重读 record 与 content；
7. 核对 identity、scope、digest、bindings 与 target path；
8. 观察 immutable revision；
9. 更新 separate current pointer；
10. 重读 pointer 并证明它引用该 revision。

Paired semantic artifact 的 `record.md` 或 `content.md` 任一缺失，或 identity/digest/scope/binding 不一致，整个 revision 无效。Pointer update 失败时 immutable revision 可存在但不 current。不得原地修改 immutable revision，也不得以 symlink、文件存在或成功写入声明 authority。

Temporary Specification handoff 是唯一没有 persistent pointer 的 semantic handoff；它仍非权威，并在中断后从 current bindings 重新生成。

## 返回与停止

Control action 完整物化并重读后，才返回 Policy rule 声明的 Capability、Human Dialogue 或 gate continuation。任一 recorder、digest、validator、evaluator、write support 或 currentness 证明 unavailable 时，停在 last proven gate；不得手写 machine-owned state 模拟成功。
