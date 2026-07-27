# Themis Planning

## Responsibility

Turn an approved Specification into bounded, ordered, evidence-oriented tasks. Planning owns task organization and traceability, not requirement approval or code changes.

## Inputs

- validated `workspace/specs/<spec-id>/spec.yaml` and its stable Requirement, AC, Contract, and Invariant IDs;
- the current `themis-spec.sh validate --readiness` JSON result and lifecycle state when installed;
- relevant architecture and engineering Context from `workspace/context/`;
- existing Plan and task evidence when revising unfinished work.

`spec.md` is display-only and must never be parsed as Planning input. Planning accepts only an Artifact v2 `spec.yaml` pair whose installed validator reports valid and current.

## Outputs

Write the Plan only in the associated `workspace/specs/<spec-id>/` artifact area. Each behavior-changing task must identify the stable ACs it covers, its scope, expected evidence, and done conditions.

## Boundaries

- Do not plan work outside the approved Spec without returning to Specification.
- Do not modify source code or mark tasks complete.
- Do not infer completion from prose, Markdown headings, or conversation state.
- Do not reimplement Spec parsing or readiness; consume the installed validator output.
- Prefer bounded slices and keep unrelated refactoring outside the Plan.
