# Specification — 规范定义

## 职责边界

Specification 定义 Spec 的结构、语义和验收标准（Acceptance Criteria）。它只关心"Spec 应该长什么样、是否合法"，不关心 Spec 的内容是否合理（那是 Planning 和 Review 的职责）。

## 核心能力

| 能力 | 说明 |
|---|---|
| Spec 结构定义 | 定义 Spec 文档的必需字段、可选字段和结构约束 |
| 语义校验 | 校验 Spec 内容的结构完整性和语义一致性 |
| 验收标准定义 | 定义 AC 的格式、粒度和可验证性要求 |

## 子模块

### Spec-Model — Spec 结构模型

定义 Spec 的完整结构模型：

- **必需字段**：ID、标题、状态、创建时间、作者
- **可选字段**：标签、优先级、依赖、关联上下文
- **需求描述**：结构化需求（用户故事、功能需求、非功能需求）
- **验收标准**：可验证的 AC 列表
- **关联关系**：与其他 Spec、Context、Plan 的引用

**边界**：Spec-Model 是结构定义，不是内容模板。实际创建 Spec 时使用 `core/templates/spec.md` 作为初始模板。

### Spec-Validation — Spec 校验

对 Spec 进行结构化和语义化校验：

- 必填字段完整性检查
- 引用完整性检查（引用的 Context、依赖的 Spec 是否存在）
- AC 可验证性检查（AC 是否模糊、是否可测试）
- 与 Plan 的一致性检查（Plan 是否覆盖了所有 AC）

**边界**：Spec-Validation 只校验结构正确性，不评估内容质量（那是 Review 的职责）。

### Acceptance-Criteria — 验收标准

定义验收标准的规范：

- AC 格式：`Given-When-Then` 或等价结构化格式
- AC 粒度：一个 AC 对应一个可验证的行为
- AC 可验证性：每个 AC 必须可被至少一个 Gate 验证
- AC 与 Plan Task 的可追踪性：每个 AC 必须被至少一个 Task 覆盖

**边界**：AC 定义的是"验证什么"，不是"如何验证"（那是 Verification 的职责）。

## 与 Workspace 的交互

```
Specification 读取:
  workspace/specs/<spec-id>/spec.md   # 当前 Spec 内容
  workspace/context/                   # 引用的上下文

Specification 写入:
  （无直接写入 — 校验结果通过 Verification 模块的 Gate 机制记录）
```

## 输入/输出协议

- **输入**：通过 Spec Artifact Protocol 读取和解析 Spec 文档
- **输出**：校验结果通过 Gate Result Protocol 传递给 Verification 模块