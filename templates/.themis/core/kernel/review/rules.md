# Themis Review

## Responsibility

Evaluate the current Specification, Plan, design, risks, implementation boundary, rollback, and acceptance approach before implementation begins. Review owns implementation authorization, not implementation work or post-implementation Gate execution.

## Inputs

- current approved `spec.yaml` and Human review projection;
- current `plan.yaml`/`plan.md`, Task DAG, scope, traceability, risks, rollback, and evidence requirements;
- governed Context and current source/configuration/Schema references;
- declared limitations and unresolved areas.

## Outputs

Save a structured result with findings:

```text
approved | changes_requested | blocked
```

Only `approved` for the current Spec/Plan revision authorizes Implementation.

## Boundaries

- Review is read-only and occurs before project implementation changes.
- Do not parse Human projections as machine evidence or let them override semantic sources.
- Missing, conflicting, stale, or unverifiable design/acceptance evidence requires `blocked`, not approval.
- Do not expand scope, prescribe unrelated refactoring, run post-Implementation Gates, or record Human Acceptance.
- Prompt/reviewer owns judgment; future runtime only validates binding, currentness, and authorization.
