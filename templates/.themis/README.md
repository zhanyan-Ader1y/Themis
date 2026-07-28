# Themis 安装包合同

本目录定义未来 fresh Init 安装到项目 `.themis/` 的 Core 与 Workspace 基线。当前源仓库只包含声明式资产和目录模板，没有可执行安装器或确定性运行时。

## 产品主链

安装包必须共同强化：Spec 前追问、轻松 Spec Review、可沉淀的 Agent Plan、不断进化的项目知识库。固定生命周期为：

```text
Draft → Specified → Planned → Reviewed → Implemented → Verified
      → Human Acceptance → Summary → Archived
```

Review 在 Implementation 前；Verification 在 Implementation 后；Summary 只在 current Verification `pass` 且 Human Acceptance `accepted` 后生成。

## 包结构

| Package | 合同 |
|---|---|
| [`core/kernel/orchestrator`](core/kernel/orchestrator/README.md) | 持久工件驱动的领域路由 |
| [`core/kernel/specification`](core/kernel/specification/README.md) | 追问、Spec 语义源、Human projection 与批准 |
| [`core/kernel/context`](core/kernel/context/README.md) | 受治理项目事实、Catalog、Bundle、freshness 与 Signal |
| [`core/kernel/planning`](core/kernel/planning/README.md) | durable Plan、Task DAG、scope 与 cursor |
| [`core/kernel/review`](core/kernel/review/README.md) | Implementation 前只读批准 |
| [`core/kernel/implementation`](core/kernel/implementation/README.md) | bounded Task execution 与 ledger |
| [`core/kernel/verification`](core/kernel/verification/README.md) | 实际 Gate、evidence 与 verdict |
| [`core/kernel/delivery`](core/kernel/delivery/README.md) | Human Acceptance 与 final Summary |
| [`core/kernel/knowledge`](core/kernel/knowledge/README.md) | candidate、人工决定与 Context disposition |
| [`core/kernel/attribution`](core/kernel/attribution/README.md) | 可选 post-delivery analytics |
| [`core/policies`](core/policies/README.md) | 稳定策略和枚举 |
| [`core/protocols`](core/protocols/README.md) | 跨模块结构化协议 |
| [`core/templates`](core/templates/README.md) | 新工件与 Human projection 模板 |
| [`core/adapters`](core/adapters/README.md) | 可选外部工具映射边界 |
| [`workspace`](workspace/README.md) | 项目持有的事实与流程工件 |

## 权威和边界

- Core 管理控制合同，不保存项目事实；Workspace 保存项目事实和流程记录，不实现控制逻辑。
- 每个模块只有唯一当前合同，不使用功能性版本目录或 `v1`、`v2`、`v3` 标识。
- Upgrade、Migration 和 Behavior Map 已退役，不得通过 Adapter 或 runtime 隐式恢复。
- Attribution 与 Multi-Agent 都是可选能力，不能成为核心门禁。
- Prompt 负责语义判断和人工交互；未来 runtime 负责 validation、projection、state/evidence、path safety、transaction 与 recovery。

## 当前实现状态

`rules.md`、部分 YAML policy/protocol/template、Workspace scaffold 和 `themis-q` 方法存在。Implementation 与 Delivery 尚无运行资产；生产 installer、Spec/Context executors、state recorder、Gate runner 和回归套件不存在。任何能力声明都必须以当前文件和实际观察为准。
