# Verification

> Human-readable half of one immutable independent Verification revision. Verification is read-only and cannot modify project implementation to make checks pass.

## Bindings

- Lifecycle identity:
- Verification revision identity:
- Current Request revision:
- Review Approval revision:
- Plan revision and task identity:
- Shared Plan Task Execution Identity:
- Verification Invocation and attempt identities:
- Approved pre-Impl baseline:
- Impl Result revision references:
- Actual implementation revision or delta reference:

## Verdict

- Status: `passed | failed | needs-planning | needs-specification | escalate-full | blocked`
- Failure classification: `implementation-defect | none`

## Current Request and Plan assertions

| Assertion | Expected result | Actual result | Evidence | Conclusion |
|---|---|---|---|---|

## Commands and observations

| Command or observation | Working directory/environment | Exit/result | stdout/stderr or evidence reference |
|---|---|---|---|

## Delta and drift

- Expected approved delta:
- Observed actual delta:
- Unauthorized external drift:
- Baseline applicability:

## Simple-path boundary

- Applicable: `yes | no`
- Still simple-qualified:
- Hidden contract, data, permission, state, or cross-module complexity:

## Failure details

- Failed assertion:
- Actual result:
- Impacted scope:
- Recommended route:

## Boundary

Only a complete, reread Verification pair can become current. A writer cannot verify itself, and this file alone cannot establish `passed`.
