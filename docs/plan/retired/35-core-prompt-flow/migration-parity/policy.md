# 自然语言 Policy 迁移核验

## 核验范围

本分片核验任务 3 将 `templates/.themis/core/policies/transitions.yaml` 的 Prompt-level YAML 表示迁移为 `templates/.themis/core/policies/README.md` 与十三个按主题/阶段加载的自然语言 references。新文件当前只是 Markdown Policy candidate；旧 YAML 保留至任务 9 全局 cutover，且其存在不表示继续符合 Markdown-first 规则。

本任务不修改 Global Rule、公共 `themis` Skill、Capability、模板或 Workspace consumer，不实现 parser、evaluator、recorder 或 runtime，也不恢复 current representation authority。

## 旧来源与新目标

- 旧来源：`templates/.themis/core/policies/transitions.yaml`，identity 为 `themis-core-control`。
- 唯一新入口：`templates/.themis/core/policies/README.md`。
- 共享主题 references：`authority-scopes.md`、`intake-and-retention.md`、`capability-bindings.md`、`materialization-and-currentness.md`、`guards-invalidation-and-recovery.md`、`failure-control.md`、`assurance-boundary.md`。
- 阶段 route references：`routes/intake.md`、`routes/understanding.md`、`routes/planning.md`、`routes/review.md`、`routes/delivery.md`、`routes/learning.md`。
- References 合起来构成一个 Policy，不单独形成多个 Policy；route 文件使用完整中文句子，不使用固定 Markdown route table、JSON/YAML 片段、可解析行格式、Markdown DSL 或 parser 指令。
- 允许的表示修订：paired artifact 从 `machine-record + markdown-content` 改述为同一 immutable revision 下的 `record.md + content.md`；该修订已由 current Plan 35 authority 批准。

## 逐项迁移观察

### 十六个旧顶层主题

计划中的“十六个主题”把 `authority_model` 与 `authority_scopes` 分别计数；旧 YAML 的实际顶层来源与新 owner 如下。

| 旧主题 | 新自然语言 owner | 观察 |
|---|---|---|
| `policy_binding` | `README.md`、`authority-scopes.md` | 保留 identity、route key、observed digest binding、digest change action 和 route count 非产品 identity |
| `authority_model` | `authority-scopes.md` | 保留 external input、target semantics、implementation facts、design constraints、temporary Specification、approved Plan、proposal 与 authority conditions |
| `authority_scopes` | `authority-scopes.md` | 保留双 scope ownership、disposition/retention、lifecycle gates 和全部动态隔离 |
| `external_message_interception` | `intake-and-retention.md`、`routes/intake.md` | 保留 Source Event first、attachment source、forbidden signals、no-change/changed continuation、多目标 materialization 和 host-observed abandonment |
| `lifecycle_completion_retention` | `intake-and-retention.md` | 保留 Summary/completion gate、逐 target freeze、whole-Intake gate、`dormant-read-only` 禁止行为和只读保留 |
| `vocabulary` | `capability-bindings.md` | 保留 Profile、scope、path、Plan profile、failure class、route target 和 invalidation category 的闭合语义 |
| `capabilities` | `capability-bindings.md` | 保留十六个 identity、fixed Profile、legal scope、path/profile domain、legal statuses 和 materialization targets |
| `materialization` | `materialization-and-currentness.md` | 保留 ordered steps、paired/structured requirements、temporary handoff、incomplete、pointer failure 和 stale result handling |
| `currentness` | `materialization-and-currentness.md` | 保留 current bindings、Policy change、dependent invalidation 和 external drift |
| `recovery` | `guards-invalidation-and-recovery.md` | 保留 authoritative inputs、last proven gate、forbidden sources 和禁止自动 repair/rollback/merge/inferred completion |
| `failure_control` | `failure-control.md` | 保留双 Execution Identity、三次上限、分类、ordered actions、identity survival 和 Failure Learning |
| `lifecycle_control` | `guards-invalidation-and-recovery.md` 与阶段 routes | 保留两路径、Plan Check 后汇合、sticky full、Approval、Verify、Acceptance 和 Summary gates |
| `invalidation` | `guards-invalidation-and-recovery.md` 与阶段 routes | 保留全部 source-to-dependent 传播，并在每个具体 control result 中重复所需的实际失效范围 |
| `routes` | 六个 `routes/*.md` | 98 个旧合法组合逐项映射到自然语言规则标题与完整控制句 |
| `invalid_result` | `failure-control.md` 与每个 route 的共同停止条件 | 保留全部适用原因、counted fail-closed action 和 failure-control next |
| `assurance` | `assurance-boundary.md` | 保留七项 unavailable 与一项无 observed runtime 时禁止 transition claim，共八项边界 |

