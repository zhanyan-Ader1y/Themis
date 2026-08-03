# Request Intake

> 本文件属于 [Plan 35：Core Contract Replacement](../2026-07-31-plan-35-core-contract-replacement-design.md) 的功能 reference，拥有 Request Intake、Source Event、assignment、完成后 retention 合同。它不是第二份设计权威。稳定 identity 包括 Intake、Source Event、assignment decision、target operation 和 completion observation；核心不变量是 assignment 前不创建 provisional lifecycle，且 `dormant-read-only` Intake 永不可附加、恢复或重激活。

## Intake identity

每条外部用户消息必须先记录为不可变 Source Event，并绑定一个 Intake identity。Intake 在 lifecycle assignment 前提供独立 authority scope，不使用 provisional lifecycle。

Intake identity 只能由 durable control facts 选择：

- active Intake-local continuation 明确等待某个 `open` Intake 下特定 proposal 的确认时，新消息作为 confirmation Source Event 加入该 Intake；
- active Intake-local continuation 明确等待用户对 terminated Intake Execution 的 restart/unblock 决定时，新消息作为 restart decision Source Event 加入该 Intake；只有明确授权才能创建显式关联的 replacement Execution Identity；
- `dormant-read-only` Intake 的 continuation 全部 inactive，不能接受 Source Event、恢复、重激活或调度 Invocation；
- 其他外部消息全部创建新 Intake，即使消息将继续既有 lifecycle 的 Questioning、Review 或 Acceptance，或涉及曾与 dormant Intake 关联的 lifecycle；
- 不能仅因存在 open/assigned Intake、消息文本像确认/重试或聊天顺序相邻而附加消息；
- public Skill 和 Global Rule 只读取 active continuation binding，不对消息语义进行 Intake 归属判断。

Intake disposition 只有：

```text
open | assigned | rejected | abandoned
```

`rejected` 只来自用户明确决定。`abandoned` 只来自宿主观察到的明确会话终止或离开事件。Capability 和控制面不得从沉默推断二者。

`dormant-read-only` 不是第五种 disposition，而是 `assigned` Intake 在关联 lifecycle 完结后的派生 retention mode。执行失败也不是 disposition；第三次 counted failure 后，Intake 保持 `open`，当前 Intake Execution Identity 为 terminated，禁止第四次 Invocation。

## Source Event

Source Event 至少拥有：

- stable event identity；
- Intake identity；
- actor/source identity；
- observed time；
- original UTF-8 bytes；
- content digest；
- transport metadata；
- recorded result。

原始 bytes 不执行 Unicode 或换行 normalization。规范化文本只能是可重建 projection，不能替代来源 authority。

用户语义的精确引用必须绑定：

```text
event identity
+ UTF-8 byte range
+ quoted fragment digest
```

范围或 digest 与原始 bytes 不一致时必须拒绝。

## Intake assignment

一个 Intake 可以显式分流到一个或多个 lifecycle，也可以更新既有 lifecycle。每个 target operation 必须有 stable identity，且只能是：

```text
create-lifecycle | update-current-request | no-change
```

同一 Source Event 片段可以显式用于多个 target，但每次共享都必须出现在用户确认的 assignment decision 中，禁止隐式多重归属。

多目标 assignment 使用逐目标可恢复持久化：

1. assignment decision 不可变；
2. 每个 target operation 独立执行、观察和记录；
3. 全部 target 物化成功后 Intake 才成为 `assigned`；
4. 部分成功时保持 `open + incomplete`；
5. 不自动 rollback 已成功 target；
6. 恢复时重读实际 target 状态，只继续 `remaining_target_identities`；
7. lifecycle-bearing target 完结后独立记录 completion observation，并冻结该 target 的历史绑定；
8. 任一关联 lifecycle target 未完成时，Intake retention mode 仍为 `active`；
9. 全部关联 lifecycle target observed completed 后，Intake 才整体进入 `dormant-read-only`。

同一 lifecycle 可被多个历史 Intake 的显式 target 引用。completion observation 必须按 lifecycle identity 找到并冻结所有匹配 target，再分别判断每个 Intake 的整体休眠 gate；不能只更新最初创建 lifecycle 的 Intake。没有 lifecycle identity 的 target 不得被虚构成 lifecycle。

## 外部消息 interception

无论 lifecycle 正等待 Questioning、Review、Acceptance 或其他用户输入，每条外部消息都先形成新的 Source Event，并调用 `themis-current-request-dialogue`。

- 无 claim/assignment 变化：返回 `assignment-confirmed + no-change`，物化 Intake decision 后，把原消息 Source Event 交给 durable continuation 指定的 lifecycle Capability；
- 有变化：持久化 proposal，等待 confirmation Source Event；确认和 Current Request materialization 完成后再回原 continuation；
- confirmation Source Event 只确认 governance diff，不自动替代触发原 lifecycle dialogue 的 Source Event。

控制面只依据 durable continuation identity 恢复，不依据聊天上下文猜测消息属于哪个阶段。

## Lifecycle completion 与 retention

Summary revision 完整物化和重读后，Policy 才能记录 lifecycle completion observation。Summary 内容本身不创建 completion 事实。

```text
Summary fully materialized and reread
→ lifecycle completion observed
→ resolve every immutable assignment decision + target identity bound to the lifecycle
→ record completion observation and freeze each matching target read-only
→ for each affected Intake, if every associated lifecycle target is observed completed:
     preserve disposition assigned
     set retention mode dormant-read-only
     deactivate all Intake-local continuations
```

该后置控制不是新的 Capability、status、route key dimension 或 disposition。它只通过 stable immutable references 连接 lifecycle completion 与 Intake retention，不能共享两个 scope 的动态状态。

其他关联 target 未完成时，Intake 保持 `active`，该 target 的 continuation、failure budget 与执行不受已完成 target 影响。

进入 `dormant-read-only` 后：

- 不可附加新 Source Event；
- 不可调度 Invocation；
- 不可恢复、重激活或修改；
- Source Event、proposal、decision、target/completion observation 和历史绑定只读保留；
- 只允许清理可重建 cache；
- 未来外部消息必须创建新 Intake。

若 recorder/runtime 不能观察并记录 completion 或 retention transition，控制面停在 last proven gate，报告 assurance unavailable，不能手写 machine-owned state 冒充休眠完成。
