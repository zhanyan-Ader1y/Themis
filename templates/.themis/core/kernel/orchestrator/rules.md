# Themis Global Control Rule

## Purpose

This Rule is the only always-loaded Themis control instruction. It generically interprets the sole `../../policies/transitions.yaml` policy across isolated `request-intake` and `lifecycle` authority scopes. It coordinates identity, bindings, temporary Invocation, proposed-result validation, policy action, observed materialization, invalidation, failure control, and recovery. It does not own any Capability's reasoning or copy the policy route table.

Load only:

- the current `../../policies/transitions.yaml`;
- one policy-selected `../../capabilities/*.md`;
- that Capability's fixed `../../agent-profiles/*.md`;
- the minimum durable Intake/lifecycle records and evidence required by the current gate.

Do not import sibling Rules. Do not use chat, summaries, temporary Agent reasoning, filesystem existence, or `recommended_route` as control state.

## Ownership Model

```text
Source Event      = immutable original external bytes and fragment references
Current Request   = user-confirmed source-bound lifecycle target claims
Capability        = one semantic judgment; proposed result only
Agent Profile     = tool, permission, and isolation boundary
Invocation        = temporary carrier for one Capability and one authority scope
transitions.yaml  = sole legal route/control policy
Global Rule       = generic policy interpreter and coordinator
recorder result   = observed persistence/materialization evidence
Workspace         = durable scope records, artifacts, evidence, and pointers
```

Only `.claude/skills/themis/SKILL.md` is public. Sixteen internal Capability contracts are not project Skills.

## Authority Scopes

### `request-intake`

Owns Source Event references, claim/assignment proposals, user confirmation decisions, Intake Execution Identity, Intake-local continuation, Intake pointers, disposition, and post-completion retention facts.

### `lifecycle`

Owns Current Request revisions, Questioning, path/Plan, Review/Approval, Plan Task Execution, Verification, Acceptance, Summary, lifecycle-local continuation, and lifecycle pointers.

The scopes may reference immutable identities across the boundary, but must not share dynamic state, Execution Identity, failure budget, continuation authority, current pointer, or completion state. An Intake failure never creates or consumes a lifecycle budget.

## Authority Classification

1. Original external input authority comes only from immutable Source Event bytes and exact fragment references.
2. Lifecycle target semantics come only from user-confirmed Current Request claim revisions.
3. Governed design constraints constrain solutions but do not rewrite user claims or prove implementation.
4. Code, configuration, Schema, and observed executable behavior are the only current implementation fact sources.
5. Temporary Specification handoff is full-path, non-persistent, and non-authoritative.
6. Current approved unified Plan is the execution contract.
7. Workspace records prove events only after complete persistence, observed completion, reread, and pointer update where required.

Specification, Plan prose, Review Projection, Summary, design documents, Themico, experience, external references, Agent analysis, and conversation memory cannot masquerade as user semantics or current implementation facts.

## Intake-First External Message Entry

Every external user message handled by Themis must pass these gates before any lifecycle semantic handling:

1. Record the exact original bytes as an immutable Source Event with event identity, actor/transport metadata, raw bytes path/digest/length, and `normalization: none`.
2. Choose Intake attachment only from durable control facts:
   - a matching active Intake-local confirmation continuation;
   - a matching active terminated-Intake restart/unblock continuation;
   - a `dormant-read-only` Intake is never attachable;
   - otherwise create a new Intake identity.
3. Do not choose attachment from wording, adjacency, an open Intake, chat history, or Agent inference.
4. Bind `request-intake`, the Intake Execution Identity, Source Event, policy, and exact continuation.
5. Invoke `themis-current-request-dialogue` with fixed `human-dialogue`, `selected_path: null`, and `profile: null`.
6. Validate and route its proposed result through policy.

Before a confirmed assignment decision is fully materialized and reread, do not create, locate, continue, split, merge, or update a lifecycle. There is no provisional lifecycle.

## Current Request Confirmation Protocol

When claim or assignment semantics change:

```text
Source Event
→ first Current Request Dialogue Invocation
→ needs-request-confirmation
→ materialize immutable Intake proposal
→ wait for a new confirmation Source Event
→ second Current Request Dialogue Invocation
→ assignment-confirmed
→ materialize immutable Intake decision and every declared target
→ create/update lifecycle Current Request revisions
→ resume decision-bound continuation
```

The first Invocation must preserve stable diff item identities, exact Source Event fragments, allowed dispositions, complete diff digest, proposed claim revisions, assignment operations, and confirmation continuation.

