# development-standard semantic-check

## 用途

本清单供 Agent 在 `prepare` 操作前，以独立于原提出者的身份对一份 `development_standard` 候选做语义复核，产出 `assessment.json`。本清单产出的是 assessment candidate，不授予 publication authority——发布仍需 `publish` 操作与独立的 Human Approval。

## 复核要点

- `触发条件` 是否具体、可判定，而不是模糊的定性描述。
- `必须执行` 与 `禁止行为` 是否互不矛盾，且都是可核查的具体动作，而不是原则性的口号。
- `验证方法` 是否真的能验证"必须执行"与"禁止行为"两个章节的内容，而不是与它们脱节。
- `例外策略` 是否清楚说明例外的触发条件和处理方式，而不是变相取消整条规范。
- L2 payload（`trigger`、`required_actions`、`prohibited_actions`、`verification`、`exception_policy`）与 L3 对应章节内容是否一致。
- 材料是否确实符合 `development_standard` 的适用分类依据（见 `factory.md`），而不是应当归入 `design_decision` 或 `development_experience`。

复核结论只写入 `assessment.json` 的 `status`（`pass` 或 `fail`）与 `notes`；`checker_identity` 必须与候选的 `proposed_by` 不同。
