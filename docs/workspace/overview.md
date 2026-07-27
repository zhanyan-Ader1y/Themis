# Workspace — 项目空间

## 职责边界

Workspace 完全属于当前项目，保存项目特有内容。它由项目持有，运行过程中可读写。

**Workspace 保存内容，不实现控制逻辑。控制逻辑在 Core 中。**

## 设计原则

1. **项目所有权**：Workspace 属于当前项目，开发者、Agent 和 Themis 运行过程均可写入
2. **内容与逻辑分离**：Workspace 只保存数据，不包含执行逻辑
3. **Core 只读**：Core 通过 Protocols 读取 Workspace 内容，通过 Policies 治理 Workspace 内容
4. **版本化**：Workspace 有独立的 Schema 版本，与 Core 版本解耦

---

## manifest.yaml — 项目契约

项目和 Themis Core 之间的契约入口。Core 读取 Manifest，但不拥有它。

### 职责

声明项目的配置、能力和约束。

### 结构

```yaml
# 版本标识
workspace_schema: themis-workspace/v1
artifact_schema: themis-artifact/v1

# 项目信息
project:
  name: "my-project"
  root: "."

# 构建和测试命令
commands:
  lint: "eslint src/"
  build: "npm run build"
  test: "npm test"

# 上下文入口
context:
  entry_points:
    - workspace/context/architecture/
    - workspace/context/domain/
  external_sources: []

# 启用的 Gate
gates:
  - lint
  - build
  - test
  - review

# Adapter 配置
adapters:
  git:
    ignore_patterns: [".themis/", "*.log"]
  command:
    shell: "bash"
    default_timeout: 300
  testing:
    framework: "jest"
    test_command: "npm test -- --json"

# 项目策略覆盖
policy_overrides:
  verification:
    test:
      coverage_threshold: 90%  # 收紧 Core 默认的 80%

# 工件和证据位置
paths:
  specs: workspace/specs/
  state: workspace/state/
  runs: workspace/runs/
  evidence: workspace/evidence/
  outcomes: workspace/outcomes/
  knowledge: workspace/knowledge/
  cache: workspace/cache/
```

---

## 规范层级与路径规则

已安装项目使用以下 Workspace 层级；仓库中的 `templates/.themis/workspace/` 只是该层级的源模板：

```text
workspace/
├── manifest.yaml
├── policies/
├── context/
│   ├── catalog.yaml
│   ├── .abstract.md
│   ├── .overview.md
│   ├── architecture/
│   │   └── behavior-map/
│   ├── domain/
│   ├── engineering/
│   ├── decisions/
│   ├── pitfalls/
│   ├── glossary/
│   └── external/
├── specs/
├── state/
│   └── context-signals/
├── runs/
├── evidence/
├── outcomes/
├── knowledge/
│   └── actions/
└── cache/
    ├── context-index/
    └── resolved-context/
```

- 项目事实只由受治理 Context 或绑定当前 revision 的代码、配置与 Schema 支撑；Spec、Plan、State、Evidence 和对话各自保留流程职责，不能替代项目事实来源。
- 不存在 `workspace/domain/`。领域规则、业务不变量和领域模型属于正式 Context，固定存储在 `workspace/context/domain/`。
- `workspace/context/catalog.yaml` 是唯一持久 Context Item 注册表；L1/L2、缓存索引和 Bundle 均为可重建派生数据。
- `workspace/context/architecture/behavior-map/` 是 P6 规划中的代码派生 Context 位置；目录存在不代表生成器、Adapter 或新鲜度执行器已实现。
- `specs/` 保存人工/Agent 编写的生命周期工件，`state/` 保存机器可读状态和持久 Context Signal；二者不得相互替代。
- `runs/`、`evidence/`、`outcomes/` 分别表示执行记录、证明材料和真实交付结果，不能合并为一个结论文件。
- `cache/` 可删除和重建，不得成为正式事实、批准或生命周期状态的唯一来源。

---

## policies/ — 项目策略

