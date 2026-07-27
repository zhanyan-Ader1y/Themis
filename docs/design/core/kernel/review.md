# Review — 评审

> 规范状态：正式设计。实现状态：已确认但未实现；当前只有前置 Review 领域 rules，没有 Review template、policy、结构化 evidence 或结果执行器。

## 职责边界

Review 在 Implementation 之前只读检查 Spec、Plan、Context/源码依据、设计、风险、实施边界、回滚与验收方案。它形成是否授权实施的结构化判断，不修改项目实现、不执行 Verification Gate，也不记录 lifecycle transition。

Review 不等于实现后的代码检查。实现后的静态分析、测试、质量检查和缺陷复现属于 Verification Gate 或另行命名的检查能力。

## 输入

Review 至少读取：

- 已验证且已批准的 `spec.yaml`；
- current `spec.md`，仅供人类导向审阅；
- `plan.md`、Task DAG、AC traceability 与预期 evidence；
- 采用的 Context ID、当前源码/配置/Schema 引用及其 revision/digest；
- 设计图、关键决策、风险、回滚、实施 scope lock 与人工验收步骤。

Review 不以 implementation diff、已完成代码或 Verification evidence 作为前置输入。

## 评审合同

评审至少覆盖：

- 需求、范围和 AC 是否完整且一致；
- 方案、接口、状态转换、安全与数据完整性是否可实施；
- Plan/Task DAG、定位、依赖和范围锁定是否充分；
- 风险、回滚和失败边界是否明确；
- AC → Task → Gate → 人工验收的证据链是否可执行；
- Context、源码依据和未知区域是否被如实记录。

每个 finding 记录稳定 ID、具体 artifact/Context/代码引用、failure scenario、严重级别、修正要求或 disposition。严重级别为：

```text
critical | major | minor | suggestion
```

Review result 只使用：

```text
approved | changes_requested | blocked
```

- 未解决的 `critical` 或 `major` finding 阻止 `approved`。
- Spec/Plan/设计或验收证据缺失、冲突或无法核验时返回 `blocked`。
- `changes_requested` 返回 Specification 或 Planning，取决于问题属于需求范围还是实施设计。
- 只有绑定 current Spec/Plan revision 的 `approved` 才能授权 Implementation；相关工件变化后旧批准失效。
- Context 冲突或源码依据无法核验时不得以 reviewer confidence 代替事实。

未来若允许 major waiver，必须先定义独立、持久、可审计的 disposition 合同。

## Human Review 投影

Review 的机器权威是 versioned、结构化 Review evidence；`review.md` 由确定性 renderer 生成，只供人类审阅，不能被解析为最终 result 或反向覆盖 evidence。

`review.md` 首屏展示：

- 最终 result 与 blockers；
- 未解决的 `critical` / `major` findings；
- Spec/Plan/设计 revision；
- evidence gaps 与必须完成的修订；
- 关键 Context ID、源码引用和验收方案。

完整 findings、failure scenario、严重级别、引用和 disposition 保留在后续章节。P6.8 的 Protocol、policy、Prompt、lint/publish/render executor 和投影尚未实现。

## Workspace 交互

目标合同：

```text
读取:
  workspace/specs/<spec-id>/spec.yaml
  workspace/specs/<spec-id>/spec.md       # current 投影，仅供人类审阅
  workspace/specs/<spec-id>/plan.md
  workspace/context/
  当前代码、配置与 Schema

写入:
  workspace/evidence/review/
  workspace/specs/<spec-id>/review.md     # Human projection
```

只有 current Review evidence 的 result 为 `approved` 时，未来 lifecycle executor 才能记录 `reviewed` 并允许 Implementation。
