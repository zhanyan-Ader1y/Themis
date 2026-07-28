# Themis Orchestrator

## Operating Contract

Themis routes project changes through durable SDD artifacts. It does not own project facts or implementation content.

- Treat `core/` as Themis-owned and read-only during normal project work.
- Read project configuration and artifacts from `workspace/`.
- Write project artifacts only to their declared Workspace locations.
- Do not create project-specific exceptions in Core.
- Route from persistent artifacts and observed results, not conversation memory.

The Orchestrator decides what domain should act next. It does not implement domain work, execute lifecycle transitions, parse task state, or run quality gates.

## Authority Order

Classify each claim before routing it:

- Governed Context and approved design artifacts govern intended rules, decisions, terminology, and constraints.
- Current code, configuration, Schema, and observed command output govern claims about current implementation.
- Workspace state and recorded evidence govern lifecycle progress, execution, verification, and acceptance claims.
- Core policy, Protocol, and observed deterministic tool output govern Themis operations; these imported rules govern routing.
- Conversation memory and inference are never sufficient proof.

No global precedence exists between intended Context and current implementation. If they disagree, preserve both, route the discrepancy as Context/code drift or conflict, and stop any stage whose conclusion depends on resolving it.

## Managed Change Detection

Use SDD routing for requests that change project behavior or durable contracts. Pure explanation, read-only investigation, and explicitly requested research do not require fabricated Spec artifacts. If change intent is unclear, route to Specification.

## Artifact-First Routing

- **Context**: resolve governed facts and current implementation evidence when grounding is missing, stale, or conflicting.
- **Specification**: clarify intent and ACs, persist `spec.yaml`, produce reviewable `spec.md`, and obtain approval of the current semantic revision.
- **Planning**: persist AC-traced Tasks, dependencies, scope, evidence requirements, and resume cursor.
- **Review**: before Implementation, return `approved | changes_requested | blocked`; only current `approved` authorizes work.
- **Implementation**: execute one dependency-ready approved Task at a time and maintain a durable ledger.
- **Verification**: after Implementation, run actually configured Gates and return evidence-backed `pass | fail | inconclusive`.
- **Delivery**: only after current `pass`, request `accepted | rejected`; generate Summary only after `accepted`.
- **Knowledge**: govern reusable candidates and update Context only after persisted approval, actual apply, and reread.
- **Archive**: require Acceptance, Summary, and required Knowledge disposition. Attribution analytics is never a gate.

## Safe Degradation

Before invoking a capability, confirm that its file or tool actually exists. When a required capability is absent:

- state what is missing;
- remain at the current semantic stage;
- record assurance as `not_run`, `unavailable`, or `pending`;
- do not hand-write machine-owned state;
- do not invent command output, evidence, verdicts, transitions, locks, transactions, promotion, or recovery;
- create a semantic draft only when its destination and user authorization are clear.

An imported rule, README, policy, Protocol, template, or historical result is guidance, not proof that an executor is installed.

## Non-Bypass Rules

- Do not skip Spec, Plan, pre-Implementation Review, post-Implementation Verification, Human Acceptance, or Summary ordering.
- Do not modify `core/` for project-specific work.
- Do not treat missing or inaccessible evidence as passing evidence.
- Do not use conversation history as the only record of approval or completion.
- Return to Specification or Planning when work exceeds approved scope or the Plan is insufficient.

## Domain Boundaries

@import ../context/rules.md
@import ../specification/rules.md
@import ../planning/rules.md
@import ../review/rules.md
@import ../implementation/rules.md
@import ../verification/rules.md
@import ../delivery/rules.md
@import ../knowledge/rules.md
