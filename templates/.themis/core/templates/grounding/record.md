# Grounding Record 模板

> 本文件是活动 Prompt-level immutable structured record 模板，用于形成候选 Grounding 记录。具体记录只有经适用 Policy control action 完整物化、记录完成观察并重读 identity、fields 与 bindings 后，才构成 governed Grounding record；它记录 `themis-grounding` 对明确事实请求的只读观察，不创建无语义的 `content.md`。

## Record identity 与执行绑定

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Template status | 必填 | `prompt-level-not-machine-validated` | 模板固定值 | 不声称机器校验 |
| Record class | 必填 | `structured-semantic-result` | 模板固定值 | structured Grounding record |
| Authority scope | 必填 | `lifecycle` | current lifecycle | lifecycle-local result |
| Record identity | 必填 | opaque immutable identity | materialization action | Grounding record identity |
| Lifecycle identity | 必填 | opaque lifecycle identity | Invocation binding | 所属 lifecycle |
| Execution identity | 必填 | current lifecycle Execution Identity | Invocation contract | failure budget 绑定 |
| Invocation identity | 必填 | current temporary Invocation | Invocation contract | proposal 来源 |
| Attempt identity | 必填 | current lifecycle attempt identity | Invocation contract | 与 Execution Identity 的 counted attempt 绑定 |
| Capability | 必填 | `themis-grounding` | fixed binding | Capability identity |
| Agent Profile | 必填 | `semantic-readonly` | fixed binding | 只读执行身份 |
| Status | 必填 | `ready`、`partial` 或 `blocked` | Capability legal result | closed result status |

## Input bindings 记录

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Current Request revision | 必填 | immutable current revision | lifecycle current pointer | 需求输入 |
| Questioning round revision | 必填 | completed current round reference | lifecycle current pointer | Why/abstract What 输入 |
| Requesting Capability | 必填 | stable Capability identity | durable continuation | Grounding 完成后唯一 return owner |
| Requested fact assertions | 必填 | 一项或多项 assertion identities/text | requesting Capability | 核验范围 |
| Implementation baseline | 必填 | observed checkout/baseline identity | Invocation preflight | 证据适用边界 |
| Policy identity/digest | 必填 | current observed binding | Policy preflight | route/currentness 绑定 |
| Continuation identity | 必填 | exact durable continuation | caller | 完成后的返回位置 |
| Selected path/profile | 必填 | 均为 `none` | Capability binding | Grounding 不选择 path/profile |

## Fact observations 记录

每个 requested assertion 逐项记录，不得合并为笼统 summary：

| Assertion | Conclusion | Evidence references | Unknowns/limits | Baseline applicability |
|---|---|---|---|---|
|  | `observed`、`contradicted` 或 `unknown` | code/configuration/Schema/observed behavior | 无则写 `none` | 当前 baseline 下的适用说明 |

行为证据另记录：

| Command/observation | CWD | Environment | Exit/result | Raw stdout/stderr/evidence reference |
|---|---|---|---|---|

`ready` 要求每个 assertion 都有直接 observed 或 contradicted evidence；任一 `unknown` 只能返回 `partial`。权限、环境或外部条件使核验无法开始时才返回 `blocked`。

## Blocker 证据记录

`blocked` 时逐项记录，其他状态为空集合：

| Blocker identity | Blocked permission/environment/external condition | Observed evidence reference | Human-unblock requirement | Preserved requesting continuation |
|---|---|---|---|---|

不得用假设的 blocker、工具已开始后的执行失败或未尝试核验替代 observed blocker evidence。

## 物化观察

| Operation identity | Recorder result reference | Observed complete | Reread reference |
|---|---|---|---|
|  |  | `true` 或 `false` | `true` 时必填 |

## 停止边界

文档、Specification、Plan、Review、Summary、经验或 Agent prose 只能提供搜索线索，不能证明当前实现事实。工具或命令已开始后失败属于 counted failure，不能改写为 `partial` 或 `blocked`。
