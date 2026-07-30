# Capabilities Package

## Responsibility

Capabilities 保存 Themis 十五项生命周期语义合同。每个 Capability 只判断一个明确语义问题并返回结构化 Capability Invocation Result；它不拥有全局路由、生命周期状态、持久化权威或执行权限扩张。

## Execution model

```text
Global Control Rule
→ transitions.yaml 选择一个 Capability
→ 读取该 Capability 的固定 Agent Profile
→ 创建一次性 Invocation Identity
→ 传入最小 current bindings
→ 返回结构化 Capability Invocation Result
→ 丢弃临时上下文
→ transitions.yaml 继续路由
```

- 一次 invocation 只加载一个 Capability。
- Capability 不调用其他 Capability 或 Agent。
- Capability 不选择下一 Capability；`recommended_route` 仅供人类诊断。
- Capability 不能选择或扩张 Agent Profile。
- Agent 对话、summary 和临时推理不是 lifecycle state。
- validator、recorder 或 runtime 不可用时必须报告 assurance unavailable，不能把建议写成已经执行的状态变化。

## Common result envelope

```yaml
capability: themis-*
status: <capability-legal status>
input_bindings: {}
output:
  structured_result: {}
  artifact_references: []
diagnostics:
  gaps: []
  evidence: []
  affected_semantics: []
recommended_route: <advisory only>
```

每个合同分别声明 stable identity、固定 Agent Profile、合法 `selected_path/profile`、输入与 current bindings、合法状态、payload、evidence、工具与写入边界以及停止条件。

## Discovery boundary

本目录不是 Claude Code project Skill 注册目录：

- 不使用 Skill frontmatter；
- 不提供 slash-command 或 `user-invocable` 入口；
- 只有 `.claude/skills/themis/SKILL.md` 是公共入口。

## Owned capabilities

- `questioning.md` — `themis-q`
- `grounding.md` — `themis-grounding`
- `complexity-assessment.md` — `themis-complexity-assessment`
- `simple-planning.md` — `themis-simple-plan`
- `specification.md` — `themis-spec`
- `planning.md` — `themis-planning`
- `plan-check.md` — `themis-plan-check`
- `review-projection.md` — `themis-review-projection`
- `review-check.md` — `themis-review-check`
- `review-dialogue.md` — `themis-review-dialogue`
- `implementation.md` — `themis-impl`
- `verification.md` — `themis-verification`
- `acceptance-dialogue.md` — `themis-acceptance-dialogue`
- `failure-learning.md` — `themis-failure-learning`
- `summary.md` — `themis-summary`
