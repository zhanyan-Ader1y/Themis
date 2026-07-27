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
- `AGENTS.CN.md` is the Chinese mirror of this contract. Update both files in the same change; if their meanings differ, `AGENTS.md` remains authoritative.

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

## Repository Hierarchy

Use the installed-project hierarchy below. Paths beneath `templates/.themis/` are source templates for these installed locations, not a second runtime hierarchy.

```text
.themis/
├── CLAUDE.themis.md
├── core/
│   ├── kernel/       # domain rules and routing boundaries
│   ├── policies/     # declarative defaults, thresholds, Gates, and dispositions
│   ├── protocols/    # versioned data and tool interface contracts
│   ├── templates/    # artifact skeletons and on-demand Prompt templates
│   ├── adapters/     # normalized interfaces to languages and external tools
│   └── migrations/   # explicit Workspace and Artifact schema transformations
└── workspace/
    ├── manifest.yaml # project identity, paths, commands, Gates, and adapters
    ├── policies/     # project policy overrides allowed by the Core contract
    ├── context/      # sole authoritative project-knowledge tree
    │   ├── catalog.yaml       # sole persistent Context Item registry
    │   ├── .abstract.md       # L1 derived navigation
    │   ├── .overview.md       # L2 derived navigation
    │   ├── architecture/
    │   │   └── behavior-map/ # derived B1/B2/B3 code-behavior Context
    │   ├── domain/           # L3 business rules, invariants, and domain models
    │   ├── engineering/      # L3 project engineering conventions and constraints
    │   ├── decisions/        # L3 durable decisions and rationale
    │   ├── pitfalls/         # L3 verified traps and known failure patterns
    │   ├── glossary/         # L3 project terminology
    │   └── external/         # L3 governed references to external sources
    ├── specs/        # authored Spec, Plan, Review, Verify, and related artifacts
    ├── state/        # machine-readable transitions, task/session state, locks, and Context signals
    ├── runs/         # execution envelopes and durable run verdicts
    ├── evidence/     # proof material or references supporting Gate facts
    ├── outcomes/     # measured post-delivery results
    ├── knowledge/    # candidate, review, action, rejection, and archive governance records
    └── cache/        # disposable Context indexes, bundles, and derived metadata
```

- There is no separate `workspace/domain/`; authoritative domain knowledge belongs in `workspace/context/domain/`.
- `workspace/specs/` stores authored lifecycle artifacts; `workspace/state/` stores machine state. Neither substitutes for the other.
- Runs describe executions, Evidence supports claims, Review makes independent judgments, and Outcomes record real post-delivery results; do not collapse them into one artifact.
- Cache is never authoritative and may be regenerated or deleted without changing project meaning.

## Project-Fact Trust and Lifecycle

Project facts have exactly two trusted roots with distinct authority:

1. Governed active items beneath `workspace/context/` define what the project is intended to mean: business concepts, rules, invariants, terminology, durable decisions, external constraints, and engineering conventions.
2. Current revision-bound code, configuration, schemas, and other versioned implementation artifacts define what the project currently implements.

Neither root globally overrides the other. A claim about intended project meaning must cite a Context ID; a claim about current implementation must cite a repository-relative path plus revision or content digest. If the two conflict, persist a `context_code_drift` signal and leave the dependent conclusion unresolved rather than silently selecting either source. Context without readable code cannot prove implementation, and code without Context cannot prove business intent.

- Specs define approved desired change, scope, and Acceptance Criteria; Plans define task organization and evidence requirements. Neither is a project-fact source.
- State is authoritative only for machine lifecycle and task facts. Runs and Evidence are authoritative only for the commands, observations, Gate results, and verdicts they record. Outcomes are authoritative only for measured post-delivery results.
- Core policies, protocols, rules, Prompts, and deterministic outputs define or execute Themis control contracts; they do not contain project-specific facts.
- Knowledge records are proposals and governance history until an approved action writes a validated Context item.
- Direct external material, conversation, model memory, summaries, search ranking, caches, and Agent inference cannot independently establish project facts. External constraints become trusted only as governed `external_reference` Context items.
- Reusable observations from State, Runs, Evidence, Review, Attribution, or Outcomes must be checked against Context or current code and pass Knowledge Governance before promotion.

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

## Core Module Boundaries

### Kernel Domains

