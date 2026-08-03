# 迁移基线核验

## 核验范围

本分片冻结 Plan 35 Markdown 合同重构开始时的版本控制状态、活动 YAML 来源、四个大型入口及旧证据适用边界。它不修改 replacement Plan 35 的产品语义，也不证明任何新 Markdown candidate 已完成。

## 旧来源与新目标

- 旧来源：2026-07-31 已接受的 replacement Plan 35 设计、Prompt/template/policy/Workspace 实现及其静态核验、人工 replay 和 acceptance audit。
- 新目标：保持相同产品语义，将无 Go CLI 消费者的 YAML 与大文件权威改为按功能拆分的自然语言 Markdown，并重新建立人工证据。
- 适用边界：历史重新接受仍是真实记录，但不能代替本次 Markdown-first amendment 的重新核验和重新接受。

## 逐项迁移观察

### 工作树基线

基线提交：`6678eaa docs: 规划 Plan 35 Markdown 合同重构`

在任务 1 开始时运行：

```text
git status --short
```

实际输出：无输出。提交后的工作树为 clean。

后续只允许修改已批准实施计划列出的路径；不得 reset、restore、clean、stash、覆盖或迁移现有修改，不得再 commit 或 push。

### 活动 YAML 基线

文件搜索工具在 `templates/.themis/**/*.yaml` 中实际观察到 27 个活动 YAML：

1. `templates/.themis/core/protocols/context/common-schema.yaml`
2. `templates/.themis/core/protocols/context/context-item-schema.yaml`
3. `templates/.themis/core/protocols/context/catalog-schema.yaml`
4. `templates/.themis/core/protocols/context/bundle-schema.yaml`
5. `templates/.themis/core/protocols/context/signal-schema.yaml`
6. `templates/.themis/workspace/context/catalog.yaml`
7. `templates/.themis/core/templates/request-intake-source-event.yaml`
8. `templates/.themis/core/templates/current-request.yaml`
9. `templates/.themis/core/templates/questioning-round.yaml`
10. `templates/.themis/core/templates/grounding.yaml`
11. `templates/.themis/core/templates/complexity-assessment.yaml`
12. `templates/.themis/core/templates/plan.yaml`
13. `templates/.themis/core/templates/plan-check.yaml`
14. `templates/.themis/core/templates/review.yaml`
15. `templates/.themis/core/templates/review-check.yaml`
16. `templates/.themis/core/templates/review-approval.yaml`
17. `templates/.themis/core/templates/impl-result.yaml`
18. `templates/.themis/core/templates/verification.yaml`
19. `templates/.themis/core/templates/acceptance.yaml`
20. `templates/.themis/core/templates/summary.yaml`
21. `templates/.themis/core/templates/failure-learning.yaml`
22. `templates/.themis/core/core.yaml`
23. `templates/.themis/workspace/manifest.yaml`
24. `templates/.themis/core/templates/request-intake-proposal.yaml`
25. `templates/.themis/core/templates/request-intake-decision.yaml`
26. `templates/.themis/core/templates/review-feedback.yaml`
27. `templates/.themis/core/policies/transitions.yaml`

这些文件都没有当前 Go CLI 消费者，因此在全局 authority cutover 完成前只作为旧语义来源保留，最终目标为 0 个活动产品 YAML。

### 大文件基线

| 入口 | 读取工具观察行数 | 当前主题范围 | 后续目标 |
|---|---:|---|---|
| `docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement-design.md` | 1293 | 跨模块 authority、Intake、Capability、Policy、lifecycle、artifact、Workspace、Review/Delivery、failure/recovery、verification 与 32 条标准 | 短入口 + 十个功能 references |
| `templates/.themis/core/policies/transitions.yaml` | 623 | 双 scope、16 Capability、materialization、currentness、failure、invalidation、98 个 route 结果组合和 assurance | 一个 Markdown Policy 入口 + 主题/阶段 references |
| `templates/.themis/core/kernel/orchestrator/rules.md` | 308 | Intake-first、Invocation、materialization、lifecycle、Review/Delivery、failure、recovery 与 safe degradation | 短常驻 Rule + 六个按 gate 加载的 references |
| `docs/plan/35-core-prompt-flow/manual-replay.md` | 244 | 十六个完整场景 ledger | 短 replay 索引 + 十六个独立场景文件 |

