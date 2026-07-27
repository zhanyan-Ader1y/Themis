# Planning — 计划

> 规范状态：正式设计。实现状态：已确认但未实现；当前只有领域 rules 和 Workspace 目录骨架，没有 Plan template、validator、Context Bundle 消费器或 lifecycle executor。

## 职责边界

Planning 将已批准 Spec 转化为有边界的 Plan、Task、依赖和 evidence 要求。它定义任务如何组织和证明完成，不执行任务。

- 不修改项目源码。
- 不把 Task 标记为完成。
- 不修改 Spec 范围或伪造 lifecycle transition。
- Plan 不足但工作仍在 Spec 内时修订 Plan；工作超出 Spec 时返回 Specification。
- Spec/Plan 不能自证项目事实；Planning 使用 Context 和当前代码定位任务边界。

## 输入事实

Planning 读取：

- 已验证且已批准的 `workspace/specs/<spec-id>/spec.yaml`，用于目标、范围、稳定 Requirement/AC/Contract/Invariant ID 与 validator readiness JSON；
- `spec.md` 仅用于人类展示，绝不解析其标题或正文作为 Planning 输入；
- P5.4 Context Bundle 及其引用的 L3 Context，用于项目“应当是什么”；
- 当前代码、配置和 Schema，用于项目“现在是什么”；
- 可选的 `current` Behavior Map，用于候选位置导航。

Context Bundle 为 `partial`、`conflict` 或 `unavailable` 时，不得假装事实或定位已经完整；应补充证据、请求裁决或明确记录未知区域。

## Plan 与 Task

Planning 创建或更新：

```text
workspace/specs/<spec-id>/plan.md
```

Plan 至少定义：

- 关联 Spec 及其 YAML revision；
- 稳定 Task ID；
- 每个 Task 的类型、范围、覆盖 AC、依赖和完成标准；
- Task dependency DAG；
- AC → Task → code location → Gate traceability；
- 预期 evidence、验证方式和未决区域。

一个 Task 应能在一次聚焦会话中完成。每个行为变更 Task 必须覆盖至少一个 AC；纯工程 Task 必须明确标记并说明必要性。

## Change Localization

P6 可用时，Planning 只读消费以下建议链路：

```text
AC → B2 Behavior Unit → B3 Anchor → Candidate File/Symbol → Task → Gate
```

每个候选位置记录 role、理由、Anchor ID、source revision、confidence 和 unresolved area。只有 `current` 且受支持的 B3 可以支撑候选定位，关键当前实现仍需读取代码核验。

Localization 不是实现授权，不能自动创建或完成 Task、修改代码、扩大 Plan 或把 Anchor 当成 Verification evidence。Map 缺失、过期、未知或不支持时必须回退源码检查；低置信度只扩大只读调查范围，不扩大实施范围。

## Plan Validation

确定性 validator 应检查：

- 所有 AC 都被 Task 覆盖；
- 依赖引用存在且 DAG 无环；
- Task 粒度与范围可执行；
- evidence 和 done condition 明确；
- 代码位置具有可验证事实锚点或明确的源码核验记录；
- Context 冲突、未知定位和 scope gap 没有被隐藏。

校验失败只要求修订 Plan，不得自动进入 Implementation。

## Workspace 交互

```text
读取:
  workspace/specs/<spec-id>/spec.yaml
  workspace/specs/<spec-id>/spec.md       # 仅展示，不作机器输入
  workspace/specs/<spec-id>/plan.md
  workspace/cache/resolved-context/
  workspace/context/
  workspace/context/architecture/behavior-map/  # P6 可选导航
  当前代码、配置与 Schema

写入:
  workspace/specs/<spec-id>/plan.md
```

Plan 校验的 Run/Evidence 应由后续确定性执行器保存；Planning 本身不计算 Verification verdict。
