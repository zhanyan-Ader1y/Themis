# 场景 04：多 target 部分成功后的恢复

## 初始 durable facts

- Immutable assignment decision 已 current。
- Target A 有 complete materialization observation；Target B 为 incomplete。
- Intake 保持 `open + incomplete`，并记录 `remaining_target_identities: [B]`。
- 原 recorder/materialization failure 已计入同一 Intake Execution Identity。

## 选择的 Capability / Profile / scope

- 不启动新的 semantic Capability。
- `request-intake` scope 的 recovery control 重读 decision、每 target observation、remaining identities、failure count 与 exact recovery continuation。

## proposed status

无。Recovery 是 Policy/Rule control，不是 Capability result，也不创造隐藏 status。

## 适用的自然语言控制规则及其标题

- [Intake 入口控制 · Assignment 物化](../../../../templates/.themis/core/kernel/orchestrator/references/intake-entry.md#assignment-物化)：partial success 保留完成 target，只恢复 remaining targets。
- [Failure、失效与恢复控制 · 持久事实恢复](../../../../templates/.themis/core/kernel/orchestrator/references/failure-invalidation-recovery.md#持久事实恢复)：从 incomplete markers 与 target observations 确定 last proven gate。
- [Guard、失效与恢复 · 中断恢复](../../../../templates/.themis/core/policies/references/guards-invalidation-and-recovery.md#中断恢复)：禁止 rollback、replay completed write 或 inferred completion。

## control action

- 重读 A/B observations，验证 A 确已完成、B 仍在 remaining set。
- 保持 A frozen read-only，只执行 `resume-remaining-target-operations-only` 对 B 的动作。
- B 完成后重新观察 assignment completion，再将 Intake disposition 设为 `assigned` 并分别恢复 decision-bound continuations。

## materialized record/revision

- 保留原 immutable Decision 和 A observation。
- 为 B 写入新的 operation observation；若成功，再写 assignment complete observation。
- 不生成 replacement decision，不覆盖 A。

## current pointer/gate

- B 未完成前停在 assignment materialization gate。
- B 完成并重读前，不派发任何尚未获证实的 lifecycle continuation。

## invalidation

- A 不因 B 的失败而失效或回滚。
- B 的 partial candidate 不 current。

## failure class

- 原 recorder/materialization failure：`counted`，只消耗 Intake budget。
- Recovery 本身不重置 Execution Identity 或 count；preflight unavailable 不制造伪 attempt。

## 缺失 machine guarantees

Incomplete detection、operation idempotence、target-specific resume、recorder 和 deterministic recovery runtime 均为 `unavailable`。

## replay result

**PASS（人工合同重放）**：当前 Rule/Policy 明确只有 remaining-target recovery，已完成 target 保留且预算不清零。