行数来自本任务使用文件读取工具完整读取时观察到的末行，不是自动 Go CLI 输出。

### 活动状态入口

以下入口在任务 1 中统一改为“Markdown-first 表示迁移待核验”，并保留 2026-07-31 历史重新接受事实：

| 入口 | 当前状态边界位置 | 核对结果 |
|---|---|---|
| `docs/plan/35-core-prompt-flow/impl.md` | 第 3、5 行和“2026-07-31 固定架构基线”章节 | 明确历史重新接受、当前表示待核验、Plan 36/37 暂停；旧 YAML 架构只作为迁移输入 |
| `docs/plan/35-core-prompt-flow/static-verification.md` | 第 5–7 行和第 166 行 | 明确旧静态输出为历史证据，自动 Go CLI 检查 unavailable，不能恢复 current authority |
| `docs/plan/35-core-prompt-flow/manual-replay.md` | 第 5 行和第 243 行 | 明确十六场景为历史 replay，必须针对新 Markdown Policy 重新重放 |
| `docs/plan/35-core-prompt-flow/acceptance-audit.md` | 第 6、8、83、85 行 | 矩阵统一标为 `HISTORICAL PASS`；当前 31 项待重新映射，criterion 32 待重新接受 |
| `docs/plan/35-core-prompt-flow/evidence-summary.md` | 第 3、42、46 行 | 区分历史 32 项通过与当前 Markdown-first pending 状态 |
| `docs/plan/README.md` | 第 11、17、27、66、91 行 | 活动队列和依赖门禁保持 Plan 36/37 暂停，旧 `transitions.yaml` 只作为历史基线 |

人工搜索未发现上述活动入口仍把 `32/32`、criterion 32 complete、current authority restored 或 Plan 36 可启动作为当前 Markdown-first 结论。

## 实施者核对

- 工作树基线已保存，实际为 clean。
- 27 个 YAML 路径与批准计划的完整迁移矩阵一致。
- 四个大型入口的主题范围与拆分目标已记录。
- 旧 evidence 主体未删除，历史 2026-07-31 重新接受未被改写为从未发生。
- 活动入口不再把旧 `32/32 PASS` 当作当前 Markdown-first 表示合规结论。
- Plan 36/37 在新证据完成和用户重新接受前继续暂停。

## fresh reviewer 核对

2026-08-01 的独立只读 reviewer 返回 `Verdict: APPROVED`，未发现 Critical、High、Medium、Low finding，也未发现会阻止任务 1 完成的实质性 GAP。reviewer 核对了：

- 工作树变更只覆盖任务 1 的六个修改文件和两个新建 evidence 路径；
- diff 只冻结状态和证据适用边界，没有改变 replacement Plan 35 产品语义；
- 2026-07-31 重新接受作为历史事实保留；
- criteria 1–31 当前待重新映射，criterion 32 为 `PENDING USER RE-ACCEPTANCE`；
- Plan 36/37 持续暂停；
- 27 个 YAML 路径、四个大文件行数和六个状态入口定位准确；
- 自动 Go CLI 检查如实为 `unavailable`；
- 十六个旧 replay 场景主体未被改写；
- `git diff --check` 成功，仅有 LF→CRLF 工作副本提示。

reviewer 为只读复核，未修改文件、未 commit 或 push。

## 未裁决 GAP

无。任务 1 的实施者观察与 fresh reviewer 核对均已完成。

## 自动 Go CLI 检查状态

`unavailable`。当前不存在已批准并已实现的 Themis Go CLI 基线、文档体积或合同核验命令；未使用 Python、Shell 临时脚本或虚构子命令替代。
