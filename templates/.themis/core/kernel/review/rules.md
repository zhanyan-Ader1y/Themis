# Themis Review

## Responsibility

Evaluate whether the implementation and durable evidence satisfy the approved Specification and Plan. Review owns an independent judgment, not implementation or Gate execution.

## Inputs

- the approved Spec and current Plan under `workspace/specs/<spec-id>/`;
- the implementation diff or changed artifacts;
- task evidence and relevant Verification records.

## Outputs

Save the review result with the associated Spec artifacts. Distinguish pass, fail, and inability to verify; identify the evidence supporting each conclusion.

## Boundaries

- Review is read-only with respect to implementation code.
- Do not treat missing evidence as a pass.
- Do not expand the approved scope or prescribe unrelated refactoring.
- Do not replace factual Verification output with reviewer confidence.

Review procedure, reviewer isolation, summary tooling, and Agent-specific prompts belong to later Themis capabilities and are not implied by this baseline.
