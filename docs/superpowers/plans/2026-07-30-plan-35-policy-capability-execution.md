# Plan 35 Policy、Capability 与执行模型收尾实施计划

> 历史状态：本文已被 `docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement-design.md` 及其当前实施计划取代，仅保留为历史记录，不是 current authority。本文的 YAML policy/artifact 表示与 Python 检查说明又由 `2026-08-01-plan-35-markdown-contract-refactor.md` 取代，不是当前实施 guidance。

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成 Plan 35 的结构收尾，使 Core 身份最小化、`transitions.yaml` 成为唯一完整路由政策源、十五项能力成为内部 Capability、四个 Agent Profile 约束临时 invocation，并以实际静态检查和人工 replay 核验 Prompt-level 生命周期。

**Architecture:** 唯一公共 `.claude/skills/themis/SKILL.md` 接收生命周期请求并加载 Global Control Rule；Global Rule 读取一个内部 Capability 及其固定 Agent Profile，通过一次性 invocation 获取结构化结果，再使用 `capability + selected_path + profile + status` 在 `transitions.yaml` 中恰好匹配一条 route。Workspace 按 lifecycle identity 保存实际记录与引用；Plan 35 只提供 Prompt-level 合同和人工可重放控制，不声称 Plan 36 strict assurance 或 Plan 37 runtime 已存在。

**Tech Stack:** Markdown、YAML、Claude Code project Skill、Git、Python 标准库静态检查。

## Global Constraints

- 以 `docs/superpowers/specs/2026-07-29-plan-35-core-prompt-flow-design.md` 和其增量修订 `docs/superpowers/specs/2026-07-30-plan-35-policy-capability-execution-design.md` 为跨模块权威。
- 当前 `main` 工作树已有大量未提交 Plan 35 修改；必须原地增量编辑，不创建或迁移到新 worktree，不覆盖、恢复、丢弃或顺带整理已有用户修改。
- 不提交、不推送；每个任务以可观察 diff 和验证结果结束。
- 不实现 Plan 36 strict Schema、validator、canonicalization、digest/currentness enforcement 或 contract fixtures。
- 不实现 Plan 37 Go runtime、installer、state recorder、通用锁、事务、复杂 rollback 或自动 recovery。
- 不实现 Plan 80 多 Agent 调度、投票、共识、持久 Agent、Agent-to-Agent 调用或共享 Agent memory。
- 不实现 Plan 90 Attribution analytics；只清理 active Attribution Rule 的旧生命周期术语。
- 不创建持久 Specification artifact、`spec.yaml`、`spec.md` 或 Specification approval。
- 不恢复 Shell runtime/fallback、upgrade、migration、compatibility matrix、功能版本字段或版本目录。
- 只修改 fresh template 源，不覆盖已安装 `.themis`，不提供旧安装转换。
- Review 必须位于 Impl 前；Impl 与独立 Verification 构成 Verify；Summary 只允许在 current Verification `passed` 且 Human Acceptance `accepted` 后生成。
- 只有 `implementation-writer` Profile 允许修改项目实现；其他 Profile 必须显式禁止。
- 路由字段 `profile` 只表示 Plan profile `lightweight | full | null`；执行权限字段统一称为 `agent_profile`，不得混用。
- Canonical policy vocabulary 使用 kebab-case；Capability identity 保留现有 `themis-*` 值。
- Prompt-level route 表存在不等于 recorder、validator、digest service 或 transition executor 已执行；任何未实际观察的机器保证必须报告 unavailable。

---

## File Structure

### Create

- `templates/.claude/skills/themis/SKILL.md` — 唯一公共 lifecycle 入口，不拥有十五项语义。
- `templates/.themis/core/capabilities/README.md` — 内部 Capability 包职责、共同合同和发现边界。
- `templates/.themis/core/capabilities/questioning.md`
- `templates/.themis/core/capabilities/grounding.md`
- `templates/.themis/core/capabilities/complexity-assessment.md`
- `templates/.themis/core/capabilities/simple-planning.md`
- `templates/.themis/core/capabilities/specification.md`
- `templates/.themis/core/capabilities/planning.md`
- `templates/.themis/core/capabilities/plan-check.md`
- `templates/.themis/core/capabilities/review-projection.md`
- `templates/.themis/core/capabilities/review-check.md`
- `templates/.themis/core/capabilities/review-dialogue.md`
- `templates/.themis/core/capabilities/implementation.md`
- `templates/.themis/core/capabilities/verification.md`
- `templates/.themis/core/capabilities/acceptance-dialogue.md`
- `templates/.themis/core/capabilities/failure-learning.md`
- `templates/.themis/core/capabilities/summary.md`
- `templates/.themis/core/agent-profiles/README.md` — Profile 包职责、固定映射和权限不可扩张规则。
- `templates/.themis/core/agent-profiles/semantic-readonly.md`
- `templates/.themis/core/agent-profiles/independent-checker.md`
- `templates/.themis/core/agent-profiles/human-dialogue.md`
- `templates/.themis/core/agent-profiles/implementation-writer.md`

### Modify

