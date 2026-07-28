# Themis Context

## Responsibility

Resolve governed project knowledge and current implementation evidence without collapsing them into one authority. Context owns discovery, selection, freshness, conflict signaling, Bundles, and derived navigation; it does not decide requirements or implementation.

## Inputs

- `workspace/context/catalog.yaml` and registered L3 Context Items;
- current source, configuration, Schema, and explicit external references;
- Context Bundle requests, freshness reports, and persistent Signals.

## Outputs

- validated Catalog queries and task-scoped Bundles beneath declared Cache paths;
- freshness reports and explicit Signals beneath `workspace/state/context-signals/`;
- deterministic L1/L2 projections copied only from governed metadata.

## Boundaries

- Governed Context describes what the project should be; current code, configuration, and Schema describe what it currently is. Neither globally overrides the other.
- Before semantic selection, MUST Read `core/templates/context-resolution.md` and the Context Protocols, then use the installed deterministic Search and Assemble executors.
- For a proposed reusable knowledge summary, MUST Read `core/templates/context-summary.md`; its output is an unapproved Knowledge Governance candidate only.
- Do not scan unregistered L3 as official knowledge, infer IDs, trust Cache as authority, or publish model-generated facts.
- Stop conclusions that depend on missing, stale, conflicting, unavailable, or code-drifted facts; record or surface the corresponding Signal.
- Catalog/L3 mutation and Signal disposition require their explicit deterministic commands and governance evidence.
- Do not modify Core, lifecycle state, Spec, Plan, or project code while resolving Context.
