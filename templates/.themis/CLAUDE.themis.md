# Themis Project Guidance

This managed guidance defines cross-stage boundaries for an installed project. Detailed module contracts live in `.themis/core/**/README.md`; project facts and work artifacts remain in `.themis/workspace/`.

## Installation Boundary

- `.themis/core/` is Themis-owned and read-only during normal project work.
- `.themis/workspace/` is project-owned configuration, Context, Specs/Plans, state, evidence, outcomes, and knowledge governance.
- Preserve an existing `.themis/`. Do not run Init over it, delete it as an update workaround, or copy a source template over it.
- Current source templates describe a fresh-only target and may be installed only by an actually available approved installer.
- Do not edit project guidance to hide a Themis conflict; stop and surface it.

## Product Flow

Themis must preserve: questioning before Spec, lightweight Spec Review, durable Agent Plans, and a governed evolving project knowledge base.

```text
Draft → Specified → Planned → Reviewed → Implemented → Verified
      → Human Acceptance → Summary → Archived
```

Review is before Implementation. Verification is after Implementation. Summary is generated only after current Verification `pass` and Human Acceptance `accepted`.

## Source of Truth

- Governed Context and approved design artifacts describe intended project facts.
- Current code, configuration, Schema, and observed command output describe current implementation.
- Workspace state and evidence describe durably recorded workflow facts.
- Core policies, Protocols, and observed deterministic results govern Themis operations.
- Conversation memory and Agent inference are discovery aids only.

When intended and current facts disagree, preserve both and surface drift/conflict. Missing evidence is never success.

## Lifecycle Routing

Route from existing artifacts, not conversation claims:

- unresolved intent or no current approved Spec → Specification;
- approved Spec without adequate durable Plan → Planning;
- current Plan without pre-Implementation approval → Review;
- current approved Review with ready Task → Implementation;
- implemented work without sufficient Gate evidence → Verification;
- current Verification `pass` without acceptance → Delivery acceptance;
- accepted work without Summary → Delivery summary;
- reusable evidence-backed lesson → Knowledge governance;
- archive only after Acceptance, Summary, and required Knowledge disposition.

Attribution analytics is optional and never a core gate.

## Safe Degradation

Before invoking a Command, Skill, Agent, Adapter, validator, or runtime operation, confirm it exists. If absent, keep the semantic stage, report `not_run`/`unavailable`/`pending`, and never invent output, evidence, verdicts, transitions, locks, transactions, promotion, or recovery.

## Key Paths

| Purpose | Installed path |
|---|---|
| Package contracts and Core assets | `.themis/core/` |
| Project manifest | `.themis/workspace/manifest.yaml` |
| Formal project knowledge | `.themis/workspace/context/` |
| Specifications and Plans | `.themis/workspace/specs/` |
| State and cursors | `.themis/workspace/state/` |
| Runs and evidence | `.themis/workspace/runs/`, `.themis/workspace/evidence/` |
| Outcomes and knowledge governance | `.themis/workspace/outcomes/`, `.themis/workspace/knowledge/` |
