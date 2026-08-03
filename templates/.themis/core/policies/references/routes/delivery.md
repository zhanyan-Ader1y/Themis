# 交付阶段路由

> 本文件属于 [`themis-core-control`](../../README.md) 唯一 Policy，拥有 Impl、independent Verification、Human Acceptance 和 Summary 的三十一个合法控制结果。它不是 route table、DSL 或独立 Policy。

所有规则只适用于 `lifecycle` scope，并要求 current Policy、Approval、Plan task、Plan Task Execution Identity、separate Invocation/attempt、path/profile、fixed Profile、baseline/expected delta、current artifacts 和 exact continuation 全部匹配。Verify 固定为 `themis-impl → independent themis-verification`；Impl writer 不能验证自身。

## `themis-impl` · `implementation-writer`

### `simple/lightweight` 的 `implemented`

当 legal status 为 `implemented` 时，control plane 必须物化绑定 actual delta/evidence 的 Impl Result pair；成功后继续独立 `themis-verification`。Affected Verification evidence、Human Acceptance 和 Summary 失效；failure class 为 `none`。

### `simple/lightweight` 的 `needs-planning`

当 legal status 为 `needs-planning` 时，control plane 必须物化 Impl Result/finding、设置 sticky full并继续 `themis-spec`；quick Plan、Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

### `simple/lightweight` 的 `escalate-full`

当 legal status 为 `escalate-full` 时，control plane 必须物化 Impl Result/finding、设置 sticky full并继续 `themis-spec`；quick Plan、Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

### `simple/lightweight` 的 `blocked`

当 legal status 为 `blocked` 时，control plane 必须物化可用的 Impl blocker evidence、保留 continuation并进入 `human-unblock`；不伪造完成 delta。该结果为 `non-counted`，不额外失效 authority。

### `full/full` 的 `implemented`

当 legal status 为 `implemented` 时，control plane 必须物化绑定 actual delta/evidence 的 Impl Result pair；成功后继续独立 `themis-verification`。Affected Verification evidence、Human Acceptance 和 Summary 失效；failure class 为 `none`。

### `full/full` 的 `needs-planning`

当 legal status 为 `needs-planning` 时，control plane 必须物化 Impl Result/finding并返回 `themis-planning`；Plan、Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

### `full/full` 的 `blocked`

当 legal status 为 `blocked` 时，control plane 必须物化可用的 Impl blocker evidence、保留 continuation并进入 `human-unblock`；不伪造完成 delta。该结果为 `non-counted`，不额外失效 authority。

## `themis-verification` · `independent-checker`

### `simple/lightweight` 的 `passed`

当 legal status 为 `passed` 时，control plane 必须物化 Verification pair 和 exact evidence；成功后继续 `themis-acceptance-dialogue`，不额外失效 authority。Failure class 为 `none`。

### `simple/lightweight` 的 `failed`

当 legal status 为 `failed` 时，control plane 必须物化 Verification failure 和 bounded implementation repair continuation，返回 `themis-impl`；Affected Verification evidence、Human Acceptance 和 Summary 失效。该 execution failure 为 `counted`，继续使用同一 Plan Task Execution Identity 和 budget。

### `simple/lightweight` 的 `needs-planning`

当 legal status 为 `needs-planning` 时，control plane 必须物化 Verification finding、设置 sticky full并继续 `themis-spec`；quick Plan、Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

### `simple/lightweight` 的 `needs-specification`

当 legal status 为 `needs-specification` 时，control plane 必须物化 Verification finding、设置 sticky full并继续 `themis-spec`；quick Plan、Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

### `simple/lightweight` 的 `escalate-full`

当 legal status 为 `escalate-full` 时，control plane 必须物化 Verification finding、设置 sticky full并继续 `themis-spec`；quick Plan、Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

### `simple/lightweight` 的 `blocked`

当 legal status 为 `blocked` 时，control plane 必须物化 Verification blocker evidence、保留 continuation并进入 `human-unblock`；不产生 passed verdict。该结果为 `non-counted`。

### `full/full` 的 `passed`

当 legal status 为 `passed` 时，control plane 必须物化 Verification pair 和 exact evidence；成功后继续 `themis-acceptance-dialogue`，不额外失效 authority。Failure class 为 `none`。

### `full/full` 的 `failed`

当 legal status 为 `failed` 时，control plane 必须物化 Verification failure 和 bounded implementation repair continuation，返回 `themis-impl`；Affected Verification evidence、Human Acceptance 和 Summary 失效。该 execution failure 为 `counted`，继续使用同一 Plan Task Execution Identity 和 budget。

### `full/full` 的 `needs-planning`

