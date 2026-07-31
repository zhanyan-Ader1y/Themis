# Plan 35 Static Verification Evidence

> Date: 2026-07-31
> Scope: replacement Plan 35 Prompt/template/policy/Workspace contracts only
> Result: PASS — dormancy-aware structural revalidation complete; the user explicitly re-accepted replacement Plan 35 on 2026-07-31 and current authority is restored

## 1. Assurance boundary

This verification observes repository text, file layout, declared mappings, route-key uniqueness, and Git diff hygiene. It does not provide or claim:

- Plan 36 strict Schema, canonical serialization, validator, issue taxonomy, semantic oracle, or fixtures;
- Plan 37 evaluator, Invocation host, recorder, digest/write services, command execution, atomicity, or native recovery;
- machine proof that any Source Event, artifact, transition, pointer, attempt, invalidation, termination, or recovery operation has executed.

The checks were run from the repository root against the current dirty `main` working tree. Existing user changes were preserved; no reset, restore, clean, stash, commit, or push was performed.

## 2. Structural contract assertions

A read-only Python assertion script inspected the public Skill, internal Capability contracts, Agent Profiles, sole policy, Global Rule, templates, Workspace scaffold, Approval bindings, invalidation declarations, and unavailable-assurance markers.

Observed output:

```text
PASS public_skills=1 name=themis
PASS capability_contracts=16 complete_contract_shape=16
PASS agent_profiles=4
PASS fixed_capability_scope_profile_mappings=16 writer=themis-impl
PASS route_keys=98 unique=98 complete_status_coverage=true
PASS global_rule=1 intake_first=true copied_route_table=false recovery_closure=true
PASS immutable_paired_families=11 legacy_questioning_artifact=false version_file=false
PASS workspace_family_roots=3 intake_path_declared=true per_round_questioning=true target_recovery=true retention_facts=true
PASS intake_target_operations=3 partial_recovery=true abandonment_action=true
PASS review_feedback_owners=7 current_request_route=true questioning_route=true
PASS sticky_full_policy_guard=true simple_qualified_cannot_bypass=true
PASS approval_bindings=true invalidation_categories=true paired_artifact_contract=true
PASS intake_dormancy disposition_count=4 retention_modes=2 route_count_unchanged=true
PASS completion_retention all_bound_targets=true independent_freeze=true all_target_gate=true preserve_assigned=true
PASS dormant_controls continuations_inactive=true attach=false invocation=false recovery=false reactivation=false mutation=false
PASS dormant_retention immutable_records=7 delete=none cache_cleanup=allowed future_message=new_intake
PASS retention_cross_contracts rule=true public_skill=true workspace=true immutable_decision_unchanged=true
PASS manual_replay_scenarios=16 dormancy_aware=true
PASS acceptance_criteria_rows=32 criterion_31_pass=true criterion_32_reaccepted=true
PASS unavailable_machine_assurances_declared=8
```

The script asserted:

1. `templates/.claude/skills/themis/SKILL.md` is the only public project Skill.
2. `templates/.themis/core/capabilities/` contains exactly sixteen non-README Capability contracts.
3. Every Capability contract declares stable identity, authority scope, fixed Agent Profile, materialization target, inputs, legal statuses, output envelope, permissions, stop conditions, and the prohibition on invoking another Capability or Agent.
4. The four Profile identities are exactly `semantic-readonly`, `independent-checker`, `human-dialogue`, and `implementation-writer`.
5. Capability scope/Profile declarations exactly match the sixteen fixed policy mappings.
6. Only `themis-impl` maps to `implementation-writer`.
7. The observed policy contains 98 route keys, all 98 are unique, and every declared legal Capability/path/profile/status combination has exactly one route. This number is observation output, not product identity.
8. The Global Rule is Intake-first, does not contain a copied route table, does not import sibling domain Rules, and declares exact partial-target, abandonment, and sticky-full recovery controls.
9. `templates/.themis/VERSION` and the legacy mutable `core/templates/questioning.md` are absent.
10. Eleven paired semantic families have both machine-readable and Markdown templates.
11. The fresh Workspace scaffold contains family roots rather than literal example identity directories and records remaining target identities for partial Intake recovery.
12. Intake target operations are exactly `create-lifecycle | update-current-request | no-change`; partial success preserves completed targets and resumes remaining targets only; abandonment requires an explicit host observation.
13. Review Feedback uses the seven approved semantic owners, with explicit routes from Review Dialogue to Current Request Dialogue and Questioning.
14. The simple-qualified route has an explicit sticky-full guard and full-path guard-failure action.
15. Approval binds the Intake assignment decision, Review revision, and pre-Impl baseline.
16. Policy declarations include Plan/Approval/sticky-full invalidation categories.
17. The policy explicitly declares eight Plan 36/37 unavailable-or-forbidden assurance markers and forbids transition claims without observed runtime.
18. Request Intake dispositions remain exactly `open | assigned | rejected | abandoned`; `dormant-read-only` is one of two retention modes and is not a disposition, Capability status, route-key dimension, or additional route.
19. External messages may attach only through active durable Intake continuations; dormant attachment is forbidden and later messages create a new Intake.
20. Observed Summary materialization and lifecycle completion precede retention control; every Intake target bound to the completed lifecycle identity is frozen independently, while whole-Intake dormancy waits for all associated lifecycle-bearing targets.
21. Dormancy preserves disposition `assigned`, deactivates every Intake continuation, forbids Invocation/recovery/reactivation/mutation, retains seven authority-record categories read-only, deletes none, and permits only rebuildable-cache cleanup.
22. The Global Rule, public Skill, Workspace contract, and Templates classification agree on retention ownership; the immutable assignment decision remains unchanged.
23. The replay ledger contains exactly sixteen dormancy-aware scenarios and the acceptance audit contains exactly thirty-two criteria.

