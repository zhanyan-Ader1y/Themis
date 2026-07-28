# Review Package

## Responsibility

Review 在 Implementation 前评估 current Spec、Plan、设计、风险、scope、rollback 和 acceptance approach。它让 Spec/Plan 审阅聚焦可执行决策，并独占实现授权。

## Owned assets

- `rules.md`：只读 Review 边界。
- 未来 Review result schema、finding protocol 和 projection。

## Inputs and outputs

输入为 current approved Spec、current Plan、相关 Context/代码证据和声明的 limitations。输出为：

```text
approved | changes_requested | blocked
```

每个 finding 应有 stable ID、severity、具体引用、failure scenario 和 disposition/correction target。只有 current `approved` 授权 Implementation。

## Prompt flow and handoff

1. 确认审阅对象和 revision basis。
2. 审查 AC coverage、设计一致性、scope、风险、rollback 和验证/验收方案。
3. 保存 findings 与 verdict。
4. `changes_requested` 返回 Planning 或 Specification；`blocked` 保持 Review；`approved` handoff 到 Implementation。

## Assurance boundary

Review judgment 属于人工/Agent 语义。未来 runtime 只校验 Review binding、currentness 和 authorization，不代替 reviewer 判断。

## Safe degradation

必要 artifact、current projection 或证据缺失时只能 `blocked`，不能将缺失默认为批准。没有 deterministic binding 时明确 assurance `unavailable`。

## Workspace interaction

只写关联 Spec artifact area 的 Review record；不得修改 Spec、Plan、Context 或 project code。

## Non-ownership

不实现代码、不运行 post-Implementation Gates、不作 Human Acceptance 或 Summary。

## Current status

`rules.md` 存在；Review artifact、Prompt procedure、binding/currentness validator 和 executable tests 尚未实现。