- `templates/.themis/core/core.yaml` — 只保留三个无版本身份字段。
- `templates/.themis/core/policies/transitions.yaml` — 完整 91 条合法 route、固定 Profile 映射、vocabulary、guards、failure control 和 `invalid_result`。
- `templates/.themis/core/kernel/orchestrator/rules.md` — 通用政策解释器，不复制 Capability-specific route。
- `templates/.themis/core/kernel/orchestrator/README.md`
- `templates/.themis/core/kernel/context/README.md`
- `templates/.themis/core/kernel/specification/README.md`
- `templates/.themis/core/kernel/planning/README.md`
- `templates/.themis/core/kernel/review/README.md`
- `templates/.themis/core/kernel/implementation/README.md`
- `templates/.themis/core/kernel/verification/README.md`
- `templates/.themis/core/kernel/knowledge/README.md`
- `templates/.themis/core/kernel/attribution/rules.md`
- `templates/.themis/core/policies/README.md`
- `templates/.themis/core/protocols/README.md`
- `templates/.themis/core/templates/failure-learning.md`
- `templates/.themis/CLAUDE.themis.md`
- `templates/.themis/README.md`
- `docs/plan/35-core-prompt-flow/impl.md`
- `docs/plan/36-deterministic-assurance/impl.md`
- `docs/plan/37-native-runtime/impl.md`
- `docs/plan/README.md`

### Remove after semantic migration

- `templates/.claude/skills/themis-q/SKILL.md`
- `templates/.claude/skills/themis-grounding/SKILL.md`
- `templates/.claude/skills/themis-complexity-assessment/SKILL.md`
- `templates/.claude/skills/themis-simple-plan/SKILL.md`
- `templates/.claude/skills/themis-spec/SKILL.md`
- `templates/.claude/skills/themis-planning/SKILL.md`
- `templates/.claude/skills/themis-plan-check/SKILL.md`
- `templates/.claude/skills/themis-review-projection/SKILL.md`
- `templates/.claude/skills/themis-review-check/SKILL.md`
- `templates/.claude/skills/themis-review-dialogue/SKILL.md`
- `templates/.claude/skills/themis-impl/SKILL.md`
- `templates/.claude/skills/themis-verification/SKILL.md`
- `templates/.claude/skills/themis-acceptance-dialogue/SKILL.md`
- `templates/.claude/skills/themis-failure-learning/SKILL.md`
- `templates/.claude/skills/themis-summary/SKILL.md`

---

### Task 1: Protect the Dirty Baseline and Minimize Core Identity

**Files:**
- Modify: `templates/.themis/core/core.yaml`
- Observe only: repository status and existing Plan 35 diff

**Interfaces:**
- Consumes: current dirty working tree as protected input.
- Produces: a recorded baseline inventory and the exact three-field Core identity required by every later task.

- [ ] **Step 1: Capture the protected baseline**

Run:

```bash
git status --short
```

Expected: existing modified, added, and deleted Plan 35 paths are visible; save the output in the session record and do not restore any path.

- [ ] **Step 2: Review the current Core identity before editing**

Read `templates/.themis/core/core.yaml` and confirm the current `contract.functional_versions`, `contract.upgrade`, and `contract.migration` fields are the only non-identity content being removed.

- [ ] **Step 3: Replace Core identity with the approved exact content**

```yaml
schema: themis-core
workspace_schema: themis-workspace
artifact_schema: themis-artifact
```

- [ ] **Step 4: Verify no prohibited Core field remains**

Run:

```bash
py -3 -c "from pathlib import Path; p=Path('templates/.themis/core/core.yaml'); lines=[x for x in p.read_text(encoding='utf-8').splitlines() if x.strip()]; assert lines == ['schema: themis-core','workspace_schema: themis-workspace','artifact_schema: themis-artifact']; print('core identity: 3/3 exact fields')"
```

Expected: `core identity: 3/3 exact fields`.

---

### Task 2: Create the Internal Capability Package

**Files:**
- Create: `templates/.themis/core/capabilities/README.md`
- Create: all fifteen `templates/.themis/core/capabilities/*.md` contracts listed in File Structure
- Remove after migration: all fifteen `templates/.claude/skills/themis-*/SKILL.md`

**Interfaces:**
- Consumes: the semantic content, legal statuses, bindings, evidence requirements, write boundaries, and stop conditions from each current `themis-*` Skill.
- Produces: fifteen non-discoverable internal Capability contracts with stable `themis-*` identities, consumed by Task 4 policy and Task 5 Global Rule.

- [ ] **Step 1: Establish the Capability package contract**

Write `capabilities/README.md` with these exact ownership rules:

- Capability owns one semantic judgment and its structured payload.
- Capability does not own route selection, lifecycle state, persistence authority, Profile choice, or another Capability/Agent invocation.
- Each invocation loads exactly one Capability.
- Capability Invocation Result uses `capability`, `status`, `input_bindings`, `output`, `diagnostics`, and advisory `recommended_route`.
- Missing validator/recorder/runtime means assurance unavailable, never implicit success.
- Internal files have no Claude Code Skill frontmatter and no slash-command or `user-invocable` registration.

- [ ] **Step 2: Migrate Questioning and grounding contracts**

Move semantic content without Skill frontmatter:

| Source | Target | Stable identity | Agent profile | Legal path/profile | Legal statuses |
|---|---|---|---|---|---|
| `themis-q/SKILL.md` | `questioning.md` | `themis-q` | `human-dialogue` | `null/null` | `needs-questioning`, `converged` |
| `themis-grounding/SKILL.md` | `grounding.md` | `themis-grounding` | `semantic-readonly` | `null/null` | `ready`, `partial`, `blocked` |
| `themis-complexity-assessment/SKILL.md` | `complexity-assessment.md` | `themis-complexity-assessment` | `semantic-readonly` | `null/null` | `simple-qualified`, `full-required`, `blocked` |

