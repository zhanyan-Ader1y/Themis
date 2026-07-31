# Plan 35 Manual Replay Evidence

> Date: 2026-07-31
> Scope: replacement Plan 35 Prompt/template/policy/Workspace contracts
> Result: PASS — sixteen dormancy-aware scenarios have declared fail-closed Prompt-level outcomes; runtime execution is not claimed

## 1. Assurance boundary

This is a manual policy replay against the current `transitions.yaml`, Global Rule, Capability/Profile contracts, immutable templates, and Workspace model. It demonstrates that the declared contracts select one legal route and fail closed for the scenarios below. It does not claim that Plan 36 validation or Plan 37 evaluation, recording, writing, command execution, atomicity, or recovery ran.

For every scenario, `materialized` means the record/revision that the declared control action must produce after complete persistence, completion observation, reread, and pointer update. No such runtime operation is claimed to have executed in this checkout.

## 2. Replay ledger

### Scenario 1 — New Intake, confirmation, and lifecycle creation

- **Initial durable facts:** no matching Intake-local continuation; a new external message exists only as transport input.
- **Selected Capability / Profile / scope:** record Source Event, then `themis-current-request-dialogue` / `human-dialogue` / `request-intake`.
- **Proposed status:** first `needs-request-confirmation`; after a new confirmation Source Event, `assignment-confirmed` with `create-lifecycle`.
- **Matched route:** both exact `null/null` Current Request Dialogue routes.
- **Control action:** `persist-intake-proposal-and-await-confirmation`; then `materialize-confirmed-assignment`.
- **Materialized records/revisions:** immutable Source Events, Intake proposal, Intake decision, target operation observation, paired Current Request revision.
- **Current pointer/gate:** Intake becomes `assigned` only after the target completes; lifecycle Current Request pointer becomes current, then the decision-bound continuation selects `themis-q`.
- **Invalidation:** prior Intake decision is invalidated before the new decision becomes current; no provisional lifecycle exists.
- **Failure class:** waiting for confirmation is non-counted; successful assignment is `none`.
- **Missing machine guarantees:** byte recording, digest validation, exact route evaluation, target creation, reread, and pointer update remain Plan 36/37 assurances.
- **Replay result:** PASS.

### Scenario 2 — Active no-change continuation resumes; dormant Intake does not

- **Initial durable facts:** variant A has an active lifecycle dialogue continuation, confirmed assignment, current claims, and a new Source Event whose semantics and assignment are unchanged. Variant B has the same historical bindings, but the former Intake is `assigned + dormant-read-only` and every Intake continuation is inactive.
- **Selected Capability / Profile / scope:** variant A invokes `themis-current-request-dialogue` / `human-dialogue` / `request-intake` through the active continuation. Variant B records the message under a new Intake before any Current Request Dialogue Invocation.
- **Proposed status:** variant A returns `assignment-confirmed` with structured `no-change`. Variant B has no legal attachment to the dormant Intake.
- **Matched route:** variant A uses Current Request Dialogue `assignment-confirmed`, `null/null`; variant B uses `external_message_interception.attachment_decision_sources.otherwise: create-new-intake` and never reuses the dormant continuation.
- **Control action:** variant A executes `materialize-confirmed-assignment` and resumes the original durable dialogue continuation. Variant B creates a new Intake and starts its own Intake-first flow.
- **Materialized records/revisions:** variant A creates an immutable Source Event and Intake decision containing a `no-change` target and decision-bound continuation; no new claim revision is invented. Variant B creates a new Source Event/Intake identity while preserving all dormant records read-only.
- **Current pointer/gate:** variant A preserves the original lifecycle gate. Variant B leaves the dormant Intake unchanged and cannot recover or reactivate it.
- **Invalidation:** none beyond replacement of any stale active Intake decision proposal; dormant history is not invalidated or rewritten.
- **Failure class:** `none`; no redundant human confirmation wait and no failure for refusing dormant attachment.
- **Missing machine guarantees:** unchanged-claim comparison, attachment enforcement, continuation dispatch, and new-Intake creation are not machine-enforced until Plans 36/37.
- **Replay result:** PASS.

