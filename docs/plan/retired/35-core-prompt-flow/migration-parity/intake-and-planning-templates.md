# Intake、需求与 Planning 模板迁移核验

## 核验范围

本分片核验任务 5 把 Request Intake、Current Request、completed Questioning round、Grounding、Complexity Assessment、unified Plan 与 Plan Check 的旧 YAML/flat Markdown 表示迁移为候选中文 Markdown templates。候选文件尚未切换为 current authority；旧文件继续保留到任务 9 全局 cutover。

本任务不修改 Capability、Workspace consumer 或 Policy route，不删除旧模板，不实现 validator、digest、recorder、pointer runtime 或 Plan 36/37 能力。

## 旧来源与候选目标

| 旧来源 | 候选目标 | Artifact class | 字段迁移观察 |
|---|---|---|---|
| `request-intake-source-event.yaml` | `request-intake/source-event.md` | operational source-event record | 保留 template/record/scope、event/Intake identities、observed time、transport、actor、raw bytes path/digest/length、`normalization: none`、三种 attachment mode、continuation、reason 与完整 materialization observation |
| `request-intake-proposal.yaml` | `request-intake/proposal.md` | structured semantic proposal | 保留 Intake/Execution/Invocation、Capability/Profile/status、Source Event refs、changed-only claims、assignment targets、item dispositions、fragment byte ranges、full diff digest 与 materialization；补齐 current Capability envelope 的 attempt identity，并显式保存原 lifecycle-bearing Source Event/exact fragments/continuation |
| `request-intake-decision.yaml` | `request-intake/decision.md` | structured semantic decision | 保留 Intake/Execution/Invocation/attempt、原 lifecycle-bearing Source Event/continuation、per-target operation/status/observation、remaining targets、resume-only recovery、rejection fragments 与 materialization；按 current contract 显式区分 `confirmation-decision`、`no-change` 与 `rejection`，并为三类 operation 分别绑定 proposal/confirmation、unchanged conclusion 或 rejection Source Event |
| `current-request.yaml` + `current-request.md` | `current-request/record.md` + `content.md` | paired semantic artifact | record 保留 family/revision/lifecycle/assignment decision/prior revision、claim revision/disposition/relation/source fragments、content path/digest、materialization、disposition 与 separate pointer observation；content 仅呈现 source-bound active/ambiguous/superseded claims |
| `questioning-round.yaml` + `questioning-round.md` | `questioning-round/record.md` + `content.md` | paired semantic artifact | 保留 previous round、question proposal、dialogue continuation、answer Source Events、post-answer Current Request、status、content binding、materialization、disposition 与 pointer；content 保留 pre-answer understanding、weak points/questions、answers、Why/abstract What 与 diagnostics |
| `grounding.yaml` | `grounding/record.md` | structured semantic record | 保留 identities、Capability/Profile、`ready | partial | blocked`、Current Request/Questioning/fact requests/baseline、逐 assertion conclusion/evidence、continuation 与 materialization；补齐 requesting Capability、Policy/path/profile 与 attempt bindings，并区分 command evidence |
| `complexity-assessment.yaml` | `complexity-assessment/record.md` | structured semantic record | 保留 identities、Capability/Profile、`simple-qualified | full-required | blocked`、Current Request/Questioning/Grounding/sticky guard、simple evidence、path proposal 与 materialization；补齐 constraints、Policy/continuation/path/profile 与 attempt bindings |
| `plan.yaml` + `plan.md` | `plan/record.md` + `content.md` | paired semantic artifact | record 保留 unified Plan 的 Current Request/claims/Questioning/constraints/Grounding/Assessment/path/profile/sticky/handoff/baseline、content binding、materialization、disposition 与 pointer，并补齐 confirmed assignment decision；content 保留目标、范围、flow、contracts、acceptance、facts、assumptions、trade-offs、impact、failure/recovery、Impl/Verification tasks 与四类 authority coverage |
| `plan-check.yaml` | `plan-check/record.md` | structured semantic record | 保留 checker identities、Plan/Request/Questioning/Assessment/baseline、findings 与 materialization；按 current Policy/Capability 拆开 `simple/lightweight` 和 `full/full` 合法状态，补齐 Plan digest、constraints、Grounding、temporary handoff、Policy/continuation 与 attempt bindings |

## 候选文件观察

任务计划要求的 12 个候选 Markdown 均已建立：

- `request-intake/source-event.md`
- `request-intake/proposal.md`
- `request-intake/decision.md`
- `current-request/record.md`
- `current-request/content.md`
- `questioning-round/record.md`
- `questioning-round/content.md`
- `grounding/record.md`
- `complexity-assessment/record.md`
- `plan/record.md`
- `plan/content.md`
- `plan-check/record.md`

逐文件使用中文标题、自然语言说明与“字段｜必填性｜合法值/格式｜来源或绑定｜语义”字段合同；嵌套 item、fragment、target、fact、condition、task 和 finding 使用独立子表，没有折叠为泛化 metadata/details。

## Paired 与 structured 边界

