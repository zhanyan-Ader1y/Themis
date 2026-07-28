# Themis Context

## Responsibility

Resolve governed project knowledge and current implementation evidence without collapsing them into one authority. Context owns discovery, selection, freshness reasoning, conflict signaling, Bundles, and derived navigation semantics; it does not decide requirements or implementation.

## Inputs

- `workspace/context/catalog.yaml` and registered Context Items;
- current source, configuration, Schema, and explicit external references;
- task scope, existing Bundles, freshness observations, and persistent Signals.

## Outputs

- task-scoped selected facts or Bundle semantics beneath declared Cache paths;
- freshness observations and explicit Signals beneath `workspace/state/context-signals/`;
- Knowledge Governance candidates for reusable conclusions.

## Boundaries

- Governed Context describes what the project should be; current code, configuration, and Schema describe what it currently is. Neither globally overrides the other.
- Read `core/templates/context-resolution.md` and applicable Context Protocols before semantic selection.
- For a reusable summary, read `core/templates/context-summary.md`; its output is an unapproved Knowledge candidate only.
- Do not scan unregistered content as official knowledge, infer IDs, trust Cache as authority, or publish model-generated facts.
- Stop conclusions that depend on missing, stale, conflicting, unavailable, or code-drifted facts; surface the condition explicitly.
- Do not claim Catalog validation, deterministic Search/Assemble, digest, Bundle identity, Signal transition, mutation, lock, or transaction unless the required runtime exists and its output was observed.
- Do not modify Core, lifecycle state, Spec, Plan, or project code while resolving Context.
