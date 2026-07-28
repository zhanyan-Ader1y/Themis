# Themis Planning

## Responsibility

Turn an approved Specification into bounded, ordered, evidence-oriented tasks. Planning owns task organization, AC traceability, scope, and resume data, not requirement approval or code changes.

## Inputs

- current approved `workspace/specs/<spec-id>/spec.yaml`;
- current `spec.md` only for human review, never as semantic input;
- relevant governed Context and directly observed current code/configuration/Schema;
- existing Plan, task ledger, and evidence when revising unfinished work.

## Outputs

Persist `plan.yaml` as semantic authority and `plan.md` as Human projection in the associated Spec area. Each Task records stable ID, dependencies, covered ACs, scope, evidence, done conditions, risks, rollback, and resume cursor.

## Boundaries

- Do not plan outside the approved Spec without returning to Specification.
- Do not modify source code, approve Implementation, or mark Tasks complete.
- Do not infer completion or currentness from prose, Markdown headings, or conversation state.
- Prompt owns decomposition judgment; deterministic assurance may validate DAG, traceability, scope, and cursor but must not choose the Plan.
- When validators are absent, record assurance as `unavailable`; do not claim machine-valid or current Plan state.
