# Review Package

## Responsibility

Review occurs before project implementation. It projects a current checked Plan into a low-burden immutable view, independently checks projection fidelity, and uses governed dialogue to propose feedback or explicit approval of that Plan revision.

## Capability mapping

- `themis-review-projection`: proposes a paired read-only Review Projection.
- `themis-review-check`: proposes a structured fidelity/burden judgment.
- `themis-review-dialogue`: explains the shown projection and proposes a continuation, immutable feedback, or immutable approval.
- Global Control Rule and policy: materialize the matched result; the dialogue Capability cannot write authority directly.

## Review flow

```text
current checked Plan
→ Review Projection
→ Review Check
→ user message intercepted as Source Event
→ Review Dialogue
   ├─ continuation
   ├─ Review Feedback proposal → semantic owner
   └─ Review Approval proposal
```

Review Projection presents high-impact content first and moves from abstract to concrete, adding only diagrams that reduce understanding cost. It is a projection of the checked Plan, not a second Plan, execution input, or place for manual governance edits.

## Feedback and Approval

Review Feedback is an independent paired immutable revision. It preserves the user's source-bound meaning and selects exactly one semantic owner from Current Request Dialogue, `themis-q`, Specification, Simple Planning, Planning, Plan Check, or Review Projection. Claim/assignment feedback returns through Intake interception to Current Request Dialogue; Why/abstract-What feedback returns to `themis-q`. Grounding may collect evidence for a bound owner but is not a feedback owner. Review Dialogue cannot patch Plan or projection directly.

Approval approves the checked Plan while also binding the exact projection shown to the user. It binds the confirmed Intake assignment decision, Current Request and active claims, Questioning, governed constraints, Grounding/Assessment, path/profile and sticky flag, Plan/Plan Check, projection/Review Check, empty unresolved feedback, approval Source Event, approval time, and pre-Impl baseline.

A dialogue `approved` result is still proposed output. Only complete policy-controlled materialization and reread creates current Approval. A changed bound input invalidates the old Approval.

## Current status

Plan 35 provides the three internal Review Capability contracts and immutable template families. Strict projection/currentness validation belongs to Plan 36; policy evaluation, recording, deterministic writes, and reread enforcement belong to Plan 37.
