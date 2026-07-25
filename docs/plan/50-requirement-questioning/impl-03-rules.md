# P5 子模块：规则引擎

## 覆盖任务

- 任务 4：更新 `specification/rules.md`

## 设计依据

- **D1**：追问在 Spec-Validation 之前 → rules 中先描述追问流程，再描述校验
- **D4**：中间状态不持久化 → 追问完成后写 spec.md 草稿，不在 state/ 中持久化 Step 进度
- **D5**：Red Flags 嵌入 Prompt → rules 中列出防绕过规则但不定义触发机制（触发机制在 spec-questioning.md 的 Prompt 中）

## 目标文件：`specification/rules.md`

**路径**：`templates/.themis/core/kernel/specification/rules.md`

### 当前状态

当前文件包含：
- Responsibility（职责声明）
- Inputs / Outputs
- Boundaries（含占位句："Requirement-questioning depth, approval mechanics, Spec templates, validation, and the Draft → Specified gate belong to the later Requirement Questioning capability"）

### 变更内容

1. **保留** Responsibility、Inputs、Outputs 结构
2. **新增** `Requirement Questioning` 段（在 Boundaries 之前）
3. **更新** Boundaries 段：移除占位句，替换为实际的追问相关边界
4. **新增** `Red Flags` 段
5. **新增** `Spec Self-Check` 段
6. **新增** `References` 段：引用 policy 和 template 文件

### 目标内容

