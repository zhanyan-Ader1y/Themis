# Templates — 模板层

## 职责边界

Templates 保存默认工件模板。这些模板只是创建新项目工件时的初始结构，不是运行中的实际 Spec 或 Plan。

**模板是"新建文档向导"，不是"运行中的文档"。**

## 设计原则

1. **模板与实例分离**：模板在 `core/templates/`，实例在 `workspace/specs/`
2. **不可覆盖**：Core 升级模板时，不得覆盖已经创建的项目 Spec 和 Plan
3. **版本标记**：模板带有版本标记，实例创建时记录模板版本
4. **显式迁移**：旧工件需要升级时，通过 Migration 明确处理

## 模板列表

### spec.md — Spec 模板

创建新 Spec 时的初始结构：

```markdown
# Spec: <spec-id>

## 元数据
- **ID**: SPEC-XXX
- **标题**:
- **状态**: draft
- **创建时间**:
- **作者**:
- **模板版本**:

## 背景
（为什么需要这个 Spec，解决什么问题）

## 需求
### 功能需求
### 非功能需求

## 验收标准
### AC-001
**Given** ...
**When** ...
**Then** ...

## 依赖
- 依赖的 Spec:
- 依赖的 Context:

## 约束
- 技术约束:
- 时间约束:
- 资源约束:
```

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
（Task 之间的依赖关系）

## 里程碑
- M1:
- M2:
```

### review.md — Review 模板

创建新 Review 时的初始结构：

```markdown
# Review: <spec-id>

## 元数据
- **关联 Spec**: SPEC-XXX
- **评审时间**:
- **评审者**:
- **模板版本**:

## 评审维度

### 正确性
### 安全性
### 性能
### 可维护性
### 可测试性

## 发现的问题

### ISSUE-001
- **严重级别**: critical / major / minor / suggestion
- **维度**:
- **位置**:
- **描述**:
- **建议修复**:

## 评审结论
- **状态**: approved / changes_requested / blocked
```

### verify.md — Verify 模板

验证结果的记录模板：

```markdown
# Verify: <spec-id>

## 元数据
- **关联 Spec**: SPEC-XXX
- **Run ID**:
- **Git SHA**:
- **验证时间**:
- **模板版本**:

## Gate 结果

| Gate | 状态 | 证据 | 备注 |
|---|---|---|---|
| lint | pass | evidence/lint/... | |
| build | pass | evidence/build/... | |
| test | pass | evidence/tests/... | |
| schema | skip | - | 无 Schema 变更 |

## Verdict
- **结论**: pass / fail / inconclusive
- **阻塞问题**:
- **警告**:
```

### knowledge-candidate.md — 知识候选模板

新知识候选的初始结构：

```markdown
# Knowledge Candidate: <标题>

## 元数据
- **候选 ID**:
- **来源**: spec_execution / review / verification_failure / outcome_analysis
- **关联 Spec**:
- **置信度**:
- **模板版本**:

## 内容
（知识的具体内容）

## 建议分类
- 架构 / 领域 / 工程 / 决策 / 陷阱 / 术语

## 关联知识
- 相关的已有知识:
- 可能冲突的知识:
```

## 模板生命周期

```
core/templates/spec.md
        ↓ 初始化（创建新 Spec 时）
workspace/specs/SPEC-001/spec.md
        ↓ 独立演进
（Core 模板升级不影响已有实例）
```

## 与 Workspace 的交互

```
Templates 读取:
  （无——Templates 是纯静态资源）

Templates 被使用:
  创建新 Spec 时 → 复制 spec.md 模板
  创建新 Plan 时 → 复制 plan.md 模板
  创建新 Review 时 → 复制 review.md 模板
  记录验证结果时 → 复制 verify.md 模板
  提交知识候选时 → 复制 knowledge-candidate.md 模板
```