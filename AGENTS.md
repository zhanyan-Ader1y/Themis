# Project

AGENTS.md takes precedence over CLAUDE.md and all module planning documents. This file is the canonical repository-wide design contract.

Themis is an SDD Harness framework that installs a local AI coding system into engineering projects and enables governed accumulation of project knowledge.

## Design Governance

- Every confirmed Themis design standard must be recorded in this file in the same change that establishes or modifies it.
- Module `README.md`, `impl.md`, Wiki pages, policies, and templates may contain detailed design, but must not be the only source of a repository-wide rule.
- If another design document conflicts with this file, follow `AGENTS.md` and update the conflicting document.
- A plan is not implementation authorization. The user must explicitly initiate the plan.
- The first implementation step for a plan is to create or update `docs/plan/<priority>-<slug>/impl.md` with decisions, tasks, target files, and verification matrix.
- Do not modify implementation files for that plan until the user confirms its `impl.md`.
- Each plan owns its own directory and its own `impl.md`. Split large module designs into focused implementation segments in that directory.

## Repository Documentation

- `README.md` is project introduction and Wiki navigation, not the full design specification.
- Organize long-lived documentation as a module-oriented Wiki under `docs/`; one module per file or directory.
- Non-module details belong as sections of the owning module document.
- Keep workflow, plan index, module Wiki, template contracts, and release metadata synchronized with implemented behavior.

## Core and Workspace Ownership

- `.themis/core/` is Themis-owned capability content: kernel rules, policies, protocols, templates, adapters, migrations, and deterministic executors.
- `.themis/workspace/` is project-owned content and runtime data: manifest, Context, Specs, Plans, state, runs, evidence, outcomes, and knowledge governance records.
- Core defines capabilities and control rules; it must never store project-specific facts or work artifacts.
- Workspace stores project content; it must not implement control logic.
- Core upgrades must never copy, replace, delete, restore, or otherwise mutate `.themis/workspace/`.
- Workspace or Artifact Schema evolution requires an explicit, user-authorized migration with backup, verification, and rollback.
- Formal project knowledge has one authoritative location: `workspace/context/`. `workspace/knowledge/` stores candidate, review, rejection, and archive governance records, not a second authoritative knowledge base.

## Source of Truth and Lifecycle

Use authority in this order:

1. Current code, configuration, structured artifacts, and observed command output.
2. Persistent Workspace state and recorded evidence.
3. Core policy, protocol, and deterministic tool output.
4. Imported rules and Prompt guidance.
5. Conversation memory or Agent inference.

The default lifecycle is:

```text
Draft → Specified → Planned → Implemented → Verified → Reviewed → Archived
```

- Route from persistent artifacts and machine state, not conversational claims.
- Missing evidence is not success evidence. Inaccessible or inconclusive checks cannot pass.
- Do not claim a lifecycle transition unless persistent state or a deterministic executor records it.
- User approval, Prompt output, or a completed Markdown artifact is evidence for a transition gate; it is not the machine transition itself.
- Any code change invalidates affected Verification evidence and requires relevant Gates to run again.
- Review is read-only and cannot replace command-backed Verification.
- Return to Planning when the Plan is insufficient but work remains inside the approved Spec.
- Return to Specification when requested or discovered work exceeds the approved Spec.

## Three-Layer Execution Model

Every runtime module must separate policy, semantic work, and deterministic operations.

### YAML Policy

- YAML is the single authoritative declaration for step ordering, thresholds, routing conditions, Gates, transition requirements, limits, stable identifiers, and allowed dispositions.
- Prompt files reference YAML policy; they must not duplicate or independently redefine deterministic policy logic.
- Policy identifiers must be stable, ASCII-safe, and suitable for deterministic parsing.

### Prompt

- Prompt templates define each step's purpose, Agent role, semantic reasoning, user interaction, and how to interpret policy or script results.
- Every Prompt must include an `Available Scripts` table with script path, purpose, and fallback when missing.
- Before executing a module, its imported `rules.md` must use explicit `MUST Read` instructions for every required Prompt and policy file.
- Before a Prompt phase uses another template or checklist, it must explicitly require reading that asset; do not rely on model memory or generic knowledge.
- Creative and semantic work remains Prompt-driven: intent discovery, questioning, option analysis, Task decomposition, adversarial scenario generation, review judgment, and knowledge candidate extraction.

### Shell Scripts

- Deterministic, repeatable operations must be implemented as Shell scripts rather than repeated by Agents.
- Script candidates include lifecycle transitions, Gate execution, format validation, policy-derived classification, DAG and coverage validation, file operations, backups, migrations, index updates, and evidence skeleton generation.
- Scripts must be idempotent where applicable: the same input must produce the same result without duplicate side effects.
- Runtime script interfaces should use machine-readable JSON input and output when consumed by Agents.
- Agents must check that a declared script exists before invoking it, parse its real output, and follow the Prompt's declared fallback when it is absent.
- Agents must never invent a script, skip a required script, or fabricate script output.

## Kernel Rules and Loading

