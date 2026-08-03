# Templates 模板包

## 职责

Templates 为 immutable semantic revisions、结构化 Markdown records、operational evidence 与 human projections 提供 Prompt-level shape。它们降低格式漂移，但不创建事实、不计算 canonical digest、不校验 currentness、不执行 Policy，也不证明 persistence。

本目录中的分层 Markdown templates 是活动 Prompt-level 表示。它们定义结构与边界，但在静态证据、人工 replay 和用户明确重新接受前不得被描述为已重新验收；文件存在也不形成 machine authority。

## Artifact 分类

### Paired semantic artifacts 配对语义工件

每个 logical revision 使用不可分割的同 revision pair：

```text
<artifact-family>/<opaque-revision-id>/
  record.md
  content.md
```

十一类 paired family：

1. Current Request：`current-request/record.md` + `current-request/content.md`
2. Completed Questioning round：`questioning-round/record.md` + `questioning-round/content.md`
3. Unified Plan：`plan/record.md` + `plan/content.md`
4. Review Projection：`review-projection/record.md` + `review-projection/content.md`，stable family identity 仍为 `review`
5. Review Approval：`review-approval/record.md` + `review-approval/content.md`
6. Review Feedback：`review-feedback/record.md` + `review-feedback/content.md`
7. Impl Result：`impl-result/record.md` + `impl-result/content.md`
8. Verification：`verification/record.md` + `verification/content.md`
9. Human Acceptance：`acceptance/record.md` + `acceptance/content.md`
10. Summary：`summary/record.md` + `summary/content.md`
11. Failure Learning：`failure-learning/record.md` + `failure-learning/content.md`

任一 component 缺失，或 revision identity、content digest、authority scope、source binding、artifact binding 不一致，整个 logical revision invalid。不能保留或 current 化其中一个 half，也不能用单独 `content.md` 建立用户批准、技术结论或事实 authority。

### 结构化与 operational Markdown records

以下七类记录的 governed content 已是结构化字段，因此不制造空的 `content.md` half：

1. Intake Source Event：`request-intake/source-event.md`
2. Intake Proposal：`request-intake/proposal.md`
3. Intake Decision：`request-intake/decision.md`
4. Grounding：`grounding/record.md`
5. Complexity Assessment：`complexity-assessment/record.md`
6. Plan Check：`plan-check/record.md`
7. Review Check：`review-check/record.md`

这些记录仍需 stable identity、typed bindings、closed status、source references 与 observed materialization/reread；需要 currentness 的记录还必须有 separate pointer observation。结构化 Markdown 不等于 strict Schema 或 machine validation。

### 其他 operational 与 evidence records

Intake/lifecycle state、post-completion retention fact、Execution Identity、Invocation、attempt、raw Capability result、recorder result、current pointer、completion/incomplete marker、command evidence 与 Git observation 是 operational facts，不是 semantic artifact revisions。

Dormant retention fact 只能引用 immutable assignment 与 lifecycle completion observations；它不重写 assignment decision。Source Event 自身使用结构化 Markdown 保存 metadata、raw-byte reference 与 exact fragments，也不成为 paired lifecycle artifact。

### Context 辅助模板

- `context/resolution.md`：选择和排除受治理 Context，并记录 missing/stale/conflict/drift。
- `context/summary.md`：提出 source-bound governance candidate。

这两个文件只移动原 Context aid 的路径并改用自然语言 Markdown 字段；它们不是 lifecycle authority，不拥有 current pointer，也不能证明当前实现行为。

### Human projections 人类投影

Paired artifact 的 `content.md` 为人类呈现 governed semantics。Review Projection 是 checked Plan 的只读压缩投影，不是 execution contract；Summary 是 actual delivery 的 bound projection，不自行设置 completion。Human-readable file existence 永远不建立 authority。

## Identity 与物化规则

- Revision immutable，不原地替换。
- Artifact revision、Invocation identity、attempt identity、operation identity、current pointer 与 incomplete operation 是不同 identities。
- 所有必需 component 由同一 operation 完整写入并被 control layer 重读后，才可观察为 complete revision。
- Complete revision 可以在 pointer update 失败时存在但不 current；currentness 必须由 separate pointer update 与 reread evidence 证明。
- Symlink、目录顺序、filename、file existence 或 prose similarity 不建立 identity、replacement linkage、completion 或 currentness。
- Request Intake 的 disposition 与 `dormant-read-only` retention fact 分离；retention 不新增 disposition/status/route dimension。
- Template 中的 closed values 是 Prompt guidance，不是 Plan 36 strict Schema。

## Lifecycle 边界

- 只有 user-confirmed、Source Event-bound claims 可以进入 Current Request revision。
- `needs-questioning` 只保存 proposal 与 durable continuation；只有 `converged` 形成 completed Questioning pair。
- Temporary Specification 是 full-path handoff，不是 persistent artifact。
- Simple/full path 使用同一个 Plan family；不存在 `simple-plan` artifact。
- Approval 不修改 Plan 或 Review Projection；Feedback 也不能直接 patch 它们。
- Verify 固定为 `themis-impl → independent themis-verification`；两个 Invocation 共享同一 Plan Task Execution Identity 与 failure budget。
- Acceptance 的 `implementation-defect` repair 使用同一 identity/budget，且 repair 后必须再次 independent Verification。
- Summary 仅在 current Verification `passed` 与 current Human Acceptance `accepted` 后返回 `ready`；lifecycle completion 是 pair current 后的 separate observation。
- Failure Learning 与 Summary 只能提出 candidate，不能自动 publish knowledge；Learning failure 不递归也不阻塞 main route。

## 当前不可用保证

Strict Schema、canonicalization、validator output、deterministic digest、Policy evaluator、state recorder、Invocation host、atomic write runtime 与 machine currentness 均为 `unavailable`，直到后续获批计划提供已实现的 Themis Go CLI 能力。不得以 Python、Shell parser 或临时脚本替代。
