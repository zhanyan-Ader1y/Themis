# P6 — Behavior Map & Change Localization（代码行为地图与变更定位）

> **Deferred/Superseded — 2026-07-28**：Behavior Map 已从当前产品设计、模板和运行路由中移除，以避免扩张 Themis 职责。本文仅保留历史研究与方案；Planning/Review 当前直接核验源码，未来若重启本方向必须重新确认设计。

**优先级**：P6
**依赖**：[P1 Template Contract](../10-template-contract/README.md)、[P5 Requirement Questioning](../50-requirement-questioning/README.md)、[P5.4 Context Restructure](../54-context-restructure/README.md)
**状态**：待用户主动发起

## 背景

Themis 当前以 Spec 为 SDD 入口，但缺少从"需求 → 代码位置"的结构化映射能力。一个 Spec 需求往往跨越多个模块，当前只能靠 Agent 自行搜索，效率低且容易遗漏。

## 参考来源

Harness Handbook（Ruhan Wang et al., arXiv 2607.13285）提出了一种行为导向的代码表示方法：通过静态分析 + LLM 结构化，将分散在多个模块中的实现按"行为路径"重组为三个层次的手册，并用该手册引导 Agent 精确定位变更位置。实验证明手册辅助的规划器在分散代码点、罕见执行路径和跨模块交互上的定位准确率更高，token 消耗更低。

完整研究页面已归档至 [docs/references/harness-handbook.html](../../references/harness-handbook.html)。

## 目标

将 Harness Handbook 的行为地图（Behavior Map）和变更定位（Change Localization）方法论适配到 Themis，作为 Context 模块的**自动化代码事实提取**能力和 Planning 模块的**Task → Code 定位**能力。

## 实施状态与所有权

P6 是已确认的设计方向，但尚未获得实施授权。当前只有 Workspace 预留目录和基线 Context/Planning 边界；静态分析 Adapter、生成策略、Prompt、脚本、Schema 和变更定位执行器均未安装。

领域所有权如下：

| 能力 | 所有者 | 边界 |
|---|---|---|
| 行为事实提取 | 语言 Adapter | 只输出受支持的语法、符号和关系事实，不编写行为解释 |
| 行为归类与说明 | Context Prompt | 基于锚点组织 B1/B2/B3，不创造无证据事实 |
| Map 校验、存储与新鲜度 | Context | 管理派生 Context，不决定需求或实施方案 |
| AC 变更定位 | Planning | 只读生成候选范围和可追溯性，不修改代码或扩大 Plan |
| Gate 发现辅助 | Verification | 可用锚点寻找相关检查，但 Map 本身不是 Gate evidence 或 verdict |
| 路由 | Orchestrator | 只在已验证 P6 能力存在时路由，不模拟缺失执行器 |
| 派生数据治理 | Context | Behavior Map 可重新生成，不经过 Knowledge 的人工知识提升流程 |

## 核心设计

### 行为地图的 B1/B2/B3 模型

Handbook 原始 L1/L2/L3 思想在 Themis 中改名为 B1/B2/B3，避免与 P5.4 Context 的知识披露层冲突：

| Handbook 层 | Themis 持久名称 | 职责 |
|---|---|---|
| L1 — System overview | B1 System | 项目整体架构、模块关系、请求生命周期导航 |
| L2 — Behavior-unit overview | B2 Behavior Unit | 按行为域拆分的职责、输入输出、状态与关系导航 |
| L3 — Behavior-unit detail | B3 Evidence | 绑定 revision 的文件、符号、分支、副作用、路径和代码锚点 |

B1/B2 是 `derived_navigation`，必须引用 B3；只有 `current` 且受支持的 B3 Anchor 可以支撑当前实现事实。

### BGPD（行为引导的渐进披露）适配

```
Handbook 工作流: Behavior question → L1 → L2 → L3 → Code evidence
Themis 适配:     Spec AC → B1 System → B2 Behavior Unit → B3 Evidence → 当前代码核验 → Task 定位
```

这个同一证据路径服务于 Themis 的三个场景：

| 场景 | Themis 模块 |
|---|---|
| **Understand** — 理解系统 | Context Discovery |
| **Audit** — 发现需要核验的行为和检查位置 | Verification Check Discovery（Anchor 不是 Evidence） |
| **Adapt** — 定位变更边界 | Planning Traceability |

### 变更定位子系统

Handbook 的 planner 模式（只读 planner + SKILL + 按需读源码）适配到 Themis 的 Planning 模块：

