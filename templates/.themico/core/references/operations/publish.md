# publish

## 输入与前置条件

- `--prepare <prepare-id>`：一次先前成功的 `prepare publish` 产出的 `prepare_id`。
- `--approval <approval.json>`：`schema`（固定为 `themico/approval`）、`operation`（固定为 `publish`）、`prepare_id`、`prepare_digest`（必须精确等于该 prepare 的 `digest`）、`approved_by`（非空）、`approved_at`（RFC3339 时间）、`authority_ref`（非空）。
- 前置条件：对应的 prepare 制品必须存在且未被篡改；候选自 prepare 冻结以来未发生变化（`candidate_revision` 仍一致）；候选声明的 source 文件字节未变化；store 的 generation 自 prepare 冻结以来未推进——只有 generation 推进才算并发写入冲突，source 字节变化本身属于内容不再成立，见下方“合法 machine statuses”的分类边界。

## Agent 职责

- 组装 `approval.json` 供 Human 签署，但不得代替 Human 填写 `approved_by`、`authority_ref`，也不得自我批准。
- 调用前确认对应 `prepare` 仍然是最新的（source 与候选均未被后续操作改变），避免提交一次已知会失败的发布请求。

## 对应 CLI command

```text
themico publish --root <root> --prepare <prepare-id> --approval <approval.json>
```

## Human gate

这是治理链上第二个、也是最后一个 Human gate——发布授权。`approved_by`、`authority_ref` 必须来自 Human，与类型确认 gate 相互独立，互不替代。

## 权威输出

`output` 为一个新的 `model.RecordRevision`：正式 Knowledge Record，状态为 `active`，携带 `record_id`、`record_revision`、`knowledge_type`、`zone`、`generation` 等字段。发布同一次 commit 中还会把候选状态更新为 `published` 并绑定 `published_record_id`。

## 合法 machine statuses

分类边界是：approval/prepare 自身的**结构或格式**非法归为 `validation_failed`；approval 与 prepare 的**绑定或授权语义**不符归为 `precondition_failed`；只有 store 的 generation **在 prepare 冻结之后已经推进**才归为 `conflict`。

- `succeeded`
- `usage_error`
- `validation_failed`：`approval.schema` 不是 `themico/approval`、`approved_at` 不是合法 RFC3339 时间；prepare 制品无法读取、不是规范 JSON、`prepare_id` 与内容不一致或摘要不匹配；候选声明的 source 文件当前**不可读**或**字节已经变化**（source 漂移属于内容结构不再成立，不是并发冲突）。
- `not_found`：`.themico/workspace/` 尚不存在。
- `precondition_failed`：`approval.operation` 或 `prepare.operation` 不是 `publish`、approval 未绑定到该 prepare（`prepare_id`/`prepare_digest` 不匹配）、`approved_by`/`authority_ref` 为空；prepare 制品不存在；候选自 prepare 冻结后已经推进（`candidate_revision` 不再一致）；即将提交的字节与 prepare 冻结时的摘要不一致。
- `conflict`：store 的 generation 自 prepare 冻结以来已经推进（超出了 prepare 冻结的 `expected_generation`），说明另一次提交已经抢先发生。
- `internal_error`

## fail-closed 行为

任一前置条件不满足时，整个调用不产生任何写入、不改变 current 指针；成功时整批写入（record、content、projection、更新后的候选、approval 制品）在单次原子 generation commit 中一起可见，不存在部分可见的中间状态。source 字节漂移会使调用整体失败（`validation_failed`），而不是被当作可重试的并发冲突；只有 generation 真正被别的提交抢先推进时才是 `conflict`。
