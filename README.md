<h1 align="center">Themis</h1>

<p align="center"><strong>面向团队的 repo-local、规范驱动 AI Coding Harness</strong></p>

Themis 用常驻控制面和按需语义能力组织从需求理解到交付验收的受治理软件开发。它的目标不是让 Agent 自由生成代码，而是让需求、设计、Review、实现、验证和知识沉淀拥有明确边界、可追溯依据与人工决策点。

## 产品特点

- **Spec 前追问**：每项需求先通过 `themis-q` 收敛提出需求的原因、期望结果和抽象核心链路，再进入 Specification 细化；需求追问不提前决定合同、边界或实现方案。
- **更轻松的 Review**：Plan 完成后自动生成只读 `review.md`，按需使用流程图或时序图提供 Overview，并将 Review 项从抽象到具体精简呈现。用户通过 Agent 对话按需展开 Plan 原文，最终批准特定 Plan revision，而不是机械逐项确认或手动维护投影。
- **外部经验可沉淀**：失败经验、开发经验、已验证实践以及失败后成功的恢复经验可以形成知识候选，不因脱离当前 Themis 对话而丢失。
- **不断进化的项目知识库**：经过事实核验、人工 Review 和授权的项目知识与项目经验可以进入 Themico，以不同治理策略保留当前内容、历史来源和显式关系。

## 目标主流程

```text
用户需求
→ themis-q
→ Specification
→ Planning
→ Plan Check
→ review.md
→ Human Review
→ Review Approval
→ Verify
   ├─ Impl
   └─ Verification
→ Human Acceptance
→ Summary
→ 可选知识候选治理
```

关键边界：

- **Specification** 定义交付必须具备的语义、可观察行为和结果。
- **Planning** 调查实现事实，完成技术设计、方案取舍、任务分解和 Verification 设计。
- **Plan** 是首个完整、持久化的语义工件，也是实现的唯一语义来源；不生成独立 `spec.yaml` 权威。
- **Review** 必须发生在实现前；`review.md` 是从 Plan 生成的只读人工投影，不是第二份 Plan。
- **Verify** 包含相互独立的 Impl 与 Verification；实现者不能自行给出验证通过结论。
- **Summary** 只在 Verification 通过且 Human Acceptance 接受后生成，记录实际落地结果，不是中间阶段摘要。

## 控制架构

```text
Global Control Rule
├─ 生命周期、门禁、路由、失效与恢复
├─ revision / digest / 状态合同校验
├─ 每任务失败预算与终止
└─ 按需调用 Skill
   ├─ 前台交互能力
   ├─ 隔离 Worker Agent
   └─ 独立 Checker Agent
```

- **Rule 管流程**：只执行确定性的组装、校验、状态路由和失效传播，不改写用户意图、补充 Specification、选择实现方案或给出 Verification verdict。
- **Skill 管语义**：定义能力的方法、输入、状态和输出，不直接调用其他 Skill，也不拥有全局生命周期。
- **Agent 是执行载体**：需要隔离上下文的 Skill 可由受限 Agent 执行；Agent 不是新的能力层或权威。Impl 可以在批准范围内写入，Verification 和其他 Checker 保持只读。

Plan 35 只规划一个控制面按需调用一个受限 Agent 的基础模型。并行协作、投票、委派、持久 Agent 和其他复杂拓扑属于后续可选能力，不能成为核心交付门禁。

## 失败控制与经验学习

每个稳定任务最多允许三次计数失败：

```text
attempt 1 failed
→ attempt 2 failed
→ attempt 3 failed
→ 终止该任务
```

- 切换 Agent、模型、工具或恢复会话不能重置计数。
- `continue`、外部 `blocked`、语义返工和调度前门禁拒绝不计入失败。
- 第三次失败后，控制面只机械终止任务，不能自行把重复失败解释成 Planning 或 Specification 缺陷。
- 只有对应语义能力形成新的权威输入和替代任务，才能启动新的失败预算；这不是原任务的第四次重试。

每次计数失败后，可以由独立 Failure Learning Skill 非阻塞判断是否值得形成 Themico 项目经验候选。后续成功时，可以追加恢复或成功经验并关联原失败。该分析不能改变任务状态、重试预算或交付结果，也不能绕过知识治理直接发布正式经验。

## Themico 知识库方向

Themico 是独立、本地优先、受治理的知识库设计，不依赖 OpenViking、向量数据库、外部模型服务或其他知识库作为运行后端。

```text
Zone
└─ Knowledge Record
   ├─ L1：发现与筛选
   ├─ L2：理解与规划
   └─ L3：完整 Markdown 内容
```

初始治理边界：

- **项目知识区**：保存架构、领域划分、Bounded Context、核心业务链路和已批准设计规则。内容可以更新，但必须保留历史和来源。
- **项目经验区**：保存失败经验、失败诊断、开发经验、恢复经验和已验证实践。内容以追加为主，更正、替代及失败后成功通过显式关系表达。

项目经验不能自动升级为当前项目事实。Agent 只能形成知识候选；正式知识必须经过核验、Review 和授权。

## 当前状态

本仓库当前处于设计与安装包合同重建阶段：

- `themis-q` 方法和部分声明式 Rule、Policy、Protocol、Template 与 Workspace scaffold 已存在；
- Plan 35 的新 Prompt-first 流程和 Themico 目前仍是待审阅、待实施的设计；
- 当前没有可运行的 Init、完整生命周期执行器、确定性状态记录器或生产运行时；
- 本 checkout 不提供安装命令，也不得把目标设计描述为已经可用的产品能力；
- 不提供生产 Shell runtime 或 Shell fallback；
- 每个模块只维护唯一当前合同，不引入功能版本、Upgrade 或 Migration 机制。

后续活动计划的依赖顺序为：

```text
Plan 35 Core Prompt Flow
→ Plan 36 Deterministic Assurance
→ Plan 37 Native Runtime

Plan 80 Multi-Agent Execution   optional / non-blocking
Plan 90 Attribution Analytics   optional / post-delivery / non-blocking
```

每个计划都必须单独审阅和授权；设计确认不等于授权实施。

## 文档

- [安装包与模块合同](templates/.themis/README.md)
- [活动实施计划](docs/plan/README.md)
- [Plan 35 Core Prompt Flow 设计](docs/superpowers/specs/2026-07-29-plan-35-core-prompt-flow-design.md)
- [Themico 顶层设计](docs/superpowers/specs/2026-07-29-themico-design.md)
- [更新日志](CHANGES.md)

## 许可证

本项目采用 [MIT License](LICENSE)。
