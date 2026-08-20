# state.md — core-removal

> 各闸门行内格式（本次 replay 约定，控制面未定义，见 `docs/plan/spec-replay/drift-log.md` 追问条目）：
> `- <节点名>：<结论> — <证据路径>`；结论取值：已证 / 进行中 / 未开始 / approved / 驳回 / passed / failed / accepted / 退回。

## 当前节点

R1 意图评审

## 各闸门

- Intake：已证 — `Intent.md` 来源引用小节
- 追问：已证 — `QA.md` 第 1、2 轮（全部问题均已获所有者答复；Agent 依据 `rules.md` §2 提出收敛主张，确认权归 R1 评审者，R1 已 approved，本节点由此判"已证"）
- R1 意图评审：approved — `intent-review.md` 结论小节
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

- `Intent.md`：current（已按 R1 结论所附所有者表态更新期望结果节与来源引用小节：`.gitignore` 规则、`AGENTS.md`"与 core/ 的关系"一节均已确认；`catalog.md` 相对路径引用处理方式仍未确定，明确延后，待单独审阅。此次更新与 `flow.md` R1 节失效波及条款的适用边界存在解读空当，按结论闭环处理，未触发重新评审，详见 `docs/plan/spec-replay/drift-log.md` R1 条目）
- `QA.md`：current（第 1、2 轮均已追加答复，不覆盖不回填）
- `intent-review.md`：current（R1 approved，结论小节已记所有者原话；未解决反馈第 3 条仍未解决，作为开放决策点带入后续节点）
- `step1/specify.md`、`step1/design.md`、`step1/design-review.md`：未产出（R1 已 approved，前置闸门已满足，抽象设计节点尚未开始）
- `step1/task/*`、`step1/impl/*`、`step1/verify/*`、`step1/acceptance.md`、`step1/summary.md`：未产出
