# 场景 15：Interruption recovery 与 last proven gate

## 初始 durable facts

- Variant A：paired artifact只完成一个component并有incomplete marker。
- Variant B：完整revision已形成但current pointer update失败。
- Variant C：multi-target Intake部分成功，保存`remaining_target_identities`。
- Variant D：Plan Task Execution Identity已第三次失败而terminated。
- Variant E：仅有旧temporary Specification handoff、chat或Agent summary。

## 选择的 Capability / Profile / scope

恢复动作由Global Rule按durable gate协调；只有确定last proven gate后才选择一个对应Capability与fixed Profile。`dormant-read-only` Intake不选择任何Capability。

## proposed status

Recovery本身不是Capability status。恢复后Capability只能返回其当前path/profile的合法status；不得复用中断前未完整接受的result。

## 适用的自然语言控制规则及其标题

- [Failure、失效与恢复控制 · 持久事实恢复](../../../../templates/.themis/core/kernel/orchestrator/references/failure-invalidation-recovery.md#持久事实恢复)：只从durable facts确定last proven gate。
- [Guard、失效与恢复 · 中断恢复](../../../../templates/.themis/core/policies/references/guards-invalidation-and-recovery.md#中断恢复)：禁止从chat、summary或temporary handoff恢复。
- [物化与当前性 · Incomplete 与 pointer failure](../../../../templates/.themis/core/policies/references/materialization-and-currentness.md#incomplete-与-pointer-failure)：区分partial pair与non-current complete revision。

## control action

- A保持incomplete并从原gate恢复，不补写或推断revision。
- B重读完整revision、pointer和current bindings，只在明确action下重试pointer。
- C保留已成功target，只继续`remaining_target_identities`，不rollback。
- D拒绝第四次Invocation；required terminated task阻止Acceptance/Summary。
- E从current bindings重新生成temporary handoff；chat/summary不参与恢复。

## materialized record/revision

只使用scope state、pointers、complete/incomplete/termination markers、artifact components、Invocation/attempt records、target observations和适用Git facts；不把临时对话内容物化为恢复authority。

## current pointer/gate

每个variant停在可由durable evidence唯一证明的last proven gate。无法唯一确定时required-human/fail-closed。

## invalidation

只应用current Policy已声明的invalidation；恢复不得自动repair、rollback、merge、resolve conflict、mutate pointer或重放已完成write。

## failure class

Recovery decision本身不制造failure。错误地接受stale/partialresult、第四次Invocation或未经授权的write属于counted invalid-result；preflight unavailable不创建attempt。

## 缺失 machine guarantees

Recovery evaluator、marker/pointer recorder、partial-write inspector、termination enforcement和deterministic resume runtime均为 `unavailable`。

## replay result

**PASS（人工合同重放）**：五个variant都只从durable facts回到last proven gate；temporary handoff、chat、Agent report、文件存在和dormant Intake均不能充当恢复来源。
