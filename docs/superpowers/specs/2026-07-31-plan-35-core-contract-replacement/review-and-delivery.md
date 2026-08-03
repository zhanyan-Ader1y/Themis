# 审阅与交付

> 本文件属于 [Plan 35：Core Contract Replacement](../2026-07-31-plan-35-core-contract-replacement-design.md) 的功能 reference，拥有 Review、Approval、Impl、independent Verification、Human Acceptance 和 Summary 合同。它不是第二份设计权威。Review 必须发生在 Impl 前；Verify 固定为 `themis-impl → independent themis-verification`，且 Summary 必须同时受 current passed Verification 和 accepted Human Acceptance 门禁。

## Review Projection

Review Projection 是 checked Plan 的独立、不可变、可验证绑定投影。

`record.md` 至少绑定：

- source checked Plan revision；
- projection profile；
- coverage map；
- content path/digest；
- materialization observation。

`content.md` 按由抽象到具体、高影响优先、异常优先和按需展开原则降低理解成本，可包含必要的时序图或流程图。它不拥有目标或执行语义。

## Review Dialogue

Review Dialogue：

- 展示和解释 Review Projection；
- 按需定位 checked Plan；
- 保存用户反馈原意；
- 将反馈分类到正确 owner；
- 返回 feedback 或 approval proposal。

它不直接 patch Plan 或 Review Projection。用户不手工修改 Plan Markdown 作为治理操作。

合法 feedback owners 包括：

- Current Request Dialogue；
- `themis-q`；
- Specification；
- Simple Planning；
- Planning；
- Plan Check；
- Review Projection。

反馈首先形成独立 immutable feedback revision，再由 owner 产生新的 semantic artifact 或 checker result。Review Dialogue 必须用 owner-specific legal status 表达返回目标：`needs-current-request`、`needs-questioning`、`needs-specification`、`needs-simple-planning`、`needs-planning`、`needs-plan-check` 或 `needs-review-projection`；`needs-grounding` 只保存其中一个已分类 owner 的 continuation。Owner continuation 必须绑定 exact Feedback revision；只有 owner 结果按该 continuation 完整物化并重读后，control layer 才能先记录并重读独立 feedback-resolution observation，再记录并重读引用它的 unresolved-set update observation；只有后一步完成后，新 state view 才能移除该 revision。Plan 或 projection 新 revision 会使旧 Approval stale。

## Review Approval

Review Approval 是不可变 paired artifact，至少绑定：

- lifecycle identity；
- confirmed Intake assignment decision；
- current Current Request revision 与 active claim revisions；
- current Questioning round；
- governed design constraints；
- relevant Grounding/Complexity Assessment refs；
- selected path/profile；
- sticky `full_path_required`；
- checked Plan revision；
- Plan Check result；
- 用户实际看到的 Review Projection revision；
- Review Check result；
- unresolved feedback 为空；
- approver decision Source Event；
- approval time；
- pre-Impl implementation baseline。

Approval 批准的是 checked Plan，不是 Review Projection；绑定 projection 只证明用户批准时实际看到的内容。

Review Dialogue 的 `approved` result 仍只是 proposal。Approval 必须完整物化并重读后才能进入 Impl。

## Verify 定义

Verify 固定为：

```text
themis-impl
→ independent themis-verification
```

Impl 与 Verification：

- 使用不同 Invocation；
- 共享同一 Plan Task Execution Identity 和 failure budget；
- 绑定同一 current Approval、Plan task、baseline 和 expected delta；
- Implementation writer 不验证自身；
- Review Markdown 不是 execution input。

## Impl Result

每次完整实现结果形成独立 immutable paired revision，至少绑定：

- Approval、Plan task 和 Task Execution Identity；
- Invocation/attempt；
- pre-Impl baseline；
- expected delta；
- actual changed paths/delta；
- commands/evidence refs；
- deviations；
- observed post-state。

写入或 attempt 失败可以没有 Impl Result revision。旧结果保留其 failed、stale、superseded 或 invalidated disposition。

## Verification

每次完整 Verification 形成独立 immutable paired revision，至少绑定：

- current Approval 和 Plan revision；
- current Impl Result；
- exact implementation revision/delta；
- independent Invocation/attempt；
- exact commands/observations；
- stdout/stderr/evidence refs；
- coverage；
- verdict；
- residual risk。

只有 current `passed` 可以进入 Acceptance。Verification 不接受 stale、missing 或 producer-only evidence。

## Human Acceptance

Acceptance Dialogue 形成 acceptance proposal；Human Acceptance paired artifact 只有在 control action 完整物化后获得 authority。

Acceptance 至少绑定：

- current Verification；
- current Approval/Plan/Current Request；
- delivered actual delta；
- user decision Source Event；
- observed result/feedback；
- decision。

非 `accepted` 不能进入 Summary。implementation defect 返回 current Approval 范围内的 Impl 并重新 Verification；需求、Plan 或 complexity 问题按 owner 失效上游。

## Summary

Summary 是不可变交付投影，必须绑定：

- current Verification `passed`；
- current Human Acceptance `accepted`；
- actual delta；
- current artifact revisions；
- source evidence refs。

Summary 不能：

- 创建新事实；
- 改变 completion；
- 替换 Verification 或 Acceptance；
- 自动发布知识。

Summary 或知识候选生成失败不改变已经 observed 的 passed/accepted，但在 Summary 未完整物化前 lifecycle 不标记 completed。

Summary 完整物化后的 lifecycle completion 与 Intake retention 后置控制由 [Request Intake](request-intake.md#lifecycle-completion-与-retention) 唯一定义；本文件不建立第二份 completion 规则。
