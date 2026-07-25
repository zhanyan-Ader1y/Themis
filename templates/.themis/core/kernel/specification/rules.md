# Themis Specification

## Responsibility

Define what a project change must achieve, why it is needed, its approved scope, and what evidence will demonstrate acceptance. Specification owns intent and acceptance criteria, not implementation design.

## Inputs

- the user's stated goal and constraints;
- relevant facts from `workspace/context/`;
- existing related artifacts under `workspace/specs/`;
- current code or configuration only to verify a stated scope assumption.

## Outputs

Save Draft Specification artifacts only beneath `workspace/specs/<spec-id>/`. Keep acceptance criteria stable and identifiable so Planning and later evidence can trace back to them. Record questioning, adversarial, and explicit approval evidence in `spec.md`.

## Requirement Questioning

Before Spec validation, follow the Step 0–4 flow in `core/templates/spec-questioning.md`. Use `core/policies/specification.yaml` for complexity modes and `core/policies/transitions.yaml` for the declared `draft_to_specified` evidence contract. P5 creates or completes a Draft; only a future deterministic P8 executor may record a lifecycle transition.

## Boundaries

- Do not write implementation code or choose task ordering.
- Do not treat an unresolved Draft as approved.
- Do not invent project facts when Context is missing or conflicting.
- Do not skip adversarial validation; low complexity uses its quick checklist.
- Do not claim `draft → specified` without persistent state or a deterministic executor.
- Return scope changes discovered later to Specification before implementation continues.
