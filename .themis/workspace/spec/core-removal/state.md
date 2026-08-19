# state.md — core-removal

> 各闸门行内格式（本次 replay 约定，控制面未定义，见 `docs/plan/spec-replay/drift-log.md` 追问条目）：
> `- <节点名>：<结论> — <证据路径>`；结论取值：已证 / 进行中 / 未开始 / approved / 驳回 / passed / failed / accepted / 退回。

## 当前节点

追问

## 各闸门

- Intake：已证 — `Intent.md` 来源引用小节
- 追问：进行中 — `QA.md` 第 1、2 轮（全部问题均已获所有者答复；Agent 依据 `rules.md` §2 提出收敛主张，确认权归 R1 评审者，本节点在 R1 批准前不判"已证"）
- R1 意图评审：未开始 — 无
- 抽象设计：未开始 — 无
- R2 抽象设计评审：未开始 — 无
- 详细设计+任务：未开始 — 无
- R3 详细方案评审：未开始 — 无
- impl/basic：未开始 — 无
- verify/basic：未开始 — 无
- impl/detail：未开始 — 无
- verify/detail：未开始 — 无
- 人工验收：未开始 — 无
- 摘要：未开始 — 无

## 当前性

- `Intent.md`：current（六节均已按 `QA.md` 第 1、2 轮答复更新；Agent 已提出收敛主张，R1 批准前仍为待评审状态，任何后续修订将使 R1 结论 stale——但 R1 尚未开始，暂无下游结论）
- `QA.md`：current（第 1、2 轮均已追加答复，不覆盖不回填）
- `intent-review.md`：未产出（R1 尚未进行，前置闸门见 `flow.md` R1 节）
- `step1/specify.md`、`step1/design.md`、`step1/design-review.md`：未产出（抽象设计节点未开始，需 R1 approved 后才能开始）
- `step1/task/*`、`step1/impl/*`、`step1/verify/*`、`step1/acceptance.md`、`step1/summary.md`：未产出
