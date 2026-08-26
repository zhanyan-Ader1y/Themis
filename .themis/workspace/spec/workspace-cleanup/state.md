# state.md — workspace-cleanup

> 各闸门行内格式：`- <节点名>：<结论> — <证据路径>`。结论取值由 `flow.md` 通用状态条款按节点类型固定，本文件不自建约定。

## 当前节点

**无——本 spec 实例已闭合，需求达成。** step1 走完全部节点，人工验收 accepted，摘要为链尾。`Intent.md`「step 分解」只载 step1 一项，无第二个大步骤。

**需求范围在追问中扩大**：初始为 `workspace/` 一个包（39 份），经所有者答复 4 与问 5 扩至整个 `templates/.themis/`（48 份），并由问 6 确定控制面改为 `.themis/` 直接入库。R1 一并确认扩大后的需求与 step 分解（一个大步骤）。

**本实例与 `core-removal` 无关**：那是"删除 `core/` 本体与其活跃引用"，已闭合；本实例是新需求"清空 `templates/.themis/` 并把控制面改为 `.themis/` 入库"，另起 spec 实例（`template.md` 明写真正无关的需求另起实例，不作为 step）。

## 各闸门

### spec 级

- Intake：已走完 — `Intent.md`「来源引用」小节（8 条命令来源 + Plan 35 退役事实 + 该包自述 + 用户确认；所有数字均由命令得出，无一处凭印象写入）
- 追问：已走完 — `QA.md` 第 1、2 轮（共六问，全部获所有者答复并闭合；答栏逐字录入原话，未代答）
- R1 意图评审：approved — `intent-review.md`「结论」（所有者原话逐字："批准"；确认需求本身与 step 分解一个大步骤，并把唯一风险点"先迁后删"与等价性核实纳入已确认范围）

### step 级

### step1（进行中）

- step 定界：已走完 — `step1/scope.md`（三节齐备；执行 `Intent.md` 要求的等价性核实时发现四条忽略路径只有 `.themis/spec/` 真实存在，如实标出交 R2，未擅自改做法）
- 抽象设计：已走完 — `step1/specify.md`（五条行为条目，判据均为可执行命令加可判定语义，逐条实跑证实能判失败——见 `design.md` 命令 8）
- R2 抽象设计评审：approved — `step1/design-review.md`「结论」（所有者原话两条逐字："A 接受。B 不补" / "approved"。**录入说明**：首条只裁定两个附带决策点、不含评审结论，Agent 未推断补足，就结论单独追问后取得第二条——与 core-removal 人工验收那次单字母 `a` 同型。裁定 A 接受改动非做项文件（仅限该行路径）；裁定 B 不补 SPEC-WSCLEAN-006，三份迁移文件因此无判据覆盖）
- 详细设计+任务：已走完 — `step1/design.md` 与 `step1/task/basic.md`、`step1/task/detail.md`（三份齐备；basic 段为空并写明逐个候选的判定依据，detail 段六条任务带依赖声明）
- R3 详细方案评审：approved — `step1/task/review.md`「结论」（所有者原话两条逐字："批准" / "允许推迟到动手时定"。**录入说明**：首条只给结论、未答复那条未解决反馈，而 `flow.md` 要求未解决反馈为空才能放行，故单独追问后取得第二条——本 spec 第二次同型处置。裁定：接受把 `AGENTS.md:48-52` 的做法推迟到实现期，是对 `rules.md` §6 的一次显式豁免，仅限本处，impl 须如实记录所选做法与理由）
- impl/basic：已走完 — `step1/impl/basic.md`（零落地调用，空段形态；命令 B1 证实基线到本节点区间内 `templates/` 与 `.gitignore` 零改动，B2 自行数出 T-B 条目数 0）
- verify/basic：不适用 — `step1/verify/basic.md`「结论」（**本 step 是该取值 2026-08-24 新增后的首个使用者**；三项判据一项无断言对象、两项与本段无因果关系。`core-removal` 当时同一处需控制器两次裁定，本次由条款直接给出答案。身份独立在本段不成立，如实记录）
- impl/detail：已走完 — `step1/impl/detail.md`（T-D1–T-D6 六条全部落地；**两处偏差如实标出**——改动一个不在任务对象清单内的 Go 测试文件（六处活引用清点漏检 Go 源码所致），以及 AGENTS.md 一节取改写而非删除（R3 已授权实现期定夺并要求记录理由））
- verify/detail：passed — `step1/verify/detail.md`「结论」（五条判据逐条断言、五条全部满足；孤儿不存在（空段，前提已写明）；越界边界成立，themico 包只改一行。**SPEC-WSCLEAN-003 的判据命令实跑报 DIFF**，本节点用三法互证（忽略行尾、去 CR 字节计数、blob 哈希）确认内容逐字未变，判为判据写法缺陷而非落地缺陷。结论不覆盖三处：三份迁移文件无判据、Go 测试越界待人工裁量、身份独立不成立）
- 人工验收：accepted — `step1/acceptance.md`「结论」（所有者原话两条逐字："批准" / "接受"。**录入说明**：首条未对 Go 测试越界表态，该项由单独追问取得——本 spec 第三次、本项目累计第四次同型处置。三项阻断核查均不阻断；裁定接受 Go 测试文件越界，效力仅限该处断言）
- 摘要：已走完 — `step1/summary.md`（三节齐备，绑定 accepted 的实际交付；另列本 step 带出未关闭的三项与对控制面的一处验证价值）

