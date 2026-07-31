# Implementation Package

## Responsibility

Implementation executes one dependency-ready task from the current approved unified Plan and records the actual delta. It is the write step inside Verify and never owns the Verification verdict.

## Capability mapping

- `themis-impl`: the only internal Capability allowed to modify project implementation, using the fixed `implementation-writer` Profile.
- `core/templates/impl-result.yaml` and `impl-result.md`: paired immutable Impl Result structure.

## Inputs and result

An Invocation binds the lifecycle, current Approval, Plan revision/task, Plan Task Execution Identity, Invocation/attempt identities, policy, pre-Impl baseline, expected delta, allowed paths/commands, and exact continuation.

`implemented` proposes an Impl Result revision containing actual changed paths/delta, evidence references, deviations, and observed post-state. It does not prove persistence/currentness or Verification success. Other legal statuses return control to policy without expanding scope.

## Boundaries

- Do not modify Current Request, Plan, Review Projection, Approval, or acceptance requirements.
- Do not perform unrelated refactors or broaden approved paths/commands.
- On a simple path, hidden complexity returns `escalate-full` and stops mutation.
- Unauthorized workspace, dependency, configuration, Schema, or behavior change is external drift and requires revalidation.
- Tool/command/Agent/result-contract and materialization failures are counted failures, not `blocked` disguises.
- Filesystem write success is not governance artifact/state/current-pointer materialization.

Impl and independent Verification use separate Invocations but share the same Plan Task Execution Identity and three-failure budget, including an Acceptance `implementation-defect` repair.

## Current status

Plan 35 provides the internal Capability/Profile and Prompt-level permission/materialization boundaries. It does not provide native scope enforcement, command execution, task ledgers, recorder, digest service, deterministic writes, completion markers, or reread enforcement; those belong to Plans 36/37 as defined by their scopes.