### 旧合法组合计数

| 阶段 | 旧组合数 | 新 owner |
|---|---:|---|
| Intake | 3 | `routes/intake.md` |
| Understanding | 8 | `routes/understanding.md` |
| Planning | 20 | `routes/planning.md` |
| Review | 24 | `routes/review.md` |
| Delivery | 31 | `routes/delivery.md` |
| Learning | 12 | `routes/learning.md` |
| 合计 | 98 | 六个自然语言 route references |

98 只表示旧 YAML 的人工迁移覆盖观察值，不是产品 identity、永久常量、固定 Markdown 行数、可解析 DSL 或 Go CLI 输入。

### Intake：3 个组合

| 旧 Capability/path/profile/status | 新规则 | `next` / 旧 control action | Guard、失效与 failure | 观察 |
|---|---|---|---|---|
| `themis-current-request-dialogue · null/null · needs-request-confirmation` | `intake.md` → `needs-request-confirmation` | `human-request-confirmation` / `persist-intake-proposal-and-await-confirmation` | 无额外 guard；无失效；`non-counted` | 完整表达 proposal、durable confirmation continuation、禁止 lifecycle 与 invalid-result stop |
| `themis-current-request-dialogue · null/null · assignment-confirmed` | `intake.md` → `assignment-confirmed` | `decision-bound-continuation` / `materialize-confirmed-assignment` | confirmed decision/targets guard；旧 `intake-decision` 失效；`none` | 完整表达逐 target operation、partial recovery、decision-bound continuation 与 fail-closed |
| `themis-current-request-dialogue · null/null · rejected` | `intake.md` → `rejected` | `intake-closed` / `persist-intake-rejection` | explicit user rejection guard；无失效；`none` | 完整区分 rejection、host-observed abandonment 与 silence |

### Understanding：8 个组合

| 旧 Capability/path/profile/status | 新规则 | `next` / 旧 control action | Guard、失效与 failure | 观察 |
|---|---|---|---|---|
| `themis-q · null/null · needs-questioning` | `understanding.md` → `themis-q/needs-questioning` | `human-questioning` / `persist-question-proposal-and-await-answer` | current Current Request/continuation；无失效；`non-counted` | 完整 |
| `themis-q · null/null · converged` | `understanding.md` → `themis-q/converged` | `themis-complexity-assessment` / `materialize-questioning-round-and-pointer` | completed round/pointer guard；失效 Assessment、Plan、unfinished downstream；`none` | 完整 |
| `themis-grounding · null/null · ready` | `understanding.md` → `themis-grounding/ready` | `requesting-capability` / `materialize-grounding-and-resume-continuation` | requesting continuation guard；无失效；`none` | 完整 |
| `themis-grounding · null/null · partial` | `understanding.md` → `themis-grounding/partial` | `requesting-capability` / `materialize-partial-grounding-and-resume-continuation` | partial 不等于 ready；无失效；`non-counted` | 完整 |
| `themis-grounding · null/null · blocked` | `understanding.md` → `themis-grounding/blocked` | `human-unblock` / `preserve-continuation-and-request-unblock` | blocker/continuation guard；无失效；`non-counted` | 完整 |
| `themis-complexity-assessment · null/null · simple-qualified` | `understanding.md` → `themis-complexity-assessment/simple-qualified` | 正常：`themis-simple-plan` / `materialize-assessment-and-select-simple`；guard failure：`themis-spec` / `materialize-assessment-preserve-sticky-full-and-select-full` | Guard `full_path_required == false`；failure 时失效 quick Plan、Plan Check、Review Projection/Check/Feedback/Approval、unfinished downstream；正常 `none`，guard failure `non-counted` | 正常与 sticky-full guard failure 均完整表达 |
| `themis-complexity-assessment · null/null · full-required` | `understanding.md` → `themis-complexity-assessment/full-required` | `themis-spec` / `materialize-assessment-and-set-sticky-full` | 设置 sticky full；失效 quick downstream；`non-counted` | 完整 |
| `themis-complexity-assessment · null/null · blocked` | `understanding.md` → `themis-complexity-assessment/blocked` | `human-unblock` / `preserve-continuation-and-request-unblock` | 不选择 path；无失效；`non-counted` | 完整 |

### Planning：20 个组合

