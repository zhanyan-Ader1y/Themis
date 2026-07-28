# Themis 活动实施计划

`docs/plan/**` 是面向未来的活动实施队列，只保存尚待单独确认和执行的实施设计。长期规范以 [Themis 设计规范](../design/README.md) 及其所属设计页为准；本目录不替代正式设计，也不保存已经完成或退役计划的历史叙事。

## 授权规则

- 每个计划都是实施设计，必须由用户分别确认。
- 确认某个计划的设计不自动确认其依赖计划，也不自动授权后续计划。
- 本次队列清理只重组文档，**不授权实施 Plan 35 或任何其他计划**。
- 未获得目标计划的明确实施确认前，不得修改该计划涉及的产品、模板、运行时或测试文件。
- 实施过程中若需要改变已确认的长期设计，必须先按 [设计治理](../design/governance.md) 更新所属 `docs/design/**` 页面并取得相应确认。

## 活动队列

| 顺序 | 计划 | 依赖 | 定位 | 状态 |
|---|---|---|---|---|
| 35 | [Core Prompt Flow](35-core-prompt-flow/impl.md) | 无 | 串联八个领域的 Prompt-first 语义生命周期 | 待单独确认 |
| 36 | [Deterministic Assurance](36-deterministic-assurance/impl.md) | 已单独接受的 Plan 35 | 定义语言无关的严格合同与合同夹具 | 待单独确认 |
| 37 | [Native Runtime](37-native-runtime/impl.md) | 已单独接受的 Plan 36 | 以单一无版本 Go 模块实现首个新生产确定性运行时 | 待单独确认 |
| 80 | [Multi-Agent Execution](80-multi-agent-execution/impl.md) | 可选；核心生命周期不依赖 | 定义隔离、handoff、聚合和证据边界 | 待单独确认，非阻塞 |
| 90 | [Attribution Analytics](90-attribution-analytics/impl.md) | 可选；交付后使用 | 定义 Attribution 与 Outcome 分析 | 待单独确认，非阻塞 |

## 依赖与阶段约束

```text
Plan 35 Core Prompt Flow
  └── Plan 36 Deterministic Assurance
        └── Plan 37 Native Runtime

Plan 80 Multi-Agent Execution       optional / non-blocking
Plan 90 Attribution Analytics       optional / post-delivery / non-blocking
```

核心生命周期保持：

```text
Context → Specification → Planning → Review → Implementation
        → Verification → Human Acceptance → Summary → Knowledge
```

- Review 必须发生在 Implementation 前，并绑定待实施的 current Spec 与 Plan。
- Verification 必须发生在 Implementation 后；证据缺失、不确定、不可访问或已失效时不得报告成功，必须返回 `inconclusive` 或失败。
- Human Acceptance 只能在 current Verification 返回 `pass` 后记录。
- Summary 只能在 Human Acceptance 已持久记录为 `accepted` 后生成。
- Plan 80 和 Plan 90 不得成为 Verification、Human Acceptance、Summary 或核心生命周期完成的前置条件。

## 通用实施边界

- 不引入功能性 `v1`、`v2` 或模块/协议版本目录；模块只维护唯一 current contract。
- Prompt 与 Agent 行为拥有意图、方案、风险、Review、语义判断和知识价值判断。
- 确定性执行器只拥有可验证的解析、校验、状态、投影、事务、文件和命令执行，不得替代语义判断。
- 只能调用实际存在且已核验的工具、命令和能力；不得虚构文件、状态、输出、命令、证据或成功。
- 每个计划完成时都必须按自身验证矩阵提供实际证据；计划文档中的预期结果不是完成证据。
