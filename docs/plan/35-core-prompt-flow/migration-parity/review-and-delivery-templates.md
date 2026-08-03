# Review、Delivery、Outcome 与 Learning 模板迁移核验

## 核验范围

本分片核验任务 6 把 Review Projection、Review Check、Review Approval、Review Feedback、Impl Result、independent Verification、Human Acceptance、Summary、Failure Learning 与两个 Context aid 的旧 YAML/flat Markdown 表示迁移为候选中文 Markdown templates。

候选文件尚未切换为 current authority；旧 YAML 与 flat Markdown sources 继续保留到任务 9 全局 cutover。本任务不修改 Capability 或 Policy route，不删除旧模板，不实现 validator、digest、recorder、pointer runtime 或 Plan 36/37 能力。

## 旧来源与候选目标

| 旧来源 | 候选目标 | Artifact class | 字段迁移观察 |
|---|---|---|---|
| `review.yaml` + `review.md` | `review-projection/record.md` + `content.md` | paired semantic artifact | 保留 stable family `review`、revision/lifecycle、checked Plan revision/content digest、Plan Check、path/profile、human projection、content binding、materialization、disposition 与 separate pointer；补齐 Current Request、sticky guard、Execution/Invocation/attempt、Capability/Profile、Policy/continuation、projection profile 与逐项 projection map |
| `review-check.yaml` | `review-check/record.md` | structured semantic record | 保留 checker identity、Plan/Plan Check/Review bindings、fidelity/presentation findings 与 materialization；补齐 Current Request、Execution/Invocation/attempt、Profile、projection map、path/profile、Policy/continuation 与 currentness observation |
| `review-approval.yaml` + `review-approval.md` | `review-approval/record.md` + `content.md` | paired semantic artifact | 保留 assignment decision、Current Request/claims、Questioning、constraints、Grounding/Assessment、path/profile/sticky、Plan/Plan Check、shown Review/Review Check、unresolved feedback、decision Source Event/time、pre-Impl baseline、content/materialization/disposition/pointer；补齐 Execution/Invocation/attempt、Capability/Profile、Plan/Review digests、Policy/continuation 与唯一 `approved` decision |
| `review-feedback.yaml` + `review-feedback.md` | `review-feedback/record.md` + `content.md` | paired semantic artifact | 保留 Source Event、shown Review、closed affected owner、`feedback-recorded`、owner continuation、content/materialization/disposition/pointer；补齐 exact fragments、Current Plan、path/profile、Execution/Invocation/attempt、Capability/Profile、Policy、grounding-needed 与 invalidation projection |
| `impl-result.yaml` + `impl-result.md` | `impl-result/record.md` + `content.md` | paired semantic artifact | 保留 Plan Task Execution Identity、Invocation/attempt、Approval/Plan/task、pre-Impl baseline、expected delta、status、actual changes、completion、deviations、drift、content/materialization/disposition/pointer；补齐 Current Request、Capability/Profile、allowed scope、remaining budget、path/profile/sticky、Policy/continuation、post-state 与 blocker/finding |
| `verification.yaml` + `verification.md` | `verification/record.md` + `content.md` | paired semantic artifact | 保留 shared task identity、independent Invocation/attempt、Approval/Plan/task、baseline、Impl Results、actual implementation delta、status/failure classification、assertions、commands/evidence、delta/drift、simple boundary、content/materialization/disposition/pointer；补齐 Current Request、Capability/Profile、expected delta、allowed commands、remaining budget、path/profile/sticky、Policy/continuation、coverage、residual risk 与 typed findings |
| `acceptance.yaml` + `acceptance.md` | `acceptance/record.md` + `content.md` | paired semantic artifact | 保留 Source Events、Current Request、Plan、Approval、Verification、closed status、acceptance view、preserved feedback、classification、content/materialization/disposition/pointer；补齐 exact fragments、actual delivered delta/evidence、shared task identity/budget、Invocation/attempt、Capability/Profile、path/profile/sticky、Policy/continuation 与 repair/re-Verification boundary |
| `summary.yaml` + `summary.md` | `summary/record.md` + `content.md` | paired semantic artifact | 保留 Current Request、Plan、Approval、Verification、Acceptance、delivery projection、optional candidates、content/materialization/disposition/pointer；补齐 Execution/Invocation/attempt、Capability/Profile、actual delta、current artifact revisions、source evidence、path/profile、Policy/continuation，以及 pair current 后 separate lifecycle completion observation |
| `failure-learning.yaml` + `failure-learning.md` | `failure-learning/record.md` + `content.md` | paired semantic artifact | 保留 request-intake/lifecycle scope、scope identity、Execution/Invocation/attempt、failure/main continuation/later success、candidate/disposition、content/materialization/disposition；补齐 fixed Capability/Profile、remaining budget、Policy/Learning continuation、path/profile domain、reuse boundary、redaction、governance destination；明确只有 `candidate-ready` 与 `not-reusable` 形成 pair |
| `context-resolution.md` | `context/resolution.md` | read-only Context aid | 路径移动并把原 fenced YAML output 改为中文 Markdown tables/fields；保留 selected/excluded、reason、missing/stale/conflict/context-code drift、unavailable 与“不能证明当前实现事实”边界，不增加 lifecycle authority |
| `context-summary.md` | `context/summary.md` | read-only Context aid | 路径移动并把原 fenced YAML candidate 改为中文 Markdown fields/tables；保留 source-bound metadata/body/uncertainties/governance handoff 与未持久化边界，不增加 approval、digest、Catalog 或 publication authority |

