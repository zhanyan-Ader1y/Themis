# Specification Package

## Responsibility

Specification refines an already questioned, user-confirmed Current Request on the full path. It creates a temporary, non-authoritative handoff for Planning and does not own claims, assignment, lifecycle state, path selection, Plan, Review, or implementation facts.

## Capability mapping

- `themis-q`: converges Why and abstract What before path selection; it is not a Specification sub-step.
- `themis-spec`: refines scope, observable behavior, business/external contracts, invariants, acceptance, risks, and Planning invariants on the full path.

## Inputs and output

Inputs bind the confirmed Current Request revision and active claims, current Questioning round, governed design constraints, relevant Grounding/Assessment references, and directly observed implementation facts.

A `ready` result returns a temporary Invocation handoff containing motivation, core flow, scope, behavior/contracts, acceptance, implementation evidence, assumptions, risks, unresolved issues, and Planning invariants. It has no persistent artifact revision or current pointer. After interruption it must be regenerated from current bindings.

## Authority boundary

- Exact Source Event fragments and confirmed claim revisions own user semantics.
- Specification cannot add or rewrite claims, confirm ambiguity, assign lifecycles, prove current implementation, or override user correction.
- It does not generate `spec.yaml`, `spec.md`, independent approval, persistent currentness, or an implementation contract.
- Planning must return factual or semantic gaps to the owning Capability rather than silently filling them.

## Current status

Plan 35 provides the internal `themis-spec` Capability contract and temporary handoff shape. There is no public Specification Skill, persistent Specification artifact, validator, projector, publisher, approval recorder, or executable runtime.
