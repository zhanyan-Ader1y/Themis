# operation-contract

## 用途

本 reference 定义 `.themico/core/references/operations/` 下每份 operation reference 必须固定包含的结构。它不描述任何具体 operation 的输入或行为；具体行为只在对应 operation reference 中说明。

## 固定结构

每份 operation reference 必须依次包含以下七个部分：

1. **输入与前置条件**：本 operation 需要的 machine JSON/Markdown 输入文件形状，以及执行前必须已经成立的状态（例如候选必须处于某个 status）。
2. **Agent 职责**：Agent 在调用 CLI 前后必须完成、且只有 Agent 能完成的工作（起草内容、提出分类依据、解释相关性等）。这些职责产出 proposal，不产出 published/current/valid 的权威结论。
3. **对应 `themico` CLI command**：本 operation 唯一对应的一条 `themico` 命令行，逐字引用 `themico help` 暴露的命令面。
4. **Human gate**：本 operation 是否需要独立于 Agent 的 Human 确认或授权；若需要，说明该 gate 授权的确切事项（不得与其它 gate 合并）。
5. **权威输出**：CLI stdout 的 JSON result envelope 中，`output` 字段承载的权威数据形状，以及它对应哪个 model 结构。
6. **合法 machine statuses**：本 operation 在 envelope `status` 字段上实际可能出现的取值子集，取自 `common/result-contract` 的闭集，不得声称闭集之外的状态。
7. **fail-closed 行为**：当输入无效、前置条件不满足、并发写入冲突或依赖不可用时，本 operation 如何在不产生部分成功、不产生伪造权威结论的前提下失败。

## 与本文件的关系

本文件只规定“形状”，不重复三种知识类型的完整 L2/L3 合同，不定义新的 Zone、类型、状态或关系——那些内容分别位于 `.themico/core/references/types/` 与 `.themico/core/references/common/knowledge-record.md`、`.themico/core/references/common/type-registry.md`。
