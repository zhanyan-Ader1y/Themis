# Project

Themis is an SDD Harness framework that installs a local AI coding system into engineering projects and enables governed accumulation of project knowledge.

This file defines repository working conventions for Agents. The canonical Themis design specification is [`docs/design/README.md`](docs/design/README.md); do not duplicate detailed product design here.

## Product Identity

Preserve these four defining characteristics when evaluating plans and changes:

- **Question before Spec**: clarify intent, scope, assumptions, constraints, and acceptance criteria before publishing a Spec.
- **Easier Spec review**: keep the machine-readable semantic source and a concise, deterministic human projection so people can review decisions without reading raw protocol data.
- **Durable autonomous planning**: allow Agent-generated plans, task decomposition, decisions, and evidence requirements to persist as governed project artifacts instead of disappearing with a conversation.
- **An evolving project knowledge base**: turn verified, human-approved learning into traceable project Context through governed knowledge accumulation.

These are product characteristics, not claims that every lifecycle executor is already implemented. Detailed contracts and implementation status remain under [`docs/design/**`](docs/design/README.md).

## Design References

Read the design pages relevant to the task before changing behavior or contracts:

- [Design authority and document status](docs/design/README.md)
- [Design governance and evidence](docs/design/governance.md)
- [Architecture and domain ownership](docs/design/architecture.md)
- [Lifecycle and routing](docs/design/workflow.md)
- [Core and Workspace module index](docs/design/README.md#设计导航)

If implementation, templates, tests, or observed output conflict with the design, report the drift and update the owning design page or plan. Do not claim an unobserved capability exists.

## Plan Execution

- A plan is not implementation authorization. The user must explicitly initiate it.
- The first implementation step is to create or update `docs/plan/<priority>-<slug>/impl.md` with decisions, tasks, target files, and a verification matrix.
- Do not modify that plan's implementation files until the user confirms its `impl.md`.
- Each plan owns its directory and implementation record. Split large work into focused segments in that directory.

## Documentation

- `README.md` is the project introduction and top-level navigation.
- `docs/README.md` is the documentation portal.
- Confirmed design changes must update the owning file under `docs/design/**` in the same change.
- Plans, analysis, templates, policies, prompts, and changelogs may link to design rules but must not become a second normative source.
- Keep implementation status and evidence links accurate. Preserve historical plans; add a superseded note instead of rewriting their original decisions.
- Files under the legacy `docs/core/`, `docs/workspace/`, `docs/workflow.md`, and `docs/runtime-environment.md` paths are compatibility pointers only.
- Keep `AGENTS.md` and `AGENTS.CN.md` semantically synchronized in the same change.
- When handling a Spec, use `workspace/specs/<spec-id>/spec.yaml` as the machine-readable semantic source; `spec.md` is a generated human-review projection and must not be reverse-synced or parsed as machine evidence. See [Specification](docs/design/core/kernel/specification.md).

## No Functional Versions

- Themis modules (Core, Workspace, Artifact, Spec, Context, Planning, Review, Verification, Knowledge, and all future domains) maintain one current contract. Module identifiers and protocol directories must not carry `v1`, `v2`, or any functional version suffix.
- There is no old-module compatibility, no side-by-side versioned schemas, and no conversion path. Convergence replaces the current contract directly.
- External tool versions (Bash 3.2, mikefarah/yq v4) are runtime requirements, not Themis module versions.

## Script Documentation

- Every shell script must include Chinese comments explaining its purpose, operating boundary, and non-obvious behavior.
- Public functions and major validation or control-flow sections must document their behavior and necessary inputs or outputs.
- Keep comments accurate when implementation changes.
- Maintain Bash 3.2 compatibility unless an approved plan changes the runtime contract.
- Run Bash syntax checks and ShellCheck for modified shell scripts.

## Verification

- Extend deterministic template checks and isolated regression fixtures when a Core contract gains a required file, identifier, heading, policy shape, import, or line-budget rule.
- Run affected template, Init, and module-specific suites after Core changes.
- Finish implementation work with `git diff --check` and inspect the final working tree.
- Do not claim a check passed unless its actual output was observed.
