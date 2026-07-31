# Verification Package

## Responsibility

Verification runs after Impl in an independent read-only Invocation. It reads the actual implementation and exact evidence to judge Current Request and Plan acceptance requirements, baseline/delta, external drift, and simple-path boundaries. It cannot modify the implementation to make checks pass.

## Capability mapping

- `themis-verification`: fixed `independent-checker` Capability.
- `core/templates/verification.yaml` and `verification.md`: paired immutable Verification structure.

## Evidence and binding

A complete Verification revision binds current Approval and Plan, current Impl Result and exact implementation delta, independent Invocation/attempt identities, commands/observations, cwd/environment, exit/result, stdout/stderr or evidence references, coverage, verdict, and residual risk.

Missing configured evidence cannot produce `passed`. Unconfigured commands cannot be guessed. A file write, Agent assertion, Review Markdown, or stale result is not implementation evidence.

## Status boundary

`failed` means an evidence-backed `implementation-defect`. Requirement/design/path complexity returns to its semantic owner through the corresponding policy status; external drift stops and revalidates without consuming a failure as an implementation defect.

Impl and Verification have different Invocation identities but share one Plan Task Execution Identity and cumulative three-failure budget. A bounded implementation repair keeps the approved Plan only when policy confirms the Approval bindings remain current.

## Workspace interaction

Task Execution/Invocation/attempt/Impl/Verification records belong under `workspace/runs/<lifecycle-id>/`; direct command and Git evidence belongs under `workspace/evidence/<lifecycle-id>/`. Each complete Verification is an immutable revision with a separate current pointer.

## Current status

Plan 35 provides the Capability/Profile, evidence semantics, and paired templates. Strict evidence/result validation belongs to Plan 36; native command execution, recording, completion markers, digesting, and reread enforcement belong to Plan 37.