项目级策略覆盖。与 Core 默认策略合并生成有效策略。

### 合并规则

- 项目可以增加 Gate
- 项目可以收紧要求（提高阈值、缩短超时）
- 项目可以替换标记为 `overridable` 的默认项
- 项目不能修改 Core 内置协议语义
- 项目不能把 `fail` 重新定义为 `pass`

### 文件

| 文件 | 说明 |
|---|---|
| `workflow.yaml` | 自定义工作流阶段和规则 |
| `verification.yaml` | 项目 Gate 配置和阈值 |
| `review.yaml` | 评审通过标准 |
| `knowledge.yaml` | 知识治理项目规则 |

---

## context/ — 项目上下文

项目长期事实和知识。知识分类与读取深度使用两个正交维度：

```text
分类：domain / glossary / decisions / architecture / engineering / pitfalls / external
深度：L1 Abstract → L2 Overview → L3 Detail
```

- L1 `.abstract.md` 用于快速过滤，必须引用派生来源；
- L2 `.overview.md` 用于领域导航，每项事实性说明必须引用 L3 Context ID 或 current B3 Anchor；
- L3 Context Item 保存正式知识内容、authority、Scope、provenance、digest、freshness、依赖和 supersession。

### 子目录

| 目录 | 内容 |
|---|---|
| `architecture/` | 系统结构、组件边界、交互路径和可重新生成的 Behavior Map |
| `domain/` | 业务概念、规则、不变量、状态机、流程和领域模型；不是独立的 `workspace/domain/` |
| `engineering/` | 项目级开发、测试、构建、运行和维护约定 |
| `decisions/` | 已选择的架构或工程决策、上下文、替代方案和理由 |
| `pitfalls/` | 经证据验证的历史陷阱、已知问题和反模式 |
| `glossary/` | 项目术语、缩写和精确定义 |
| `external/` | 受治理的外部协议、文档和来源引用 |

### Behavior Map（P6 规划契约）

`architecture/behavior-map/` 保存从源码与配置确定性事实中派生的代码行为地图，而不是人工编写的第二份代码说明：

- **B1 System**：系统边界、模块关系、入口和生命周期路径；
- **B2 Behavior Unit**：行为域、职责、输入输出、状态与跨模块关系；
- **B3 Evidence**：绑定 revision 的文件、符号、分支、副作用、执行路径和代码证据锚点；
- **索引与元数据**：符号/函数清单、受支持关系、锚点索引、源码 revision、Adapter 版本、语言能力覆盖、置信度和新鲜度。

B1/B2 是 `derived_navigation`；只有 `current` 且受支持的 B3 事实可直接支撑当前实现声明。非 `current` 覆盖必须回退源码检查。

P6 尚未实施。当前目录只是 Template Contract 的预留位置，不得声称已有静态分析、自动生成、变更定位或新鲜度维护能力。

### Catalog

`catalog.yaml` 是所有 L3 Context Item 的唯一持久注册表：

```yaml
context_catalog_schema: themis-context-catalog/v1
items:
  CTX-order-state-machine:
    path: domain/orders/state-machines/order.md
    layer: L3
    category: domain
    knowledge_kind: state_machine
    authority: declared
    status: active
    scope:
      domains: [orders]
      entities: [order]
      operations: [transition]
      states: []
    tags: [order, lifecycle]
    content_digest: ""
    source_revision: null
    verified_at: null
    depends_on: []
    supersedes: null
```

目录摘要、Behavior Map Anchor Index、TSV 索引和 Context Bundle 都不能替代 Catalog。Core 只能通过 Context Protocol 读取和治理这些内容，不能在内部复制一份项目 Context。

---

## specs/ — SDD 工件

保存每个 SDD 工作单元的主要工程工件。

### 结构

```
workspace/specs/
└── <spec-id>/
    ├── spec.md        # Spec 规范
    ├── plan.md        # 实施计划
    ├── review.md      # 评审结果
    ├── verify.md      # 验证结果
    └── artifacts/     # 相关附件（图表、截图等）
```

### 生命周期

