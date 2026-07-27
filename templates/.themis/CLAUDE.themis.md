# Themis Project Guidance

This Themis-managed guidance defines cross-stage boundaries for the installed project. Detailed project facts and work artifacts remain in `.themis/workspace/`; the project's `CLAUDE.md` imports this file and the Orchestrator directly.

## Installation Boundary

- `.themis/core/` is Themis-owned capability and policy content. Treat it as read-only during project work.
- `.themis/workspace/` is project-owned configuration, context, specifications, state, evidence, outcomes, and knowledge.
- `.themis/core/` and `.themis/workspace/` are not updated or converted in place by this release. Preserve an existing installation rather than running Init over it.
- Files under a Themis source repository's `templates/` tree are installation sources. In an installed project, use the corresponding `.themis/` instance paths.
- Do not edit project `AGENTS.md` or other project guidance to resolve a Themis conflict. Stop and surface the conflicting instructions.

## Source of Truth

Use sources in this order:

1. Current code, configuration, structured artifacts, and command output.
2. Persistent Workspace state and recorded evidence.
3. Core policies, protocols, and deterministic tool results when those tools exist.
4. Imported guidance rules.
5. Conversation memory or Agent inference.

A lower-ranked source must not override a higher-ranked fact. Missing evidence is not evidence of success.

## Lifecycle Routing

The documented default lifecycle is:

```text
Draft → Specified → Planned → Reviewed → Implemented → Verified → Human Acceptance → Summary → Archived
```

Route from existing artifacts rather than from what the conversation claims has happened:

- No approved specification: use Specification.
- Approved specification without an adequate plan: use Planning.
- Current plan without an approved pre-implementation review: use Review.
- Approved review with unfinished tasks: implement only the reviewed scope.
- Implemented work without command-backed evidence: use Verification.
- Passing Verification without human acceptance: request acceptance against the approved Spec, Plan, Review, and Verification evidence.
- Accepted work without a final delivery projection: generate Summary when that capability exists.
- Archive only after acceptance, Summary, required outcomes, and knowledge handling are complete.

Workspace policy or a future deterministic status tool may refine this routing. Do not hand-edit lifecycle state or claim a transition that has not been durably recorded.

## Key Paths

| Purpose | Installed path |
|---|---|
| Core metadata and compatibility | `.themis/core/core.yaml` |
| Project manifest and configured gates | `.themis/workspace/manifest.yaml` |
| Project context | `.themis/workspace/context/` |
| Specifications and plans | `.themis/workspace/specs/` (`spec.yaml` authoritative; `spec.md` review-only) |
| Lifecycle state | `.themis/workspace/state/` |
| Runs and evidence | `.themis/workspace/runs/`, `.themis/workspace/evidence/` |
| Outcomes and knowledge governance | `.themis/workspace/outcomes/`, `.themis/workspace/knowledge/` |

The Orchestrator supplies the always-on routing and module boundaries. Later Themis capabilities may add explicit Commands, Skills, Agents, policies, or deterministic executors; never assume those capabilities exist until their files or tool results are present.
