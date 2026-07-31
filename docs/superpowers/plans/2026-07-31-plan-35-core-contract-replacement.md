# Plan 35 Core Contract Replacement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the invalidated lifecycle-first Plan 35 contracts with the approved Intake-first, dual-authority, sixteen-Capability Prompt contract and produce static and manual-replay evidence for user re-acceptance.

**Architecture:** One public `themis` Skill and one always-loaded Global Rule interpret one `transitions.yaml` policy across isolated `request-intake` and `lifecycle` authority scopes. External messages first become immutable Source Events; user-confirmed source-bound claims may then materialize lifecycle Current Request revisions. Capability results are proposals until policy-selected control actions persist complete immutable records, reread them, and update separate current pointers.

**Tech Stack:** Markdown and YAML Prompt contracts, Claude project Skills, Themis template Workspace scaffold, Python standard-library assertions for Plan-35-only static checks, and documented manual policy replay.

## Global Constraints

- Work in the current dirty `main` checkout and preserve every pre-existing uncommitted change.
- Do not create or enter a worktree; the user explicitly authorized in-place implementation.
- Do not commit, amend, push, reset, restore, clean, stash, or otherwise discard user work.
- Do not implement a Plan 36 strict Schema, canonicalizer, validator, issue taxonomy, semantic oracle, or fixture corpus.
- Do not implement a Plan 37 Go runtime, recorder, evaluator, digest service, command runner, write primitive, installer, or host adapter.
- Do not add compatibility, upgrade, migration, functional module versions, Shell fallback, or a second policy.
- Keep exactly one public `themis` Skill, one Global Rule, one `transitions.yaml`, sixteen internal Capability identities, and four Agent Profiles.
- Treat every Capability result as proposed output until a policy-selected control action has a complete observed persist-and-reread result.
- Preserve the original bodies of Plan 80 and Plan 90; their existing launch-time rebaseline declarations are not part of this implementation.
- Plan 35 remains unaccepted until the user reviews actual static and replay evidence and explicitly re-accepts it.

---

### Task 1: Rebase Plan Status and Historical Authority

**Files:**
- Modify: `docs/plan/35-core-prompt-flow/impl.md`
- Modify: `docs/plan/README.md`
- Modify: `docs/plan/36-deterministic-assurance/impl.md`
- Modify: `docs/plan/37-native-runtime/impl.md`
- Modify: `docs/superpowers/specs/2026-07-29-plan-35-core-prompt-flow-design.md`
- Modify: `docs/superpowers/specs/2026-07-30-plan-35-policy-capability-execution-design.md`
- Modify: `docs/superpowers/plans/2026-07-30-plan-35-policy-capability-execution.md`
- Modify: `README.md`

**Interfaces:**
- Consumes: approved replacement design `docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement-design.md`.
- Produces: one active Plan 35 authority pointer, explicit historical supersession markers, and paused Plan 36/37 status without redesigning their bodies.

- [ ] **Step 1: Capture the protected baseline**

Run:

```bash
git status --short
```

Save the output for the final changed-file audit. Do not modify, stage, or delete any listed path merely because it predates this implementation.

- [ ] **Step 2: Replace the active Plan 35 implementation plan**

Rewrite `docs/plan/35-core-prompt-flow/impl.md` to describe the replacement design, the nine implementation tasks in this plan, the 32 acceptance criteria, the static checks, the sixteen manual replay scenarios, and the final explicit user re-acceptance gate. Remove active lifecycle-first, fifteen-Capability, permanent route-count, mutable Questioning, and Markdown-only authority claims.

- [ ] **Step 3: Update active plan sequencing**

Change `docs/plan/README.md` so the active order is:

```text
replacement Plan 35 implementation and evidence
→ explicit Plan 35 re-acceptance
→ full Plan 36 rebaseline and separate approval
→ Plan 36 implementation and acceptance
→ Plan 37 rebaseline and separate approval
```

Keep Plan 80 and Plan 90 optional and subject to one launch-time rebaseline.

- [ ] **Step 4: Pause Plan 36 and Plan 37 without redesigning them**

Add or update only their status/rebaseline notices so neither can start until replacement Plan 35 is explicitly re-accepted. Do not introduce replacement Plan 35 semantics into their main task bodies.

