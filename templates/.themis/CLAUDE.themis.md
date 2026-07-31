# Themis Project Guidance

This managed guidance defines the installed project's control boundary. `.claude/skills/themis/SKILL.md` is the only public project Skill, and `.themis/core/kernel/orchestrator/rules.md` is the only always-loaded control Rule. Semantic contracts and permission boundaries remain internal under `.themis/core/capabilities/` and `.themis/core/agent-profiles/`.

## Installation Boundary

- `.themis/core/` is Themis-owned and read-only during normal project work.
- `.themis/workspace/` is project-owned Intake/lifecycle records, Context, evidence, outcomes, and knowledge governance.
- Preserve an existing `.themis/` byte-for-byte. Fresh templates are not an upgrade, migration, or compatibility mechanism.
- Use an installer or runtime operation only when it actually exists and its result can be observed. Do not edit guidance to hide a conflict.

## Intake-First Entry

Every external user message must first become an immutable Source Event under `request-intake`, preserving original bytes and exact fragment references. This includes new requests, Questioning answers, Review feedback/approval, Acceptance, and restart/unblock messages.

Attach a Source Event to an existing Intake only through a matching active durable Intake-local confirmation or restart/unblock continuation. A `dormant-read-only` Intake is never attachable. Wording, adjacency, chat history, an open Intake, or Agent inference cannot choose attachment; otherwise create a new Intake.

```text
Source Event
→ themis-current-request-dialogue
   ├─ needs-request-confirmation → persist proposal and await a new Source Event
   ├─ rejected → persist explicit rejection
   └─ assignment-confirmed → materialize decision and declared targets
→ create/update source-bound Current Request revisions
→ resume the exact decision-bound lifecycle continuation
```

Do not create, locate, update, split, merge, or continue a lifecycle before the confirmed assignment is fully materialized and reread.

## Product Flow

```text
confirmed Current Request claims
→ Questioning
→ optional Grounding
→ Complexity Assessment
   ├─ simple → Simple Plan → lightweight Plan Check
   └─ full   → temporary Specification → Planning → full Plan Check
→ Review Projection → Review Check → Review Dialogue → Review Approval
→ Verify [Impl → independent Verification]
→ Human Acceptance
→ Summary
→ optional governed knowledge candidates
```

Both paths create the same immutable paired Plan family and converge before Review. Review occurs before project implementation. Summary requires current Verification `passed` and current Acceptance `accepted`. After the Summary pair and lifecycle completion are observed, policy freezes the bound Intake target; once all associated lifecycle targets complete, the assigned Intake becomes `dormant-read-only`, retains its immutable authority records, and cannot be attached, invoked, mutated, reactivated, or recovered.

## Authority Model

- Source Event original bytes own external input authority.
- User-confirmed source-bound claim revisions own lifecycle target semantics.
- Governed design constraints constrain solutions but cannot rewrite claims or prove implementation.
- Code, configuration, Schema, and observed executable behavior are the only current implementation fact sources.
- Temporary Specification is a full-path handoff with no persistent artifact/current pointer.
- The current checked and explicitly approved unified Plan is the execution contract.
- Review Projection is a bound read-only view of the checked Plan, not execution input.
- Context, Themico, experience, documentation, Plans, summaries, Agent inference, conversation memory, and file existence cannot replace direct implementation evidence or observed materialization.

When sources disagree, preserve the disagreement and return it to the semantic owner. Missing evidence is never success.

## Control Architecture

```text
public themis Skill
→ Global Control Rule
→ one transitions.yaml across request-intake and lifecycle
→ one internal Capability + fixed Agent Profile
→ one temporary Invocation in one authority scope
→ proposed result
→ exactly one route and declared control action
→ complete materialization, observation, reread, and pointer update
```

- `transitions.yaml` is the sole `capability + selected_path + profile + status` route/control source.
- Sixteen internal Capabilities own individual proposed semantic judgments; they are not public Skills or persistent Agents.
- Four fixed Agent Profiles constrain tools, permission, and isolation. No governance-writer Profile exists.
- One Invocation binds one scope, scope-local Execution Identity, Capability/Profile, policy digest, current evidence/artifacts, exact continuation, and allowed operations.
- Capability-to-Capability and Agent-to-Agent calls, shared authority, voting, and consensus are forbidden.
- Only `implementation-writer` may modify project implementation within current Approval/Plan scope. All governance outputs remain proposals until policy-controlled persistence and reread.

