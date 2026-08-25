# state.md — core-removal

> 各闸门行内格式：`- <节点名>：<结论> — <证据路径>`。**结论取值现由 `flow.md` 通用状态条款按节点类型固定**，本文件不再自建约定。
>
> 此前该取值集合属"控制面未定义、本次 replay 自建"（原缺口记在 `docs/plan/spec-replay/drift-log.md` 追问条目与 verify/basic 条目——"已证"被重载，同时表示"本节点已走完"和被误读为"验证通过"）。缺口已于 2026-08-24 修复：`已证` 改记为 `已走完`（含义不变，且明写不含任何判据结论），verify/basic 空段结论改记为新增的 `不适用`。**各闸门的实际结论一处未变，改的只是取值写法。** 下文括注中仍出现的"已证"字样是**当时记述的原文**，保留不改。

## 当前节点

**step1 已走完全流程，闭环。** 摘要为链尾（`flow.md`「摘要」节），无后继节点；`step1` 无下一个待进入的节点。impl/detail 当时的进入依据是控制器裁定 Ruling 18（**前置取 R3 approved**），不是控制面条款直接给出的结论，见下。

**当前节点：step2 的 step 定界（未开始）。** 本 spec 的需求尚未达成——`Intent.md`「step 分解」载两个 step，step2 未开始。

**2026-08-24 的两处控制面变化，影响本文件的读法：**

1. **Ruling 18、Ruling 20 绕开的两处缺口已修复**，裁定内容固化进条款：`flow.md`「impl/detail」正文加了"basic 段非空时"限定，verify/basic 新增 `不适用` 取值。下文关于"两处缺口仍未修复"的记述是**当时的事实**，保留不改；现按修复后的条款读，step1 当时的处置与现行条款一致。
2. **意图分两层**（spec 级 `Intent.md` + step 级 `scope.md`），`Intent.md` 新增「step 分解」小节，step1 补写了 `scope.md`。补写与新增分解项**不使 step1 失效**——依据是 `flow.md`「R1 意图评审」节新增的失效级联例外：仅新增分解项、不改变任何已有 step 目标语义的 `Intent.md` 修订，不使已 accepted 的 step 失效。step1 当初被批准时依据的前提一字未改。

原记"该 step 自设计节点起完整走流程"的说法按新结构调整：step2 自 **step 定界节点**起走完 step 级十一个节点（`scope.md` → 抽象设计 → R2 → 详细设计+任务 → R3 → impl/verify 两段 → 验收 → 摘要），不重走 spec 级的 Intake/追问/R1。

impl/basic 与 verify/basic 两节点均已走完，均为空段形态：impl/basic 零落地调用；verify/basic 的结论既非 passed 也非 failed（三项判据无断言对象，且执行身份与实现者相同）。空段下能否进入 impl/detail，`flow.md`「impl/detail」节内部有两处互斥读法——前置闸门为空段单列了 R3 approved 这一取值（可进入），同节末尾援引 `SPEC-IMPL-002` 的那句却是无条件的（进不去，空段永远拿不到它要求的那个通过）。**控制面本身没有指出该以哪句为准；本 step 曾据此停下等待裁定，现由控制器裁定以前置闸门为准（Ruling 18），据此解锁。** 裁定不消解那处矛盾：节末那句按字面读仍无空段豁免，控制面待修。裁定内容、代价与仍待修的缺口见 `docs/plan/spec-replay/drift-log.md`「verify/basic」条目 (3)，比对见 `step1/verify/basic.md`「说明」。

fail-closed 是否适用于"结论不可判"一处，同由控制器裁定（Ruling 20）：不等同于失败、不触发停靠。**本 step 由此不再残留任何自陈的阻断条件。**

**删除动作已执行**——`step1/task/detail.md` 的 T-D6 落地，`templates/.themis/core/` 98 个文件整体删除；T-D1 至 T-D5 五处文件改动同批落地。命令与真实输出见 `step1/impl/detail.md`「命令记录」。本 step 由此第一次产生了可观测的代码改动；这些改动是否满足 `step1/specify.md` 四条判据，属 verify/detail，本文件不预判。

