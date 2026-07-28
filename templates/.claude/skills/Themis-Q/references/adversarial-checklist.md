# Themis-Q adversarial checklist

Use this reference when the change warrants adversarial questioning:

- `quick`: run the five quick checks against the proposed requirements and acceptance criteria;
- `focused`: apply every relevant dimension to the highest-risk behavior;
- `comprehensive`: apply all dimensions across the full scope until the important scenarios are covered.

## Quick checks

1. **Empty or missing input** — Is behavior defined for empty, null, absent, or deleted related data?
2. **Failure state** — How does the user detect failure, and how does the system recover safely?
3. **Concurrency** — What happens when two actors or retries perform the operation together?
4. **Backward compatibility** — Which existing callers, data, interfaces, or workflows can regress?
5. **Rollback** — What triggers rollback, what are the exact steps, and what user or data impact remains?

## Boundary conditions

- Values at, below, and above allowed limits.
- Oversized text, files, collections, and batches.
- Unicode, control characters, paths, templates, and injection-shaped input.
- Deleted or inaccessible referenced resources.
- Locale, timezone, currency, precision, and formatting differences.

## Concurrency and race conditions

- Concurrent modification of the same resource.
- Duplicate submission and retry after ambiguous timeout.
- Partial batch success and compensation.
- Out-of-order events or stale reads.
- Conflicting state updates across processes.

## State transitions

- Operations attempted from an illegal state.
- Required steps bypassed or repeated.
- Initial or empty-system state.
- Rollback and state regression conditions.
- Recovery after interruption between state changes.

## Security and permissions

- Unauthenticated or insufficiently privileged access.
- Horizontal access to another actor's resources.
- Secret, token, personal-data, or internal-detail disclosure.
- SQL, command, template, path, and prompt injection.
- CSRF, XSS, session, tenant, and trust-boundary failures where applicable.

## Dependency failures

- API, database, queue, filesystem, network, or external service unavailable.
- Timeout versus explicit rejection.
- Unexpected status, malformed response, or incompatible version.
- Cache or default-value degradation that could hide stale data.
- Correct resumption when the dependency recovers.

## Data integrity

- Partial writes and transactional boundaries.
- Invalid schema, encoding, or binary data.
- Duplicate, lost, reordered, or stale records.
- Interrupted conversion or destructive operation.
- Large-data behavior and memory or storage exhaustion.

## Handling findings

For each valid concern, identify the affected behavior or acceptance criterion, severity, and concrete scenario. Clarify whether it should be covered now, accepted as a known risk, or deferred as separately owned work.

Critical security, permissions, and data-integrity concerns require explicit resolution or explicit blocking treatment; do not soften them merely to reach agreement.