- [ ] **Step 5: Mark historical Plan 35 documents as superseded**

Add a short top-level notice to each former design and implementation plan stating that it is retained for history, is not current authority, and has been replaced by `docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement-design.md`. Do not rewrite historical content.

- [ ] **Step 6: Point the root product overview to the replacement design**

Update `README.md` so its Plan 35 design link resolves to the replacement design and its product flow starts with Intake rather than lifecycle creation.

- [ ] **Step 7: Verify status and authority references**

Run:

```bash
py -3 - <<'PY'
from pathlib import Path
root = Path('.')
replacement = 'docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement-design.md'
active = (root / 'docs/plan/README.md').read_text(encoding='utf-8')
assert replacement in active
assert 'Plan 36' in active and 'Plan 37' in active
for rel in [
    'docs/superpowers/specs/2026-07-29-plan-35-core-prompt-flow-design.md',
    'docs/superpowers/specs/2026-07-30-plan-35-policy-capability-execution-design.md',
    'docs/superpowers/plans/2026-07-30-plan-35-policy-capability-execution.md',
]:
    text = (root / rel).read_text(encoding='utf-8')
    assert replacement in text
print('PASS: active authority and historical supersession are explicit')
PY
```

Expected: `PASS: active authority and historical supersession are explicit`.

---

### Task 2: Establish Intake and Immutable Artifact Templates

**Files:**
- Modify: `templates/.themis/core/templates/README.md`
- Delete: `templates/.themis/core/templates/questioning.md`
- Create: `templates/.themis/core/templates/request-intake-source-event.yaml`
- Create: `templates/.themis/core/templates/request-intake-proposal.yaml`
- Create: `templates/.themis/core/templates/request-intake-decision.yaml`
- Create: `templates/.themis/core/templates/current-request.yaml`
- Create: `templates/.themis/core/templates/current-request.md`
- Create: `templates/.themis/core/templates/questioning-round.yaml`
- Create: `templates/.themis/core/templates/questioning-round.md`
- Create: `templates/.themis/core/templates/grounding.yaml`
- Create: `templates/.themis/core/templates/complexity-assessment.yaml`
- Create: `templates/.themis/core/templates/plan.yaml`
- Modify: `templates/.themis/core/templates/plan.md`
- Create: `templates/.themis/core/templates/plan-check.yaml`
- Create: `templates/.themis/core/templates/review.yaml`
- Modify: `templates/.themis/core/templates/review.md`
- Create: `templates/.themis/core/templates/review-check.yaml`
- Create: `templates/.themis/core/templates/review-approval.yaml`
- Modify: `templates/.themis/core/templates/review-approval.md`
- Create: `templates/.themis/core/templates/review-feedback.yaml`
- Create: `templates/.themis/core/templates/review-feedback.md`
- Create: `templates/.themis/core/templates/impl-result.yaml`
- Modify: `templates/.themis/core/templates/impl-result.md`
- Create: `templates/.themis/core/templates/verification.yaml`
- Modify: `templates/.themis/core/templates/verification.md`
- Create: `templates/.themis/core/templates/acceptance.yaml`
- Modify: `templates/.themis/core/templates/acceptance.md`
- Create: `templates/.themis/core/templates/summary.yaml`
- Modify: `templates/.themis/core/templates/summary.md`
- Create: `templates/.themis/core/templates/failure-learning.yaml`
- Modify: `templates/.themis/core/templates/failure-learning.md`

**Interfaces:**
- Consumes: replacement design sections for Source Events, claims, materialization, paired artifacts, Questioning rounds, Review/Approval, Verify, Acceptance, Summary, and Failure Learning.
- Produces: Prompt-level record structures used by Capability contracts, Workspace layout, policy control actions, and manual replay. These files are examples/contracts, not strict Plan 36 Schemas.

- [ ] **Step 1: Define Source Event and Intake records**

Create templates that preserve original Source Event bytes and record identity, observed byte length, content digest placeholder, transport metadata, and durable Intake attachment reason. Proposal records must contain changed-only claim/assignment diffs, per-item allowed dispositions, original dialogue continuation, and full diff digest. Decision records must contain confirmed per-item dispositions, assignment targets, partial materialization progress, and stable decision identity.

