# Themis Global Control Rule

## Purpose

This Rule is the only Themis lifecycle control logic kept in persistent context. It coordinates lifecycle identity, current bindings, Capability invocation, policy interpretation, observed persistence, invalidation, failure limits, and safe degradation. It does not own the semantic judgment implemented by internal Capabilities and does not duplicate their legal status routes.

Load these control contracts as needed:

- `../../policies/transitions.yaml` as the sole status-route declaration source;
- one selected `../../capabilities/*.md` contract;
- the fixed `../../agent-profiles/*.md` contract mapped by policy;
- actual lifecycle records and references from Workspace.

Do not import sibling Rules. Do not treat chat, summaries, temporary Agent reasoning, or `recommended_route` as lifecycle state.

## Ownership Model

```text
Capability        = stable semantic judgment contract
Agent Profile     = execution permission and isolation contract
Agent Invocation  = temporary carrier for exactly one Capability
transitions.yaml  = sole legal status-route policy
Global Rule       = generic policy interpreter and lifecycle coordinator
Workspace         = per-lifecycle actual records and references
```

Only the public `.claude/skills/themis/SKILL.md` starts, continues, or restores the lifecycle. The fifteen lifecycle abilities are internal Capability contracts, not separately registered project Skills.

## Authority Model

Classify every input before use:

1. **Current Request Revision** owns what the current delivery must achieve. It contains only the user's original request, additions, corrections, and explicit decisions.
2. **Governed design constraints** constrain acceptable solutions; they neither rewrite Current Request nor prove current implementation.
3. **Code, configuration, Schema, and observed executable behavior** are the only current implementation fact sources.
4. **Temporary Specification handoff** is a full-path, non-persistent, non-authoritative refinement.
5. **Approved unified Plan** is the execution contract after its selected Plan Check and Human Review pass.
6. **Workspace records and evidence** prove lifecycle events only after the responsible operation is observed.

Specification, historical Specs, Plan prose, `review.md`, Summary, design documents, module contracts, Themico, `themis-context`, external references, Agent analysis, and conversation memory cannot prove current implementation behavior. Preserve disagreements and return them to their semantic owner; never silently merge target semantics, constraints, implementation facts, or lifecycle evidence.

## Managed Change Entry

Use this lifecycle for changes to project behavior, configuration, Schema, code, or durable contracts. Do not fabricate lifecycle artifacts for pure explanation, read-only investigation, or explicitly requested research.

Create one lifecycle identity and one immutable Current Request Revision. A new goal that can be independently approved and delivered creates a new lifecycle rather than expanding the current one or clearing its sticky full-path state. If ownership is ambiguous, preserve the user's wording and ask through the dialogue Capability.

## Required Package

The lifecycle can advance only when all contracts required at the current gate are readable:

```text
.claude/skills/themis/SKILL.md
.themis/core/kernel/orchestrator/rules.md
.themis/core/policies/transitions.yaml
.themis/core/capabilities/<selected>.md
.themis/core/agent-profiles/<fixed>.md
actual lifecycle records and current bindings
```

One invocation loads exactly one Capability and its fixed Agent Profile. At package initialization, verify that policy declares exactly fifteen unique Capability identities, maps each to one of exactly four Agent Profile contracts, and that every mapped file exists; do not copy that mapping into this Rule. A Capability does not call another Capability. An Agent does not call another Agent. A result cannot select another Profile, expand permission, persist lifecycle state, or choose the next route.

## Generic Invocation Sequence

For every lifecycle step, execute this order:

1. Determine the current lifecycle identity and control position from actual records.
2. Verify the bound policy identity/digest and all required current lifecycle bindings.
3. Select the Capability named by the current control position.
4. Read that Capability contract and its fixed `agent_profile` mapping from `transitions.yaml`.
5. Create one Invocation Identity with the minimum lifecycle-bound inputs, Task Execution Identity, path/profile, allowed reads/writes/commands, expected outputs, and any policy-required continuation.
6. Run one temporary Agent invocation; nested Capability or Agent calls are forbidden.
7. Validate the returned Capability identity, legal envelope and payload shape, path/profile, current bindings, evidence references, and Agent Profile permission boundary.
8. Match exactly one policy row using `capability + selected_path + profile + status`, then apply any policy-level guard whose declared precondition matches current lifecycle state.
9. If validation fails or route matching yields zero or multiple rows, execute the policy's global `invalid_result`; do not infer or rewrite a semantic status.
10. For a counted failure, record the attempt first, invoke non-blocking Failure Learning with the saved main-route continuation, then terminate on the third failure or continue with the declared route.
11. Execute the effective `control_action`, wait for observed persistence where required, apply declared invalidation, and only then move to `next`.
12. Discard temporary invocation context and retain only observed structured records, artifacts, evidence, bindings, and references.

`recommended_route` is diagnostic only. Diagnostics, prose, model confidence, or apparent intent cannot replace status lookup or a policy guard.

## Invocation and Result Boundary

Each Invocation Identity binds at least:

```text
Agent Invocation
├── lifecycle identity
├── Task Execution Identity
├── Invocation Identity
├── Capability identity
├── fixed agent_profile
├── authoritative input revisions/digests
├── selected_path and profile when applicable
├── minimum input bundle and continuation identity
├── allowed project read/write scopes and commands
├── exclusive worktree identity for concurrent mutating work
├── pre-Impl baseline and expected write state
├── expected artifact or evidence destination
└── failure attempt and remaining budget
```

Every Capability Invocation Result must preserve the Capability contract's envelope:

```text
Capability Invocation Result
├── capability
├── status
├── input_bindings
├── output
│   ├── structured_result
│   └── artifact_references
├── diagnostics
└── recommended_route
```

Validate that the result belongs to the invoked Capability; required bindings equal current lifecycle inputs; referenced artifacts/evidence are available and current when checking support exists; the payload satisfies the Capability contract; path/profile is legal; no quick-only result appears on the full path; and the result did not exceed its Agent Profile. Unknown status, missing or stale binding, wrong path/profile, illegal payload, Capability mismatch, permission expansion, tool/command failure, or result-contract failure enters `invalid_result`.

A retry with unchanged authoritative bindings retains Task Execution Identity and failure count but receives a new Invocation Identity. Changed authoritative inputs require revalidation and may create a replacement semantic task only through the owning Capability and policy.

## Generic Control Actions

The Rule implements only the generic meanings declared by policy. It does not decide which Capability status selects them.

- **Questioning persistence:** create the post-answer Current Request Revision, append one complete immutable Questioning round, observe the write, then update the Current Questioning Pointer. Never edit prior rounds or infer the pointer from the last text block.
- **Path selection:** record only the policy-authorized simple/full path. A simple selection requires the declared assessment and `full_path_required = false` guard.
- **Sticky full path:** once set, preserve `full_path_required = true`, invalidate declared quick downstream, and never clear it within the lifecycle. On later reassessment, policy guards may suppress a simple route action while preserving the Capability's valid semantic result.
- **Grounding continuation:** return direct evidence to the lifecycle-bound requesting Capability. `partial` remains partial; unknown facts are never filled from Specification, documentation, knowledge, or inference.
- **Unified Plan persistence:** both paths write the same Plan location and semantic contract. Do not create `simple-plan`, `full-plan`, or persistent Specification authority.
- **Review records:** persist checked Plan projection and Review results separately. `review.md` is never an execution input, and Approval never writes back into Plan or Review.
- **Approval:** record only explicit overall user approval with all policy-required current bindings and pre-Impl baseline.
- **Verify:** keep Impl and independent Verification in distinct invocations that share the same Plan Task Execution Identity. Impl never supplies a Verification verdict; Verification cannot modify implementation.
- **Bounded repair:** preserve the current approved Plan only for an evidence-backed implementation defect within approved scope, then rerun affected Verification.
- **Human Acceptance:** record the user's observed delivery result only after current Verification passed; do not repeat technical Verification.
- **Summary completion:** complete only after current Verification passed and Human Acceptance accepted. Knowledge candidates remain optional and cannot block or reopen completion.
- **Dynamic continuation:** Grounding, Review Dialogue affected-owner returns, and Failure Learning main-route resumes require current lifecycle-bound closed continuation identities.
- **Mutating invocation:** bind lifecycle, Task Execution, Invocation, exclusive worktree, allowed paths, pre-Impl baseline, and expected write state. When concurrency is enabled, one mutating task owns one worktree; if exclusive ownership is unavailable, serialize a unique writer or stop fail closed.
- **Minimal write safety:** before each write revalidate path, bindings, baseline, and expected state; where applicable complete a same-directory temporary write before atomically replacing one target; record completion or incomplete state for critical multi-step writes; reread files, Git status/diff, and records before reporting completion.
- **Unblock:** remain at the current gate and request the specific missing permission, environment, record, evidence, or external prerequisite.