## 候选文件观察

任务计划要求的 19 个候选 Markdown 均已建立：

- `review-projection/record.md`
- `review-projection/content.md`
- `review-check/record.md`
- `review-approval/record.md`
- `review-approval/content.md`
- `review-feedback/record.md`
- `review-feedback/content.md`
- `impl-result/record.md`
- `impl-result/content.md`
- `verification/record.md`
- `verification/content.md`
- `acceptance/record.md`
- `acceptance/content.md`
- `summary/record.md`
- `summary/content.md`
- `failure-learning/record.md`
- `failure-learning/content.md`
- `context/resolution.md`
- `context/summary.md`

`templates/README.md` 同时列出十一类 paired family、七类结构化/operational Markdown records、两个 Context aids，以及 component mismatch 的整体 invalidation。

## Paired、structured 与 Context 边界

- Review Projection、Approval、Feedback、Impl Result、Verification、Acceptance、Summary 和 Failure Learning 使用同一 immutable revision 下的 `record.md + content.md`；加上任务 5 的 Current Request、Questioning 与 Plan，共十一类 paired family。
- Intake Source Event/proposal/decision、Grounding、Complexity Assessment、Plan Check 与 Review Check 是七类结构化 Markdown records，不机械生成空 `content.md` half。
- Review Projection `blocked`、Summary `blocked`、Failure Learning `needs-more-evidence | blocked` 不形成空 pair；只保存相应 blocker/proposal/continuation operational observation。
- Artifact revision、Invocation、attempt、operation、current pointer、incomplete operation 与 dormant retention fact 是不同 identity/fact。
- 任一 paired component 缺失，或 identity、digest、scope、source/artifact binding mismatch 时，整个 revision invalid。
- Context aids 只选择/压缩来源，不拥有 lifecycle authority、current pointer 或当前实现事实。

## Current contract 对旧模板的表示修正

本任务只做表示迁移，但旧 templates 有三项已落后于 current approved Plan 35 contracts；候选以 current design、Capability 与 natural-language Policy 为准：

1. `review-check.yaml` 使用旧成功状态 `passed` 并允许 `blocked`。Current `themis-review-check` 的唯一合法状态为 `pass | needs-projection`；缺少证据时停止，Invocation/tool/result failure 进入 counted invalid-result，不能包装为 `blocked`。
2. `summary.yaml` 使用旧 Capability status `completed | blocked`。Current `themis-summary` 使用 `ready | blocked`；`ready` pair 完整物化、重读并成为 current 后，Policy 才另行记录 lifecycle completion observation。
3. `failure-learning.yaml` 与旧 human half 把四个 Capability status 都放入 pair。Current Policy 只让 `candidate-ready | not-reusable` 形成 pair；`needs-more-evidence` 只保留 bound proposal/gaps，`blocked` 只记录 unavailable 并立即恢复 main route。

另外，旧 Review/Delivery records 未普遍保存 current Skill Result envelope 的 Capability、fixed Profile、Policy/continuation、path/profile、attempt、failure budget 和 direct evidence bindings；候选补齐这些已经批准的 current contract fields，不增加新产品能力。

## Review-before-Impl 与 Verify 链路核对

