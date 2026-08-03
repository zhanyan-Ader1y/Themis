# Plan 35：Core Contract Replacement 实施计划

> 状态：用户曾于 2026-07-31 明确重新接受 replacement Plan 35，其产品语义继续作为本次表示重构的输入；2026-08-01 生效的 Markdown-first 规则使当时的 YAML 表示与旧核验证据不再足以证明当前合规。Markdown authority cutover、新静态证据、十六场景人工 replay 与 criteria 1–31 重映射已完成；criterion 32 保持 `PENDING USER RE-ACCEPTANCE`，Plan 36/37 继续暂停。

> 本次只重构表示与加载粒度，不重新设计 Intake、Capability、Review、Verify、Failure Learning、Workspace 或 lifecycle。2026-07-31 的重新接受仍是历史事实，不得改写为从未发生。

## 1. 权威设计

本次 Markdown 表示重构的唯一 Plan 35 产品语义输入是：

- `docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement-design.md`

2026-07-29 与 2026-07-30 的 Plan 35 设计及原实施计划仅保留为历史记录，不再是 current authority。

## 2. 目标

直接替换旧 lifecycle-first 合同，建立 Intake-first Core：

```text
external user message
→ immutable Source Event under Request Intake
→ themis-current-request-dialogue
→ explicit changed-only confirmation when semantics or assignment changes
→ policy-controlled materialization and reread
→ create or update lifecycle Current Request revisions
→ Questioning and optional Grounding
→ Complexity Assessment
   ├─ simple → Simple Plan → Lightweight Plan Check
   └─ full   → temporary Specification → Planning → Full Plan Check
→ Review Projection → Review Check → Review Dialogue → Review Approval
→ Verify [Impl → independent Verification]
→ Human Acceptance → Summary
```

Plan 35 只提供 Prompt-level 产品合同、模板结构、声明式政策和人工可重放语义，不提供 strict machine enforcement。

## 3. Markdown-first 固定架构

本节记录保持不变的 2026-07-31 产品语义及完成 cutover 后的活动表示：

- 一个公共 `themis` Skill；
- 一个常驻 Global Control Rule 与六个按 durable gate 加载的 references；
- 一个由 `templates/.themis/core/policies/README.md` 与 references 组成的自然语言 Policy；
- 两个隔离 authority scope：`request-intake`、`lifecycle`；
- 十六个固定 Capability；
- 四个固定 Agent Profile；
- route key 保持 `capability + selected_path + profile + status`；
- Capability Invocation Result 始终是 proposal，只有 Policy control action 完整持久化、记录完成观察、重读并更新独立 current pointer 后才形成 authority。

两个 scope 只能通过 stable references 关联，不能共享 Execution Identity、failure budget、continuation、current pointer、completion state 或动态状态。

## 4. Intake 与 Current Request

每条外部消息在任何 lifecycle 语义处理前形成 immutable Source Event。原始 bytes 不进行 Unicode 或换行归一化；claim fragment 使用 event identity、UTF-8 byte range 和 fragment digest 引用。

只有 active durable Intake-local confirmation 或 restart/unblock continuation 可以把新消息附加到已有 Intake；其他消息创建新 Intake。Intake disposition 仅为：

```text
open | assigned | rejected | abandoned
```

`dormant-read-only` 是 assigned Intake 在全部关联 lifecycle target 完成后的派生 retention mode，不是第五种 disposition、Capability status 或 route key 维度。进入休眠后 continuation 全部失活，Intake 不可附加、恢复、重激活、修改或调度 Invocation；Source Event、proposal、decision、target/completion observation 和历史绑定只读保留，未来消息创建新 Intake。

Current Request 由 user-confirmed、source-bound claims 组成。claim revision 不可变，disposition 为 `active | ambiguous | superseded`。任何 add、rewrite、supersede、ambiguity 或 assignment change 都必须展示 changed-only semantic diff，并获得逐项 `confirm | correct | keep-ambiguous` disposition；无语义或 assignment 变化时不重复确认。

