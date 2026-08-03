# Review Check Record 模板

> 本文件是活动 Prompt-level immutable structured record 模板，用于形成候选 Review Check 记录。具体记录只有经适用 Policy control action 完整物化、记录完成观察并重读 identity、fields 与 bindings 后，才构成 governed Review Check record；它只检查 Review Projection 的忠实度、可追溯性与呈现负担，不评价 Plan 方案优劣。

## Record identity 与执行绑定

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Template status | 必填 | `prompt-level-not-machine-validated` | 模板固定值 | 不声称自动校验 |
| Record class | 必填 | `structured-semantic-result` | 模板固定值 | structured checker result |
| Authority scope | 必填 | `lifecycle` | current lifecycle | lifecycle-local result |
| Record identity | 必填 | opaque immutable identity | materialization action | Review Check revision |
| Lifecycle identity | 必填 | opaque lifecycle identity | Invocation binding | 所属 lifecycle |
| Execution identity | 必填 | current lifecycle Execution Identity | Invocation contract | failure control 绑定 |
| Invocation identity | 必填 | current temporary Invocation | checker proposal | checker 来源 |
| Attempt identity | 必填 | current attempt identity | Invocation contract | 与 Execution Identity 绑定 |
| Capability | 必填 | `themis-review-check` | fixed binding | checker identity |
| Agent Profile | 必填 | `independent-checker` | fixed binding | producer/checker isolation |
| Status | 必填 | `pass` 或 `needs-projection` | legal result | 供 exactly-one Policy rule 匹配 |

旧状态 `passed` 与 `blocked` 不再合法。必要证据不可验证时不能返回 `pass`；Invocation 或工具失败不能伪装成 `needs-projection`。

## Input bindings 记录

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Current Request revision | 必填 | current immutable revision | lifecycle pointer | 目标绑定 |
| Plan revision/digest | 必填 | current checked Plan | paired Plan | source authority |
| Plan Check reference | 必填 | current `pass` record | checker gate | Plan 已通过检查 |
| Review revision/digest | 必填 | current Review Projection pair | projection pointer | checker target |
| Projection map reference | 必填 | complete map | Review record | traceability |
| Selected path/profile | 必填 | `simple/lightweight` 或 `full/full` | current route | profile lock |
| Policy identity/digest | 必填 | current observed binding | Invocation preflight | route/currentness |
| Continuation identity | 必填 | exact durable continuation | lifecycle control | Dialogue 或 re-projection return |

## Check findings 记录

| Check identity | Requirement | Result | Evidence | Affected Projection location | Source Plan location |
|---|---|---|---|---|---|
|  |  | `pass` 或 `gap` |  |  |  |

检查关键决定覆盖、压缩原意、图形忠实度、由抽象到具体排序、推荐依据、呈现负担与 projection map。`needs-projection` 只能修复投影，不能 patch Plan。

## 物化与当前性观察

| 字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义 |
|---|---|---|---|---|
| Operation identity | 必填 | opaque operation identity | control action | 写入操作 |
| Recorder result reference | 必填 | immutable result reference | recorder observation | 写入结果 |
| Observed complete | 必填 | `true` 或 `false` | control observation | record 是否完整 |
| Reread reference | `true` 时必填 | immutable reread evidence | observed reread | identity/status/bindings 重读 |
| Currentness observation reference | current 时必填 | separate current reference；否则 `none` | lifecycle control | record 存在不证明 current |

## 停止边界

Plan、Projection、Plan Check、scope、Profile、Policy、continuation 或 map binding 缺失/过期时停止。Checker 不继承 producer 临时推理，不形成 Approval，也不把 Plan quality defect 包装为 projection defect。
