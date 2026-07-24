# Themis Knowledge

## Responsibility

Govern durable, reusable lessons derived from project outcomes. Knowledge owns candidate review and promotion, while authoritative project facts remain in approved Workspace context.

## Inputs

- outcome records beneath `workspace/outcomes/`;
- candidates and governance records beneath `workspace/knowledge/`;
- existing context used to detect duplicates and conflicts.

## Outputs

Keep candidates, review history, and archival records beneath `workspace/knowledge/`. Promote approved project knowledge only to the appropriate `workspace/context/` location with its provenance preserved.

## Boundaries

- Do not store project knowledge in Core.
- Do not promote secrets, transient logs, or unverified observations.
- Do not bypass duplicate, conflict, or review checks when governance is required.
- Do not rewrite existing authoritative context without recording the decision.

Candidate extraction, review workflow, promotion, archival rules, Commands, and deterministic knowledge tooling belong to later Themis capabilities and are not implied by this baseline.