- [ ] **Step 2: Define source-bound Current Request revisions**

Create paired `current-request.yaml` and `current-request.md`. The machine record must own revision identity, lifecycle identity, Intake decision ref, claim revision refs, content digest, disposition/currentness, materialization observation, and separate pointer expectations. The Markdown half must render only confirmed claims and exact Source Event fragment references.

- [ ] **Step 3: Replace single-file Questioning with per-round revisions**

Delete `questioning.md`. Create `questioning-round.yaml` and `questioning-round.md` containing previous round, question proposal/continuation, answer Source Event refs, post-answer Current Request revision, Why/abstract What result, content digest, and materialization observation. State that unanswered questions remain proposal/continuation state and do not form a completed round.

- [ ] **Step 4: Add structured-only result records**

Create Prompt-level structures for Grounding, Complexity Assessment, Plan Check, and Review Check. Each must bind authority scope, Execution/Invocation identity, current input refs, Capability/Profile, legal status, evidence refs, and observed materialization. They must not include Markdown as a second authority component.

- [ ] **Step 5: Pair lifecycle semantic artifacts**

Add machine records and align Markdown halves for Plan, Review Projection, Review Approval, Review Feedback, Impl Result, Verification, Human Acceptance, Summary, and Failure Learning. Every pair must declare that absence or mismatch of either component invalidates the entire logical revision and that current pointer update is separate from revision creation.

- [ ] **Step 6: Document artifact classes and immutability**

Rewrite `templates/README.md` to distinguish paired semantic artifacts, structured-only semantic records, operational/evidence records, and read-only projections. Explicitly separate artifact revision, attempt, current pointer, and incomplete operation.

- [ ] **Step 7: Verify template families**

Run:

```bash
py -3 - <<'PY'
from pathlib import Path
base = Path('templates/.themis/core/templates')
required = {
    'request-intake-source-event.yaml', 'request-intake-proposal.yaml',
    'request-intake-decision.yaml', 'current-request.yaml', 'current-request.md',
    'questioning-round.yaml', 'questioning-round.md', 'grounding.yaml',
    'complexity-assessment.yaml', 'plan.yaml', 'plan.md', 'plan-check.yaml',
    'review.yaml', 'review.md', 'review-check.yaml', 'review-approval.yaml',
    'review-approval.md', 'review-feedback.yaml', 'review-feedback.md',
    'impl-result.yaml', 'impl-result.md', 'verification.yaml', 'verification.md',
    'acceptance.yaml', 'acceptance.md', 'summary.yaml', 'summary.md',
    'failure-learning.yaml', 'failure-learning.md',
}
missing = sorted(name for name in required if not (base / name).is_file())
assert not missing, missing
assert not (base / 'questioning.md').exists()
for stem in ['current-request', 'questioning-round', 'plan', 'review', 'review-approval',
             'review-feedback', 'impl-result', 'verification', 'acceptance', 'summary',
             'failure-learning']:
    assert (base / f'{stem}.yaml').is_file()
    assert (base / f'{stem}.md').is_file()
print('PASS: immutable template families and per-round Questioning are present')
PY
```

Expected: `PASS: immutable template families and per-round Questioning are present`.

---

### Task 3: Implement Sixteen Capability and Four Profile Contracts

**Files:**
- Create: `templates/.themis/core/capabilities/current-request-dialogue.md`
- Modify: `templates/.themis/core/capabilities/README.md`
- Modify: all fifteen existing files under `templates/.themis/core/capabilities/*.md`
- Modify: `templates/.themis/core/agent-profiles/README.md`
- Modify: `templates/.themis/core/agent-profiles/semantic-readonly.md`
- Modify: `templates/.themis/core/agent-profiles/independent-checker.md`
- Modify: `templates/.themis/core/agent-profiles/human-dialogue.md`
- Modify: `templates/.themis/core/agent-profiles/implementation-writer.md`

**Interfaces:**
- Consumes: templates from Task 2 and fixed identity/scope/Profile table from the replacement design.
- Produces: exactly sixteen internal Capability contracts with fixed authority scope, Profile, result envelope, legal statuses, materialization targets, permissions, and stop conditions. The only registered project Skill remains `templates/.claude/skills/themis/SKILL.md`.