| 旧 Capability/path/profile/status | 新规则 | `next` / 旧 control action | Guard、失效与 failure | 观察 |
|---|---|---|---|---|
| `themis-simple-plan · simple/lightweight · ready` | `planning.md` → `themis-simple-plan/ready` | `themis-plan-check` / `materialize-unified-plan-pair` | sticky full 必须 false；失效 Plan Check、Review Projection/Check/Feedback/Approval、unfinished downstream；`none` | 完整 |
| `themis-simple-plan · simple/lightweight · escalate-full` | `planning.md` → `themis-simple-plan/escalate-full` | `themis-spec` / `set-sticky-full-and-invalidate-quick-downstream` | sticky full；失效 quick downstream；`non-counted` | 完整 |
| `themis-simple-plan · simple/lightweight · blocked` | `planning.md` → `themis-simple-plan/blocked` | `human-unblock` / `preserve-continuation-and-request-unblock` | 无失效；`non-counted` | 完整 |
| `themis-spec · full/null · ready` | `planning.md` → `themis-spec/ready` | `themis-planning` / `bind-temporary-specification-handoff` | handoff 非 authority；无失效；`none` | 完整 |
| `themis-spec · full/null · needs-questioning` | `planning.md` → `themis-spec/needs-questioning` | `themis-q` / `return-to-questioning-and-invalidate-downstream` | 失效 Questioning、Assessment、Plan、unfinished downstream；`non-counted` | 完整 |
| `themis-spec · full/null · needs-grounding` | `planning.md` → `themis-spec/needs-grounding` | `themis-grounding` / `ground-and-resume-specification` | exact Specification continuation；无失效；`non-counted` | 完整 |
| `themis-spec · full/null · blocked` | `planning.md` → `themis-spec/blocked` | `human-unblock` / `preserve-continuation-and-request-unblock` | 无失效；`non-counted` | 完整 |
| `themis-planning · full/full · ready` | `planning.md` → `themis-planning/ready` | `themis-plan-check` / `materialize-unified-plan-pair` | 失效 Plan Check、Review Projection/Check/Feedback/Approval、unfinished downstream；`none` | 完整 |
| `themis-planning · full/full · needs-specification` | `planning.md` → `themis-planning/needs-specification` | `themis-spec` / `return-to-specification-and-invalidate-plan` | 失效 Plan、Plan Check、Review Projection/Check/Feedback/Approval、unfinished downstream；`non-counted` | 完整 |
| `themis-planning · full/full · needs-grounding` | `planning.md` → `themis-planning/needs-grounding` | `themis-grounding` / `ground-and-resume-planning` | exact Planning continuation；无失效；`non-counted` | 完整 |
| `themis-planning · full/full · blocked` | `planning.md` → `themis-planning/blocked` | `human-unblock` / `preserve-continuation-and-request-unblock` | 无失效；`non-counted` | 完整 |
| `themis-plan-check · simple/lightweight · pass` | `planning.md` → simple Plan Check `pass` | `themis-review-projection` / `materialize-plan-check-pass` | independent checker guard；无失效；`none` | 完整 |
| `themis-plan-check · simple/lightweight · needs-simple-planning` | `planning.md` → simple Plan Check `needs-simple-planning` | `themis-simple-plan` / `materialize-plan-check-and-return-to-simple-planning` | 失效 Plan、Plan Check、Review Projection/Check/Feedback/Approval、unfinished downstream；`non-counted` | 完整 |
| `themis-plan-check · simple/lightweight · escalate-full` | `planning.md` → simple Plan Check `escalate-full` | `themis-spec` / `materialize-plan-check-and-set-sticky-full` | sticky full；失效 quick downstream；`non-counted` | 完整 |
| `themis-plan-check · simple/lightweight · blocked` | `planning.md` → simple Plan Check `blocked` | `human-unblock` / `materialize-plan-check-and-request-unblock` | 不推进 Review；无额外失效；`non-counted` | 完整 |
| `themis-plan-check · full/full · pass` | `planning.md` → full Plan Check `pass` | `themis-review-projection` / `materialize-plan-check-pass` | independent checker guard；无失效；`none` | 完整 |
| `themis-plan-check · full/full · needs-planning` | `planning.md` → full Plan Check `needs-planning` | `themis-planning` / `materialize-plan-check-and-return-to-planning` | 失效 Plan、Plan Check、Review Projection/Check/Feedback/Approval、unfinished downstream；`non-counted` | 完整 |
| `themis-plan-check · full/full · needs-specification` | `planning.md` → full Plan Check `needs-specification` | `themis-spec` / `materialize-plan-check-and-return-to-specification` | 同上失效范围；`non-counted` | 完整 |
| `themis-plan-check · full/full · needs-grounding` | `planning.md` → full Plan Check `needs-grounding` | `themis-grounding` / `materialize-plan-check-ground-and-resume` | exact checker continuation；无失效；`non-counted` | 完整 |
| `themis-plan-check · full/full · blocked` | `planning.md` → full Plan Check `blocked` | `human-unblock` / `materialize-plan-check-and-request-unblock` | 不推进 Review；无额外失效；`non-counted` | 完整 |

