# Plan 35 Acceptance Audit

> Date: 2026-07-31
> Authority: `docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement-design.md`
> Scope: thirty-two replacement Plan 35 acceptance criteria
> Result: 32 PASS, 0 implementation GAP

## 1. Audit method

Each criterion was mapped to current repository contracts and, where behavioral sequencing matters, to one or more scenarios in `manual-replay.md`. `static-verification.md` supplies observed structural assertions. PASS means the replacement Plan 35 Prompt/template/policy/Workspace contract is present and manually closed; it does not mean unavailable Plan 36/37 machine guarantees executed.

## 2. Acceptance matrix

| # | Status | Contract evidence | Replay / observed evidence |
|---|---|---|---|
| 1 | PASS | `request-intake-source-event.yaml`; Global Rule **Intake first** records exact original bytes before semantic handling | Replay 1, 5, 6; static `intake_first=true` |
| 2 | PASS | `transitions.yaml` attachment sources permit only active durable Intake confirmation or restart/unblock continuation; dormant Intake, wording, adjacency, and chat inference are forbidden | Replay 1, 2, 11, 15, 16 |
| 3 | PASS | policy and Rule isolate `request-intake` from `lifecycle`; Rule forbids provisional lifecycle before materialized assignment | Replay 1, 3, 4 |
| 4 | PASS | Source Event template records raw bytes path/digest/length with `normalization: none`; claim templates record UTF-8 byte range and fragment digest | Replay 1, 5; static template assertions |
| 5 | PASS | `current-request.yaml/.md` require confirmed claim revisions and exact Source Event fragments | Replay 1, 5 |
| 6 | PASS | Intake proposal declares changed-only claim/assignment items; decision requires `confirm | correct | keep-ambiguous` per item | Replay 1, 5 |
| 7 | PASS | policy `no-change` resumes original durable dialogue continuation; Rule explicitly forbids redundant confirmation | Replay 2, 6 |
| 8 | PASS | Intake decision supports per-target `create-lifecycle | update-current-request | no-change`, target observations, remaining identities, and resume-only recovery; completion freezes each bound target and whole-Intake dormancy waits for all associated lifecycles | Replay 3, 4, 14; static `completion_retention` assertions |
| 9 | PASS | `core/capabilities/` contains exactly sixteen contracts including Current Request Dialogue; the original fifteen retain their semantic roles | Static `capability_contracts=16` and fixed mapping assertion |
| 10 | PASS | Current Request Dialogue maps to `request-intake + human-dialogue`; Profile returns proposals only and cannot write governance authority | Replay 1, 2, 5; static fixed mapping |
| 11 | PASS | exactly four Profile contracts: `semantic-readonly`, `independent-checker`, `human-dialogue`, `implementation-writer`; no governance writer | Static `agent_profiles=4`; only `themis-impl` is writer |
| 12 | PASS | public `themis` Skill and Global Rule intercept every external message, then restore the exact durable continuation | Replay 5, 6, 11 |
| 13 | PASS | one public `templates/.claude/skills/themis/SKILL.md`, one Global Rule, one `transitions.yaml` | Static `public_skills=1`, `global_rule=1`; active guidance |
| 14 | PASS | policy declares route key `capability + selected_path + profile + status`; authority scope is fixed outside the key | Static `route_keys=98 unique=98 complete_status_coverage=true` |
| 15 | PASS | Rule requires validation, exactly-one-route match, control action, complete persistence, observation, reread, immutable observation, then pointer update | Replay 1, 4, 9, 10 |
| 16 | PASS | Templates README and Rule invalidate a pair if either component or identity/digest/scope/binding is invalid | Replay 9; static `paired_artifact_contract=true` |
| 17 | PASS | eleven paired families use opaque immutable revision directories and separate current pointer observations; Intake dormancy is a separate operational retention fact referencing immutable decisions/completions | Replay 7, 9, 14; static `retention_cross_contracts=true` |
| 18 | PASS | `questioning-round.yaml/.md` is a per-round immutable pair; unanswered questions stay in proposal/continuation state | Replay 5; static `per_round_questioning=true` and legacy artifact absent |
| 19 | PASS | Templates and Workspace contracts distinguish attempt identity, operation/revision identity, current pointer, incomplete operation, and post-completion retention fact | Replay 3, 4, 9, 10, 12, 14 |
| 20 | PASS | Workspace README restricts lifecycle state to refs/control facts and Intake state to control/retention facts; neither may copy or rewrite Current Request, Plan, design, Acceptance, Source Event, or decision semantics | Replay 14, 15; static `retention_facts=true` and immutable-decision assertion |
| 21 | PASS | Review Projection is a checked-Plan projection; Approval binds Plan, shown projection, Review Check, assignment, claims, and pre-Impl baseline | Replay 7, 14; static `approval_bindings=true` |
| 22 | PASS | Review Feedback is an independent paired revision with exactly seven semantic owners; Review Dialogue cannot patch Plan/projection | Replay 7; static `review_feedback_owners=7` |
| 23 | PASS | lifecycle contract fixes Verify as `themis-impl → independent themis-verification`; separate Invocations share Plan Task Execution Identity/budget | Replay 12; orchestrator README invariants |
| 24 | PASS | Verification, Human Acceptance, and Summary are distinct paired families; gates require current passed Verification then accepted Acceptance, and only observed Summary/completion may trigger route-preserving Intake retention | Replay 12, 14; separate templates and policy post-control |
| 25 | PASS | policy/Rule isolate Intake and lifecycle budgets and terminate the corresponding Execution Identity on the third counted failure | Replay 11, 12, 16 |
| 26 | PASS | Failure Learning supports exactly one bound scope per Invocation, is candidate-only, non-blocking, and non-recursive | Replay 11, 13 |
| 27 | PASS | invalid-result policy fails closed for duplicate, late, stale, wrong-Profile, wrong-scope, incomplete, or binding-invalid results | Replay 10 |
| 28 | PASS | recovery rereads active durable scope/pointer/marker/artifact/attempt/Git facts and resumes only from the last proven gate; dormant Intake records are historical evidence only and cannot recover/reactivate | Replay 4, 9, 15, 16 |
| 29 | PASS | `full_path_required` is lifecycle-local, false-to-true-only, preserved across re-entry/restart/resume/retry, and guards `simple-qualified` | Replay 8; static `sticky_full_policy_guard=true` |
| 30 | PASS | Rule and package status explicitly reserve strict assurance for Plan 36 and runtime execution for Plan 37; Plan 80/90 are absent/non-gating | Every replay lists missing assurances; static `unavailable_machine_assurances_declared=8` |
| 31 | PASS | dormancy-aware structural assertions, classified drift scan, Git hygiene, protected working-tree observation, and all sixteen manual scenarios were rerun and recorded | `static-verification.md`; `manual-replay.md` |
| 32 | PASS | user reviewed the completed dormancy-aware evidence and explicitly re-accepted replacement Plan 35 on 2026-07-31 | current product authority restored; Plan 36 may now be fully rebaselined but still requires separate approval |

## 3. Cross-cutting verification

Observed structural results are recorded in `static-verification.md`:

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
PASS unavailable_machine_assurances_declared=8
PASS authoritative_stale_contract_scan files=96 unexpected_hits=0
PASS git_diff_check whitespace_errors=0
PASS working_tree_dirty_entries=91 protected_baseline_present=true
```

The manual replay records all required facts for sixteen scenarios: initial durable state, selected Capability/Profile/scope, proposed status, route, control action, materialization target, pointer/gate, invalidation, failure class, and unavailable machine guarantees.

## 4. Audit conclusion

Replacement Plan 35 has no remaining Prompt-contract implementation GAP against criteria 1–32. Its implementation surface is structurally consistent, the discovered replay gaps were repaired, all sixteen required scenarios have a declared fail-closed route, and the user explicitly completed the re-acceptance gate on 2026-07-31.

Criterion 32 is complete: the user reviewed the completed evidence and explicitly re-accepted replacement Plan 35 on 2026-07-31. The replacement contract is now current product authority. This does not approve Plan 36; it only permits a full Plan 36 rebaseline followed by separate review and approval.
