# Review 阶段路由

> 本文件属于 [`themis-core-control`](../../README.md) 唯一 Policy，拥有 Review Projection、Review Check 和 Review Dialogue 的二十八个合法控制结果。它不是 route table、DSL 或独立 Policy。旧 YAML 中迁移的二十四个 Review 结果继续保留；新增四个 owner-specific 结果只闭合已批准的 `plan-check` 与 `review-projection` feedback owner，不改变 owner 集合或 Review 顺序。

所有规则要求 `lifecycle` scope、current checked Plan/Plan Check、Policy、Execution/Invocation identity、path/profile、fixed Profile、exact continuation 和 current source/artifact bindings 全部匹配。Review 必须发生在 Impl 前，Review Projection 不是 execution contract。

## `themis-review-projection` · `semantic-readonly`

### `simple/lightweight` 的 `ready`

当 legal status 为 `ready` 时，control plane 必须物化绑定 current checked Plan 的 Review Projection pair；成功后继续 `themis-review-check`。旧 Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效；failure class 为 `none`。

### `simple/lightweight` 的 `blocked`

当 legal status 为 `blocked` 时，control plane 必须保留 Projection continuation 和 blocker evidence，进入 `human-unblock`；不形成 projection。该结果为 `non-counted`，不额外失效 authority。

### `full/full` 的 `ready`

当 legal status 为 `ready` 时，control plane 必须物化绑定 current checked Plan 的 Review Projection pair；成功后继续 `themis-review-check`。旧 Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效；failure class 为 `none`。

### `full/full` 的 `blocked`

当 legal status 为 `blocked` 时，control plane 必须保留 Projection continuation 和 blocker evidence，进入 `human-unblock`；不形成 projection。该结果为 `non-counted`，不额外失效 authority。

## `themis-review-check` · `independent-checker`

### `simple/lightweight` 的 `pass`

当 legal status 为 `pass` 时，control plane 必须物化 Review Check pass structured record；成功后继续 `themis-review-dialogue`，不额外失效 authority。Failure class 为 `none`。

### `simple/lightweight` 的 `needs-projection`

当 legal status 为 `needs-projection` 时，control plane 必须物化 checker finding并返回 `themis-review-projection`；Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

### `full/full` 的 `pass`

当 legal status 为 `pass` 时，control plane 必须物化 Review Check pass structured record；成功后继续 `themis-review-dialogue`，不额外失效 authority。Failure class 为 `none`。

### `full/full` 的 `needs-projection`

当 legal status 为 `needs-projection` 时，control plane 必须物化 checker finding并返回 `themis-review-projection`；Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

## `themis-review-dialogue` · `simple/lightweight` · `human-dialogue`

### `continue`

当 legal status 为 `continue` 时，control plane 必须持久化 Review Dialogue continuation，继续 `human-review`；不形成 Approval、不失效 authority。该等待结果为 `non-counted`。

### `approved`

当 legal status 为 `approved` 时，control plane 必须验证 unresolved feedback 为空及全部 Approval bindings，物化 Review Approval pair；成功后继续 `themis-impl`，不额外失效 authority。Failure class 为 `none`。任一 binding 缺失时不得把用户措辞解释为 Approval。

### `needs-current-request`

当 legal status 为 `needs-current-request` 且 `affected_owner` 唯一为 `current-request-dialogue` 时，control plane 必须先物化 Review Feedback pair，再返回 `themis-current-request-dialogue`；Current Request、Questioning、Complexity Assessment、Plan、Plan Check、Review Projection、Review Check、prior Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

### `needs-questioning`

当 legal status 为 `needs-questioning` 且 `affected_owner` 唯一为 `questioning` 时，control plane 必须物化 Review Feedback pair并返回 `themis-q`；Questioning、Complexity Assessment、Plan、Plan Check、Review Projection、Review Check、prior Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

### `needs-simple-planning`

当 legal status 为 `needs-simple-planning` 且 `affected_owner` 唯一为 `simple-planning` 时，control plane 必须物化 Review Feedback pair并返回 `themis-simple-plan`；Plan、Plan Check、Review Projection、Review Check、prior Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

### `needs-planning`

当 legal status 为 `needs-planning` 且 `affected_owner` 唯一为 `planning` 时，control plane 必须物化 Review Feedback pair、设置 sticky full并继续 `themis-spec`；quick Plan、Plan Check、Review Projection、Review Check、prior Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

### `needs-specification`

当 legal status 为 `needs-specification` 且 `affected_owner` 唯一为 `specification` 时，control plane 必须物化 Review Feedback pair、设置 sticky full并继续 `themis-spec`；quick Plan、Plan Check、Review Projection、Review Check、prior Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

