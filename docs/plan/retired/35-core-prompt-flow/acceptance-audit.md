# Plan 35 Markdown-first Acceptance Audit

> 日期：2026-08-03
> 当前权威：[Plan 35：Core Contract Replacement](../../superpowers/specs/2026-07-31-plan-35-core-contract-replacement-design.md)
> 结论：criteria 1–31 有当前 Markdown contract、人工静态观察或十六场景 replay 证据；criterion 32 保持 `PENDING USER RE-ACCEPTANCE`。

## Audit method

本审计逐项对照 current cross-module authority、唯一自然语言 Policy、Capability/Profile contracts、Markdown templates、Workspace ownership、[静态核验证据](static-verification.md) 与 [十六场景 replay](manual-replay.md)。`PASS` 只表示 Prompt-level 合同与人工证据闭合，不表示 Plan 36/37 的机器保证已执行。

历史 2026-07-31 YAML 审计和重新接受仍是历史事实，但不作为本次 Markdown-first amendment 的当前 PASS 依据。自动 Themis Go CLI audit 为：

```text
unavailable
```

## Acceptance matrix

| # | Status | Current contract evidence | Current replay / observation |
|---:|---|---|---|
| 1 | PASS | [Request Intake](../../superpowers/specs/2026-07-31-plan-35-core-contract-replacement/request-intake.md) 与 [Intake/retention Policy](../../../templates/.themis/core/policies/references/intake-and-retention.md) 要求外部消息先形成 immutable Source Event | [01](manual-replay/scenario-01-new-intake-confirmation.md)、[05](manual-replay/scenario-05-questioning-claim-change.md)、[06](manual-replay/scenario-06-review-acceptance-intake-first.md) |
| 2 | PASS | Intake attachment 只接受 active durable confirmation/restart/unblock continuation；`dormant-read-only` 永不可附加 | [02](manual-replay/scenario-02-active-no-change-and-dormancy.md)、[15](manual-replay/scenario-15-interruption-recovery.md)、[16](manual-replay/scenario-16-rejection-abandonment-new-intake.md) |
| 3 | PASS | [Authority scopes](../../../templates/.themis/core/policies/references/authority-scopes.md) 隔离 `request-intake` 与 `lifecycle`，assignment 前禁止 provisional lifecycle | [01](manual-replay/scenario-01-new-intake-confirmation.md)、[03](manual-replay/scenario-03-multi-target-completion.md)、[04](manual-replay/scenario-04-partial-target-recovery.md) |
| 4 | PASS | Source Event template 保存原始 bytes 引用、digest/length 与 `normalization: none`；claim fragment 保存精确 byte range/reference | [01](manual-replay/scenario-01-new-intake-confirmation.md)、[05](manual-replay/scenario-05-questioning-claim-change.md)；静态 §7 |
| 5 | PASS | Current Request `record.md + content.md` 要求 user-confirmed、source-bound claims | [01](manual-replay/scenario-01-new-intake-confirmation.md)、[05](manual-replay/scenario-05-questioning-claim-change.md) |
| 6 | PASS | Intake proposal/decision templates 要求 changed-only semantic diff 与逐项 `confirm | correct | keep-ambiguous` disposition | [01](manual-replay/scenario-01-new-intake-confirmation.md)、[05](manual-replay/scenario-05-questioning-claim-change.md) |
| 7 | PASS | `no-change` 保留原 dialogue continuation，不要求冗余确认 | [02](manual-replay/scenario-02-active-no-change-and-dormancy.md)、[06](manual-replay/scenario-06-review-acceptance-intake-first.md) |
| 8 | PASS | Intake target operations 固定为 `create-lifecycle | update-current-request | no-change`；partial recovery、target freeze 和 all-target dormancy 均有 Policy owner | [03](manual-replay/scenario-03-multi-target-completion.md)、[04](manual-replay/scenario-04-partial-target-recovery.md)、[14](manual-replay/scenario-14-completion-and-retention-gates.md) |
| 9 | PASS | [Capability package](../../../templates/.themis/core/capabilities/README.md) 固定十六个 internal Capability，保留原十五项职责并新增 Current Request Dialogue | 静态 §5：Capability contracts = 16 |
| 10 | PASS | `themis-current-request-dialogue` 固定绑定 `request-intake + human-dialogue`，只返回 proposal，不直接持久化 governance state | [01](manual-replay/scenario-01-new-intake-confirmation.md)、[02](manual-replay/scenario-02-active-no-change-and-dormancy.md)、[05](manual-replay/scenario-05-questioning-claim-change.md) |
| 11 | PASS | [Agent Profiles](../../../templates/.themis/core/agent-profiles/README.md) 恰好四个；只有 `themis-impl` 使用 `implementation-writer`，没有 governance writer | 静态 §5：Profile contracts = 4、writer = `themis-impl` |
| 12 | PASS | 公共 `themis` entry 与 Global Rule 对所有外部消息执行 Intake interception，再使用 exact durable continuation | [05](manual-replay/scenario-05-questioning-claim-change.md)、[06](manual-replay/scenario-06-review-acceptance-intake-first.md)、[16](manual-replay/scenario-16-rejection-abandonment-new-intake.md) |
| 13 | PASS | 一个公共 `themis` 治理入口、一个 [Global Rule entry](../../../templates/.themis/core/kernel/orchestrator/rules.md)、一个 [Markdown Policy package](../../../templates/.themis/core/policies/README.md) 保持唯一 | 静态 §5–6；六个 phase-route references 均存在 |
| 14 | PASS | 语义 route identity 保持 `capability + selected_path + profile + status`；scope 由 Capability binding 固定，Markdown 不形成 parser table 或 DSL | 静态 §6：历史 98 组合有迁移覆盖，当前四条 owner-specific Review 补充单独记录 |
| 15 | PASS | [Materialization/currentness](../../../templates/.themis/core/policies/references/materialization-and-currentness.md) 要求 result 验证、唯一 Policy rule、control action、完整记录、重读、revision observation 和 separate pointer update | [04](manual-replay/scenario-04-partial-target-recovery.md)、[09](manual-replay/scenario-09-paired-artifact-pointer-failure.md) 分别实例化单 half、明确 digest mismatch 与 pointer update failure、[10](manual-replay/scenario-10-invalid-result.md) |
| 16 | PASS | 十一类 paired semantic artifacts 使用同一 revision 下的 `record.md + content.md`；任一 half 或 identity/digest/scope/source/artifact binding 无效使 whole revision invalid | [09](manual-replay/scenario-09-paired-artifact-pointer-failure.md) 明确观察 `record.md.content_digest != content.md observed digest`；静态 §7 |
| 17 | PASS | Logical artifacts 使用 immutable revision 与独立 current pointer；dormancy 是引用 immutable decision/completion observations 的独立 retention fact | [03](manual-replay/scenario-03-multi-target-completion.md)、[09](manual-replay/scenario-09-paired-artifact-pointer-failure.md)、[14](manual-replay/scenario-14-completion-and-retention-gates.md) |
| 18 | PASS | Questioning 使用每轮独立 `record.md + content.md`；未回答问题只保留 proposal/continuation | [05](manual-replay/scenario-05-questioning-claim-change.md)；静态 §7 |
| 19 | PASS | Attempt、artifact revision、pointer、incomplete operation 与 post-completion retention observation 在 templates/Workspace 中保持分离 | [04](manual-replay/scenario-04-partial-target-recovery.md)、[09](manual-replay/scenario-09-paired-artifact-pointer-failure.md)、[12](manual-replay/scenario-12-shared-delivery-failure-budget.md)、[14](manual-replay/scenario-14-completion-and-retention-gates.md) |
| 20 | PASS | [Workspace ownership](../../../templates/.themis/workspace/references/directory-ownership.md) 只允许 state 保存最小 refs/control/retention observations，不复制或改写 artifact/source/decision semantics | [14](manual-replay/scenario-14-completion-and-retention-gates.md)、[15](manual-replay/scenario-15-interruption-recovery.md) |
| 21 | PASS | Review Projection 是 checked Plan 的绑定投影；Approval 批准 Plan 并绑定 exact shown projection、空 unresolved set 与 pre-Impl baseline；上游 Plan revision 变化阻止 prior Approval 恢复 current | [07](manual-replay/scenario-07-review-feedback-owner.md) 建立 `plan-revision-p1` / `approval-revision-a1`，观察 Feedback invalidation 先使旧 Approval stale，并由新 `plan-revision-p2` 的 binding 变化阻止其复活；[14](manual-replay/scenario-14-completion-and-retention-gates.md)；静态 §8 |
| 22 | PASS | Review Feedback 是独立 immutable pair，七个 owner 使用唯一 status；Review Dialogue 不 patch Plan；closure 绑定 exact Feedback/continuation 并经过 resolution + set-update 两步 observation | [07](manual-replay/scenario-07-review-feedback-owner.md) 以 `planning` owner 代表分支产生新 Plan，并保留 `plan-check` / `review-projection` 不产生新 Plan 的边界；[Review routes](../../../templates/.themis/core/policies/references/routes/review.md) |
| 23 | PASS | Verify 固定为 `themis-impl → independent themis-verification`；两次 Invocation 共享 Plan Task Execution Identity 与 cumulative budget | [12](manual-replay/scenario-12-shared-delivery-failure-budget.md)；静态 §8 |
| 24 | PASS | Verification、Human Acceptance、Summary 为独立 immutable pairs；`passed → accepted → Summary` gates 后另行观察 completion，再执行 Intake retention | [12](manual-replay/scenario-12-shared-delivery-failure-budget.md)、[14](manual-replay/scenario-14-completion-and-retention-gates.md) |
| 25 | PASS | [Failure control](../../../templates/.themis/core/policies/references/failure-control.md) 隔离 Intake/lifecycle budgets；对应 identity 第三次 counted failure 终止并禁止第四次 Invocation | [11](manual-replay/scenario-11-intake-failure-isolation.md)、[12](manual-replay/scenario-12-shared-delivery-failure-budget.md) |
| 26 | PASS | Failure Learning 可绑定 `request-intake` 或 `lifecycle` 中恰好一个 scope，只产生 candidate，non-blocking、non-recursive 且不改主流程 | [11](manual-replay/scenario-11-intake-failure-isolation.md)、[13](manual-replay/scenario-13-failure-learning.md) |
| 27 | PASS | Duplicate、late、stale、wrong-profile、wrong-scope、incomplete 或 invalid binding result 均拒绝成为 current | [09](manual-replay/scenario-09-paired-artifact-pointer-failure.md)、[10](manual-replay/scenario-10-invalid-result.md) |
| 28 | PASS | Interruption 只从 durable facts 与 last proven gate 恢复；dormant Intake 只供历史核验，不参与恢复、reactivation 或 Invocation | [04](manual-replay/scenario-04-partial-target-recovery.md)、[15](manual-replay/scenario-15-interruption-recovery.md)、[16](manual-replay/scenario-16-rejection-abandonment-new-intake.md) |
| 29 | PASS | `full_path_required` 是 lifecycle-local、`false → true` only，跨 retry/restart/resume 保持 sticky | [08](manual-replay/scenario-08-sticky-full-escalation.md) |
| 30 | PASS | [Assurance boundary](../../../templates/.themis/core/policies/references/assurance-boundary.md) 明确 Plan 36 strict assurance、Plan 37 runtime、Plan 80 multi-Agent、Plan 90 Attribution 均不由 Plan 35 实现或声称 | 每个 replay 都列出缺失机器保证；静态 §8、§12 |
| 31 | PASS | 当前 Markdown-first 静态检查与十六类人工 replay 都有实际观察证据，不复用旧 YAML PASS；权威枚举中的 Review owner 新 Plan/旧 Approval stale，以及 paired half-write/digest mismatch/pointer failure 均已显式实例化 | [静态核验证据](static-verification.md)；[replay index](manual-replay.md)、[07](manual-replay/scenario-07-review-feedback-owner.md)、[09](manual-replay/scenario-09-paired-artifact-pointer-failure.md) 与其余 [scenario-01…16](manual-replay/) |
| 32 | PENDING USER RE-ACCEPTANCE | 用户尚未审阅并明确重新接受当前 Markdown-first 实际证据 | 历史 2026-07-31 acceptance 不替代本次 amendment；用户沉默、assistant 判断、reviewer 报告或系统通知均不构成接受 |

## Cross-cutting observations

- `templates/.themis` 活动 YAML：0。
- Internal Capability contracts：16；Agent Profile contracts：4；唯一 writer：`themis-impl`。
- Policy phase-route references：6。
- 已删除 YAML 的历史迁移覆盖：98 个组合；current owner model 另有 4 个 Review 结果，人工 current coverage enumeration 为 102。两者都不是产品 identity、固定 route table、DSL 或 Go CLI 输入。
- Paired semantic families：11；structured Markdown records：7；Intake target operations：3。
- Manual replay files：恰好 16；每个文件：恰好 11 个标准观察标题。
- Automated Go contract/replay/audit check：`unavailable`。

## Audit conclusion

Criteria 1–31 在当前 Markdown-first contracts、人工静态观察和十六场景 replay 中都有可追溯证据。该结论不宣称 unavailable machine guarantees 已执行，也不恢复 Plan 36/37。

Criterion 32 保持：

```text
PENDING USER RE-ACCEPTANCE
```

只有用户审阅当前静态证据、十六个场景和本三十二项矩阵并明确重新接受后，criterion 32 才可改变。