Every target must explicitly state: no implementation writes, no route ownership, no Capability/Agent calls, and no lifecycle persistence authority.

- [ ] **Step 3: Migrate Plan-formation contracts**

| Source | Target | Stable identity | Agent profile | Legal path/profile | Legal statuses |
|---|---|---|---|---|---|
| `themis-simple-plan/SKILL.md` | `simple-planning.md` | `themis-simple-plan` | `semantic-readonly` | `simple/lightweight` | `ready`, `escalate-full`, `blocked` |
| `themis-spec/SKILL.md` | `specification.md` | `themis-spec` | `semantic-readonly` | `full/null` | `ready`, `needs-questioning`, `needs-grounding`, `blocked` |
| `themis-planning/SKILL.md` | `planning.md` | `themis-planning` | `semantic-readonly` | `full/full` | `ready`, `needs-specification`, `needs-grounding`, `blocked` |

`specification.md` must say its output is temporary and non-persistent; `simple-planning.md` and `planning.md` both produce the same unified Plan contract.

- [ ] **Step 4: Migrate Plan and Review gate contracts**

| Source | Target | Stable identity | Agent profile | Legal path/profile | Legal statuses |
|---|---|---|---|---|---|
| `themis-plan-check/SKILL.md` | `plan-check.md` | `themis-plan-check` | `independent-checker` | `simple/lightweight` | `pass`, `needs-simple-planning`, `escalate-full`, `blocked` |
| same | same | same | same | `full/full` | `pass`, `needs-planning`, `needs-specification`, `needs-grounding`, `blocked` |
| `themis-review-projection/SKILL.md` | `review-projection.md` | `themis-review-projection` | `semantic-readonly` | `simple/lightweight`, `full/full` | `ready`, `blocked` |
| `themis-review-check/SKILL.md` | `review-check.md` | `themis-review-check` | `independent-checker` | `simple/lightweight`, `full/full` | `pass`, `needs-projection` |
| `themis-review-dialogue/SKILL.md` | `review-dialogue.md` | `themis-review-dialogue` | `human-dialogue` | `simple/lightweight` | `continue`, `approved`, `needs-simple-planning`, `needs-planning`, `needs-specification`, `needs-grounding`, `escalate-full` |
| same | same | same | same | `full/full` | `continue`, `approved`, `needs-planning`, `needs-specification`, `needs-grounding` |

Review Projection/Check must say `profile` binds the upstream Plan but does not weaken or vary projection fidelity standards. Review Dialogue `needs-grounding` must return an explicit `affected_owner` binding rather than relying on diagnostics prose.

- [ ] **Step 5: Migrate execution and outcome contracts**

| Source | Target | Stable identity | Agent profile | Legal path/profile | Legal statuses |
|---|---|---|---|---|---|
| `themis-impl/SKILL.md` | `implementation.md` | `themis-impl` | `implementation-writer` | `simple/lightweight` | `implemented`, `needs-planning`, `escalate-full`, `blocked` |
| same | same | same | same | `full/full` | `implemented`, `needs-planning`, `blocked` |
| `themis-verification/SKILL.md` | `verification.md` | `themis-verification` | `independent-checker` | `simple/lightweight` | `passed`, `failed`, `needs-planning`, `needs-specification`, `escalate-full`, `blocked` |
| same | same | same | same | `full/full` | `passed`, `failed`, `needs-planning`, `needs-specification`, `blocked` |
| `themis-acceptance-dialogue/SKILL.md` | `acceptance-dialogue.md` | `themis-acceptance-dialogue` | `human-dialogue` | `simple/lightweight` | `accepted`, `implementation-defect`, `needs-planning`, `needs-specification`, `escalate-full` |
| same | same | same | same | `full/full` | `accepted`, `implementation-defect`, `needs-planning`, `needs-specification` |
| `themis-failure-learning/SKILL.md` | `failure-learning.md` | `themis-failure-learning` | `semantic-readonly` | `null/null`, `simple/lightweight`, `full/full` | `candidate-ready`, `not-reusable`, `needs-more-evidence`, `blocked` |
| `themis-summary/SKILL.md` | `summary.md` | `themis-summary` | `semantic-readonly` | `simple/lightweight`, `full/full` | `ready`, `blocked` |

Only `implementation.md` may permit project implementation writes. Verification `failed` requires evidence-backed `implementation-defect`. Failure Learning must carry a lifecycle-bound `main_route_continuation`, never recursively learn from its own failure, and never replace the main route.

- [ ] **Step 6: Remove the fifteen old project Skill registrations**

After every target file has been reread and checked for semantic completeness, remove the fifteen source `SKILL.md` files and their now-empty `themis-*` directories. Do not leave wrappers, aliases, or compatibility entries.

- [ ] **Step 7: Verify the internal package shape**

Run:

```bash
py -3 -c "from pathlib import Path; root=Path('templates/.themis/core/capabilities'); files=sorted(p.name for p in root.glob('*.md') if p.name!='README.md'); assert len(files)==15, files; assert not any('---'==p.read_text(encoding='utf-8').splitlines()[0].strip() for p in root.glob('*.md') if p.name!='README.md'); print('internal capabilities:', len(files))"
```

Expected: `internal capabilities: 15`.