The second Invocation must bind that exact proposal/digest, a new confirmation Source Event, and an explicit `confirm | correct | keep-ambiguous` disposition for every required item. A whole-diff confirmation must bind the complete diff digest. Silence, omitted items, ambiguous approval, or a stale proposal cannot confirm.

When claims and assignment are unchanged, `assignment-confirmed + no-change` may resume the original durable lifecycle dialogue continuation after its Intake decision materializes; no redundant user confirmation is required.

Confirmed target operations are exactly `create-lifecycle | update-current-request | no-change`. Execute, observe, and record each target separately. Mark the Intake `assigned` only after every target is complete; partial success remains `open + incomplete`, preserves completed targets, and records `remaining_target_identities`. Recovery must reread every target observation and execute only `resume-remaining-target-operations-only`; automatic rollback or replay of completed targets is forbidden.

`rejected` requires an explicit rejection Source Event. `abandoned` requires an explicit host-observed session termination or leave event and the policy control action `record-intake-abandoned`; it is not a Capability status and must never be inferred from silence.

## Required Package and Preflight

At each gate, confirm that these readable contracts exist:

```text
.claude/skills/themis/SKILL.md
.themis/core/kernel/orchestrator/rules.md
.themis/core/policies/transitions.yaml
.themis/core/capabilities/<selected>.md
.themis/core/agent-profiles/<fixed>.md
minimum current durable records and bindings
```

Verify policy declares exactly sixteen unique internal Capability identities and four Profile contracts. Do not copy mappings or legal status sets into this Rule. If strict validation/evaluation support is unavailable, report the assurance gap and use only Prompt-level/manual semantics; never claim machine enforcement.

## Generic Invocation Sequence

For every Intake or lifecycle step:

1. Reread scope state, current pointers, policy binding, markers, applicable artifact components, Invocation/attempt records, and exact durable continuation.
2. Determine the `last proven gate`; do not infer progress from chat or partial files.
3. Validate the current policy identity/digest and all required source/artifact/baseline bindings.
4. Select exactly one Capability from current policy control state and read its fixed authority scope and Agent Profile.
5. Create one Invocation binding:
   - one authority scope and scope identity;
   - one scope-local Execution Identity;
   - one Invocation identity and attempt identity;
   - one Capability and fixed Agent Profile;
   - policy identity/digest;
   - selected path/profile;
   - current Source Event/artifact/evidence bindings;
   - exact durable continuation;
   - allowed reads/writes/commands;
   - expected materialization target and remaining failure budget.
6. Record the attempt before started execution when an actual recorder exists.
7. Run one temporary Agent Invocation. Nested Capability or Agent calls are forbidden.
8. Validate the single returned proposed result: capability, authority scope, Agent Profile, status, path/profile, identities, current bindings, payload, evidence, permissions, continuation, and materialization target.
9. Reject stale, duplicate, late, wrong-scope, wrong-profile, incomplete, permission-expanding, or competing terminal results.
10. Match exactly one route using `capability + selected_path + profile + status`; then apply current policy guards.
11. Zero or multiple matches enter policy `invalid_result`; never infer a route from prose or `recommended_route`.
12. Execute only the declared control action, observe materialization, apply declared invalidation, and move to `next` only after the action is proven complete.
13. Discard temporary context. Retain only observed records, artifacts, evidence, bindings, and references.

A retry with unchanged authoritative inputs preserves the scope-local Execution Identity and failure count but receives a new Invocation/attempt identity. Changed authoritative inputs require invalidation and semantic-owner re-entry; they do not silently reset an identity.

## Proposed Result and Materialization Boundary

A Capability result, Markdown draft, structured payload, successful file write, or Agent statement is never authority by itself. Materialization requires this exact order:

1. validate result identity, scope, Profile, status, bindings, and payload;
2. match exactly one policy route;
3. execute the declared control action;
4. persist every required machine/Markdown/operational component;
5. record completion or incomplete observation;
6. reread record and content;
7. verify identity, authority scope, digest, bindings, and target path;
8. create the immutable revision observation;
9. update the separate current pointer.

For paired semantic artifacts, missing either machine record or Markdown, or any identity/digest/scope/binding mismatch, invalidates the entire pair. If pointer update fails, a valid immutable revision may exist but is not current. Never edit an immutable revision in place or use a symlink as authority.

Temporary Specification handoff is the only semantic handoff without a persistent current pointer. It remains non-authoritative and must be regenerated from current bindings after interruption.

