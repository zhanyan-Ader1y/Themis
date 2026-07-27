# Themis 实施计划

本目录以模块为单位管理 Themis 的提案、实施设计、任务和执行历史，属于非规范文档。已确认的长期设计以 [Themis 设计规范](../design/README.md) 为准；计划内容与正式设计冲突时，不得覆盖正式设计。

> **执行协议**：计划文档不是实现授权。只有用户主动发起某个计划后才可开始执行。执行的第一步必须在该计划自身目录创建或更新 `impl.md`（即 `docs/plan/<priority>-<slug>/impl.md`），将设计决策、任务拆分、目标文件和验证矩阵落地。`impl.md` 完成后必须等待用户确认，确认前不得修改该计划所涉及的实现文件。

## 计划队列

| 优先级 | 计划 | 模块 | 依赖 | 状态 |
|---|---|---|---|---|
| P0 | [Init Environment Validation](00-runtime-environment/) | Init 所需的 Bash、Git、yq 前置环境校验 | 无 | 已完成 |
| P1 | [Template Contract](10-template-contract/) | 安装模板、版本和 YAML 契约 | P0 | 已完成 |
| P2 | [Top-level Guidance](20-top-level-guidance/) | Themis 顶层 SDD 指引与路由 | P1 | 已完成（运行时 import 探针待认证环境复核） |
| P3 | [Init](30-init/) | 交互式安装流程 | P0、P1、P2 | 已完成 |
| P4 | [Upgrade](40-upgrade/) | 无损升级 | P1、P3 | 已完成 |
| P4.5 | [Explicit Migration](45-explicit-migration/) | 显式 Workspace/Artifact Schema 迁移执行器 | P1、P4 | 已完成 |
| P5 | [Requirement Questioning](50-requirement-questioning/) | Spec 创建前的追问与需求澄清 | P1、P2 | 已完成（P8 状态执行器待实施） |
| P5.2 | [Spec Dual View](52-spec-dual-view/) | `spec.yaml` Agent 权威源 + `spec.md` Human 审阅投影 | P4.5、P5 | 实施设计待确认 |
| P5.4 | [Context Restructure](54-context-restructure/) | 双轴可信源、L1/L2/L3 Context、Catalog、检索装配与 Signal | P1、P2、P4.5、P5 | 设计完成，待发起 |
| P5.5 | [Knowledge Governance](55-knowledge-governance/) | 人机混合知识治理（候选→审核→提升→废弃） | P1、P2、P5、P5.4 | 待发起 |
| P5.8 | [Planning Enhancement](58-planning-enhancement/) | 计划增强（Task 模型、依赖 DAG、Traceability、Plan 校验） | P1、P5 | 待发起 |
| P5.9 | [Implementation Enhancement](59-implementation-enhancement/) | 实施增强（Task 执行、范围锁定、证据记录、进度评估） | P1、P5、P5.8 | 设计中 |
| P6 | [Behavior Map & Change Localization](60-behavior-map/) | 代码行为地图与变更定位子系统 | P1、P5、P5.4 | 待发起 |
| P6.5 | [Verification Enhancement](65-verification-enhancement/) | 验证增强（Gate 策略、失败分类、对抗式证据检查） | P1、P5 | 待发起 |
| P6.8 | [Review Enhancement](68-review-enhancement/) | 评审增强（评审维度、严重级别、独立证据审查） | P1、P5、P6.5 | 待发起 |
| P7 | [Integration Audit](70-integration-audit/) | 模块串联、加载机制、编排保证、知识入口、结构审计 | P1–P6 | 分析完成 |
| P7.5 | [Attribution & Outcome](75-attribution-outcome/) | 归因与交付结果（Outcome 分类、归因分析、质量趋势） | P1、P6.5、P6.8 | 待发起 |
| P8 | [Multi-Agent Architecture](80-multi-agent-architecture/) | 7 领域专用 Agent + Shell 确定性操作 | P1、P5、P7 | 待发起 |

## 依赖图

```text
P0 Init Environment Validation
 └── P1 Template Contract
      ├── P2 Top-level Guidance
      │    ├── P3 Init ── P4 Upgrade
      │    │    └── P4.5 Explicit Migration      ← 迁移执行器
      │    └── P5 Requirement Questioning
      │         ├── P5.2 Spec Dual View             ← Agent/Human 双视图
      │         ├── P5.4 Context Restructure        ← 可信源、分层 Context 与装配
      │         │    ├── P5.5 Knowledge Governance ← 知识治理
      │         │    └── P6 Behavior Map           ← 行为地图
      │         ├── P5.8 Planning Enhancement      ← 计划增强
      │         │    └── P5.9 Implementation Enhancement ← 实施增强
      │         ├── P6.5 Verification Enhancement ← Gate 策略
      │         └── P6.8 Review Enhancement       ← 评审增强
      └── P7 Integration Audit                   ← 跨模块集成
           ├── P7.5 Attribution & Outcome        ← 归因与结果
           └── P8 Multi-Agent Architecture       ← Agent 层

P0 仅由 Init 调用。
P4.5 是 P4 的补充能力，可独立实施；P5.2 与 P5.4 的 Artifact/Workspace Schema 变化必须消费其迁移机制。
P5.2 为后续 Planning 与 P8 提供结构化 Spec 契约。
P5.4 是 P5.5 与 P6 的共同前置，统一项目事实可信源、Context Catalog、L1/L2/L3、Bundle、Signal 与 B1/B2/B3 命名。
P5.5/P5.8/P6/P6.5/P6.8/P7.5/P8 属于 SDD 运行时能力。
P7 是跨模块分析性审计。
P8 是最终执行层。
```

## 通用边界

- Themis 默认假设用户已有文件系统权限与 Agent 环境；计划及实现不得检查、安装或配置这两者。
- Bash、Git 与 [mikefarah/yq](https://github.com/mikefarah/yq) 是 **Init 的安装前置环境**，仅由 Init 校验；已安装 Themis 的 SDD 运行流程不会调用这些环境检查。
- Core 是 Themis 管理的能力层；Workspace 是项目持有的内容与运行数据层。任何计划不得违背“升级不覆盖 Workspace”的边界。
- 每项计划的 `impl.md` 是该计划自身的执行设计记录，不是新的长期 WIKI 模块；它位于对应计划目录中，便于隔离审计。
