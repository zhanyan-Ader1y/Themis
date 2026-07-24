# Themis Specification

## Responsibility

Define what a project change must achieve, why it is needed, its approved scope, and what evidence will demonstrate acceptance. Specification owns intent and acceptance criteria, not implementation design.

## Inputs

- the user's stated goal and constraints;
- relevant facts from `workspace/context/`;
- existing related artifacts under `workspace/specs/`;
- current code or configuration only when needed to resolve factual scope.

## Outputs

Save Specification artifacts only beneath the associated `workspace/specs/<spec-id>/` area. Keep acceptance criteria stable and identifiable so Planning and later evidence can trace back to them.

## Boundaries

- Do not write implementation code or choose task ordering.
- Do not treat an unresolved draft as approved.
- Do not invent project facts when Context is missing or conflicting.
- Return scope changes discovered later to Specification before implementation continues.

Requirement-questioning depth, approval mechanics, Spec templates, validation, and the `Draft → Specified` gate belong to the later Requirement Questioning capability and are not implied by this baseline.
