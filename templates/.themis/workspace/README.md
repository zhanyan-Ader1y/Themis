# Workspace Package

## Responsibility

Workspace is the project-owned boundary for durable Request Intake records, lifecycle artifacts, control facts, execution evidence, outcomes, and governed knowledge candidates. Core is read-only. Workspace stores observed records and references but does not decide routes, semantic judgments, currentness, or completion.

## Directory ownership

| Path | Ownership |
|---|---|
| `manifest.yaml` | Project identity, explicit commands/Gates, paths, adapters, and restricted policy overrides |
| `context/` | Governed Context inputs; never proof of current implementation |
| `intakes/<intake-id>/` | Source Events, claim/assignment proposals, confirmation decisions, Intake state, Intake-local continuations, and post-completion retention facts |
| `changes/<lifecycle-id>/` | Immutable Current Request, Questioning, Plan, Review Projection, Approval, and Review Feedback revision families |
| `state/<lifecycle-id>/` | Minimal lifecycle control facts, current pointers, invalidations, markers, incomplete operations, and last proven gate |
| `runs/<lifecycle-id>/` | Task Execution, Invocation, attempt, Impl Result, and Verification records |
| `evidence/<lifecycle-id>/` | Command evidence, Git observations, and external evidence |
| `outcomes/<lifecycle-id>/` | Immutable Human Acceptance and Summary revision families |
| `knowledge/intakes/<intake-id>/` | Intake-scoped Failure Learning candidates and dispositions |
| `knowledge/lifecycles/<lifecycle-id>/` | Lifecycle-scoped Failure Learning/Summary candidates and dispositions |
| `cache/` | Rebuildable indexes, bundles, and projections; never authority |
| `policies/` | Restricted project overrides that cannot bypass global invariants |

## Approved shape

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

The fresh scaffold creates family roots only. It does not pre-create example Intake, lifecycle, or revision identities.

## Artifact and state model

Paired semantic revisions use an opaque revision directory containing one machine record and one governed Markdown document. Structured-only judgments and operational/evidence records remain separate families. A path or file does not prove authority: identity, bindings, complete materialization, completion observation, reread, immutable revision observation, and separate pointer update are required where applicable.

A completed Questioning exchange is one immutable `questioning/<round-revision>/` pair. An unanswered question remains proposal/continuation state and is not a completed round.

Lifecycle state stores only control facts and references: current gate and pointers, policy identity/digest, sticky flags, Execution Identity and attempt references, currentness, markers, invalidations, incomplete operations, and last proven gate. It must not copy Current Request claims, Plan content, design, Acceptance semantics, or artifact prose.

## Scope isolation

Request Intake and lifecycle records may reference the same immutable Source Event or assignment decision but cannot share dynamic state, Execution Identity, failure budget, continuation authority, current pointer, or completion state.

A confirmed and fully materialized Intake assignment decision must exist before lifecycle creation or update. Target operations are exactly `create-lifecycle | update-current-request | no-change`. Each target has its own decision-bound continuation, materialization status, and observation. Partial success remains `open + incomplete`; successful targets remain authoritative, `remaining_target_identities` identifies unfinished work, and recovery resumes only those remaining targets without automatic rollback.

## Post-completion Intake retention

When a lifecycle Summary pair is fully materialized and lifecycle completion is observed, the completion observation is recorded against every immutable Intake assignment target bound to that lifecycle identity under each `intakes/<intake-id>/state/`. Each matching target binding becomes read-only without changing other targets.

An assigned Intake enters derived retention mode `dormant-read-only` only after every associated lifecycle-bearing target is observed completed. Its disposition remains `assigned`; all Intake-local continuations become inactive and non-attachable. Source Events, proposals, confirmation and assignment decisions, target materialization observations, lifecycle completion observations, and historical bindings remain immutable read-only records. They are not deleted, rewritten, or used to schedule an Invocation or recover execution. Only rebuildable cache may be cleaned.

While any associated lifecycle target remains incomplete, the Intake stays `active`; completed target bindings are frozen independently and cannot block, roll back, or mutate unfinished targets. A future external message never attaches to a `dormant-read-only` Intake and must create a new Intake identity.

## Evidence and recovery

Code, configuration, Schema, and observed executable behavior are the only current implementation fact sources. Plan, Review, Context, Specification, Summary, and Agent prose cannot substitute for direct evidence.

Recovery rereads scope state, pointers, completion/incomplete markers, every required artifact component, Invocation/attempt records, and applicable Git facts to determine the last proven gate. It does not infer completion or automatically repair, roll back, merge, or continue partial writes.

## Installation and runtime boundary

Fresh installation must refuse an existing `.themis/` or conflicting managed target before writing. There is no upgrade, migration, or compatibility path.

Plan 35 provides this scaffold and Prompt-level ownership contracts only. It does not provide an installer, validator, evaluator, recorder, digest service, deterministic writer, command runner, transaction system, lock manager, or automatic recovery runtime.
