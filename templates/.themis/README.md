# Themis 安装包合同

本目录定义 future fresh Init 安装到项目 `.themis/` 的 Core 与 Workspace 基线。当前 checkout 提供 Prompt-level 合同、模板、静态核验与人工 replay 语义；不提供生产 installer、严格 validator 或确定性运行时。

## 产品主链

安装包共同强化：详细细化前的需求追问、低负担 Plan Review、可沉淀的 Agent Plan，以及受治理、持续进化的项目知识库。

```text
external user message
→ immutable Source Event under Request Intake
→ user-confirmed source-bound Current Request claims
→ Questioning
→ optional Grounding
→ Complexity Assessment
   ├─ simple → Simple Plan → lightweight Plan Check
   └─ full   → temporary Specification → Planning → full Plan Check
→ Review Projection → Review Check → Review Dialogue → Review Approval
→ Verify [Impl → independent Verification]
→ Human Acceptance
→ Summary
→ optional governed knowledge candidates
```

每条外部消息，包括 Questioning 回答、Review 反馈/批准、Acceptance 和 restart/unblock，都先经过 Intake interception。快速与完整路径只在统一 Plan 形成前不同；Review 始终位于项目实现前；Summary 只在 current Verification `passed` 且 Human Acceptance `accepted` 后生成。

## 控制架构

```text
one public themis Skill
→ one always-loaded Global Control Rule
→ one transitions.yaml across request-intake and lifecycle
→ one internal Capability + fixed Agent Profile
→ one temporary Invocation in one authority scope
→ proposed Capability result
→ exactly one legal route and declared control action
→ observed materialization, reread, and pointer update
```

- [`../.claude/skills/themis/SKILL.md`](../.claude/skills/themis/SKILL.md) 是唯一公共 Themis 入口，负责运输消息与 durable continuation，不拥有语义判断或路由。
- [`core/kernel/orchestrator/rules.md`](core/kernel/orchestrator/README.md) 是唯一常驻 Rule，通用解释 policy 并协调双作用域。
- [`core/policies/transitions.yaml`](core/policies/README.md) 是 route/control、固定 Profile/scope、guards、invalidation 和失败控制的唯一声明源。
- [`core/capabilities`](core/capabilities/README.md) 中十六个内部 Capability 分别拥有一个 proposed semantic judgment；它们不是公共 Skills。
- [`core/agent-profiles`](core/agent-profiles/README.md) 中四个固定 Profile 只约束工具、权限与隔离；没有 governance writer。
- 一次 Invocation 只执行一个 Capability，Capability/Agent 不得嵌套调度，也不存在持久 Agent、共享 authority、投票或共识。

## Authority scopes

### `request-intake`

拥有原始 Source Event 引用、claim/assignment proposal、用户确认 decision、Intake Execution Identity、Intake-local continuation、pointer、disposition 和 post-completion retention facts。只有 active durable confirmation 或 restart/unblock continuation 可以把新 Source Event 附着到已有 Intake；`dormant-read-only` Intake 不可附加，否则创建新 Intake。

### `lifecycle`

拥有 Current Request revisions、Questioning、path/Plan、Review/Approval、Plan Task Execution、Verification、Acceptance、Summary、continuation 和 current pointers。

两个 scope 只能交换稳定不可变引用，不能共享动态 state、Execution Identity、failure budget、continuation authority、current pointer 或 completion state。Confirmed assignment 完整物化并重读前，不得创建或继续 lifecycle。

## 权威模型

- Source Event 保存外部输入原始 bytes；normalized projection 不能替代原文。
- 用户明确确认的 source-bound claim revisions 拥有 lifecycle 目标语义。
- 受治理设计约束只限制可接受方案，不改写用户 claims。
- 代码、配置、Schema 和实际观察到的可执行行为是当前实现事实的唯一来源。
- Specification 只是完整路径中的临时非权威 handoff，没有持久 artifact 或 current pointer。
- 当前 checked 且明确批准的统一 Plan 是执行合同。
- Review Projection 是 checked Plan 的绑定只读投影，不是第二份 Plan 或实现输入。
- Capability result、Markdown、文件存在或 Agent prose 都只是 proposal/线索；只有 policy action、完整持久化、completion observation、reread 与 pointer update 才能证明 current authority。

