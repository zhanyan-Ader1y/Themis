# confirm-type

## 输入与前置条件

- `--confirmation <confirmation.json>`：`schema`（固定为 `themico-type-confirmation`）、`candidate_id`、`candidate_revision`（必须精确等于候选当前的 `candidate_revision`）、`knowledge_type`、`confirmed_by`（非空）、`confirmed_at`（RFC3339 时间）、`authority_ref`（非空）。
- 前置条件：候选必须存在且状态恰为 `proposed`；`knowledge_type` 必须与候选的 `zone` 兼容（符合 `common/type-registry` 的 identity routing table）。

## Agent 职责

- 向 Human 呈现候选已提出的 `proposed_type` 与 `classification_rationale`，供 Human 判断是否确认；Agent 不得代替 Human 填写 `confirmed_by`、`authority_ref`。
- 确认前用 `candidate inspect` 核对 `candidate_revision`，避免绑定到已过期的候选修订。

## 对应 CLI command

```text
themico candidate confirm-type --root <root> --confirmation <confirmation.json>
```

## Human gate

这是治理链上第一个 Human gate——类型确认。`confirmed_by`、`authority_ref` 必须来自 Human，CLI 只校验结构与绑定，不核验签署人真实身份。确认后 `knowledge_type` 固化，不得原地改型（详见 `common/governance`）。

## 权威输出

`output` 为新的 `model.CandidateRevision`：`status` 变为 `type_confirmed`，`knowledge_type` 被固化为确认值，`candidate_revision` 是新分配的修订 ID。

## 合法 machine statuses

`succeeded`、`usage_error`、`validation_failed`（confirmation 字段缺失、`confirmed_at` 非法时间、类型与 Zone 不兼容）、`not_found`、`conflict`（`candidate_id`/`candidate_revision` 绑定过期、候选已不处于 `proposed` 状态）、`internal_error`。

## fail-closed 行为

绑定的 `candidate_revision` 与当前不一致，或候选已不在 `proposed` 状态时，整体返回 `conflict`，不修改候选状态；`knowledge_type` 与 `zone` 不兼容时返回 `validation_failed`，同样不产生任何写入。
