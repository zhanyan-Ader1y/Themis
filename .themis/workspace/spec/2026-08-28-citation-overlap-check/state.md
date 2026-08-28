# state.md — 2026-08-28-citation-overlap-check

> 各闸门行内格式：`- <节点名>：<结论> — <证据路径>`。结论取值由 `flow.md` 通用状态条款按节点类型固定，本文件不自建约定。

## 当前节点

**本需求已完成。** 两个 step 全部走完并经人工验收：step1 交付 `themis overlap`，step2 用它修掉报出的五处复述、并用它验证归零。

**交付后仍开着的四项**见 `step2/summary.md`，其中最要紧的一项：**`overlap` 报 `0` 不等于确实无复述**——只等于"无未被四条经验规则排除的重合"，那是本工具能力的上限。

**step1 与 step2 均 accepted**。新增 step2 时未触动 step1 的目标语义，其 accepted 结论全程有效，并已由 R1 第 2 轮追认。

## 各闸门

### spec 级

- Intake：已走完 — `Intent.md`（**未停留在清单记载，当场实测**：首次 shell 滑窗两分钟超时，改 Go 秒级完成；`91` 处片段中读出 `3` 处真违规，其中一处是本会话执行者两个需求前所写、过四道闸门无人发现）
- 追问：已走完 — `QA.md` 第 1 轮（**零提问**。四项候选问题逐条核对后全部可从既有事实或已批准记录推出，依 `rules.md` §2 新补的提问资格判据不提出；同时说明为何不属第三条拒绝条件）
- R1 意图评审：approved — `intent-review.md`「结论」（所有者原话"批准"）。**step2 的分解项为本次新增，待 R1 再次确认**

### step 级

### step1 — 重叠检测子命令（已完成）

- step 定界：已走完 — `step1/scope.md`（**首次按 `flow.md` R2 节新增条款主动列出会触及的既有裁定**——白名单只读命令不触及、`go` 不放行触及、不改证据不触及）
- 抽象设计：已走完 — `step1/specify.md`（五条条目，001 带 `[basic]`、005 带 `[横切]`；001–004 落地前实跑均为 `0`）
- R2 抽象设计评审：approved — `step1/design-review.md`「结论」（所有者原话"批准"；**判据与边界的交叉核查记入工件，该条款第一次实际检验通过**——冲突在抽象设计阶段即摆出，而非拖到落地）
- 详细设计+任务：已走完 — `step1/design.md` 与两份任务文件（四条结构决策，两条由实测定；**实测中报出既有实例一处缺陷**——`2026-08-27-claim-command-evidence/step2` 声明带 `[basic]` 而条目标题实际没带，不改它、交人工裁定）
- R3 详细方案评审：approved — `step1/task/review.md`「结论」（所有者原话"批准"；**本 spec 三次评审均只含一个待裁定项**，源于提问前先穷尽既有依据）
- impl/basic：不适用 — basic 段为空
- verify/basic：不适用 — 同上
- impl/detail：已走完 — `step1/impl/detail.md`（三条任务全部落地；**三处偏离批准范围全部由实跑或测试抓到**，其中拟定的顿号规则会排除掉本需求要找的那处违规——**工具差点把自己要找的东西过滤掉**）
- verify/detail：passed — `step1/verify/detail.md`（五条判据全满足，两环均通；**对真实控制面零误报**，报出五处逐条核实成立，其中三处此前从未被发现）
- 人工验收：accepted — `step1/acceptance.md`「结论」（所有者原话"一起修了"。**该答复推翻投影推荐**（原推荐"仍不修"），裁定一并修复；**未直接就批准与否表态，本节点判定其蕴含接受并如实标明这是推断**）
- 摘要：已走完 — `step1/summary.md`（绑定 accepted 的交付，带出未关闭的四项）

### step2 — 修掉五处复述（已完成）

**依赖 step1**：不先有工具，就不知道要修哪些、也无法验证修完是否干净。

- R1 分解项确认：approved — `intent-review.md`「第 2 轮」（所有者原话"确认"；**同时追认 step1 的 accepted 结论**——此前那是本节点的推断）
- step 定界：已走完 — `step2/scope.md`（逐处打开两端原文核对；**发现第 5 处性质不同**——不是复述而是归属未定，两侧都不是引用另一份。已标出交 R2）
- 抽象设计：已走完 — `step2/specify.md`（五条条目，005 带 `[横切]`；落地前实跑均为待修状态）
- R2 抽象设计评审：**授权代行（非 approved）** — `step2/design-review.md`（所有者答"按你的判断继续"，未就内容表态。**三项裁定由执行者作出**，其中裁定二自认无决定性依据）
- 详细设计+任务：已走完 — `step2/design.md` 与两份任务文件（四条结构决策；**结构决策二明写"逐处通读靠人读"**，后被证明必要）
- R3 详细方案评审：**授权代行（非 approved）** — `step2/task/review.md`（沿用 R2 授权）
- impl/basic、verify/basic：不适用 — basic 段为空
- impl/detail：已走完 — `step2/impl/detail.md`（三条任务落地；**一处偏差靠通读抓到**——第 33 行引入重复指向，判据查不出）
- verify/detail：passed — `step2/verify/detail.md`（五条判据全满足，两环均通；**`themis overlap` 报 `0` 处**，step1 的产物验证了 step2 的完成）
- 人工验收：accepted — `step2/acceptance.md`「结论」（所有者原话"批准"；**同时闭合 R2、R3 两处授权代行**，三项代行裁定一并追认，并划定裁定二的效力边界——不构成一般性先例）
- 摘要：已走完 — `step2/summary.md`

## 当前性

- `Intent.md`：current（「step 分解」已增列 step2 并写明新增依据；**step1 的目标语义未被触动**）
- `QA.md`、`intent-review.md`：current
- `step1`、`step2` 全部工件：current（两个 step 均已闭合）