- Current Request、completed Questioning round 和 unified Plan 使用同一 immutable revision 下的 `record.md + content.md`；两部分任一缺失或 identity/digest/scope/binding mismatch 时整个 revision invalid。
- Request Intake Source Event/proposal/decision、Grounding、Complexity Assessment 与 Plan Check 使用独立 Markdown record，不机械生成无语义 content half。
- Unanswered question 只存在于 durable proposal/continuation，不形成 completed Questioning revision。
- Temporary Specification handoff 只作为 full-path Plan binding，不成为 persistent artifact 或恢复 authority。
- 所有 current pointer 都是 separate operational observation；revision 存在不能证明 pointer 已更新。

## Current contract 对旧模板的表示修正

本任务只做表示迁移，但旧模板已有少量字段/状态落后于 current approved Plan 35 contracts，因此候选以 current authority、Policy 和 Capability 为准：

1. `plan-check.yaml` 的成功状态为旧值 `passed`，且把 quick/full 状态合并；候选按 current `themis-plan-check` 与 natural-language Policy 使用：
   - `simple/lightweight`: `pass | needs-simple-planning | escalate-full | blocked`
   - `full/full`: `pass | needs-planning | needs-specification | needs-grounding | blocked`
2. 旧 structured result templates 未普遍保存 current Skill Result envelope 的 `attempt_identity`；候选在 Intake proposal/decision、Grounding、Assessment 与 Plan Check 中补齐 scope-local attempt binding。
3. 旧 Intake templates 未显式保存“confirmation Source Event 不替代原 lifecycle-bearing Source Event”的完整 binding；候选保存原 Source Event identity、exact fragments 与原 durable continuation。
4. 旧 Plan record 没有 typed `confirmed Intake assignment decision` 字段；候选 record 与 content binding 保持一致并显式记录。

这些修正不增加新产品能力，只使候选表示与已经批准并在任务 2–4 迁移的 current contract 一致。

## 实施者核对

- 人工观察 12 个候选文件全部存在，总计 758 行；单文件最大为 `plan/content.md` 的 99 行。
- 候选文件没有 fenced YAML、route DSL、parser instruction、Python、临时 validator 或 Go CLI 虚构子命令。
- 通用 Markdown 标题使用中文；stable identities、字段名、Profile、status 与 operation 值按合同保留英文。
- `git diff --check` 对本任务候选目录与证据文件成功。
- 对 12 个旧 YAML/flat Markdown 来源执行定向 `git diff --exit-code`，结果为空且 exit 0；旧文件仍存在，本任务未删除、重命名或修改它们。
- 本任务未切换 Templates README、Capability consumer、Workspace consumer 或 current authority，未启动 Plan 36/37，未 commit 或 push。

## Fresh reviewer 核对

首次独立只读 review 返回 `CHANGES_REQUIRED`，包含五个 Medium 与一个 Low finding：

1. Intake proposal 只有 Source Event/fragment 引用，缺少用户实际确认所需的短原文、旧/新语义、affected lifecycle 和完整 changed-only 精简视图。
2. Intake decision 的 proposal/confirmation bindings 被无条件要求，无法合法表示 `no-change` 与明确 `rejection`。
3. Questioning pair 允许 `needs-questioning`，与“只有 converged 才能形成 completed pair”冲突。
4. Plan Check 缺少供 exactly-one Policy rule 匹配的唯一 `Status` 字段。
5. Grounding 与 Complexity Assessment 的 `blocked` 缺少 observed blocker、human-unblock requirement 与 preserved continuation；同类核验还发现 Plan Check 需要相同 blocker record。
6. 首次证据中的 702 行观察已因 reviewer 修复而失效。

逐项修复后：

- proposal 的 claim/assignment diff item 记录 stable item identity、短原文引用、旧/新 semantic、affected lifecycle、Source fragments 与 allowed dispositions，并把完整 user-visible concise diff 绑定到 full diff digest；
- decision 显式区分 `confirmation-decision | no-change | rejection`，按 operation 条件化 proposal/confirmation/rejection bindings；`no-change` 保存 current assignment/Request/unchanged conclusion，`rejection` 强制 lifecycle operations 为空；
- completed Questioning pair 的唯一合法状态改为 `converged`，`needs-questioning` 只保留 proposal/continuation；
- Plan Check 新增唯一 required `Status` 字段，并保留 path/profile-specific closed status sets；
- Grounding、Assessment 与 Plan Check 均新增 `blocked` 专属 blocker record，禁止把 evidence gap 或执行失败伪装为 blocker；
- fresh 人工计数为 758 行，候选纯英文说明标题已改为中文，stable contract values 未翻译。

同一独立 reviewer 的 scoped re-review 返回 `Verdict: APPROVED`、`Findings: None`。Reviewer 确认上述五个 Medium finding、Low 行数误差与同类 Plan Check blocker record 已正确闭合，且修复未引入新的 load-bearing contract gap。

## 未裁决 GAP

无。Task 5 候选模板已完成独立复核；它们仍只是候选表示，直到任务 9 全局 authority cutover 才能成为 current authority。

## 自动 Go CLI 检查状态

`unavailable`。当前仓库不存在已批准并已实现的 Themis Go CLI template-contract 核验命令；未使用 Python、Shell 临时脚本、临时 parser 或虚构子命令替代。Git、Glob、Grep 与 `wc` 只用于人工文件/版本控制观察，不构成 Themis machine enforcement。
