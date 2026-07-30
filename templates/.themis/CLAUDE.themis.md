# Themis Project Guidance

This managed guidance defines the installed project's cross-stage control boundary. The only permanently loaded lifecycle logic is `.themis/core/kernel/orchestrator/rules.md`. Claude Code exposes one public project Skill at `.claude/skills/themis/SKILL.md`; semantic contracts and execution permissions remain internal under `.themis/core/capabilities/` and `.themis/core/agent-profiles/`.

## Installation Boundary

- `.themis/core/` is Themis-owned and read-only during normal project work.
- `.themis/workspace/` is project-owned lifecycle records, Context, evidence, outcomes, and knowledge governance.
- Preserve an existing `.themis/` byte-for-byte. Do not run Init over it, delete it as an update workaround, or copy a source template over it.
- Source templates describe a fresh-only target and may be installed only by an actually available approved installer.
- Do not edit project guidance to hide a Themis conflict; stop and surface it.

## Product Flow

Themis preserves questioning before detailed design, low-burden Plan Review, durable Agent Plans, and a governed evolving project knowledge base.

```text
Current Request
→ Questioning
→ Complexity Assessment
   ├─ simple → Simple Plan → Lightweight Plan Check
   └─ full   → temporary Specification → Planning → Full Plan Check
→ Review Projection → Review Check → Human Review → Review Approval
→ Verify [Impl → independent Verification]
→ Human Acceptance
→ Summary
→ optional governed knowledge candidates
```

The two paths differ only before the unified Plan is checked. Review always happens before project implementation. Summary is allowed only after current Verification `passed` and Human Acceptance `accepted`.

## Authority Model

- Current Request Revision governs the current delivery target.
- Governed design constraints constrain acceptable solutions but do not rewrite the request or prove implementation facts.
- Code, configuration, Schema, and observed executable behavior are the only sources of current implementation facts.
- Temporary Specification is a full-path handoff, not a persisted authority or fact source.
- The checked and explicitly approved unified Plan is the execution contract.
- Workspace state and evidence prove lifecycle events only when the responsible operation was observed.
- Documentation, Context, Themico, experience, Plans, summaries, Agent inference, and conversation memory may provide guidance or lookup leads but cannot replace direct current implementation evidence.

When sources disagree, preserve the disagreement and return it to the owning Capability. Missing evidence is never success.

## Control Architecture

```text
public themis Skill
→ Global Control Rule
→ transitions.yaml selects one internal Capability
→ fixed Agent Profile
→ one temporary Agent invocation
→ validate Capability Invocation Result
→ match one legal route and execute its generic action
```

- `transitions.yaml` is the sole `capability + selected_path + profile + status` route source.
- Fifteen internal Capabilities own semantic judgments; they are not public Skills or persistent Agents.
- Four Agent Profiles constrain permission and isolation only; they do not own semantics or routing.
- One invocation loads exactly one Capability and its fixed Profile. Capability-to-Capability, Agent-to-Agent, shared memory, voting, and consensus are forbidden.
- Only `implementation-writer` may modify project implementation. Independent checkers and Verification are read-only.
- The control plane routes only from legal structured statuses and current bindings; diagnostics and `recommended_route` are advisory.

## Review and Approval

`review.md` is a read-only compression of a checked Plan, not an execution input. It presents an optional flow/sequence Overview and high-impact review items from abstract to concrete.

Human feedback is handled through the internal Review Dialogue Capability and routed to the semantic owner. Neither dialogue nor the reviewer directly edits Plan or `review.md`. Explicit overall approval is recorded separately and binds the Current Request, Questioning round, design constraints, Assessment, path, Plan, checks, projection, and implementation baseline.

Any bound input change invalidates Approval. Plan-authorized implementation delta does not invalidate it by itself; unauthorized external drift does.

## Verify, Acceptance, and Summary

- Impl executes one dependency-ready approved Plan task and records actual delta; it cannot declare Verification success.
- Verification independently reads the implementation and records actual commands, observations, evidence, coverage, limitations, and verdict.
- Impl and Verification use different Invocation Identities but share one Plan task identity and cumulative three-failure budget.
- Human Acceptance records the user's observed result only after Verification passed.
- Summary describes actual delivered behavior only after Acceptance is accepted.
- Failure Learning and Summary may produce governed candidates, but candidates are never published automatically and never alter the completed lifecycle result.

## Write Isolation and Interruption

A mutating invocation binds lifecycle, Task Execution, Invocation, worktree, allowed paths, pre-Impl baseline, and expected write state. Concurrent writers require exclusive worktrees. If exclusive ownership is unavailable, use one serial writer or stop fail closed.

Before writing, revalidate bindings, path, baseline, and expected state. Where applicable, complete a same-directory temporary write before atomically replacing one target. Critical multi-step writes require completion or incomplete markers and post-write reread of files, Git status/diff, and records.

After interruption, reread actual state and continue only from the last proven gate. Do not infer success from partial files and do not claim cross-worktree locks, general transactions, rollback journals, automatic recovery, cross-worktree merge, or conflict adjudication.

## Sticky Full Path and Failure Limit

When a simple-path Capability returns `escalate-full` or exposes hidden requirement, contract, permission, data, state, cross-module, or design complexity, set `full_path_required = true`, invalidate quick-path downstream results, and rerun the full Specification → Planning → Review path. The flag never clears within the lifecycle.

A Task Execution Identity has at most three counted failures. Agent/tool/command/result-contract failures and evidence-backed implementation defects count; semantic routes do not. Each counted failure may trigger non-blocking Failure Learning. The third failure terminates the same identity and forbids a fourth attempt.

## Safe Degradation

Before invoking a Capability, Agent, command, recorder, validator, digest operation, installer, or runtime operation, confirm it exists and observe its result. If absent, remain at the current proven gate and report exactly what is unavailable.

Never invent artifacts, evidence, digests, currentness, transitions, worktree isolation, atomic replacement, completion, invalidation, attempts, Approval, or success. A Rule, Capability, Profile, policy, template, directory, or example does not prove deterministic enforcement exists.

## Key Paths

| Purpose | Installed path |
|---|---|
| Public entry | `.claude/skills/themis/SKILL.md` |
| Global Control Rule | `.themis/core/kernel/orchestrator/rules.md` |
| Sole route policy | `.themis/core/policies/transitions.yaml` |
| Internal semantic contracts | `.themis/core/capabilities/` |
| Fixed permission contracts | `.themis/core/agent-profiles/` |
| Project manifest | `.themis/workspace/manifest.yaml` |
| Governed project Context | `.themis/workspace/context/` |
| Request, Questioning, Plan, Review, Approval | `.themis/workspace/changes/<lifecycle-id>/` |
| Lifecycle state and interruption records | `.themis/workspace/state/<lifecycle-id>/` |
| Invocations and direct evidence | `.themis/workspace/runs/<lifecycle-id>/`, `.themis/workspace/evidence/<lifecycle-id>/` |
| Acceptance and Summary | `.themis/workspace/outcomes/<lifecycle-id>/` |
| Knowledge candidates and disposition | `.themis/workspace/knowledge/` |

Attribution analytics remains optional post-delivery observation and is never a lifecycle gate.
