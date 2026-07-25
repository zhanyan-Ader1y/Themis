# Templates — 模板层

## 职责边界

Templates 保存默认工件模板和按需 Prompt 模板。它们是创建新工件或驱动特定流程的初始结构，不是运行中的项目事实。

**模板是“新建文档向导”，不是“运行中的文档”。**

## 设计原则

1. **模板与实例分离**：Core 模板在 `core/templates/`，实例在 `workspace/specs/` 等项目目录。
2. **不可覆盖**：Core 升级模板时，不得覆盖已经创建的项目工件。
3. **版本标记**：结构化工件模板带版本标记，实例创建时记录模板版本。
4. **显式迁移**：旧工件需要升级时，通过显式 Migration 处理，不因 Core Upgrade 被重写。
5. **Prompt/脚本分工**：Prompt 处理语义判断和用户交互；脚本只处理确定性、可验证操作。

## 模板列表

### spec.md — Spec 模板

`core/templates/spec.md` 是 P5 创建新 Draft Spec 的真实模板，前置元数据使用 `themis-spec/v1`：

```yaml
spec_schema: themis-spec/v1
id: ""
title: ""
status: draft
template_version: 1
complexity: pending
approval:
  decision: pending
```

正文提供稳定章节：`Intent and Root Cause`、`Scope`、`Context, Constraints, and Evidence`、`Options and Decision`、`Requirements`、`Acceptance Criteria`、`Assumptions`、`Adversarial Validation`、`Limitations and Deferred Work`、`Rollback` 和 `Approval`。

AC 使用 `AC-xxx`，对抗发现使用 `ADV-xxx`。P5 记录批准证据但保持 Draft；未来 P8 执行器才记录生命周期迁移。

### plan.md — Plan 模板

创建新 Plan 时的初始结构：

```markdown
# Plan: <spec-id>

## 元数据
- **关联 Spec**: SPEC-XXX
- **创建时间**:
- **模板版本**:

## 任务分解

### TASK-001: <任务标题>
- **类型**: 实现 / 测试 / 重构 / 文档
- **覆盖 AC**: AC-001
- **依赖**: 无
- **完成标准**:
- **预估工作量**:

## 依赖图

## 里程碑
```

### review.md — Review 模板

Review 模板记录关联 Spec、评审维度、结构化发现和结论。结论必须是 `approved`、`changes_requested` 或 `blocked`，且不能替代 Verification 的 Gate 事实。

### verify.md — Verify 模板

Verify 模板记录关联 Spec、Run ID、Git SHA、各 Gate 的证据和 `pass`、`fail` 或 `inconclusive` Verdict。

### knowledge-candidate.md — 知识候选模板

知识候选模板记录来源、关联 Spec、置信度、内容、建议分类与相关知识。它是治理候选，不是未经审核的正式 Context。

### spec-questioning.md — 需求追问 Prompt

P5 的五阶段 Prompt：Step 0 意图发现、Step 1 范围评估、Step 2 上下文收集、Step 3 设计收敛、Step 4 对抗验证。它定义一次一问、复杂度自适应、Draft 写入、明确用户批准和 P8 状态迁移边界。

### spec-adversarial-checklist.md — 对抗验证场景库

P5 的按需攻击库提供 low 的五项快速检查，以及边界条件、并发与竞态、状态转换、权限与安全、依赖失败、数据完整性六个维度的可复用场景。

### migration-execution.md — 迁移执行 Prompt

P4.5 的迁移引导模板声明检查、备份、执行、验证和回滚脚本，并要求用户确认。它不替代迁移脚本的确定性输出。

## 模板生命周期

```text
core/templates/spec.md
        ↓ 初始化
workspace/specs/SPEC-001/spec.md
        ↓ 项目独立演进
Core 模板升级不影响已有实例
```

## 与 Workspace 的交互

```text
Templates 读取:
  （无——Templates 是纯静态 Core 资源）

Templates 被使用:
  创建新 Spec 时 → 复制 spec.md 模板
  创建新 Plan 时 → 复制 plan.md 模板
  记录 Review / Verify / Knowledge 候选时 → 复制相应模板
  Draft 追问时 → 读取 P5 Prompt 与攻击场景库
```
