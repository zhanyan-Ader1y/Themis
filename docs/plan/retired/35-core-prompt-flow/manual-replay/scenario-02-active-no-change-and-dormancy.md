# 场景 02：active no-change 恢复与 dormant 排除

## 初始 durable facts

- Variant A：某 lifecycle 正等待 active Review/Questioning/Acceptance continuation；新 Source Event 与 confirmed claims/assignment 完全一致。
- Variant B：历史 Intake 的 disposition 为 `assigned`、retention 为 `dormant-read-only`，全部 Intake-local continuations 已 inactive。

## 选择的 Capability / Profile / scope

- Variant A：`themis-current-request-dialogue` / `human-dialogue` / `request-intake` / `null/null`。
- Variant B：不允许在 dormant Intake 上选择 Capability；Global Rule 先为消息创建新 Intake，之后才可在新 scope 调用 Current Request Dialogue。

## proposed status

- Variant A：`assignment-confirmed`，target operation 为 `no-change`。
- Variant B：旧 dormant Intake 没有合法 proposed status、attachment 或 reactivation route。

## 适用的自然语言控制规则及其标题

- [Intake 与保留 · 外部消息 interception](../../../../templates/.themis/core/policies/references/intake-and-retention.md#外部消息-interception)：只有 active confirmation/restart continuation 可 attachment，其他消息创建新 Intake。
- [Intake 路由 · `assignment-confirmed`](../../../../templates/.themis/core/policies/references/routes/intake.md#assignment-confirmed)：`no-change` 只能沿 decision-bound continuation 恢复原 dialogue。
- [Intake 与保留 · `dormant-read-only`](../../../../templates/.themis/core/policies/references/intake-and-retention.md#dormant-read-only)：禁止 attachment、Invocation、恢复、重激活或修改。

## control action

- Variant A 物化 no-change Intake Decision，把原 Source Event 与 exact fragments 交回原 durable lifecycle continuation，不重复请求用户确认，不创建新 Current Request revision。
- Variant B 保留 dormant history read-only，为新消息建立新 Intake identity。

## materialized record/revision

- Variant A：新 Source Event、immutable no-change Intake Decision 和 target observation。
- Variant B：新 Intake 下的新 Source Event；旧 Intake 的 Source Events、decisions、completion observations 和 historical bindings 不变。

## current pointer/gate

- Variant A 保持原 lifecycle pointer/gate。
- Variant B 的旧 Intake 不提供 current continuation；新 Intake 从自己的 Intake gate 开始。

## invalidation

- No-change 不使 Current Request 或 lifecycle downstream 失效。
- Dormant history 不失效、不重写，也不被复活。

## failure class

- 合法 no-change 与拒绝 dormant attachment：`none` / `non-counted` control。
- 试图把 dormant history 当 attachment signal 时必须 fail closed。

## 缺失 machine guarantees

Claim equivalence、attachment enforcement、decision persistence、continuation dispatch 和 dormant prohibition 的机器执行均为 `unavailable`。

## replay result

**PASS（人工合同重放）**：active no-change 只在 Decision 完整物化后恢复原 continuation；dormant Intake 明确无恢复路径，后续消息只能创建新 Intake。