### Review：24 个组合

| 旧 Capability/path/profile/status | 新规则 | `next` / 旧 control action | Guard、失效与 failure | 观察 |
|---|---|---|---|---|
| `themis-review-projection · simple/lightweight · ready` | `review.md` → simple Projection `ready` | `themis-review-check` / `materialize-review-projection-pair` | checked Plan binding；失效 Review Check/Feedback/Approval、unfinished downstream；`none` | 完整 |
| `themis-review-projection · simple/lightweight · blocked` | `review.md` → simple Projection `blocked` | `human-unblock` / `preserve-continuation-and-request-unblock` | 无失效；`non-counted` | 完整 |
| `themis-review-projection · full/full · ready` | `review.md` → full Projection `ready` | `themis-review-check` / `materialize-review-projection-pair` | checked Plan binding；同上失效；`none` | 完整 |
| `themis-review-projection · full/full · blocked` | `review.md` → full Projection `blocked` | `human-unblock` / `preserve-continuation-and-request-unblock` | 无失效；`non-counted` | 完整 |
| `themis-review-check · simple/lightweight · pass` | `review.md` → simple Review Check `pass` | `themis-review-dialogue` / `materialize-review-check-pass` | independent checker；无失效；`none` | 完整 |
| `themis-review-check · simple/lightweight · needs-projection` | `review.md` → simple Review Check `needs-projection` | `themis-review-projection` / `materialize-review-check-and-regenerate-projection` | 失效 Projection/Check/Feedback/Approval、unfinished downstream；`non-counted` | 完整 |
| `themis-review-check · full/full · pass` | `review.md` → full Review Check `pass` | `themis-review-dialogue` / `materialize-review-check-pass` | independent checker；无失效；`none` | 完整 |
| `themis-review-check · full/full · needs-projection` | `review.md` → full Review Check `needs-projection` | `themis-review-projection` / `materialize-review-check-and-regenerate-projection` | 同上失效；`non-counted` | 完整 |
| `themis-review-dialogue · simple/lightweight · continue` | `review.md` → simple Dialogue `continue` | `human-review` / `persist-review-dialogue-continuation` | 无失效；`non-counted` | 完整 |
| `themis-review-dialogue · simple/lightweight · approved` | `review.md` → simple Dialogue `approved` | `themis-impl` / `materialize-review-approval-pair` | unresolved feedback empty + Approval bindings；无失效；`none` | 完整 |
| `themis-review-dialogue · simple/lightweight · needs-current-request` | `review.md` → simple Dialogue `needs-current-request` | `themis-current-request-dialogue` / `materialize-review-feedback-and-return-to-current-request-dialogue` | 失效 Current Request、Questioning、Assessment、Plan、Plan Check、Review Projection/Check/Feedback/Approval、unfinished downstream；`non-counted` | 完整 |
| `themis-review-dialogue · simple/lightweight · needs-questioning` | `review.md` → simple Dialogue `needs-questioning` | `themis-q` / `materialize-review-feedback-and-return-to-questioning` | 失效 Questioning、Assessment、Plan、Plan Check、Review Projection/Check/Feedback/Approval、unfinished downstream；`non-counted` | 完整 |
| `themis-review-dialogue · simple/lightweight · needs-simple-planning` | `review.md` → simple Dialogue `needs-simple-planning` | `themis-simple-plan` / `materialize-review-feedback-and-return-to-simple-planning` | 失效 Plan、Plan Check、Review Projection/Check/Feedback/Approval、unfinished downstream；`non-counted` | 完整 |
| `themis-review-dialogue · simple/lightweight · needs-planning` | `review.md` → simple Dialogue `needs-planning` | `themis-spec` / `materialize-review-feedback-and-set-sticky-full` | sticky full；失效 quick downstream；`non-counted` | 完整 |
| `themis-review-dialogue · simple/lightweight · needs-specification` | `review.md` → simple Dialogue `needs-specification` | `themis-spec` / `materialize-review-feedback-and-set-sticky-full` | sticky full；失效 quick downstream；`non-counted` | 完整 |
| `themis-review-dialogue · simple/lightweight · needs-grounding` | `review.md` → simple Dialogue `needs-grounding` | `themis-grounding` / `materialize-review-feedback-ground-and-resume-owner` | owner continuation；无额外失效；`non-counted` | 完整 |
| `themis-review-dialogue · simple/lightweight · escalate-full` | `review.md` → simple Dialogue `escalate-full` | `themis-spec` / `materialize-review-feedback-and-set-sticky-full` | sticky full；失效 quick downstream；`non-counted` | 完整 |
| `themis-review-dialogue · full/full · continue` | `review.md` → full Dialogue `continue` | `human-review` / `persist-review-dialogue-continuation` | 无失效；`non-counted` | 完整 |
| `themis-review-dialogue · full/full · approved` | `review.md` → full Dialogue `approved` | `themis-impl` / `materialize-review-approval-pair` | Approval guard；无失效；`none` | 完整 |
| `themis-review-dialogue · full/full · needs-current-request` | `review.md` → full Dialogue `needs-current-request` | `themis-current-request-dialogue` / `materialize-review-feedback-and-return-to-current-request-dialogue` | 失效 Current Request 及全部受影响 downstream；`non-counted` | 完整 |
| `themis-review-dialogue · full/full · needs-questioning` | `review.md` → full Dialogue `needs-questioning` | `themis-q` / `materialize-review-feedback-and-return-to-questioning` | 失效 Questioning 及 downstream；`non-counted` | 完整 |
| `themis-review-dialogue · full/full · needs-planning` | `review.md` → full Dialogue `needs-planning` | `themis-planning` / `materialize-review-feedback-and-return-to-planning` | 失效 Plan 及 Review/downstream；`non-counted` | 完整 |
| `themis-review-dialogue · full/full · needs-specification` | `review.md` → full Dialogue `needs-specification` | `themis-spec` / `materialize-review-feedback-and-return-to-specification` | 同上失效；`non-counted` | 完整 |
| `themis-review-dialogue · full/full · needs-grounding` | `review.md` → full Dialogue `needs-grounding` | `themis-grounding` / `materialize-review-feedback-ground-and-resume-owner` | owner continuation；无额外失效；`non-counted` | 完整 |