If recorder, digest, validator, evaluator, or write support required by an action is unavailable, remain at the last proven gate and report unavailable. Do not hand-write machine-owned state and claim success.

## Lifecycle Continuation After Assignment

Only a fully materialized assignment decision can create/update lifecycle Current Request revisions. Each revision is an immutable set of confirmed claim revisions with exact Source Event fragments and `active | ambiguous | superseded` disposition.

The lifecycle then follows policy:

```text
Current Request claims
→ themis-q
→ optional Grounding
→ Complexity Assessment
   ├─ simple → Simple Plan → lightweight Plan Check
   └─ full   → temporary Specification → Planning → full Plan Check
→ Review Projection → Review Check → Review Dialogue → Review Approval
→ themis-impl → independent themis-verification
→ Human Acceptance → Summary → completed
```

Questioning consumes confirmed claims. An unanswered question is durable proposal/continuation state, not a completed round. A completed exchange materializes one immutable paired Questioning round and then updates its separate pointer.

Both paths create the same paired Plan family and converge before Review. Do not create `simple-plan`, `full-plan`, or persistent Specification authority.

## Review and Approval

- Plan Check must be current `pass` before Review Projection.
- Review Projection is a checked-Plan projection, never an execution contract.
- Review Check only evaluates projection fidelity and burden.
- Every Review user message first passes Intake interception, then returns through the durable Review continuation.
- Review Dialogue can propose Feedback or Approval; it cannot write either, patch Plan/Projection, or execute owner routes.
- Feedback materializes as an independent immutable revision and returns to one of exactly seven semantic owners: Current Request Dialogue, `themis-q`, Specification, Simple Planning, Planning, Plan Check, or Review Projection.
- Claim/assignment feedback returns through Intake interception to Current Request Dialogue; Why/abstract-What feedback returns to `themis-q`. Grounding may collect evidence for the bound owner but is not itself a Review Feedback owner.
- Approval requires explicit overall user decision, empty unresolved feedback, current bindings, the exact projection shown, and pre-Impl baseline.
- Any changed bound input invalidates old Approval.

## Verify, Acceptance, and Summary

Verify is always:

```text
themis-impl
→ independent themis-verification
```

Impl and Verification use separate Invocations, share one approved Plan Task Execution Identity/failure budget, and bind the same Approval, Plan task, baseline, and expected delta. The writer cannot self-verify; Review Markdown is not execution input.

An expected delta authorized by the current Plan does not invalidate Approval. Unauthorized workspace, dependency, configuration, Schema, or behavior change is external drift: stop and revalidate without blaming the otherwise completed Invocation.

Human Acceptance requires current Verification `passed`. Its user message passes Intake interception and returns through the acceptance continuation. Acceptance stores source-bound user observation; silence is not acceptance.

Summary requires current Verification `passed` and current Human Acceptance `accepted`. It is a bound delivery projection only. Optional knowledge candidates do not publish automatically and cannot block or reopen completed delivery.

## Lifecycle Completion and Intake Dormancy

The `materialize-summary-pair-and-complete-lifecycle` action must first fully materialize and reread the Summary pair, then record an observed lifecycle completion fact. Summary prose does not create completion by itself.

After lifecycle completion is observed:

1. Resolve every immutable assignment decision and target identity that explicitly binds the completed lifecycle identity to an Intake.
2. For each matching Intake target, record the lifecycle completion observation and freeze only that completed target binding as read-only.
3. Preserve each Intake disposition as `assigned`; `dormant-read-only` is a derived retention mode, not a Capability status, route-key dimension, or fifth disposition.
4. For each affected Intake, if any other lifecycle-bearing target from the same assignment remains incomplete, keep its retention mode `active` and do not affect that target's continuation or execution.
5. Only after every associated lifecycle target for an affected Intake is observed completed, record that Intake's retention mode as `dormant-read-only` and deactivate every Intake-local continuation.
6. Retain Source Events, proposals, confirmations, assignment decisions, target observations, completion observations, and historical bindings as immutable read-only authority. Only rebuildable cache may be removed.

A `dormant-read-only` Intake cannot accept a future Source Event, schedule an Invocation, recover, reactivate, or mutate. A later external message always creates a new Intake, even when it concerns a lifecycle formerly associated with the dormant Intake. Historical dormant records remain valid for source and decision verification only.

This is a policy post-completion control using stable immutable cross-scope references. It adds no Capability route. Without an observed recorder/runtime operation, remain at the last proven completion gate and report the retention transition as unavailable rather than hand-writing machine-owned state.

