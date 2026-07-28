# Context Resolution

## Purpose

Resolve only the governed Context needed for the current Spec, Plan, Review, or Task. Semantic selection is allowed; discovery, validation, persistence, digest calculation, and Bundle publication remain deterministic executor responsibilities.

## Required Flow

1. Read the installed Context Protocols under `core/protocols/context/`.
2. Use `themis-context-search.sh query` to discover candidates, then create a request and use `themis-context-assemble.sh prepare` to freeze the candidate set.
3. Read only the prepared Bundle manifest and the candidate metadata it contains. Do not add an ID, path, digest, or fact that is absent from that manifest.
4. Classify every candidate as selected or excluded. Selection is semantic relevance, not a freshness or authority override.
5. Write only the selection YAML below and pass it to `themis-context-assemble.sh select`; the executor must validate membership, uniqueness, digests, and budgets.
6. Use `themis-context-assemble.sh finalize` before relying on the resolved Context.

## Output

```yaml
selected:
  - id: CTX-001
    reason: <why this governed item is required>
excluded:
  - id: CTX-002
    reason: <why this candidate is not required>
```

Both arrays are required. Each candidate ID must appear exactly once, and no ID outside the prepared candidate set is allowed. Reasons must describe relevance only; they must not introduce project facts.

## Fail-Closed Rules

- An empty candidate set is missing Context, not permission to infer the answer.
- If the Bundle or relevant Signal reports `missing`, `stale`, `context_conflict`, `context_code_drift`, `conflict`, or `unavailable`, stop factual conclusions that depend on the affected claim and surface the blocker.
- Governed Context describes intended rules and decisions; current code, configuration, and Schema describe current implementation. Record disagreement as drift or conflict rather than choosing a global winner.
- Do not edit Catalog, L3 Items, L1/L2 projections, Signal disposition, lifecycle state, or source code from this Prompt.
- Do not treat ranking, Cache content, conversation memory, or model inference as authoritative Context.