### Scenario 3 — One Intake targets multiple lifecycles and sleeps only after all complete

- **Initial durable facts:** one changed-only proposal explicitly lists multiple stable target identities and any shared Source Event fragments.
- **Selected Capability / Profile / scope:** two Current Request Dialogue Invocations in `request-intake` using `human-dialogue`; later lifecycle completion retention is policy control with no new Capability Invocation.
- **Proposed status:** `needs-request-confirmation`, then `assignment-confirmed` with per-target `create-lifecycle | update-current-request | no-change` operations. Lifecycle completion itself is an observed control fact, not a Capability status.
- **Matched route:** Current Request Dialogue confirmation routes; each lifecycle later reaches its existing Summary `ready → completed` route without adding a route key.
- **Control action:** persist the proposal, then execute/observe/record each confirmed target separately. On lifecycle A completion, freeze every Intake target bound to A; keep this Intake `active` while lifecycle B remains incomplete. On B completion, freeze B, preserve disposition `assigned`, set retention mode `dormant-read-only`, and deactivate all Intake continuations.
- **Materialized records/revisions:** one immutable assignment decision, independent target observations and decision-bound continuations, per-lifecycle Current Request/Summary/completion observations, and an Intake retention fact under Intake state. The immutable assignment decision is not rewritten.
- **Current pointer/gate:** assignment becomes `assigned` only when all target materialization completes; lifecycles advance independently. The Intake becomes dormant only when every lifecycle-bearing target is observed completed.
- **Invalidation:** target-local Current Request/downstream invalidation only where that target changed. Completing A neither rolls back nor blocks B.
- **Failure class:** completed operations are `none`; waiting and retention gating are non-counted controls.
- **Missing machine guarantees:** exact fragment-sharing validation, per-target execution, completion discovery, retention writes, and continuation deactivation are declarative only.
- **Replay result:** PASS.

### Scenario 4 — Partial multi-target materialization and recovery

- **Initial durable facts:** an immutable decision with target A `completed`, target B `incomplete`, Intake `open + incomplete`, and `remaining_target_identities: [B]`.
- **Selected Capability / Profile / scope:** no new semantic Capability; the request-intake recovery control rereads target observations.
- **Proposed status:** none; this is a declared policy recovery action, not a Capability result.
- **Matched route:** prior `assignment-confirmed` route plus `external_message_interception.multi_target_materialization.recovery_action`.
- **Control action:** `reread-target-status-and-resume-remaining-target-operations-only`.
- **Materialized records/revisions:** preserve target A and its observations; retry/complete only target B with a new operation observation.
- **Current pointer/gate:** remain at assignment materialization until B completes; then mark the Intake `assigned` and dispatch decision-bound continuations.
- **Invalidation:** no rollback, replay, or invalidation of target A solely because B was incomplete.
- **Failure class:** the original recorder/materialization failure is counted; recovery does not reset the Intake Execution Identity budget.
- **Missing machine guarantees:** native partial-write detection and exact resume execution belong to Plan 37.
- **Replay result:** PASS.

### Scenario 5 — Questioning answer changes a claim

- **Initial durable facts:** current lifecycle waits on a Questioning continuation; the answer arrives as a new Source Event and changes one confirmed claim.
- **Selected Capability / Profile / scope:** Current Request Dialogue in `request-intake`, followed after confirmation/materialization by `themis-q` / `human-dialogue` / `lifecycle`.
- **Proposed status:** `needs-request-confirmation` with a changed-only claim diff; after explicit item disposition, `assignment-confirmed` with `update-current-request`; then Questioning returns its legal status.
- **Matched route:** Current Request Dialogue confirmation routes, followed by the exact Questioning route.
- **Control action:** persist proposal, materialize decision and a new paired Current Request revision, invalidate dependent lifecycle state, then resume the original Questioning continuation.
- **Materialized records/revisions:** two Source Events, proposal/decision, immutable Current Request revision, and later a per-round Questioning pair when converged.
- **Current pointer/gate:** Current Request pointer updates before Questioning resumes; an unanswered question remains proposal state rather than a completed round.
- **Invalidation:** `[questioning, complexity-assessment, plan, unfinished-downstream]` for changed Current Request semantics.
- **Failure class:** confirmation wait and `needs-questioning` are non-counted.
- **Missing machine guarantees:** semantic diff validation and dependency invalidation are not runtime-enforced yet.
- **Replay result:** PASS.