impl/detail 与 verify/detail 由两次不同的 agent 会话承担，`rules.md` §7 的身份独立在本节点起首次具备成立条件——判定仍以两份工件「执行身份」小节的实际比对为准，不以本行的说明为准。

## 各闸门

> **2026-08-24 结构调整**：控制面已把意图分为两层（spec 级 `Intent.md` + step 级 `scope.md`），本小节据此分组：spec 级节点各一行，step 级节点按 step 分组。**取值改用 `flow.md` 通用状态条款新定义的固定取值表**——此前本文件开头声明的行内格式属"控制面未定义、本次 replay 自建约定"，该缺口已修复，`已证` 相应改记为 `已走完`（含义不变：本节点已产出其规定工件，不含任何判据结论）。改的是取值写法与分组，**各闸门的实际结论一处未变**。

### spec 级

- Intake：已走完 — `Intent.md` 来源引用小节
- 追问：已走完 — `QA.md` 第 1、2 轮（全部问题均已获所有者答复；Agent 依据 `rules.md` §2 提出收敛主张，确认权归 R1 评审者，R1 已 approved，本节点由此判"已证"）
- R1 意图评审：approved — `intent-review.md` 结论小节
### step1（已完成，2026-08-22 accepted）

- step 定界：已走完 — `step1/scope.md`（**2026-08-24 补写**：step1 执行时该节点尚不存在，本文件不追认、不改写当时任何判断，内容全部取自 step1 已 accepted 的工件。补写不使 step1 失效，依据见 `Intent.md`「step 分解」）
- 抽象设计：已走完 — `step1/specify.md`（行为条目与来源覆盖两节已产出，四条 SPEC-COREREMOVAL 判据均可执行，命令与真实输出见 `step1/design.md`「事实依据」）
- R2 抽象设计评审：approved — `step1/design-review.md` 结论小节（所有者逐字批复："appreved。 1. 接受。2. 宽度。3. 纳入"）
- 详细设计+任务：已走完 — `step1/design.md` 与 `step1/task/basic.md`、`step1/task/detail.md`（三份产出齐备，basic/detail 分类已完成并经 R3 判定；design.md 已按 R2 结论修订完毕，不再是草稿）
- R3 详细方案评审：approved — `step1/task/review.md` 结论小节（所有者逐字批复："appreved。1. 确认不计入。2. 优先解决流程闭环，可观测在MVP后再处理。3. 由你定义边界给我审阅后决定。 删掉这句。"——与 `step1/task/review.md`「结论」所录一字不差，含句末句号。**截断说明**：所有者同一条消息末尾另有一句面向控制器的会话指令未录入实例工件，理由见该文件「结论」末段，故本行所引是该条消息的截断，不是整条）
- impl/basic：已走完 — `step1/impl/basic.md`（节点已走完，四节齐备；`flow.md`「impl/basic」节列出的第二项产出在空段下为空集——零落地调用，`templates/`、`.gitignore`、仓库根 `AGENTS.md` 均未被触碰，命令与真实输出见该文件「命令记录」。**取值说明**：本次 replay 约定的结论取值里仍没有"空段不产生调用"这一档（缺口由任务 4 记入 `docs/plan/spec-replay/drift-log.md` R3 条目）；本轮不新增取值，改记"已证"，其含义仅为"本节点已走完、其产出已在"，**不含**"有改动已落地"。缺口本身未修复）
- verify/basic：不适用 — `step1/verify/basic.md`（节点已走完，五节齐备；**「结论」既非 passed 也非 failed**——第一项判据无断言对象、第二三项可跑但与本段无因果关系、且执行身份与 `step1/impl/basic.md` 相同致 `rules.md` §7 身份独立不成立，三条理由见该文件「结论」。**取值说明**：验证型节点在本次 replay 的约定里只有 passed/failed 两档，两档均不成立，此处的"已证"只表示本文件已产出，**不表示验证通过**；本文件不构成任何下游节点的通过凭据——空段下 impl/detail 的前置本就不是它（见「当前节点」与控制器裁定 Ruling 18、Ruling 20）。这是同一取值集合缺口的第二次显形："已证"在本行与该节点自述的"不表示验证通过"共用同一字面值，属取值重载，如实记为敞开缺口、本轮不修，见 `docs/plan/spec-replay/drift-log.md`「verify/basic」条目）
- impl/detail：已走完 — `step1/impl/detail.md`（节点已走完，四节齐备；T-D1–T-D6 六个任务全部落地——5 个文件编辑合计 `+7 −105` 行，加 `templates/.themis/core/` 98 个文件整体删除，命令与真实输出见该文件「命令记录」。前置依据是控制器裁定 Ruling 18，见「当前节点」。**取值说明**：本行的"已证"含义与 impl/basic 行相同，只表示本节点已走完、其产出已在，**不含**任何关于判据是否满足的结论——那属 verify/detail。本节点自陈的偏差为"落地范围无偏差"，另标出四点：空行分隔符处理是 `design.md` 未定、由本节点当场定的一条规则，以及三处顺带修复的记录缺陷，逐条见该文件「与批准范围的偏差」）
- verify/detail：passed — `step1/verify/detail.md`「结论」（`specify.md` 四条判据逐条断言、四条全部满足；实际删除区间与 `design.md` 所载区间相减，非空行差额 0、空行差额 7 且七行长度均为 0，未越出批准范围；Go 侧构建与测试通过、通过包数 10。孤儿判定一并在本节点完成：**不存在孤儿**——basic 段 `### T-B` 条目数 0，无可判对象，该结论供 `acceptance.md` 阻断核查引用。`rules.md` §7 身份独立**本节点首次成立**：与 `step1/impl/detail.md` 比对，派发任务、会话、起始 HEAD 三项均不同。本行取值 `passed` 是验证型节点的正常取值，与 verify/basic 行那个重载的"已证"不同，此处名副其实）
- 人工验收：accepted — `step1/acceptance.md`「结论」（所有者原话三条逐字见该文件「用户原话」：`a` / `accepted` / `验收后作为新 step 处理`。**录入说明**：首条只回「阻断核查」第 5 项的选项字母、不含验收结论，验收结论与残留项走法由随后两次追问取得，选定内容即后两条。三项阻断核查均不阻断。**两项带出未关闭**：`templates/.themis/workspace/README.md:5` 的范围外残留经所有者裁定作为**新 step** 处理，不并入本 step、不触发回退、本 step 已批准工件不标 stale；`catalog.md:33` 的开放决策点未因本次验收关闭——判据由"找到'延后'这一明确决定"满足，决定内容仍是延后）
- 摘要：已走完 — `step1/summary.md`（三节齐备，绑定 accepted 的实际交付；`flow.md`「摘要」节所称链尾。**取值说明**：本行"已证"含义与 impl 两行相同——本节点已走完、其产出已在，本 step 的流程闭环由本行合拢）

