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

项目长期事实和知识。

### 子目录

| 目录 | 内容 |
|---|---|
| `architecture/` | 架构决策、组件图、技术栈 |
| `domain/` | 领域规则、业务逻辑、术语定义 |
| `engineering/` | 工程规范、代码风格、约定 |
| `decisions/` | ADR（架构决策记录） |
| `pitfalls/` | 历史陷阱、已知问题、反模式 |
| `glossary/` | 项目术语表 |
| `external/` | 外部协议和文档引用 |

### 索引

`context-map.yaml` 维护所有上下文项的索引：

```yaml
items:
  - id: CTX-001
    title: "系统架构概览"
    type: architecture
    path: workspace/context/architecture/overview.md
    freshness: 2026-07-20
    source: manual
  - id: CTX-002
    title: "订单状态机"
    type: domain
    path: workspace/context/domain/order-state-machine.md
    freshness: 2026-07-15
    source: spec_execution
```

**Core 只能通过 Context Protocol 读取和治理这些内容，不能在内部复制一份项目 Context。**

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
| `context-index/` | 上下文索引缓存 |
| `resolved-context/` | 解析后的有效上下文快照 |
| `metadata/` | 文件元数据缓存 |

**缓存位于 Workspace 而非 Core，因为同一套 Core 在不同分支或不同项目内容下运行时可能产生上下文污染。**