### Scenario 6 — Review and Acceptance messages pass Intake first

- **Initial durable facts:** lifecycle waits at Review or Acceptance with an exact durable continuation.
- **Selected Capability / Profile / scope:** every new message first records a Source Event and invokes Current Request Dialogue in `request-intake`; only a materialized no-change/changed decision restores `themis-review-dialogue` or `themis-acceptance-dialogue` in `lifecycle`.
- **Proposed status:** normally `assignment-confirmed + no-change`; changed semantics use the two-Invocation confirmation protocol.
- **Matched route:** Current Request Dialogue route, then the continuation-selected lifecycle route.
- **Control action:** materialize the Intake decision before lifecycle semantic handling.
- **Materialized records/revisions:** Source Event and Intake decision; Review Feedback/Approval or Human Acceptance only after lifecycle continuation resumes.
- **Current pointer/gate:** Review/Acceptance gate is preserved until Intake materialization proves the message binding.
- **Invalidation:** changed claims invalidate the dependent gate; unchanged claims do not.
- **Failure class:** human waits are non-counted.
- **Missing machine guarantees:** interception and continuation binding are Prompt-level until Plan 37.
- **Replay result:** PASS.

### Scenario 7 — Review feedback returns to the correct owner

- **Initial durable facts:** current checked Plan, passed Review Check, shown Review Projection, and a Review Source Event.
- **Selected Capability / Profile / scope:** `themis-review-dialogue` / `human-dialogue` / `lifecycle` after Intake interception.
- **Proposed status:** one of `needs-current-request`, `needs-questioning`, `needs-simple-planning`, `needs-planning`, `needs-specification`, `needs-grounding`, or projection rework through the approved owner vocabulary.
- **Matched route:** exact simple/lightweight or full/full Review Dialogue route. Claim feedback goes to Current Request Dialogue; Why/abstract-What feedback goes to `themis-q`; Grounding gathers evidence for a bound owner but is not an owner.
- **Control action:** materialize an immutable paired Review Feedback revision, apply route invalidation, and return to the owner.
- **Materialized records/revisions:** Review Feedback pair, new owner result, new Plan or Projection revision as required, and a new check result.
- **Current pointer/gate:** old Approval becomes stale; Review can resume only from the new checked Plan/projection.
- **Invalidation:** exact route sets include Plan/Plan Check/Projection/Review Check/Feedback/Approval/unfinished downstream as appropriate.
- **Failure class:** semantic rework is non-counted.
- **Missing machine guarantees:** owner enum validation, route match, and stale-pointer enforcement await Plans 36/37.
- **Replay result:** PASS.

### Scenario 8 — Sticky simple-to-full escalation

- **Initial durable facts:** a simple lifecycle later receives a legal complexity signal, setting `full_path_required = true`.
- **Selected Capability / Profile / scope:** the signaling lifecycle Capability and later Complexity Assessment; Profiles remain fixed by policy.
- **Proposed status:** quick-path `escalate-full`/equivalent rework, then possibly a later `simple-qualified` reassessment.
- **Matched route:** quick escalation sets sticky full; later `simple-qualified` matches its route but fails guard `full-path-not-required`.
- **Control action:** set/preserve sticky full, invalidate quick downstream, and use `materialize-assessment-preserve-sticky-full-and-select-full` with next `themis-spec`.
- **Materialized records/revisions:** assessment/result records, sticky lifecycle control fact, invalidation records, then full-path Plan family revisions.
- **Current pointer/gate:** full path remains required across retry, restart, resume, Questioning re-entry, and reassessment.
- **Invalidation:** `[quick-plan, plan-check, review-projection, review-check, review-feedback, review-approval, unfinished-downstream]`.
- **Failure class:** escalation and guard-failure reroute are non-counted; budget is not cleared.
- **Missing machine guarantees:** guard evaluation and sticky state persistence remain unavailable runtime functions.
- **Replay result:** PASS.

