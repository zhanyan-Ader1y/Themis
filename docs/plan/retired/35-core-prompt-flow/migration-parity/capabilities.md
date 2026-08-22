# Capability 合同迁移核验

## 核验范围

本分片核验任务 7 把 `templates/.themis/core/capabilities/README.md` 与十六个内部 Capability 合同中的 fenced YAML result envelope 改写为 Markdown 字段合同。迁移保持十六个单文件，不创建十六个功能目录，不改变 Capability 的推理职责、权限、route ownership 或已接受产品语义。

本任务不删除 Task 9 之前仍须保留的旧模板/YAML authority，不切换 Workspace consumer，不实现 validator、Policy evaluator、recorder、Invocation host、digest/currentness runtime，也不启动 Plan 36/37。

## 迁移基线

迁移前人工观察：

- `templates/.themis/core/capabilities/` 共 17 个 Markdown 文件：一个 README 与十六个 Capability 合同。
- 17 个文件各含一个 fenced YAML block，共 17 个。
- 文件总计 1587 行。
- 唯一 authoritative binding 对照为 `templates/.themis/core/policies/references/capability-bindings.md`。
- Go CLI 自动合同检查为 `unavailable`；未使用 Python、临时 Shell parser 或虚构 Go CLI 子命令。

## Result envelope 表示迁移

README 使用 Markdown 表格逐字保留公共字段：

```text
capability
authority_scope
agent_profile
status
input_bindings
output.structured_result
output.proposed_artifact_references
output.materialization_target
diagnostics.gaps
diagnostics.evidence
diagnostics.affected_semantics
recommended_route
```

每个 Capability 的“输出字段合同”均：

1. 显式声明顶层 `capability`、`authority_scope`、`agent_profile` 与合法 `status`；
2. 使用 `Input bindings` 表逐项列出 identity、revision、Policy、continuation 和 path/profile bindings；
3. 使用 `Structured result` 表保留 Capability-specific nested fields；
4. 使用 `Artifact refs 与 materialization` 表声明 proposal refs 和 Invocation-bound expected target family；status-specific control action 仍只由唯一 Policy route 决定；
5. 使用 `Diagnostics 与 recommended route` 表保留 gaps、evidence、affected semantics 与 advisory route。

`recommended_route` 仍只供诊断，Global Rule 只能按唯一 Policy 的 exact route identity 选择 control action。

## 固定章节观察

十六个 Capability 文件均包含以下七个章节：

```text
身份与固定绑定
能力目标
输入
合法状态
输出字段合同
权限与边界
停止条件
```

每个“输出字段合同”均包含四个固定子节：

```text
Input bindings
Structured result
Artifact refs 与 materialization
Diagnostics 与 recommended route
```

## Capability-specific 字段保留

| Capability | Structured result 字段观察 |
|---|---|
| `themis-current-request-dialogue` | `operation`、`changed_only_diff`、`user_visible_diff`、`item_dispositions`、`assignment_operations`、`assignment_decision`、`confirmation_continuation`、`original_dialogue_continuation` |
| `themis-q` | `current_understanding`、`weak_points`、`questions`、`converged_why`、`converged_what`、`source_fragment_references`、`question_continuation`、`completed_round_content` |
| `themis-grounding` | `baseline`、`facts`、`blocked_by` |
| `themis-complexity-assessment` | `criteria`、`full_requirement_reasons` |
| `themis-simple-plan` | `plan_content`、`coverage_summary`、`not_applicable_evidence` |
| `themis-spec` | `handoff`、`fact_requests`、`request_conflicts` |
| `themis-planning` | `plan_content`、`alternatives_and_tradeoffs`、`fact_requests`、`coverage_summary` |
| `themis-plan-check` | `checks`、`plan_check_result` |
| `themis-review-projection` | `review_content`、`projection_map`、`diagram_rationale` |
| `themis-review-check` | `checks` |
| `themis-review-dialogue` | `presented_sections`、`expanded_plan_locations`、`preserved_user_feedback`、`classified_impact`、`affected_owner`、`owner_continuation`、`approval_subject`、`approval_decision_source_event_reference` |
| `themis-impl` | `actual_changes`、`completion_results`、`deviations`、`external_drift`、`command_evidence_references` |
| `themis-verification` | `assertions`、`commands_and_observations`、`expected_delta`、`actual_delta`、`external_drift`、`simple_boundary_check`、`failure_classification` |
| `themis-acceptance-dialogue` | `acceptance_view`、`preserved_user_feedback`、`observed_difference`、`classification_reason` |
| `themis-failure-learning` | `reuse_assessment`、`candidate`、`related_failure_and_success` |
| `themis-summary` | `summary_content`、`experience_candidates`、`project_knowledge_candidates` |

