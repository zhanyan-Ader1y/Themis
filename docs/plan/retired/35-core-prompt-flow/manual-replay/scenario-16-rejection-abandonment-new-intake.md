# 场景 16：Rejection、abandonment 与 post-dormancy 新 Intake

## 初始 durable facts

- Variant A：active Intake正在等待用户对changed-only proposal作明确决定。
- Variant B：宿主观察到明确session termination/leave event。
- Variant C：用户保持沉默，没有新Source Event。
- Variant D：旧Intake已为`assigned + dormant-read-only`，随后收到新外部消息。

## 选择的 Capability / Profile / scope

- Variant A 使用`themis-current-request-dialogue` / `human-dialogue` / `request-intake`。
- Variant B是host-observed post-control，不伪造Capability result。
- Variant C不调度Invocation。
- Variant D先创建新Intake和immutable Source Event，再按新Intake选择Current Request Dialogue。

## proposed status

- A只有明确用户拒绝才返回`rejected`。
- B没有`abandoned` Capability status。
- C没有status。
- D的新Intake可合法返回`needs-request-confirmation`、`assignment-confirmed`或`rejected`，取决于新Source Event。

## 适用的自然语言控制规则及其标题

- [Intake 路由 · `rejected`](../../../../templates/.themis/core/policies/references/routes/intake.md#rejected)：只接受明确用户decision Source Event。
- [Intake 与保留 · Rejection 与 abandonment](../../../../templates/.themis/core/policies/references/intake-and-retention.md#rejection-与-abandonment)：abandonment只由宿主观察记录，沉默不构成abandonment。
- [Intake 与保留 · `dormant-read-only`](../../../../templates/.themis/core/policies/references/intake-and-retention.md#dormant-read-only)：旧Intake禁止attachment/reactivation/recovery，未来消息创建新Intake。

## control action

- A物化rejection decision并关闭该Intake，不创建lifecycle。
- B记录host-observed abandonment，保留历史records，只读关闭；不得改写为`rejected`。
- C保持原等待continuation，不推断decision或failure。
- D拒绝把消息attach到旧Intake，创建新Intake identity、Source Event、Execution Identity和独立continuation。

## materialized record/revision

A产生Intake rejection decision；B产生host abandonment observation；C不产生新record；D产生新Intake Source Event及后续proposal/decision。旧dormant Intake全部历史bindings保持immutable read-only。

## current pointer/gate

A/B进入各自closed retention；C停在等待用户gate；D使用全新的Intake gate，旧Intake没有current mutation或recovery continuation。

## invalidation

Rejection/abandonment不失效其他Intake或lifecycle authority。新Intake不得复活、合并或覆盖旧dormant Intake。

## failure class

合法`rejected`为`none`；等待/沉默为`non-counted`且不执行Invocation；host abandonment不是Capability failure。伪造rejection、attach dormant Intake或错误scope binding属于counted invalid-result。

## 缺失 machine guarantees

Host event recorder、silence detector boundary、retention enforcer、new-Intake allocator和attachment validator均为 `unavailable`。

## replay result

**PASS（人工合同重放）**：明确rejection、host-observed abandonment、silence和post-dormancy新消息保持四种不同控制事实；旧dormant Intake不能被附加、恢复或重激活。
