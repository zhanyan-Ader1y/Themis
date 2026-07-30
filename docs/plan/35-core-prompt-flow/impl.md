# Plan 35：Core Prompt Flow 实施计划

> 状态：已批准实施，正在完成最终静态核验与用户接受。

## 1. 目标

将 Themis Core 建立为 Prompt-first 双路径生命周期，并完成以下控制架构：

```text
one public themis Skill
→ one always-loaded Global Control Rule
→ transitions.yaml selects one internal Capability
→ one fixed Agent Profile
→ one temporary Agent invocation
→ Capability Invocation Result
→ exactly one legal route
```

Plan 35 只提供 Prompt-level 合同、声明式政策、模板结构与人工可重放语义；不实现 Plan 36 strict assurance、Plan 37 runtime、Plan 80 multi-Agent 或 Plan 90 analytics。

## 2. 权威设计

- `docs/superpowers/specs/2026-07-29-plan-35-core-prompt-flow-design.md`
- `docs/superpowers/specs/2026-07-30-plan-35-policy-capability-execution-design.md`

若本文与批准设计冲突，以批准设计为准。

## 3. 生命周期

```text
Current Request
→ Questioning
→ Complexity Assessment
   ├─ simple → Simple Plan → Lightweight Plan Check
   └─ full   → temporary Specification → Planning → Full Plan Check
→ Review Projection → Review Check → Human Review → Review Approval
→ Verify [Impl → independent Verification]
→ Human Acceptance
→ Summary
→ optional governed knowledge candidates
```

- 两条路径生成同一个 Plan，并在 Plan Check 后汇合。
- Review 必须发生在 Impl 前。
- Impl 与 Verification 是不同 invocation，但共享 approved Plan task identity 与累计三次失败预算。
- Summary 只允许在 current Verification `passed` 且 Human Acceptance `accepted` 后生成。
- Specification 只在 full path 中形成临时、非持久、非权威 handoff。

## 4. 实施结构

### 4.1 最小 Core identity

`templates/.themis/core/core.yaml` 只包含：

```yaml
schema: themis-core
workspace_schema: themis-workspace
artifact_schema: themis-artifact
```

不得增加功能版本、兼容矩阵、upgrade 或 migration 字段。

### 4.2 一个公共 Skill

`templates/.claude/skills/themis/SKILL.md` 是唯一注册到 Claude Code 环境的 Themis project Skill。它只负责启动、继续或从实际记录恢复 lifecycle 控制，不拥有任何领域语义或 route。

### 4.3 十五个内部 Capability

`templates/.themis/core/capabilities/` 保存：

1. `themis-q`
2. `themis-grounding`
3. `themis-complexity-assessment`
4. `themis-simple-plan`
5. `themis-spec`
6. `themis-planning`
7. `themis-plan-check`
8. `themis-review-projection`
9. `themis-review-check`
10. `themis-review-dialogue`
11. `themis-impl`
12. `themis-verification`
13. `themis-acceptance-dialogue`
14. `themis-failure-learning`
15. `themis-summary`

Capability 不使用 Skill frontmatter，不提供公共调用入口，不调用其他 Capability 或 Agent，不拥有 lifecycle state、route、persistence 或权限扩张。

### 4.4 四个固定 Agent Profile

`templates/.themis/core/agent-profiles/` 保存：

- `semantic-readonly`
- `independent-checker`
- `human-dialogue`
- `implementation-writer`

每个 Capability 在 `transitions.yaml` 中恰好绑定一个 Profile。只有 `implementation-writer` 可以修改项目实现；Profile 不拥有语义或 route。

### 4.5 唯一路由政策

`templates/.themis/core/policies/transitions.yaml` 是 `capability + selected_path + profile + status` 的唯一声明源，并包含：

- 十五个固定 Capability/Profile 映射；
- 91 条唯一合法 route；
- closed vocabularies；
- simple/full、sticky-full、continuation、currentness 与 persistence guards；
- global `invalid_result`；
- shared three-failure control；
- unavailable machine-assurance 声明。

Global Rule 只解释政策，不复制 Capability-specific `status → next/action`。

## 5. 权威与工件边界

- Current Request Revision 拥有交付目标语义。
- governed design constraints 只限制方案。
- 代码、配置、Schema 与 observed executable behavior 是当前实现事实的唯一来源。
- unified Plan 是首个持久执行合同。
- `review.md` 是 checked Plan 的只读压缩投影，不是 Impl 输入。
- Workspace 记录只有在对应操作被观察后才能证明 lifecycle 事实。
- Context、Themico、经验、文档、Plan prose、Summary、Agent reasoning 与聊天不能替代当前实现证据。

