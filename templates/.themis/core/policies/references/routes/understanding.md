# 理解阶段路由

> 本文件属于 [`themis-core-control`](../../README.md) 唯一 Policy，拥有 Questioning、Grounding 和 Complexity Assessment 的八个合法控制结果。它不是 route table、DSL 或独立 Policy。

本文件所有规则只适用于 `lifecycle` scope，并要求 current Policy、lifecycle identity、Execution/Invocation identity、Current Request revision、source/artifact bindings、exact continuation、fixed Agent Profile 和 `selected_path/profile: null/null` 全部 current。任何 artifact/record 都须按共享 materialization 合同完整持久化并重读。

## `themis-q` · `human-dialogue`

### `needs-questioning`

当 legal status 为 `needs-questioning` 时，control plane 必须持久化绑定 current Current Request 的 Questioning proposal 和等待 answer 的 durable continuation；成功后进入 `human-questioning`，不提前形成 completed round，也不失效 current 下游。该等待结果为 `non-counted`。

### `converged`

当 legal status 为 `converged` 时，control plane 必须物化 Questioning Round pair 并在完整重读后更新 Current Questioning Pointer；成功后继续 `themis-complexity-assessment`。新 round 使依赖旧 round 的 Complexity Assessment、Plan 和 unfinished downstream 失效；failure class 为 `none`。

若 answer 尚未经过 Intake interception、round 与 pointer 不一致、或不能证明 post-answer Current Request binding，必须停止，不得从 chat 拼接 completed round。

## `themis-grounding` · `semantic-readonly`

### `ready`

当 legal status 为 `ready` 时，control plane 必须物化绑定 current sources、事实证据和 requesting continuation 的 Grounding structured record；成功后通过 `requesting-capability` 恢复该 exact continuation，不额外失效 authority。Failure class 为 `none`。

### `partial`

当 legal status 为 `partial` 时，control plane 必须物化 partial Grounding record，明确已观察事实、缺失项和不得视为已满足的限制；成功后通过 `requesting-capability` 恢复 exact continuation，由原 owner 决定是否仍可继续。该控制结果为 `non-counted`，不能被解释为 `ready`。

### `blocked`

当 legal status 为 `blocked` 时，control plane 必须保留 requesting continuation 和 blocker evidence，并进入 `human-unblock`；不物化虚假事实，也不失效既有 current authority。该结果为 `non-counted`。

若 Grounding result 不绑定请求它的 Capability continuation，引用未观察实现事实，或试图自行选择后续 owner，必须停止并按 invalid-result 处理。

## `themis-complexity-assessment` · `semantic-readonly`

### `simple-qualified`

当 legal status 为 `simple-qualified` 且 current lifecycle 的 `full_path_required` 为 false 时，control plane 必须物化 Complexity Assessment structured record、选择 `simple/lightweight`，并继续 `themis-simple-plan`；不失效额外 authority，failure class 为 `none`。

若 legal status 仍为 `simple-qualified` 但 guard `full_path_required == false` 不成立，control plane 必须同样物化 Assessment，却保持 sticky full、选择 full path、继续 `themis-spec`，并失效 quick Plan、Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream；该 guard-failure control 为 `non-counted`，不得清除 failure budget。

### `full-required`

当 legal status 为 `full-required` 时，control plane 必须物化 Assessment、把 `full_path_required` 设置或保持为 true，并继续 `themis-spec`；quick Plan、Plan Check、Review Projection、Review Check、Review Feedback、Review Approval 和 unfinished downstream 失效。该 path decision 为 `non-counted`。

### `blocked`

当 legal status 为 `blocked` 时，control plane 必须保留 Assessment continuation 和 blocker evidence，进入 `human-unblock`，不选择 simple/full 或伪造 Assessment。该结果为 `non-counted`，不额外失效 authority。

若 simple 条件未逐项证明、sticky state 无法读取、status 与 fixed Profile 不匹配或 result 试图清除 `full_path_required`，必须停止并按 invalid-result 处理，不得把 unknown 默认为 simple。

## 共同停止条件

任何 stale/duplicate/late result、zero/multiple rule match、wrong scope/Profile/path、missing current binding、illegal payload、competing terminal results 或 recorder/materialization failure 都必须进入 counted invalid-result；不得从 diagnostics 或自由文本猜测 continuation、事实充分性或 path。