Persistence actions complete only after an observed recorder result. If no recorder exists, do not represent a proposed or narrated write as persisted state.

## Cross-Cutting Gates

These invariants apply independently of individual route rows:

- Questioning precedes path selection.
- A simple path requires a proved simple assessment and `full_path_required = false`.
- The full-path Specification handoff is temporary and non-authoritative.
- Both paths form one unified Plan and converge before Review.
- The selected Plan Check must pass before Review Projection.
- Review and explicit current Approval occur before Impl.
- Verify is ordered `Impl → independent Verification` with separate invocations.
- Human Acceptance requires current Verification `passed`.
- Summary requires current Verification `passed` and Human Acceptance `accepted`.
- Failure Learning and Summary can create governed candidates only; neither publishes knowledge automatically.
- Attribution is optional and never a core lifecycle gate.

## Approval and Drift

Review Approval binds the policy-declared Current Request, Questioning, design constraints, assessment, selected path/profile, sticky flag, Plan, Plan Check, Review projection/check, approver decision/time, and approved pre-Impl implementation baseline.

Before Verify, revalidate every binding. Any changed pre-Impl input or external baseline drift invalidates Approval. Expected implementation delta explicitly authorized by the approved Plan does not invalidate Approval by itself. Unauthorized workspace, dependency, configuration, Schema, or executable-behavior change is external drift: stop, record the observed difference when possible, and revalidate through policy.

A policy identity/digest change also stops execution and requires revalidation. Never route a lifecycle under a policy different from its observed binding.

## Failure Budget

Task Execution Identity binds lifecycle identity, task class, and authoritative input revisions/digests. Capability work uses its Capability identity as task class; Impl and Verification use the shared approved Plan task identity.

For every policy-declared counted failure:

1. observe and record the failure fact and attempt;
2. invoke Failure Learning as a non-blocking side path with the saved main-route continuation;
3. prevent Failure Learning from changing the route, failure count, verdict, Acceptance, or lifecycle result;
4. do not recurse if Failure Learning itself fails;
5. on attempts one or two, execute the effective policy route after the side path;
6. on attempt three, apply the policy's termination override instead of its normal next route.

Agent restart, model change, tool retry, session resume, or sticky full escalation does not reset the count. A failed Verification and Human Acceptance `implementation-defect` count against the same Plan task. Semantic rework, grounding, blocked states, and sticky upgrade are not counted unless the policy explicitly classifies a result as counted.

When the same Task Execution Identity, or an explicitly linked replacement task, later succeeds, Failure Learning may run again using the original failures, intervening actions, final result, and success evidence. Similar prose is not replacement linkage.

