# Learning 阶段路由

> 本文件属于 [`themis-core-control`](../../README.md) 唯一 Policy，拥有 `themis-failure-learning` 在三个 path/profile domain 下的十二个合法控制结果。它不是 route table、DSL 或独立 Policy。

所有规则要求 Invocation 已唯一绑定 `request-intake` 或 `lifecycle` scope、scope-local Execution Identity、failed attempt/evidence 或 explicitly linked later success、scope-local main continuation、current Policy、fixed Profile `semantic-readonly` 和对应 path/profile。Learning result 永远 non-blocking，不能改变主 route 或跨 scope 动态状态。

## `null/null`

该 domain 用于 request-intake scope，或合同允许且 Invocation 明确绑定 `null/null` 的 scope-local Learning continuation。

### `candidate-ready`

当 legal status 为 `candidate-ready` 时，control plane 必须物化 Failure Learning candidate pair；成功后恢复 `resume-scope-main-route` 所绑定的 exact continuation，不失效主流程 authority。Failure class 为 `none`。

### `not-reusable`

当 legal status 为 `not-reusable` 时，control plane 必须物化不可复用 disposition 及其证据；成功后恢复 scope-local main route，不失效主流程 authority。Failure class 为 `none`。

### `needs-more-evidence`

当 legal status 为 `needs-more-evidence` 时，control plane 只保留 bound Learning proposal 与缺失证据说明，不物化可复用 candidate；随后恢复 scope-local main route。该结果为 `non-counted`。

### `blocked`

当 legal status 为 `blocked` 时，control plane 必须记录 Failure Learning unavailable，并立即恢复 scope-local main route；Learning 自身失败不递归。该结果为 `non-counted`。

## `simple/lightweight`

该 domain 只适用于 lifecycle scope 中 current simple/lightweight Plan Task Execution 所显式绑定的 Learning continuation。

### `candidate-ready`

当 legal status 为 `candidate-ready` 时，control plane 必须物化 scope-bound Failure Learning candidate pair；成功后恢复 exact lifecycle main route，不失效 delivery 或其他 authority。Failure class 为 `none`。

### `not-reusable`

当 legal status 为 `not-reusable` 时，control plane 必须物化不可复用 disposition 及证据；成功后恢复 exact lifecycle main route。Failure class 为 `none`。

### `needs-more-evidence`

当 legal status 为 `needs-more-evidence` 时，control plane 只保留 bound Learning proposal 与缺失证据说明，随后恢复 exact lifecycle main route。该结果为 `non-counted`。

### `blocked`

当 legal status 为 `blocked` 时，control plane 必须记录 Failure Learning unavailable 并恢复 exact lifecycle main route；不递归调用 Learning。该结果为 `non-counted`。

## `full/full`

该 domain 只适用于 lifecycle scope 中 current full/full Plan Task Execution 所显式绑定的 Learning continuation。

### `candidate-ready`

当 legal status 为 `candidate-ready` 时，control plane 必须物化 scope-bound Failure Learning candidate pair；成功后恢复 exact lifecycle main route，不失效 delivery 或其他 authority。Failure class 为 `none`。

### `not-reusable`

当 legal status 为 `not-reusable` 时，control plane 必须物化不可复用 disposition 及证据；成功后恢复 exact lifecycle main route。Failure class 为 `none`。

### `needs-more-evidence`

当 legal status 为 `needs-more-evidence` 时，control plane 只保留 bound Learning proposal 与缺失证据说明，随后恢复 exact lifecycle main route。该结果为 `non-counted`。

### `blocked`

当 legal status 为 `blocked` 时，control plane 必须记录 Failure Learning unavailable 并恢复 exact lifecycle main route；不递归调用 Learning。该结果为 `non-counted`。

## 共同停止条件

若 scope/path/profile、execution linkage、failed attempt/evidence、later-success linkage 或 scope-local continuation 无法从 durable bindings 证明，必须拒绝 result并进入当前 scope 的 counted invalid-result。不得以 prose similarity 建立 replacement linkage，不得因 Learning blocked 而阻塞主流程，也不得从 candidate 自动发布知识或修改 failure count、Verification、Acceptance、assignment 或 completion。