### Scenario 9 — Paired artifact and pointer failures

- **Initial durable facts:** a proposed paired Plan/Review/etc. revision reaches materialization.
- **Selected Capability / Profile / scope:** any paired-artifact producer in its fixed lifecycle Profile.
- **Proposed status:** a legal result such as `ready`, `approved`, `implemented`, `passed`, `accepted`, or `candidate-ready`.
- **Matched route:** the exact producer route; failure occurs during declared materialization rather than semantic routing.
- **Control action:** persist both components, observe completion, reread identity/digest/bindings, create revision observation, then update the pointer.
- **Materialized records/revisions:** if one half is missing or mismatched, the whole revision is invalid; if pointer update alone fails, a valid immutable revision may exist but is not current.
- **Current pointer/gate:** remains at the last proven gate; downstream does not advance.
- **Invalidation:** dependent currentness is not established; existing current pointer remains authoritative until explicitly changed.
- **Failure class:** recorder/materialization failure is counted.
- **Missing machine guarantees:** atomic writes, digests, reread, and pointer CAS-like behavior belong to Plan 37/36.
- **Replay result:** PASS.

### Scenario 10 — Invalid, stale, duplicate, late, wrong-Profile, or wrong-scope result

- **Initial durable facts:** one active Invocation binds scope, Execution/Invocation/attempt identity, Capability/Profile, path/profile, policy digest, inputs, and continuation.
- **Selected Capability / Profile / scope:** whichever Invocation is current; no competing result has authority.
- **Proposed status:** unknown, stale, duplicate, late, incomplete, wrong-Profile, wrong-scope, or otherwise binding-invalid.
- **Matched route:** zero legal route; policy `invalid_result` applies.
- **Control action:** `fail-closed-and-apply-scope-failure-control`.
- **Materialized records/revisions:** attempt and observed failure only; no proposed semantic artifact becomes current.
- **Current pointer/gate:** unchanged at the last proven gate.
- **Invalidation:** no new authority; any partial candidate is invalid.
- **Failure class:** counted.
- **Missing machine guarantees:** strict result validation and duplicate/late detection are Plan 36/37 work.
- **Replay result:** PASS.

### Scenario 11 — Intake failures do not consume lifecycle budget

- **Initial durable facts:** an Intake Execution Identity has one counted failure; an existing lifecycle Plan Task Execution Identity has its own count.
- **Selected Capability / Profile / scope:** failing Current Request Dialogue in `request-intake`; lifecycle task remains isolated.
- **Proposed status:** invalid/failed result entering Intake failure control.
- **Matched route:** `invalid_result` in request-intake scope.
- **Control action:** record attempt/failure, dispatch Intake-scoped Failure Learning, preserve exact continuation or terminate on the third Intake failure.
- **Materialized records/revisions:** Intake attempt/failure and optional Intake knowledge candidate only.
- **Current pointer/gate:** lifecycle budget/count and lifecycle gate are unchanged.
- **Invalidation:** no lifecycle failure-budget mutation.
- **Failure class:** counted only against Intake Execution Identity.
- **Missing machine guarantees:** scope-local counters and fourth-Invocation prevention require Plan 37.
- **Replay result:** PASS.

### Scenario 12 — Impl and Verification share one three-failure budget

