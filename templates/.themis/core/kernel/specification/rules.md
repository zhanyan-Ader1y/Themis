# Themis Specification

## Responsibility

Define what a project change must achieve, why it is needed, its approved scope, and what evidence will demonstrate acceptance. Specification owns intent and acceptance criteria, not implementation design.

## Inputs

- the user's stated goal and constraints;
- relevant governed facts from `workspace/context/`;
- existing related artifacts under `workspace/specs/`;
- current code, configuration, and Schema needed to ground scope assumptions.

## Requirement Questioning

Before creating or modifying a Spec source, invoke the `Themis-Q` Skill with the Skill tool when material uncertainty remains and its method has not already clarified the current request.

- `Themis-Q` supplies questioning methods and coverage only. It does not own routing, persistence, confirmation, candidate creation, or handoff.
- Specification owns policy/Context reads, complexity classification, convergence, normalized summary, explicit Draft confirmation, persistence, projection, review, approval, and Planning handoff.
- If the Skill is missing or invocation fails, remain in Specification and report the blocker; do not substitute a legacy Prompt.

## Outputs and flow

- Persist `workspace/specs/<spec-id>/spec.yaml` as the only semantic authority.
- Produce `spec.md` as a Human review projection; never reverse-sync Markdown into YAML.
- Ask the user to review the current projection. Feedback revises `spec.yaml` and invalidates prior approval.
- Record explicit approval of the current semantic revision before Planning handoff.
- When deterministic assurance is unavailable, mark validation/projection/currentness as `unavailable` rather than claiming machine guarantees.

## Boundaries

- Do not write implementation code or choose task ordering.
- Do not invent project facts when Context and current code are missing or conflicting.
- Do not claim canonical projection, digest, OID, readiness, currentness, publication transaction, or `draft → specified` transition without observed runtime output.
- Do not treat an unresolved Draft or a review copy as approved machine state.
