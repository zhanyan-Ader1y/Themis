<h1 align="center">Themis</h1>

<p align="center"><strong>面向团队的 repo-local、规范驱动 AI Coding Harness</strong></p>

Themis 让团队能够以更清晰、更易评审和更可追溯的方式使用 AI 完成软件变更。它关注的不是让 Agent 不受约束地生成代码，而是让需求理解、方案设计、实现验证和知识积累形成一条有人类决策参与的受治理交付链路。

## 核心特性

- **Spec 前追问**：在细化需求前先理解问题为什么提出、期望改变什么结果，以及从需求场景到目标结果必须经过的核心链路，避免从模糊输入直接进入设计或实现。
- **更轻松的 Review**：将完整设计提炼为由抽象到具体的评审内容，按需提供流程图或时序图 Overview，帮助评审者先理解整体方案，再聚焦关键取舍、风险和验证方式。
- **外部经验可沉淀**：失败、恢复、开发经验和已验证实践可以形成知识候选，不因发生在其他 Agent、工具或对话中而丢失。
- **不断进化的项目知识库**：项目知识与项目经验在保留来源、历史和关系的前提下持续更新，并通过核验、Review 和授权进入正式知识。

## 核心流程

```text
外部请求形成不可变 Intake Source Event
→ 确认可追溯的 Current Request claims
→ 设计与评审
→ 实现与独立验证
→ 人工验收与知识候选
```

- **Intake 与需求理解**：先保存用户原始输入并确认 source-bound claims，再收敛需求动机、期望结果和必要的核心链路。
- **设计与评审**：细化交付语义，调查项目事实，形成完整技术方案，并在实现前通过精简视图完成人工 Review。
- **实现与验证**：在批准范围内完成实现，再由独立验证确认实际结果是否满足设计和验收要求。
- **验收与知识沉淀**：由人类接受实际交付结果并生成交付摘要；有复用价值的项目知识和经验按需进入独立治理流程。

## 目标能力

- 收敛需求的 Why、期望结果和抽象核心链路；
- 完成 Specification 细化、项目事实调查和完整技术规划；
- 通过图形化 Overview 与渐进展开降低人工 Review 压力；
- 约束实现范围，并保持实现与验证相互独立；
- 以技术验证、人工验收和交付摘要共同闭合交付；
- 在本地保存供人类与 Agent 共享的项目知识和项目经验，支持渐进读取、来源追溯和受治理更新。

## 当前状态

Themis 当前处于设计与安装包合同重建阶段，目标流程尚未形成可运行产品。当前模板已表达 Intake-first、十六个内部 Capability、四个固定 Agent Profile 与双作用域单一 policy 的 Prompt-level 合同；严格校验和原生执行仍由后续计划负责。详细实施状态请查看[活动实施计划](docs/plan/README.md)。

## 文档

- [安装包与模块合同](templates/.themis/README.md)
- [活动实施计划](docs/plan/README.md)
- [Core Contract Replacement 目标设计](docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement-design.md)
- [Themico 顶层设计](docs/superpowers/specs/2026-07-29-themico-design.md)
- [更新日志](CHANGES.md)

## 参考项目

- [superpowers](https://github.com/obra/superpowers)
- [lattice](https://github.com/zdolphin07-dotcom/lattice)
- [openviking](https://github.com/volcengine/OpenViking)
- [graphify](https://github.com/Graphify-Labs/graphify)

## 参考文章

- [从 Vibe Coding 到渐进式 Spec驱动开发](https://mp.weixin.qq.com/s/xuFwPJelKHIQBT3CMgpqVQ)
- [高德广告工程的AI Native知识库体系](https://mp.weixin.qq.com/s/1d9LDoD2SOcEZ19mDwiE-Q)
- [从AI Coding到Harness Engineering的端到端工程开发实践](https://mp.weixin.qq.com/s/UE-RZH9hnbBd06CVapFGrA)
- [Agent 治理：用 Hook 堵住 LLM 的偷懒、越权与失忆](https://mp.weixin.qq.com/s/ISwjIw5lj7JlcQJV7BOx5g)
- [Spec-Driven Development: From Code to Contract in the Age of AI Coding Assistants](https://arxiv.org/html/2602.00180v1)
- [Spec-Driven Development (SDD) — best practices (so far)](https://blog.allegro.tech/2026/06/spec-driven-development-best-practices.html)
- [SDD and the Future of Software Development](https://www.cesarsotovalero.net/blog/sdd-and-the-future-of-software-development.html)


## 许可证

本项目采用 [MIT License](LICENSE)。
