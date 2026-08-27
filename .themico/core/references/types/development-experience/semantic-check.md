# development-experience semantic-check

## 用途

本清单供 Agent 在 `prepare` 操作前，以独立于原提出者的身份对一份 `development_experience` 候选做语义复核，产出 `assessment.json`。本清单产出的是 assessment candidate，不授予 publication authority——发布仍需 `publish` 操作与独立的 Human Approval。

## 复核要点

- `观察到的现象` 与 `已确认事实` 是否清楚区分：前者是表面症状，后者是已核实的具体事实，不应混为一谈。
- `建议行动` 是否是从 `已确认事实` 合理推出的，而不是缺乏依据的跳跃结论。
- `证据与强度` 章节是否诚实反映证据的实际强度，没有把单次观察包装成强证据。
- `风险与停止条件` 是否具体列出了采纳建议行动的风险，以及应当停止采纳的明确条件。
- `适用与不适用条件` 是否清楚界定边界，而不是笼统声称普遍适用。
- L2 payload（`symptoms`、`preconditions`、`observed_facts`、`recommended_action`、`evidence_strength`、`risks`、`stop_conditions`）与 L3 对应章节内容是否一致。
- 材料是否确实符合 `development_experience` 的适用分类依据（见 `factory.md`），而不是应当归入 `design_decision` 或 `development_standard`。

复核结论只写入 `assessment.json` 的 `status`（`pass` 或 `fail`）与 `notes`；`checker_identity` 必须与候选的 `proposed_by` 不同。
