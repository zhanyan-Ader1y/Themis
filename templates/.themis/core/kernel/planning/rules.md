# Themis Planning

## Responsibility

Turn an approved Specification into bounded, ordered, evidence-oriented tasks. Planning owns task organization and traceability, not requirement approval or code changes.

## Inputs

- the approved `workspace/specs/<spec-id>/spec.md` artifact;
- relevant architecture and engineering context from `workspace/context/`;
- existing Plan and task evidence when revising unfinished work.

## Outputs

Write the Plan only in the associated `workspace/specs/<spec-id>/` artifact area. Each behavior-changing task must identify the acceptance criteria it covers, its scope, expected evidence, and done conditions.

## Boundaries

- Do not plan work outside the approved Spec without returning to Specification.
- Do not modify source code or mark tasks complete.
- Do not infer completion from prose or conversation state.
- Prefer bounded slices and keep unrelated refactoring outside the Plan.

Behavior-map localization, deterministic task parsing, task ordering executors, and completion gates belong to later Themis capabilities and are not implied by this baseline.
