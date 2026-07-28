# Delivery Package

## Responsibility

Delivery 在 current Verification `pass` 后请求 Human Acceptance，并在 `accepted` 后生成 final delivery Summary。它把“机器证据”和“用户是否接受结果”保持为两个独立决定。

## Owned assets

- 未来 `rules.md`、Acceptance record、delivery source 和 Summary template/protocol。

## Inputs and outputs

输入为 current approved Spec/Plan/Review、current Implementation revision、Verification verdict/evidence 和 acceptance criteria。输出为：

```text
accepted | rejected
```

只有 `accepted` 后才生成 `summary.md`。Summary 概括批准目标、实际变化、验证证据、限制和交付结果，不是 machine status 或通用阶段摘要。

## Prompt flow and handoff

1. 确认 current Verification 为 `pass` 且绑定当前实现。
2. 向用户展示验收范围、证据和限制。
3. 持久化明确 `accepted` 或 `rejected`。
4. rejection 路由到 Specification、Planning 或 Implementation；实现变化后重新 Verification。
5. accepted 后从 current delivery source 生成 Summary，并 handoff Knowledge/Archive。

## Assurance boundary

Human Acceptance 是人工决定，runtime 不能代替。未来 assurance 只校验 ordering、binding、currentness 和 Summary projection。

## Safe degradation

Verification 非 `pass`、evidence 不完整或 binding 不可确认时不得请求/记录 accepted。Summary capability 缺失时保持待交付，不能手写后声称 machine-generated current projection。

## Workspace interaction

Acceptance、Summary 和 delivery records 只写关联 artifact/outcome paths；不修改 implementation 或 Verification evidence。

## Non-ownership

不运行 Gates、不判断代码质量、不 promotion Knowledge。Attribution analytics 不是 Acceptance、Summary 或 Archive gate。

## Current status

该 package 当前只有目录，无 `rules.md`、Acceptance/Summary schema、Prompt、runtime 或 tests。Plan 35 将建立语义流程，Plans 36/37 补充 assurance 与实现。
