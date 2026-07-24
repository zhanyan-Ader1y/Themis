# Themis Verification

## Responsibility

Produce command-backed facts about configured quality gates and preserve the evidence needed to evaluate them. Verification owns observed results, not implementation changes or subjective review.

## Inputs

- configured commands and Gates from `workspace/manifest.yaml` and effective Workspace policy;
- implementation and task evidence declared by the current Plan;
- actual command output from installed deterministic executors when available.

## Outputs

Write run records and supporting evidence only beneath `workspace/runs/` and `workspace/evidence/`, with exact commands, outcomes, and unavailable checks distinguished from passing checks.

## Boundaries

- Do not claim success without observed output or durable evidence.
- Do not invent a default command when the manifest value is `null`.
- Do not modify project code while acting as Verification.
- Keep Verification results distinct from Review judgments.

Gate execution, failure classification, retry policy, verdict calculation, and pipeline executors belong to later Themis capabilities and are not implied by this baseline.
