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
- Core policy, Protocol, and deterministic tool output govern Themis operations; these imported rules govern routing.
- Conversation memory and inference are never sufficient proof.

No global precedence exists between intended Context and current implementation. If they disagree, preserve both, route the discrepancy as Context/code drift or conflict, and stop any stage whose conclusion depends on resolving it.

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

Route to Specification when no relevant approved Spec exists, intent or acceptance criteria remain unresolved, requested scope exceeds the approved Spec, or the Spec validator reports an invalid/stale pair. `spec.yaml` is machine authority and `spec.md` is display-only. Do not implement from an unapproved draft.

### Planning

Route to Planning when an approved Spec exists but no adequate AC-traced Plan exists, or implementation reveals that the Plan no longer covers the approved scope. Planning organizes work; it does not modify project code.

### Review

Route to Review when an approved Spec and adequate Plan exist but no current pre-implementation approval covers the design, risks, implementation boundary, and acceptance approach. Review is read-only; only `approved` authorizes Implementation.

### Implementation

Implementation is allowed only for work represented by an approved Spec, the current Plan, and the current approved Review. Implement one bounded planned task at a time. Do not mix unrelated refactors or silently expand scope.

### Verification

Route to Verification after implementation has durable task evidence. Verification requires configured command output or recorded evidence; prose confidence is not a Gate result. A passing verdict routes to human acceptance, not Review.

### Acceptance, Summary, Archival, and Knowledge

After Verification passes, request human acceptance against the approved artifacts and current evidence. Generate the final delivery Summary only after acceptance and only through an installed capability. Archive after acceptance, Summary, Outcome, and required knowledge handling are durably satisfied. Route reusable outcomes to Knowledge governance; do not write unreviewed observations directly into authoritative project context.

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
- Do not merge pre-implementation Review, post-implementation Verification, and human acceptance into one unsupported completion claim.
- Do not claim a lifecycle transition unless persistent state or a deterministic tool records it.
- Do not use conversation history as the only record of approval or completion.
- Return to Specification or Planning when requested work exceeds approved scope.

## Domain Boundaries

The imported domain rules define stable responsibilities and Workspace boundaries. They intentionally do not claim that later Agent, Command, Skill, or Shell capabilities are already installed.

@import ../specification/rules.md
@import ../planning/rules.md
@import ../context/rules.md
@import ../verification/rules.md
@import ../review/rules.md
@import ../knowledge/rules.md
@import ../attribution/rules.md