- **Initial durable facts:** current Approval and one lifecycle Plan Task Execution Identity bind Impl and Verification.
- **Selected Capability / Profile / scope:** `themis-impl` / `implementation-writer`, then `themis-verification` / `independent-checker`, both in lifecycle but separate Invocations.
- **Proposed status:** counted started failures and/or evidence-backed Verification `failed` across the two Capabilities.
- **Matched route:** relevant Impl failure control or Verification `failed → themis-impl` route.
- **Control action:** record each attempt; preserve bounded repair continuation after failures one/two; on the third record termination, forbid a fourth Invocation, and invalidate unfinished task downstream.
- **Materialized records/revisions:** separate attempts, Impl Results, Verification results/evidence, shared task identity, and termination record.
- **Current pointer/gate:** no accepted Verification after termination; Acceptance and Summary remain blocked.
- **Invalidation:** affected verification evidence, Human Acceptance, Summary, and unfinished downstream.
- **Failure class:** counted against the shared lifecycle Plan task budget.
- **Missing machine guarantees:** native command execution, counters, and termination enforcement await Plan 37.
- **Replay result:** PASS.

### Scenario 13 — Failure Learning after failure and linked success

- **Initial durable facts:** a counted failure record and exact scope-local main-route continuation; later, the same or explicitly linked replacement identity has success evidence.
- **Selected Capability / Profile / scope:** `themis-failure-learning` / `semantic-readonly` / exactly one of `request-intake | lifecycle`.
- **Proposed status:** `candidate-ready | not-reusable | needs-more-evidence | blocked` after failure and again after explicit linked success.
- **Matched route:** exact scope/path/profile Failure Learning route; all return to `resume-scope-main-route`.
- **Control action:** materialize candidate/disposition, retain proposal, or record unavailable without changing the main route.
- **Materialized records/revisions:** optional paired Failure Learning candidate in the matching scope.
- **Current pointer/gate:** main route and failure budget remain unchanged by learning; original continuation resumes.
- **Invalidation:** none.
- **Failure class:** Failure Learning result is none/non-counted; its own failure does not recurse.
- **Missing machine guarantees:** explicit identity-link validation and dispatch are not machine-enforced yet.
- **Replay result:** PASS.

### Scenario 14 — Verification, Acceptance, Summary, completion, and retention gates

- **Initial durable facts:** test four states: Verification absent/failed; Verification passed but Acceptance absent/non-accepted; both current `passed + accepted`; and a fully materialized/reread Summary with observed lifecycle completion plus one or more explicitly bound Intake targets.
- **Selected Capability / Profile / scope:** Summary is not invocable in the first two states; in the third, `themis-summary` / `semantic-readonly` / lifecycle. The fourth state runs policy post-completion retention control without invoking another Capability.
- **Proposed status:** only the valid third state may return Summary `ready`; Intake dormancy has no Capability status.
- **Matched route:** existing `themis-summary` ready route after both policy gates. After its action is fully observed, `lifecycle_completion_retention` runs as a route-preserving post-control. Attempts to bypass a gate have no legal invocation and fail closed.
- **Control action:** `materialize-summary-pair-and-complete-lifecycle`; then resolve every assigned Intake target bound to the completed lifecycle identity, record completion, freeze those targets, and mark an affected Intake dormant only if all of its lifecycle targets are completed.
- **Materialized records/revisions:** separate immutable Verification, Human Acceptance, and Summary pairs with independent pointers; lifecycle completion observation; per-Intake target completion/retention facts. Source Events and assignment decisions remain unchanged.
- **Current pointer/gate:** lifecycle completes only after Summary materialization and completion observation; knowledge candidate failure cannot reopen it. Intake disposition remains `assigned`; retention mode changes to `dormant-read-only` only at its all-target gate.
- **Invalidation:** implementation or evidence change before completion invalidates affected Verification evidence, Acceptance, and Summary. Post-completion dormant history is not silently rewritten or reactivated.
- **Failure class:** waiting for human acceptance and waiting for other associated lifecycle targets are non-counted.
- **Missing machine guarantees:** gate evaluation, currentness checks, completion observation, cross-reference lookup, retention persistence, and continuation deactivation await Plans 36/37.
- **Replay result:** PASS.

### Scenario 15 — Active interruption resumes from the last proven gate; dormant Intake is excluded