```
输入：Spec AC 列表 + 行为地图
  ↓
Planner 读取 B1 → 定位到相关系统边界
  ↓
Planner 读取 B2 → 定位到相关 Behavior Unit
  ↓
Planner 读取 current B3 → 获取候选文件、符号和 Anchor
  ↓
Planner 读取当前代码 → 核验现行实现事实
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
  ├── 使用 P6 impl 确认的 parser/Adapter 提取受支持事实
  ├── 分能力输出 symbol inventory + relation/call graph + anchors
  └── 实现于已安装 core/adapters/schema/behavior-extractor/

Phase 2 — Classify by Behavior（LLM 辅助）
  ├── 将函数按行为域归类
  ├── 组织为 B1 System → B2 Behavior Unit → B3 Evidence
  └── 实现于 core/kernel/context/discovery/rules.md

Phase 3 — Store as Context（写入 Workspace）
  ├── 存入 workspace/context/architecture/behavior-map/
  ├── 包含 B1/B2 导航 + B3 代码锚点索引
  └── 由 Context Discovery 维护新鲜度
```

### 输入契约

Behavior Map 生成只接受可验证的项目输入：

- manifest 指定范围内的源码、配置、Schema、路由和构建元数据；
- include/exclude 规则及项目根边界；
- Git revision 或文件内容摘要；
- 已安装 Adapter 的真实能力声明和确定性输出；
- 手工触发的生成范围。

Change Localization 额外读取：

- 已批准 Spec 的 AC；
- 相关的正式 Context；
- 与当前源码 revision 匹配且新鲜度可接受的 Behavior Map。

文件不可读、revision 不一致或 Adapter 不支持时必须产生 `unknown`/`unsupported`，不能由 LLM 补造事实。

### 输出与存储契约

P6 生成的全部项目数据位于：

```text
workspace/context/architecture/behavior-map/
```

最小产物集合包括：

| 产物 | 内容 |
|---|---|
| B1 System | 系统边界、入口、模块关系和端到端生命周期路径导航 |
| B2 Behavior Units | 行为单元职责、输入、输出、状态、依赖和跨模块关系导航 |
| B3 Evidence | 绑定 revision 的文件、符号、触发、分支、副作用、失败路径和证据锚点 |
| Symbol Inventory | 文件、符号、函数、类型、路由、Schema 等确定性清单 |
| Relation Graph | 受 Adapter 支持的调用、引用、数据流或依赖关系 |
| Anchor Index | 声明与源码/配置事实之间的稳定引用 |
| Generation Metadata | Map Schema、源码 revision、Adapter 版本、语言覆盖、置信度、生成时间和新鲜度 |

这些文件是派生 Context；可重新生成，但在被 Plan 或审计引用期间必须保留其 revision 和摘要，以便复核历史结论。

### Evidence Anchor 契约

每条事实性说明必须引用一个或多个稳定 Anchor ID。每个锚点至少记录：

```yaml
id: ANCHOR-...
path: src/example.ts
kind: function
symbol: handleRequest
source_range:
  start_line: 10
  end_line: 42
source_revision: <git-sha-or-content-digest>
extraction_method: tree-sitter-typescript
relation: implements
confidence: high
```

- Anchor ID 的确定性生成方式在 P6 `impl.md` 中定义，不能依赖随机数或对话顺序。
- 行号和代码片段只用于导航，不是持久身份；revision/digest 和符号身份用于检测漂移。
- LLM 只能解释、归类或连接已提取事实。无法锚定的内容必须标为 `hypothesis` 或 `unknown`。
- 低置信度关系可以作为调查线索，但不能成为硬性 Plan 范围或 Verification 结论的唯一依据。

### Freshness 契约

Behavior Map 条目使用四态新鲜度：

| 状态 | 含义 | 消费规则 |
|---|---|---|
| `current` | 锚点与相关依赖仍匹配记录的 revision/digest | 可用于定位，但仍按需核验关键源码 |
| `stale` | 锚点或已知相关依赖发生变化 | 不得直接作为当前事实；重新生成或源码检查 |
| `unknown` | 无法计算影响或来源不可访问 | 回退源码检查，并记录未知覆盖 |
| `unsupported` | Adapter 不支持所需语言或关系类型 | 禁止推断；明确报告能力缺失 |

首版仅承诺手动重生成和过期标记。代码变化触及 Anchor 或其已知依赖时使相关条目 `stale`；无法确定影响范围时标记 `unknown`，不得乐观保持 `current`。

### Change Localization 输出

定位链路固定为：

```text
AC → Behavior Unit → Candidate File/Symbol → Task → Gate
```

