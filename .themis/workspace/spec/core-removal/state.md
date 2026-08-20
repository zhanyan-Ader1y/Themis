# state.md — core-removal

> 各闸门行内格式（本次 replay 约定，控制面未定义，见 `docs/plan/spec-replay/drift-log.md` 追问条目）：
> `- <节点名>：<结论> — <证据路径>`；结论取值：已证 / 进行中 / 未开始 / approved / 驳回 / passed / failed / accepted / 退回。

## 当前节点

详细设计 + 任务

## 各闸门

- Intake：已证 — `Intent.md` 来源引用小节
- 追问：已证 — `QA.md` 第 1、2 轮（全部问题均已获所有者答复；Agent 依据 `rules.md` §2 提出收敛主张，确认权归 R1 评审者，R1 已 approved，本节点由此判"已证"）
- R1 意图评审：approved — `intent-review.md` 结论小节
- 抽象设计：已证 — `step1/specify.md`（行为条目与来源覆盖两节已产出，四条 SPEC-COREREMOVAL 判据均可执行，命令与真实输出见 `step1/design.md`「事实依据」）
- R2 抽象设计评审：approved — `step1/design-review.md` 结论小节（所有者逐字批复："appreved。 1. 接受。2. 宽度。3. 纳入"）
- 详细设计+任务：进行中 — `step1/design.md`（提前于本节点在抽象设计阶段成形的草稿，R2 approved 后正式归属本节点；七处结构决策中 `CLAUDE.themis.md`/`README.md`（宽读口径）与仓库根 `AGENTS.md:13`（已纳入范围）两项待按 R2 结论修订，`task/basic.md`、`task/detail.md` 尚未产出，故判"进行中"而非"已证"）
- R3 详细方案评审：未开始 — 无
- impl/basic：未开始 — 无
- verify/basic：未开始 — 无
- impl/detail：未开始 — 无
- verify/detail：未开始 — 无
- 人工验收：未开始 — 无
- 摘要：未开始 — 无

## 当前性

- `Intent.md`：current（已按 R1 结论所附所有者表态更新期望结果节与来源引用小节：`.gitignore` 规则、`AGENTS.md`"与 core/ 的关系"一节均已确认；`catalog.md` 相对路径引用处理方式仍未确定，明确延后，待单独审阅。此次更新与 `flow.md` R1 节失效波及条款的适用边界存在解读空当，按结论闭环处理，未触发重新评审，详见 `docs/plan/spec-replay/drift-log.md` R1 条目。**追加**：本轮又按 R2 结论所附所有者表态（"appreved。 1. 接受。2. 宽度。3. 纳入"）更新范围/期望结果/核心链路三节——六处活跃引用改记为七处，纳入仓库根 `AGENTS.md:13`；`CLAUDE.themis.md`/`README.md` 删节口径记为宽读。与 R1 条目同型的解读空当再度适用：本次更新是誊写 R2 评审者本人批复、且不超出其内容，按控制器裁定不触发 stale，见 `docs/plan/spec-replay/drift-log.md` R2 条目）
- `QA.md`：current（第 1、2 轮均已追加答复，不覆盖不回填；本轮未新增轮次——R2 结论走的是 `design-review.md`「结论」通道，不是 `QA.md` 追问通道）
- `intent-review.md`：current（R1 approved，结论小节已记所有者原话；未解决反馈第 3 条仍未解决，作为开放决策点带入后续节点）
- `step1/specify.md`：current（本轮新增 `SPEC-COREREMOVAL-004`，闭合仓库根 `AGENTS.md:13` 的判据覆盖缺口；命令已真实核验可执行，见 `design-review.md` 与 `drift-log.md` R2 条目）
- `step1/design-review.md`：current（R2 approved，结论小节已记所有者原话；未解决反馈三条中前两条经 R2 批复关闭，第三条——`catalog.md:33`——仍未解决，未随 R2 通过而被标记已决）
- `step1/design.md`：**stale（草稿，待下一任务修订）**——内容按上一程现状保留未改，但其中"结构决策"第 1、2 条（`CLAUDE.themis.md`/`README.md`）仍是窄读法（只删字面 `core/` 路径行），与 R2 已确认的宽读口径不一致；第 7 条（仓库根 `AGENTS.md:13`）仍标"范围外新发现、不处理"，与 R2 已确认"纳入范围"不一致。这两处修订以及新增结构决策条目，按控制器指示归属下一任务，本程不改 `design.md` 内容
- `step1/task/*`、`step1/impl/*`、`step1/verify/*`、`step1/acceptance.md`、`step1/summary.md`：未产出
