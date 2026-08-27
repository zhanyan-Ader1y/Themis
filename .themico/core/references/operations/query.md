# query

## 输入与前置条件

- `--request <query.json>`：`zones`（必填、非空数组）、`types`（可选，空表示所有已注册类型）、`statuses`（可选，空表示只匹配 `active`）、`project`（可选精确匹配）、`domains_any`/`architecture_units_any`/`features_any`/`tags_any`/`triggers_any`（可选，任一命中即匹配）、`content_budget_bytes`（必填，1 到 16 MiB）。
- 前置条件：仓库已初始化；`zones`、`types`、`statuses` 中出现的值必须属于各自闭集。

## Agent 职责

- 在读取任何记录正文前，先用本操作做确定性发现与筛选，缩小候选集合。
- 只依据 `common/l1-discovery` 描述的过滤维度组织请求；不得假设本操作支持历史查询、关系遍历、跨 Zone 扩展或按相关性排序——这些能力当前不可用。
- 收到 `candidates` 后，若需要判断哪些记录与当前任务相关，这属于 Agent 自身的非权威解释，不是 CLI 返回的机器事实。

## 对应 CLI command

```text
themico query --root <root> --request <query.json>
```

## Human gate

无。

## 权威输出

`output` 为一个 `query.Result`：`generation`、`candidates`（每条只含 L1 投影：`record_id`、`record_revision`、`zone`、`knowledge_type`、`status`、`l1`）。`trace` 字段（envelope 顶层）记录 `observed_generation`、`searched_zones`、`candidate_ids`、`selected_ids`、`excluded_ids`、`content_bytes`、`remaining_bytes` 等可重放事实。

## 合法 machine statuses

`succeeded`、`usage_error`、`validation_failed`（`zones` 缺失、枚举值非法、`content_budget_bytes` 超出 1~16 MiB 范围，或已选中记录的投影绑定校验失败）、`not_found`（`.themico/workspace/` 尚不存在）、`budget_exceeded`、`internal_error`。

## fail-closed 行为

当全部匹配记录的编码字节总和超出 `content_budget_bytes` 时，整体返回 `budget_exceeded`：`candidates` 为空数组，`trace` 仍完整记录本应匹配和被排除的记录 ID，不做任何截断或部分返回。
