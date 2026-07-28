# Workspace — 项目空间

> 规范状态：正式设计。实现状态：当前 `themis-workspace` 目录骨架、manifest、无版本 Spec 双视图与 P5.4 Context Catalog/Signal/Bundle/Navigation 基础设施已实现；通用 lifecycle state、Review、Verification、Acceptance、Summary、Outcome 和知识治理执行器尚未实现。

## 职责边界

Workspace 完全属于当前项目，保存项目特有内容和运行数据；Core 读取并治理这些内容，但不得在内部复制项目事实。

- Workspace 保存内容，不实现控制逻辑。
- 当前版本只支持 fresh Init，不更新或转换既有 `.themis`；Init 只在目标 `Themis-Q` 路径不存在时安全合并 `.claude/skills/Themis-Q/`。
- Workspace/Artifact Schema 必须位于 `core.yaml` 的 fixed supported allow-list；不支持的值 fail closed。
- 任何运行时都不得隐式改写 Schema、创建不兼容结构或以复制模板替代更新机制。
- 正式项目知识只存在于 `workspace/context/`；`workspace/knowledge/` 是治理过程数据。

## manifest.yaml

当前模板结构：

```yaml
workspace_schema: themis-workspace
artifact_schema: themis-artifact
project:
  name: ""
  root: "."
commands:
  lint: null
  build: null
  test: null
context:
  entry_points: []
  external_sources: []
gates: []
adapters: {}
policy_overrides: {}
paths:
  policies: workspace/policies
  context: workspace/context
  specs: workspace/specs
  state: workspace/state
  runs: workspace/runs
  evidence: workspace/evidence
  outcomes: workspace/outcomes
  knowledge: workspace/knowledge
  cache: workspace/cache
```

`null` command 表示 Gate 不可用。Agent 不得发明替代命令；Verification 应按 policy 返回 unavailable、`inconclusive` 或失败。

## 目录所有权

| 路径 | 内容 | 当前状态 |
|---|---|---|
| `policies/` | 项目允许的 policy override | 目录骨架 |
| `context/` | 正式项目知识 | 空 bootstrap Catalog、L1/L2 Navigation 与七类目录已实现；L3 内容由人工维护或未来 P5.5 Knowledge Governance 提供 |
| `specs/` | Spec、Plan、Review、Verify、Summary 等 SDD 工件 | 无版本 Spec 双视图已实现；其余未实现 |
| `state/` | transition、Task、retry、lock、session、Context Signal 等机器状态 | Context Signal、lock 与 transaction 基础设施已实现；通用 lifecycle state 未实现 |
| `runs/` | 一次执行的输入、Gate、verdict 与摘要 | 目录骨架 |
| `evidence/` | 命令、构建、测试、Review、Acceptance、漂移与部署证据 | 目录骨架 |
| `outcomes/` | success、rework、defect、incident、rollback | 目录骨架 |
| `knowledge/` | candidate、review、canonical action、rejected projection、archive snapshot | 目录骨架 |
| `cache/` | 可重建的 Context 索引、Bundle 与派生元数据 | Context index 与 resolved Bundle Cache 已实现 |

目录存在不代表对应执行能力已经实现。

## P5.4 Context 结构

P5.4 在当前 `themis-workspace` 可表达的目录内实现：

```text
workspace/
├── context/
│   ├── catalog.yaml
│   ├── .abstract.md
│   ├── .overview.md
│   ├── architecture/
│   ├── domain/
│   ├── engineering/
│   ├── decisions/
│   ├── pitfalls/
│   ├── glossary/
│   └── external/
├── state/
│   └── context-signals/
├── knowledge/
│   ├── candidates/
│   ├── reviews/
│   ├── actions/
│   ├── rejected/
│   └── archive/
└── cache/
    ├── context-index/
    └── resolved-context/
```

- `catalog.yaml` 是唯一持久 Context 注册表。
- L1/L2 是派生导航，L3 是正式 Context Item；Catalog Search 直接覆盖完整 L3 集合。
- `context-signals/` 保存 missing、stale、conflict 和 drift 等流程信号，不保存项目事实。
- Candidate 保持追加式；所有 canonical action 写入 `knowledge/actions/`。
- Cache 可以删除重建，不能保存唯一批准、裁决、来源或项目知识。
- 若实施需要改变 Workspace Schema 或转换既有安装，该部分必须延期；当前版本没有转换能力。

## specs/ — SDD 工件

目标结构：

```text
workspace/specs/<spec-id>/
├── spec.yaml       # 当前唯一、无独立版本号的机器语义源
├── spec.md         # 确定性 Human projection
├── plan.md
├── review.md       # 前置 Review projection
├── verify.md       # 后置 Verification projection
└── summary.md      # Human Acceptance 后的最终交付投影
```

当前只实现 `spec.yaml`/`spec.md` pair。Requirement Questioning 发生在 Workspace 写入之前；Themis-Q 只提供提问方法，Specification 在需求收敛并获用户确认后才创建唯一 `workspace/cache/spec-candidates/<spec-id>.yaml` candidate，`themis-spec.sh publish` 负责验证、渲染、配对校验与可恢复发布。Plan、Review、Verify、Summary 的模板和执行器尚未落地。

生命周期状态统一为：

```text
draft → specified → planned → reviewed → implemented → verified → archived
```

完整阶段顺序还包含 `verified` 后的 Human Acceptance 与 Summary 门禁。工件内容由对应领域或用户维护；只有确定性状态执行器可以写入机器 transition。

## state/、runs/ 与 evidence/

- `state/` 是机器可读索引和审计状态，不能脱离 Spec、Plan 与 Evidence 单独解释流程。
- `runs/` 描述一次执行；`evidence/` 保存或引用支撑结论的材料，两者不得混为一谈。
- Review result、Gate execution status、Verification verdict、Human Acceptance decision 和 lifecycle status 使用不同命名空间。
- Review approval 绑定 Spec/Plan revision；相关工件变化后失效。
- 代码变化使受影响的 Verification evidence 失效。
- Acceptance evidence 绑定 accepted Spec/Plan/Review/Verification revision；实现变化后必须重新 Verification 与 Acceptance。

当前通用 Run、Evidence、Acceptance 和 lifecycle state 执行器尚未实现。

## Summary、Outcome 与 Knowledge

`summary.md` 只在 Human Acceptance 为 `accepted` 后生成，引用接受证据和来源 digest，汇总最终范围、实际变更、证据、偏差、残余风险和后续事项。它不是机器 acceptance、Verification verdict、Outcome 或 lifecycle state。

Outcome 记录交付后的真实结果。Knowledge 流程为：

```text
candidate → fact validation → dedup/conflict check → governed review → human decision
  ├─ promote         → workspace/context/ + catalog.yaml
  ├─ reject/revise   → canonical action + retained candidate
  ├─ merge_duplicate → canonical action + canonical reference
  └─ retain/archive  → canonical action + optional historical projection/snapshot
```

Candidate 不因处置被移动或删除。自动治理执行器尚未实现。

## cache/

Cache 只保存可重建的项目派生数据，不能成为正式事实源。Cache 属于 Workspace，因为同一 Core 在不同项目或分支内容上可能产生不同结果。
