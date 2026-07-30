# Templates Package

## Responsibility

Templates 为 Prompt-level 语义工件、只读 Human projection、治理记录和证据记录提供初始结构。它们减少格式漂移，但不创建事实、计算 digest、证明 currentness 或形成 machine approval。

## Owned assets

- `questioning.md`：每个 lifecycle 的 append-only 追问轮次结构。
- `plan.md`：简单与完整路径共用的唯一 Plan 结构。
- `review.md`：从 checked Plan 生成的精简只读投影。
- `review-approval.md`：批准对象与输入 binding 的独立治理记录。
- `impl-result.md`、`verification.md`：实际变更与独立验证证据结构。
- `acceptance.md`、`summary.md`：人工验收与最终交付摘要结构。
- `failure-learning.md`：非阻塞经验候选结构。
- `context-resolution.md`、`context-summary.md`：Context 选择与候选说明。

## Boundaries

- template 是起点，不是 current artifact、approval、evidence 或 validator output。
- 只有控制面实际提供的 revision/digest 才能写入 binding 字段；不得由 Agent 发明。
- `review.md` 不反向修改 Plan，Approval 不写回 Plan 或 Review。
- 临时 Specification handoff 不持久化，不存在 `spec.yaml` 或 `spec.md` 模板。
- 不嵌入项目事实、默认 Gate、功能版本、upgrade、migration 或 Shell fallback。

## Current status

Plan 35 provides human-readable structures. Strict Schema, canonical rendering, currentness, Capability Invocation Result vectors, and write-safety fixtures belong to Plan 36; policy evaluation, per-lifecycle recording, atomic single-file replacement, completion markers, and reread verification belong to Plan 37. Neither plan owns general transactions, locks, rollback journals, or automatic recovery.