当 legal status 为 `needs-planning` 时，control plane 必须物化 Verification finding并返回 `themis-planning`；Plan、Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

### `full/full` 的 `needs-specification`

当 legal status 为 `needs-specification` 时，control plane 必须物化 Verification finding并返回 `themis-spec`；Plan、Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

### `full/full` 的 `blocked`

当 legal status 为 `blocked` 时，control plane 必须物化 Verification blocker evidence、保留 continuation并进入 `human-unblock`；不产生 passed verdict。该结果为 `non-counted`。

## `themis-acceptance-dialogue` · `human-dialogue`

### `simple/lightweight` 的 `accepted`

当 legal status 为 `accepted` 且 current Verification 为 `passed` 时，control plane 必须物化 Human Acceptance pair；成功后继续 `themis-summary`，不额外失效 authority。Failure class 为 `none`。

### `simple/lightweight` 的 `implementation-defect`

当 legal status 为 `implementation-defect` 时，control plane 必须物化 Acceptance observation 和 bounded implementation repair continuation，返回 current Approval 范围内的 `themis-impl`；Affected Verification evidence、Human Acceptance 和 Summary 失效。该 defect 为 `counted`，共享同一 Plan Task Execution Identity/budget，并在 repair 后重新 Verification。

### `simple/lightweight` 的 `needs-planning`

当 legal status 为 `needs-planning` 时，control plane 必须物化 Acceptance feedback、设置 sticky full并继续 `themis-spec`；quick Plan、Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

### `simple/lightweight` 的 `needs-specification`

当 legal status 为 `needs-specification` 时，control plane 必须物化 Acceptance feedback、设置 sticky full并继续 `themis-spec`；quick Plan、Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

### `simple/lightweight` 的 `escalate-full`

当 legal status 为 `escalate-full` 时，control plane 必须物化 Acceptance feedback、设置 sticky full并继续 `themis-spec`；quick Plan、Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

### `full/full` 的 `accepted`

当 legal status 为 `accepted` 且 current Verification 为 `passed` 时，control plane 必须物化 Human Acceptance pair；成功后继续 `themis-summary`，不额外失效 authority。Failure class 为 `none`。

### `full/full` 的 `implementation-defect`

当 legal status 为 `implementation-defect` 时，control plane 必须物化 Acceptance observation 和 bounded implementation repair continuation，返回 current Approval 范围内的 `themis-impl`；Affected Verification evidence、Human Acceptance 和 Summary 失效。该 defect 为 `counted`，共享同一 Plan Task Execution Identity/budget，并在 repair 后重新 Verification。

### `full/full` 的 `needs-planning`

当 legal status 为 `needs-planning` 时，control plane 必须物化 Acceptance feedback并返回 `themis-planning`；Plan、Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

### `full/full` 的 `needs-specification`

当 legal status 为 `needs-specification` 时，control plane 必须物化 Acceptance feedback并返回 `themis-spec`；Plan、Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

## `themis-summary` · `semantic-readonly`

### `simple/lightweight` 的 `ready`

当 legal status 为 `ready` 且 current Verification 为 `passed`、current Human Acceptance 为 `accepted` 时，control plane 必须物化 Summary pair并重读；成功后记录 lifecycle completion observation，进入 `completed` gate，再按 Intake retention reference 执行逐 target 后置控制。Failure class 为 `none`。

### `simple/lightweight` 的 `blocked`

当 legal status 为 `blocked` 时，control plane 必须保留 Summary continuation 和 blocker evidence，进入 `human-unblock`；不记录 lifecycle completion。该结果为 `non-counted`。

### `full/full` 的 `ready`

当 legal status 为 `ready` 且 current Verification 为 `passed`、current Human Acceptance 为 `accepted` 时，control plane 必须物化 Summary pair并重读；成功后记录 lifecycle completion observation，进入 `completed` gate，再按 Intake retention reference 执行逐 target 后置控制。Failure class 为 `none`。

### `full/full` 的 `blocked`

当 legal status 为 `blocked` 时，control plane 必须保留 Summary continuation 和 blocker evidence，进入 `human-unblock`；不记录 lifecycle completion。该结果为 `non-counted`。

## 共同停止条件

Approval stale、writer 自验、Verification/Acceptance/Summary gate 不成立、wrong path/Profile、quick-only status 出现在 full path、repair 试图创建新 budget、stale/duplicate/late result、zero/multiple rule match、invalid binding、competing terminal results 或 recorder/materialization failure，都必须进入 counted invalid-result。不得从 Review Markdown、用户自由文本或文件存在推断实现、passed、accepted 或 completed。
