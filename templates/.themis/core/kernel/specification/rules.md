# Themis Specification

## Responsibility

Define what a project change must achieve, why it is needed, its approved scope, and what evidence will demonstrate acceptance. Specification owns intent and acceptance criteria, not implementation design.

## Inputs

- the user's stated goal and constraints;
- relevant facts from `workspace/context/`;
- existing related artifacts under `workspace/specs/`;
- current code or configuration only to verify a stated scope assumption.

## Outputs

After requirements are clarified and the user confirms Specification's normalized summary, create exactly one candidate at `workspace/cache/spec-candidates/<spec-id>.yaml`, then publish the authoritative `spec.yaml` plus generated `spec.md`. Stable map keys identify semantic objects and references; Markdown prose is never machine evidence.

## Requirement Questioning

Before creating or modifying a Spec candidate, invoke the `Themis-Q` Skill with the Skill tool unless it has already clarified the current request in this conversation.

- `Themis-Q` supplies questioning methods and coverage only. It does not own lifecycle routing, persistence, confirmation gates, candidate creation, or a handoff format.
- Specification owns reading `core/policies/specification.yaml`, relevant Context, existing Specs, and current code or configuration needed to ground the questions.
- Specification owns complexity classification, deciding when material uncertainty is resolved, normalizing the clarified requirement, and asking the user whether to generate the Draft Spec.
- If the Skill is missing or invocation fails, remain in Specification and report the blocker. Do not read a legacy questioning Prompt or create a candidate as fallback.
- If the user rejects or corrects the normalized summary, continue clarification and invoke `Themis-Q` again when its questioning guidance is needed.

After explicit confirmation, read `core/policies/transitions.yaml`, `core/templates/spec.yaml`, and the Artifact v2 Spec schema/projection protocols. Map final semantics from the conversation into the single candidate, then use `core/kernel/specification/themis-spec.sh publish`; never hand-maintain the canonical pair. P5 keeps `status: draft`; P8 alone may record a lifecycle transition.

## Boundaries

- Do not write implementation code or choose task ordering.
- Do not treat an unresolved or validator-blocked Draft as approved.
- Do not invent project facts when Context is missing or conflicting.
- Do not skip adversarial validation; low complexity uses its quick checklist.
- Do not recover YAML from `spec.md` or claim `draft → specified` without a deterministic executor.