### Delivery：31 个组合

| 旧 Capability/path/profile/status | 新规则 | `next` / 旧 control action | Guard、失效与 failure | 观察 |
|---|---|---|---|---|
| `themis-impl · simple/lightweight · implemented` | `delivery.md` → simple Impl `implemented` | `themis-verification` / `materialize-impl-result-pair` | current Approval/Plan task；失效 affected Verification evidence、Acceptance、Summary；`none` | 完整 |
| `themis-impl · simple/lightweight · needs-planning` | `delivery.md` → simple Impl `needs-planning` | `themis-spec` / `materialize-impl-result-and-set-sticky-full` | sticky full；失效 quick downstream；`non-counted` | 完整 |
| `themis-impl · simple/lightweight · escalate-full` | `delivery.md` → simple Impl `escalate-full` | `themis-spec` / `materialize-impl-result-and-set-sticky-full` | sticky full；同上失效；`non-counted` | 完整 |
| `themis-impl · simple/lightweight · blocked` | `delivery.md` → simple Impl `blocked` | `human-unblock` / `materialize-impl-result-and-request-unblock` | 不伪造 completed delta；无额外失效；`non-counted` | 完整 |
| `themis-impl · full/full · implemented` | `delivery.md` → full Impl `implemented` | `themis-verification` / `materialize-impl-result-pair` | current Approval/Plan task；失效 Verification evidence、Acceptance、Summary；`none` | 完整 |
| `themis-impl · full/full · needs-planning` | `delivery.md` → full Impl `needs-planning` | `themis-planning` / `materialize-impl-result-and-return-to-planning` | 失效 Plan/Check、Review Projection/Check/Feedback/Approval、unfinished downstream；`non-counted` | 完整 |
| `themis-impl · full/full · blocked` | `delivery.md` → full Impl `blocked` | `human-unblock` / `materialize-impl-result-and-request-unblock` | 无额外失效；`non-counted` | 完整 |
| `themis-verification · simple/lightweight · passed` | `delivery.md` → simple Verification `passed` | `themis-acceptance-dialogue` / `materialize-verification-pair` | independent Invocation/evidence；无失效；`none` | 完整 |
| `themis-verification · simple/lightweight · failed` | `delivery.md` → simple Verification `failed` | `themis-impl` / `materialize-verification-and-bounded-implementation-repair` | 同一 task budget；失效 Verification evidence、Acceptance、Summary；`counted` | 完整 |
| `themis-verification · simple/lightweight · needs-planning` | `delivery.md` → simple Verification `needs-planning` | `themis-spec` / `materialize-verification-and-set-sticky-full` | sticky full；失效 quick downstream；`non-counted` | 完整 |
| `themis-verification · simple/lightweight · needs-specification` | `delivery.md` → simple Verification `needs-specification` | `themis-spec` / `materialize-verification-and-set-sticky-full` | sticky full；同上失效；`non-counted` | 完整 |
| `themis-verification · simple/lightweight · escalate-full` | `delivery.md` → simple Verification `escalate-full` | `themis-spec` / `materialize-verification-and-set-sticky-full` | sticky full；同上失效；`non-counted` | 完整 |
| `themis-verification · simple/lightweight · blocked` | `delivery.md` → simple Verification `blocked` | `human-unblock` / `materialize-verification-and-request-unblock` | 不产生 passed；无额外失效；`non-counted` | 完整 |
| `themis-verification · full/full · passed` | `delivery.md` → full Verification `passed` | `themis-acceptance-dialogue` / `materialize-verification-pair` | independent evidence；无失效；`none` | 完整 |
| `themis-verification · full/full · failed` | `delivery.md` → full Verification `failed` | `themis-impl` / `materialize-verification-and-bounded-implementation-repair` | 同一 task budget；失效 Verification evidence、Acceptance、Summary；`counted` | 完整 |
| `themis-verification · full/full · needs-planning` | `delivery.md` → full Verification `needs-planning` | `themis-planning` / `materialize-verification-and-return-to-planning` | 失效 Plan/Check、Review/downstream；`non-counted` | 完整 |
| `themis-verification · full/full · needs-specification` | `delivery.md` → full Verification `needs-specification` | `themis-spec` / `materialize-verification-and-return-to-specification` | 同上失效；`non-counted` | 完整 |
| `themis-verification · full/full · blocked` | `delivery.md` → full Verification `blocked` | `human-unblock` / `materialize-verification-and-request-unblock` | 无额外失效；`non-counted` | 完整 |
| `themis-acceptance-dialogue · simple/lightweight · accepted` | `delivery.md` → simple Acceptance `accepted` | `themis-summary` / `materialize-human-acceptance-pair` | current Verification passed；无失效；`none` | 完整 |
| `themis-acceptance-dialogue · simple/lightweight · implementation-defect` | `delivery.md` → simple Acceptance `implementation-defect` | `themis-impl` / `materialize-acceptance-and-bounded-implementation-repair` | 同一 task budget、repair 后 re-Verification；失效 Verification evidence、Acceptance、Summary；`counted` | 完整 |
| `themis-acceptance-dialogue · simple/lightweight · needs-planning` | `delivery.md` → simple Acceptance `needs-planning` | `themis-spec` / `materialize-acceptance-and-set-sticky-full` | sticky full；失效 quick downstream；`non-counted` | 完整 |
| `themis-acceptance-dialogue · simple/lightweight · needs-specification` | `delivery.md` → simple Acceptance `needs-specification` | `themis-spec` / `materialize-acceptance-and-set-sticky-full` | sticky full；同上失效；`non-counted` | 完整 |
| `themis-acceptance-dialogue · simple/lightweight · escalate-full` | `delivery.md` → simple Acceptance `escalate-full` | `themis-spec` / `materialize-acceptance-and-set-sticky-full` | sticky full；同上失效；`non-counted` | 完整 |
| `themis-acceptance-dialogue · full/full · accepted` | `delivery.md` → full Acceptance `accepted` | `themis-summary` / `materialize-human-acceptance-pair` | current Verification passed；无失效；`none` | 完整 |
| `themis-acceptance-dialogue · full/full · implementation-defect` | `delivery.md` → full Acceptance `implementation-defect` | `themis-impl` / `materialize-acceptance-and-bounded-implementation-repair` | 同一 task budget、re-Verification；失效 Verification evidence、Acceptance、Summary；`counted` | 完整 |
| `themis-acceptance-dialogue · full/full · needs-planning` | `delivery.md` → full Acceptance `needs-planning` | `themis-planning` / `materialize-acceptance-and-return-to-planning` | 失效 Plan/Check、Review/downstream；`non-counted` | 完整 |
| `themis-acceptance-dialogue · full/full · needs-specification` | `delivery.md` → full Acceptance `needs-specification` | `themis-spec` / `materialize-acceptance-and-return-to-specification` | 同上失效；`non-counted` | 完整 |
| `themis-summary · simple/lightweight · ready` | `delivery.md` → simple Summary `ready` | `completed` / `materialize-summary-pair-and-complete-lifecycle` | passed + accepted gate；无 route invalidation；`none` | 完整表达 Summary 后 lifecycle completion observation 与 Intake retention |
| `themis-summary · simple/lightweight · blocked` | `delivery.md` → simple Summary `blocked` | `human-unblock` / `preserve-continuation-and-request-unblock` | 不完成 lifecycle；无失效；`non-counted` | 完整 |
| `themis-summary · full/full · ready` | `delivery.md` → full Summary `ready` | `completed` / `materialize-summary-pair-and-complete-lifecycle` | passed + accepted gate；无 route invalidation；`none` | 完整 |
| `themis-summary · full/full · blocked` | `delivery.md` → full Summary `blocked` | `human-unblock` / `preserve-continuation-and-request-unblock` | 不完成 lifecycle；无失效；`non-counted` | 完整 |

