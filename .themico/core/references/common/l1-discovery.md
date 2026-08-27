# l1-discovery

## L1 只用于发现与确定性筛选

`themico query` 只返回匹配记录的 L1 投影（`record_id`、`record_revision`、`zone`、`knowledge_type`、`status`、`l1`），绝不携带 L2 或 L3 内容。L1 的作用是让 Agent 在不读取完整正文的前提下，先做确定性的发现与筛选：按 `zones`（必填）、`types`、`statuses`、`project`、`domains_any`、`architecture_units_any`、`features_any`、`tags_any`、`triggers_any` 过滤，并受 `content_budget_bytes`（必填，1 到 16 MiB）约束。

`query` 的过滤是完全确定性的机器操作；`trace` 字段记录可重放的过滤、选择、排除与预算事实。任何相关性判断、优先级排序或语义解释都是 Agent 在收到 L1 结果后自行完成的非权威工作，不是 CLI 返回的机器事实。

## 升级读取需要 exact record ID

要读取某条记录的 L2 或 L3，必须先从 `query`（或已知渠道）获得该记录的 exact `record_id`，再调用 `themico inspect` 并指定 `depth`（1、2 或 3）逐条升级读取。`inspect` 不支持按标题、摘要或标签模糊定位记录；`record_ids` 必须是已经确定的具体 ID 列表。

`inspect` 与 `query` 共享同一个 `content_budget_bytes` 约束和 fail-closed 语义：整批请求若超出预算会以 `budget_exceeded` 整体失败，不返回部分条目。

## 本次交付不支持的读取能力

以下能力当前不可用，Agent 不得声称或尝试使用：

- 历史版本查询（history query）；
- 跨类型的关系遍历、多跳查询（relation traversal）；
- 跨 Zone 的查询扩展；
- 基于内容相关性的排序（Agent relevance ranking 仅是 Agent 自身的非权威解释，不是 CLI 提供的排序）；
- 聚合 view 或索引（`views.json` 当前固定为空对象，不是可查询的聚合索引）。
