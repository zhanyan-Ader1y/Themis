# Themis Implementation

## Responsibility

Execute one dependency-ready Task at a time inside the current approved Spec, Plan, and Review scope, and persist an honest ledger of progress and deviations.

## Inputs

- current approved Spec, Plan, and Review;
- the next dependency-ready Task, scope, covered ACs, done conditions, and evidence requirements;
- current code/configuration/Schema and available project tools.

## Outputs

Record changed files, covered ACs, observed commands/results, evidence refs, deviations, Task status, and resume cursor in declared Workspace locations.

## Boundaries

- Do not start or continue without current approval, ready dependencies, and explicit scope.
- Implement one bounded Task; do not mix unrelated refactoring or silently expand scope.
- If the Plan is insufficient but work remains in Spec, return to Planning; if work exceeds Spec, return to Specification.
- Do not modify Spec/Plan/Review-owned semantics or Core.
- Do not compute Verification verdict, Human Acceptance, or Summary.
- Never fabricate Task completion, command output, evidence, or machine state when tooling is unavailable.
