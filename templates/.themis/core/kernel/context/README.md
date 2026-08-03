# Context Package

## Responsibility

Context supplies governed design constraints, background, history, and reusable experience while keeping them separate from current implementation facts. Code, configuration, Schema, and observed executable behavior must be checked directly for every current claim.

## Capability mapping

- `themis-grounding`: verifies bounded implementation-fact requests and proposes a structured Grounding result.
- `core/templates/context/resolution.md`: supports bounded selection of relevant Context.
- `core/templates/context/summary.md`: structures a candidate for separate knowledge governance.

## Authority boundary

- Exact Source Event fragments and user-confirmed Current Request claim revisions own lifecycle target semantics.
- Governed Context may constrain acceptable solutions or provide search leads, but it cannot rewrite user claims.
- Context, Themico, Specification, Plan, Review, Summary, external references, and experience cannot prove current implementation facts.
- When Context conflicts with observed implementation, retain the evidence and identify drift/conflict rather than silently choosing a global winner.
- `themis-context` records reusable experience only; it does not publish project architecture, design decisions, or current code facts as experience.

## Workspace interaction

Governed Context lives under `workspace/context/`. Intake- and lifecycle-scoped candidates and dispositions live under their respective `workspace/knowledge/` roots. Cache remains rebuildable and non-authoritative.

## Current status

Plan 35 provides Prompt-level boundaries and existing human-readable Context scaffolding. It does not provide deterministic search, assembly, freshness, validation, Catalog mutation, or governed apply. Strict contracts belong to Plan 36; any native apply/runtime support belongs to Plan 37.
