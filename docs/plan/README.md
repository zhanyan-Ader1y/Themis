# Themis 实施计划

本目录以模块为单位管理 Themis 的**待执行计划**。计划按优先级编号排序，编号同时表达依赖顺序。

> **执行协议**：计划文档不是实现授权。只有用户主动发起某个计划后才可开始执行。执行的第一步必须在该计划自身目录创建或更新 `impl.md`（即 `docs/plan/<priority>-<slug>/impl.md`），将设计决策、任务拆分、目标文件和验证矩阵落地。`impl.md` 完成后必须等待用户确认，确认前不得修改该计划所涉及的实现文件。

## 计划队列

| 优先级 | 计划 | 模块 | 依赖 | 状态 |
|---|---|---|---|---|
| P0 | [Init Environment Validation](00-runtime-environment/) | Init 所需的 Bash、Git、yq 前置环境校验 | 无 | 已完成 |
| P1 | [Template Contract](10-template-contract/) | 安装模板、版本和 YAML 契约 | P0 | 已完成 |
| P2 | [Top-level Guidance](20-top-level-guidance/) | Themis 顶层 SDD 指引与路由 | P1 | 已完成（运行时 import 探针待认证环境复核） |
| P3 | [Init](30-init/) | 交互式安装流程 | P0、P1、P2 | 已完成 |
| P4 | [Upgrade](40-upgrade/) | 无损升级与显式迁移 | P1、P3 | 已完成 |
| P5 | [Requirement Questioning](50-requirement-questioning/) | Spec 创建前的追问与需求澄清 | P1、P2 | 待发起 |
| P6 | [Behavior Map & Change Localization](60-behavior-map/) | 代码行为地图与变更定位子系统 | P1、P5 | 待发起 |
| P7 | [Integration Audit](70-integration-audit/) | 模块串联、加载机制、编排保证、知识入口、结构审计 | P1–P6 | 分析完成 |
| P8 | [Multi-Agent Architecture](80-multi-agent-architecture/) | 7 领域专用 Agent + Shell 确定性操作 | P1、P5、P7 | 待发起 |

## 依赖图

```text
P0 Init Environment Validation
 └── P1 Template Contract
      ├── P2 Top-level Guidance
      │    ├── P3 Init ── P4 Upgrade           ← 安装链路
      │    └── P5 Requirement Questioning
      │         └── P6 Behavior Map             ← SDD 运行时能力
      └── P7 Integration Audit                  ← 跨模块集成（已完成分析）
           └── P8 Multi-Agent Architecture      ← 执行层 Agent 拆分

P0 仅由 Init 调用。
P5/P6/P8 属于 SDD 运行时能力。
P7 是跨 P1–P6 的分析性审计。
P8 依赖 P5（Themis-Spec 追问）和 P7（集成审计结论）。
```

## 通用边界

- Themis 默认假设用户已有文件系统权限与 Agent 环境；计划及实现不得检查、安装或配置这两者。
- Bash、Git 与 [mikefarah/yq](https://github.com/mikefarah/yq) 是 **Init 的安装前置环境**，仅由 Init 校验；已安装 Themis 的 SDD 运行流程不会调用这些环境检查。
- Core 是 Themis 管理的能力层；Workspace 是项目持有的内容与运行数据层。任何计划不得违背“升级不覆盖 Workspace”的边界。
- 每项计划的 `impl.md` 是该计划自身的执行设计记录，不是新的长期 WIKI 模块；它位于对应计划目录中，便于隔离审计。
