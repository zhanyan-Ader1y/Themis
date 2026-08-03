# Planning Package

## Responsibility

Planning creates the single persistent Plan family from confirmed source-bound claims, governed constraints, and directly verified implementation facts. The simple path uses `themis-simple-plan`; the full path uses temporary Specification refinement followed by `themis-planning`.

## Capability mapping

- `themis-simple-plan`: creates the unified Plan within a proven simple boundary.
- `themis-planning`: performs full technical investigation, trade-off analysis, task design, and Verification planning.
- `themis-plan-check`: independently checks the proposed Plan with the selected lightweight/full profile.

## Unified Plan

Each Plan revision is a paired immutable Markdown artifact:

```text
workspace/changes/<lifecycle-id>/plan/<plan-revision>/
  record.md
  content.md
```

It binds Current Request claims, Questioning, design constraints, Grounding/Assessment, selected path/profile, and direct implementation evidence. Its governed content covers scope and core flow, behavior/contracts/acceptance, implementation facts and assumptions, technical design and trade-offs, impact/failure/recovery boundaries, dependency-ready Impl/Verification tasks, done conditions, evidence, and source-category coverage.

Simple and full paths use this same family. A simple Plan must prove non-applicable deep-design items rather than omit claim coverage, evidence, Verification, or executability.

## Boundaries

Planning does not approve claims, authorize implementation, modify the project, issue Verification verdicts, or use Specification/Context as current implementation proof. Plan Check is isolated from generation. A changed Plan revision invalidates its old Check, Review Projection, Review Check, feedback resolution, and Approval as declared by policy.

## Current status

Plan 35 provides internal Simple Planning, Planning, and Plan Check contracts plus paired Plan templates. Strict Schema/currentness/oracle/fixtures belong to Plan 36. Evaluation, recording, deterministic writes, Invocation hosting, and command execution belong to Plan 37.
