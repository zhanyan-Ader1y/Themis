# P5.5 / impl-05 — 文档、设计契约与发布

## 目标

让仓库级设计契约、模块 WIKI、工作流、计划索引和发布元数据与 P5.5 实际行为一致。文档不得声称未安装的 Agent、Command、Freshness、Embedding 或上游结构化工件已经可用。

## `AGENTS.md` 与 `AGENTS.CN.md`

在 Knowledge Governance 领域同步记录：

- candidate/review/action 是追加式治理记录；修订通过新候选和 `supersedes` 表达；
- 精确重复是脚本事实，语义重复/冲突是待治理判断；
- 所有 v1 最终处置需要持久化人工批准；
- 正式 Context 的提升和废弃只能通过确定性 apply 执行器完成；
- apply 不得静默覆盖 Context，失败必须回滚或报告不确定状态。

英文与中文文件语义必须同步；`AGENTS.md` 继续作为冲突时的权威来源。

## P5.5 计划文档

更新 `docs/plan/55-knowledge-governance/README.md`：

- 依赖修正为 P1、P2、P5；
- 删除“Shell 全部留待 P8”的冲突描述；
- 将 P8 边界改为 Agent/Command/Skill/路由；
- 目标文件加入 artifact templates、Core scripts、测试和发布文件；
- 修正分类全集和治理流程；
- 验收条件改为可确定性验证的契约与行为。

完成全部实现和验证后，将该 README 与 `docs/plan/README.md` 状态更新为“已完成”。在此之前保持“实施中”或“impl 待确认”，不得提前标记完成。

## Kernel WIKI

更新 `docs/core/kernel/knowledge.md`：

- 明确 Candidate Extraction、Review Recommendation、Human Decision、Deterministic Apply 的职责分离；
- 将 `workspace/knowledge/` 定义为治理历史而非第二知识库；
- 解释六种候选/废弃处置；
- 说明候选不移动、不删除、修订追加；
- 说明 provenance、摘要绑定、stale review、锁和回滚；
- 标出 P6/P7.5/P8 未安装时的 unavailable 路径。

## Policies WIKI

更新 `docs/core/policies.md` 中 `knowledge-governance.yaml`：

- 使用真实根 Schema 和稳定 ID；
- 展示来源、分类、流程顺序、审核维度和处置；
- 删除 `similarity_threshold: 0.8`；
- 解释 exact duplicate 与 semantic assessment 的边界；
- 解释 v1 只允许人工批准。

不得顺手实现全局 Effective Policy 合并器；若项目级 override 存在但当前没有确定性解析能力，应报告缺失能力。

## Templates 与 Protocols WIKI

更新 `docs/core/templates.md`：

- `knowledge-candidate.md`：候选工件；
- `knowledge-review-record.md`：审核和批准工件；
- `knowledge-action-record.md`：脚本执行结果；
- `knowledge-candidate-extraction.md`：候选提取 Prompt；
- `knowledge-review.md`：审核/废弃 Prompt。

更新 `docs/core/protocols.md`：

- 三类知识治理工件的 Schema 和引用关系；
- candidate/review/action/context 的摘要绑定；
- provenance 必填和 stale review 拒绝；
- Context Catalog 项的 candidate/review/action 反向引用。

协议文档只描述数据结构，不吸收脚本执行步骤。

## Workspace WIKI

更新 `docs/workspace/overview.md`：

- `candidates/` 保存原始追加式候选；
- `reviews/` 保存审核和 promote/revise/merge/retain action；
- `rejected/` 保存拒绝 action，不是移动后的唯一候选副本；
- `archive/` 保存废弃 Context 的历史快照/action，不构成当前正式知识；
- 治理子目录的创建遵循 P5.4 Workspace Schema 与 Migration；Runtime 不创建或迁移 Catalog；
- Upgrade 绝不补建或改写既有 Workspace。

## 工作流 WIKI

更新 `docs/workflow.md` 的 Knowledge 流程：

- 使用真实 Prompt/Script 读取顺序；
- 区分 AI recommendation、human decision、script action；
- 未实现的 P6 Freshness、P7.5 Outcome、P8 Agent 输入用虚线或 unavailable 标识；
- 不把 P5.5 完成解释为自动知识捕获或自动 Context 更新。

## 发布元数据

P5.5 是新增可安装 Runtime 能力，协调提升 Core/Bundle 次版本：

- `templates/.themis/VERSION`
- `templates/.themis/core/core.yaml`
- `CHANGES.md`

实施时根据当前基线确定具体版本；若基线仍为 `0.2.0`，目标为 `0.3.0`。同时更新 Upgrade 测试中的候选版本和 rollback 基线，避免版本等于当前 Core 导致测试失真。

## 文档一致性检查

完成后逐项确认：

1. README、impl、AGENTS、WIKI、policy 和 Prompt 使用相同来源/分类/处置 ID。
2. 所有脚本路径均为 `core/bin/`，不存在根 `bin/` 与安装后路径混淆。
3. 文档不再宣称自动 embedding、Freshness 或 P8 Agent 已实现。
4. Workspace 文档不再描述“移动 candidate”导致历史丢失。
5. `catalog.yaml` 的字段、Context Item digest 与 apply 脚本实际输出一致。
6. 版本、CHANGES、计划状态和测试期望一致。
7. 所有确认的新仓库级设计规则同时进入英文和中文 AGENTS。
