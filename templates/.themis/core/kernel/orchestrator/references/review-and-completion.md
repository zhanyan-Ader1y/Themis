# Review 与完成控制

> 本文件属于 [Themis Global Control Rule](../rules.md) 的按 gate 加载 reference。它解释 Review、Approval、Verify、Acceptance、Summary、lifecycle completion 与 Intake retention 的通用顺序；具体 status、control action、guard 与 failure class 由唯一 [自然语言 Policy](../../../policies/README.md) 决定。

## 加载条件

Current Plan Check 已 pass，或 durable gate 位于 Review Projection、Review Check、Review Dialogue、Impl、Verification、Acceptance、Summary、lifecycle completion 或 Intake retention 后置控制时加载本文件。

任何 Review 或 Acceptance 用户消息必须先加载 Intake reference 完成 Source Event interception，再返回本文件保存的 exact lifecycle continuation。

## Review 与 Approval

Review 必须发生在 Impl 前：

```text
current checked Plan
→ Review Projection
→ independent Review Check
→ Review Dialogue
→ explicit Review Approval
→ Impl
```

Review Projection 是 checked Plan 的只读精简投影，不是 execution contract。Review Check 只检查投影忠实度与呈现负担，不能检查或修改实现。Review Dialogue 只解释、定位与分类用户反馈，不能写 Feedback/Approval、patch Plan/projection 或执行 semantic owner route。

Review Feedback 必须物化为独立 immutable revision，再返回 Policy 分类的 semantic owner。Grounding 可为 bound owner 收集事实，但不是 Review Feedback owner。Owner continuation 必须绑定 exact Feedback revision；只有 owner proposal/result 沿该 continuation 完整物化、重读并证明 owner action 后，控制层才先记录并重读 separate feedback-resolution observation，再记录并重读引用它的 unresolved-set update observation；只有后一步完成后，新 state view 才能移除该 revision。文件存在、相似内容或 owner Invocation 开始都不能推断 resolved。

Approval 只有在以下内容全部 current 且 unresolved feedback 为空时才能物化：Current Request、Questioning、governed design constraints、Assessment、selected path/profile、checked Plan、Plan Check、exact Review Projection、Review Check、explicit overall user decision 与 pre-Impl baseline。任一 bound input 变化都使旧 Approval 失效；用户自由文本或 Review 文件存在不能替代 Approval materialization。

## Verify 控制

Verify 固定为：

```text
themis-impl
→ independent themis-verification
```

Impl 与 Verification 是不同 Invocation，但绑定同一 current Approval、Plan task、baseline、expected delta、Plan Task Execution Identity 与 failure budget。Implementation writer 不能验证自身，Review Projection 不能作为 execution input。

Expected delta 是 Approval 已授权的变化，不因成功写入而使 Approval 失效。未授权 workspace、dependency、configuration、Schema 或 behavior change 是 external drift：停下并重验 currentness，不把 otherwise successful Invocation 计为执行失败。

Verification `failed` 和 Acceptance `implementation-defect` 都返回 current Approval 范围内的 bounded implementation repair continuation，共享同一 task identity/budget，且 repair 后必须重新进行 independent Verification。

## Acceptance 与 Summary

Human Acceptance 要求 current Verification 为 `passed`。Acceptance 用户消息先经过 Intake interception；它保存 source-bound user observation，silence 不构成 accepted。

Summary 要求 current Verification 为 `passed` 且 current Human Acceptance 为 `accepted`。Summary 是实际交付的 bound projection，不得描述未观察到的实现，也不能自动发布 knowledge candidate。

Summary pair 完整物化并重读后，才能记录 observed lifecycle completion。Summary prose 或文件存在不能自行创建 completion。

## Lifecycle completion 与 Intake retention

Completion 被观察后：

1. 解析所有明确绑定该 lifecycle identity 的 immutable assignment decision 与 target identity；
2. 为每个匹配 target 记录 lifecycle completion observation，并只冻结该 target binding；
3. 保持 Intake disposition 为 `assigned`；
4. 若同一 Intake 仍有未完成 lifecycle-bearing target，保持 retention `active`，不影响其 continuation 或 execution；
5. 仅当该 Intake 的全部关联 lifecycle target 均 observed completed 时，记录 `dormant-read-only` 并停用所有 Intake-local continuation；
6. Source Events、proposals、confirmations、decisions、target/completion observations 与历史 bindings 保持 immutable read-only。

`dormant-read-only` 是 derived retention，不是 Capability status、route-key dimension 或第五个 disposition。它不能 attachment、Invocation、mutation、reactivation 或 recovery；未来消息创建新 Intake。

## 返回与停止

- Review Feedback 返回其已分类且持久化的 semantic-owner continuation。
- Approval materialized 后返回 Impl。
- Impl 后只返回 independent Verification。
- Verification passed 后返回 Acceptance；accepted 后返回 Summary。
- Completion observation 后返回逐 Intake target 的 retention continuation。
- Approval stale、writer 自验、Verification/Acceptance/Summary gate 不成立、repair 创建新 budget、completion/retention observation 缺失或 competing terminal results 时停止，并按 Policy 处理对应 failure class。
