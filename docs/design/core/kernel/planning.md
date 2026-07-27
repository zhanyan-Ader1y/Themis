# Planning — 计划

> 规范状态：正式设计。实现状态：已确认但未实现；当前只有领域 rules 和 Workspace 目录骨架，没有 Plan template、validator 或 lifecycle executor。

## 职责边界

Planning 将已批准 Spec 转化为有边界的 Plan、Task、依赖和 evidence 要求。它定义任务如何组织，不执行任务。

- 不修改项目源码。
- 不把 Task 标记为完成。
- 不修改 Spec 范围或伪造 lifecycle transition。
- Plan 不足但工作仍在 Spec 内时修订 Plan；工作超出 Spec 时返回 Specification。

## Plan 与 Task

Planning 创建或更新：

```text
workspace/specs/<spec-id>/plan.md
```

Plan 至少定义：

- 关联 Spec 与版本信息；
- 稳定 Task ID；
- 每个 Task 的类型、范围、覆盖 AC、依赖和完成标准；
- Task dependency DAG；
- AC → Task → code location → Gate traceability；
- 预期 evidence 和验证方式。

一个 Task 应能在一次聚焦会话中完成。每个行为变更 Task 必须覆盖至少一个 AC；纯工程 Task 必须明确标记并说明必要性。

## Plan Validation

确定性 validator 应检查：

- 所有 AC 都被 Task 覆盖；
- 依赖引用存在且 DAG 无环；
- Task 粒度与范围可执行；
- evidence 和 done condition 明确；
- 代码位置具有可验证事实锚点。

Behavior Map 可辅助定位，但缺失时回退到源码检查。校验失败只要求修订 Plan，不得自动进入 Implementation。

## Workspace 交互

```text
读取:
  workspace/specs/<spec-id>/spec.md
  workspace/specs/<spec-id>/plan.md
  workspace/context/
  相关代码事实

写入:
  workspace/specs/<spec-id>/plan.md
```

Plan 校验的 Run/Evidence 应由后续确定性执行器保存；Planning 本身不计算 Verification verdict。
