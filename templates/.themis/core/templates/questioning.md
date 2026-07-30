# Questioning Log

> Append-only lifecycle record. Add a new complete round for every user answer or correction. Never edit, replace, reorder, or delete an earlier round.

## Round `<round-id>`

### Bindings

- Previous round: `<round-id | none>`
- Current Request Revision after incorporating this round's user input: `<revision>`
- Round digest: `<control-plane supplied digest | unavailable>`

### Original request snapshot

> Preserve the user's original input without rewriting it as Agent-authored requirements.

### New user input or correction

> Preserve the complete user input for this round.

### Current understanding at question time

- Problem:
- Expected result:
- Provisional core flow:

### Diagnosed weak points

1. Weak point:
   Why it blocks Why or abstract What:

### Questions asked

1. Question:

### Complete user answers

1. Answer:

### Converged Why and What

- Why: concrete problem → impact → expected result
- What: trigger → necessary abstract action → result
- Status: `needs-questioning | converged`

### Diagnostics

- Remaining gaps:
- Notes that are Agent interpretation rather than user statements:
