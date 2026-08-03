# Global Rule 与公共入口迁移核验

## 核验范围

本分片核验任务 4 将原 308 行 Global Control Rule 拆为一个 96 行常驻入口与六个按 durable gate 加载的中文 references，并把公共 `themis` Skill 从旧 `transitions.yaml` 加载链改为唯一自然语言 Policy package。它不修改 Capability、template、Workspace consumer，不删除旧 YAML，也不执行全局 authority cutover。

## 旧来源与新目标

- 旧 Rule：`templates/.themis/core/kernel/orchestrator/rules.md`，原始基线为 308 行。
- 新常驻入口：同一路径 `rules.md`。
- 新 references：`templates/.themis/core/kernel/orchestrator/references/*.md` 六个文件。
- 包级说明：`templates/.themis/core/kernel/orchestrator/README.md`。
- 公共治理入口：`templates/.claude/skills/themis/SKILL.md`。
- 唯一 Policy：`templates/.themis/core/policies/README.md` 与其 references。

## 旧 Rule 章节迁移

| 旧 Rule 内容 | 新 owner | 观察 |
|---|---|---|
| Purpose、Ownership Model | `rules.md`、orchestrator `README.md` | 保留唯一 always-loaded Rule、one public entry、Capability/Profile/Invocation/Policy/Workspace ownership；删除旧 YAML current-authority 表述 |
| Authority Scopes、Authority Classification | `rules.md` | 保留 `request-intake`/`lifecycle` ownership、动态隔离与 implementation fact authority |
| Intake-First External Message Entry、Current Request Confirmation Protocol | `references/intake-entry.md` | 保留 exact Source Event、durable attachment、两次 confirmation、`no-change`、multi-target partial recovery、rejection/abandonment |
| Required Package and Preflight、Generic Invocation Sequence | `references/invocation-and-materialization.md` | 保留 current binding 重读、one temporary Invocation、fixed Profile、single terminal result、exactly-one Policy rule |
| Proposed Result and Materialization Boundary | `references/invocation-and-materialization.md` | 保留 proposal-only、ordered persistence/observation/reread/revision/pointer、paired artifact 与 temporary Specification 边界 |
| Lifecycle Continuation After Assignment | `references/lifecycle-continuation.md` | 保留 Current Request、Questioning、Grounding、Assessment、simple/full、统一 Plan 与 Plan Check |
| Review and Approval、Verify/Acceptance/Summary | `references/review-and-completion.md` | 保留 Review-before-Impl、explicit Approval、`Impl → independent Verification`、shared task budget、Acceptance repair 与 Summary gate |
| Lifecycle Completion and Intake Dormancy | `references/review-and-completion.md`、`references/intake-entry.md` | 保留逐 target completion observation、whole-Intake dormancy gate 与 `dormant-read-only` 禁止行为 |
| Sticky Full Escalation and Invalidation | `references/failure-invalidation-recovery.md` | 保留 one-way sticky full、quick downstream invalidation 与 currentness/external drift 边界 |
| Scope-Local Failure Control | `references/failure-invalidation-recovery.md` | 保留双预算、三次上限、第三次 termination、第四次 Invocation 禁令与 Failure Learning |
| Recovery from Durable Facts | `references/failure-invalidation-recovery.md` | 保留 last proven gate、remaining-target-only 与禁止自动 repair/rollback/merge/replay |
| Safe Degradation | `references/safe-degradation.md` | 保留八项 assurance、pre-Invocation unavailable non-counted 与禁止模拟执行 |
| Non-Bypass Rules | `rules.md` | 保留 Intake-first、one Plan、Review/Approval、Verify、Acceptance/Summary、sticky full、三次失败与 Learning 门禁 |

旧 Rule 的全部控制主题均有唯一常驻或按 gate owner；阶段 legal status、具体 route/control action 和 artifact 字段没有复制到 orchestrator package，继续由 Policy、Capability 和 template 拥有。

## Reference 加载边界

| Reference | 加载 gate | 返回 continuation |
|---|---|---|
| `intake-entry.md` | 外部消息、confirmation、assignment、remaining targets、retention | Intake human continuation、decision-bound lifecycle continuation 或 remaining-target continuation |
| `invocation-and-materialization.md` | preflight、Invocation、result validation、control action、materialization、pointer | Policy rule 声明的 Capability、Human Dialogue 或 gate continuation |
| `lifecycle-continuation.md` | Questioning、Grounding、Assessment、Specification、Planning、Plan Check | human-questioning、requesting owner、simple/full owner 或 Review Projection |
| `review-and-completion.md` | Review、Approval、Impl、Verification、Acceptance、Summary、completion | semantic owner、Impl、Verification、Acceptance、Summary 或 Intake retention continuation |
| `failure-invalidation-recovery.md` | sticky signal、invalidation、failure、invalid-result、interruption、recovery | scope-local main continuation、full-path owner 或 last proven gate |
| `safe-degradation.md` | 需要 unavailable machine guarantee 或准备 machine-execution claim | last proven gate 与 exact durable continuation |