```
Draft → Specified → Planned → Implemented → Verified → Reviewed → Archived
```

每个阶段的工件状态由 Orchestrator 驱动，工件内容由开发者或 Agent 维护。

---

## state/ — 运行状态

机器可读运行状态，是索引和审计信息，不能脱离 Spec、Plan 和证据单独解释流程状态。

### 子目录

| 目录 | 内容 |
|---|---|
| `active/` | 当前活动的 Spec 引用 |
| `transitions/` | 状态迁移历史记录 |
| `tasks/` | 当前任务状态 |
| `retries/` | 重试记录 |
| `locks/` | 并发锁（防止同时修改同一 Spec） |
| `sessions/` | 执行会话记录 |
| `context-signals/` | Context missing、stale、conflict 与 Context/代码 drift 信号；只记录问题，不自动裁决 |

---

## runs/ — 执行记录

描述一次执行的整体结构。

### 结构

```
workspace/runs/
└── <run-id>/
    ├── run.json        # 执行元数据
    ├── inputs.json     # 输入参数
    ├── gates.json      # Gate 执行结果
    ├── verdict.json    # 最终判定
    └── summary.md      # 人类可读摘要
```

### run.json 结构

```json
{
  "run_id": "RUN-001",
  "spec_id": "SPEC-001",
  "git_sha": "abc123",
  "executor": "agent-01",
  "started_at": "2026-07-23T10:00:00Z",
  "finished_at": "2026-07-23T10:05:00Z",
  "gates_executed": ["lint", "build", "test", "review"],
  "verdict": "pass",
  "effective_policy": { }
}
```

**Run = 执行记录，Evidence = 支撑 Run 结论的证据。两者不同。**

---

## evidence/ — 验证证据

保存或引用具体证明材料。

### 子目录

| 目录 | 内容 |
|---|---|
| `commands/` | 命令执行输出 |
| `build/` | 构建日志 |
| `lint/` | Lint 报告 |
| `tests/` | 测试报告 |
| `review/` | 评审意见 |
| `drift/` | 架构漂移报告 |
| `deployment/` | 部署证据 |

证据通过 Evidence Protocol 定义格式，由 Verification 模块采集和保存。

---

## outcomes/ — 交付结果

保存验证完成后的真实结果，用于区分"当时验证通过"和"实际交付结果成功"。

### 子目录

| 目录 | 内容 |
|---|---|
| `success/` | 成功交付的 Spec |
| `rework/` | 需要返工的 Spec |
| `defects/` | 逃逸缺陷记录 |
| `incidents/` | 事故记录 |
| `rollbacks/` | 回滚记录 |

由 Attribution 模块分析，为长期质量改进提供数据。

---

## knowledge/ — 知识治理

知识治理过程数据。正式项目知识仍位于 `workspace/context/`。

### 子目录

| 目录 | 内容 |
|---|---|
| `candidates/` | 待审核的知识候选 |
| `reviews/` | 审核记录 |
| `actions/` | 经批准的 promote、merge、revise、reject 或 archive 处置记录 |
| `rejected/` | 被拒绝的候选 |
| `archive/` | 已废弃的知识 |

### 知识流转

```
workspace/knowledge/candidates/
        ↓ 审核、去重、冲突检查
workspace/context/architecture/
workspace/context/domain/
workspace/context/pitfalls/
workspace/context/decisions/
```

这样可以避免同时出现两套正式知识目录。

---

## cache/ — 缓存

项目执行派生数据。

### 子目录

| 目录 | 内容 |
|---|---|
| `context-index/` | 由 Catalog 重建的 items/tags/scopes/paths/references 文本索引 |
| `resolved-context/` | 按 Spec/Task 装配的 Context Bundle 与 manifest |
| `metadata/` | 文件元数据缓存 |

**Cache 只加速检索与装配，不保存唯一事实、批准、冲突处置或生命周期状态。缓存位于 Workspace 而非 Core，因为同一套 Core 在不同分支或不同项目内容下运行时可能产生上下文污染。**