# P5.5 — 人机混合知识治理

**优先级**：P5.5（可独立于 P6/P8 提前实施）
**依赖**：[P1 Template Contract](../10-template-contract/README.md)、[P2 Top-level Guidance](../20-top-level-guidance/README.md)
**状态**：待用户主动发起

## 背景

Themis 在 `docs/design/workflow.md` 和 `docs/design/core/kernel/knowledge.md` 中已定义了知识治理的完整理论模型——从候选识别、去重、冲突检查、审核、提升到废弃的闭环流程。但该模型目前仅存在于文档层面：

- `core/kernel/knowledge/rules.md` 定义了模块边界，但内容为基线占位
- 无治理策略文件（`knowledge-governance.yaml`）
- 无知识审核模板
- 无候选提取 Prompt 模板

P5 需求追问的方法论分析揭示了一个关键设计原则——**AI 生成候选，人工确认提升**——这一原则同样适用于知识治理，但目前尚未落地为可执行的 Prompt 指令和策略配置。

## 目标

将知识治理从文档化的理论模型落地为可执行的能力层：

1. 定义知识治理策略（审核标准、去重阈值、提升规则）
2. 编写知识候选提取 Prompt 模板（从执行、验证、评审中提取教训）
3. 编写知识审核 Prompt 模板（结构化审核候选）
4. 更新 `knowledge/rules.md` 使其不再为占位状态
5. 同步更新 WIKI 文档

## 人机职责边界

| 环节 | AI（自动或 Prompt 驱动） | 人工（门禁确认） |
|---|---|---|
| 候选发现 | 从执行、验证失败、评审发现、Outcome 中提取模式 | 可补充遗漏 |
| 候选去重 | 语义相似度检索、标记潜在重复 | 决定是否合并 |
| 冲突检查 | 标记与已有知识的潜在冲突 | 裁决哪一条有效 |
| 审核 | 按标准逐项检查，给出推荐（promote/reject/revise） | 最终决定 |
| 提升 | 执行文件移动、索引更新 | 确认提升 |
| 废弃 | 根据新鲜度标记提出候选 | 确认知识确实过时 |

## 核心原则

1. **单一权威源**：`workspace/context/` 是唯一正式知识存储，`workspace/knowledge/` 是治理工作流数据
2. **AI 不许直接写 Context**：未经人工审核，AI 不得将观察性结论写入 `workspace/context/`
3. **候选可追溯**：每个知识候选必须引用其来源（哪个 Spec、哪次 Run、哪次 Review）
4. **去重先于审核**：先检查是否已有类似知识，避免重复审核
5. **废弃需确认**：Context Freshness 标记过期 ≠ 自动废弃，需人工确认

## 知识流转流程

```
执行过程（Task / Verification / Review / Outcome）
        │
        ▼
  候选识别（AI 提取）
        │
        ▼
  workspace/knowledge/candidates/
        │
        ├── 去重（与已有 Context 和候选比较）
        ├── 冲突检查（标记矛盾）
        │
        ▼
  结构化审核（AI 辅助 + 人工决策）
        │
        ├── promote → workspace/context/{architecture,domain,engineering,decisions,pitfalls}
        ├── reject  → workspace/knowledge/rejected/
        └── revise  → 修改后回到 candidates
        │
        ▼
  索引更新（context-map 刷新）
        │
        ▼
  新鲜度监控（Context Freshness）
        │
        └── 过期候选 → 人工确认 → workspace/knowledge/archive/
```

## 目标文件

| # | 文件 | 操作 | 说明 |
|---|---|---|---|
| 1 | `templates/.themis/core/policies/knowledge-governance.yaml` | 新建 | 审核标准、去重阈值、提升规则 |
| 2 | `templates/.themis/core/templates/knowledge-candidate-extraction.md` | 新建 | AI 候选提取 Prompt（从各类源头提取知识候选） |
| 3 | `templates/.themis/core/templates/knowledge-review.md` | 新建 | AI 审核 Prompt（结构化审核候选） |
| 4 | `templates/.themis/core/kernel/knowledge/rules.md` | 更新 | 从占位内容更新为完整的治理规则 |
| 5 | `docs/design/core/kernel/knowledge.md` | 更新 | 同步 WIKI 文档 |

## 验收条件

- `knowledge-governance.yaml` 定义审核维度、去重策略、提升规则
- `knowledge-candidate-extraction.md` 覆盖至少 4 种候选来源（Task 执行、Verification 失败、Review 发现、Outcome 分析）
- `knowledge-review.md` 包含结构化审核框架（准确性、完整性、冲突、可操作性）
- `knowledge/rules.md` 不再包含占位内容
- 知识流转路径可追踪（从候选到正式 Context 或拒绝/归档）
- AI 不能绕过人工审核直接写入 Context（硬约束嵌入 Prompt）

## 非范围

- 不实现确定性 Shell 脚本（留待 P8）
- 不实现自动语义去重（需要 embedding 基础设施）
- 不修改 Workspace 目录结构（已由 P1 定义）
- 不实现 Context Freshness 的自动化检测（属于 P6 Behavior Map 范围）

## 风险与回滚

- **风险**：知识候选过多，人工审核负担重 → **缓解**：去重先过滤；低置信度候选自动降级
- **风险**：AI 审核判断不准确 → **缓解**：AI 只给推荐，最终决定权在人工
- **回滚**：移除新增的 policy/template 文件，恢复 rules.md 到基线版本
