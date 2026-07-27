# P5.4 — Context Restructure（Repo-local Knowledge System）

**优先级**：P5.4
**依赖**：[P1 Template Contract](../10-template-contract/README.md)、[P2 Top-level Guidance](../20-top-level-guidance/README.md)、[P5 Requirement Questioning](../50-requirement-questioning/README.md)
**状态**：实施设计待确认

## 目标

在当前 `themis-workspace/v1` 可表达的布局内，将 `workspace/context/` 落地为正式项目知识的唯一存储，并提供：

- L1 Abstract、L2 Overview、L3 Detail 渐进披露；
- 唯一持久 `catalog.yaml`；
- 可重建的文本索引和任务级 Context Bundle；
- Context 缺失、过期、冲突及 Context/代码漂移 Signal；
- Bash 3.2 + Git + mikefarah/yq v4 的确定性 lint、检索、装配与 freshness 操作。

完整字段、CLI、文件清单与测试矩阵见 [impl.md](impl.md)。

## 可信边界

项目事实只有两个按声明类型分工的可信源：

```text
受治理的 workspace/context/  → 项目应当是什么
当前代码、配置与 Schema       → 项目现在是什么
```

Spec、Plan、State、Run、Evidence、Outcome、Core Policy、Prompt、缓存、对话和 Agent 推断不能独立建立项目事实。Context 与代码冲突时必须生成 `context_code_drift`，不得静默选边。

Context 不拥有 Behavior Map、Anchor、第二套源码表示或语言解析层。Planning 与 Review 需要实现事实时直接核验当前源码，并记录 revision/digest。

## Workspace 与安装边界

P5.4 必须适配当前 Workspace Schema，不得：

- 引入或预留 Behavior Map、B1/B2/B3 或 Behavior Extractor；
- 创建 Migration 描述符或隐式转换已有 Workspace；
- 通过重复 Init、模板覆盖或删除 `.themis` 处理已有安装；
- 在缺少 Catalog、治理目录或受支持 Schema 时自行补建不兼容结构。

fresh Init 可安装新 Core 与目标 Workspace 骨架。已有安装若布局不受支持，Runtime 返回 `unsupported_workspace_layout` 或 `unavailable`，并保持 Workspace 字节不变。

## 与其他能力的关系

- P5.5 Knowledge Governance 消费 Context 的 Catalog、检索、Freshness 与冲突 Signal，经人工批准后执行确定性处置；
- Specification 和 Planning 消费可追溯 Context Bundle；
- Review 直接检查 current Spec、Plan、Context 与源码依据；
- Verification 使用命令 Evidence 证明实现后的 Gate 事实，不把 Context 当执行证据；
- P6 Behavior Map 已退役，不是 P5.4 的后续依赖。

## 验收条件

1. Context Item、Catalog、Bundle 与 Signal 具有稳定 Schema 和 ID。
2. `catalog.yaml` 是唯一持久注册表，缓存可全部删除重建。
3. 所有事实输出可关联 Context ID 或当前源码 path + revision/digest。
4. L1/L2 不引入 L3 中不存在的新事实。
5. unsupported layout fail closed，Runtime 不改写 Schema 或旧数据。
6. imported `rules.md` 继续满足 50 行预算。
7. Context、Template Contract、fresh Init 与相关回归测试全部通过。

## 非范围

- SQLite、向量数据库、Embedding、GraphRAG 或常驻服务；
- Tree-sitter、LSP、调用图或其他源码派生表示；
- Knowledge Promotion、生命周期编排或自动冲突裁决；
- Workspace Schema 转换、Core 原地更新或兼容层。
