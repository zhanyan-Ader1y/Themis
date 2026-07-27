# Protocols — 协议层

## 职责边界

Protocols 定义 Core 与 Workspace、Core 与外部工具之间的数据契约。它解决的是格式和语义稳定性，使 Workspace 可以在 Core 升级后继续被正确解释。

**Protocols 是接口定义，不是实现。它说"数据长什么样"，不说"数据怎么处理"。**

## 设计原则

1. **协议版本化**：每个协议有独立版本号，Core 升级时协议可独立演进
2. **向后兼容**：新版本 Core 必须能读取旧版本协议的数据
3. **向前声明**：旧版本 Core 遇到新版本协议数据时，应给出明确诊断而非静默失败
4. **协议与实现分离**：协议定义在 `core/protocols/`，实现在各 Kernel 模块中

## 子协议

### Artifact Protocol — 工件协议

定义 SDD 工件的结构和语义：

- **Spec Artifact Protocol**：Spec 文档的字段、类型、约束、版本
- **Plan Artifact Protocol**：Plan 文档的字段、Task 结构、依赖关系
- **Review Artifact Protocol**：Review 文档的字段、严重级别、评审状态
- **Verify Artifact Protocol**：Verify 文档的字段、Gate 结果、Verdict

每种工件协议定义：
- 工件的 Schema（必需字段、可选字段、字段类型）
- 工件的版本标识
- 工件之间的引用规则
- 工件的生命周期状态

**边界**：Artifact Protocol 定义工件格式，不定义工件内容的好坏标准。

### Gate Protocol — 门禁协议

定义 Gate 的接口和结果格式：

- Gate 的输入：Spec 引用、Plan 引用、代码变更范围
- Gate 的输出：状态（pass/fail/skip/error）、证据引用、失败原因
- Gate 的元数据：名称、类型（阻塞/警告/信息）、超时时间
- Gate 结果通过 Evidence Protocol 关联到具体证据

**边界**：Gate Protocol 定义 Gate 的接口契约，不定义 Gate 的具体检查逻辑。

### Evidence Protocol — 证据协议

定义证据的格式和存储规则：

- 证据类型：命令输出、测试报告、构建日志、Lint 结果、Review 评论
- 证据格式：文本、JSON、XML、二进制
- 证据元数据：时间戳、来源、关联 Gate、关联 Spec
- 证据存储位置：`workspace/evidence/` 对应子目录
- 证据保留策略：保留时间、压缩规则

**边界**：Evidence Protocol 定义证据格式，不定义证据如何被采集（采集由 Verification 执行）。

### Context Protocol — 上下文协议

Context 使用四个相互引用但职责独立的协议：

- **Context Item**：L3 正式知识，记录稳定 ID、category、knowledge kind、authority、status、Scope、tags、provenance、source revision、content digest、freshness、dependencies 和 supersession；
- **Context Catalog**：`workspace/context/catalog.yaml` 的唯一持久注册表，保存 Item 身份、路径和完整性元数据；
- **Context Bundle**：按 Spec/Task 查询装配的可重建快照，记录选中与排除项、代码路径、revision/digest、token budget、理由、未决 Signal 和完整性状态；
- **Context Signal**：持久记录 `missing`、`stale`、`context_conflict`、`context_code_drift` 等问题及其来源和处置状态。

L1 `.abstract.md` 和 L2 `.overview.md` 是引用 L3/B3 的 `derived_navigation` 投影，不是独立事实协议。Cache 索引和 Bundle 可以删除重建；Signal 存于 State，不得只存在 Cache。

**边界**：Context Protocol 定义数据结构、引用与完整性约束，不决定知识内容是否正确，也不批准 Knowledge Promotion。

### Outcome Protocol — 产出协议

定义产出记录的结构：

- 产出类型：成功、返工、缺陷、事故、回滚
- 产出元数据：关联 Spec、关联 Run、时间戳、严重级别
- 产出关联：与 Spec、Plan、Verification、Deployment 的关联
- 产出存储位置：`workspace/outcomes/` 对应子目录

**边界**：Outcome Protocol 定义产出记录格式，不定义如何分析产出（那是 Attribution 的职责）。

### Adapter Protocol — 适配器协议

定义 Adapter 的接口契约：

- Adapter 的输入：命令、参数、环境变量
- Adapter 的输出：退出码、stdout、stderr、结构化结果
- Adapter 的配置：可配置项、默认值、环境依赖
- Adapter 的错误处理：超时、重试、降级

**边界**：Adapter Protocol 定义 Adapter 的接口，不定义具体 Adapter 的实现。

## 协议版本管理

每个协议在 `core/protocols/<name>/` 目录下维护其版本定义：

```
core/protocols/
├── artifact/
│   ├── v1/
│   │   ├── spec-schema.yaml
│   │   ├── plan-schema.yaml
│   │   └── review-schema.yaml
│   └── v2/
│       └── ...
├── gate/
│   └── v1/
│       └── gate-result-schema.yaml
├── evidence/
│   └── v1/
│       └── evidence-schema.yaml
├── context/
│   └── v1/
│       ├── context-item-schema.yaml
│       ├── catalog-schema.yaml
│       ├── bundle-schema.yaml
│       └── signal-schema.yaml
├── outcome/
│   └── v1/
│       └── outcome-schema.yaml
└── adapter/
    └── v1/
        └── adapter-interface.yaml
```

## 与 Core/Workspace 的关系

```
Protocols 定义:
  Core 和 Workspace 之间的数据格式契约

Core Kernel 模块:
  通过 Protocols 读取和写入 Workspace 数据

Workspace:
  存储符合 Protocols 定义的数据

Core 升级时:
  新 Protocols 版本 → 旧 Workspace 数据通过 Migration 兼容
```