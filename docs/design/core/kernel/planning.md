# Planning — 计划

> 规范状态：正式设计。实现状态：已确认但未实现；当前只有领域 rules 和 Workspace 目录骨架，没有 Plan template、validator、Context Bundle 消费器或 lifecycle executor。

## 职责边界

Planning 将已批准 Spec 转化为有边界的 Plan、Task、依赖和 evidence 要求。它定义任务如何组织和证明完成，不执行任务，也不授权 Implementation；授权由后续 Review 负责。

- 不修改项目源码或把 Task 标记为完成。
- 不修改 Spec 范围或伪造 lifecycle transition。
- Plan 不足但工作仍在 Spec 内时修订 Plan；工作超出 Spec 时返回 Specification。
- Spec/Plan 不能自证项目事实；Planning 使用 Context 与当前代码定位任务边界。

## 输入事实

Planning 读取：

- 已验证且已批准的 `spec.yaml` 与 validator readiness JSON；
- current `spec.md`，仅供人类展示；
- P5.4 Context Bundle 及其引用的 L3 Context，用于项目“应当是什么”；
- 当前代码、配置和 Schema，用于项目“现在是什么”。

代码定位必须直接核验当前源码并记录 path、symbol/region、revision/digest 和 unresolved area。Context Bundle 为 `partial`、`conflict` 或 `unavailable` 时，不得假装事实或定位完整。

## Plan 与 Task

Planning 创建或更新：

```text
workspace/specs/<spec-id>/plan.md
```

Plan 至少定义：

- 关联 Spec 及其 YAML revision；
- 稳定 Task ID、类型、范围、覆盖 AC、依赖和完成标准；
- Task dependency DAG；
- AC → Task → code location → Gate → human acceptance traceability；
- 预期 evidence、验证方式、回滚与未决区域；
- Review 所需的设计图、关键决策、风险与 scope lock。

一个 Task 应能在一次聚焦会话中完成。每个行为变更 Task 必须覆盖至少一个 AC；纯工程 Task 必须明确标记并说明必要性。

## Plan Validation

确定性 validator 应检查：

- 所有 AC 都被 Task 覆盖；
- 依赖引用存在且 DAG 无环；
- Task 粒度与范围可执行；
- evidence、done condition 和 acceptance step 明确；
- 代码位置具有直接源码核验记录；
- Context 冲突、未知定位和 scope gap 没有被隐藏；
- Review 输入充分且 Plan 变化可使旧 Review approval 失效。

校验失败只要求修订 Plan，不得自动进入 Review 或 Implementation。

## Workspace 交互

```text
读取:
  workspace/specs/<spec-id>/spec.yaml
  workspace/specs/<spec-id>/spec.md       # 仅展示，不作机器输入
  workspace/specs/<spec-id>/plan.md
  workspace/cache/resolved-context/
  workspace/context/
  当前代码、配置与 Schema

写入:
  workspace/specs/<spec-id>/plan.md
```

Plan 校验的 Run/Evidence 应由后续确定性执行器保存；Planning 不计算 Review result 或 Verification verdict。