## Sticky Full Escalation and Invalidation

`full_path_required` is lifecycle-local and one-way `false → true`. It survives Questioning re-entry, reassessment, restart, resume, retries, and implementation/verification attempts. It never resets a failure budget.

The `simple-qualified` route is guarded by `full_path_required == false`. When the flag is already true, the same assessment result must use the policy guard-failure action `materialize-assessment-preserve-sticky-full-and-select-full` and continue to `themis-spec`; it must not invoke Simple Planning or clear the flag.

Any legal quick-path complexity signal applies the policy's sticky-full action, invalidates all declared quick downstream including Approval, and restarts full-path Specification/Planning/Review. A later `simple-qualified` result cannot clear or bypass the sticky flag.

Apply only policy-declared invalidation using actual revision/digest/baseline/evidence comparisons. Do not preserve downstream currentness because prose appears equivalent.

## Scope-Local Failure Control

Request Intake and lifecycle each have an independent maximum of three counted failures.

Counted failures include started Agent/tool/command failure, missing/invalid/wrong-profile/wrong-scope/stale result, result-contract failure, declared execution failure, recorder/materialization failure, and evidence-backed `implementation-defect`.

Waiting, `needs-*`, `blocked`, `partial`, `full-required`, `escalate-full`, and external-drift stop/revalidate are non-counted controls unless policy explicitly says otherwise.

For each counted failure:

1. record attempt and observed failure;
2. dispatch scope-bound non-blocking Failure Learning with the exact saved main-route continuation;
3. do not let Failure Learning change route, budget, verdict, Acceptance, or completion;
4. do not recurse if Failure Learning fails;
5. on failure one or two, preserve the policy continuation;
6. on failure three, terminate that Execution Identity and forbid a fourth Invocation.

Agent restart, model change, tool retry, session resume, or simple-to-full escalation does not reset count. Impl, Verification, and acceptance `implementation-defect` share one lifecycle Plan task budget.

After the same Execution Identity or an explicitly linked replacement later succeeds, dispatch Failure Learning again with success evidence. Prose similarity cannot establish replacement linkage.

An Intake third failure leaves its Intake disposition `open` but terminated; only an explicit durable restart/unblock continuation can attach a future Source Event. A terminated required lifecycle Plan task prevents successful Acceptance and Summary.

## Recovery from Durable Facts

After interruption, reread:

```text
scope state
+ current pointers
+ completion/incomplete markers
+ every required artifact component
+ Invocation/attempt records
+ applicable Git facts
→ last proven gate
```

Resume only from that gate. For incomplete multi-target Intake materialization, reread each target observation, preserve completed targets, and resume only `remaining_target_identities`. Never recover from chat, Agent reports, summaries, temporary Specification, or inferred completion. Do not automatically repair, roll back, merge, resolve conflicts, mutate pointers, replay completed target writes, or continue any partial write whose exact declared recovery action is absent.

## Safe Degradation

Plan 35 supplies Prompt-level policy, contracts, templates, static checks, and manual replay only.

- Plan 36 owns strict Schema, canonical serialization, validator, issue taxonomy, semantic oracle, and fixtures.
- Plan 37 owns evaluator, Invocation host, recorder, digest/write services, and command execution.

Without observed support, do not claim machine-enforced Source Event recording, route match, persistence, digest, currentness, invalidation, attempt, termination, recovery, atomicity, or completion. A Rule, YAML, template, directory, or prose record is not runtime evidence.

## Non-Bypass Rules

- Do not handle a lifecycle user message before Source Event and Intake interception.
- Do not create or continue a lifecycle before confirmed assignment materializes.
- Do not treat Agent summaries or normalized text as original Source Event authority.
- Do not invoke more than one Capability/Agent per Invocation.
- Do not select a route outside current policy or parse free text as hidden state.
- Do not treat a Capability result or file existence as materialized authority.
- Do not use Specification as implementation fact source or persistent authority.
- Do not create a second Plan family.
- Do not enter Impl without current explicit Review Approval.
- Do not combine Impl and Verification or allow writer self-verdict.
- Do not request Acceptance before Verification passed.
- Do not generate Summary before Acceptance accepted.
- Do not share Intake/lifecycle state, continuation, pointers, completion, or failure budgets.
- Do not schedule a fourth Invocation after three counted failures.
- Do not restore functional versions, compatibility, upgrade, migration, Shell fallback, multi-Agent orchestration, or Attribution gates.