- [ ] **Step 1: Add Current Request Dialogue**

Define `themis-current-request-dialogue` with:

```text
authority_scope: request-intake
agent_profile: human-dialogue
selected_path: null
profile: null
statuses: needs-request-confirmation | assignment-confirmed | rejected
```

Its first Invocation proposes changed-only claim/assignment diffs and preserves the original continuation. A later confirmation Source Event requires a separate Invocation. It cannot create a lifecycle, write claims/state, execute a route, or infer confirmation from silence.

- [ ] **Step 2: Update the fifteen existing Capability contracts**

Add explicit authority scope and materialization target to every contract. Keep the approved semantic responsibilities and legal statuses. Change Questioning to consume confirmed claims and produce one completed per-round result. Change Review Dialogue and Acceptance Dialogue to return proposals only. Change Failure Learning to accept either scope while preserving scope-local continuation and state isolation.

- [ ] **Step 3: Preserve the internal discovery boundary**

Keep all sixteen contracts under `templates/.themis/core/capabilities/` without Skill frontmatter or public invocation registration. Do not recreate the removed per-Capability project Skills; the sole registered public Skill is `templates/.claude/skills/themis/SKILL.md`.

- [ ] **Step 4: Update the four Profiles**

Add the sixteenth mapping without creating a fifth Profile. `human-dialogue` may return governance proposals and structured user decisions but may not write Intake/lifecycle state, semantic artifacts, routes, or project implementation. Only `implementation-writer` may modify approved project implementation, and it may not write governance authority or issue a Verification verdict.

- [ ] **Step 5: Verify identities and fixed mappings**

Run:

```bash
py -3 - <<'PY'
from pathlib import Path
caps = {
    'themis-current-request-dialogue', 'themis-q', 'themis-grounding',
    'themis-complexity-assessment', 'themis-simple-plan', 'themis-spec',
    'themis-planning', 'themis-plan-check', 'themis-review-projection',
    'themis-review-check', 'themis-review-dialogue', 'themis-impl',
    'themis-verification', 'themis-acceptance-dialogue',
    'themis-failure-learning', 'themis-summary',
}
public_skills = list(Path('templates/.claude/skills').glob('*/SKILL.md'))
assert public_skills == [Path('templates/.claude/skills/themis/SKILL.md')], public_skills
contracts = [p for p in Path('templates/.themis/core/capabilities').glob('*.md') if p.name != 'README.md']
assert len(contracts) == 16, len(contracts)
actual = set()
for path in contracts:
    text = path.read_text(encoding='utf-8')
    for cap in caps:
        if f'Stable identity：`{cap}`' in text:
            actual.add(cap)
    lower = text.lower()
    for marker in ['authority scope', 'agent profile', '合法状态', 'materialization target', '不调用其他 capability 或 agent']:
        assert marker in lower, (path, marker)
assert actual == caps, (sorted(caps - actual), sorted(actual - caps))
print('PASS: 16 internal Capability contracts expose fixed boundaries; one public Skill remains')
PY
```

Expected: `PASS: 16 internal Capability contracts expose fixed boundaries; one public Skill remains`.

---

### Task 4: Replace the Sole Policy with Dual-Scope Control

**Files:**
- Modify: `templates/.themis/core/policies/transitions.yaml`
- Modify: `templates/.themis/core/policies/README.md`
- Modify: `templates/.themis/core/core.yaml`
- Delete: `templates/.themis/VERSION`

**Interfaces:**
- Consumes: sixteen Capability contracts, four Profile contracts, artifact classes, and approved authority/control rules.
- Produces: the sole declarative route/control policy for Intake and lifecycle scopes. The file remains Prompt-level input until Plan 36/37 supply strict validation and execution.

- [ ] **Step 1: Declare both authority scopes**

Add `request-intake` and `lifecycle` scope declarations with isolated Execution identities, failure budgets, continuations, pointers, completion state, and dynamic state. Allow only stable cross-scope references.

- [ ] **Step 2: Declare sixteen fixed Capability bindings**

For every Capability, declare its stable identity, fixed `authority_scope`, fixed `agent_profile`, selected-path/profile domain, result contract, and materialization target. Keep the four-field route key:

