# Knowledge Package

## Responsibility

Knowledge receives governed candidates produced by failure and completion flows. Candidates never become formal knowledge automatically and cannot alter the Intake/lifecycle route, failure budget, verdict, Acceptance, Summary, or completion state that produced them.

## Capability mapping

- `themis-failure-learning`: proposes a scope-bound candidate after every counted failure and after an explicitly linked later success.
- `themis-summary`: may propose optional project-experience or project-knowledge changes after delivery completion.
- `core/templates/failure-learning.yaml` and `failure-learning.md`: paired immutable candidate structure.
- `core/templates/context-summary.md`: source-supported candidate structure for separate governance.

## Scope and failure boundary

Failure Learning runs in exactly one `request-intake | lifecycle` authority scope per Invocation:

- `request-intake` candidates live under `workspace/knowledge/intakes/<intake-id>/`.
- `lifecycle` candidates live under `workspace/knowledge/lifecycles/<lifecycle-id>/`.

It is non-blocking and non-recursive. Its failure cannot consume or reset the main route's budget. A later success association requires explicit identity linkage; prose similarity is insufficient.

## Publication boundary

Summary and Failure Learning only propose candidates. Formal publication requires separate source verification, duplicate/conflict checks, Review, explicit authorization, observed apply, and reread. Plan 35 does not implement this publication flow.

`themis-context` records reusable experience only. It does not turn project architecture, design decisions, user claims, or current implementation facts into experience authority. Governed project knowledge and experience remain distinct from direct implementation evidence.

## Current status

Plan 35 provides scope-aware Failure Learning/Summary contracts and candidate templates. Strict candidate/apply contracts belong to Plan 36. Any native approved apply, deterministic write, completion observation, and reread enforcement belongs to Plan 37; neither plan supplies a general transaction, lock, rollback, or automatic-recovery subsystem.
