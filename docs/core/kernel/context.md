# Context — 上下文

## 职责边界

Context 管理受治理项目知识与当前代码事实的发现、解析、冲突信号和新鲜度。它回答“哪些项目事实可被引用，以及它们来自哪里”，但不拥有项目内容——正式知识始终在 Workspace，当前实现事实始终在代码、配置与 Schema 中。

**Context 是事实解析与治理边界，不是第二个存储层，也不为项目提供 Core 默认事实。**

## 核心能力

| 能力 | 说明 |
|---|---|
| Context 发现 | 从 Catalog、L1/L2/L3 与当前代码中确定可追溯候选 |
| Context 解析 | 按 Scope 和引用渐进加载，生成可重建 Context Bundle |
| 冲突信号 | 检测 Context 内冲突及 Context/代码漂移并持久化 Signal |
| 新鲜度维护 | 以 digest/revision 标记 current、stale、unknown 或 unsupported |

## 子模块

### Discovery — Context 发现

从两个可信根发现项目事实：

- 从 `workspace/context/catalog.yaml` 查询受治理 L3 Context Item，并以目录级 L1/L2 导航逐步缩小范围；
- 从当前 revision 的代码、配置、Schema 和其他版本化实现工件核验当前实现事实；
- 外部文档只有作为受治理的 `external_reference` Context Item 后才可支撑项目事实；
- 未验证观察以候选形式提交给 Knowledge Governance，不直接写入正式 Context。

**边界**：Discovery 只产生带来源候选，不审核知识、不把搜索结果或 Agent 推断标记为事实。

### Resolution — Context 解析

解析 Context Item 引用、Scope 与当前代码事实：

- 从 Spec 显式 Context ID 或 domain/entity/operation/state 查询 Catalog；
- 按 `L1 Abstract → L2 Overview → L3 Detail` 渐进加载必要内容；
- L1/L2 只作为带引用导航，不能覆盖或新增 L3 事实；
- 按声明类型读取当前代码、配置或 Schema，并检测 Context/代码漂移；
- 将选择项、digest、revision、排除理由和未决 Signal 写入 `workspace/cache/resolved-context/` 的 Context Bundle。

**边界**：Resolution 不修改正式 Context。Bundle 是可重建快照，不是第三个事实源。

### Conflict — 冲突检测

检测可信项目事实之间的不一致：

- Context Item 对同一 Scope 给出矛盾定义；
- Context 规则与当前代码、配置或 Schema 不一致；
- Context 引用已失效、被 supersede 或 digest 不匹配；
- 将 `context_conflict`、`context_code_drift`、`missing` 或 `stale` 写入 `workspace/state/context-signals/`。

**边界**：Signal 只记录问题，不建立项目事实或自动裁决。依赖冲突事实的阶段必须停留并交由当前 SDD 阶段或 Knowledge Governance 处置。

### Behavior Map — 行为地图（P6 规划中）

Behavior Map 是 `architecture/behavior-map/` 下可重新生成的代码派生 Context，使用 B1 System、B2 Behavior Unit 和 B3 Evidence 组织导航与 revision-bound Anchor，并为 Planning 提供变更定位依据。

核心能力契约：

- 读取受 manifest 限定的源码、配置、Schema、路由、构建元数据和真实 Adapter 输出；
- 保存符号/函数清单、规范化关系图、三层 Map、Anchor Index 和 Generation Metadata；
- 要求每条事实声明引用包含路径、符号、源码范围、revision/digest、提取方法和置信度的稳定 Anchor；
- 使用 `current`、`stale`、`unknown`、`unsupported` 表达新鲜度和能力覆盖；
- 向 Planning 提供只读的 `AC → Behavior Unit → Candidate Location` 定位输入；
- Map 缺失、过期或不支持时回退到直接源码检查。

**边界**：Context 管理 Map 的生成治理、存储、冲突和新鲜度，但不把 Anchor 当作 Gate 结果，不修改 Plan 或代码，也不让 LLM 在 Adapter 不支持时模拟确定性事实。P6 尚未实施，当前只有存储目录占位和设计契约。

### Freshness — 新鲜度

维护上下文的新鲜度：

- 标记每个上下文项的来源和最后更新时间
- 检测可能过期的上下文（依赖的代码已变更、外部文档已更新）
- 生成过期上下文列表供开发者审核
- 与 Knowledge 模块协作，将过期上下文标记为废弃候选

**边界**：Freshness 只标记过期，不自动更新上下文（更新需要人工确认）。

## 与 Workspace 的交互

```
Context 读取:
  workspace/context/catalog.yaml       # 唯一持久 Context 注册表
  workspace/context/                   # L1/L2/L3 项目知识
  workspace/manifest.yaml              # Context 入口与项目范围
  当前代码、配置与 Schema              # 当前实现事实
  workspace/cache/context-index/       # 可重建检索索引

Context 写入:
  workspace/cache/resolved-context/    # 可重建 Context Bundle
  workspace/cache/context-index/       # 可重建检索索引
  workspace/state/context-signals/     # 持久 missing/conflict/stale/drift Signal
  workspace/knowledge/candidates/      # 未验证观察候选
```

## 输入/输出协议

- **输入**：Context Item、Catalog、当前代码事实与查询 Scope
- **输出**：Context Bundle 对外暴露选中来源，结构化 Signal 持久化到 `workspace/state/context-signals/`