不存在持久 `spec.yaml`、`spec.md`、Specification approval、第二种 Plan 或独立 Delivery stage。

## 6. Workspace 与隔离

```text
workspace/changes/<lifecycle-id>/   Request、Questioning、Plan、Review、Approval
workspace/state/<lifecycle-id>/     current gate、pointer、attempt、invalidation、incomplete operation
workspace/runs/<lifecycle-id>/      invocation metadata
workspace/evidence/<lifecycle-id>/  direct facts、commands、outputs、coverage
workspace/outcomes/<lifecycle-id>/  Acceptance、Summary
workspace/knowledge/                candidates 与治理 disposition
```

多个 lifecycle 可以共享同一只读 policy identity/digest，但动态状态、continuation、worktree identity、attempt、artifacts、evidence 与 outcomes 必须 lifecycle-scoped。

## 7. Worktree 与最小写入安全

- mutating invocation 绑定 lifecycle、Task Execution、Invocation、worktree、allowed paths、pre-Impl baseline 和 expected state。
- 并发时一个写入任务独占一个 worktree；缺少独占能力时只能串行唯一 writer，否则 fail closed。
- 写前重新核验 path、bindings、baseline 与 expected state。
- 适用时先完整写同目录临时文件，再原子替换单个目标。
- 关键多步写入使用 completion/incomplete marker；完成前重读文件、Git status/diff 与记录。
- 中断后只从最后已证明 gate 继续，不根据部分文件推断成功。

Plan 35 不实现或声称跨 worktree 锁、通用事务、rollback journal、自动恢复、跨 worktree 合并或冲突裁决。

## 8. Failure、Review 与完成门禁

- 每个 counted failure 先记录 attempt，再非阻塞调用 Failure Learning，最后执行正常 route 或第三次终止 override。
- Agent restart、model change、retry、resume 或 sticky escalation 不重置计数。
- Review Approval 绑定 Current Request、Questioning、constraints、Assessment、path/profile、Plan、checks、projection 和 pre-Impl baseline。
- expected approved delta 不使 Approval 自行 stale；external drift 必须停止并重新核验。
- Failure Learning 与 Summary 只能生成治理候选，不能发布知识或改变原 lifecycle 结果。

## 9. 实施任务

1. 最小化 Core identity。
2. 建立十五个内部 Capability，并移除十五个公共 lifecycle Skills。
3. 建立四个 Agent Profile 和固定映射。
4. 建立唯一公共 `themis` Skill。
5. 将 `transitions.yaml` 完成至 91 条唯一 route。
6. 将 Global Rule 收缩为通用 policy interpreter。
7. 对齐 Workspace、templates、module READMEs 与安装 guidance。
8. 清理 Attribution 旧术语。
9. 声明 worktree 与最小写入安全边界。
10. 对齐 Plans 36、37、80、90 的未来职责。
11. 执行静态一致性验证和人工 replay。
12. 将实际证据交给用户并获得 Plan 35 单独接受。

## 10. 最终验证

必须实际观察并报告：

- Core identity 恰好 3 个字段；
- 公共 Skill 恰好 1 个；
- 内部 Capability 恰好 15 个；
- Agent Profile 恰好 4 个；
- 固定映射 15/15；
- 只有 `implementation-writer` 可写项目实现；
- route 91 条且 key 91 个唯一；
- route statuses 与 Capability contracts 完全一致；
- Global Rule 无 Capability-specific route table；
- YAML 可解析；
- active guidance 无旧公共 Skill、持久 Spec、Delivery、Shell fallback、功能版本、upgrade/migration、通用 transaction/lock/recovery 声明；
- simple/full happy path、Grounding、Review rework、sticky escalation、invalid result、shared failure budget、Acceptance/Summary gates、多 lifecycle isolation 与 interruption boundary replay 通过；
- `git diff --check` 通过；
- 现有 dirty-tree 修改未被覆盖、恢复或丢弃。

没有 Plan 36 validator 或 Plan 37 runtime 时，验证结论只能是 Prompt-level 静态一致与人工 replay 通过，不能声称 machine enforcement。

## 11. 接受条件

- 两份批准设计的全部验收条件均映射到当前文件与实际验证证据。
- 旧 Spec-first、十五公共 Skills、重复 route ownership、独立 Delivery 和 broad transaction/recovery 模型已从 active path 移除。
- Plan 36/37/80/90 能力没有被提前实现或虚构。
- 用户审阅最终证据并明确接受 Plan 35 后，本计划才完成；Plan 36 仍需单独授权。
