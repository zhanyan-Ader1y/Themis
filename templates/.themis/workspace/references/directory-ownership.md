# Workspace 目录归属

## 目录表

| 路径 | 归属 |
|---|---|
| `project.md` | 项目 identity、显式 commands/Gates、paths、adapters 与 restricted Policy overrides |
| `context/` | 受治理经验、背景、约束与核验线索；不得证明当前实现 |
| `intakes/<intake-id>/` | Source Events、claim/assignment proposals、confirmation decisions、Intake state、Intake-local continuations 与 retention facts |
| `changes/<lifecycle-id>/` | Current Request、Questioning、unified Plan、Review Projection、Approval 与 Review Feedback revision families |
| `state/<lifecycle-id>/` | 最小 lifecycle control facts、current pointers、invalidations、markers、Review Feedback resolution 与 unresolved-set update observations、incomplete operations 与 last proven gate |
| `runs/<lifecycle-id>/` | Plan Task Execution、Invocation、attempt、Impl Result 与 Verification records |
| `evidence/<lifecycle-id>/` | Command evidence、Git observations 与 external evidence |
| `outcomes/<lifecycle-id>/` | Human Acceptance 与 Summary immutable revision families |
| `knowledge/intakes/<intake-id>/` | Intake-scoped Failure Learning candidates 与 dispositions |
| `knowledge/lifecycles/<lifecycle-id>/` | Lifecycle-scoped Failure Learning/Summary candidates 与 dispositions |
| `cache/` | 可重建 index、bundle 与 projection；永不拥有 authority |
| `policies/` | 不得绕过 global invariants 的 restricted project overrides |

## Family 根目录

```text
workspace/
  intakes/<intake-id>/
    source-events/
    proposals/
    decisions/
    state/

  changes/<lifecycle-id>/
    current-request/
    questioning/
    plan/
    review/
    approval/
    feedback/

  state/<lifecycle-id>/
    lifecycle-state
    current-pointers/
    invalidations/
    feedback-resolutions/
    feedback-set-updates/
    markers/

  runs/<lifecycle-id>/
    task-executions/
    invocations/
    attempts/
    impl-results/
    verification-results/

  evidence/<lifecycle-id>/
    commands/
    git-observations/
    external-evidence/

  outcomes/<lifecycle-id>/
    acceptance/
    summary/

  knowledge/
    intakes/<intake-id>/
    lifecycles/<lifecycle-id>/
```

Fresh scaffold 只创建 family roots，不预建示例 Intake、lifecycle、revision 或 current pointer identity。Fresh installation 在任何写入前必须拒绝既有 `.themis/` 或冲突 managed target；不存在 upgrade、runtime migration 或 compatibility path。