- **Initial durable facts:** variant A has active scope state, current pointers, completion/incomplete markers, artifact components, Invocation/attempt records, and applicable Git facts that disagree with an Agent/chat claim of completion. Variant B has an `assigned + dormant-read-only` Intake with inactive continuations and retained historical records.
- **Selected Capability / Profile / scope:** variant A selects none until recovery determines the exact continuation from active durable facts. Variant B selects no recovery Capability or Invocation.
- **Proposed status:** none; recovery and dormant exclusion are policy/Rule controls, not semantic Capability output.
- **Matched route:** variant A resumes the last fully proven gate; incomplete multi-target Intake uses its explicit remaining-target action. Variant B has no recovery route and cannot reactivate a historical continuation.
- **Control action:** reread active durable evidence, reject inferred completion, and invoke only the Capability bound by the recovered active continuation. For variant B, preserve records read-only and perform no execution.
- **Materialized records/revisions:** no automatic repair, rollback, merge, pointer mutation, inferred success, or dormant-state mutation.
- **Current pointer/gate:** active last observed valid pointer/gate wins over chat, summaries, temporary Specification, or Agent reasoning. Dormant records may verify historical source/decisions but never provide a current gate.
- **Invalidation:** stale/partial active candidates remain non-current; dormant history remains immutable.
- **Failure class:** a prior materialization failure retains its recorded class; recovery does not reset budgets. Dormant exclusion is non-counted.
- **Missing machine guarantees:** native durable recovery execution and dormant recovery prohibition belong to Plan 37.
- **Replay result:** PASS.

### Scenario 16 — Rejection, abandonment, silence, and post-dormancy input

- **Initial durable facts:** compare an explicit user rejection Source Event, an explicit host-observed termination/leave event, mere silence, and a new external message after a former Intake became `assigned + dormant-read-only`.
- **Selected Capability / Profile / scope:** rejection uses Current Request Dialogue / `human-dialogue` / request-intake; abandonment uses no Capability status and only host policy control; silence selects neither. Post-dormancy input starts a new Intake and then uses Current Request Dialogue there.
- **Proposed status:** rejection returns `rejected`; abandonment and silence have no Capability result; the dormant Intake has no legal attachment or reactivation result.
- **Matched route:** rejection uses `persist-intake-rejection → intake-closed`; abandonment uses `host_observed_abandonment.control_action: record-intake-abandoned`; post-dormancy input uses `otherwise: create-new-intake`.
- **Control action:** persist explicit rejection or host-observed abandonment only; for post-dormancy input, record a new Source Event under a new Intake and leave the old Intake unchanged.
- **Materialized records/revisions:** immutable rejection decision or host event/disposition record; silence creates neither. The new request gets a new Intake identity while dormant Source Events, decisions, observations, and historical bindings remain read-only.
- **Current pointer/gate:** rejected/abandoned Intake closes according to its explicit event; a silent open Intake remains open; a dormant Intake remains non-attachable and supplies no continuation.
- **Invalidation:** no lifecycle assignment is created from rejection or abandonment; a new Intake does not rewrite dormant history.
- **Failure class:** neither is a counted execution failure; a third counted Intake failure instead leaves disposition `open` with terminated Execution Identity. Dormant attachment refusal is non-counted.
- **Missing machine guarantees:** host event ingestion, disposition recording, dormant attachment enforcement, and new-Intake recording await Plan 37.
- **Replay result:** PASS.

## 3. Replay conclusion

All sixteen scenarios have one declared fail-closed Prompt-level outcome and preserve the replacement design's authority boundaries. The earlier replay repaired five closure gaps: Intake target vocabulary, partial-target recovery, Review owner routing, sticky-full route guarding, and host-observed abandonment control. The updated replay additionally closes the approved post-completion Intake contract: per-target freezing, all-target dormancy, inactive continuations, recovery exclusion, read-only retention, and new-Intake handling.

The replay is evidence for acceptance criterion 31 together with the now-passing dormancy-aware structural assertions. It is not runtime proof. Explicit user re-acceptance remains a separate final gate.