每个定位候选至少包含：

- `role`：`primary`、`supporting`、`test`、`config` 或 `schema`；
- 关联 AC 和 Behavior Unit；
- 文件、符号和 Anchor ID；
- 定位理由和预期行为边界；
- source revision；
- confidence；
- 未决区域和建议源码核验；
- 与 Task/Gate 的可追溯引用。

定位是 Planning 的建议性证据，不是实施许可。它不能修改代码、自动添加 Task、静默扩展 Plan 范围或标记 Task 完成。

### Language Adapter 契约

P6 不使用笼统的“支持语言”布尔值。每个 Adapter 必须按能力矩阵报告：

| 能力 | 示例 |
|---|---|
| Parse | AST/语法结构是否可解析 |
| Symbol Inventory | 函数、类型、路由、Schema 是否可枚举 |
| Reference Relations | import、调用、继承、注册等关系是否可提取 |
| Call Graph | 是否支持静态调用边及其置信度 |
| Data/Schema Lineage | SQL、Schema、序列化关系是否支持 |
| Dynamic Limits | 反射、宏、运行时注入、动态分派等缺口 |

首版目标语言和每项能力必须在 P6 `impl.md` 中按可用 parser 与测试夹具最终确认。当前文档中的 Python、TypeScript、Rust、Go、SQL 仅为候选范围，不代表已安装支持。

### 回退与安全退化

- Map 缺失：Planning 直接检查相关源码并记录 Map unavailable。
- Map stale/unknown：只用于导航，不得作为事实结论；核验源码后记录当前证据。
- Adapter unsupported：报告缺失能力，不让 LLM 模拟静态分析输出。
- Anchor conflict：Context 输出冲突报告，不自动选择更符合预期的一方。
- Localization 低置信度：扩大只读调查范围，而不是扩大实施范围。

### Facts-First 规则

从 Handbook 直接引入的核心规则：

> 自然语言解释行为，但每个声明必须锚定在代码事实上。LLM 写 prose，但 source links、函数引用和代码片段必须来自提取的程序事实。文字解释，事实锚定。

### 与 Themis 模块的整合

```
Context 模块:
  ├── Discovery → 行为地图生成管线（新增）
  ├── Resolution → Behavior Map B1/B2/B3 解析（新增）
  ├── Conflict → 行为漂移检测（版本间的行为变化，新增）
  └── Freshness → 行为地图过期标记（代码变更后触发重生成）

Planning 模块:
  └── Traceability → AC → Behavior Unit → Code Location 的精确映射（增强）

Verification 模块:
  └── Check Discovery → 使用行为地图锚点寻找相关 Gate、测试和源码，但不把 Map 当作 Evidence（增强）
```

## 范围

- 定义行为地图 B1/B2/B3 模型及其在 workspace/context/ 中的存储结构
- 设计变更定位的 planner 模式（只读、按需读源码、输出 Task → Code 映射）
- 适配 Facts-First 规则到 Themis 的 Context Protocol
- 定义静态分析 Adapter 的规范化接口和逐能力矩阵；首版语言范围由获批 `impl.md` 根据可用 parser 与测试夹具确定
- 与 Planning 的 Traceability 子模块集成

## 非范围

- 不实现 Handbook Studio 的交互式 UI
- 不实现 Handbook Resync 机制的全自动或保证实时增量版本；首版仅为手动触发重生成 + 新鲜度标记
- 不实现 actor-critic skeleton 收敛循环的完整版本（首版采用受证据约束的行为归类）
- 不改变 Planning 的核心 Task 模型结构，也不自动创建、修改或完成 Task
- 不支持无源码的二进制依赖行为映射
- 不保证解析运行时动态分派、反射、宏展开、代码生成或依赖注入形成的全部关系
- 不把 Behavior Map 或 Anchor 当作 Gate 执行结果、Verification evidence 或 verdict
- 不允许 LLM 在 Adapter 不支持时模拟确定性代码事实

## 规划资产

以下是 P6 获批实施时应落地的能力层，不代表当前已经存在：

