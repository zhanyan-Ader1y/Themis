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

## Themico

Themico 是安装到仓库根目录 `.themico/` 下的独立知识治理 CLI 与配套 Skill，用于让 Human 与 Agent 在本地完成一次真实、受治理且可验证的知识发布与读取。Themico 与 Themis 治理框架松耦合，不共享运行时。

- 顶层设计：[`docs/superpowers/specs/2026-07-29-themico-design.md`](docs/superpowers/specs/2026-07-29-themico-design.md)
- 首个可用交付范围（本节描述的能力边界的权威来源）：[`docs/superpowers/specs/2026-07-29-themico-design/first-usable-delivery.md`](docs/superpowers/specs/2026-07-29-themico-design/first-usable-delivery.md)
- 公共 Skill 发现入口：[`templates/.themis/skills/themico/SKILL.md`](templates/.themis/skills/themico/SKILL.md)
- CLI 构建入口：`go build -o themico ./cmd/themico`（module `github.com/zhanyan-Ader1y/Themis`，Go 1.26，二进制名固定为 `themico`）
- 实现证据与人工 replay 记录：[`docs/plan/themico-core/implementation-evidence.md`](docs/plan/themico-core/implementation-evidence.md)、[`docs/plan/themico-core/manual-replay.md`](docs/plan/themico-core/manual-replay.md)

以下内容只陈述首个可用交付**已经**实现并被 fresh 证据核实的能力，不描述计划或设计中尚未落地的部分。

### 已实现能力

`themico` 当前提供 11 条可构建、可运行、且每次只输出一个 JSON result envelope 的命令：

```
themico help
themico init --root <root>
themico candidate create --root <root> --input <candidate.json> --content <content.md>
themico candidate revise --root <root> --input <revision.json> --content <content.md>
themico candidate confirm-type --root <root> --confirmation <confirmation.json>
themico candidate inspect --root <root> --id <candidate-id>
themico validate --root <root> --candidate <candidate-id> --revision <candidate-revision>
themico prepare publish --root <root> --candidate <candidate-id> --assessment <assessment.json>
themico publish --root <root> --prepare <prepare-id> --approval <approval.json>
themico query --root <root> --request <query.json>
themico inspect --root <root> --request <inspect.json>
```

这些命令共同支持的端到端链路（`init → create/revise candidate → Human confirm-type → deterministic validate → independent semantic assessment → prepare publish → Human Approval → publish → query L1 → exact-ID inspect L2/L3`）已经过真实二进制在临时仓库中的人工 replay 核实，覆盖 `design_decision`、`development_standard`、`development_experience` 三个首批知识类型与 `project_knowledge`、`project_experience` 两个 Zone；类型确认后改型、source drift、错误/stale Approval、并发 generation conflict、投影/内容篡改、byte budget 不足等失败关闭路径同样经过真实 replay 核实。详见 [`docs/plan/themico-core/manual-replay.md`](docs/plan/themico-core/manual-replay.md)。

`candidate create`/`candidate revise` 的 `--content <content.md>` 上限是 **128 KiB**，不是设计文档早先写的 4 MiB：终审发现 4 MiB 的候选内容会被 `inspect --depth 3` 的 1 MiB canonical envelope 硬上限永久拒读（发布后读不回），已在 `internal/themico/candidate/service.go` 的 `maxContent` 常量收紧并加测试锁定；这条上限的完整推导过程见该常量自身的注释。**这条修复只堵住了 L3（content.md）本身导致的读不回，不构成"任何已发布记录都能被 depth-3 读回"的整体保证**：`L1`、`L2`、`Scope` 都没有独立的字节上限，唯一约束是整份 `candidate.json`（不含走 `json:"-"` 的 `content.md`）不超过 1 MiB。因此仍可构造一个 `L1.Tags`/`Summary` 或 `L2.Payload` 逼近 900 KB 的候选，配合任意合法的 128 KiB content 成功发布，此后该记录的 `inspect --depth 3` 会永久返回 `validation_failed`。这一缺口与恢复到接近 4 MiB 的能力，都需要先解决已知缺陷 2（下方）指出的 envelope 预算模型本身，属后续独立计划。