### step2（未开始）

承担 `Intent.md`「step 分解」的 step2 项：清除 `templates/.themis/workspace/README.md:5` 的 Core 主语描述。十一个 step 级节点全部未开始。

- step 定界：未开始 — 无
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

- `Intent.md`：current（已按 R1 结论所附所有者表态更新期望结果节与来源引用小节：`.gitignore` 规则、`AGENTS.md`"与 core/ 的关系"一节均已确认；`catalog.md` 相对路径引用处理方式仍未确定，明确延后，待单独审阅。此次更新与 `flow.md` R1 节失效波及条款的适用边界存在解读空当，按结论闭环处理，未触发重新评审，详见 `docs/plan/spec-replay/drift-log.md` R1 条目。**追加**：本轮又按 R2 结论所附所有者表态（"appreved。 1. 接受。2. 宽度。3. 纳入"）更新范围/期望结果/核心链路三节——六处活跃引用改记为七处，纳入仓库根 `AGENTS.md:13`；`CLAUDE.themis.md`/`README.md` 删节口径记为宽读。与 R1 条目同型的解读空当再度适用：本次更新是誊写 R2 评审者本人批复、且不超出其内容，按控制器裁定不触发 stale，见 `docs/plan/spec-replay/drift-log.md` R2 条目）
- `QA.md`：current（第 1、2 轮均已追加答复，不覆盖不回填；本轮未新增轮次——R2 结论走的是 `design-review.md`「结论」通道，不是 `QA.md` 追问通道）
- `intent-review.md`：current（R1 approved，结论小节已记所有者原话；未解决反馈第 3 条仍未解决，作为开放决策点带入后续节点）
- `step1/specify.md`：current（本轮新增 `SPEC-COREREMOVAL-004`，闭合仓库根 `AGENTS.md:13` 的判据覆盖缺口；命令已真实核验可执行，见 `design-review.md` 与 `drift-log.md` R2 条目）
- `step1/design-review.md`：current（R2 approved，结论小节已记所有者原话；未解决反馈三条中前两条经 R2 批复关闭，第三条——`catalog.md:33`——仍未解决，未随 R2 通过而被标记已决）
- `step1/design.md`：current（本轮已按 R2 结论完成修订，不再是上一程那份 stale 草稿）——"结构决策"第 1、2 条（`CLAUDE.themis.md`/`README.md`）已改写为宽读逐节判定，与 R2 已确认的口径一致；第 7 条（仓库根 `AGENTS.md:13`）已由"范围外新发现、不处理"改为纳入范围并给出处理做法；"事实依据"两处事实错误已订正（命中行数 14→16；`CHANGES.md:41,81,82` 的分类理由不再依赖经 `git ls-files` 核验并不存在的 `docs/core/`）。另在本轮自查重跑命令时发现并订正四处行号区间错误（`CLAUDE.themis.md`「控制架构」「关键路径」、`README.md`「产品主链」，以及被合并记为一节的「Authority scopes」/「权威模型」），核验命令与输出见该文件「事实依据」命令 8。第 5、6 条未改动——`templates/.themis/spec/README.md` 沿用既有裁定不改，`catalog.md:33` 仍是唯一开放决策点，本轮未为其定做法
- `step1/task/basic.md`、`step1/task/detail.md`：current（`basic.md` 为空段并写明判定依据；`detail.md` 为 T-D1–T-D6，其中 T-D3 末句的落地顺序建议已按所有者 R3 批复"删掉这句"删除，经过记在 `task/review.md`「分类核查」第 5 条）
- `step1/task/review.md`：current（R3 approved，「结论」小节已记所有者逐字原话；「未解决反馈」经所有者批复"确认不计入"后清空，无遗留待回应项。本轮补记任务 4 那次编辑中未声明的删改——据 `git diff f04d721 c675c07` 逐段核出：「分类核查」第 8 条第二项失去四段文字加一处词级改动（含一句面向评审者的判定请求），第 5 条被同型改写四处；逐段清单、依据的 diff 命令与不恢复原文的理由已写进第 8 条第二项末尾的补记，第 5 条末尾留有指向。补记的第一版只凭眼看、仅披露两段，跑 diff 后才补全，这次复发记入 `docs/plan/spec-replay/drift-log.md`。「结论」原话与分类判定均未改动。**本轮（任务 6）第三次补披露**：把同一条 diff 的两版原行按标点切段后逐段机械比对，核出「分类核查」第 5 条那次编辑实为八处改动，补记原列四处、另四处字词级改动未列，且其中一处的定性由"删去限定语"更正为整句改写；第 8 条第二项所列五处经同法比对无遗漏。补记已按比对结果重写，第 5 条末尾那句指向随之改数。仍只增加披露、不恢复原文、不动「结论」原话与分类判定；命令与真实输出见 `step1/impl/detail.md`「命令记录」命令 D7）
- `step1/impl/basic.md`：current（上一轮产出；本段为空、零落地调用，该节点执行时 `templates/` 下无任何文件被改动——这一记述是对当时的记录，不因 impl/detail 已落地而失效。**本轮（任务 6）就地更正一处失准描述**：「与批准范围的偏差」第 2 条（c）原写作只补记了 `task/review.md`「分类核查」第 8 条第二项那次修剪，而披露范围其后已两次扩大，现按 `state.md` 本节 `task/review.md` 一行的准确版本改写。只改这一处描述，该文件其余各节未动）
- `step1/verify/basic.md`：current（上一轮产出；「结论」未取 passed/failed，理由见该文件「结论」。该文件「说明」记的两处控制面无一致答案：一处是空段下本节点是否本该发生，至今仍无一致答案；另一处是 fail-closed 是否适用于"不可判"，已由控制器裁定 Ruling 20 给出取向——不触发 fail-closed，见「当前节点」——但条款本身的空白未修，控制面仍无一致答案。**本行本轮只补齐后一处的裁定口径，与其余各行看齐**，该文件正文未改动）
- `step1/impl/detail.md`：current（本轮产出；四节齐备，「执行身份」如实记本次会话，未预写 verify/detail 一方的身份；「实际改动」逐条对回 T-D1–T-D6，每个数字都由本节点当场跑命令得出并粘贴在「命令记录」；「与批准范围的偏差」记"落地范围无偏差"外加四点如实标出。该文件不含任何验证结论）
- `step1/verify/detail.md`：current（五节齐备，结论 `passed`；四条判据的每个数字均由本节点当场跑命令得出、输出原样粘在「命令证据」并在收尾重跑比对；`impl/detail.md` 的自述在其中只作被核验对象，不作证据。「说明」如实写出三样核验不动的东西——控制面"一字未改"的证据排除不了"改后精确改回"、对方身份栏的真伪、实现者的推理过程——以及一处不落在任何判据范围内的范围外残留）
- `step1/acceptance.md`：current（四节齐备，结论 accepted；「用户原话」逐字录入所有者三条答复并附录入说明——首条 `a` 只回残留项选项字母、不含验收结论，故就验收结论与残留走法两项分别追问后取得后两条。「阻断核查」三项均不阻断，另如实转达三处知情项与一处需表态项，后者已由所有者裁定）
- `step1/summary.md`：current（三节齐备，链尾工件；绑定 accepted 所放行的实际交付，不含带出的两项。「中性工件说明」按 `SPEC-THEMICO-002` 写明本摘要与 Themico 无关、是否接入由可选 adapter 决定且不构成运行前提。依 `rules.md` §9，链尾工件在产出时由摘要作者自检，下一次被引用时由引用方复核）

