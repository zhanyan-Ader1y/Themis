# Plan 35 Markdown-first 人工流程重放

> 日期：2026-08-03
> 状态：十六个场景已按当前自然语言 Policy 人工重放；自动 Themis Go CLI replay 为 `unavailable`。

## Assurance boundary

本索引只汇总 replacement Plan 35 的 Prompt-level 合同重放。每个场景以 durable facts、Capability/Profile/scope、合法 status、适用自然语言规则、control action、物化、pointer/gate、失效、failure class 与缺失机器保证为固定观察维度。

`PASS（人工合同重放）` 只表示当前 Markdown contracts 对该场景给出唯一、可追溯且 fail-closed 的声明式结果，不表示 Policy evaluator、recorder、validator、digest、writer、pointer、failure counter、command runner 或 recovery runtime 已执行。Plan 36/37 保持暂停。

```text
automated-go-replay: unavailable
```

## Scenario index

1. [新 Intake、确认与 lifecycle creation](manual-replay/scenario-01-new-intake-confirmation.md)
2. [Active no-change resume 与 dormant exclusion](manual-replay/scenario-02-active-no-change-and-dormancy.md)
3. [Multi-target assignment、target freeze 与 all-target dormancy](manual-replay/scenario-03-multi-target-completion.md)
4. [Partial target recovery](manual-replay/scenario-04-partial-target-recovery.md)
5. [Questioning answer 改变 claim](manual-replay/scenario-05-questioning-claim-change.md)
6. [Review/Acceptance message 先经过 Intake](manual-replay/scenario-06-review-acceptance-intake-first.md)
7. [Review Feedback owner 与 durable resolution](manual-replay/scenario-07-review-feedback-owner.md)
8. [Sticky full 单向升级](manual-replay/scenario-08-sticky-full-escalation.md)
9. [Paired artifact 与 pointer failure](manual-replay/scenario-09-paired-artifact-pointer-failure.md)
10. [Invalid result fail closed](manual-replay/scenario-10-invalid-result.md)
11. [Intake failure 与 lifecycle budget 隔离](manual-replay/scenario-11-intake-failure-isolation.md)
12. [Delivery 共享三次失败预算](manual-replay/scenario-12-shared-delivery-failure-budget.md)
13. [Failure Learning 非阻塞且不递归](manual-replay/scenario-13-failure-learning.md)
14. [Completion 与 Intake retention 门禁](manual-replay/scenario-14-completion-and-retention-gates.md)
15. [Interruption recovery 与 last proven gate](manual-replay/scenario-15-interruption-recovery.md)
16. [Rejection、abandonment 与 post-dormancy 新 Intake](manual-replay/scenario-16-rejection-abandonment-new-intake.md)

## Coverage matrix

| 场景 | Capability / scope 焦点 | 主要不变量 |
|---:|---|---|
| 01 | Current Request Dialogue / `request-intake` | Source Event-first、两次确认、无 provisional lifecycle |
| 02 | Current Request Dialogue / `request-intake` | active continuation、`no-change`、dormant 不可附加 |
| 03 | Intake post-control + lifecycle refs | multi-target、逐 target freeze、all-target dormancy |
| 04 | Intake recovery | partial success 保留、只恢复 remaining targets、no rollback |
| 05 | Current Request Dialogue → Questioning | claim change 先确认、Current Request pointer 先更新 |
| 06 | Intake → Review/Acceptance | 每条外部消息先过 Intake、exact durable continuation |
| 07 | Review Dialogue + 七个 owner | status/owner 唯一、exact bindings、代表分支新 Plan 使旧 Approval stale、两步 durable closure |
| 08 | quick/full lifecycle | `full_path_required` 单向 sticky、budget 不重置 |
| 09 | paired producer | 单 half、明确 digest mismatch、whole-pair invalidation、pointer failure 后 non-current complete revision |
| 10 | 任一 Invocation | duplicate/late/wrong binding 与 zero/multiple match fail closed |
| 11 | Current Request Dialogue / `request-intake` | Intake/lifecycle Execution Identity 与 budget 隔离 |
| 12 | Impl → Verification → Acceptance | separate Invocation、shared Plan task budget、第三次终止 |
| 13 | Failure Learning / 两种 scope | scope-bound、candidate-only、non-blocking、non-recursive |
| 14 | Summary + retention post-control | passed + accepted gate、separate completion、all-target dormancy |
| 15 | Global Rule recovery | durable facts、last proven gate、terminated/dormant exclusion |
| 16 | Intake close/new Intake | rejection ≠ abandonment、silence ≠ abandonment、新 Intake |

## Overall conclusion

十六个场景恰好各有一个独立文件，每个文件都包含十一项标准观察。所有场景引用当前自然语言 Policy 或 Global Rule 标题，不以已删除的 YAML、固定机器行、隐藏 DSL、聊天内容、文件存在或 Agent summary 建立 authority。

人工重放观察到 Intake-first、双 scope 隔离、七 owner Review closure、代表 owner 新 Plan 使旧 Approval stale、sticky full、paired half-write/digest mismatch/pointer failure、invalid-result、共享/隔离失败预算、Failure Learning、Verify/Acceptance/Summary gates、completion retention 与 durable recovery 均有唯一声明式闭环。机器执行保证继续为 `unavailable`；该 replay 不构成 criterion 32 的用户重新接受。