### `needs-plan-check`

当 legal status 为 `needs-plan-check` 且 `affected_owner` 唯一为 `plan-check` 时，control plane 必须物化并保留该 unresolved Review Feedback pair，失效 current Plan Check、Review Projection、Review Check、Review Approval 和 unfinished downstream，然后返回 `themis-plan-check`。Current Plan 保持不变，不设置 sticky full。该结果为 `non-counted`。

### `needs-review-projection`

当 legal status 为 `needs-review-projection` 且 `affected_owner` 唯一为 `review-projection` 时，control plane 必须物化并保留该 unresolved Review Feedback pair，失效 current Review Projection、Review Check、Review Approval 和 unfinished downstream，然后返回 `themis-review-projection`。Current Plan 与 current passed Plan Check 保持不变，不设置 sticky full。该结果为 `non-counted`。

### `needs-grounding`

当 legal status 为 `needs-grounding` 时，control plane 必须物化 Review Feedback pair、保存 feedback owner continuation并继续 `themis-grounding`；Grounding 后恢复被分类的 owner，不额外失效 authority。该结果为 `non-counted`。

### `escalate-full`

当 legal status 为 `escalate-full` 时，control plane 必须物化 Review Feedback pair、设置 sticky full并继续 `themis-spec`；quick Plan、Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

## `themis-review-dialogue` · `full/full` · `human-dialogue`

### `continue`

当 legal status 为 `continue` 时，control plane 必须持久化 Review Dialogue continuation，继续 `human-review`；不形成 Approval、不失效 authority。该等待结果为 `non-counted`。

### `approved`

当 legal status 为 `approved` 时，control plane 必须验证 unresolved feedback 为空及全部 Approval bindings，物化 Review Approval pair；成功后继续 `themis-impl`，不额外失效 authority。Failure class 为 `none`。

### `needs-current-request`

当 legal status 为 `needs-current-request` 且 `affected_owner` 唯一为 `current-request-dialogue` 时，control plane 必须物化 Review Feedback pair并返回 `themis-current-request-dialogue`；Current Request、Questioning、Complexity Assessment、Plan、Plan Check、Review Projection、Review Check、prior Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

### `needs-questioning`

当 legal status 为 `needs-questioning` 且 `affected_owner` 唯一为 `questioning` 时，control plane 必须物化 Review Feedback pair并返回 `themis-q`；Questioning、Complexity Assessment、Plan、Plan Check、Review Projection、Review Check、prior Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

### `needs-planning`

当 legal status 为 `needs-planning` 且 `affected_owner` 唯一为 `planning` 时，control plane 必须物化 Review Feedback pair并返回 `themis-planning`；Plan、Plan Check、Review Projection、Review Check、prior Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

### `needs-specification`

当 legal status 为 `needs-specification` 且 `affected_owner` 唯一为 `specification` 时，control plane 必须物化 Review Feedback pair并返回 `themis-spec`；Plan、Plan Check、Review Projection、Review Check、prior Review Feedback、Review Approval 和 unfinished downstream 失效。该结果为 `non-counted`。

### `needs-plan-check`

当 legal status 为 `needs-plan-check` 且 `affected_owner` 唯一为 `plan-check` 时，control plane 必须物化并保留该 unresolved Review Feedback pair，失效 current Plan Check、Review Projection、Review Check、Review Approval 和 unfinished downstream，然后返回 `themis-plan-check`。Current Plan 保持不变。该结果为 `non-counted`。

### `needs-review-projection`

当 legal status 为 `needs-review-projection` 且 `affected_owner` 唯一为 `review-projection` 时，control plane 必须物化并保留该 unresolved Review Feedback pair，失效 current Review Projection、Review Check、Review Approval 和 unfinished downstream，然后返回 `themis-review-projection`。Current Plan 与 current passed Plan Check 保持不变。该结果为 `non-counted`。

### `needs-grounding`

当 legal status 为 `needs-grounding` 时，control plane 必须物化 Review Feedback pair、保存 feedback owner continuation并继续 `themis-grounding`；Grounding 后恢复被分类的 owner，不额外失效 authority。该结果为 `non-counted`。

## 共同停止条件

若 Projection 与 checked Plan 不一致、Review Check 未 current pass、Approval bindings 不完整、unresolved feedback 非空、simple/full status 域不匹配、owner-specific status 与 `affected_owner` 不唯一一致，或出现 stale/duplicate/late result、wrong Profile、zero/multiple rule match、invalid binding、competing terminal results 或 materialization failure，必须进入 counted invalid-result。Review Dialogue 不得直接 patch Plan/projection，也不得从用户自由文本跳过 Approval materialization。
