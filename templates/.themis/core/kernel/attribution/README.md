# Attribution Package

## Responsibility

Attribution 是可选 post-delivery observer，把 durable outcomes 与支持它们的 Spec、changes、runs 和 evidence 相关联，并清楚区分 measurement、correlation 和 interpretation。

## Owned assets

- `rules.md`：当前分析边界。
- 未来 metrics、privacy、retention 和 analysis protocols。

## Inputs and outputs

输入为已完成的 core lifecycle artifacts、outcomes 和可核验 evidence。输出为声明位置中的 attributable analysis、metrics 和 supporting references。

## Prompt flow and handoff

仅在 core delivery 不受阻后按显式触发运行。分析可以产生 Knowledge candidate，但不能直接 promotion，也不能改变 lifecycle state。

## Assurance boundary

runtime 可以校验输入引用和保存结构化 metrics，但不能从相关性自动断言因果。所有 interpretation 必须标注证据和限制。

## Safe degradation

缺失 evidence、privacy consent、retention policy 或能力时跳过/报告 unavailable；核心 Acceptance、Summary、Knowledge 和 Archive 继续正常进行。

## Workspace interaction

只写声明的 outcome/analysis locations，不重写 source evidence，不在 Core 保存项目数据。

## Non-ownership

不进入 baseline import graph；不拥有 Human Acceptance、Summary、Knowledge promotion、transition、archive readiness、Gate execution 或 project implementation。

## Current status

只有 `rules.md`，且旧基线 import 仍待移除。Plan 90 是可选实施计划；当前没有 analytics artifacts、automation 或 tests。