每个 reference 都引用唯一 Policy package，只解释通用控制顺序，不复制六个阶段的 status/control 规则。

## 公共 `themis` 入口观察

公共 Skill 仅保留 host-required `name` 与 `description` frontmatter，正文把入口身份明确为“唯一公共 `themis` 治理入口”。加载顺序为：

```text
rules.md
→ policies/README.md
→ 当前 gate 对应的 orchestrator reference
→ 当前决定所需的 Policy shared-topic reference
→ 当前 Capability/Profile 对应的唯一 Policy phase route reference
→ one Capability contract + fixed Agent Profile
→ one temporary Invocation
```

Skill 与 Rule 均不再把 `transitions.yaml` 当作 current authority，也不从 `recommended_route`、chat、summary、Agent prose 或 file existence 推进 gate。

## 文件体积观察

使用 `wc -l` 人工观察，结果如下；该命令只是文件行数观察，不是 Themis 合同检查：

| 文件 | 实际行数 | 上限 | 结果 |
|---|---:|---:|---|
| `rules.md` | 96 | 140 | 范围内 |
| `references/intake-entry.md` | 72 | 180 | 范围内 |
| `references/invocation-and-materialization.md` | 77 | 180 | 范围内 |
| `references/lifecycle-continuation.md` | 60 | 180 | 范围内 |
| `references/review-and-completion.md` | 73 | 180 | 范围内 |
| `references/failure-invalidation-recovery.md` | 81 | 180 | 范围内 |
| `references/safe-degradation.md` | 60 | 180 | 范围内 |
| 公共 `themis/SKILL.md` | 100 | 未设计划上限 | 已收敛为治理入口 |

## 实施者核对

- `rules.md` 保留 Intake-first、双 scope、ownership、reference loading、unique Policy rule、complete materialization、non-bypass gates 与 safe degradation，没有复制 98 个阶段 route 或 artifact 字段全集。
- Intake reference 明确 proposal 同时绑定原 lifecycle-bearing Source Event/exact fragments 与原 durable continuation；confirmation Source Event 只确认 governance diff，materialization 后仍把原消息交回原 continuation。
- 六个 references 覆盖 Intake、Invocation/Materialization、Lifecycle、Review/Completion、Failure/Recovery 与 safe degradation。
- `rules.md`、orchestrator README 与公共 Skill 均不再引用 `transitions.yaml`、machine record 或 YAML current authority。
- 公共 Skill frontmatter 只有 `name` 与 `description`。
- 新文件没有 `TODO`、`TBD`、fenced YAML、route DSL、parser instruction 或固定结构化 route fragment。
- `git diff --check` 对任务 4 路径成功，仅报告 Windows LF→CRLF 警告。
- 本任务未删除或修改旧 `templates/.themis/core/policies/transitions.yaml`，该文件留给任务 9 全局 cutover。
- 本任务未修改 Capability、template、Workspace consumer，未启动 Plan 36/37，未 commit 或 push。

## Fresh reviewer 核对

2026-08-01 的独立只读 reviewer 首轮返回 `Verdict: CHANGES_REQUIRED`。Reviewer 确认 Rule/六个 gate references/公共 Skill 的总体拆分与体积边界成立，但提出一个 Medium finding：`intake-entry.md` 没有明确保存“触发原 lifecycle dialogue 的 Source Event”与原 durable continuation，也没有禁止 confirmation Source Event 替代原消息，可能在 Questioning、Review 或 Acceptance interception 后把只含“确认”的第二条消息错误送入 lifecycle。

已修复：

- Intake proposal 明确绑定原 lifecycle-bearing Source Event identity、exact fragments 与原 durable lifecycle continuation；
- confirmation Source Event 只作为 governance diff confirmation 的 source authority，不替代原消息；
- assignment/Current Request materialization 完成后，原 Source Event 被交回原 durable lifecycle continuation；
- confirmation 消息若另含独立 lifecycle 内容，必须经过自身显式 Intake/assignment control，不能隐式覆盖。

2026-08-01 的 scoped re-review 返回 `Verdict: APPROVED`，`Findings: None`。Reviewer 确认 proposal 已绑定原 lifecycle-bearing Source Event/exact fragments 与原 durable continuation，confirmation Source Event 只确认 governance diff，materialization 后仍把原消息交回原 continuation；confirmation 中的独立 lifecycle 内容也必须经过显式单独治理。

Reviewer 始终只读，未修改文件、commit 或 push。

## 未裁决 GAP

无。首轮唯一 Medium finding 已修复并通过 scoped re-review；自动 Go CLI 核验仍按下节记为 `unavailable`，不构成已实现 guarantee。

## 自动 Go CLI 检查状态

`unavailable`。当前不存在已批准并已实现的 Themis Go CLI Rule/Policy/Skill 合同核验命令；未使用 Python、Shell 临时脚本、临时 parser 或虚构子命令替代。Git 与 `wc` 只用于人工版本控制/文件观察。
