# state.md — core-removal

> 各闸门行内格式（本次 replay 约定，控制面未定义，见 `docs/plan/spec-replay/drift-log.md` 追问条目）：
> `- <节点名>：<结论> — <证据路径>`；结论取值：已证 / 进行中 / 未开始 / approved / 驳回 / passed / failed / accepted / 退回。

## 当前节点

impl/basic（R3 已 approved，实现节点已解锁；本 step 的 basic 段为空，空段的处理见 `flow.md`「impl/basic」节，据此实际下一个产生落地动作的节点是 impl/detail。删除动作尚未执行）

## 各闸门

- Intake：已证 — `Intent.md` 来源引用小节
- 追问：已证 — `QA.md` 第 1、2 轮（全部问题均已获所有者答复；Agent 依据 `rules.md` §2 提出收敛主张，确认权归 R1 评审者，R1 已 approved，本节点由此判"已证"）
- R1 意图评审：approved — `intent-review.md` 结论小节
- 抽象设计：已证 — `step1/specify.md`（行为条目与来源覆盖两节已产出，四条 SPEC-COREREMOVAL 判据均可执行，命令与真实输出见 `step1/design.md`「事实依据」）
- R2 抽象设计评审：approved — `step1/design-review.md` 结论小节（所有者逐字批复："appreved。 1. 接受。2. 宽度。3. 纳入"）
- 详细设计+任务：已证 — `step1/design.md` 与 `step1/task/basic.md`、`step1/task/detail.md`（三份产出齐备，basic/detail 分类已完成并经 R3 判定；design.md 已按 R2 结论修订完毕，不再是草稿）
- R3 详细方案评审：approved — `step1/task/review.md` 结论小节（所有者逐字批复："appreved。1. 确认不计入。2. 优先解决流程闭环，可观测在MVP后再处理。3. 由你定义边界给我审阅后决定。 删掉这句"）
- impl/basic：未开始 — 无（前置闸门 R3 已 approved，本节点已解锁；但本 step 的 basic 段为空，见 `step1/task/basic.md`，空段的处理见 `flow.md`「impl/basic」节。**行内格式说明**：本次 replay 约定的结论取值里没有"空段不产生调用"这一档，故仍记"未开始"，实际情况以本行证据栏为准——这是 replay 内部约定的一处不足，控制面未定义该格式，已记入 `docs/plan/spec-replay/drift-log.md`）
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
- `step1/design.md`：current（本轮已按 R2 结论完成修订，不再是上一程那份 stale 草稿）——"结构决策"第 1、2 条（`CLAUDE.themis.md`/`README.md`）已改写为宽读逐节判定，与 R2 已确认的口径一致；第 7 条（仓库根 `AGENTS.md:13`）已由"范围外新发现、不处理"改为纳入范围并给出处理做法；"事实依据"两处事实错误已订正（命中行数 14→16；`CHANGES.md:41,81,82` 的分类理由不再依赖经 `git ls-files` 核验并不存在的 `docs/core/`）。另在本轮自查重跑命令时发现并订正四处行号区间错误（`CLAUDE.themis.md`「控制架构」「关键路径」、`README.md`「产品主链」，以及被合并记为一节的「Authority scopes」/「权威模型」），核验命令与输出见该文件「事实依据」命令 8。第 5、6 条未改动——`templates/.themis/spec/README.md` 沿用既有裁定不改，`catalog.md:33` 仍是唯一开放决策点，本轮未为其定做法
- `step1/task/basic.md`、`step1/task/detail.md`：current（`basic.md` 为空段并写明判定依据；`detail.md` 为 T-D1–T-D6，其中 T-D3 末句的落地顺序建议已按所有者 R3 批复"删掉这句"删除，经过记在 `task/review.md`「分类核查」第 5 条）
- `step1/task/review.md`：current（R3 approved，「结论」小节已记所有者逐字原话；「未解决反馈」经所有者批复"确认不计入"后清空，无遗留待回应项）
- `step1/impl/*`、`step1/verify/*`、`step1/acceptance.md`、`step1/summary.md`：未产出