## Artifact 与 Workspace

所有逻辑 artifacts 使用 immutable revision；需要人类语义的 family 使用 machine record + Markdown paired revision，current pointer 独立保存。任一 component 缺失或 identity/digest/scope/bindings 不一致时，整个 revision invalid。

```text
workspace/intakes/<intake-id>/       Source Events、proposals、decisions、state
workspace/changes/<lifecycle-id>/    Current Request、Questioning、Plan、Review、Approval、Feedback
workspace/state/<lifecycle-id>/      minimal refs、pointers、invalidations、markers、last proven gate
workspace/runs/<lifecycle-id>/       task executions、Invocations、attempts、Impl/Verification records
workspace/evidence/<lifecycle-id>/   commands、Git observations、external evidence
workspace/outcomes/<lifecycle-id>/   Acceptance、Summary
workspace/knowledge/intakes/         Intake-scoped candidates
workspace/knowledge/lifecycles/      lifecycle-scoped candidates
```

Questioning 每个完成 exchange 形成独立 immutable round；未回答的问题只保存在 proposal/continuation state。路径与文件存在本身不证明 authority。

## Review、Verify 与门禁

- 只有 current Plan Check `pass` 才能生成 Review Projection。
- Review Dialogue 只产生 continuation、Feedback proposal 或 Approval proposal，不直接 patch Plan/Projection 或写治理状态。
- Approval 批准 checked Plan，并绑定用户实际看到的 projection、空 unresolved feedback 与 pre-Impl baseline。
- Verify 固定为 `themis-impl → independent themis-verification`；两个 Invocation 共享一个 Plan Task Execution Identity 和失败预算。
- Current Verification 必须 `passed` 才能 Acceptance；current Acceptance 必须 `accepted` 才能 Summary。
- Summary 和 lifecycle completion 完整观察后冻结对应 Intake target；所有关联 lifecycle target 完成后，Intake 保持 `assigned` 并进入 `dormant-read-only`，只读保留来源/决定/观察记录，失活 continuation，未来消息创建新 Intake。
- `full_path_required` 在 lifecycle 内只允许 `false → true`，不会因 restart、retry 或 reassessment 清除。

## Failure 与 recovery

Intake Execution Identity 和 lifecycle Plan Task Execution Identity 分别最多三次 counted failures；第三次终止对应 identity 并禁止第四次 Invocation。Intake failure 不消耗 lifecycle budget。Impl、Verification 和 Acceptance `implementation-defect` repair 共享一个 Plan task budget。

Failure Learning 支持两个 scope，但始终 non-blocking、non-recursive、candidate-only。中断后只从 active scope state、pointers、markers、artifact components、Invocation/attempt records 和 applicable Git facts恢复到 `last proven gate`；不从聊天、Summary、临时 Specification 或 Agent reasoning 猜测完成。Dormant Intake 只供历史 authority 核验，不参与恢复、重激活或 Invocation。

## 不变量与当前能力边界

- Core 管理控制合同；Workspace 保存项目拥有的记录与引用，但不实现控制逻辑。
- 模块不使用功能版本，不提供 compatibility、upgrade 或 migration。
- Behavior Map、Shell fallback、多 Agent execution 与 Attribution gate 不属于 Plan 35。
- Plan 35 只提供一个公共 Skill、一个 Global Rule、一个双作用域 policy、十六个内部 Capability、四个 Profile、immutable templates、static verification 和 manual replay semantics。
- Plan 36 owns strict Schema、canonical serialization、validator、issue taxonomy、semantic oracle 与 fixtures。
- Plan 37 owns evaluator、Invocation host、recorder、digest/write services 与 command execution。
- 未观察到相应 runtime 时，不得声称 Source Event recording、transition、persistence、digest、currentness、attempt、invalidation、termination、recovery、atomicity 或 completion 已由机器执行。
