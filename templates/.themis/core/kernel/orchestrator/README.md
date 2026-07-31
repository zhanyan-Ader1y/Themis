# Orchestrator Package

## Responsibility

Orchestrator hosts the sole always-loaded Global Control Rule. It interprets one `transitions.yaml` across isolated `request-intake` and `lifecycle` scopes, coordinates one temporary Capability Invocation at a time, validates proposed results, executes policy-declared generic control actions, observes materialization, applies invalidation/failure control, and recovers from durable facts.

It does not own Capability reasoning, legal status tables, route mappings, user claims, implementation facts, artifact content, or recorder behavior.

## Owned assets

- `rules.md`：Intake-first generic policy interpreter, materialization/currentness boundary, lifecycle gates, scope-local failure control, recovery, and safe degradation.
- `../../policies/transitions.yaml`：sole route/control policy, fixed scope/Profile mappings, guards, invalidation, and invalid-result behavior.

## Execution model

```text
external user message
→ immutable Source Event under Request Intake
→ Global Control Rule
→ transitions.yaml selects one internal Capability + fixed Profile
→ one temporary Invocation in one authority scope
→ proposed Capability result
→ exactly one four-field route
→ policy control action
→ complete persistence + observation + reread + pointer update
→ decision-bound lifecycle continuation, if assignment exists
```

The route key is `capability + selected_path + profile + status`; authority scope is fixed by Capability contract and policy rather than added as a fifth dimension.

## Authority boundary

- Source Event owns original external bytes.
- User-confirmed source-bound claims own lifecycle target semantics.
- Code/configuration/Schema/observed behavior own current implementation facts.
- Capability owns one semantic judgment and returns a proposal.
- Agent Profile owns tools, permissions, and isolation.
- Policy owns control actions and route legality.
- Observed recorder result plus reread proves materialization.
- Workspace stores durable scope records, immutable revisions, evidence, and separate current pointers.

The Rule never directly judges complexity, refines requirements, designs/checks Plan, creates/checks Review, verifies implementation, classifies acceptance, or publishes knowledge.

## Scope isolation

`request-intake` and `lifecycle` may exchange immutable stable references only. They cannot share dynamic state, Execution Identity, failure budget, continuation authority, current pointer, or completion state.

All lifecycle user interactions—including Questioning answers, Review feedback/approval, Acceptance, and unblock/restart—first become Source Events and pass Current Request Dialogue. Durable active Intake-local confirmation/restart continuations are the only way to attach a Source Event to an existing Intake; a `dormant-read-only` Intake is never attachable.

## Materialization and recovery

Capability results are proposed outputs. Authority requires validation, exactly-one-route match, declared control action, complete persistence, completion/incomplete observation, reread of identity/content/digest/bindings, immutable revision observation, and separate pointer update.

Multi-target Intake decisions execute and record each target independently. Partial success remains `open + incomplete`, preserves completed targets, and recovery resumes only recorded remaining targets; no rollback or replay of completed targets is allowed. Explicit host-observed abandonment uses a policy control action rather than a Capability status and is never inferred from silence.

After a Summary pair is fully materialized and lifecycle completion is observed, policy records that completion against every immutable Intake target bound to the completed lifecycle identity and freezes each matching target binding read-only. Each affected Intake retains disposition `assigned` and becomes `dormant-read-only` only when every lifecycle target associated with that Intake is observed completed. Dormancy deactivates all Intake continuations, forbids attachment, Invocation, mutation, reactivation, and recovery, and preserves source/decision/observation records read-only; later messages create a new Intake. This is a post-completion control, not a Capability route or fifth disposition.

Recovery rereads scope state, pointers, markers, artifact components, Invocation/attempt records, and applicable Git facts, then resumes only from the `last proven gate`. It does not infer completion or automatically repair/rollback/merge. Dormant Intake records may verify historical source and decisions but are never a recovery source.

## Lifecycle invariants

- Confirmed assignment precedes lifecycle creation/update.
- Questioning consumes confirmed claims and precedes path selection.
- simple/full paths create one Plan family and converge before Review.
- Plan Check precedes Review; explicit current Approval precedes Impl.
- Verify is `Impl → independent Verification` with separate Invocations and one shared Plan task budget.
- Acceptance requires current Verification `passed`; Summary also requires current Acceptance `accepted`.
- `full_path_required` is lifecycle-local, sticky, and one-way.
- Failure Learning is scope-bound, non-blocking, non-recursive, and candidate-only.

## Failure boundary

Intake Execution Identity and lifecycle Plan Task Execution Identity each allow at most three counted failures. The third terminates only that identity and forbids a fourth Invocation. Intake failure never consumes lifecycle budget; Impl, Verification, and acceptance repair share one lifecycle Plan task budget.

## Current status

Plan 35 provides one public Skill, one Global Rule, one dual-scope policy, sixteen internal Capability contracts, four Profiles, immutable artifact templates, static verification, and manual replay semantics. It does not provide strict validation or runtime enforcement.

Plan 36 owns strict contracts/validation. Plan 37 owns evaluator, Invocation host, recorder, deterministic writes, and command execution. This package does not claim functional versions, upgrade/migration, Shell fallback, general transactions, automatic recovery, multi-Agent execution, or Attribution gates.