---

### Task 3: Define Agent Profiles and the Single Public Skill

**Files:**
- Create: `templates/.themis/core/agent-profiles/README.md`
- Create: four Agent Profile files
- Create: `templates/.claude/skills/themis/SKILL.md`

**Interfaces:**
- Consumes: stable Capability identities from Task 2.
- Produces: fixed execution-permission contracts and the sole auto-discoverable public entry used by Tasks 4–6.

- [ ] **Step 1: Write the Profile package README with the exact fixed mapping**

```text
themis-q                    → human-dialogue
themis-grounding            → semantic-readonly
themis-complexity-assessment→ semantic-readonly
themis-simple-plan          → semantic-readonly
themis-spec                 → semantic-readonly
themis-planning             → semantic-readonly
themis-plan-check           → independent-checker
themis-review-projection    → semantic-readonly
themis-review-check         → independent-checker
themis-review-dialogue      → human-dialogue
themis-impl                 → implementation-writer
themis-verification         → independent-checker
themis-acceptance-dialogue  → human-dialogue
themis-failure-learning     → semantic-readonly
themis-summary              → semantic-readonly
```

State that a Capability cannot select or expand its Profile and an invocation cannot override this mapping.

- [ ] **Step 2: Write `semantic-readonly.md`**

Require project reads only, no project implementation writes, no inherited temporary reasoning requirement, minimal evidence references, one Capability per invocation, and structured result only.

- [ ] **Step 3: Write `independent-checker.md`**

Require independent context, no generator temporary reasoning inheritance, read-only project access, direct evidence, no implementation writes, and no verdict delegation.

- [ ] **Step 4: Write `human-dialogue.md`**

Allow user interaction through the Global Rule only; each invocation generates one current presentation/question/result from durable lifecycle records, user raw answers are recorded by the control plane, and chat context is not lifecycle authority. Prohibit project implementation writes.

- [ ] **Step 5: Write `implementation-writer.md`**

Allow implementation writes only within current Review Approval and Plan Task scope; require actual delta and command evidence; prohibit Verification verdict, route selection, Profile expansion, or writes to Core policy.

- [ ] **Step 6: Write the public `themis` Skill**

Frontmatter must register only the name `themis` and describe that it starts, continues, or recovers a governed Themis lifecycle. The body must:

- locate or establish lifecycle control context;
- load `core/kernel/orchestrator/rules.md`;
- read `core/policies/transitions.yaml`;
- delegate semantic judgment to exactly one internal Capability using its fixed Agent Profile;
- present human dialogue generated by the control plane;
- never implement Questioning, Planning, Review, Impl, Verification, Acceptance, Summary, routing, persistence, or digest logic itself;
- fail closed and report unavailable when required Core contracts or actual recorder/runtime operations are absent.

- [ ] **Step 7: Verify exactly one public project Skill**

Run:

```bash
py -3 -c "from pathlib import Path; files=sorted(Path('templates/.claude/skills').glob('*/SKILL.md')); assert [p.parent.name for p in files]==['themis'], files; print('public skills: themis only')"
```

Expected: `public skills: themis only`.

---

### Task 4: Make `transitions.yaml` the Complete Route Authority

**Files:**
- Modify: `templates/.themis/core/policies/transitions.yaml`
- Modify: `templates/.themis/core/policies/README.md`

**Interfaces:**
- Consumes: fifteen Capability status sets and fixed Agent Profile mapping from Tasks 2–3.
- Produces: the sole route-policy declaration consumed by Task 5; every legal route key appears exactly once.

- [ ] **Step 1: Preserve non-routing Plan 35 invariants**

Keep declarations for lifecycle phases, simple/full path sequence, `full_path_required` sticky behavior, Review/Verification/Acceptance/Summary gates, invalidation semantics, shared three-failure budget, and Prompt-level assurance limitations.

- [ ] **Step 2: Declare canonical vocabularies**

Declare closed lists for:

- `agent_profiles`: `semantic-readonly`, `independent-checker`, `human-dialogue`, `implementation-writer`;
- `selected_paths`: `simple`, `full` plus explicit YAML `null` where not applicable;
- `profiles`: `lightweight`, `full` plus explicit YAML `null` where not applicable;
- route targets: fifteen Capability identities plus `human-questioning`, `human-review`, `human-unblock`, `requesting-capability`, `resume-main-route`, `failure-control`, `completed`;
- control actions used by the route matrix below;
- invalidation categories: `quick-plan`, `complexity-assessment`, `plan`, `plan-check`, `review-projection`, `review-check`, `review-approval`, `unfinished-downstream`, `affected-verification-evidence`, `human-acceptance`, `summary`;
- failure classes: `none`, `non-counted`, `counted`.

- [ ] **Step 3: Declare fixed Capability-to-Agent-Profile bindings**

Encode all fifteen exact mappings from Task 3 once. Route rows continue using lifecycle `profile`; they do not repeat or override `agent_profile`.

- [ ] **Step 4: Declare generic guards and continuation bindings**

Define these policy-level rules outside the four-field route key:

- `simple-qualified` may execute `select-simple-path` only when `full_path_required` is false.
- Once true, `full_path_required` never becomes false within the lifecycle.
- Questioning re-entry always returns through Complexity Assessment and preserves sticky full state.
- `requesting-capability` requires a current lifecycle-bound continuation identity.
- Review Dialogue `needs-grounding` requires a current `affected_owner` binding from a closed Capability set.
- Failure Learning requires a lifecycle-bound `main_route_continuation` and never replaces it.
- Counted failure is recorded before normal route continuation; the third counted failure replaces normal `next` with termination of the same Task Execution Identity.
- Persistence actions complete only after an observed recorder result; unavailable persistence stops at the current gate.
- Policy identity/digest binding must match the policy actually read; a changed digest stops and requires revalidation rather than silent adoption.

- [ ] **Step 5: Expand all 91 legal route rows**

Every row must contain exactly:

```yaml
- capability: <stable identity>
  selected_path: <simple | full | null>
  profile: <lightweight | full | null>
  status: <legal capability status>
  next: <declared target>
  control_action: <declared action>
  invalidate: [<declared categories>]
  failure_class: <none | non-counted | counted>
```

Use this exact route distribution and behavior:

| Capability | Row count | Required behavior |
|---|---:|---|
| `themis-q` | 2 | `needs-questioning → human-questioning/present-questioning-questions/non-counted`; `converged → themis-complexity-assessment/persist-questioning-round-and-pointer/none` |
| `themis-grounding` | 3 | `ready` and `partial` return through current `requesting-capability`; `blocked → human-unblock/request-unblock`; partial/blocked are non-counted |
| `themis-complexity-assessment` | 3 | simple selects simple; full-required sets sticky full and invalidates quick downstream; blocked requests unblock |
| `themis-simple-plan` | 3 | ready persists unified Plan and goes to Plan Check; escalate sets sticky full; blocked requests unblock |
| `themis-spec` | 4 | ready supplies temporary handoff to Planning; questioning/grounding return to their owners; blocked requests unblock |
| `themis-planning` | 4 | ready persists unified Plan; specification/grounding rework routes; blocked requests unblock |
| `themis-plan-check` | 9 | four `simple/lightweight` rows and five `full/full` rows; pass goes to Review Projection; rework returns to the owning Plan capability; simple escalation sets sticky full |
| `themis-review-projection` | 4 | ready/blocked expanded separately for `simple/lightweight` and `full/full` |
| `themis-review-check` | 4 | pass/needs-projection expanded separately for both legal path/profile pairs |
| `themis-review-dialogue` | 12 | continue/approved on both pairs; quick-only `needs-simple-planning` and `escalate-full` only on simple; full rework returns to Planning/Specification; simple planning/specification defects set sticky full; grounding uses bound affected owner |
| `themis-impl` | 7 | implemented and blocked on both pairs; needs-planning on simple sets sticky full and on full returns to Planning; escalate-full only on simple |
| `themis-verification` | 11 | passed/failed/blocked on both pairs; failed is counted and returns to bounded repair unless third failure terminates; planning/specification rework is path-specific; escalation only on simple |
| `themis-acceptance-dialogue` | 9 | accepted and implementation-defect on both pairs; defect is counted bounded repair; planning/specification rework path-specific; escalation only on simple |
| `themis-failure-learning` | 12 | four statuses expanded over only `null/null`, `simple/lightweight`, `full/full`; all resume the bound main route; no recursive counted failure |
| `themis-summary` | 4 | ready/blocked expanded over both legal path/profile pairs; ready persists Summary and completes lifecycle |

Required invalidation sets:

```text
sticky quick-to-full:
  quick-plan, plan-check, review-projection, review-check,
  review-approval, unfinished-downstream

questioning revision:
  complexity-assessment, plan, plan-check, review-projection,
  review-check, review-approval, unfinished-downstream

plan rework:
  plan, plan-check, review-projection, review-check,
  review-approval, unfinished-downstream

new unified Plan:
  plan-check, review-projection, review-check,
  review-approval, unfinished-downstream

review projection regeneration:
  review-projection, review-check, review-approval,
  unfinished-downstream

new review projection:
  review-check, review-approval, unfinished-downstream

implementation/verification repair:
  affected-verification-evidence, human-acceptance, summary
```

- [ ] **Step 6: Add the separate global invalid-result rule**

```yaml
invalid_result:
  control_action: fail-closed
  failure_class: counted
  next: failure-control
```

State that zero/multiple route matches, unknown status, wrong capability/path/profile, missing or stale binding, policy mismatch, illegal payload, tool/Agent/result-contract failure all use this rule and never masquerade as semantic statuses.

- [ ] **Step 7: Update the Policies README**

State that `transitions.yaml` uniquely owns route data, Capability owns semantic judgment, Global Rule owns generic interpretation, Workspace owns lifecycle values, and Plan 36/37 machine guarantees are unavailable.

- [ ] **Step 8: Verify route count, key uniqueness, and closed references with a Python standard-library parser**

Run an inline Python command that scans each eight-field route block, asserts exactly 91 blocks, asserts unique `(capability, selected_path, profile, status)` tuples, checks all capabilities/targets/actions/invalidations/failure classes against the declared vocabulary, and prints:

```text
routes: 91
unique route keys: 91
closed vocabulary: pass
```

Do not add a repository test or claim this is a Plan 36 YAML validator.

---

### Task 5: Contract the Global Control Rule to Generic Policy Interpretation

**Files:**
- Modify: `templates/.themis/core/kernel/orchestrator/rules.md`
- Modify: `templates/.themis/core/kernel/orchestrator/README.md`