- **Orchestrator** reads durable artifacts and effective policy to select the next eligible domain. It does not perform domain semantics, execute Gates or migrations, edit lifecycle artifacts, or fabricate transitions.
- **Specification** owns intent, root cause, scope, assumptions, requirements, Acceptance Criteria, adversarial validation, and explicit approval evidence. It does not decompose Tasks, modify code, judge Gate results, or record machine transitions.
- **Context** owns validated project facts, provenance, discovery, resolution, conflict reporting, indexing, and freshness. It does not decide requirements, Plans, implementation, or knowledge promotion.
- **Planning** turns an approved Spec into bounded Tasks, dependencies, scope, completion standards, evidence requirements, and AC traceability. It does not modify source code, execute Tasks, or mark them complete.
- **Implementation** executes one dependency-ready Task within a continuous scope lock and records task evidence. Its dedicated P5.9 Core assets remain planned until that plan is approved and implemented.
- **Verification** executes configured Gates, records exact commands and outputs, classifies failures, and persists run evidence and verdicts. It does not modify implementation code or replace Review judgment.
- **Review** independently and read-only evaluates the Spec, Plan, implementation diff, and Verification evidence. It does not execute Gates, repair code, or approve missing evidence.
- **Attribution** links Specs, Plans, Tasks, commits, runs, deployments, and measured outcomes. It does not infer unsupported causality, rewrite source evidence, or route lifecycle stages.
- **Knowledge Governance** manages candidate extraction, duplicate/conflict assessment, review, approval, promotion, rejection, revision, and deprecation. It does not create a second authoritative knowledge store or promote unapproved observations.

### Core Infrastructure

- **Policies** declare stable ordering, thresholds, routing conditions, Gates, limits, and allowed dispositions; they do not execute operations or contain project facts.
- **Protocols** version data shapes, references, and adapter interfaces; they define what valid data looks like, not how semantic decisions are made.
- **Templates** provide initial artifact structures and on-demand Prompt workflows; template instances belong in Workspace and are not overwritten by Core upgrades.
- **Adapters** extract or translate external tool and language facts into normalized protocol results; they report unsupported capabilities and never make domain decisions.
- **Migrations** are the only authorized mechanism for Workspace or Artifact schema transformation; they require explicit authorization, complete backup, deterministic verification, and rollback.
- **Deterministic executors** perform repeatable parsing, validation, classification, file operations, indexing, Gate execution, and state changes. They consume policy, emit machine-readable results, and do not perform open-ended semantic judgment.

## Workspace Module Boundaries

- **Manifest** declares project identity, root, managed paths, configured commands, Gates, context entry points, adapters, and permitted policy overrides; it is configuration, not execution history.
- **Workspace policies** may specialize Core defaults only within declared override rules; they cannot weaken immutable safety, ownership, approval, migration, or evidence requirements.
- **Context** is the sole authoritative project-knowledge tree. Its categories are `architecture/`, `domain/`, `engineering/`, `decisions/`, `pitfalls/`, `glossary/`, and `external/`; these are knowledge classifications, not control modules. Formal knowledge uses L3 Context Items, while directory-level L1 `.abstract.md` and L2 `.overview.md` files are traceable `derived_navigation` projections that must not introduce independent facts.
- **Context Catalog** at `workspace/context/catalog.yaml` is the sole persistent registry for Context Item identity, path, category, scope, authority, status, provenance, digest, freshness, dependencies, and supersession. Other indexes, summaries, and resolved bundles are derived and rebuildable.
- **Specs** stores authored lifecycle artifacts and their attachments. Artifact content is human/Agent-authored intent and evidence; machine lifecycle status remains under State.
- **State** stores machine-readable transitions, active references, Task/session state, retries, locks, and persistent Context missing/conflict/stale/drift signals. State must reference source artifacts and evidence and must not become a parallel requirements or knowledge store.
- **Runs** stores one execution's inputs, effective-policy snapshot, Gate results, and verdict envelope. A Run does not itself prove correctness without Evidence.
- **Evidence** stores or references command output, reports, logs, reviews, drift records, and deployment proof. Evidence is immutable support material and does not make the verdict it supports.
- **Outcomes** records measured delivery results such as success, rework, escaped defects, incidents, and rollback. Outcomes are distinct from pre-delivery Verification verdicts.
- **Knowledge** stores append-only governance workflow records. Only approved promotion writes formal knowledge into Context.
- **Cache** stores disposable indexes, resolved Context snapshots, and derived metadata. Cache loss must not destroy authoritative state or project knowledge.

## Domain Boundaries

### Specification

