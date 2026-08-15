# publish

## 输入与前置条件

- `--prepare <prepare-id>`：一次先前成功的 `prepare publish` 产出的 `prepare_id`。
- `--approval <approval.json>`：`schema`（固定为 `themico/approval`）、`operation`（固定为 `publish`）、`prepare_id`、`prepare_digest`（必须精确等于该 prepare 的 `digest`）、`approved_by`（非空）、`approved_at`（RFC3339 时间）、`authority_ref`（非空）。
- 前置条件：对应的 prepare 制品必须存在且未被篡改；候选自 prepare 冻结以来未发生变化（`candidate_revision` 仍一致）；候选声明的 source 文件字节未变化；store 的 generation 自 prepare 冻结以来未推进（否则视为并发写入冲突）。

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

`succeeded`、`usage_error`、`validation_failed`、`not_found`、`precondition_failed`（approval 结构/绑定非法、prepare 不存在或结构非法、候选自 prepare 后已变化）、`conflict`（source 自 prepare 后已变化、store generation 已推进）、`internal_error`。

## fail-closed 行为

任一前置条件不满足时，整个调用不产生任何写入、不改变 current 指针；成功时整批写入（record、content、projection、更新后的候选、approval 制品）在单次原子 generation commit 中一起可见，不存在部分可见的中间状态。
