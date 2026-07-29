# README Product Overview Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite the root README as a concise product overview centered on Themis's stable characteristics and target capabilities.

**Architecture:** Replace implementation-oriented architecture, state-machine, failure-budget, knowledge-model, and Plan sequencing sections with a low-volatility product narrative. Preserve an explicit maturity boundary and route detailed readers to existing design and contract documents.

**Tech Stack:** Markdown, Git link validation

## Global Constraints

- Modify only `README.md` during implementation.
- Preserve the four core product characteristics defined by `AGENTS.md`.
- Present the lifecycle only as: 理解需求 → 设计与评审 → 实现与验证 → 验收与知识沉淀.
- Describe unimplemented capabilities as target capabilities, never as currently available features.
- Keep exactly one concise current-status statement and link detailed status to the activity plan.
- Do not include Rule / Skill / Agent internals, failure counting, Plan dependency order, or Themico storage structures.

---

### Task 1: Rewrite the product overview

**Files:**
- Modify: `README.md:1-132`

**Interfaces:**
- Consumes: Product identity from `AGENTS.md` and approved design from `docs/superpowers/specs/2026-07-29-readme-product-overview-design.md`.
- Produces: A product-facing root README with stable navigation links.

- [ ] **Step 1: Replace the README body**

Write these sections in order:

```text
项目定位
核心特性
核心流程
核心能力
当前状态
文档
许可证
```

The core flow must be exactly:

```text
理解需求
→ 设计与评审
→ 实现与验证
→ 验收与知识沉淀
```

The current status must state that Themis remains in design and installation-package contract reconstruction, the target flow is not yet a runnable product, and detailed status belongs in the activity plan.

- [ ] **Step 2: Check required product language**

Verify `README.md` contains all of:

```text
Spec 前追问
更轻松的 Review
外部经验可沉淀
不断进化的项目知识库
理解需求
设计与评审
实现与验证
验收与知识沉淀
目标能力
```

- [ ] **Step 3: Check implementation details were removed**

Verify the product body no longer explains:

```text
Global Control Rule
revision / digest
attempt 1 failed
Plan 35 → Plan 36
Knowledge Record
L1 / L2 / L3
```

Design names may remain only in documentation-link labels.

- [ ] **Step 4: Validate Markdown and links**

Run:

```bash
git diff --check -- README.md
```

Expected: exit code 0 with no whitespace errors.

Confirm every relative link in `README.md` resolves to an existing file.

- [ ] **Step 5: Review the final diff**

Run:

```bash
git diff -- README.md
```

Expected: the diff only simplifies the root README and does not modify other files.

Do not commit unless the user explicitly requests it.
