# inspect

## 输入与前置条件

- `--request <inspect.json>`：`record_ids`（必填、非空的确切 record ID 数组，通常来自此前一次 `query` 的结果）、`depth`（1、2 或 3）、`content_budget_bytes`（必填，1 到 16 MiB）。
- 前置条件：`record_ids` 中每一个 ID 都必须存在于当前 manifest；本操作不支持按标题、摘要或标签模糊定位记录。

## Agent 职责

- 只在已经通过 `query`（或其他已知渠道）获得确切 `record_id` 之后调用本操作；不得凭猜测或标题匹配调用。
- 按实际需要选择 `depth`：只需判断相关性时用 1，需要规划信息时用 2，需要完整正文时才用 3，避免不必要地消耗预算。
- 读取已固化的 `knowledge_type` 后，按 `common/type-registry` 的 identity routing table 路由到唯一 type factory 做进一步解释；不得据标题、摘要或正文重新猜测类型。

## 对应 CLI command

```text
themico inspect --root <root> --request <inspect.json>
```

## Human gate

无。

## 权威输出

`output` 为一个 `query.InspectResult`：`generation`、`items`（每条含 L1，`depth >= 2` 时含 L2，`depth >= 3` 时含 L3 正文）。`trace` 字段（envelope 顶层）记录本次读取涉及的 ID 集合与字节预算事实。

## 合法 machine statuses

`succeeded`、`usage_error`、`validation_failed`（`record_ids` 缺失、`depth` 不在 1~3、`content_budget_bytes` 超出范围）、`not_found`（任一 `record_id` 不在当前 manifest 中）、`budget_exceeded`、`internal_error`。

## fail-closed 行为

`record_ids` 中只要有一个不存在于当前 manifest，整批请求即返回 `not_found`，不返回其余可读记录；超出 `content_budget_bytes` 时整体返回 `budget_exceeded`，`items` 为空数组，不做部分返回或截断。
