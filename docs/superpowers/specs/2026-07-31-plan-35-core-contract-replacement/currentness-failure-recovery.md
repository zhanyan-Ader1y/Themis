# 当前性、失败与恢复

> 本文件属于 [Plan 35：Core Contract Replacement](../2026-07-31-plan-35-core-contract-replacement-design.md) 的功能 reference，拥有 currentness、invalidation、failure budget、Failure Learning、duplicate/stale 和 interruption recovery 合同。它不是第二份设计权威。Intake Execution Identity 与 lifecycle Plan Task Execution Identity 的预算隔离，且各自第三次 counted failure 后禁止第四次 Invocation。

## Source Event 与 claim changes

Source Event 的存在本身不使 lifecycle 失效。只有 confirmed decision 改变 claims 或 assignment 才触发 invalidation。

- claim revision 或 active set 改变
  → 新 Current Request revision
  → 失效受影响的 Questioning、Assessment、Plan 和下游；
- 不改变 claims 的回答
  → 保留 Current Request revision，形成新 Questioning round 或恢复原 dialogue；
- lifecycle assignment 改变
  → 只影响 decision 明确列出的 lifecycle，禁止隐式搬运动态 state。

## Facts、constraints 与 Plan

- Grounding fact、governed design constraint 或 pre-approval baseline 变化
  → 失效依赖其内容的 Assessment、Plan 和下游；
- Plan 新 revision
  → 失效 Plan Check、Review Projection、Review Check、Approval 和 unfinished downstream；
- Review feedback
  → 记录 feedback，路由 owner，新 artifact materialization 后按其影响传播。

## Delivery currentness

- implementation delta 变化
  → 失效 affected Verification、Acceptance 和 Summary；
- Verification 非 current `passed`
  → 禁止 Acceptance 和 Summary；
- Acceptance 非 current `accepted`
  → 禁止 Summary；
- Summary source binding stale
  → Summary 不再 current，但不反向改写原 Verification 或 Acceptance 历史事实。

## Policy currentness

Policy digest 变化时：

- 停在 last proven gate；
- 重新验证 current bindings 和 legal continuation；
- 不从聊天或旧 Agent context 恢复；
- 不让旧 proposed result 在新 Policy 下自动物化。

## Intake Execution Identity

Intake proposal、confirmation 和 assignment materialization 使用独立 Intake Execution Identity：

- 最大 counted failures 为三次；
- 第三次记录 termination，禁止同一 identity 的第四次 Invocation；
- 不创建 lifecycle；
- 不消耗任何 lifecycle Task Execution budget；
- Intake 保持 `open + terminated execution`；
- 只有新的明确用户输入可以授权一个显式关联的 replacement execution。

## Lifecycle Task Execution Identity

lifecycle 保持按 Plan task 的 Task Execution Identity：

- Impl 与 Verification 共享 budget；
- Acceptance 的 `implementation-defect` repair 继续使用同一 Plan Task Execution Identity 和 budget，返回 current Approval 范围内的 Impl 后必须重新 Verification；
- retry、Agent restart、model change、session resume、worktree replacement 或 simple→full escalation 不清零；
- 第三次终止该 identity；
- 禁止第四次 Invocation；
- 失效 unfinished downstream。

## Failure classification

Counted failure 包括：

- 已开始 Invocation 后 Agent、工具或 command failure；
- missing、invalid、wrong-profile、wrong-scope 或 stale binding 的 Capability result；
- result-contract failure；
- declared execution failure；
- recorder/materialization operation failure；
- `implementation-defect`。

Non-counted control result 包括：

- 等待用户 confirmation、answer、review 或 acceptance；
- `needs-*`；
- `blocked`；
- `partial`；
- `full-required`；
- `escalate-full`。

Invocation 开始前已观察到的宿主能力 unavailable 不创建伪 attempt。Invocation 完成后由独立 external drift 导致的 currentness 失效时，丢弃 proposed result 并 stop-and-revalidate，不将外部漂移计作该 Invocation failure。

attempt 必须在执行前记录。counted failure 必须先记录 observed failure，再触发 Failure Learning 和终止/继续决定。

## Failure Learning

每次 counted failure 后创建非阻塞、scope-bound Failure Learning request：

```text
authority_scope
execution identity
failed attempt/evidence
scope-local main continuation
```

同一 execution identity 后续成功，或显式关联的 replacement execution 成功时，必须再次创建 Failure Learning request。仅凭 prose 相似不能形成 replacement linkage。

Failure Learning：

- 可以显式引用另一 scope 的相关证据；
- 不共享或修改另一 scope 的动态 state；
- 只产生候选；
- 自身失败不递归；
- 不改变 assignment、route、count、Verification、Acceptance 或 lifecycle result；
- 不阻塞 scope-local main continuation 或已完成 delivery。

## Currentness checkpoints

至少在以下位置验证 current bindings：

- Invocation 前；
- Capability result 返回后；
- control action 前；
- current pointer 更新前。

Invocation 使用错误前置 binding，或 result 自身 wrong-profile、wrong-scope、invalid/stale 时，进入 global invalid result，并按 Policy counted fail-closed。

若 Invocation 完成后发生独立 external drift，result 不物化，记录 drift 并 non-counted stop-and-revalidate。

## Result uniqueness

- 一个 Invocation 只接受一个终态 result；
- duplicate、late 或 cancelled Invocation result 永远不能成为 current；
- pending Intake proposal 在 Source Event、claim set、assignment target 或 Policy 改变后 stale；
- stale proposal 不能被旧 confirmation Source Event 复活。

## Interruption recovery

恢复必须重读：

```text
Intake/lifecycle state
+ current pointers
+ complete/incomplete markers
+ artifact components
+ Invocation/attempt records
+ Git facts where applicable
→ identify last proven gate
```

规则：

- 不从聊天、Agent summary 或 temporary reasoning 恢复；
- `dormant-read-only` Intake 不参与中断恢复、重激活或新 Invocation；它的只读 Source Event、decision 和 observation records 只用于历史 authority 核验；
- 完整 revision 已形成但 pointer 未更新时，保留 revision，并重新判断 currentness 后再决定是否更新 pointer；
- paired artifact 只完成一部分时，记录 incomplete，不创建 revision；
- 多目标 assignment 部分成功时保留成功目标，只继续未完成项；已完成 lifecycle target 的 binding 保持 frozen read-only；
- 无法证明唯一合法恢复动作时，返回 required-human/fail-closed；
- 不自动 repair、rollback、merge 或推断完成。