## Policy binding 交叉核对

| Capability | Scope / Profile | Path/profile 与 legal status | Materialization target 观察 |
|---|---|---|---|
| `themis-current-request-dialogue` | `request-intake` / `human-dialogue` | `null/null`: `needs-request-confirmation | assignment-confirmed | rejected` | Request Intake proposal/decision |
| `themis-q` | `lifecycle` / `human-dialogue` | `null/null`: `needs-questioning | converged` | Questioning proposal/round pair |
| `themis-grounding` | `lifecycle` / `semantic-readonly` | `null/null`: `ready | partial | blocked` | Grounding structured record |
| `themis-complexity-assessment` | `lifecycle` / `semantic-readonly` | `null/null`: `simple-qualified | full-required | blocked` | Complexity Assessment structured record |
| `themis-simple-plan` | `lifecycle` / `semantic-readonly` | `simple/lightweight`: `ready | escalate-full | blocked` | unified Plan pair |
| `themis-spec` | `lifecycle` / `semantic-readonly` | `full/null`: `ready | needs-questioning | needs-grounding | blocked` | temporary Specification handoff；无 semantic current pointer |
| `themis-planning` | `lifecycle` / `semantic-readonly` | `full/full`: `ready | needs-specification | needs-grounding | blocked` | unified Plan pair |
| `themis-plan-check` | `lifecycle` / `independent-checker` | simple 与 full 两组 closed status 分别锁定 | Plan Check structured record |
| `themis-review-projection` | `lifecycle` / `semantic-readonly` | simple/full: `ready | blocked` | Review Projection pair |
| `themis-review-check` | `lifecycle` / `independent-checker` | simple/full: `pass | needs-projection` | Review Check structured record |
| `themis-review-dialogue` | `lifecycle` / `human-dialogue` | simple 含 quick-only 状态；full 禁止 `needs-simple-planning | escalate-full` | dialogue continuation、Review Feedback pair 或 Review Approval pair |
| `themis-impl` | `lifecycle` / `implementation-writer` | simple 允许 `escalate-full`；full 禁止 | implementation delta 与 Impl Result pair |
| `themis-verification` | `lifecycle` / `independent-checker` | simple 允许 `escalate-full`；full 禁止 | Verification pair 与 evidence |
| `themis-acceptance-dialogue` | `lifecycle` / `human-dialogue` | simple 允许 `escalate-full`；full 禁止 | Human Acceptance pair |
| `themis-summary` | `lifecycle` / `semantic-readonly` | simple/full: `ready | blocked`；`completed` 非法 | Summary pair；completion observation 后置分离 |
| `themis-failure-learning` | `request-intake | lifecycle` / `semantic-readonly` | `null/null | simple/lightweight | full/full` 共用四个 closed status | expected target 固定为 `failure-learning-pair`；仅 `candidate-ready`/`not-reusable` 形成 pair，其余由 Policy 保留 proposal 或记录 unavailable |

交叉核对未通过新增 route 消解差异；stable identity、scope、Profile、path/profile、status 与 target 均以 `capability-bindings.md` 和对应 route reference 的 accepted contract 为准。

## 关键跨能力边界

