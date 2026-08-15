# design-decision semantic-check

## 用途

本清单供 Agent 在 `prepare` 操作前，以独立于原提出者的身份对一份 `design_decision` 候选做语义复核，产出 `assessment.json`。本清单产出的是 assessment candidate（Agent 的独立语义判断），不授予 publication authority——发布仍需 `publish` 操作与独立的 Human Approval。

## 复核要点

- `core_conclusion` 是否准确概括了"决策"章节的结论，二者不矛盾。
- `决策` 章节陈述的是已经做出的决定，而不是仍在讨论中的选项。
- `约束` 与 `备选方案` 是否清楚区分：约束是决策必须遵守的边界，备选方案是曾经比较过但未采用的其他选择。
- `后果` 是否如实反映正负两方面影响，没有回避已知的负面后果。
- `重新评估条件` 是否具体、可核对，而不是空泛的"情况变化时"。
- L2 payload 各字段与 L3 对应章节内容是否一致，没有 L2 概括了 L3 未提及的内容，也没有 L3 提及但 L2 遗漏的关键点。
- 材料是否确实符合 `design_decision` 的适用分类依据（见 `factory.md`），而不是应当归入 `development_standard` 或 `development_experience`。

复核结论只写入 `assessment.json` 的 `status`（`pass` 或 `fail`）与 `notes`；`checker_identity` 必须与候选的 `proposed_by` 不同。
