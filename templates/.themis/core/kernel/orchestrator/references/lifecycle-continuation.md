# Lifecycle continuation 控制

> 本文件属于 [Themis Global Control Rule](../rules.md) 的按 gate 加载 reference。它解释 assignment 后 Questioning、Grounding、Complexity Assessment、simple/full 选择、统一 Plan 与 Plan Check 的通用顺序；具体 legal status、action、guard failure 与 invalidation 由唯一 [自然语言 Policy](../../../policies/README.md) 决定。

## 加载条件

Fully materialized assignment decision 已创建或更新 lifecycle Current Request 后，以及当前 durable gate 位于 Questioning、Grounding、Assessment、Specification、Planning 或 Plan Check 时加载本文件。

每条新的用户消息仍须先加载 Intake reference 完成 Source Event interception，再返回本文件所保存的 lifecycle continuation。

## Current Request 与 Questioning

Lifecycle 只能消费 user-confirmed、source-bound Current Request revision。每个 revision 是 immutable confirmed claim revisions 集合，绑定 exact Source Event fragments，并使用 `active | ambiguous | superseded` disposition。

Questioning 必须消费 current Current Request。Unanswered question 只形成 durable proposal 与 human-questioning continuation，不能形成 completed round。Answer 先经过 Intake interception，再由新的 Invocation 绑定 post-answer Current Request revision。

Completed exchange 必须物化一组 immutable Questioning `record.md + content.md`，完整重读后再更新 separate current pointer。Round、pointer 或 post-answer binding 不一致时停止，不能从 chat 拼接 completed round。

## Grounding 控制

Grounding 只核验代码、配置、Schema、observed executable behavior 与 current sources。调用者必须保存 `requesting-capability` 和 exact continuation；Grounding 完成后只能返回该 owner。

`partial` 必须保留 observed facts、unknowns 与限制，不能解释为 `ready`。`blocked` 进入 durable human-unblock continuation。Grounding 不能自行选择后续 Capability，也不能让设计文档、Plan、经验或 Agent prose证明当前实现事实。

## Complexity Assessment 与 path

Assessment 只能根据 current Current Request、Questioning、Grounding 与 sticky state 形成 proposal。Unknown 不能默认为 simple。

```text
Current Request
→ Questioning
→ optional Grounding
→ Complexity Assessment
   ├─ simple → Simple Plan → lightweight Plan Check
   └─ full   → temporary Specification → Planning → full Plan Check
```

`full_path_required` 是 lifecycle-local、单向 `false → true` 的 sticky guard。若 status 为 `simple-qualified` 但 sticky flag 已 true，必须使用 Policy 声明的 guard-failure action，保留 full 并进入 Specification；不得清除 flag 或调用 Simple Planning。

## 统一 Plan 与 Plan Check

Simple 与 full path 只在 Plan 形成前不同，并产生同一个 paired Plan family。不得创建 `simple-plan`、`full-plan` 或 persistent Specification authority。

- Simple Planning 只在 simple 已逐项证明且 sticky false 时运行。
- Specification 只提供 full-path temporary non-authoritative handoff。
- Planning 消费 current bindings 与 temporary handoff，形成统一 Plan proposal。
- Plan materialization 必须遵守 Invocation 与物化 reference。
- Plan Check 使用 fixed `independent-checker`，并证明 checker 与 producer 隔离。
- Lightweight/full profile 只能返回各自 Policy 允许的 status；quick-only status 不得出现在 full path。

Plan Check current `pass` 后返回 Review Projection continuation。新的 Plan 或返回 semantic owner 的 finding 必须按 Policy 失效旧 Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream。

## 返回与停止

- Questioning 等待 answer 时返回 durable human-questioning continuation。
- Grounding 后返回 requesting Capability 的 exact continuation。
- Assessment 后只返回 Policy 证明的 simple 或 full continuation。
- Plan Check pass 后返回 Review Projection。
- `needs-*`、`blocked` 与 sticky escalation 只按 Policy 声明的 non-counted control action 返回。
- Wrong path/profile、sticky guard 无法读取、producer/checker isolation 无法证明、temporary handoff 被当成 authority或 current bindings 不完整时停止；Invocation/result 后的无效情况交给 Policy invalid-result。
