# Context Summary Candidate

## Purpose

Propose a source-backed Context Item candidate for Knowledge Governance. This Prompt may compress verified material into reviewable metadata and body text; it cannot approve, register, publish, or assign authority to project knowledge.

## Required Inputs

- the verified source material and its relative paths or external references;
- the relevant governed Context Bundle, when one exists;
- the intended category and scope;
- unresolved uncertainty, conflict, freshness, and code-drift signals.

## Output

```yaml
candidate:
  title: <concise governed title>
  category: domain | glossary | decisions | architecture | engineering | pitfalls | external
  kind: <knowledge kind>
  authority: <proposed authority>
  scope: []
  tags: []
  abstract: <L1-safe abstract>
  overview: <L2-safe overview>
  source_refs: []
  dependencies: []
  supersedes: []
body: |
  <proposed L3 detail grounded only in the cited sources>
uncertainties: []
```

Use stable Context IDs in `dependencies` and `supersedes` only when those IDs already exist in the validated Catalog. Preserve disagreement and uncertainty explicitly instead of smoothing it into one claim.

## Boundaries

- Do not invent a `CTX-*` ID, status, digest, revision, approval, or Catalog entry.
- Do not write directly to `workspace/context/`, `catalog.yaml`, L1/L2 projections, or Context Cache.
- Do not convert current code behavior into intended policy without human-approved governance evidence.
- Do not use missing sources, stale material, unresolved conflict, or model inference as a factual basis.
- Route the output to the installed Knowledge Governance candidate location and process; if that capability is absent, return the candidate to the caller without persistence.
- Navigation publication remains the responsibility of `themis-context-navigation.sh` after the governed L3 Item and Catalog entry exist.