### Learning：12 个组合

| 旧 Capability/path/profile/status | 新规则 | `next` / 旧 control action | Guard、失效与 failure | 观察 |
|---|---|---|---|---|
| `themis-failure-learning · null/null · candidate-ready` | `learning.md` → null `candidate-ready` | `resume-scope-main-route` / `materialize-failure-learning-candidate` | scope-local linkage；无失效；`none` | 完整 |
| `themis-failure-learning · null/null · not-reusable` | `learning.md` → null `not-reusable` | `resume-scope-main-route` / `materialize-failure-learning-disposition` | 无失效；`none` | 完整 |
| `themis-failure-learning · null/null · needs-more-evidence` | `learning.md` → null `needs-more-evidence` | `resume-scope-main-route` / `retain-failure-learning-proposal` | 无失效；`non-counted` | 完整 |
| `themis-failure-learning · null/null · blocked` | `learning.md` → null `blocked` | `resume-scope-main-route` / `record-failure-learning-unavailable` | non-recursive；无失效；`non-counted` | 完整 |
| `themis-failure-learning · simple/lightweight · candidate-ready` | `learning.md` → simple `candidate-ready` | `resume-scope-main-route` / `materialize-failure-learning-candidate` | lifecycle scope-local linkage；无失效；`none` | 完整 |
| `themis-failure-learning · simple/lightweight · not-reusable` | `learning.md` → simple `not-reusable` | `resume-scope-main-route` / `materialize-failure-learning-disposition` | 无失效；`none` | 完整 |
| `themis-failure-learning · simple/lightweight · needs-more-evidence` | `learning.md` → simple `needs-more-evidence` | `resume-scope-main-route` / `retain-failure-learning-proposal` | 无失效；`non-counted` | 完整 |
| `themis-failure-learning · simple/lightweight · blocked` | `learning.md` → simple `blocked` | `resume-scope-main-route` / `record-failure-learning-unavailable` | non-recursive；无失效；`non-counted` | 完整 |
| `themis-failure-learning · full/full · candidate-ready` | `learning.md` → full `candidate-ready` | `resume-scope-main-route` / `materialize-failure-learning-candidate` | lifecycle scope-local linkage；无失效；`none` | 完整 |
| `themis-failure-learning · full/full · not-reusable` | `learning.md` → full `not-reusable` | `resume-scope-main-route` / `materialize-failure-learning-disposition` | 无失效；`none` | 完整 |
| `themis-failure-learning · full/full · needs-more-evidence` | `learning.md` → full `needs-more-evidence` | `resume-scope-main-route` / `retain-failure-learning-proposal` | 无失效；`non-counted` | 完整 |
| `themis-failure-learning · full/full · blocked` | `learning.md` → full `blocked` | `resume-scope-main-route` / `record-failure-learning-unavailable` | non-recursive；无失效；`non-counted` | 完整 |

