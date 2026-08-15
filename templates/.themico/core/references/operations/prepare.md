# prepare

## 输入与前置条件

- `--candidate <candidate-id>`：目标候选 ID；CLI 内部使用其当前 `candidate_revision`，不需要单独传入。
- `--assessment <assessment.json>`：`schema`（固定为 `themico/semantic-assessment`）、`candidate_id`、`candidate_revision`（必须绑定到候选当前修订）、`status`（`pass` 或 `fail`）、`checker_identity`（非空，且必须不同于候选的 `proposed_by`）、`checked_at`（RFC3339 时间）、`notes`。
- 前置条件：候选必须先通过 `validate`（`Report.OK == true`）；`assessment.status` 必须为 `pass`。

## Agent 职责

- 以独立于原提出者的身份（`checker_identity` 不同于 `proposed_by`）对候选内容做语义复核，产出 `assessment.json`；这是 Agent 的独立语义判断，不是 Human 授权，也不是发布权威。
- 复核未通过时应设置 `status: fail` 并说明理由，此时不应继续调用本操作申请冻结。

## 对应 CLI command

```text
themico prepare publish --root <root> --candidate <candidate-id> --assessment <assessment.json>
```

## Human gate

无直接 gate。本操作只冻结后续 `publish` 需要的全部输入（候选内容、语义评估、record/projection 的目标字节 digest、`expected_generation`），Human 授权发生在下一步 `publish`。

## 权威输出

`output` 为一个 `model.Prepare`：`prepare_id`、候选与评估的 digest、`expected_generation`、待分配的 `record_id`/`record_revision`、冻结写入目标（`writes`）及其 digest、`created_at`、本 prepare 自身的 `digest`。本次调用会提交一次不可变的 generation（只新增 prepare 与 assessment 制品），但不会改变任何 current 指针。

## 合法 machine statuses

`succeeded`、`usage_error`、`validation_failed`（候选未通过 `validate`、assessment 结构非法）、`not_found`、`precondition_failed`（`assessment.status` 为 `fail`、`checker_identity` 与 `proposed_by` 相同）、`conflict`、`internal_error`。

## fail-closed 行为

候选未通过确定性校验、评估未通过或评估绑定不匹配时，整体返回对应失败状态，不冻结任何 prepare 制品；即便冻结成功，也不会使候选被发布——发布仍需 `publish` 命令与独立的 Human `Approval`。
