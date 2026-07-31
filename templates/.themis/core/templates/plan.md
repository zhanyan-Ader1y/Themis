# Plan

> Human-readable half of the single immutable execution contract used by simple and full paths. The paired machine record owns identity, typed bindings, content digest, observed materialization, and currentness. This file alone is not authority.

## Bindings

- Lifecycle identity:
- Plan revision identity:
- Confirmed Intake assignment decision:
- Current Request revision and active claim revisions:
- Questioning round revision:
- Governed design constraint references:
- Grounding result reference:
- Complexity Assessment reference:
- Selected path: `simple | full`
- Profile: `lightweight | full`
- Full path required: `false | true`
- Temporary Specification handoff reference: `<full path only | none>`
- Implementation fact baseline and evidence:

## Current request, scope, and core flow

### Goal and expected result

### Core flow

### Included scope

### Explicit exclusions

## Behavior, contracts, and acceptance requirements

### Observable behavior

### Contracts and invariants

### Acceptance requirements

## Current implementation facts, assumptions, and invariants

### Direct implementation facts

| Assertion | Code/configuration/Schema/observation evidence | Baseline | Applicability | Unknowns |
|---|---|---|---|---|

### Assumptions

### Not applicable deep-design areas

> Simple path only: each compressed area requires evidence explaining why it is not applicable.

## Technical approach, trade-offs, and implementation design

### Approach

### Components, boundaries, and dependencies

### Data flow and state changes

### Interfaces and failure behavior

### Key trade-offs

## Impact, failure handling, and interruption boundaries

### Expected implementation delta

### Regression surface

### Failure handling

### Recovery or rollback

## Impl and Verification task breakdown

### Impl tasks

| Task identity | Dependencies | Approved scope | Completion condition | Expected delta |
|---|---|---|---|---|

### Verification tasks

| Plan task identity | Assertions | Method or command | Expected evidence | Completion condition |
|---|---|---|---|---|

## Authority input coverage

| Source class | Source reference | Covered Plan sections | Treatment |
|---|---|---|---|
| User-confirmed Current Request claims | | | objective authority |
| Governed design constraints | | | constrains solution only |
| Implementation fact evidence | | | current implementation fact |
| Temporary Specification refinement | | | full-path non-authoritative refinement |

## Revision boundary

Changes create a new immutable Plan pair. A current pointer is updated only after complete materialization and reread; Review, Approval, or dialogue never patch this content in place.
