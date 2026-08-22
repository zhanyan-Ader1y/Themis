# 场景 14：Completion 与 Intake retention 门禁

## 初始 durable facts

- Lifecycle A 有 current Verification `passed`、current Human Acceptance `accepted` 和 current Summary continuation。
- 同一 Intake 的 confirmed assignment decision包含 lifecycle-bearing targets A 与 B；B 尚未 completed。
- Variant failure 分别缺少 passed Verification、accepted Acceptance或完整 Summary pair。

## 选择的 Capability / Profile / scope

`themis-summary` / `semantic-readonly` / `lifecycle`；Summary完成后的 retention是 control-plane post-control，不调用新的 Capability。

## proposed status

Lifecycle A 在全部 gates成立时返回 `ready`；外部 blocker可返回 `blocked`。缺少 Verification/Acceptance gate时，`ready` 是非法结果而非可接受状态。

## 适用的自然语言控制规则及其标题

- [交付阶段路由 · Summary](../../../../templates/.themis/core/policies/references/routes/delivery.md#themis-summary--semantic-readonly)：`ready` 要求 passed + accepted 并先物化 Summary。
- [Intake 与保留 · Lifecycle completion 后置控制](../../../../templates/.themis/core/policies/references/intake-and-retention.md#lifecycle-completion-后置控制)：completion后逐 target freeze。
- [Intake 与保留 · `dormant-read-only`](../../../../templates/.themis/core/policies/references/intake-and-retention.md#dormant-read-only)：只有 all-target completed 才进入只读保留。

## control action

- 完整物化并重读 Summary pair，随后另行记录 lifecycle completion observation。
- 找出所有绑定 A 的 immutable assignment targets，逐 target记录 completion observation并冻结 A binding。
- 因 B 未完成，Intake retention保持 `active`；B completed后才保持 disposition `assigned` 并记录 `dormant-read-only`，停用全部 Intake-local continuations。

## materialized record/revision

Summary pair、lifecycle completion observation、A target completion/freeze observation；B完成后另有B observation与whole-Intake retention observation。

## current pointer/gate

Summary pair或文件存在本身不创建 completion。A可进入 completed gate；Intake在B完成前仍active。Whole-Intake dormancy不改变各 lifecycle的历史authority。

## invalidation

缺少或 stale Verification/Acceptance/Summary时，completion和retention后置控制不可继续。A完成不得失效或完成B。

## failure class

合法 Summary `ready`为 `none`，`blocked`为 `non-counted`；绕过gate、错误binding或materialization failure为counted invalid-result。

## 缺失 machine guarantees

Summary recorder、gate evaluator、completion recorder、target lookup/freeze、whole-Intake retention和dormancy enforcement均为 `unavailable`。

## replay result

**PASS（人工合同重放）**：passed、accepted、完整 Summary与separate completion observation依次门禁；target A独立冻结，B未完成时Intake保持active，全部target完成后才dormant-read-only。