- Review Projection 只来自 current checked Plan；Review Check 只检查 fidelity、traceability 与 presentation burden。
- Review Dialogue feedback 必须先形成 immutable Review Feedback pair；七个合法 owner 为 `current-request-dialogue`、`questioning`、`specification`、`simple-planning`、`planning`、`plan-check`、`review-projection`。`grounding` 不是 owner。
- Approval 批准 checked Plan，并绑定用户实际看到的 Projection；只有完整物化、重读和 separate pointer observation 后才进入 Impl。
- Verify 固定为 `themis-impl → independent themis-verification`。两个 Capability 使用不同 Invocation/attempt，但共享同一 Plan Task Execution Identity 与 failure budget；writer 不验证自身。
- Verification `failed` 只表示 evidence-backed `implementation-defect`；hidden complexity 使用 `escalate-full`，semantic gaps 使用 `needs-planning | needs-specification`。
- Acceptance `implementation-defect` 只返回 current Approval 范围内 Impl repair，继续使用同一 identity/budget，并在 repair 后重新 independent Verification。
- Summary 仅在 current Verification `passed` 且 current Human Acceptance `accepted` 后返回 `ready`；candidate governance failure 不改变 passed/accepted actual delivery observations。

## Path/profile 状态核对

| Capability | `simple/lightweight` | `full/full` |
|---|---|---|
| `themis-review-projection` | `ready | blocked` | `ready | blocked` |
| `themis-review-check` | `pass | needs-projection` | `pass | needs-projection` |
| `themis-impl` | `implemented | needs-planning | escalate-full | blocked` | `implemented | needs-planning | blocked` |
| `themis-verification` | `passed | failed | needs-planning | needs-specification | escalate-full | blocked` | `passed | failed | needs-planning | needs-specification | blocked` |
| `themis-acceptance-dialogue` | `accepted | implementation-defect | needs-planning | needs-specification | escalate-full` | `accepted | implementation-defect | needs-planning | needs-specification` |
| `themis-summary` | `ready | blocked` | `ready | blocked` |
| `themis-failure-learning` | `candidate-ready | not-reusable | needs-more-evidence | blocked` | 同一 closed set；另有 Intake/null domain |

Review Approval 的唯一 decision 为 `approved`；Review Feedback artifact 的固定 status 为 `feedback-recorded`。Full path 不接受 `escalate-full`。

## 实施者核对

- 人工观察 19 个候选文件全部存在，修复后总计 1084 行；单文件最大为 `verification/record.md` 的 96 行。
- 候选文件没有 fenced YAML、旧 `<artifact>.yaml` pair authority 术语、`machine record`、route DSL/parser instruction、Python、临时 validator 或虚构 Go CLI 子命令。
- 候选通用说明标题使用中文；stable identities、字段名、Profile、status 与 operation 值按合同保留英文。
- `git diff --check` 对当前工作树退出 0；现有 LF/CRLF warning 不表示 whitespace error。
- 对九个旧 YAML、八个旧 paired human halves 与两个旧 Context aids 执行定向 `git diff --exit-code`，结果为空且 exit 0；旧 files 仍存在，本任务未删除、重命名或修改它们。
- 本任务未切换 Capability consumer、Workspace consumer 或 current authority，未启动 Plan 36/37，未 commit 或 push。

## Fresh reviewer 核对

首次独立只读 review 返回 `CHANGES_REQUIRED`，包含四个 High finding：

1. `impl-result/content.md` 无条件列出 `escalate-full`，可能让 `full/full` 产生 quick-only status。
2. `verification/content.md` 无条件列出 `escalate-full`，与 record/Policy 的 path-locked status domain 冲突。
3. `acceptance/content.md` 无条件列出 `escalate-full`，同样可能表示非法 full-path result。
4. `summary/record.md` 把 Summary current 后才产生的 lifecycle completion observation 写成 immutable pair 的后置必填字段，无法表示合法的“pair current、completion observation 尚待 Policy 记录”窗口，也违反独立 operational fact 边界。

逐项修复后：

- Impl Result、Verification 与 Acceptance content 均按 `simple/lightweight`、`full/full` 分列 closed status set，并明确 full path 禁止 `escalate-full`；
- Summary record 移除 completion observation 字段，明确它是 pair current 后由 Policy 另行记录且不得回写 immutable Summary revision 的 operational fact。

修复后的 scoped re-review 返回：

```text
Verdict: APPROVED
Findings: None
```

Reviewer 通过只读 `node_repl/js` 读取四个修正模板、迁移证据，以及相关 record、Delivery route、Capability 与 materialization/currentness 对照合同；确认三个 content half 的 path/profile 状态域已收窄，Summary completion 已与 immutable pair 分离，且 1084 行观察与首次 findings/fixes 记录一致。

## 未裁决 GAP

无。Task 6 候选模板已完成独立复核；它们仍只是候选表示，直到任务 9 全局 authority cutover 才能成为 current authority。

## 自动 Go CLI 检查状态

`unavailable`。当前仓库不存在已批准并已实现的 Themis Go CLI template-contract 核验命令；未使用 Python、Shell 临时脚本、临时 parser 或虚构子命令替代。Git、Glob、Grep 与 `wc` 只用于人工文件/版本控制观察，不构成 Themis machine enforcement。
