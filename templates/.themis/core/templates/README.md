# Templates Package

## Responsibility

Templates define Prompt-level shapes for immutable semantic revisions, structured semantic records, operational evidence, and human projections. They reduce format drift but do not create facts, calculate canonical digests, validate currentness, execute policy, or prove persistence.

## Artifact classes

### Paired semantic artifacts

Each logical revision contains one machine-readable record and one Markdown content file:

```text
<artifact-family>/<opaque-revision-id>/
  <artifact>.yaml
  <artifact>.md
```

Families are Current Request, completed Questioning round, Plan, Review Projection, Review Approval, Review Feedback, Impl Result, Verification, Human Acceptance, Summary, and Failure Learning. If either component is absent, or identity, digest, authority scope, or bindings differ, the entire logical revision is invalid.

### Structured-only semantic records

Request Intake proposal/decision, Grounding, Complexity Assessment, Plan Check, and Review Check use machine-readable records because their governed content is already structured. They still require observed materialization and reread before becoming authoritative.

### Operational and evidence records

Source Event metadata/raw-byte references, Intake/lifecycle state, Intake post-completion retention facts, Execution Identity, Invocation, attempt, raw Capability result, recorder result, current pointer, completion/incomplete marker, command evidence, and Git observations are operational facts. They are not semantic artifact revisions. A dormant retention fact references immutable assignment and lifecycle completion observations; it does not rewrite the assignment decision.

### Read-only projections

Markdown halves render governed semantics for humans. Review Projection is a checked-Plan projection; it is not an execution contract. A Markdown file alone never establishes authority.

## Immutable revision rules

- Revisions are immutable and never replaced in place.
- Current pointers are separate operational records and update only after a complete revision is reread and verified.
- Artifact revision, Invocation attempt, current pointer, and incomplete operation are different identities.
- A valid revision may exist without becoming current when pointer update fails.
- Symlinks, directory order, filenames, or file existence do not establish authority or currentness.
- Template enum text is Prompt guidance, not a strict Plan 36 Schema.

## Owned templates

- Intake: `request-intake-source-event.yaml`, `request-intake-proposal.yaml`, `request-intake-decision.yaml`.
- Requirements: `current-request.yaml` + `current-request.md`, `questioning-round.yaml` + `questioning-round.md`.
- Structured checks: `grounding.yaml`, `complexity-assessment.yaml`, `plan-check.yaml`, `review-check.yaml`.
- Delivery semantics: paired Plan, Review, Approval, Feedback, Impl Result, Verification, Acceptance, Summary, and Failure Learning templates.
- Context support: `context-resolution.md`, `context-summary.md`; these remain Context aids and are not lifecycle authority.

## Boundaries

- Only user-confirmed, source-bound claims may enter a Current Request revision.
- Unanswered Questioning remains in durable proposal/continuation state and does not create a completed round.
- Temporary Specification handoff is not a persistent artifact.
- Approval does not modify Plan or Review Projection.
- Failure Learning and Summary may propose candidates but cannot publish knowledge.
- Strict Schema, canonicalization, validator output, deterministic digests, policy execution, recorder proof, atomic replacement, and runtime currentness remain unavailable until separately implemented by Plans 36 and 37.
