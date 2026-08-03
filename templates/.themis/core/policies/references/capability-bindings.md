# Capability 绑定

> 本文件属于 [`themis-core-control`](../README.md) 唯一 Policy，拥有 closed vocabulary、十六个 Capability 的 scope、fixed Agent Profile、path/profile domain、legal status 和 materialization target。它不是独立 Policy。

## 闭合词汇

Agent Profile 的闭合枚举为 `semantic-readonly | independent-checker | human-dialogue | implementation-writer`。Authority scope 为 `request-intake | lifecycle`。Selected path 为 `simple | full | null`。Plan profile 为 `lightweight | full | null`，它不表示 Agent 工具权限。Failure class 为 `none | non-counted | counted`。

Review 或其他 lifecycle feedback 可路由的 affected owner 只有 `current-request-dialogue | questioning | specification | simple-planning | planning | plan-check | review-projection`。

合法 next/continuation target 只有：`human-request-confirmation`、`intake-closed`、`decision-bound-continuation`、`human-questioning`、`human-review`、`human-acceptance`、`human-unblock`、`requesting-capability`、`resume-scope-main-route`、`failure-control`、十六个固定 Capability identity，以及 `completed`。

失效类别只有：`intake-proposal`、`intake-decision`、`current-request`、`questioning`、`complexity-assessment`、`quick-plan`、`plan`、`plan-check`、`review-projection`、`review-check`、`review-feedback`、`review-approval`、`unfinished-downstream`、`affected-verification-evidence`、`human-acceptance` 和 `summary`。具体 route 只能使用 [Guards, invalidation and recovery](guards-invalidation-and-recovery.md) 已定义的传播组合。

只有 `themis-impl` 使用 `implementation-writer`。任何 Capability 不得选择或扩张自身 Profile、调用其他 Capability/Agent、保留跨 Invocation authority、直接执行 route 或返回多个竞争终态结果。

## Intake 能力

### `themis-current-request-dialogue`

该 Capability 固定绑定 `request-intake`、`human-dialogue`、`selected_path: null` 和 `profile: null`。Legal status 只有 `needs-request-confirmation | assignment-confirmed | rejected`；允许的 materialization target 只有 Request Intake proposal 和 Request Intake decision。

## 理解阶段能力

### `themis-q`

该 Capability 固定绑定 `lifecycle`、`human-dialogue`、`selected_path: null` 和 `profile: null`。Legal status 只有 `needs-questioning | converged`；允许的 materialization target 是 Questioning proposal 或 Questioning round pair。

### `themis-grounding`

该 Capability 固定绑定 `lifecycle`、`semantic-readonly`、`selected_path: null` 和 `profile: null`。Legal status 只有 `ready | partial | blocked`；允许的 materialization target 是 Grounding structured record。

### `themis-complexity-assessment`

该 Capability 固定绑定 `lifecycle`、`semantic-readonly`、`selected_path: null` 和 `profile: null`。Legal status 只有 `simple-qualified | full-required | blocked`；允许的 materialization target 是 Complexity Assessment structured record。

## Planning 阶段能力

### `themis-simple-plan`

该 Capability 固定绑定 `lifecycle`、`semantic-readonly`、`simple/lightweight`。Legal status 只有 `ready | escalate-full | blocked`；允许的 materialization target 是 unified Plan pair。

### `themis-spec`

该 Capability 固定绑定 `lifecycle`、`semantic-readonly`、`full/null`。Legal status 只有 `ready | needs-questioning | needs-grounding | blocked`；唯一 target 是 temporary Specification handoff，它不是 semantic authority，不拥有持久 current pointer。

### `themis-planning`

该 Capability 固定绑定 `lifecycle`、`semantic-readonly`、`full/full`。Legal status 只有 `ready | needs-specification | needs-grounding | blocked`；允许的 materialization target 是 unified Plan pair。

### `themis-plan-check`

该 Capability 固定绑定 `lifecycle` 和 `independent-checker`。在 `simple/lightweight` 下 legal status 只有 `pass | needs-simple-planning | escalate-full | blocked`；在 `full/full` 下只有 `pass | needs-planning | needs-specification | needs-grounding | blocked`。允许的 target 是 Plan Check structured record。

## Review 阶段能力

### `themis-review-projection`

该 Capability 固定绑定 `lifecycle`、`semantic-readonly`，允许 `simple/lightweight` 或 `full/full`。Legal status 只有 `ready | blocked`；target 是 Review Projection pair。

### `themis-review-check`

该 Capability 固定绑定 `lifecycle`、`independent-checker`，允许 `simple/lightweight` 或 `full/full`。Legal status 只有 `pass | needs-projection`；target 是 Review Check structured record。

### `themis-review-dialogue`

该 Capability 固定绑定 `lifecycle`、`human-dialogue`。在 `simple/lightweight` 下 legal status 只有 `continue | approved | needs-current-request | needs-questioning | needs-simple-planning | needs-planning | needs-specification | needs-plan-check | needs-review-projection | needs-grounding | escalate-full`；在 `full/full` 下只有 `continue | approved | needs-current-request | needs-questioning | needs-planning | needs-specification | needs-plan-check | needs-review-projection | needs-grounding`。Targets 是 durable Review Dialogue continuation、Review Feedback pair 或 Review Approval pair。

## 交付阶段能力

### `themis-impl`

该 Capability 固定绑定 `lifecycle` 和唯一的 `implementation-writer`。在 `simple/lightweight` 下 legal status 只有 `implemented | needs-planning | escalate-full | blocked`；在 `full/full` 下只有 `implemented | needs-planning | blocked`。Target 是 implementation delta 与 Impl Result pair。

### `themis-verification`

该 Capability 固定绑定 `lifecycle`、`independent-checker`。在 `simple/lightweight` 下 legal status 只有 `passed | failed | needs-planning | needs-specification | escalate-full | blocked`；在 `full/full` 下只有 `passed | failed | needs-planning | needs-specification | blocked`。Target 是 Verification pair 与 evidence。

### `themis-acceptance-dialogue`

该 Capability 固定绑定 `lifecycle`、`human-dialogue`。在 `simple/lightweight` 下 legal status 只有 `accepted | implementation-defect | needs-planning | needs-specification | escalate-full`；在 `full/full` 下只有 `accepted | implementation-defect | needs-planning | needs-specification`。Target 是 Human Acceptance pair。

### `themis-summary`

该 Capability 固定绑定 `lifecycle`、`semantic-readonly`，允许 `simple/lightweight` 或 `full/full`。Legal status 只有 `ready | blocked`；target 是 Summary pair。

## Learning 能力

### `themis-failure-learning`

该 Capability 固定使用 `semantic-readonly`，可在 `request-intake` 或 `lifecycle` 运行。允许的 path/profile domain 是 `null/null | simple/lightweight | full/full`；legal status 只有 `candidate-ready | not-reusable | needs-more-evidence | blocked`。Target 是 Failure Learning pair；其 scope 与 continuation 必须来自 Invocation 已验证的 binding。

## 必须停止的情况

Unknown status、wrong Profile、wrong scope、wrong selected path/profile、full path 上出现 quick-only status、illegal payload 或 competing terminal results 都必须进入 invalid-result control。Global Rule 不得把相近措辞映射为 legal status，也不得从 `recommended_route` 推导 control action。
