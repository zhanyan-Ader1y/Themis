# revise-candidate

## 输入与前置条件

- `--input <revision.json>`：`candidate_id`、`expected_revision`（必须等于该候选当前的 `candidate_revision`，否则整体失败）、`proposed_type`、`l1`、`l2`、`source_paths`、`relations`、`revised_by`（必须非空）。
- `--content <content.md>`：新的 L3 正文，非空且不超过 4 MiB。
- 前置条件：候选必须存在且状态为 `proposed` 或 `type_confirmed`；若候选已处于 `type_confirmed`，`proposed_type` 必须与已固化的 `knowledge_type` 完全一致——类型固化后不得原地改型。

## Agent 职责

- 调用本操作前先用 `candidate inspect` 读取候选当前状态，取得准确的 `expected_revision`，避免基于过期版本发起修订。
- 修订内容时遵循与 create-candidate 相同的 factory 合同（`l2.md`、`l3.md`）；若候选已类型确认，不得尝试改变 `proposed_type`。
- 本步骤仍只产出 proposal；不改变候选的 Human gate 状态（`type_confirmed` 候选修订后仍保持 `type_confirmed`，不需要重新确认）。

## 对应 CLI command

```text
themico candidate revise --root <root> --input <revision.json> --content <content.md>
```

## Human gate

无直接 gate。若候选尚未类型确认，仍需后续 `confirm-type` 完成第一个 Human gate；若已类型确认，本操作不重新触发该 gate。

## 权威输出

`output` 为新的 `model.CandidateRevision`：`candidate_id` 不变，`candidate_revision` 是新分配的修订 ID，`status` 保持修订前的状态不变。

## 合法 machine statuses

`succeeded`、`usage_error`、`validation_failed`（类型确认后尝试改型、内容为空或超限等）、`not_found`、`conflict`（`expected_revision` 与当前不一致，即并发修订冲突）、`internal_error`。

## fail-closed 行为

`expected_revision` 过期时整体返回 `conflict`，不写入任何新修订；候选状态不允许修订（例如已 `published` 或 `abandoned`）时返回 `validation_failed`；类型确认后修改 `proposed_type` 同样返回 `validation_failed`，候选内容保持修订前状态不变。