## 当前性

- `Intent.md`：current（六节齐备并按扩大后的范围重写；三要素齐备、无悬问，已提出收敛主张。「step 分解」写出拟定的一个大步骤，待 R1 确认）
- `QA.md`：current（第 1 轮四问 + 第 2 轮两问，追加写入不覆盖不回填；六问答栏均为所有者原话逐字录入，无一处代答）
- `intent-review.md`：current（R1 approved，结论小节已记所有者原话；未解决反馈为空，无遗留待回应项）

- `step1/scope.md`：current（三节齐备；「本 step 边界」记入本节点核实到的做法收窄——四条忽略路径只有 `.themis/spec/` 真实存在，其余四份无安装副本可转）
- `step1/specify.md`：current（五条行为条目 + 来源覆盖两节；五条判据逐条实跑，当前值全部处于未通过侧。末段明写：若 design 决定保留 `skills/` 或顶层 md 任何一份，须新增条目并重走 R2——该条件已触发，见 `design-review.md` 裁定点 B）
- `step1/design.md`：current（四节齐备，九条命令均当场跑出并附真实输出。**「结构决策」第 2 条与「取舍」第 2 条记录了一次自查推翻初判**：初稿判 `AGENTS.md` 可直接删，理由是"其约束已写在 rules.md §9"；命令 9 核实结果相反，`.themis/spec/` 全文不含该约束，据此改为迁入）
- `step1/design-review.md`：current（R2 approved，结论小节已记所有者两条原话与录入说明；未解决反馈两条经裁定关闭后清空。裁定 B 的代价如实写入结论：三份迁移文件无判据覆盖，verify 不得判其"通过"）
- `step1/task/basic.md`、`step1/task/detail.md`：current（`basic.md` 为空段，逐个候选列出 §4 两条判据的判定——六个候选无一同时满足，本 step 无内部结构层；`detail.md` 为 T-D1–T-D6，带依赖链与出处栏）
- `step1/task/review.md`：current（R3 approved，「结论」已记两条原话与录入说明；未解决反馈经裁定关闭后清空。分类核查五条已产出。**第 2 条记一处推翻**：任务作者拒绝了 `design.md` 的分类建议——该建议只考虑次序、未核对 §4 第二条判据，若照办本 step 会以不成立的 basic 段进入 R3；本节点确认推翻正确。未解决反馈一条待裁定，「结论」待所有者答复）
- `step1/impl/basic.md`：current（零调用，空段形态；两条命令均本节点自行跑出）
- `step1/verify/basic.md`：current（结论「不适用」，本 step 是该取值的首个使用者；身份独立在本段不成立，如实记录）
- `step1/impl/detail.md`：current（六条任务全部落地；两处偏差如实标出，均经裁定放行）
- `step1/verify/detail.md`：current（结论 `passed`，五条判据逐条断言；SPEC-WSCLEAN-003 的判据命令报 DIFF，用三法互证判为判据写法缺陷而非落地缺陷；结论明确不覆盖三处）
- `step1/acceptance.md`：current（accepted，「用户原话」两条逐字并附录入说明；裁定接受 Go 测试越界）
- `step1/summary.md`：current（链尾工件，绑定 accepted 所放行的交付；带出三项未关闭事项）

**本 spec 全部工件均为 current，无 stale。** 验收未触发任何回退。三项带出未关闭事项（三份迁移文件无判据、身份独立不成立、活引用清点方法缺陷）不属当前性问题，逐条见 `step1/summary.md`。