## 5. Capability 与 Profile

固定 Capability：

1. `themis-current-request-dialogue`
2. `themis-q`
3. `themis-grounding`
4. `themis-complexity-assessment`
5. `themis-simple-plan`
6. `themis-spec`
7. `themis-planning`
8. `themis-plan-check`
9. `themis-review-projection`
10. `themis-review-check`
11. `themis-review-dialogue`
12. `themis-impl`
13. `themis-verification`
14. `themis-acceptance-dialogue`
15. `themis-failure-learning`
16. `themis-summary`

固定 Profile：

- `semantic-readonly`
- `independent-checker`
- `human-dialogue`
- `implementation-writer`

`themis-current-request-dialogue` 固定使用 `human-dialogue` 和 `request-intake` scope。它只返回 proposal 或结构化用户决定，不创建 lifecycle、不写治理状态、不执行 route，也不从沉默推断确认。

只有 `themis-impl` 使用 `implementation-writer`。Capability 与 Agent 都不能调用另一个 Capability 或 Agent，不能选择或扩张 Profile，不能把临时上下文变成 authority。

## 6. Immutable artifacts 与 Workspace

Paired semantic artifact 使用同一不可变 revision 下的两个 Markdown components：

```text
<artifact-family>/<opaque-revision-id>/
  record.md
  content.md
```

`record.md` 保存 identity、typed bindings、content digest、scope 与 materialization/currentness slots；`content.md` 保存 governed human semantics。任一 component 缺失或 identity/digest/bindings 不匹配时，整个 logical revision invalid。current pointer 与 revision creation 分离；不原地覆盖，不以 symlink、文件存在或叙述证明 currentness。

Questioning 每个已完成 exchange 形成一个不可变 pair：

```text
questioning/<round-revision>/
  record.md
  content.md
```

未回答问题保留在 durable proposal/continuation，不形成 completed round。

Workspace family roots：

```text
workspace/intakes/<intake-id>/
workspace/changes/<lifecycle-id>/
workspace/state/<lifecycle-id>/
workspace/runs/<lifecycle-id>/
workspace/evidence/<lifecycle-id>/
workspace/outcomes/<lifecycle-id>/
workspace/knowledge/intakes/<intake-id>/
workspace/knowledge/lifecycles/<lifecycle-id>/
```

`workspace/intakes/<intake-id>/state/` 保存 post-completion retention facts。Summary pair 完整物化并观察 lifecycle completion 后，policy 按 lifecycle identity 冻结所有匹配的 Intake target binding；每个多目标 Intake 只有在自身全部关联 lifecycle-bearing target 完成后才整体休眠，已完成 target 不影响未完成 target。

Fresh scaffold 只创建 family roots，不创建 literal example identity directories。

## 7. Review、Verify 与完成门禁

Review Projection 是 checked Plan 的绑定投影，不是第二执行合同。Review Dialogue 只生成 feedback 或 approval proposal；feedback 独立持久化并路由给语义 owner。Approval 批准 Plan，并绑定用户实际看到的 Review Projection、confirmed Intake assignment、Current Request claims、Questioning、checks、path/profile、sticky state 和 pre-Impl baseline。

Verify 固定为：

```text
themis-impl
→ independent themis-verification
```

Impl 与 Verification 使用不同 Invocation，但共享同一 Plan Task Execution Identity 和 failure budget。Verification current `passed` 后才能进入 Acceptance；Acceptance current `accepted` 后才能生成 Summary。

## 8. Failure 与恢复

Intake Execution Identity 与 lifecycle Plan Task Execution Identity 各自最多三次 counted failure；第三次终止对应 identity 并禁止第四次 Invocation。Intake failure 不创建或消耗 lifecycle budget。Impl 与 Verification 共享 lifecycle task budget。

