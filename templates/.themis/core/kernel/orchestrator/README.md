# Orchestrator Package

## Responsibility

Orchestrator 根据持久 Workspace 工件和实际观察选择下一个领域，不拥有任何领域的语义工作。它保证四项产品特点形成一条可恢复主链，而不是依赖对话记忆。

## Owned assets

- `rules.md`：权威顺序、managed-change detection、领域路由与 non-bypass rules。

## Inputs and outputs

输入包括 Workspace manifest、Context、Spec/Plan、Review、task ledger、runs、evidence、Acceptance 和 Knowledge records。输出只是明确的下一领域、阻塞原因和所需 handoff；Orchestrator 不写领域内容或 machine state。

## Prompt flow and handoff

1. 读取当前持久工件和有效 policy。
2. 区分 intended project facts、current implementation facts 和 lifecycle evidence。
3. 若事实冲突，保留双方并路由到拥有者裁决。
4. 选择 Context、Specification、Planning、Review、Implementation、Verification、Delivery 或 Knowledge。
5. 通过声明的 Workspace artifact handoff，不通过 sibling rule imports 传递领域语义。

## Assurance boundary

Orchestrator 不执行 validator、transition、Gate、transaction 或 recovery。未来 runtime 的结构化结果可以作为路由输入，但不能替代语义判断。

## Safe degradation

能力或工件缺失时停在当前 stage，报告 `unavailable`/`pending`，不得手写 machine state、虚构 evidence 或跳过固定门禁。

## Workspace interaction

只读取声明路径并把写入交给 owning domain。正常项目工作不得修改 Core。

## Non-ownership

不拥有 questioning、Plan decomposition、Review verdict、Implementation choice、Verification verdict、Human Acceptance、Knowledge value judgment 或 Attribution。Multi-Agent 只能改变执行拓扑。

## Current status

`rules.md` 存在，但仍需 Plan 35 完成 Prompt-first routing、加入 Implementation/Delivery imports 并移除 Attribution baseline import。没有 lifecycle runtime 或已观察的端到端执行证据。