- Specification owns intent, scope, assumptions, requirements, Acceptance Criteria, adversarial validation, and explicit approval evidence.
- Every behavior-changing request requires a Spec; low complexity may use a shorter path but must not skip adversarial validation.
- P5 uses five stages: Step 0 Intent Discovery, Step 1 Scope Assessment, Step 2 Context Gathering, Step 3 Design Convergence, and Step 4 Adversarial Validation.
- P5 creates and completes a Draft Spec. It must keep `status: draft`; only a deterministic state executor may record `draft → specified`.
- Acceptance Criteria and adversarial findings require stable identifiers.

### Context

- Context owns governed project meaning, provenance, Catalog registration, progressive discovery, resolution, conflict reporting, and freshness; it does not decide requirements, Plans, implementation, or knowledge promotion.
- Knowledge category and disclosure depth are orthogonal. Context uses `L1 Abstract → L2 Overview → L3 Detail`; L1/L2 are citation-backed navigation projections, and only active L3 items or current code-derived facts may independently support project-fact claims.
- Spec-related business lookup starts with explicit Context IDs, then filters `domain/` by bounded context, entity, operation, and state before loading L1, relevant L2, and selected L3. Supporting lookup proceeds through Glossary, Decisions, External, Pitfalls, Architecture, Behavior Map, and current code as needed.
- Context resolution produces a disposable, traceable Context Bundle and persists missing, stale, Context conflict, or Context/code drift signals under State. Bundles, summaries, search rankings, and cache indexes are never a third fact source.
- AI may propose knowledge candidates but must not write observational conclusions directly into authoritative Context without governance approval.
- Behavior Maps are derived code Context and use `B1 System`, `B2 Behavior Unit`, and `B3 Evidence` to avoid collision with Context disclosure layers. Only current, revision-bound B3 anchors may support code-fact claims; all other map content is navigation and must fall back to source inspection.

### Behavior Map and Change Localization

P6 is a confirmed design contract but remains unimplemented until its own `impl.md` is approved and executed.

- Behavior Maps are derived, regenerable Context owned by Context governance and stored only beneath `workspace/context/architecture/behavior-map/`; they are not manually promoted Knowledge and are never a second source-code authority.
- Inputs are scoped source, configuration, schemas, routes, build metadata, manifest include/exclude rules, the source revision or content digests, and real adapter capability results. Localization additionally consumes approved ACs and relevant Context.
- The generated model uses `B1 System` for boundaries and lifecycle paths, `B2 Behavior Unit` for responsibilities, inputs, outputs, state, and relationships, and `B3 Evidence` for revision-bound files, symbols, branches, side effects, paths, and anchors. B1/B2 are derived navigation; only current supported B3 facts may support implementation claims.
- Generated artifacts also include a symbol/function inventory, normalized relation or call graph, anchor index, and metadata for schema, source revision, adapter versions, language coverage, confidence, generation time, and freshness.
- Every factual prose claim must cite stable evidence-anchor IDs. An anchor records repository-relative path, symbol or artifact kind, source range, source revision or digest, extraction method, relationship type, and confidence. Line numbers and snippets aid navigation but are not durable identity.
- Unsupported statements must be marked `hypothesis` or `unknown`, never fact. Language adapters must distinguish parsing, symbol inventory, relationship extraction, call-graph support, and schema/SQL lineage rather than claiming blanket language support.
- Freshness uses `current`, `stale`, `unknown`, or `unsupported`. A changed anchor or relevant dependency invalidates affected entries; inability to calculate impact yields `unknown`. P6 initially uses manual regeneration plus staleness marking, not automatic incremental synchronization.
- Missing, stale, unknown, or unsupported map coverage requires direct source inspection. Consumers must not present low-confidence inference as verified project fact.
- Change Localization produces advisory traceability in the form `AC → behavior unit → candidate file/symbol → Task → Gate`. Each candidate records role, rationale, anchor IDs, source revision, confidence, and unresolved areas.
- Planning consumes localization read-only and remains responsible for Task scope; localization cannot edit code, expand a Plan, or mark work complete. Verification may use anchors to discover relevant checks, but anchors are not Gate evidence or verdicts.
- Adapter extraction is deterministic where supported; LLM-assisted behavior grouping and explanation are semantic, provenance-preserving steps. Unsupported dynamic dispatch, reflection, generated code, or binary-only behavior must be reported rather than invented.
- P6 excludes an interactive UI, guaranteed resolution of runtime-only behavior, autonomous Plan/code modification, Gate verdict generation, and automatic full resynchronization.

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
