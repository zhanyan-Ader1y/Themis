# 核验与重新接受

> 本文件属于 [Plan 35：Core Contract Replacement](../2026-07-31-plan-35-core-contract-replacement-design.md) 的功能 reference，拥有 Plan 35 核验策略、实施影响、completion/re-acceptance 和三十二条验收标准。它不是第二份设计权威。Plan 35 只验证 Prompt/template/Policy 产品合同，不声称当前存在 Go parser、validator、recorder 或 runtime enforcement。

## 静态一致性

实施后必须观察并报告：

- 恰好一个公共 `themis` Skill；
- 恰好十六个内部 Capability stable identities；
- 十六个 Capability 的 fixed Profile 映射唯一；
- 只有 `themis-impl` 使用 `implementation-writer`；
- 每个 Capability 声明 authority scope、inputs、outputs、legal statuses、permissions、stop conditions 和 materialization target；
- `templates/.themis/core/policies/README.md` 及其 references 共同构成唯一自然语言 route/control Policy；
- Global Rule 不维护第二状态表或领域推理；
- active guidance 不声称 lifecycle 在 Intake 前创建；
- 不存在单一可变 `questioning.md`、artifact 原地覆盖或 `content.md`-only authority；
- Workspace paths、artifact refs、Approval bindings 和 invalidation 一致；
- 不声称已有 Plan 36 validator、Plan 37 runtime、Plan 80 orchestration、upgrade 或 runtime migration；
- `git diff --check` 通过。

当前没有已批准且已实现的 Themis Go CLI 文档或合同验证命令。自动项目检查必须标记为 `unavailable`，不得用 Python、Shell 或临时脚本替代。Git 命令只提供版本控制观察，不构成 Themis machine enforcement。

## 人工重放

至少覆盖以下场景：

1. 新请求 → proposal → 明确确认 → 新 lifecycle；
2. 新消息完全匹配既有 claims → 无二次确认 → 恢复原 active continuation；dormant Intake 不可复用；
3. 一条消息显式分流到多个 lifecycle；单 target 完成只冻结自身，全部完成后才整体休眠；
4. 多目标 assignment 部分成功后恢复；
5. Questioning 回答改变 claim，只确认 changed diff；
6. Review/Acceptance 消息先经过 Intake，再恢复原 dialogue；
7. Review feedback 路由正确 owner，产生新 Plan，旧 Approval stale；
8. simple path 粘性升级到 full；
9. paired artifact 半写、digest mismatch 和 pointer 更新失败；
10. stale、duplicate、late、wrong-profile 或 wrong-scope Capability result；
11. Intake 三次失败不污染 lifecycle budget；
12. Impl/Verification 共享 lifecycle task budget 并在第三次终止；
13. failure 与显式关联 later success 均触发非阻塞 Failure Learning；
14. Verification/Acceptance gates 阻止提前 Summary；Summary 完整物化与 lifecycle completion observation 后触发 Intake retention 后置控制；
15. 中断后只从 last proven gate 恢复，dormant Intake 不参与恢复；
16. 明确 rejection 与宿主观察到的 abandoned，不从沉默推断；dormant Intake 后续消息创建新 Intake。

每个 replay 必须记录：

- initial durable facts；
- selected Capability/Profile/scope；
- proposed status；
- matched natural-language Policy rule；
- control action；
- materialized records/revisions；
- current pointer/gate；
- invalidation；
- failure class；
- 缺失的 Plan 36/37 machine guarantees。

## 实施影响

replacement 实施必须直接替换旧 Prompt contracts，不增加兼容层。

至少影响：

- Plan 35 active plan 与 plan index；
- Core package declarations；
- 唯一自然语言 Policy package；
- Global Control Rule；
- 唯一公共 `themis` Skill；
- Capability package 与新增 Current Request Dialogue contract；
- `themis-q`、Failure Learning 和 Profile contracts；
- artifact templates；
- Workspace project contract、README 与 scaffold；
- module README 和 installed guidance；
- static verification 与 manual replay evidence。

旧 Plan 35 两份设计文档保留为历史记录，但 active guidance 必须明确指向本文，不得继续把旧 fifteen-Capability、lifecycle-first 或 append-only single-file Questioning 模型当作 current。

## 完成与重新接受

replacement Plan 35 的产品语义曾按以下链路完成并于 2026-07-31 获得用户明确重新接受：