## Scope and Artifact Isolation

`request-intake` and `lifecycle` may exchange immutable stable references only. They cannot share dynamic state, Execution Identity, failure budget, continuation authority, current pointer, or completion state.

Logical artifacts use immutable revisions and separate current pointers. Paired semantic artifacts require a matching machine record and Markdown; a missing or mismatched component invalidates the whole revision. Completed Questioning exchanges use per-round immutable pairs, while unanswered questions remain proposal/continuation state.

Lifecycle state stores minimal control facts and references, not copied claim, Plan, Review, Acceptance, or Summary prose.

## Review, Verify, Acceptance, and Summary

- Review Projection presents high-impact material from abstract to concrete and uses diagrams only when they reduce burden.
- Review Dialogue proposes immutable Feedback or Approval and never patches Plan/Projection directly.
- Approval binds the checked Plan, exact projection shown, user decision Source Event, resolved feedback, and pre-Impl baseline.
- Impl records actual approved delta and cannot issue a Verification verdict.
- Independent Verification binds the exact implementation result and direct commands/observations/evidence.
- Impl and Verification use different Invocations but share one Plan Task Execution Identity and failure budget.
- Human Acceptance records source-bound user observation after Verification passed. Summary is a bound delivery projection after Acceptance accepted.

## Sticky Full Path, Failure, and Recovery

`full_path_required` is lifecycle-local and one-way. A legal quick-path complexity signal invalidates declared quick downstream state and restarts the full Specification/Planning/Review path; retries and restarts cannot clear it.

Intake Execution Identity and lifecycle Plan Task Execution Identity each allow at most three counted failures. The third terminates that identity and forbids a fourth Invocation. Intake failure never consumes lifecycle budget; Impl, Verification, and Acceptance implementation-defect repair share the lifecycle Plan task budget.

Failure Learning is scope-bound, non-blocking, non-recursive, and candidate-only. Recovery rereads active scope state, pointers, markers, artifact components, Invocation/attempt records, and applicable Git facts, then resumes only from the last proven gate. Never infer completion or automatically repair, roll back, merge, or continue partial writes. Dormant Intake records remain historical source/decision evidence but never supply a recovery continuation.

## Safe Degradation

Plan 35 provides Prompt/template/policy contracts, static checks, and manual replay semantics. Plan 36 owns strict Schema, canonical serialization, validation, issue taxonomy, semantic oracle, and fixtures. Plan 37 owns native policy evaluation, Invocation hosting, recording, digest/write services, and command execution.

If an evaluator, recorder, validator, digest service, command runner, installer, or deterministic writer is unavailable, remain at the current proven gate and state the missing assurance. Never invent Source Events, artifacts, evidence, digests, currentness, transitions, attempts, invalidations, termination, recovery, atomicity, or completion.

## Key Paths

| Purpose | Installed path |
|---|---|
| Public entry | `.claude/skills/themis/SKILL.md` |
| Global Control Rule | `.themis/core/kernel/orchestrator/rules.md` |
| Sole route/control policy | `.themis/core/policies/transitions.yaml` |
| Internal Capability contracts | `.themis/core/capabilities/` |
| Fixed Agent Profile contracts | `.themis/core/agent-profiles/` |
| Project manifest | `.themis/workspace/manifest.yaml` |
| Request Intake records | `.themis/workspace/intakes/<intake-id>/` |
| Lifecycle semantic revisions | `.themis/workspace/changes/<lifecycle-id>/` |
| Lifecycle state and pointers | `.themis/workspace/state/<lifecycle-id>/` |
| Invocations and evidence | `.themis/workspace/runs/<lifecycle-id>/`, `.themis/workspace/evidence/<lifecycle-id>/` |
| Acceptance and Summary | `.themis/workspace/outcomes/<lifecycle-id>/` |
| Scope-separated knowledge candidates | `.themis/workspace/knowledge/intakes/`, `.themis/workspace/knowledge/lifecycles/` |

Multi-Agent execution and Attribution analytics remain optional future concerns and are never Plan 35 gates.
