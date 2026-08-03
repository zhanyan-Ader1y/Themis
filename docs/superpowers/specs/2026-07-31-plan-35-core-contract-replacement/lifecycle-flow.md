# 生命周期流程

> 本文件属于 [Plan 35：Core Contract Replacement](../2026-07-31-plan-35-core-contract-replacement-design.md) 的功能 reference，拥有 lifecycle 前台流程、Questioning、simple/full 选择与 sticky escalation。它不是第二份设计权威。稳定 identity 为 lifecycle、Current Request revision 与 `full_path_required`；任何外部消息仍必须先经过 Request Intake。

## 前台流程

```text
public themis Skill
→ record Source Event under Intake
→ themis-current-request-dialogue
   ├─ needs-request-confirmation
   │  → user confirmation Source Event
   │  → second dialogue Invocation
   ├─ rejected
   │  → persist rejection and close Intake
   └─ assignment-confirmed
      → materialize assignment
      → create/update lifecycle Current Request revision
      → themis-q
      → optional Grounding
      → Complexity Assessment
         ├─ simple → Simple Plan → Lightweight Plan Check
         └─ full   → temporary Specification → Planning → Full Plan Check
      → Review Projection
      → Review Check
      → Review Dialogue
      → Review Approval
      → Impl
      → independent Verification
      → Acceptance Dialogue
      → Summary
      → completed
```

多目标 assignment 的各 lifecycle 独立按上述流程推进，不构成 Plan 80 multi-Agent execution。

## 外部消息 interception

所有外部消息的 Source Event、no-change、changed-diff、confirmation 与 durable continuation 恢复规则由 [Request Intake：外部消息 interception](request-intake.md#外部消息-interception) 唯一定义。Lifecycle flow 只在 assignment 已完整物化后消费 decision-bound continuation，不建立第二份消息归属或恢复规则。

## Questioning

`themis-q` 继续只拥有：

- Why；
- impact；
- expected result；
- trigger；
- necessary abstract action；
- result；
- weak-point questioning。

它不拥有：

- claim authority；
- lifecycle assignment；
- persistence；
- scope contract；
- implementation design。

Questioning 回答先经过 Intake。若回答改变 claims，只展示和确认 changed diff；若不改变 claims，则恢复当前 questioning continuation。

## Simple/full 与 sticky escalation

simple path 只有在 Complexity Assessment 逐项证明简单条件后才合法。unknown、无法证明或后续发现隐藏复杂度必须进入 full path。

`full_path_required` 在一个 lifecycle 内保持 sticky：

- simple path 任一阶段触发 `escalate-full` 或发现 full-only 需求后设为 true；
- Current Request 新 revision、retry、Agent restart、session resume 或新 Intake 均不能清除；
- 只影响当前 lifecycle；独立新 lifecycle 拥有自己的 sticky state。

两条路径只在 Plan 形成前不同，之后共享 Review、Approval、Impl、Verification、Acceptance 和 Summary。
