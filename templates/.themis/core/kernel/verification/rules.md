# Themis Verification

## Responsibility

Produce command-backed facts about an implementation that follows the approved Specification, Plan, and pre-implementation Review. Verification owns observed results, not implementation changes, design approval, or human acceptance.

## Inputs

- configured commands and Gates from `workspace/manifest.yaml` and effective Workspace policy;
- the approved Review and current Plan;
- implementation and task evidence declared by that Plan;
- actual command output from installed deterministic executors when available.

## Outputs

Write run records and supporting evidence only beneath `workspace/runs/` and `workspace/evidence/`, with exact commands, outcomes, and unavailable checks distinguished from passing checks. A passing verdict routes to human acceptance, not back to Review.

## Boundaries

- Do not claim success without observed output or durable evidence.
- Do not invent a default command when the manifest value is `null`.
- Do not modify project code while acting as Verification.
- Do not reconsider the approved design or issue Review approval.
- Do not claim human acceptance or generate a final delivery summary.

Gate execution, failure classification, retry policy, verdict calculation, and pipeline executors belong to later Themis capabilities and are not implied by this baseline.
