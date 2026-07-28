# Specification Package

## Responsibility

Specification 把用户目标转为可审阅、可批准、可追踪的需求语义。它负责 Spec 前追问和轻松 Spec Review，不拥有实现设计或 Task ordering。

## Owned assets

- `rules.md`：当前 Specification 边界。
- `../../policies/specification.yaml`：复杂度、追问、对抗检查和 readiness 策略输入。
- `../../templates/spec.yaml`：Spec 语义源模板。
- `../../protocols/artifact/spec-schema.yaml` 与 `spec-projection.yaml`：待 Plan 36 收敛的结构和投影合同输入。
- 外部 `Themis-Q` Skill：只提供提问方法，不拥有流程、持久化或 handoff。

## Semantic artifacts

```text
workspace/specs/<spec-id>/spec.yaml  # 唯一语义权威
workspace/specs/<spec-id>/spec.md    # Human projection
```

候选、批准和 currentness records 的最终结构由 Plans 35/36 确认。Markdown 不得反向解析为 YAML 或 machine evidence。

## Prompt flow and handoff

1. 读取受治理 Context 与相关当前代码/配置/Schema。
2. 需要澄清时调用 `Themis-Q` 方法，记录问题、假设和未决项。
3. 向用户展示 normalized summary；明确确认后创建或修订 `spec.yaml`。
4. 从语义源生成 reviewable `spec.md`，但在 runtime 缺失时不声称 byte-identical projection。
5. 用户审阅 current projection；反馈只修改语义源并使旧批准失效。
6. current semantic revision 获得明确批准后 handoff 到 Planning。

## Assurance boundary

Prompt 可以记录明确人工决定，但不能伪造 schema validation、digest、Git OID、currentness 或 lifecycle transition。Plans 36/37 分别定义并实现这些 assurance。

## Safe degradation

`Themis-Q`、必要 Context 或工具缺失时保持 Specification 并报告 blocker。投影器缺失时可生成标明 assurance `unavailable` 的 review copy，但不得称为 canonical publisher output。

## Workspace interaction

只写当前 Spec artifact area 和声明的 candidate/decision records；不修改 Core、Plan、代码或 lifecycle state。

## Non-ownership

不拥有 Plan decomposition、pre-Implementation Review、Implementation、Verification、Human Acceptance 或 Summary。

## Current status

rules、policy、template 和协议草案存在；旧 Shell publisher 已移除。当前没有 deterministic validator/projector、批准 currentness、transition recorder 或可执行 Spec regression suite。Plan 35 将实现 Prompt flow，Plan 36 固定 machine contracts，Plan 37 实现 runtime。