### Invalid result、失败预算与 assurance

- `failure-control.md` 保存 Intake Execution Identity 与 lifecycle Plan Task Execution Identity 的隔离；各自第三次 counted failure 终止，禁止第四次 Invocation。
- Impl、Verification 和 Acceptance `implementation-defect` repair 共享同一 Plan Task Execution Identity/budget；simple→full、retry、restart、resume、model/worktree change 不清零。
- Counted/non-counted 分类、attempt-before-execution、observed failure、Failure Learning、third-failure/continuation 的 ordered actions 已保留。
- Invalid-result 的适用原因完整覆盖 zero/multiple match、unknown status、Invocation mismatch、invalid/stale/duplicate/late binding/result、wrong Profile/scope/path、quick-only status on full、illegal payload、competing terminal results、tool/command/Agent/result-contract failure 和 recorder/materialization failure。
- Invalid result 的 action 为 fail closed、拒绝 proposed result、记录 observed failure并进入 scope-local failure control；failure class 为 `counted`。
- `assurance-boundary.md` 保存三项 Plan 36 unavailable、四项 Plan 37 unavailable，以及没有 observed runtime 时禁止 transition claim，共八项 unavailable/forbidden 声明。

### 双向语义核对

#### 旧 YAML → 新 Markdown

- 98 个合法组合均在上述逐组合清单中有独立条目。
- 每项都记录新规则位置、next、旧 control action、guard/guard-failure、invalidation 和 failure class。
- Complexity Assessment `simple-qualified` 同时覆盖正常 simple path 与 sticky-full guard failure。
- 新 Policy 没有遗漏 Intake dormancy、Review-before-Impl、Verify 包含 Impl 与 independent Verification、Acceptance repair 共享 budget、Failure Learning 和 invalid-result。