**Interfaces:**
- Consumes: the public Skill, internal Capability/Profile package, and complete route policy.
- Produces: one always-loaded control rule that never duplicates Capability-specific `status → next/action` mappings.

- [ ] **Step 1: Replace the old required-Skill registry**

Require the single public entry Skill plus the fifteen internal Capability contracts and four Profile contracts. State that one invocation loads one Capability and its fixed Profile, not one project Skill.

- [ ] **Step 2: Define the generic invocation sequence**

Use this exact order:

1. Determine current lifecycle identity and control position.
2. Verify current policy identity/digest and required current bindings.
3. Select the Capability named by the current route/control position.
4. Read that Capability contract and its fixed `agent_profile` mapping.
5. Create one Invocation Identity with minimum lifecycle-bound inputs and continuations.
6. Run one temporary Agent invocation; prohibit nested Capability/Agent calls.
7. Verify returned `capability`, legal payload shape, path/profile, current bindings, evidence references, and Profile permission boundary.
8. Match exactly one route in `transitions.yaml` by the four-field route key.
9. On zero/multiple match or invalid result, execute global `invalid_result`.
10. For counted failures, record attempt first, dispatch non-blocking Failure Learning with the saved main-route continuation, then terminate on the third failure or execute the route.
11. Execute route `control_action`, observed persistence, invalidation, and `next` in declared order.
12. Discard temporary invocation context; retain only actual structured records/references.

- [ ] **Step 3: Preserve generic action meanings and gates**

Define generic semantics for append Questioning round/pointer, select path, sticky full, persist unified Plan, record Plan/Review/Verification/Acceptance results, request unblock, bounded repair, enter Human Acceptance, complete lifecycle, and lifecycle-bound dynamic continuation. Do not state which Capability status chooses any action; that ownership belongs only to YAML.

- [ ] **Step 4: Preserve authority, invalidation, drift, and failure invariants**

Keep Current Request authority, code/configuration/Schema/observed behavior as implementation facts, temporary Specification non-authority, approved Plan as execution contract, Review-before-Impl, independent Verification, shared three-failure budget, policy digest stop/revalidate, external drift stop, and Summary gate.

- [ ] **Step 5: Preserve safe degradation**

If Capability/Profile/policy/recorder/validator/runtime is unavailable, stop at the current gate and report exactly which assurance is unavailable. Never claim a route, invalidation, digest, currentness, persistence, attempt, rollback, or recovery operation occurred without observed evidence.

- [ ] **Step 6: Remove all Capability-specific route duplication**

Delete every section that enumerates `themis-*.status → next capability/control action`. Capability names may remain in registry/profile mapping and examples, but no prose table may duplicate the 91-row policy.

- [ ] **Step 7: Update the Orchestrator README**

Document the final ownership split:

```text
Capability        = semantic judgment
Agent Profile     = execution permission/isolation
Invocation        = one temporary execution carrier
transitions.yaml  = sole route policy
Global Rule       = generic interpreter/coordinator
Workspace         = per-lifecycle actual records
```

- [ ] **Step 8: Verify route ownership is not duplicated**

Search the Rule for patterns that enumerate multiple statuses beneath a specific `themis-*` capability. Expected: no Capability-specific route table; only generic lookup and policy references remain.

---

### Task 6: Align Guidance, Module Contracts, and Active Plans

**Files:**
- Modify: all Guidance, module README, protocol/template, and Plan files listed under File Structure

**Interfaces:**
- Consumes: final package paths and ownership model from Tasks 2–5.
- Produces: active documentation that points to one public Skill, internal Capabilities, fixed Profiles, and future Plan 36/37 boundaries without changing approved lifecycle semantics.

- [ ] **Step 1: Update installation Guidance**

In `templates/.themis/CLAUDE.themis.md` and `templates/.themis/README.md`:

- replace `.claude/skills/themis-*/SKILL.md` and “fifteen named/on-demand Skills” with the single public `.claude/skills/themis/SKILL.md`;
- add `.themis/core/capabilities/` and `.themis/core/agent-profiles/` paths;
- explain the public Skill → Global Rule → policy → Capability/Profile → temporary invocation flow;
- preserve product lifecycle, authority model, Review/Verify/Acceptance/Summary gates, and Prompt-level safe-degradation language.

- [ ] **Step 2: Update module READMEs by semantic owner**

Update Context, Specification, Planning, Review, Implementation, Verification, and Knowledge READMEs so each names its internal Capability files and fixed Profile instead of registered Skills. Keep existing module responsibility boundaries; do not copy Global Rule routing.

- [ ] **Step 3: Update protocols and Failure Learning template terminology**

Use `Capability Invocation Result` consistently instead of `Skill Result`; change “This Skill's own failure” to the Failure Learning Capability invocation's own failure. Keep strict envelope validation assigned to Plan 36.

- [ ] **Step 4: Align the Plan 35 implementation document**

Update `docs/plan/35-core-prompt-flow/impl.md` so its completed architecture and verification targets reflect:

- minimal Core identity;
- complete route policy as sole route source;
- one public Skill;
- fifteen internal Capabilities;
- four Agent Profiles;
- generic Global Rule;
- Attribution terminology cleanup;
- static checks and replay for this closure.

Do not erase historical implementation evidence or reintroduce obsolete Spec-first tasks.

- [ ] **Step 5: Align Plan 36 boundaries without implementing them**

In `docs/plan/36-deterministic-assurance/impl.md`, replace “fifteen Skills/Unified Skill Result” with:

```text
15 internal Capability contracts
4 Agent Profile contracts
temporary Invocation envelope
transitions.yaml strict Schema
lifecycle/artifact/currentness contracts
language-neutral fixtures
```

Remove general transaction/lock/complex rollback/automatic recovery requirements. Retain minimal governed apply/fresh publish safety: pre-write validation, complete temp write, atomic replacement, completion marker, reread verification, fail closed.

- [ ] **Step 6: Align Plan 37 boundaries without implementing them**

Update `docs/plan/37-native-runtime/impl.md` so the future Go CLI consumes Plan 36-validated policy/Capability/Profile/Invocation contracts, runs temporary invocation in exclusive worktrees, observes Git baseline/status/diff/object state, and implements only minimal write safety. Explicitly exclude general locks, transactions, complex rollback, automatic recovery, cross-worktree merge, and conflict adjudication.

- [ ] **Step 7: Update the active Plan index**

In `docs/plan/README.md`, show Plan 35 as public Skill + generic Rule + complete policy + internal Capability/Profile/invocation, preserve the Plan 35 → 36 → 37 hard dependency and separate user acceptance gates, and keep Plan 80/90 outside core gates.

- [ ] **Step 8: Search for stale active references**

Search active `templates/.themis/**`, `templates/.claude/**`, and `docs/plan/**` for:

```text
.claude/skills/themis-*
fifteen Skills
十五个按需 Skill
Unified Skill Result
invoke one named Skill
```

Expected: no active reference treats the fifteen internal Capabilities as registered project Skills. Historical approved specs may retain superseded wording where the incremental design explicitly governs.

---

### Task 7: Close Attribution Terminology

**Files:**
- Modify: `templates/.themis/core/kernel/attribution/rules.md`

**Interfaces:**
- Consumes: current Plan 35 lifecycle terminology.
- Produces: a non-blocking Plan 90 observer Rule with no obsolete Specification/Archive lifecycle terms.

- [ ] **Step 1: Replace the stale outcome-correlation sentence**

Replace `supporting Specifications` with `Current Request, Questioning, Plan, or supporting delivery records`.

- [ ] **Step 2: Replace the stale non-blocking gate term**

Replace `Archive` with `lifecycle completion or completed delivery`.

- [ ] **Step 3: Verify Attribution remains outside core routing**

Confirm the Rule still says it cannot block Review, Implementation, Verification, Human Acceptance, Summary, Knowledge, or lifecycle completion and is not imported into Global Control Rule.

- [ ] **Step 4: Verify stale terms are absent**

Run:

```bash
py -3 -c "from pathlib import Path; t=Path('templates/.themis/core/kernel/attribution/rules.md').read_text(encoding='utf-8'); assert 'Specifications' not in t and 'Archive' not in t; print('attribution terminology: current')"
```

Expected: `attribution terminology: current`.

---

### Task 8: Run Static Consistency Verification

**Files:**
- Verify only: all changed Plan 35 files

**Interfaces:**
- Consumes: Tasks 1–7 implementation.
- Produces: actual observed Prompt-level structural evidence; no repository fixture suite or production-conformance claim.

- [ ] **Step 1: Verify package counts and registration boundary**

Assert:

- exactly one `templates/.claude/skills/*/SKILL.md`, under `themis`;
- exactly fifteen internal Capability contract Markdown files excluding README;
- exactly four Agent Profile contract Markdown files excluding README;
- every expected stable Capability identity appears exactly once;
- every Capability has exactly one fixed Profile mapping.

Expected summary:

```text
public skills: 1
internal capabilities: 15
agent profiles: 4
fixed mappings: 15
```

- [ ] **Step 2: Verify write and independence boundaries**

Assert only `implementation-writer.md` permits project implementation writes; all other Profiles explicitly prohibit them; `independent-checker.md` requires independent context; Verification maps to `independent-checker` and never inherits Impl write permission.

- [ ] **Step 3: Verify route completeness and uniqueness**

Re-run the Task 4 parser and assert:

```text
routes: 91
unique route keys: 91
closed vocabulary: pass
invalid_result: counted fail-closed
```

- [ ] **Step 4: Verify route legality by expected per-capability counts**

Assert exact counts:

```text
themis-q=2
themis-grounding=3
themis-complexity-assessment=3
themis-simple-plan=3
themis-spec=4
themis-planning=4
themis-plan-check=9
themis-review-projection=4
themis-review-check=4
themis-review-dialogue=12
themis-impl=7
themis-verification=11
themis-acceptance-dialogue=9
themis-failure-learning=12
themis-summary=4
```

- [ ] **Step 5: Verify Global Rule ownership contraction**

Assert the Rule describes exact-one-route lookup and `invalid_result`, but does not enumerate Capability status-to-next mappings. Confirm it still contains Review-before-Impl, independent Verification, sticky full, shared three-failure budget, Summary gate, drift/currentness stop, and assurance-unavailable language.

- [ ] **Step 6: Verify forbidden active concepts are absent**

Search active templates and plans for active claims of:

- persistent `spec.yaml`/`spec.md` authority;
- `simple-plan` as a separate artifact;
- Delivery as a top-level lifecycle stage;
- Shell fallback/runtime;
- functional module versions or `v1`/`v2`/`v3` directories;
- upgrade/migration support;
- fifteen registered lifecycle Skills;
- persistent/shared Agents, Agent voting, consensus, or Agent-to-Agent delegation;
- Attribution as a Plan 35 gate.