On the third counted failure, record attempt-limit-reached when possible, forbid further scheduling of that Task Execution Identity, invalidate unfinished downstream, and close affected execution paths. A required terminated task prevents successful Acceptance and Summary; it never receives a fourth attempt.

## Invalidation and Recorded-State Resume

Use only the invalidation declarations in policy and actual revision/digest/baseline/evidence comparisons. At minimum, changed Current Request, Questioning Pointer, governed constraints, Plan, Approval, implementation, Verification evidence, Acceptance, policy binding, or relevant external baseline must invalidate their declared dependents.

`full_path_required` is one-way sticky. It survives questioning re-entry, reassessment, revised requests, fact updates, restart, resume, and interruption within the same lifecycle. Quick Plan, quick Plan Check, Review, Approval, and unfinished downstream cannot survive an upgrade unless policy explicitly says otherwise.

After interruption, reread actual lifecycle records, the bound policy, artifacts, files, Git status/diff, evidence, and completion/incomplete markers. Resume only from the last observed current gate. Do not reconstruct completion from conversation memory, an Agent report, the temporary Specification handoff, unchecked Plan candidates, or partial files; do not automatically continue, roll back, repair partial writes, merge worktrees, or adjudicate conflicts.

## Workspace Boundary

When an actual recorder exists, Workspace stores minimal lifecycle governance state and references under lifecycle-scoped locations: `changes/<lifecycle-id>/`, `state/<lifecycle-id>/`, `runs/<lifecycle-id>/`, `evidence/<lifecycle-id>/`, and `outcomes/<lifecycle-id>/`. Records include current stage, Current Request, Questioning log/pointer, constraints, assessment/path/sticky flag, Task Execution identities and attempts, implementation baseline, Plan/Review/Approval, Impl/Verification/Acceptance/Summary evidence, invalidation, replacement, incomplete operations, last proven gate, and Failure Learning references.

Do not copy target, scope, design, contracts, or acceptance semantics into the Lifecycle Record. Multiple lifecycles may bind the same read-only policy identity/digest, but their Current Request, continuations, attempts, worktree identities, artifacts, evidence, Acceptance, Summary, incomplete operations, and sticky state never cross lifecycle identity.

## Safe Degradation

Before reading or writing an artifact, invoking a Capability, running a command, recording a digest, asserting a route, or applying invalidation, confirm that the responsible Capability, Profile, policy, validator, recorder, digest service, and runtime actually exist as required by that action.

If any required support is unavailable:

- identify exactly what is missing;
- remain at the current proven gate;
- use the Capability's legal blocked result only when the Capability itself returned it;
- report machine assurance as unavailable rather than simulated;
- do not hand-write machine-owned state and claim enforcement;
- do not claim route, persistence, digest, currentness, invalidation, attempt, termination, rollback, recorded-state resume, atomic replacement, completion, or worktree isolation without observed evidence.

A Rule, Capability, Profile, README, policy, protocol, template, directory, or example does not prove an evaluator, validator, recorder, digest service, or production invocation runtime is installed.

## Non-Bypass Rules

- Do not use Specification as implementation fact source or persistent authority.
- Do not parse free text to invent lifecycle state.
- Do not select a route outside `transitions.yaml` or bypass an applicable policy guard.
- Do not create a second Plan type.
- Do not enter Impl without current explicit Review Approval.
- Do not use `review.md` as execution authority.
- Do not combine Impl and Verification into one self-verdict invocation.
- Do not request Acceptance before Verification passed.
- Do not generate Summary before Acceptance accepted.
- Do not exceed the shared three-failure limit.
- Do not restore Shell runtime or Shell fallback.
- Do not introduce functional versions, upgrade, migration, persistent Agents, shared Agent memory, Agent-to-Agent delegation, voting, consensus, or multi-Agent orchestration.
- Do not claim cross-worktree locks, general transactions, rollback journals, automatic recovery, cross-worktree merge, or conflict adjudication.