```text
capability + selected_path + profile + status
```

- [ ] **Step 3: Add Intake routes and lifecycle interception**

Declare the three Current Request Dialogue statuses and their control actions. Require all external messages to be recorded and intercepted by Intake before lifecycle semantic handling. Use durable Intake-local confirmation/restart continuations as the only existing-Intake attachment mechanism.

- [ ] **Step 4: Declare generic materialization and currentness controls**

Add control requirements for proposed-result validation, exactly-one-route matching, complete paired/structured persistence, completion/incomplete observation, reread, immutable revision creation, separate pointer update, stale/duplicate/late rejection, and last-proven-gate recovery.

- [ ] **Step 5: Separate Intake and lifecycle failure budgets**

Define counted and non-counted classifications for both scopes. Terminate the corresponding Execution Identity on the third counted failure, forbid a fourth Invocation, and invoke scope-bound non-blocking Failure Learning after each counted failure and explicitly linked later success.

- [ ] **Step 6: Preserve lifecycle gates and sticky escalation**

Retain simple/full path convergence, Plan Check before Review, Approval before Impl, `Impl → independent Verification`, Acceptance after passed Verification, Summary after accepted Acceptance, and one-way `full_path_required` within one lifecycle.

- [ ] **Step 7: Remove version and route-count claims**

Extend `core.yaml` only with unversioned package identities and paths. Delete `templates/.themis/VERSION`. Remove any permanent `91 routes` or equivalent count from active policy/guidance; current route count is observed from current policy rather than product identity.

- [ ] **Step 8: Verify single policy and declared identities**

Run:

```bash
py -3 - <<'PY'
from pathlib import Path
policies = list(Path('templates/.themis').rglob('transitions.yaml'))
assert policies == [Path('templates/.themis/core/policies/transitions.yaml')], policies
text = policies[0].read_text(encoding='utf-8')
for marker in ['request-intake', 'lifecycle', 'themis-current-request-dialogue',
               'capability + selected_path + profile + status',
               'last-proven-gate', 'duplicate', 'wrong-scope']:
    assert marker in text, marker
assert '91' not in text
assert not Path('templates/.themis/VERSION').exists()
print('PASS: one dual-scope policy is declared without version or fixed route count')
PY
```

Expected: `PASS: one dual-scope policy is declared without version or fixed route count`.

---

### Task 5: Implement Intake-First Global Rule and Public Entry

**Files:**
- Modify: `templates/.themis/core/kernel/orchestrator/rules.md`
- Modify: `templates/.themis/core/kernel/orchestrator/README.md`
- Modify: `templates/.claude/skills/themis/SKILL.md`

**Interfaces:**
- Consumes: the sole policy from Task 4 and selected Capability/Profile/template contracts.
- Produces: one public entry and one generic interpreter that coordinate both scopes without duplicating the policy route table or Capability reasoning.

- [ ] **Step 1: Replace managed-change entry with Intake interception**

Require every external user message to become an immutable Source Event before lifecycle semantic handling. Select the Intake identity only from a durable confirmation or restart/unblock continuation; otherwise create a new Intake. Do not create, locate, continue, or update a lifecycle before confirmed assignment materializes.

- [ ] **Step 2: Define the two-Invocation confirmation flow**

The first dialogue Invocation may return `needs-request-confirmation`; the Rule persists the proposal and awaits a new Source Event. The second Invocation may return `assignment-confirmed`; only its matched control action may materialize claims and create or update one or more lifecycles.

- [ ] **Step 3: Generalize Invocation and result validation**

Bind one authority scope, one scope-local Execution Identity, one Invocation/attempt, one Capability/Profile, policy identity, source/artifact refs, path/profile, durable continuation, allowed effects, and expected materialization. Reject wrong-scope, wrong-profile, stale, duplicate, late, incomplete, or competing terminal results.

- [ ] **Step 4: Generalize materialization and recovery**

Treat results as proposals. Authority requires complete persistence, completion observation, reread, identity/digest/binding checks, immutable revision observation, and separate pointer update. Recovery reads durable Intake/lifecycle state, pointers, markers, artifact components, attempts, and applicable Git facts, then resumes only from the last proven gate.