#### 新 Markdown → 已批准来源

- `README.md` 和七个共享主题 references 的语义均可回溯到旧 `transitions.yaml` 或任务 2 的 current Plan 35 authority。
- 新增的 Markdown-first 表述只来自已批准 amendment：单一自然语言 Policy package、`record.md + content.md` 和自动 Go CLI 检查 `unavailable`。
- 未发现新 Capability、status、route、authority scope、Profile、failure budget、runtime、upgrade、migration mechanism 或 Plan 36/37 实现。
- 六个 route 文件没有使用固定 route table、JSON/YAML 片段、固定可解析行格式、Markdown DSL 或 parser instruction。

## 实施者核对

- Policy identity 仍为 `themis-core-control`，route decision identity 仍为 `capability + selected_path + profile + status`。
- `policies/README.md` 是唯一 entry，十三个 references 明确只是同一 Policy 的分片。
- 十六个 Capability、四个 Profile、双 scope、closed status/path/profile/failure vocabulary 均有唯一主题 owner。
- 98 个旧合法组合按 `3 + 8 + 20 + 24 + 31 + 12` 全部逐项映射；98 未写成产品常量或 runtime identity。
- 每个阶段文件有共同 current binding/stop 条件，每个合法 status 有独立中文 control sentence；只有 `simple-qualified` 存在特殊 guard-failure，并已完整保存 action、next、invalidation 和 failure class。
- Failure budget、invalid-result、八项 assurance、sticky full、completion retention 和 currentness/recovery 均已迁移。
- 旧 `transitions.yaml` 未删除或修改，留给任务 9 统一 cutover。
- 本任务未修改 Global Rule、公共 Skill、Capability、模板或 Workspace consumer，未启动 Plan 36/37。
- 未 commit、amend、push、reset、restore、clean 或 stash。

## fresh reviewer 核对

2026-08-01 的独立只读 reviewer 首轮返回 `Verdict: CHANGES_REQUIRED`，并独立确认：六阶段覆盖为 Intake `3/3`、Understanding `8/8`、Planning `20/20`、Review `24/24`、Delivery `31/31`、Learning `12/12`；十六个顶层主题、sticky-full、Intake dormancy、多目标 partial recovery、Review-before-Impl、独立 Verification、Acceptance repair 共享预算、第三次失败禁止第四次、Failure Learning、旧 invalid-result 原因和八项 assurance 均有覆盖；route 文件没有固定 table、JSON/YAML、Markdown DSL 或 parser instruction；旧 YAML 和消费者未提前 cutover。

Reviewer 提出一个 Medium finding：Policy entry 把 Invocation 前的 reference/package 缺失、冲突或无法唯一定位送入统一 counted invalid-result，会把宿主/Policy 可用性预检故障错误计入 scope-local failure budget，与“Invocation 前 observed unavailable 不创建伪 attempt”的既有合同冲突。

已修复：

- `policies/README.md` 明确 Invocation 前的 required reference/package unavailable 或 ambiguous 必须停在 last proven gate，不能创建 attempt，也不计入 failure budget；
- `failure-control.md` 区分 pre-invocation fail-closed 与 Invocation/result 处理后的 counted invalid-result；
- zero/multiple route match、Policy binding mismatch 和其他旧 invalid-result 原因仍在 Invocation 已开始或 result 返回后保持 counted。

2026-08-01 的 scoped re-review 返回 `Verdict: APPROVED`。Reviewer 确认：

- `policies/README.md` 与 `failure-control.md` 已明确区分 Invocation 前 Policy package/reference 预检故障和 Invocation/result 后的 invalid-result；
- Invocation 前 unavailable、ambiguous 或无法建立 observed Policy binding 时停在 last proven gate，不创建 attempt、不消耗 failure budget；
- Invocation 已开始或 proposed result 返回后的既有 invalid-result 原因仍为 `counted`，拒绝结果并进入 scope-local failure control；
- 修复与旧 `transitions.yaml` 及 current authority 的 failure/currentness 合同一致。

Reviewer 始终只读，未修改文件、commit 或 push。

## 未裁决 GAP

无。首轮唯一 Medium finding 已修复并通过 scoped re-review；自动 Go CLI 核验仍按下节明确记为 `unavailable`，不构成已实现保证。

## 自动 Go CLI 检查状态

`unavailable`。当前不存在已批准并已实现的 Themis Go CLI Policy/route parity 核验命令；未使用 Python、Shell 临时脚本或虚构子命令替代。