Historical explanation that explicitly says an item is forbidden/unsupported is allowed outside `core.yaml`; active capability claims are not.

- [ ] **Step 7: Check whitespace and review the complete dirty diff**

Run:

```bash
git diff --check
```

Expected: exit code 0; line-ending conversion warnings may be reported but no whitespace error.

Then run:

```bash
git status --short
```

Expected: all pre-existing user changes remain, Plan 35 closure paths are present, and no commit or push occurred.

---

### Task 9: Manually Replay the Revised Lifecycle

**Files:**
- Read only: public Skill, Global Rule, `transitions.yaml`, Capability/Profile contracts, templates, and Workspace guidance

**Interfaces:**
- Consumes: statically consistent Prompt-level contracts.
- Produces: observed scenario traces with input bindings, Capability/Profile, status, matched route key, action, invalidation, failure behavior, next target, and unavailable machine guarantees.

- [ ] **Step 1: Replay simple happy path**

Trace:

```text
themis-q converged
→ complexity simple-qualified with full_path_required=false
→ simple-plan ready
→ lightweight plan-check pass
→ review-projection ready
→ review-check pass
→ review-dialogue approved
→ impl implemented
→ independent verification passed
→ acceptance accepted
→ summary ready
→ completed
```

Confirm one route matches at every step, Review precedes Impl, and Summary is gated.

- [ ] **Step 2: Replay full happy path**

Trace full-required → temporary Specification → Planning → full Plan Check → common Review/Verify/Acceptance/Summary. Confirm no persistent Spec artifact and no quick-only status appears.

- [ ] **Step 3: Replay Grounding continuation behavior**

Replay `ready`, `partial`, and `blocked`; verify ready/partial require the lifecycle-bound requesting Capability continuation, partial does not imply facts are sufficient, blocked requests user unblock, and no diagnostics prose invents a target.

- [ ] **Step 4: Replay Plan and Review rework**

Replay lightweight `needs-simple-planning`, full `needs-planning`, full `needs-specification`, `needs-projection`, and Review Dialogue `needs-grounding` with explicit affected owner. Confirm exact invalidation and old Approval staleness.

- [ ] **Step 5: Replay sticky full escalation from every allowed late phase**

Replay escalation from Simple Plan, Plan Check, Review Dialogue, Impl, Verification, and Acceptance. Confirm `full_path_required` becomes true once, quick downstream is invalidated, full Specification/Planning/Review reruns, and later Complexity Assessment cannot reset the flag.

- [ ] **Step 6: Replay invalid result and policy change**

Replay unknown status, missing binding, stale digest, wrong path/profile, capability mismatch, zero route match, and duplicate route match. Confirm each uses counted `invalid_result → failure-control`. Replay policy digest change and confirm stop/revalidate rather than silent route adoption.

- [ ] **Step 7: Replay shared failure budget and Failure Learning**

Use one Plan Task Execution Identity across Impl/Verification/Acceptance repair. Confirm each counted failure records an attempt, dispatches non-blocking Failure Learning with a main-route continuation, the learning result cannot replace the route, model/session/retry changes do not reset count, and failure three terminates with no fourth invocation.

- [ ] **Step 8: Replay Acceptance and Summary gates**

Confirm no Acceptance before current Verification `passed`; `implementation-defect` returns through counted bounded repair; no Summary before durable `accepted`; Summary candidate failure does not block completion.

- [ ] **Step 9: Replay multi-lifecycle policy sharing**

Use Lifecycle A and B against the same policy identity/digest. Confirm sticky flag, current request, continuations, attempts, evidence, Acceptance, and Summary remain lifecycle-bound and cannot cross-route between A and B.

- [ ] **Step 10: Report observed assurance boundary**

For every scenario, distinguish:

- observed static route-policy consistency and manual replay result;
- unavailable strict Schema validation, canonical digest/currentness enforcement, recorder-backed transition/invalidation, atomic persistence, production Agent invocation runtime, and Go CLI behavior.

Do not call Plan 35 machine-enforced or production-conformant.

---

### Task 10: Final Plan 35 Acceptance Audit

**Files:**
- Read only: both approved Plan 35 design documents and all implementation/verification outputs

**Interfaces:**
- Consumes: all Task 1–9 results.
- Produces: a final acceptance map and explicit user gate before Plan 36 analysis resumes.

- [ ] **Step 1: Map the original Plan 35 lifecycle requirements**

Confirm Current Request, Questioning, simple/full paths, unified Plan, Review-before-Impl, Verify, Human Acceptance, Summary, sticky escalation, invalidation, and three-failure budget remain implemented.

- [ ] **Step 2: Map all fifteen incremental-design acceptance conditions**

For each condition in `2026-07-30-plan-35-policy-capability-execution-design.md` section 19, cite its concrete file and observed static/replay evidence.

- [ ] **Step 3: Classify any residual finding**

Use only:

```text
satisfied
Prompt-level satisfied / machine assurance unavailable
not satisfied
```

Any `not satisfied` item blocks Plan 35 acceptance and must be fixed before proceeding.

- [ ] **Step 4: Present the final result for explicit user acceptance**

Report changed architecture, static-check results, replay results, dirty-tree preservation, no commit/push, and exact unavailable future guarantees. Request explicit Plan 35 acceptance; do not begin Plan 36 implementation planning until accepted.