- [ ] **Step 5: Preserve lifecycle semantics after assignment**

Keep user-confirmed claims as the input to Questioning, temporary full-path Specification as non-authoritative, simple/full Plan convergence, checked Review Projection, Plan-bound Approval, Verify ordering, independent gates, failure limits, and knowledge-candidate-only behavior.

- [ ] **Step 6: Update the public Skill**

Make `templates/.claude/skills/themis/SKILL.md` the only public lifecycle/intake entry. Its flow must start with Source Event recording and Intake, not lifecycle discovery. It may coordinate only through the Global Rule and current policy.

- [ ] **Step 7: Verify ownership boundaries**

Run:

```bash
py -3 - <<'PY'
from pathlib import Path
rule = Path('templates/.themis/core/kernel/orchestrator/rules.md').read_text(encoding='utf-8')
public = Path('templates/.claude/skills/themis/SKILL.md').read_text(encoding='utf-8')
for marker in ['Source Event', 'request-intake', 'assignment-confirmed',
               'last proven gate', 'proposed']:
    assert marker.lower() in rule.lower(), marker
assert 'fifteen' not in rule.lower()
assert '91' not in rule
assert '@' + 'import' not in rule
assert public.lower().find('source event') < public.lower().find('lifecycle')
print('PASS: public entry and Global Rule are Intake-first and policy-generic')
PY
```

Expected: `PASS: public entry and Global Rule are Intake-first and policy-generic`.

---

### Task 6: Replace Workspace Layout and Module Contracts

**Files:**
- Modify: `templates/.themis/workspace/manifest.yaml`
- Modify: `templates/.themis/workspace/README.md`
- Create: `templates/.themis/workspace/intakes/.gitkeep`
- Create: `templates/.themis/workspace/knowledge/intakes/.gitkeep`
- Create: `templates/.themis/workspace/knowledge/lifecycles/.gitkeep`
- Modify: `templates/.themis/core/kernel/context/README.md`
- Modify: `templates/.themis/core/kernel/specification/README.md`
- Modify: `templates/.themis/core/kernel/planning/README.md`
- Modify: `templates/.themis/core/kernel/review/README.md`
- Modify: `templates/.themis/core/kernel/implementation/README.md`
- Modify: `templates/.themis/core/kernel/verification/README.md`
- Modify: `templates/.themis/core/kernel/knowledge/README.md`
- Modify: `templates/.themis/core/protocols/README.md`

**Interfaces:**
- Consumes: artifact families, policy scopes, and Global Rule ownership.
- Produces: fresh-install family roots and module descriptions that match the replacement contract without literal example identity directories or runtime claims.

- [ ] **Step 1: Add Intake and scope-separated knowledge roots**

Add `workspace/intakes` to the manifest and create only family-root `.gitkeep` placeholders. Do not create literal `<intake-id>`, `<lifecycle-id>`, or revision example directories.

- [ ] **Step 2: Document the approved Workspace shape**

Describe Intake Source Events/proposals/decisions/state; lifecycle Current Request/Questioning/Plan/Review/Approval/Feedback revision families; state pointers/invalidations/markers; run/evidence records; outcomes; and scope-separated knowledge candidates. State that paths and files do not prove authority without observed materialization.

- [ ] **Step 3: Align Context and Specification boundaries**

Context current implementation facts must come from code/configuration/Schema/observed behavior. Specification remains a temporary full-path refinement and cannot own Current Request claims, lifecycle state, or persistent authority.

- [ ] **Step 4: Align Planning and Review boundaries**

Planning consumes confirmed claims and verified facts. Review Projection is a checked-Plan projection. Review Dialogue creates feedback/approval proposals only, and Approval binds the Plan plus the projection actually shown to the user.

- [ ] **Step 5: Align Implementation and Verification boundaries**

Implementation follows current Approval and records actual delta without self-verdict. Verification is independent and binds exact implementation evidence. Both share the Plan task failure budget but use separate Invocations.

- [ ] **Step 6: Align Knowledge and protocol boundaries**

Failure Learning supports both scopes but produces only governed candidates. Protocol guidance must distinguish Prompt-level structures from future strict Schema/evaluator/recorder guarantees.

- [ ] **Step 7: Verify Workspace scaffold**

Run:

```bash
py -3 - <<'PY'
from pathlib import Path
root = Path('templates/.themis/workspace')
for rel in ['intakes/.gitkeep', 'knowledge/intakes/.gitkeep', 'knowledge/lifecycles/.gitkeep']:
    assert (root / rel).is_file(), rel
for path in root.rglob('*'):
    assert '<intake-id>' not in path.as_posix()
    assert '<lifecycle-id>' not in path.as_posix()
manifest = (root / 'manifest.yaml').read_text(encoding='utf-8')
assert 'intakes: workspace/intakes' in manifest
readme = (root / 'README.md').read_text(encoding='utf-8')
assert 'questioning.md' not in readme
assert 'questioning/' in readme
print('PASS: fresh Workspace scaffold uses family roots and immutable revisions')
PY
```

Expected: `PASS: fresh Workspace scaffold uses family roots and immutable revisions`.

---

### Task 7: Align Installed Guidance and Product Overview

**Files:**
- Modify: `templates/.themis/README.md`
- Modify: `templates/.themis/CLAUDE.themis.md`
- Modify: `README.md`

**Interfaces:**
- Consumes: implemented policy, Global Rule, Capability/Profile, artifact, and Workspace contracts.
- Produces: concise active guidance that accurately describes current Prompt-level ability and unavailable future machine guarantees.

- [ ] **Step 1: Rewrite installed package guidance**

Describe Intake-first entry, user-confirmed source-bound claims, sixteen on-demand Capabilities, four Profiles, one policy/two scopes, immutable paired artifacts, per-round Questioning, Review-before-Impl, Verify ordering, independent Acceptance/Summary gates, isolated budgets, and durable recovery facts.

- [ ] **Step 2: State the implementation boundary**

Explicitly say Plan 35 supplies Prompt/template/policy contracts and manual replay only. Strict validation/canonicalization belong to Plan 36; native evaluation, recording, invocation hosting, and write safety belong to Plan 37; Plan 80/90 remain optional.

- [ ] **Step 3: Remove active stale terminology**

Remove active claims of fifteen Capabilities, 91 permanent routes, lifecycle creation before Intake, one append-only `questioning.md`, mutable artifact overwrite, Markdown-only authority, version/upgrade/migration, or existing deterministic runtime enforcement.

- [ ] **Step 4: Verify guidance consistency**

Run:

```bash
py -3 - <<'PY'
from pathlib import Path
paths = [
    Path('README.md'),
    Path('templates/.themis/README.md'),
    Path('templates/.themis/CLAUDE.themis.md'),
]
for path in paths:
    text = path.read_text(encoding='utf-8')
    lower = text.lower()
    assert 'intake' in lower, path
    assert 'sixteen' in lower or '十六' in text, path
    assert 'questioning.md' not in text, path
    assert '91' not in text, path
print('PASS: active product guidance matches replacement Plan 35')
PY
```

Expected: `PASS: active product guidance matches replacement Plan 35`.

---

### Task 8: Produce Static Consistency Evidence

**Files:**
- Create: `docs/plan/35-core-prompt-flow/static-verification.md`

**Interfaces:**
- Consumes: all implemented Prompt contracts.
- Produces: reproducible observed evidence for replacement design section 19.1 without claiming Plan 36 strict validation.

- [ ] **Step 1: Run structural assertions**

Execute Python standard-library checks that observe:

- exactly one public `themis` Skill;
- exactly sixteen internal Capability identities and Skills;
- one fixed Profile and scope mapping for each Capability;
- only `themis-impl` maps to `implementation-writer`;
- every Capability/Skill contains inputs, outputs, legal statuses, permissions, stop conditions, materialization target, and no nested Capability/Agent call;
- exactly one `transitions.yaml`;
- one Global Rule without a copied route table or domain reasoning;
- no active single `questioning.md`, permanent route count, version file, or Markdown-only authority;
- consistent Workspace, Approval, invalidation, and paired-artifact terms;
- no Plan 36/37/80/90 capability claim.

- [ ] **Step 2: Search active files for forbidden stale contracts**

Use `Grep` over active README, guidance, policy, Rule, Capability, Profile, template, Workspace, and active Plan files for:

```text
fifteen
十五
91 routes
questioning.md
approved Spec
Delivery stage
runtime available
validator available
upgrade
migration
```

Classify each hit as removed, historical-only, explicit non-goal, or a real defect. Fix real defects before recording evidence.

- [ ] **Step 3: Run whitespace validation**

Run:

```bash
git diff --check
```

Expected: no output and exit status 0.

- [ ] **Step 4: Record exact observed results**

Write `static-verification.md` with date, scope, each command or equivalent assertion, actual output, pass/fail result, and the explicit limitation that these checks do not provide strict Schema validation, canonical digests, machine route evaluation, recorder proof, or runtime write guarantees.

- [ ] **Step 5: Re-run the recorded checks**

Run every command quoted in `static-verification.md` once more from the repository root. Correct the document if its recorded output differs from the rerun.

---

### Task 9: Replay Sixteen Scenarios and Audit Acceptance

**Files:**
- Create: `docs/plan/35-core-prompt-flow/manual-replay.md`
- Create: `docs/plan/35-core-prompt-flow/acceptance-audit.md`

**Interfaces:**
- Consumes: policy routes, Global Rule, Capability/Profile contracts, templates, Workspace model, and static evidence.
- Produces: scenario-by-scenario replay evidence and a 32-criterion evidence map for explicit user re-acceptance.

- [ ] **Step 1: Replay Intake creation and confirmation**

Record scenario 1 with a new Source Event, Current Request Dialogue proposal, explicit confirmation Source Event, `assignment-confirmed`, observed claim materialization, and new lifecycle creation.

- [ ] **Step 2: Replay unchanged and multi-target assignment**

Record scenarios 2–4: no semantic change resumes the bound continuation without repeat confirmation; one Intake explicitly assigns multiple lifecycles; partial materialization preserves completed targets and resumes only unfinished targets without rollback.

- [ ] **Step 3: Replay changed claims and resumed dialogue**

Record scenarios 5–7: Questioning changes a claim with changed-only confirmation; Review/Acceptance messages first pass Intake; Review feedback routes to the correct owner, produces a new Plan, and makes old Approval stale.

- [ ] **Step 4: Replay escalation and materialization failures**

Record scenarios 8–10: simple-to-full sticky escalation; paired half-write/digest mismatch/pointer-update failure; stale, duplicate, late, wrong-profile, and wrong-scope results.

- [ ] **Step 5: Replay failure budgets and learning**

Record scenarios 11–13: Intake failures do not consume lifecycle budget; Impl/Verification share one task budget and terminate on the third counted failure; counted failure and explicitly linked later success each schedule non-blocking Failure Learning without recursive failure.

- [ ] **Step 6: Replay gates, recovery, and closure**

Record scenarios 14–16: Summary is blocked without current passed Verification and accepted Acceptance; interruption resumes only from the last proven gate; explicit rejection and host-observed abandonment are distinct and silence infers neither.

- [ ] **Step 7: Include the complete replay ledger for every scenario**

For all sixteen scenarios record:

```text
initial durable facts
selected Capability/Profile/scope
proposed status
matched route
control action
materialized records/revisions
current pointer/gate
invalidation
failure class
missing Plan 36/37 machine guarantees
```

Do not claim actual machine evaluation or persistence where only Prompt-level policy replay exists.

- [ ] **Step 8: Map all 32 acceptance criteria**

Create `acceptance-audit.md` with one row per numbered criterion from the replacement design. Each row must name the exact policy/Rule/Capability/Profile/template/Workspace/evidence location and classify it `PASS` or `GAP`. Do not mark criterion 32 `PASS`; mark it `AWAITING USER RE-ACCEPTANCE` until the user explicitly accepts the implementation.

- [ ] **Step 9: Run the final changed-file and whitespace audit**

Run:

```bash
git status --short
```

Compare the result with Task 1's protected baseline. Investigate every new path outside this plan's file list and preserve all pre-existing user changes.

Run:

```bash
git diff --check
```

Expected: no output and exit status 0.

- [ ] **Step 10: Present evidence without committing**

Report static-check totals, replay totals, acceptance totals, explicit limitations, changed-file scope, and criterion 32's pending state. Ask the user for explicit replacement Plan 35 re-acceptance. Do not commit or push.
