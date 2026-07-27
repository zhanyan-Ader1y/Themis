# Context — 上下文

> 规范状态：正式设计。实现状态：领域 rules 与 Workspace 目录骨架已落地；P5.4 的机器可读 Protocol、Catalog、L1/L2 投影、检索、Bundle、Signal 与 Freshness 执行器尚未实现。

## 职责边界

Context 管理项目事实的发现、解析、来源、冲突和新鲜度。它不决定需求、Plan、实施方案或知识提升结论，也不维护代码行为地图或第二套源码表示。

项目事实由受治理 Context 与当前代码分别对“应当是什么”和“现在是什么”负责；完整可信模型见 [设计治理](../../governance.md#项目事实可信模型)。正式项目知识只有 `workspace/context/` 一个权威位置，AI 观察必须先进入 Knowledge Governance，未经批准不得直接写入正式 Context。

Core 只提供 Context 的 Protocol、Policy、Prompt 和执行能力，不保存目标项目知识。Context Item、Bundle、Signal 和派生导航必须绑定 target project、Workspace root 与 source revision；不得跨 Workspace 读取或写入项目事实。

## 知识分类与披露层级

```text
知识类别：domain / glossary / decisions / architecture / engineering / pitfalls / external
披露层级：L1 Abstract → L2 Overview → L3 Detail
```

- 类别回答知识属于什么领域；披露层级决定当前任务需要读取多深。
- L1 `.abstract.md` 与 L2 `.overview.md` 是引用 L3 的 `derived_navigation`，不得引入独立事实。
- L3 Context Item 是正式知识单元，具有稳定 Context ID、category、knowledge kind、authority、status、scope、tags、provenance、digest、freshness、dependencies 和 supersession。
- L3 或 Catalog 变化后，只将受影响的 L1/L2 标记为 stale；Catalog Search 必须继续查询完整 L3 集合。
- L1/L2 重建先生成带来源引用的 candidate，经确定性校验后发布；Prompt 不得直接覆盖导航投影。
- `authority` 至少区分 `declared`、`governed`、`external_reference`、`derived_fact` 和 `derived_navigation`。
- Spec 不拥有独立知识目录；它引用长期 Context Item。

## Catalog 与派生数据

- `workspace/context/catalog.yaml` 是 Context Item 身份、路径和完整性元数据的唯一持久注册表。
- `workspace/cache/context-index/` 只保存可重建的文本索引。
- `workspace/cache/resolved-context/` 只保存任务级 Context Bundle。
- 摘要、搜索排序、Bundle 和 Cache 都不能成为第三个事实源。
- Cache 丢失不得造成知识、批准、冲突裁决、来源证据或机器状态丢失。

## Context Resolution

Spec、Plan、Review 或 Task 的解析顺序为：

1. 优先读取显式 Context ID；否则按 domain、entity、operation、state、path 和 terms 查询 Catalog。
2. 读取命中目录的 L1，筛选后读取 L2，再只加载必要 L3。
3. 按需读取 glossary、decisions、external、pitfalls 和 architecture。
4. 对当前实现声明直接读取当前代码、配置或 Schema，并记录 revision/digest。
5. 校验 Context ID、path、status、digest、revision 和引用。
6. 生成 Context Bundle，或在缺失、过期、冲突时记录 Signal 并停止依赖该事实的结论。

Prompt 只能在确定性检索返回的候选集合内做语义选择；返回 ID 后必须由脚本再次校验，不能由模型越界加载或把排名当事实。

## Context Bundle

目标位置：

```text
workspace/cache/resolved-context/<bundle-id>/
├── manifest.yaml
└── context.md
```

Bundle 至少记录 intent、Spec/Task 与 Scope、source revision、token budget、选中 Context ID/path/digest/freshness、读取的代码路径、排除理由、未决 Signal，以及 `complete`、`partial`、`conflict` 或 `unavailable` 状态。

Bundle 是可重建快照。Run/Evidence 可以引用其 manifest、源 ID 和 digest，但 Bundle 本身不建立新的项目事实。

## Conflict 与 Signal

持久 Signal 位于 `workspace/state/context-signals/`，至少覆盖：

- `missing`：所需项目事实没有可信来源；
- `stale`：来源 revision、digest 或依赖已变化；
- `context_conflict`：Context Item 对同一 Scope 给出矛盾结论；
- `context_code_drift`：Context 描述与当前代码、配置或 Schema 不一致。

Signal 只记录问题和处置状态，不自动裁决。Freshness 只标记来源状态，不自动改写或删除正式 Context。

| 情况 | 可得结论 | 后续动作 |
|---|---|---|
| Context 与代码一致或职责互补 | 可分别引用期望与当前实现 | 生成可追溯 Bundle |
| Context 有规则、代码不符合 | `context_code_drift` | 纳入 Spec 或请求人工裁决 |
| Context 无规则、代码有行为 | 只能陈述当前实现 | 标记业务意图待确认，可生成 candidate |
| Context 有规则、代码不可读 | 实现状态 `unknown` | 不得声明已经实现 |
| Context 相互冲突 | `context_conflict` | 停止依赖该事实的阶段并进入治理 |

## Workspace 交互

```text
读取:
  workspace/context/catalog.yaml
  workspace/context/
  workspace/manifest.yaml
  workspace/cache/context-index/
  当前代码、配置与 Schema

写入:
  workspace/cache/context-index/
  workspace/cache/resolved-context/
  workspace/state/context-signals/
  workspace/knowledge/candidates/
```

正式 L3 与 Catalog 的写入只发生在人工维护或经批准的 Knowledge Governance 处置中。P5.4 目标路径与执行器尚未全部存在；其实现必须保持当前 `themis-workspace/v1` 合同，任何需要 schema 转换的结构变化延期到未来重新设计的更新能力。
