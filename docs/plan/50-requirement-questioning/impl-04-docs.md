# P5 子模块：文档与发布同步

## 覆盖内容

- 更新 `docs/core/kernel/specification.md`
- 更新 `docs/core/policies.md`
- 更新 `docs/core/templates.md`
- 更新 `docs/workflow.md`
- 更新 `docs/plan/README.md`、P5 README 与 `CHANGES.md`
- 协调 `templates/.themis/VERSION` 和 `core/core.yaml` 的 Core 发布版本
- 更新版本敏感的 Upgrade 测试预期

## WIKI 同步原则

Specification WIKI 说明 Step 0–4、复杂度自适应、Draft Spec、攻击验证和人工批准。它必须准确区分：

- P5 已落地的模板、声明式策略、Prompt 和结构契约；
- P8 尚未落地的确定性状态评估和 `workspace/state/transitions/` 记录。

Policies WIKI 使用 `draft_to_specified` keyed mapping 展示一个完整 transition contract，不把 sequence 和 `forbidden` map 混为无效 YAML。Templates WIKI 登记新的真实 `spec.md` 模板及两个 P5 Prompt 资源。

Workflow 的 Specification 子图更新为 Step 0–4 和对抗验证，但状态迁移节点必须标为 P8 未来执行器。P5 在能力表中更新为已落地的需求追问与 Draft 审批证据契约。

## 版本发布

P5 是受管 Core 内容的新增能力，发布时将 Bundle 与 Core 一并提升为 `0.2.0`。它不改变 `workspace_schema` 或 `artifact_schema`，因此不要求迁移。Upgrade 测试使用更高的临时候选版本验证受管内容替换，同时持续验证 Workspace 与项目指引不变。

## 验证

- WIKI 中的流程、policy 字段、模板路径、P8 边界与安装模板一致。
- `VERSION` 和 `core.yaml` 的 `core_version` 一致。
- Init 和 Upgrade 测试在版本提升后仍通过。
- `CHANGES.md` 仅声明已验证、实际交付的 P5 能力，不将 P8 执行器误记为已完成。
