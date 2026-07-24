# P6 — Behavior Map & Change Localization（代码行为地图与变更定位）

**优先级**：P6
**依赖**：[P1 Template Contract](../10-template-contract/README.md)、[P5 Requirement Questioning](../50-requirement-questioning/README.md)
**状态**：待用户主动发起

## 背景

Themis 当前以 Spec 为 SDD 入口，但缺少从"需求 → 代码位置"的结构化映射能力。一个 Spec 需求往往跨越多个模块，当前只能靠 Agent 自行搜索，效率低且容易遗漏。

## 参考来源

Harness Handbook（Ruhan Wang et al., arXiv 2607.13285）提出了一种行为导向的代码表示方法：通过静态分析 + LLM 结构化，将分散在多个模块中的实现按"行为路径"重组为三个层次的手册，并用该手册引导 Agent 精确定位变更位置。实验证明手册辅助的规划器在分散代码点、罕见执行路径和跨模块交互上的定位准确率更高，token 消耗更低。

完整研究页面已归档至 [docs/references/harness-handbook.html](../../references/harness-handbook.html)。

## 目标

将 Harness Handbook 的行为地图（Behavior Map）和变更定位（Change Localization）方法论适配到 Themis，作为 Context 模块的**自动化代码事实提取**能力和 Planning 模块的**Task → Code 定位**能力。

## 核心设计

### 行为地图的三层模型（适配到 Themis）

Handbook 的三层（L1/L2/L3）映射到 Themis 的 Spec 层级：

| Handbook 层 | Themis 对应 | 职责 |
|---|---|---|
| L1 — System overview | System Context | 项目整体架构、模块关系、请求生命周期 |
| L2 — Behavior-unit overview | Component Context | 按行为域拆分的模块职责、输入输出、状态 |
| L3 — Behavior-unit detail | Code Evidence | 具体行为的触发条件、执行路径、代码锚点 |

### BGPD（行为引导的渐进披露）适配

```
Handbook 工作流: Behavior question → L1 → L2 → L3 → Code evidence
Themis 适配:     Spec AC → System Context → Component Context → Code Evidence → Task 定位
```

这个同一证据路径服务于 Themis 的三个场景：

| 场景 | Themis 模块 |
|---|---|
| **Understand** — 理解系统 | Context Discovery |
| **Audit** — 验证行为是否成立 | Verification Evidence |
| **Adapt** — 定位变更边界 | Planning Traceability |

### 变更定位子系统

Handbook 的 planner 模式（只读 planner + SKILL + 按需读源码）适配到 Themis 的 Planning 模块：

```
输入：Spec AC 列表 + 行为地图
  ↓
Planner 读取 L1 → 定位到相关 Stage
  ↓
Planner 读取 L2 → 定位到相关 Behavior Unit
  ↓
Planner 读取 L3 → 获取 Code Evidence（具体文件和函数）
  ↓
输出：Task → Code 定位映射，写入 Plan 的 Traceability 字段
```

**关键设计约束**（来自 Handbook 的经验）：

- **Planner 只读不写**：planner 只输出定位方案，不修改代码
- **事实先行**：LLM 写说明文字，但每个声明必须锚定在静态分析提取的代码事实上
- **按需读源码**：Planner 通过手册路由到具体文件后才读源码，不是全文扫描

### 行为地图生成管线

适配自 Handbook 的 `handbook_generate_large/` 管线，但 Themis 只需要其 "代码事实提取 + 行为归类" 部分：

```
Phase 1 — Extract Facts（无 LLM）
  ├── tree-sitter 静态分析（Python/Rust/TS/Go）
  ├── 输出 call graph + function inventory
  └── 实现于 core/adapters/schema/behavior-extractor/

Phase 2 — Classify by Behavior（LLM 辅助）
  ├── 将函数按行为域归类
  ├── 组织为 System → Component → Detail 三层
  └── 实现于 core/kernel/context/discovery/rules.md

Phase 3 — Store as Context（写入 Workspace）
  ├── 存入 workspace/context/architecture/behavior-map/
  ├── 包含三层手册 + 代码锚点索引
  └── 由 Context Discovery 维护新鲜度
```

