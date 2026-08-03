# Planning 阶段路由

> 本文件属于 [`themis-core-control`](../../README.md) 唯一 Policy，拥有 Simple Plan、temporary Specification、Planning 和 Plan Check 的二十个合法控制结果。它不是 route table、DSL 或独立 Policy。

所有规则要求 current lifecycle、Policy、Execution/Invocation identity、Current Request、Questioning/Assessment、current source/artifact bindings、exact continuation、fixed Profile 和对应 path/profile 全部匹配。`full_path_required` 为 true 时任何 simple route 都不合法。

## `themis-simple-plan` · `simple/lightweight` · `semantic-readonly`

### `ready`

当 legal status 为 `ready` 时，control plane 必须物化 unified Plan pair；成功后继续 lightweight `themis-plan-check`。新 Plan 使旧 Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效；failure class 为 `none`。

### `escalate-full`

当 legal status 为 `escalate-full` 时，control plane 必须设置 sticky `full_path_required`，记录 escalation，并继续 `themis-spec`；quick Plan、Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效。该控制结果为 `non-counted`。

### `blocked`

当 legal status 为 `blocked` 时，control plane 必须保留 exact continuation 和 blocker evidence，进入 `human-unblock`；不形成 Plan、不清除 sticky state，也不额外失效 authority。该结果为 `non-counted`。

## `themis-spec` · `full/null` · `semantic-readonly`

### `ready`

当 legal status 为 `ready` 时，control plane 只绑定 temporary Specification handoff 到 current inputs 和 Planning continuation；成功后继续 `themis-planning`。该 handoff 不成为 semantic authority、不拥有 persistent pointer，合法成功的 failure class 为 `none`。

### `needs-questioning`

当 legal status 为 `needs-questioning` 时，control plane 必须记录返回 Questioning 的 exact continuation，并继续 `themis-q`；受影响的 Questioning、Complexity Assessment、Plan 和 unfinished downstream 失效。该结果为 `non-counted`。

### `needs-grounding`

当 legal status 为 `needs-grounding` 时，control plane 必须保存 Specification continuation，继续 `themis-grounding`，待 Grounding 后恢复同一 owner；不额外失效 authority。该结果为 `non-counted`。

### `blocked`

当 legal status 为 `blocked` 时，control plane 必须保留 Specification continuation 和 blocker evidence，进入 `human-unblock`；不伪造 handoff。该结果为 `non-counted`。

## `themis-planning` · `full/full` · `semantic-readonly`

### `ready`

当 legal status 为 `ready` 时，control plane 必须物化 unified Plan pair；成功后继续 full `themis-plan-check`。新 Plan 使旧 Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效；failure class 为 `none`。

### `needs-specification`

当 legal status 为 `needs-specification` 时，control plane 必须记录 Planning 对 Specification refinement 的 exact continuation，并继续 `themis-spec`；Plan、Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

### `needs-grounding`

当 legal status 为 `needs-grounding` 时，control plane 必须保存 Planning continuation，继续 `themis-grounding`，待 Grounding 后恢复 Planning；不额外失效 authority。该结果为 `non-counted`。

### `blocked`

当 legal status 为 `blocked` 时，control plane 必须保留 Planning continuation 和 blocker evidence，进入 `human-unblock`；不形成 Plan。该结果为 `non-counted`。

## `themis-plan-check` · `simple/lightweight` · `independent-checker`

### `pass`

当 legal status 为 `pass` 时，control plane 必须物化 Plan Check pass structured record，并确认 checker 与 Plan producer 隔离；成功后继续 `themis-review-projection`，不额外失效 authority。Failure class 为 `none`。

### `needs-simple-planning`

当 legal status 为 `needs-simple-planning` 时，control plane 必须物化 Plan Check finding并返回 `themis-simple-plan`；Plan、Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

### `escalate-full`

当 legal status 为 `escalate-full` 时，control plane 必须物化 Plan Check finding、设置 sticky full 并继续 `themis-spec`；quick Plan、Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

### `blocked`

当 legal status 为 `blocked` 时，control plane 必须物化 Plan Check blocker record并进入 `human-unblock`；不推进 Review。该结果为 `non-counted`，不额外失效 authority。

## `themis-plan-check` · `full/full` · `independent-checker`

### `pass`

当 legal status 为 `pass` 时，control plane 必须物化 Plan Check pass structured record，并确认 checker 与 Plan producer 隔离；成功后继续 `themis-review-projection`，不额外失效 authority。Failure class 为 `none`。

### `needs-planning`

当 legal status 为 `needs-planning` 时，control plane 必须物化 finding 并返回 `themis-planning`；Plan、Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

### `needs-specification`

当 legal status 为 `needs-specification` 时，control plane 必须物化 finding 并返回 `themis-spec`；Plan、Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

### `needs-grounding`

当 legal status 为 `needs-grounding` 时，control plane 必须物化 finding、保存 Plan Check continuation并继续 `themis-grounding`，待 Grounding 后恢复 checker owner；不额外失效 authority。该结果为 `non-counted`。

### `blocked`

当 legal status 为 `blocked` 时，control plane 必须物化 Plan Check blocker record并进入 `human-unblock`；不推进 Review。该结果为 `non-counted`，不额外失效 authority。

## 共同停止条件

Wrong path/profile、simple route 上 sticky full 已为 true、full route 出现 quick-only status、producer/checker isolation 无法证明、temporary handoff 被当作 authority、stale/duplicate/late result、zero/multiple match、invalid binding 或 materialization failure 都必须进入 counted invalid-result；不得从 prose 选择 Plan owner 或把 `blocked` 当作 pass。
