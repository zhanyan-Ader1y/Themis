# Planning Package

## Responsibility

Planning 把 approved Spec 转为可持久化、可恢复、AC-traced 的 bounded Task DAG，使 Agent 自主规划结果成为项目工件而不是对话残留。

## Owned assets

- `rules.md`：当前 Planning 职责与边界。
- 未来 `plan.yaml`、`plan.md`、Task/cursor protocols 和 templates。

## Semantic artifacts

```text
workspace/specs/<spec-id>/plan.yaml  # 语义权威
workspace/specs/<spec-id>/plan.md    # Human projection
```

Plan 至少保存 stable Task IDs、dependencies、AC coverage、scope、done conditions、evidence requirements、risks、rollback 和 resume cursor。

## Prompt flow and handoff

1. 读取 current approved Spec、相关 Context 和当前代码位置。
2. 将行为变化分解为 dependency-ready Tasks。
3. 为每项 Task 绑定 AC、允许范围、证据和完成条件。
4. 生成可审阅 projection，记录 unresolved design/risk。
5. current Plan 完成后 handoff 到 Review；Plan 不足时接收 Implementation repair handoff。

## Assurance boundary

Prompt 负责 decomposition judgment；未来 assurance 只校验 DAG、traceability、scope、currentness 和 cursor，不决定最佳计划。

## Safe degradation

Spec 未批准、事实冲突或必要证据无法定义时保持 Planning。runtime 缺失时标明 validation/currentness `unavailable`，不得声称 machine-approved Plan。

## Workspace interaction

只写关联 Spec artifact area 和声明的 planning records；不修改 Spec semantics、project code 或 Verification evidence。

## Non-ownership

不批准需求、不授权 Implementation、不执行 Task、不计算 Verification verdict。

## Current status

当前只有 `rules.md`，且含旧 executor 假设待 Plan 35 修订。`plan.yaml`/`plan.md` 合同、Task DAG、cursor、validator 和 tests 尚未实现。
