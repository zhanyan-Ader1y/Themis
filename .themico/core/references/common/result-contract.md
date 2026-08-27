# result-contract

## envelope 形状

`themico` CLI 的每一次调用，stdout 恒为且仅为一个 JSON result envelope，字段固定为：

| 字段 | 说明 |
| --- | --- |
| `schema` | envelope 的固定 schema 标识。 |
| `command` | 本次实际执行的命令名（例如 `candidate create`、`validate`、`prepare publish`）。 |
| `status` | 闭集 machine status，见下表。 |
| `operation_id` | 本次 Invocation 的操作标识；`help` 命令固定为空字符串，其余命令每次调用生成新值。 |
| `output` | 成功或部分结论时携带的权威输出（例如 `model.CandidateRevision`、`validate.Report`、`model.Prepare`、`model.RecordRevision`、`query.Result`、`query.InspectResult`）；不是所有 status 都携带 `output`。 |
| `issues` | 结构化问题数组，字段为 `code`、`path`、`message`；没有问题时为空数组，绝不是 `null`。 |
| `trace` | 仅 `query`、`inspect` 携带：可重放的过滤、选择、读取与预算事实；不是 Agent 的语义解释。 |

## 闭集 status

`status` 只能是以下十二个取值之一，Agent 不得假设或声称闭集之外的状态：

- `succeeded`
- `usage_error`
- `validation_failed`
- `not_found`
- `precondition_failed`
- `conflict`
- `stale`
- `unauthorized`
- `approval_required`
- `budget_exceeded`
- `unavailable`
- `internal_error`

## 关键约定

- `validate` 命令在 `Report.OK == false` 时返回 `validation_failed`，`issues` 数组携带具体问题——这是一次正常的确定性校验结论，不是进程崩溃，Agent 不得把它当作异常处理流程对待。
- `query`、`inspect` 在超出 `content_budget_bytes` 时返回 `budget_exceeded`：整次请求 fail-closed，不会截断或部分返回结果；`output` 中的候选/条目集合为空，`trace` 仍携带完整的过滤与预算事实。
- 诊断信息不得以自由文本改变 `status`；stderr 只用于无法编码为 envelope 的进程级故障，Agent 判断结果时只读取 stdout 的 envelope。
- Agent 只能依据 `output`、`issues`、`trace` 中的字段做判断和解释，不得逆向假设 CLI 未在这些字段中给出的事实。