```markdown
# Themis Specification

## Responsibility

Define what a project change must achieve, why it is needed, its approved
scope, and what evidence will demonstrate acceptance. Specification owns
intent and acceptance criteria, not implementation design.

## Inputs

- the user's stated goal and constraints;
- relevant facts from `workspace/context/`;
- existing related artifacts under `workspace/specs/`;
- current code or configuration only when needed to resolve factual scope.

## Outputs

Save Specification artifacts only beneath the associated
`workspace/specs/<spec-id>/` area. Keep acceptance criteria stable and
identifiable so Planning and later evidence can trace back to them.

During Draft, write a `spec.md` draft after Step 3 Design Convergence.
The draft becomes the approved Spec only after Step 4 Adversarial
Validation and explicit user approval.

---

## Requirement Questioning

Before validating a Spec, drive it from a vague intent to an approved,
actionable document through a four-step process. The process adapts
its depth to the assessed complexity of the request.

### Complexity Levels

| Level | Criteria | Flow |
|---|---|---|
| low | ≤1 file, no new API, no state change | Step 0 (1 round) → 1 → skip 2 → 3 (1 option) → 4 (quick) |
| medium | ≤8 files, ≤3 new APIs, may change state | Step 0 (full) → 1 → 2 → 3 (full) → 4 (focused) |
| high | above medium thresholds | Step 0-4 all full; Step 4 may iterate |

Complexity is assessed at the end of Step 1 and must be confirmed by
the user. The assessment rules are in `core/policies/specification.yaml`.

### Step 0 — Intent Discovery

Ask "why" until the root cause is clear. Distinguish what the user
asks for from what the user needs. If the root cause points to a
different solution, offer it. Use the prompt template in
`core/templates/spec-questioning.md`.

### Step 1 — Scope Assessment

Determine whether the request spans multiple subsystems. If it does,
propose decomposition and focus on one sub-project first. Run a
Pre-mortem: list the three most likely failure causes. Identify
critical assumptions. Assign a complexity level and request user
confirmation.

### Step 2 — Context Gathering

Collect goals, constraints, and measurable success criteria.
Ask Option Zero: can the problem be solved without code changes?
Build an assumption list with verification methods. Anchor key
decisions in data, experience, or documented constraints.

Skip this step for low-complexity requests.

### Step 3 — Design Convergence

Propose 2–3 options with trade-offs and a recommendation. Run a
first-pass adversarial check: what is the most likely failure mode
for each option? Segment ACs into groups of 1–3 and confirm each
group with the user. Write the draft to
`workspace/specs/<spec-id>/spec.md`. Run the self-check.

For low-complexity requests, propose 1 option with 1–2 core ACs.

### Step 4 — Adversarial Validation

Switch stance: attack the Spec to find gaps, uncovered edge cases,
and hidden assumptions. Use the standard attack scenario library in
`core/templates/spec-adversarial-checklist.md`. For each uncovered
scenario the user chooses: cover (modify Spec), accept (record as
Limitation), or defer (mark for a later release).

Continue until no new effective attack scenario remains, or until
the iteration limit defined in `core/policies/specification.yaml`
is reached.

For low-complexity requests, use only the five-item quick checklist.

### Approval Gate

After Step 4, the user must explicitly approve the Spec. Only then
may the Orchestrator record the `Draft → Specified` transition.
The hard-gate conditions are defined in
`core/policies/transitions.yaml`.

---

## Boundaries

- Do not write implementation code or choose task ordering.
- Do not treat an unresolved draft as approved.
- Do not invent project facts when Context is missing or conflicting.
- Return scope changes discovered later to Specification before
  implementation continues.
- Do not skip adversarial validation, even for simple requests
  (use the quick checklist).
- Do not mark a Spec as approved without explicit user confirmation.
- Do not write unreviewed observations directly into authoritative
  Context during questioning.

---

## Red Flags

The following patterns signal that questioning is being bypassed.
When any of them is detected, stop and return to the appropriate step.

| Pattern | Required Action |
|---|---|
| "This is simple, let's just code it" | Route to Step 4 quick checklist; do not enter Implementation |
| "I'll read the code first to understand" | Read Context first, then question, then code. State the hypothesis to verify |
| "We don't need a formal Spec for this" | Every change requires a Spec. Size scales with complexity |
| "The user has been clear enough" | Raise at least one scenario the user may not have considered |
| "Let me try one line first" | No code change before Step 0 intent confirmation |
| "This solution is obviously the best" | Propose at least one alternative, even if it is rejected |

---

## Spec Self-Check

After writing `spec.md`, verify the following before proceeding to
approval.

### Structural

- [ ] No placeholders (TODO, FIXME, TKTK)
- [ ] No internal contradictions
- [ ] No ambiguous terms without quantification
- [ ] Scope boundaries are explicit

### Adversarial

- [ ] Critical assumptions are listed with verification methods
- [ ] Each AC has at least one failure / edge-case consideration
- [ ] Key decisions cite data, experience, or constraints
- [ ] Limitations discovered during adversarial validation are
      recorded in the Spec's Limitation section
- [ ] The design addresses the root cause, not only the surface request
- [ ] A rollback path is described (if applicable)

---

## References

- Questioning policy: `core/policies/specification.yaml`
- Transition gates: `core/policies/transitions.yaml`
- Prompt templates: `core/templates/spec-questioning.md`
- Attack scenario library: `core/templates/spec-adversarial-checklist.md`
```

### 变更对比

| 段 | 变更类型 | 说明 |
|---|---|---|
| Responsibility | 保留 | 无变更 |
| Inputs / Outputs | 保留 + 微调 | Outputs 增加 Draft 阶段写入说明 |
| Requirement Questioning | **新增** | 四步流程、复杂度自适应、批准门禁 |
| Boundaries | 重写 | 移除占位句，新增 3 条追问相关边界 |
| Red Flags | **新增** | 6 条绕过模式及其约束 |
| Spec Self-Check | **新增** | 结构 4 项 + 对抗 6 项 |
| References | **新增** | 引用 4 个关联文件 |

## 验证要求

- 不再包含 `"later Requirement Questioning capability"` 占位声明
- 新增的 `Requirement Questioning` 段完整描述 Step 0–4
- `References` 段引用的 4 个路径与实际文件一致
- `Red Flags` 段包含 analysis.md 中定义的 6 条规则
- `Spec Self-Check` 包含 10 项检查（4 结构 + 6 对抗）
- 与 `specification.yaml` 中的 complexity 规则一致
