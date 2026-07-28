# Themis Delivery

## Responsibility

Request Human Acceptance only after current Verification `pass`, persist the decision, and generate the final delivery Summary only after `accepted`.

## Inputs

- current approved Spec/Plan/Review;
- current implementation revision and Verification evidence;
- acceptance criteria, human steps, residual risks, and limitations.

## Outputs

Persist `accepted | rejected`. After `accepted`, generate `summary.md` from the accepted delivery source and evidence.

## Boundaries

- Do not request or record acceptance when Verification is `fail`, `inconclusive`, stale, or unavailable.
- Implementation changes invalidate prior Verification and Acceptance.
- Rejection routes to Specification, Planning, or Implementation according to the evidence; changed implementation must be reverified.
- Summary is a final delivery projection, not a Verification verdict, acceptance decision, Outcome, or lifecycle state.
- Attribution analytics is not an Acceptance, Summary, or Archive gate.