### Facts-First 规则

从 Handbook 直接引入的核心规则：

> 自然语言解释行为，但每个声明必须锚定在代码事实上。LLM 写 prose，但 source links、函数引用和代码片段必须来自提取的程序事实。文字解释，事实锚定。

### 与 Themis 模块的整合

```
Context 模块:
  ├── Discovery → 行为地图生成管线（新增）
  ├── Resolution → 行为地图三层解析（新增）
  ├── Conflict → 行为漂移检测（版本间的行为变化，新增）
  └── Freshness → 行为地图过期标记（代码变更后触发重生成）

Planning 模块:
  └── Traceability → AC → Behavior Unit → Code Location 的精确映射（增强）

Verification 模块:
  └── Evidence → 行为地图驱动的 Gate 证据定位（增强）
```

## 范围

- 定义行为地图的三层模型（System/Component/Detail）及其在 workspace/context/ 中的存储结构
- 设计变更定位的 planner 模式（只读、按需读源码、输出 Task → Code 映射）
- 适配 Facts-First 规则到 Themis 的 Context Protocol
- 定义静态分析 Adapter 的接口（支持 Python/Rust/TypeScript/Go/SQL）
- 与 Planning 的 Traceability 子模块集成

## 非范围

- 不实现 Handbook Studio 的交互式 UI
- 不实现 Handbook Resync 机制的全自动版本（Themis 采用手动触发重生成 + 新鲜度标记）
- 不实现 actor-critic skeleton 收敛循环的完整版本（首版用简单的文件→Stage 分类）
- 不改变 Planning 的核心 Task 模型结构
- 不支持无源码的二进制依赖的行为映射

## 目标文件

- `docs/core/kernel/context.md`（更新：增加行为地图生成管线说明）
- `docs/core/kernel/planning.md`（更新：增加变更定位说明）
- `core/adapters/schema/behavior-extractor/`（新增：tree-sitter 静态分析 Adapter）
- `workspace/context/architecture/behavior-map/`（模板中的行为地图存储结构）
- `core/policies/context.yaml`（新增：行为地图生成策略）

## 执行前置步骤

当用户主动发起本计划时，**第一步**必须在本计划目录创建或更新 `impl.md`（`docs/plan/60-behavior-map/impl.md`），至少记录：

1. 行为地图三层模型的精确 Schema（L1/L2/L3 的字段定义）
2. 静态分析 Adapter 的支持语言列表、tree-sitter parser 选择和接口契约
3. 变更定位 planner 的输入/输出协议
4. Facts-First 规则的验证方式（如何确保 LLM 声明不脱离代码事实）
5. 行为地图刷新策略（全量重生成 vs 增量更新）
6. 与 Planning Traceability 的精确集成点

`impl.md` 经用户确认前，不得修改目标文件。

## 验收条件

- 静态分析 Adapter 能从 Python/TypeScript 项目中提取 call graph 和 function inventory
- 生成的行为地图包含 L1（系统概览）、L2（行为单元概览）、L3（行为单元详情+代码锚点）
- Planner 在给定 Spec AC 后输出的定位结果命中率 > 80%（对比人工标注）
- 行为地图生成时间在 10 万行代码项目上 < 5 分钟
- 代码变更后，相关行为地图项被标记为"可能过期"

## 风险与回滚

- **风险**：静态分析对动态语言（Python/JS）的精度不足，call graph 不完整
- **缓解**：结合 LLM 补全缺失的边；标记 confidence level；对低置信度边不做硬依赖
- **风险**：行为归类依赖 LLM 质量，不同模型产生不同分类
- **缓解**：行为归类记录模型和版本；支持手动调整；归类结果视为"建议"而非"权威"
- **回滚**：行为地图是 Context 的派生数据，可整体删除而不影响 Spec/Plan/Evidence；移除后 Planning 回退到全文搜索
