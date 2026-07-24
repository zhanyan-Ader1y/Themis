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

Use the highest available authority:

1. Current code, configuration, structured artifacts, and command output.
2. Workspace state and recorded evidence.
3. Core policy, protocol, and deterministic tool output.
4. These imported rules.
5. Conversation memory or inferred progress.

Never replace a higher-authority result with a lower-authority assumption. If sources conflict, stop at the current stage and report the conflict.

## Managed Change Detection

Use SDD routing for a request that changes project behavior or its durable contract, including:

- features and defect fixes;
- public interfaces, schemas, configuration, permissions, or migrations;
- build, test, deployment, compliance, or verification behavior;
- project knowledge that changes implementation constraints.

Pure explanation, read-only investigation, and explicitly requested research do not require fabricated Spec artifacts. If it is unclear whether a request changes behavior, route to Specification rather than beginning implementation.

## Artifact-First Routing

Determine the next domain from existing Workspace artifacts and the effective project policy.

### Specification

Route to Specification when no relevant approved Spec exists, intent or acceptance criteria remain unresolved, or requested scope exceeds the approved Spec. Do not implement from an unapproved draft.

### Planning

Route to Planning when an approved Spec exists but no adequate AC-traced Plan exists, or implementation reveals that the Plan no longer covers the approved scope. Planning organizes work; it does not modify project code.

### Implementation

Implementation is allowed only for work represented by an approved Spec and the current Plan. Implement one bounded planned task at a time. Do not mix unrelated refactors or silently expand scope.

### Verification

Route to Verification after implementation has durable task evidence. Verification requires configured command output or recorded evidence; prose confidence is not a Gate result. Follow the effective lifecycle policy when it differs from the documented default.

### Review

Route to Review only with the Spec, Plan, implementation diff, and required evidence available. Review is evidence-based and read-only. Missing evidence produces an unresolved result, not a pass.

### Archival and Knowledge

Archive only after the effective lifecycle requirements are durably satisfied. Route reusable outcomes to Knowledge governance; do not write unreviewed observations directly into authoritative project context.

## Safe Degradation

Later Themis plans may install Commands, Skills, domain Agents, policies, and deterministic Shell executors. Before invoking one, confirm that the capability actually exists.

When a required capability is absent:

- state which capability or artifact is missing;
- remain at the current lifecycle stage;
- do not hand-write machine-owned state as a substitute;
- do not invent command output, evidence, verdicts, or transition history;
- create a domain artifact draft only when the user has approved that work and its destination is already defined.

An imported rule is guidance, not proof that an executor or policy has been installed.

## Non-Bypass Rules

- Do not skip required Spec or Plan artifacts because a change appears small.
- Do not modify `core/` to solve a project-specific request.
- Do not treat missing, stale, or inaccessible evidence as passing evidence.
- Do not merge Verification and Review into one unsupported completion claim.
- Do not claim a lifecycle transition unless persistent state or a deterministic tool records it.
- Do not use conversation history as the only record of approval or completion.
- Return to Specification or Planning when requested work exceeds approved scope.

## Domain Boundaries

The imported domain rules define stable responsibilities and Workspace boundaries. They intentionally do not claim that later questioning, behavior-map, Agent, Command, Skill, or Shell capabilities are already installed.

@import ../specification/rules.md
@import ../planning/rules.md
@import ../context/rules.md
@import ../verification/rules.md
@import ../review/rules.md
@import ../knowledge/rules.md