每次 counted failure 记录后调用 scope-bound、非阻塞、非递归的 Failure Learning；同一 identity 或显式关联 replacement task 后续成功时再次调用。相似 prose 不建立关联。

恢复只读取 active durable Intake/lifecycle state、current pointers、markers、artifact components、Invocation/attempt records 和适用 Git facts，并只从 last proven gate 继续。`dormant-read-only` Intake 的历史记录只供来源/决定核验，不参与恢复、重激活或 Invocation。不得从聊天、Agent summary 或临时推理恢复，也不得自动 repair、rollback、merge 或推断完成。

## 9. 表示层次与剩余核验

活动合同层次：

```text
docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement-design.md
  + 同名 references
→ templates/.themis/core/kernel/orchestrator/rules.md
  + gate-specific references
→ templates/.themis/core/policies/README.md
  + shared-topic and phase-route references
→ sixteen Capability contracts + four Agent Profiles
→ layered templates using record.md/content.md or structured Markdown records
→ workspace/project.md + Workspace/Context references
```

Markdown authority cutover 已删除旧产品 YAML 与被目录结构替代的 flat templates。静态核验、十六场景人工 replay 与三十二条验收重映射已完成；唯一剩余门禁是：

1. 由用户审阅当前 `static-verification.md`、`manual-replay.md` 与十六个 scenario、`acceptance-audit.md`、`evidence-summary.md`；
2. 由用户明确决定是否重新接受当前 Markdown-first 表示；在此之前 criterion 32 保持 `PENDING USER RE-ACCEPTANCE`。

表示重构的详细执行计划位于：

- `docs/superpowers/plans/2026-08-01-plan-35-markdown-contract-refactor.md`

## 10. Verification strategy

### Static consistency

至少观察：

- 恰好一个公共 `themis` Skill；
- 恰好十六个内部 Capability stable identities；
- 每个 Capability 的 Profile/scope 映射唯一；
- 只有 `themis-impl` 使用 `implementation-writer`；
- 每个 Capability 声明 inputs、outputs、legal statuses、permissions、stop conditions 和 materialization target；
- 唯一自然语言 Policy package 是 route/control source；旧 YAML policy 只存在于冻结的历史记录；
- Global Rule 不复制第二状态表或领域推理；
- active guidance 不在 Intake 前创建 lifecycle；
- 不存在单一可变 `questioning.md`、artifact 原地覆盖或 Markdown-only authority；
- 不声称已有 Plan 36 validator、Plan 37 runtime、Plan 80 orchestration、upgrade 或 migration；
- `git diff --check` 通过。

### Manual replay

覆盖十六类场景：新请求确认、active no-change 恢复与 dormant 禁止复用、多 lifecycle assignment 逐 target 冻结/整体休眠、partial success、Questioning claim change、Review/Acceptance Intake interception、Review rework、sticky full、paired artifact failure、stale/duplicate/late/wrong Profile/scope、双预算隔离、shared Verify budget、Failure Learning、Summary/completion/retention gates、last-proven-gate recovery 与 dormant exclusion、rejection/abandonment/新 Intake。

每个 replay 记录 durable facts、Capability/Profile/scope、status、route、control action、materialized revisions、pointer/gate、invalidation、failure class 和缺失的 Plan 36/37 guarantees。

## 11. 计划边界

- Plan 36 在 Plan 35 重新接受后完整重基线，再单独批准；
- Plan 37 等待重新设计和接受后的 Plan 36；
- Plan 80/90 保持可选，只在各自启动时一次性重基线；
- 本计划不实现 strict Schema/validator/canonicalization、native runtime/recorder/evaluator、multi-Agent orchestration、analytics、compatibility、upgrade 或 migration。

## 12. 接受条件

批准设计的三十二条验收条件必须逐项映射到实际合同或观察证据。静态核验与十六类人工 replay 完成后，用户仍需审阅实际证据并明确重新接受；在该决定前 Plan 35 不恢复 current authority，Plan 36/37 保持暂停。
