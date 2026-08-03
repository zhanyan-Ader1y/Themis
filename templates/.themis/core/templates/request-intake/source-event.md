# Request Intake Source Event 记录模板

> 本文件是活动 Prompt-level Markdown 结构模板，用于形成 immutable external Source Event 记录及其 Intake attachment observation。具体记录只有经适用 Policy control action 完整持久化并重读 original bytes、identity、fragment references 与 attachment bindings 后，才构成 governed Source Event authority；模板本身不执行规范化、digest 计算、持久化或 currentness 验证。

## 记录分类

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Template status | 必填 | `prompt-level-not-machine-validated` | 模板固定值 | 仅提供 Prompt-level 结构，不声称机器校验 |
| Record class | 必填 | `operational-source-event` | 模板固定值 | 本记录是操作事实，不是 semantic artifact revision |
| Authority scope | 必填 | `request-intake` | 当前 Intake | 禁止与 lifecycle 动态状态混用 |

## Source Event 记录

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Event identity | 必填 | opaque stable identity | Source Event recorder 观察 | 不可变外部事件身份 |
| Intake identity | 必填 | opaque Intake identity | attachment 决定 | 本事件所属 Intake |
| Observed at | 必填 | observed timestamp/reference | transport/host observation | 接收观察，不用于推断顺序权威 |
| Transport | 必填 | transport identity | 外部 transport metadata | 消息来源通道 |
| Actor reference | 必填 | stable actor reference | transport metadata | 外部 actor 引用 |
| Raw bytes path | 必填 | Workspace-relative immutable path | recorder result | exact original external bytes 的引用 |
| Raw bytes digest | 必填 | digest placeholder/reference | recorder result | 当前模板不计算 canonical digest |
| Raw byte length | 必填 | 非负整数 | recorder result | exact bytes 长度 |
| Normalization | 必填 | `none` | 模板固定值 | 禁止以规范化文本替代原始 bytes |

## Intake attachment 绑定

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Attachment mode | 必填 | `new-intake`、`confirmation-continuation`、`restart-unblock-continuation` | durable Intake control facts | 本事件的 attachment 类型 |
| Continuation identity | 条件必填 | opaque continuation identity；`new-intake` 时为 `none` | 已持久化 continuation | attachment 所匹配的唯一 continuation |
| Observed reason | 必填 | source-bound observation | attachment control | 说明为何该 mode 被 durable facts 唯一证明 |

`dormant-read-only` Intake 不得作为 attachment 目标。措辞相似、聊天相邻、文件存在或 Agent 推断不能代替 durable continuation。

## 物化观察

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Operation identity | 必填 | opaque operation identity | control action | 本次记录操作身份 |
| Recorder result reference | 必填 | immutable result reference | state recorder observation | recorder 返回事实 |
| Observed complete | 必填 | `true` 或 `false` | control plane observation | 是否完整写入并可重读 |
| Reread reference | `true` 时必填 | immutable reread evidence | observed reread | exact bytes、identity 与字段重读证据 |

## 停止边界

任一 identity、raw bytes、length、digest placeholder、transport metadata、attachment continuation 或 materialization observation 无法唯一证明时，停在 last proven gate。本模板不能证明 recorder、digest 或 runtime 已实现。