```text
design reviewed and approved
→ implementation plan reviewed and approved
→ Prompt/template/Policy/Workspace implementation
→ static consistency verification
→ manual replay evidence
→ user reviewed actual evidence
→ user explicitly re-accepted replacement Plan 35
```

2026-08-01 生效的 Markdown-first 规则只要求重构表示和加载粒度，不重新设计已接受产品语义。新的表示切换必须重新经过：

```text
Markdown authority candidates
→ Policy/Capability/template/Workspace cutover
→ new static consistency evidence
→ new manual replay evidence
→ user reviews actual Markdown-first evidence
→ user explicitly re-accepts current representation
```

在最后一步前：

- 2026-07-31 re-acceptance 继续作为历史产品语义事实；
- 新 Markdown 表示不宣称 current compliance 或 machine enforcement；
- Plan 36/37 继续暂停；
- Plan 80/90 不因本次表示重构启动或获得批准。

## 验收标准

1. 每条外部用户消息在任何 lifecycle 语义处理前形成 immutable Source Event；
2. 只有 active durable Intake-local confirmation 或 restart/unblock continuation 可以把新消息加入已有 Intake，其他消息一律创建新 Intake；`dormant-read-only` Intake 永不可附加；
3. Intake 在 assignment 前拥有独立 authority scope，且不创建 provisional lifecycle；
4. Source Event 原始 bytes 永久保留，claim fragment 可精确验证；
5. Current Request 由 user-confirmed、source-bound claims 构成；
6. claim/assignment 变化必须显示 changed-only semantic diff 并获得逐项明确 disposition；
7. 无 claim/assignment 变化时不要求重复确认；
8. 一条 Intake 可以显式创建或更新多个 lifecycle，partial success 可恢复且不自动 rollback；completed target 独立冻结，全部关联 lifecycle 完成后 Intake 才整体休眠；
9. 固定十六个 Capability，原十五个不被全面重组；
10. `themis-current-request-dialogue` 使用只读 `human-dialogue`，不直接持久化治理状态；
11. 保持四个 Agent Profile，不新增 governance writer；
12. 所有外部消息统一经过 Intake interception，并依据 durable continuation 恢复原对话；
13. 一个公共 Skill、一个 Global Rule 和一个自然语言 Policy package 保持唯一；
14. route key 保持 `capability + selected_path + profile + status`；
15. Capability result 只有经 Policy control、完整持久化和重读后才可物化为 authority；
16. paired semantic artifact 的 `record.md` 与 `content.md` 任一无效时，整个 revision invalid；
17. 所有逻辑 artifacts 使用 immutable revision 与独立 current pointer；Intake dormancy 是引用不可变 decision/completion observations 的独立 operational retention fact；
18. Questioning 使用 per-round immutable artifact，不再使用单一可变 append file；
19. attempt、artifact revision、pointer、incomplete operation 和 post-completion retention fact 保持不同概念；
20. Lifecycle state 只保存最小 refs 和控制事实，不复制 artifact semantics；Intake state 只保存 control/retention facts，不改写 source/decision semantics；
21. Review Projection 是 checked Plan 的绑定投影，Approval 批准 Plan 并绑定用户实际看到的 projection；
22. Review feedback 形成独立 record 并路由 owner，Review Dialogue 不 patch Plan；
23. Verify 固定为 Impl 后独立 Verification，共享 Plan task failure budget；
24. Verification、Acceptance 和 Summary 使用独立不可变 revisions 且 gates 不可绕过；Summary 完整物化与 completion observation 后才可执行 Intake dormancy 后置控制；
25. Intake 与 Lifecycle failure budgets 隔离，各自第三次 counted failure 终止对应 Execution Identity；
26. Failure Learning 支持两种 scope，但只产生非阻塞候选且不修改主流程；
27. duplicate、late、stale、wrong-profile、wrong-scope 或 incomplete result 不得成为 current；
28. interruption 只从 durable facts 和 last proven gate 恢复；`dormant-read-only` Intake 仅供历史核验，不参与恢复、重激活或 Invocation；
29. simple path 的 `full_path_required` 在 lifecycle 内 sticky；
30. Plan 35 不实现或声称 Plan 36/37/80/90 的能力；
31. 实施完成后，静态检查与十六类人工 replay 具有实际观察证据；
32. 用户审阅新的 Markdown-first 实际证据并明确重新接受前，Plan 35 不恢复 current representation authority。
