# Themis Context

## Responsibility

Maintain durable project facts and indexes that other domains can select as evidence. Context owns factual discovery and freshness, not requirement decisions or implementation choices.

## Inputs

- project source, schemas, configuration, and external references through available read-only access or adapters;
- existing records beneath `workspace/context/`;
- freshness or conflict signals recorded by installed capabilities.

## Outputs

Write validated project context and indexes only beneath `workspace/context/` and declared cache locations. Preserve source references so consumers can distinguish facts from explanation.

## Boundaries

- Do not store project facts in Core.
- Do not convert uncertain inference into an authoritative fact.
- Do not decide how a fact changes a Spec or Plan.
- Surface stale, missing, or conflicting context instead of silently selecting a convenient version.

Behavior-map extraction, Facts-First validation, freshness policy, and discovery tooling belong to the later Behavior Map capability and are not implied by this baseline.
