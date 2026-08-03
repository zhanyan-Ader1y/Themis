# Guard、失效与恢复

> 本文件属于 [`themis-core-control`](../README.md) 唯一 Policy，拥有 lifecycle path guard、Review/Verify/Acceptance/Summary gates、失效传播和 interruption recovery。它不是独立 Policy。

## Lifecycle 路径

Simple path 依次使用 `themis-q`、`themis-complexity-assessment`、`themis-simple-plan` 和 lightweight `themis-plan-check`。Full path 依次使用 `themis-q`、`themis-complexity-assessment`、`themis-spec`、`themis-planning` 和 full `themis-plan-check`。

Plan Check 通过后，两条路径共用 Review Projection、Review Check、Review Dialogue、Review Approval、`themis-impl`、independent `themis-verification`、Acceptance Dialogue 和 Summary。

## Sticky `full_path_required`

`full_path_required` 在每个 lifecycle 初始为 false，只允许 `false → true`。Questioning re-entry、reassessment、Agent restart、model change、session resume、worktree replacement、task retry 或新 Intake 都不能清除同一 lifecycle 的 sticky state；独立 lifecycle 拥有独立状态。

Simple route 的共同 guard 是 `full_path_required == false`。当 Complexity Assessment 返回 `simple-qualified` 但 sticky flag 已为 true 时，控制面仍物化 Assessment，却必须保持 sticky full、选择 full path、继续 `themis-spec`，并失效 quick Plan、Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream；该 guard failure 为 `non-counted`，也不重置 failure budget。

任何 simple stage 的 `escalate-full` 或 full-only owner result 都必须设置 sticky full，并按对应 route 失效 quick downstream。

## Review、Verify 与 completion gates

Review Approval 必须发生在 Impl 前，并要求 unresolved feedback 为空。Approval 必须绑定 lifecycle identity、confirmed assignment decision、Current Request/claims、Questioning round、governed constraints、Grounding/Assessment、path/profile/sticky flag、checked Plan/Plan Check、用户实际看到的 Review Projection/Review Check、approval Source Event/time 和 pre-Impl baseline。

Verify 固定为 `themis-impl → independent themis-verification`。两者使用不同 Invocation，但绑定同一 Approval、Plan task、baseline、expected delta 和 Plan Task Execution Identity；writer self-verification 禁止。Expected approved delta 本身不使 Approval 失效，Review Markdown 不是 execution input。

只有 current Verification `passed` 才能进入 Acceptance；只有 current Verification `passed` 且 current Human Acceptance `accepted` 才能进入 Summary。Knowledge candidate failure 不改变已观察的 passed/accepted，但 Summary 未完整物化前 lifecycle 不能 completed。

## 失效传播

- Intake proposal 改变时，旧 Intake decision 失效。
- Confirmed assignment 改变时，受影响的 Current Request、Questioning、Complexity Assessment、Plan 和 unfinished downstream 失效。
- Current Request revision 改变时，受影响的 Questioning、Complexity Assessment、Plan 和 unfinished downstream 失效。
- Questioning round、governed design constraint 或 pre-approval baseline 改变时，受影响的 Complexity Assessment、Plan 和 unfinished downstream 失效。
- Plan revision 改变时，Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效。
- Review Projection 改变时，Review Check、Review Approval 和 unfinished downstream 失效。
- 存在 unresolved Review Feedback 时，Review Approval 和 unfinished downstream 失效。Feedback 只有在 exact owner continuation 绑定该 revision、owner 结果完整物化并重读、separate resolution observation 已记录并重读、且后续引用它的 unresolved-set update observation 也已记录并重读后，才能从新 state view 中移除；文件存在或 Invocation 开始不构成 resolution。
- Approval invalid 时，Verify、Human Acceptance 和 Summary 不可继续。
- Implementation delta 改变时，affected Verification evidence、Human Acceptance 和 Summary 失效。
- Verification 非 current `passed` 时，Human Acceptance 和 Summary 不可继续。
- Sticky full escalation 使 quick Plan、Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效。

Source Event 的存在本身不使 lifecycle 失效；只有 confirmed decision 改变 claims 或 assignment 才传播 invalidation。No-change answer 保留 Current Request revision，并形成新 Questioning round或恢复原 durable dialogue。

## 中断恢复

恢复只能重读 scope state、current pointers、completion/incomplete markers、artifact components、Invocation/attempt records 和 applicable Git facts，以确定 last proven gate。

禁止从 chat、Agent summary、temporary reasoning 或 temporary Specification handoff 恢复；禁止 automatic repair、rollback、merge 或 inferred completion。`dormant-read-only` Intake 不参与 recovery、reactivation 或 Invocation。

完整 revision 已形成但 pointer 未更新时，保留 revision并重新验证 currentness；paired artifact 只完成部分时保持 incomplete；多目标 assignment 部分成功时只继续 remaining targets，已完成 target 保持 frozen read-only。

## 必须停止的情况

若无法证明唯一合法 guard outcome、invalidation set、current gate 或 recovery action，控制面必须返回 required-human/fail-closed 并停止。不得从自由文本选择 path、清除 sticky flag、复活 stale Approval 或推断 completion。