### 当前 unavailable（尚未实现，属后续独立计划）

以下能力目前**不存在**任何命令、占位 handler 或未接线 reference——不得在本仓库其他文档或对话中声称已支持：

- **生命周期与派生**：`supersede`、`deprecate`、`archive`、history query、跨类型派生与 `create-derived-candidate`。
- **关系与查询增强**：relation traversal、多跳查询、跨 Zone 查询扩展、cycle analysis、Agent relevance ranking、enriched semantic explanation。
- **投影与性能增强**：project/domain/architecture unit/feature 聚合 view、`rebuild` 命令、增量 view 维护、cache、并行 query。
- **外部来源与集成**：URL source、MCP adapter、Claude API 或内置模型、Embedding、向量数据库、SQLite、Web UI、Themis lifecycle 正式接线、token budget（当前只实现 byte budget）。

### 已知缺陷（如实披露，非规划中的延期项）

以下三条是已确认的实现缺陷，不是设计延期，待后续独立计划修复：

1. **`l1.json` 与 `l2.json` 目前是同一份完整 `model.Projection` 的字节副本**（两文件字节相同）。根因是 `internal/themico/store/generation.go` 的 `validateProjectionReference` 要求两个文件都解码为完整 `model.Projection` 并各自校验 `record.L1` 与 `record.L2`。`query` 命令的 API 层发现/升级边界仍然成立（返回值只含 L1 字段），但"L1、L2 是两个独立存储单元"这一物理保证目前不成立：任何能读到 `l1.json` 的人也能读到完整 L2 内容。
2. **CLI 实际可返回的结果上限受 1 MiB envelope 编码限制约束，并非 `query`/`inspect` 请求里可声明的 16 MiB `content_budget_bytes`。** `internal/themico/canonical/canonical.go` 的 `Encode` 对任意一次 machine JSON 编码都有硬编码的 1 MiB 上限；一个通过了 16 MiB byte budget 门禁、语义上完全成功的多记录结果集，在 CLI 把整个 result envelope 编码为一个 JSON 对象时可能超过这个硬上限，被兜底为 `internal_error` 而非清晰的 `budget_exceeded` 或诚实的成功结果。**不要把 16 MiB 预算宣传为完全可用的读取能力上限。**
3. **`governance` 的 semantic assessment 独立性检查只在部分操作顺序下真正独立。** `checkAssessment` 要求 checker identity 不同于 proposer，也不同于当前 revision 的 reviser（读取 `candidate.RevisedBy`）；但 `candidate.Service.ConfirmType` 会用 `ConfirmedBy` 覆写 `RevisedBy`。在 `create → revise → confirm-type → assess` 这一合法顺序下（`confirm-type` 发生在 `revise` 之后，中间不再 `revise`），原 reviser 的身份已被 `ConfirmedBy` 从 `RevisedBy` 字段抹除，`checkAssessment` 只能看到覆写后的值，该 reviser 因而仍可为自己撰写的当前内容出具通过的 semantic assessment 而不被拦截。[首个可用交付范围](docs/superpowers/specs/2026-07-29-themico-design/first-usable-delivery.md) 第 8 节验收条目 7（"checker identity 字段与 proposer 不同"）字面上仍然成立；被削弱的是[顶层设计](docs/superpowers/specs/2026-07-29-themico-design.md) 第 3.4 节"Agent 只能产生…semantic assessment…"这一核心不变量所期望的独立语义评估。**publication 仍需要一份精确绑定 prepare 的独立 Human Approval，这道 gate 没有被削弱**，因此这不构成"无人审查即可发布"。彻底修复需要引入一个能跨 `ConfirmType` 存续的"当前内容真实撰写者"身份，涉及 model 与生命周期变更，属后续独立计划。

第 1、2 条缺陷的真实复现步骤见 [`docs/plan/themico-core/manual-replay.md`](docs/plan/themico-core/manual-replay.md)"补充复现材料 A/B"；第 3 条经定向再评审代码走查确认（推导见上），未新增独立复现材料。

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
