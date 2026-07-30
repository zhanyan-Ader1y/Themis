# Orchestrator Package

## Responsibility

Orchestrator hosts the only always-loaded Global Control Rule. It coordinates lifecycle identity, current bindings, temporary Capability invocations, generic policy actions, observed persistence, invalidation, recorded-state resume, and failure limits. It does not own any Capability's semantic method or `status → next/action` mapping.

## Owned assets

- `rules.md`：generic policy interpreter, cross-cutting authority/gates, invocation validation, shared failure budget, Workspace boundary, and safe degradation.
- `../../policies/transitions.yaml`：the sole closed legal status-route declaration, fixed Agent Profile mappings, policy guards, and invalid-result behavior.

## Execution model

```text
public themis Skill
→ Global Control Rule
→ transitions.yaml selects one internal Capability
→ fixed Agent Profile
→ one temporary Agent invocation
→ validate Capability Invocation Result
→ match exactly one four-field route
→ execute declared generic action/invalidation/next
```

```text
Capability        = semantic judgment
Agent Profile     = execution permission/isolation
Invocation        = one temporary execution carrier
transitions.yaml  = sole route policy
Global Rule       = generic interpreter/coordinator
Workspace         = per-lifecycle actual records
```

A Capability cannot call another Capability. An Agent cannot call another Agent. Invocation context is discarded after one structured result; it is not shared memory or lifecycle authority.

## Authority boundary

- Current Request Revision：current delivery target semantics.
- Governed design constraints：solution constraints only.
- Code/configuration/Schema/observed behavior：current implementation facts.
- Temporary Specification handoff：full-path non-authoritative refinement.
- Approved unified Plan：execution contract.
- Workspace records：actual lifecycle state only when the responsible operation was observed.

The Rule does not judge complexity, refine requirements, design a Plan, evaluate a Plan, create Review content, issue Verification verdicts, classify human acceptance, or publish knowledge. It never parses diagnostics or `recommended_route` as hidden control state.

## Workspace interaction

The Rule may append a Questioning round, update its pointer, persist an artifact/reference, record governance state, or apply invalidation only through an available operation with an observed result. Multiple lifecycles can share the same read-only policy identity/digest, but their revisions, continuations, sticky state, attempts, evidence, Acceptance, and Summary remain lifecycle-bound.

## Write isolation and interruption boundary

A mutating invocation binds one lifecycle/task/invocation identity, one worktree identity, approved paths, and the pre-Impl baseline. Concurrent writers require exclusive worktrees; without that support, the Rule allows only a serial unique writer or stops fail closed. Individual writes use pre-write validation, complete temporary writes and atomic replacement where applicable, completion/incomplete markers, and reread verification.

After interruption, the Rule rereads actual lifecycle records, files, Git status/diff, and completion markers, then resumes only from the last proven gate or stops. Worktrees do not prove persistence. Plan 35 does not claim cross-worktree locks, general transactions, rollback journals, automatic recovery, cross-worktree merge, or conflict adjudication.

## Current status

Plan 35 provides a Prompt-level Global Rule, one public Skill, fifteen internal Capability contracts, four fixed Agent Profile contracts, a 91-row route policy, explicit worktree/write-safety boundaries, and manual replay semantics. Strict Schema, result vectors, validator, canonicalization, and currentness fixtures belong to Plan 36. The future Plan 37 runtime owns policy evaluation, temporary invocation, per-lifecycle state recording, atomic replacement, completion markers, and reread verification; it does not own general locks, transactions, rollback journals, automatic recovery, cross-worktree merge, or conflict adjudication.
