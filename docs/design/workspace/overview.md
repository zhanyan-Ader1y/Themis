# Workspace — 项目空间

> 规范状态：正式设计。实现状态：当前目录骨架与 manifest 已实现；P5.4 目标 Context/Catalog/Signal/Bundle 结构、Spec 双视图、通用 lifecycle state、Run、Evidence、Outcome 和知识治理执行器均尚未实现。

## 职责边界

Workspace 完全属于当前项目，保存项目特有内容和运行数据；Core 读取并治理这些内容，但不得在内部复制项目事实。

- Workspace 保存内容，不实现控制逻辑。
- Core Upgrade 不得复制、替换、删除、恢复或修改 Workspace。
- Workspace 与 Artifact Schema 独立于 Core Version；不兼容变更只能通过显式 [Migration](../core/migrations.md) 完成。
- 正式项目知识只存在于 `workspace/context/`；`workspace/knowledge/` 是治理过程数据。

## manifest.yaml

Manifest 是项目与 Core 之间的配置入口，由项目持有。当前模板结构为：

```yaml
workspace_schema: themis-workspace/v1
artifact_schema: themis-artifact/v1
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

`null` command 表示对应 Gate 不可用。Agent 不得发明替代命令；Verification 应按 policy 返回不可用、`inconclusive` 或失败结果。

Adapter、Gate 与 policy override 的具体字段在对应 Protocol 和执行器落地后扩展。工具名称只能作为明确标注的示例，不能写成当前默认合同。

## 目录所有权

| 路径 | 内容 | 当前状态 |
|---|---|---|
| `policies/` | 项目允许的 policy override | 目录骨架 |
| `context/` | 正式项目知识与派生代码 Context | 目录骨架；P5.4 目标结构未迁移 |
| `specs/` | Spec、Plan、Review、Verify 等 SDD 工件 | 目录骨架；`themis-spec/v1` Draft 模板已实现 |
| `state/` | transition、Task、retry、lock、session、Context Signal 等机器状态 | 目录骨架 |
| `runs/` | 一次执行的输入、Gate、verdict 与摘要 | 目录骨架 |
| `evidence/` | 命令、构建、测试、Review、漂移与部署证据 | 目录骨架 |
| `outcomes/` | success、rework、defect、incident、rollback | 目录骨架 |
| `knowledge/` | candidate、review、rejected、archive 等治理记录 | 目录骨架 |
| `cache/` | 可重建的 Context 索引、Bundle 与派生元数据 | 目录骨架 |

目录存在不代表对应执行能力已经实现。

## P5.4 目标 Context 结构

```text
workspace/
├── context/
│   ├── catalog.yaml
│   ├── .abstract.md
│   ├── .overview.md
│   ├── architecture/
│   │   └── behavior-map/
│   │       ├── manifest.yaml
│   │       ├── system/       # B1
│   │       ├── units/        # B2
│   │       ├── evidence/     # B3
│   │       └── navigation/
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

- `catalog.yaml` 是目标唯一持久 Context 注册表。
- L1/L2 是派生导航，L3 是正式 Context Item；详细合同见 [Context](../core/kernel/context.md)。
- `context-signals/` 保存 missing、stale、conflict 和 drift 等流程信号，不保存项目事实。
- Cache 可以删除重建，不能保存唯一批准、裁决、来源或项目知识。
- Behavior Map 是派生 Context，不是第二套源码权威。

该结构会改变已安装 Workspace，只有 P5.4 实施提供 descriptor、备份、验证和回滚后，才能通过显式 Migration 应用；Upgrade 不得补建或重写这些路径。

## specs/ — SDD 工件

当前已实现结构为：

```text
workspace/specs/<spec-id>/
├── spec.md
├── plan.md
├── review.md
├── verify.md
└── artifacts/
```

当前已实现的是 `themis-spec/v1` Draft Spec 模板与 P5 批准证据合同。Plan、Review 和 Verify 模板及执行器尚未落地。

P5.2 提出的 `spec.yaml` Agent 权威源与 `spec.md` Human 投影仍是待确认实施设计，不是当前正式 Artifact 合同；在其获批并同步本目录前，本页继续以 `themis-spec/v1` 为准。

生命周期统一为：

```text
Draft → Specified → Planned → Implemented → Verified → Reviewed → Archived
```

工件内容由对应领域或用户维护；只有确定性状态执行器可以写入机器生命周期迁移。完整门禁见 [工作流程](../workflow.md)。

## state/、runs/ 与 evidence/

- `state/` 是机器可读索引和审计状态，不能脱离 Spec、Plan 与 Evidence 单独解释流程。
- `runs/` 描述一次执行；`evidence/` 保存或引用支撑结论的材料。Run 与 Evidence 不得混为一谈。
- Gate execution status、Verification verdict 和 Review result 使用不同命名空间，见 [Protocols](../core/protocols.md#状态词汇)。
- 代码变更会使受影响的 Verification evidence 失效。

当前通用 Run、Evidence 和 lifecycle state 执行器尚未实现。

## outcomes/ 与 knowledge/

Outcome 记录交付后的真实结果，用于区分某次 Verification 通过和实际交付成功。Attribution 只建立可追溯关联并区分相关性与因果解释。

Knowledge 流程为：

```text
candidate → fact validation → dedup/conflict check → governed review
  ├─ promote → workspace/context/ + catalog.yaml
  ├─ reject  → workspace/knowledge/rejected/
  └─ revise  → candidate
```

废弃的正式 Context 经审核后保留历史记录于 `workspace/knowledge/archive/`。自动治理执行器尚未实现。

## cache/

Cache 只保存可重建的项目派生数据，不能成为正式事实源。Cache 属于 Workspace，因为同一 Core 在不同项目或分支内容上可能产生不同结果。
