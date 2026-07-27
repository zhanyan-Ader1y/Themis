# Workspace — 项目空间

> 规范状态：正式设计。实现状态：目录骨架与 manifest 已实现；多数生命周期状态、Run、Evidence、Outcome 和知识治理执行器尚未实现。

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

Adapter、Gate 与 policy override 的具体字段在对应 Protocol 和执行器落地后扩展。Jest、pytest、CI provider 等配置只能作为明确标注的示例，不能写成当前默认合同。

## 目录所有权

| 路径 | 内容 | 当前状态 |
|---|---|---|
| `policies/` | 项目允许的 policy override | 目录骨架 |
| `context/` | 正式项目事实、ADR、领域与工程知识 | 目录骨架 |
| `specs/` | Spec、Plan、Review、Verify 等 SDD 工件 | 目录骨架；Draft Spec 模板已实现 |
| `state/` | 迁移、Task、retry、lock、session 等机器状态 | 目录骨架 |
| `runs/` | 一次执行的输入、Gate、verdict 与摘要 | 目录骨架 |
| `evidence/` | 命令、构建、测试、Review、漂移与部署证据 | 目录骨架 |
| `outcomes/` | success、rework、defect、incident、rollback | 目录骨架 |
| `knowledge/` | candidate、review、rejected、archive | 目录骨架 |
| `cache/` | 可重建的 Context 索引与派生快照 | 目录骨架 |

目录存在不代表对应执行能力已经实现。

## context/ — 正式知识

Context 保存经确认的项目事实，并按 architecture、domain、engineering、decisions、pitfalls、glossary 和 external 等类别组织。AI 可以提出候选，但未经治理审批不得把观察结论直接写入正式 Context。

Behavior Map 是 `context/architecture/behavior-map/` 下的派生事实；当前仅有目录占位。未来生成内容必须具有代码证据锚点，并支持新鲜度标记。

## specs/ — SDD 工件

目标结构：

```text
workspace/specs/<spec-id>/
├── spec.md
├── plan.md
├── review.md
├── verify.md
└── artifacts/
```

当前已实现的是 `themis-spec/v1` Draft Spec 模板与 P5 批准证据合同。Plan、Review 和 Verify 模板及执行器尚未落地。

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

Outcome 记录交付后的真实结果，用于区分“某次 Verification 通过”和“实际交付成功”。Attribution 只建立可追溯关联并区分相关性与因果解释。

Knowledge 流程为：

```text
candidate → dedup/conflict check → review
  ├─ promote → workspace/context/
  ├─ reject  → workspace/knowledge/rejected/
  └─ revise  → candidate
```

废弃的正式 Context 经审核后进入 `workspace/knowledge/archive/`。该自动治理执行器尚未实现。

## cache/

Cache 只保存可重建的项目派生数据，不能成为正式事实源。Cache 属于 Workspace，因为同一 Core 在不同项目或分支内容上可能产生不同结果。
