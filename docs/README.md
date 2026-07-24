# Themis — 规范驱动开发 (SDD) 框架

Themis 是一个为 AI 辅助编码 (Vibe Coding) 设计的 SDD 控制框架，安装到目标项目后提供规范驱动开发的完整生命周期管理能力。

## 核心设计原则

```
Core 定义能力，不保存项目内容
Workspace 保存内容，不实现控制逻辑
Core 可以升级，Workspace 不被覆盖
Workspace 可以演进，Core 通过协议解释
```

## WIKI 导航

### 实施计划

计划按模块与依赖优先级管理；它们不会自动执行。用户主动发起某项计划后，必须先在同级目录编写 `impl.md` 并取得确认，才可进入实现。

| 文档 | 说明 |
|---|---|
| [实施计划索引](plan/README.md) | P0–P8 模块计划、依赖图与执行协议 |
| [Init Environment](runtime-environment.md) | Init 阶段的 Bash、Git 与 mikefarah/yq 前置要求 |

### Core — 控制能力

Core 由 Themis 维护，提供 SDD 通用控制能力，**原则上只读**。

#### Kernel — 核心领域逻辑

| 模块 | 职责 |
|---|---|
| [Orchestrator](core/kernel/orchestrator.md) | 生命周期驱动、状态迁移、任务路由、失败恢复 |
| [Specification](core/kernel/specification.md) | Spec 结构定义、语义校验、验收标准 |
| [Planning](core/kernel/planning.md) | Plan 模型、Task 模型、可追踪性、Plan 校验 |
| [Context](core/kernel/context.md) | 项目上下文发现、解析、冲突处理、新鲜度 |
| [Verification](core/kernel/verification.md) | Gate 调度、证据采集、失败分类、Verdict 计算 |
| [Review](core/kernel/review.md) | 只读评审约束、评审结果标准化 |
| [Attribution](core/kernel/attribution.md) | 身份关联、产出模型、归因分析 |
| [Knowledge](core/kernel/knowledge.md) | 知识候选、去重、审核、提升、废弃 |

#### Core 基础设施

| 模块 | 职责 |
|---|---|
| [Protocols](core/protocols.md) | Core 与 Workspace、外部工具的数据契约 |
| [Policies](core/policies.md) | 默认治理策略（生命周期、状态迁移、Gate 语义等） |
| [Templates](core/templates.md) | 默认工件模板（Spec、Plan、Review、Verify 等） |
| [Adapters](core/adapters.md) | 外部工具链交互封装（Git、Shell、测试、CI 等） |
| [Migrations](core/migrations.md) | Core 升级时的 Workspace Schema 和工件格式迁移 |

### Workspace — 项目空间

Workspace 由项目持有，**运行过程中可读写**。

| 章节 | 职责 |
|---|---|
| [Workspace 概述](workspace/overview.md) | 项目配置、上下文、工件、状态、运行证据的完整说明 |

## 目录结构

```
<project-root>/
└── .themis/
    ├── core/           # Themis 自身控制能力（只读）
    │   ├── kernel/     # 核心领域逻辑
    │   ├── protocols/  # 数据契约
    │   ├── policies/   # 默认治理策略
    │   ├── templates/  # 工件模板
    │   ├── adapters/   # 外部工具适配
    │   └── migrations/ # 升级迁移
    │
    └── workspace/      # 项目配置、知识和执行产物（可读写）
        ├── manifest.yaml
        ├── policies/
        ├── context/
        ├── specs/
        ├── state/
        ├── runs/
        ├── evidence/
        ├── outcomes/
        ├── knowledge/
        └── cache/
```

## 版本模型

三个独立版本标识：

| 版本 | 位置 | 说明 |
|---|---|---|
| Template Bundle Version | `.themis/VERSION` | 模板包发布版本；必须与同一模板中的 Core Version 相同。 |
| Core Version | `core/core.yaml` | Themis 框架自身版本。 |
| Workspace Schema Version | `workspace/manifest.yaml` | Workspace 结构版本；独立于 Core release。 |
| Artifact Schema Version | `workspace/manifest.yaml` | 工件格式版本；独立于 Core release 与 Workspace Schema。 |

Core 升级时分别检查 Workspace 与 Artifact Schema：位于 `core.yaml` 对应 `supported` allow-list 中即兼容；有显式迁移描述符即必须由用户启动迁移；其余情况拒绝运行并给出诊断。Schema 版本不通过与 Core Version 的字面相等性判断。