- Review Projection 只压缩 current checked Plan；Review Check 只检查 fidelity、traceability 与 presentation burden。
- Review Dialogue 的 affected owner 只有 `current-request-dialogue | questioning | specification | simple-planning | planning | plan-check | review-projection`；Grounding 不是 owner。
- `themis-impl` 是唯一 `implementation-writer`，不返回 Verification verdict。
- Verify 固定为 `themis-impl → independent themis-verification`；两个 Invocation/attempt 不同，但共享同一 Plan Task Execution Identity 与 failure budget。
- Acceptance `implementation-defect` 保持同一 Plan Task Execution Identity/budget，返回 approved scope 内 Impl repair，并强制重新 independent Verification。
- Failure Learning scope-bound、non-blocking、non-recursive、candidate-only；不改变主 route、failure count 或 knowledge authority。
- Summary 只有 current Verification `passed` 且 current Human Acceptance `accepted` 后才可调用；Summary `ready` 不等于 lifecycle completion observation 已写入 immutable pair。

## 实施者机械观察

- 迁移后 17 个 Capability package 文件总计 1733 行。
- 定向搜索未发现 fenced YAML、旧 `## 输出` 或旧 `## 内部执行合同`。
- 十六个 Capability 各出现七个固定章节，共 112 个章节命中。
- 十六个 Capability 各出现四个固定输出子节。
- 定向搜索未发现 `full/full` 行包含 `escalate-full` 或 `needs-simple-planning`。
- `git diff --check -- templates/.themis/core/capabilities` 退出 0；仅有现有 LF→CRLF warning，没有 whitespace error。
- 当前 diff 只修改 Capability package 的 17 个既有 Markdown 文件；未删除旧模板、未执行 Task 9 authority cutover、未 commit、未 push。
- Git、Glob、Grep 与 `wc` 只用于人工文件/版本控制观察，不构成 Themis machine enforcement。

## Fresh reviewer 核对

首次独立只读 review 返回 `CHANGES_REQUIRED`，包含两个 High finding：

1. `capabilities/README.md` 把 `themis-q` 的 target 写成 question continuation，遗漏 accepted Questioning proposal target；
2. `capabilities/README.md` 的 `themis-review-dialogue` 行遗漏 durable Review Dialogue continuation，只列出 Review Feedback/Approval。

协调会话逐项对照 `capability-bindings.md`、Understanding/Review route 和各 Capability 合同后确认两项 finding，并在修复时额外发现两个表示漂移：公共 envelope 把 `materialization_target` 过强描述为 status-specific 唯一 target，Failure Learning 又为 `needs-more-evidence`/`blocked` 发明了旧 accepted contract 不存在的 target token。

逐项修复后：

- README 将 `themis-q` 对齐为 Questioning proposal 或 paired Questioning round；
- README 将 Review Dialogue 对齐为 durable dialogue continuation、Review Feedback pair 或 Review Approval proposal；
- 公共 `output.materialization_target` 明确为 Invocation-bound expected target family，status-specific control action 仍只由 Policy route 决定；
- Failure Learning 恢复固定 `failure-learning-pair` expected target，不再使用新增 token；只有 `candidate-ready`/`not-reusable` 形成 pair，`needs-more-evidence`/`blocked` 仍由 Policy 保留 proposal 或记录 unavailable。

修复后的 scoped read-only re-review 读取 Capability README、三个相关 Capability、binding、Understanding/Review/Learning route、Invocation/materialization reference 与 Task 7 计划，返回：

```text
Verdict: APPROVED
Findings: None
```

## 未裁决 GAP

无。Task 7 Capability 合同已完成独立复核；这些 Markdown 合同仍是候选表示，直到任务 9 全局 authority cutover 才能成为 current authority。

## 自动 Go CLI 检查状态

`unavailable`。当前仓库不存在已批准并已实现的 Themis Go CLI capability-contract 核验命令；未使用 Python、临时 Shell parser、临时 validator 或虚构子命令替代。