- `step1/scope.md`：current（2026-08-24 补写，三节齐备；内容全部取自 step1 已 accepted 的工件，无一处新增判断。补写不使 step1 失效，依据见「当前节点」第 2 点）
- `Intent.md`（2026-08-24 追加）：仍为 current。新增「step 分解」小节，按 `flow.md`「R1 意图评审」节的失效级联例外**不触发 stale**——该例外只覆盖"仅新增或细化分解项、不改变任何已有 step 目标语义"的修订，本次修订正落在此范围内：step1 的目标、期望结果、核心链路、范围与非做一字未改。**新增的 step2 分解项仍须经 R1 评审者确认**，确认前 step2 不得进入 step 定界之后的任何节点。

**step1 全部工件均为 current，无 stale。** 验收未触发任何回退，所有者裁定的残留另起新 step，不使 step1 任何工件失效；2026-08-24 的结构调整同样不使其失效（依据同上）。仍然敞开的东西不属于当前性问题，如实留在此处：`catalog.md:33` 的开放决策点（内容仍是"延后"，且经 R1 分解确认**不作为 step 存在**）。**控制面那两处互斥读法已于 2026-08-24 修复**——下文原记"绕开但未修复"是当时的事实，保留不改，逐条见 `docs/plan/spec-replay/drift-log.md`。