## 3. Active-contract drift scan

A classified read-only scan checked active guidance and package contracts for:

- fifteen-Capability claims;
- the former fixed 91-route count;
- positive persistent Specification artifact claims;
- an independent Delivery stage;
- positive claims that validator/evaluator/recorder/deterministic runtime already exists;
- active upgrade or migration support.

Observed output:

```text
PASS authoritative_stale_contract_scan files=96 unexpected_hits=0
PASS paused_plan36_known_drift=5 classification=frozen-rebaseline-input
PASS historical_and_negative_mentions classification=non-authoritative-or-explicit-non-goal
```

### Classified matches

- `docs/plan/36-deterministic-assurance/impl.md:12,75,99,270,286` still describes fifteen Capabilities or a 15/15 mapping. Its status header explicitly pauses the plan and states that the body is retained only as rebaseline input. These five matches are known future rebaseline work, not current Plan 35 authority, and were not patched piecemeal.
- `docs/plan/37-native-runtime/impl.md:20` says it will not create an independent Delivery stage. This is an explicit non-goal.
- `templates/.themis/core/capabilities/README.md:68` names the internal Capability contract file `questioning.md`; the removed mutable artifact template `templates/.themis/core/templates/questioning.md` does not exist.
- Eleven `upgrade`/`migration` matches in active authority files are explicit prohibitions or absence statements. They do not declare support.

Historical specifications, historical implementation plans, and `CHANGES.md` were not treated as current product authority. Their historical terminology was preserved.

## 4. Replay-discovered contract repairs

The first structural pass completed before manual replay. Replay then exposed five active Prompt-contract closure gaps. They were repaired before this final rerun:

1. Intake target operations now use only `create-lifecycle | update-current-request | no-change`; the stale `update-lifecycle` vocabulary was removed.
2. Multi-target assignment now declares per-target continuations/status observations, `open + incomplete` partial state, completed-target preservation, and `resume-remaining-target-operations-only` recovery without rollback.
3. Review Feedback now uses the approved seven semantic owners. Review Dialogue adds explicit `needs-current-request` and `needs-questioning` statuses/routes; Grounding remains an evidence provider, not a feedback owner.
4. The `simple-qualified` route now has a policy guard that forbids simple selection when `full_path_required` is already true and declares the full-path guard-failure action.
5. Explicit host-observed abandonment now has a policy control action and cannot be inferred from silence or represented as a Capability status.

The final assertions and evidence in this document reflect the repaired 98-route contracts and the completed Intake dormancy extension. Dormancy remains outside the route table, so the observed route count and legal-status coverage are unchanged.

## 5. Git diff hygiene

Command:

```bash
git diff --check
```

Observed result:

```text
PASS git_diff_check whitespace_errors=0
```

Git emitted Windows working-copy notices that LF will be replaced by CRLF when Git next touches modified files. The command exited successfully and reported no whitespace-error locations. No line-ending normalization was performed.

## 6. Working-tree scope

`git status --short` confirms that the pre-existing dirty baseline remains present:

- `docs/plan/36-deterministic-assurance/impl.md`;
- `docs/plan/37-native-runtime/impl.md`;
- `docs/plan/80-multi-agent-execution/impl.md`;
- `docs/plan/90-attribution-analytics/impl.md`;
- replacement Plan 35 design and implementation-plan files.

Additional changes are confined to the replacement Plan 35 implementation surface:

- active Plan 35 status and historical-authority declarations;
- the public `themis` Skill;
- internal Capability and Agent Profile contracts;
- sole policy and Global Rule;
- immutable artifact templates;
- Workspace scaffold and module/package guidance;
- product overview.

No commit or push was created. Plan 80 and Plan 90 original bodies remain outside this replacement implementation; only their previously added status/drift declarations remain in the dirty baseline.

## 7. Static conclusion

The observable repository contracts are internally consistent with the approved replacement Plan 35 design:

- external messages enter through immutable Request Intake before lifecycle semantics;
- Current Request semantics are source-bound and explicitly confirmed;
- one policy governs two isolated authority scopes;
- sixteen internal Capabilities use four fixed Profiles;
- Capability results remain proposals until policy-controlled persistence, observation, reread, and pointer update;
- paired semantic artifacts are immutable revisions with separate current pointers;
- Review precedes Impl, Verify is `Impl → independent Verification`, and Summary remains gated by passed Verification plus accepted Human Acceptance;
- Intake and lifecycle failure budgets remain isolated, while Impl/Verification/Acceptance repair share the lifecycle Plan Task budget;
- unavailable deterministic guarantees are stated rather than invented.

This evidence, together with the completed sixteen-scenario ledger in `manual-replay.md` and the thirty-two-criterion matrix in `acceptance-audit.md`, completed the implementation-evidence stages required before re-acceptance. The user explicitly re-accepted replacement Plan 35 on 2026-07-31, so the replacement design is now current product authority.
