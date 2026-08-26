# state.md — workspace-cleanup

> 各闸门行内格式：`- <节点名>：<结论> — <证据路径>`。结论取值由 `flow.md` 通用状态条款按节点类型固定，本文件不自建约定。

## 当前节点

**R2 抽象设计评审（等待所有者答复）。** step1 的 scope/specify/design 三份已产出，R2 投影已呈现，「结论」待所有者填入。**未解决反馈两条**（裁定点 A、B），Agent 不预判。

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
- R2 抽象设计评审：进行中 — `step1/design-review.md`（投影已产出，未解决反馈两条待裁定，「结论」待所有者答复）
- 详细设计+任务：进行中 — `step1/design.md` 已产出（为 R2 投影需要 Overview 而提前，与 core-removal step1 同型）；两份任务文件未产出
- R3 详细方案评审：未开始 — 无
- impl/basic：未开始 — 无
- verify/basic：未开始 — 无
- impl/detail：未开始 — 无
- verify/detail：未开始 — 无
- 人工验收：未开始 — 无
- 摘要：未开始 — 无

## 当前性

- `Intent.md`：current（六节齐备并按扩大后的范围重写；三要素齐备、无悬问，已提出收敛主张。「step 分解」写出拟定的一个大步骤，待 R1 确认）
- `QA.md`：current（第 1 轮四问 + 第 2 轮两问，追加写入不覆盖不回填；六问答栏均为所有者原话逐字录入，无一处代答）
- `intent-review.md`：current（R1 approved，结论小节已记所有者原话；未解决反馈为空，无遗留待回应项）

- `step1/scope.md`：current（三节齐备；「本 step 边界」记入本节点核实到的做法收窄——四条忽略路径只有 `.themis/spec/` 真实存在，其余四份无安装副本可转）
- `step1/specify.md`：current（五条行为条目 + 来源覆盖两节；五条判据逐条实跑，当前值全部处于未通过侧。末段明写：若 design 决定保留 `skills/` 或顶层 md 任何一份，须新增条目并重走 R2——该条件已触发，见 `design-review.md` 裁定点 B）
- `step1/design.md`：current（四节齐备，九条命令均当场跑出并附真实输出。**「结构决策」第 2 条与「取舍」第 2 条记录了一次自查推翻初判**：初稿判 `AGENTS.md` 可直接删，理由是"其约束已写在 rules.md §9"；命令 9 核实结果相反，`.themis/spec/` 全文不含该约束，据此改为迁入）
- `step1/design-review.md`：current（投影与未解决反馈已产出；未解决反馈两条——裁定点 A（改动非做项文件是否接受）、裁定点 B（三份迁移文件是否补条目重走 R2）；「结论」空缺待所有者填入）
