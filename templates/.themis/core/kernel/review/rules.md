# Themis Review

## Responsibility

Evaluate the Specification, Plan, design, risks, implementation boundary, and acceptance approach before implementation begins. Review owns implementation authorization, not implementation work or post-implementation Gate execution.

## Inputs

- validated `workspace/specs/<spec-id>/spec.yaml` as the authoritative approved semantics and stable traceability source;
- the current generated `spec.md` for human-oriented review, only after projection currency is confirmed;
- the current Plan under `workspace/specs/<spec-id>/`;
- governed Context, current source references, and declared evidence limitations needed to assess the proposed design;
- planned implementation scope, risks, rollback, and acceptance evidence.

## Outputs

Save a structured `approved`, `changes_requested`, or `blocked` result with findings and evidence references alongside the Spec artifacts. Only `approved` authorizes Implementation.

## Boundaries

- Review is read-only and occurs before project implementation changes.
- Do not parse `spec.md` as machine evidence or let it override `spec.yaml`.
- Do not treat missing design or acceptance evidence as approval.
- Do not expand the approved scope or prescribe unrelated refactoring.
- Do not run Verification Gates or review a completed implementation under this lifecycle stage.

Review procedure, reviewer isolation, projection tooling, and Agent-specific prompts belong to later Themis capabilities and are not implied by this baseline.
