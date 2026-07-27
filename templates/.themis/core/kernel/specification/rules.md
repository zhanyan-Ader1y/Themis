# Themis Specification

## Responsibility

Define what a project change must achieve, why it is needed, its approved scope, and what evidence will demonstrate acceptance. Specification owns intent and acceptance criteria, not implementation design.

## Inputs

- the user's stated goal and constraints;
- relevant facts from `workspace/context/`;
- existing related artifacts under `workspace/specs/`;
- current code or configuration only to verify a stated scope assumption.

## Outputs

Save each Draft beneath `workspace/specs/<spec-id>/` as authoritative `spec.yaml` plus generated `spec.md`. Stable map keys identify semantic objects and references; Markdown prose is never machine evidence.

## Requirement Questioning

You MUST Read these files before any Specification work:

1. `core/templates/spec-questioning.md` — the Step 0–4 protocol and publisher workflow.
2. `core/policies/specification.yaml` — complexity, readiness, projection, and publishing policy.
3. `core/policies/transitions.yaml` — validator check IDs for `draft_to_specified`.
4. `core/protocols/artifact/v2/spec-schema.yaml` and `spec-projection.yaml` — authoritative structures.

Write only a temporary `spec.yaml` candidate, then use `core/kernel/specification/themis-spec.sh publish`; never hand-maintain the pair. P5 keeps `status: draft`; P8 alone may record a lifecycle transition.

## Boundaries

- Do not write implementation code or choose task ordering.
- Do not treat an unresolved or validator-blocked Draft as approved.
- Do not invent project facts when Context is missing or conflicting.
- Do not skip adversarial validation; low complexity uses its quick checklist.
- Do not recover YAML from `spec.md` or claim `draft → specified` without a deterministic executor.