| 层 | 源模板资产 | 安装后职责 |
|---|---|---|
| Protocol | `templates/.themis/core/protocols/context/behavior-map/v1/schema.yaml` | 定义 B1/B2/B3、Anchor、Generation Metadata 和 Localization 的稳定结构 |
| Policy | `templates/.themis/core/policies/behavior-map.yaml` | 声明生成步骤、include/exclude、代码事实 Freshness、置信度和回退规则；不重复 P5.4 `context.yaml` |
| Prompt | `templates/.themis/core/templates/behavior-map-generation.md` | 基于确定性事实执行行为归类、三层说明和假设标记 |
| Prompt | `templates/.themis/core/templates/change-localization.md` | 将 AC 映射到 Behavior Unit、候选代码位置、Task 和 Gate |
| Adapter | `templates/.themis/core/adapters/schema/behavior-extractor/` | 声明能力矩阵并规范化语言事实提取结果 |
| Executor | `templates/.themis/core/bin/themis-behavior-map-lint.sh` | 校验 Schema、锚点、引用、revision 和 Facts-First 覆盖 |
| Executor | `templates/.themis/core/bin/themis-behavior-map-freshness.sh` | 根据锚点和依赖摘要确定性标记新鲜度 |
| Rules | `templates/.themis/core/kernel/context/rules.md` | 按需 MUST Read 生成资产并保持 Context 边界 |
| Rules | `templates/.themis/core/kernel/planning/rules.md` | 按需 MUST Read 定位资产并保持只读 Planning 边界 |
| Design | `docs/design/core/{adapters,protocols}.md`、`docs/design/core/kernel/{context,planning}.md`、`docs/design/workflow.md` | 在实现后同步正式合同和能力状态 |
| Workspace output | `workspace/context/architecture/behavior-map/` | 保存项目特定生成实例、锚点、图和元数据 |

Schema 和控制逻辑必须位于 Core；Workspace 只保存项目实例。不得把 Schema 文件预装进 `workspace/context/` 作为控制源，因为 Core Upgrade 不会更新 Workspace。

## 执行前置步骤

当用户主动发起本计划时，**第一步**必须在本计划目录创建或更新 `impl.md`（`docs/plan/60-behavior-map/impl.md`），至少记录：

1. 行为地图 B1/B2/B3、Anchor、Generation Metadata 和 Localization 的精确 Core Protocol Schema
2. 静态分析 Adapter 的逐语言能力矩阵、parser 选择、规范化 JSON 接口和 unsupported 行为
3. 变更定位 Prompt 的输入/输出协议，以及 AC → Behavior Unit → Candidate Location → Task → Gate 链路
4. Facts-First 的确定性 lint 规则：每条事实声明如何关联 Anchor、revision 和摘要
5. Freshness 算法、依赖影响边界、`current/stale/unknown/unsupported` 判定和手动重生成流程
6. YAML Policy、两个 Prompt、可用脚本表及脚本缺失时的 fallback
7. 确定性执行器：Map lint、Freshness、必要时的 Adapter 调度和机器可读 JSON 结果
8. 与 Planning Traceability 和 Verification 检查发现的精确集成点
9. 模板契约、隔离测试、模块测试、Init/Upgrade/Migration 回归和性能基准方法

`impl.md` 经用户确认前，不得修改目标文件。

## 验收条件

- Core Protocol 明确定义 B1/B2/B3、Anchor、Generation Metadata、Freshness 和 Localization 字段
- 每个已声明语言 Adapter 都有逐能力夹具；不支持能力稳定输出 `unsupported`，不由 LLM 补造
- 每条事实性 Map 声明均关联合法 Anchor，Anchor revision/digest 可用于检测漂移
- Planner 在固定人工标注基准上报告 precision/recall 和未决覆盖；不得只用单一“命中率 > 80%”掩盖误报或漏报
- 10 万行代码性能目标使用固定硬件、语言组合、冷/热缓存和重复次数记录，不把孤立一次运行当作保证
- 代码变更后，受影响条目被确定性标记为 `stale`；无法证明影响范围时标记为 `unknown`
- Map 缺失、过期或不支持时，Planning 回退源码检查并保留可追溯证据
- Behavior Map 不修改源码、不扩展 Plan、不生成 Gate verdict，也不写入 Knowledge 治理路径

## 风险与回滚

- **风险**：静态分析对动态语言和运行时装配的关系覆盖不足
- **缓解**：按能力矩阵声明 parse/symbol/reference/call-graph/lineage 支持；无法确定的边标记 `unknown` 或低置信度，并要求源码核验，禁止 LLM 把推测提升为确定性边
- **风险**：行为归类依赖 LLM 质量，不同模型产生不同分类
- **缓解**：归类输出必须保留模型、版本、Prompt 版本和 Anchor；结构由 lint 校验，语义归类视为可审阅解释而非源码事实
- **回滚**：Behavior Map 是 Context 的派生数据，可整体删除而不影响 Spec、Plan 或 Evidence 的权威内容；删除后 Planning 回退到直接源码检查