- Project `CLAUDE.md` loads `.themis/CLAUDE.themis.md` and the Core Orchestrator through the Init-managed import block.
- The Orchestrator maintains a shallow import graph of concise domain `rules.md` files.
- Imported domain rules define responsibility, inputs, outputs, boundaries, and mandatory on-demand asset reads; detailed procedures belong in Prompt templates.
- Keep imported domain `rules.md` files within the template contract's 50-line budget unless that contract is deliberately revised.
- Do not globally import large Prompt, policy, checklist, or reference files. Domain rules must require them on demand with explicit `MUST Read` instructions.
- Every implemented lifecycle domain must be reachable from the Orchestrator import graph.
- Before invoking a Command, Skill, Agent, adapter, or script, verify that its file or capability exists.
- If a required capability is missing, stay at the current stage, report the missing capability, and do not fabricate state, evidence, or execution results.

## Domain Boundaries

### Specification

- Specification owns intent, scope, assumptions, requirements, Acceptance Criteria, adversarial validation, and explicit approval evidence.
- Every behavior-changing request requires a Spec; low complexity may use a shorter path but must not skip adversarial validation.
- P5 uses five stages: Step 0 Intent Discovery, Step 1 Scope Assessment, Step 2 Context Gathering, Step 3 Design Convergence, and Step 4 Adversarial Validation.
- P5 creates and completes a Draft Spec. It must keep `status: draft`; only a deterministic state executor may record `draft → specified`.
- Acceptance Criteria and adversarial findings require stable identifiers.

### Context

- Context owns validated project facts, provenance, conflict reporting, and freshness; it does not decide requirements or implementation.
- AI may propose knowledge candidates but must not write observational conclusions directly into authoritative Context without governance approval.
- Behavior Maps are derived Context data and require code-evidence anchors. Missing maps fall back to source inspection without presenting low-confidence inference as fact.

### Planning

- Planning turns an approved Spec into bounded Tasks, dependencies, completion standards, evidence requirements, and AC traceability.
- Planning must not modify source code or mark Tasks complete.
- Each behavior-changing Task must identify covered ACs, scope, dependencies, expected evidence, and done conditions.

### Implementation

- Implementation executes one dependency-ready planned Task at a time.
- It must load only the current Task's ACs, constraints, Context, and relevant code.
- Treat the Plan's declared files and behavior boundary as a continuous scope lock; inspect and stop before making an out-of-scope change.
- If the Plan is insufficient but the change remains in Spec, return to Planning. If it exceeds Spec, return to Specification.
- Record Task evidence including Task ID, ACs covered, files changed, change summary, deviations, and completion evidence.
- Implementation does not own Spec or Plan edits, Verification verdicts, or lifecycle state transitions.
- Do not mix unrelated refactors or multiple Tasks into one implementation unit.

### Verification

- Verification owns command-backed Gate facts, failure classification, and durable run evidence; it does not modify implementation code.
- Read configured commands and Gates from `workspace/manifest.yaml` and effective policy.
- Do not invent commands when manifest entries are `null`; report the unavailable Gate according to policy.
- Save exact commands, outputs, status, and unavailable checks under Workspace runs and evidence.

### Review

- Review independently evaluates the Spec, Plan, implementation diff, and Verification evidence.
- Review is read-only with respect to implementation code.
- Missing evidence produces blocked or inconclusive results, never approval.
- Review findings must distinguish severity and link to concrete evidence.

### Attribution and Outcomes

- Attribution records traceable links among Spec, Plan, Task, commit, run, deployment, and outcome.
- It must distinguish measured correlation from causal interpretation and must not rewrite source evidence.

### Knowledge Governance

- Knowledge candidates may come from implementation experience, Verification failures, Review findings, and outcomes.
- Promotion, rejection, revision, deduplication, conflict resolution, and deprecation require governed decisions.
- AI may structure and suggest candidates; formal Context promotion requires human or policy-authorized approval.

## Specialized Agents and Naming

- Use one unique specialized Agent per domain to avoid a god Agent with excessive or unrelated context.
- Domain Agents must respect domain ownership and must not absorb responsibilities assigned to another Agent.
- Deterministic operations remain scripts even when invoked by a specialized Agent.
- Commands, Skills, and specialized Agents use the `Themis-` capability prefix.

## Init, Upgrade, and Migration

- Init validates only Bash, Git, and mikefarah/yq v4. These checks are Init-only and must not be sourced or invoked by Upgrade or installed SDD runtime flows.
- Init installs `.themis`, configures the Workspace manifest, and appends a reversible managed import block to the target project's root `CLAUDE.md`.
- `.themis/CLAUDE.themis.md` is contained guidance. Do not create a root-level `CLAUDE.themis.md` in installed projects.
- Upgrade replaces only Themis-managed content outside `.themis/workspace/` and preserves project guidance bytes.
- Migration is separate from Upgrade and is the only mechanism allowed to transform Workspace or Artifact schemas.
- Migration requires explicit authorization, compatible descriptors, complete backup, deterministic verification, and rollback capability.

## Script Documentation

- Every shell script must include Chinese comments explaining its purpose, operating boundary, and non-obvious behavior.
- Public functions and major validation or control-flow sections must document what they do, expected inputs or outputs where applicable, and why the behavior is necessary.
- Keep comments accurate when implementation changes.
- Maintain Bash 3.2 compatibility for portable repository scripts unless a plan explicitly changes the runtime contract.
- Run Bash syntax checks and ShellCheck for modified shell scripts.

## Verification Expectations

- Extend deterministic template checks and isolated regression fixtures whenever a Core contract gains a required file, identifier, heading, policy shape, import, or line-budget rule.
- Run the affected template, Init, Upgrade, Migration, and module-specific suites after Core changes.
- Finish implementation work with `git diff --check` and inspect the final working tree.
- Do not claim a check passed unless its actual output was observed.
