# validate

## 输入与前置条件

- `--candidate <candidate-id>`：目标候选 ID。
- `--revision <candidate-revision>`：期望校验的确切候选修订；必须等于该候选当前的 `candidate_revision`。
- 前置条件：候选必须存在；本操作在候选尚未类型确认时也可以调用，但会在结论中报告相应问题。

## Agent 职责

- 在请求 `prepare publish` 之前调用本操作，作为确定性的发布前置门；本操作不是 Human gate，只是机器可判定的结构与绑定校验。
- 读取 `issues` 数组逐条定位问题（类型未确认、L2 payload 与类型不符、L3 章节缺失、digest 不匹配、source 过期、relation 目标缺失等），据此修订候选而非直接申诉。

## 对应 CLI command

```text
themico validate --root <root> --candidate <candidate-id> --revision <candidate-revision>
```

## Human gate

无。本操作只产出确定性机器结论，不构成也不替代任何 Human gate。

## 权威输出

`output` 为一个 `validate.Report`：`candidate_id`、`candidate_revision`、`ok`（布尔）、`issues`（结构化问题数组）。`ok == true` 且 `issues` 为空数组时才代表候选通过了本次校验。

## 合法 machine statuses

`succeeded`（`ok == true`）、`validation_failed`（`ok == false`，`issues` 携带具体问题——这是正常校验结论，不是异常）、`usage_error`、`not_found`、`internal_error`。

## fail-closed 行为

本操作从不返回“部分通过”：要么 `ok == true` 且 `issues` 为空，要么 `ok == false` 且 `issues` 携带完整问题列表；`status` 为 `internal_error` 或 `not_found` 时表示店铺不可读或候选不存在，与校验结论本身无关，此时不携带 `Report`。
