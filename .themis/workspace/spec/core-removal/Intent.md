# Intent.md — core-removal

> 状态：Intake 已产出来源引用初始条目；追问第 1、2 轮均已获所有者答复，见 `QA.md`。Agent 据此提出收敛主张，判据与判定者见 `rules.md` §2——确认权归 R1 评审者，R1 批准前本文件仍为待评审状态。

## 问题

`core/` 是 simple/full 双路径模型，与已批准的单一路径契约冲突（来源见"来源引用"）。设计已定 core 在 spec 落地后整体删除；该 claim 此前只有 spec 来源，来源缺口已由所有者确认闭合（见"来源引用"该条）。删除动作至今未执行，且共有七处活跃引用指向它（六处在 `templates/.themis/` 下，一处为仓库根 `AGENTS.md:13`，经 R2 结论确认纳入），删除前需先厘清这些引用如何处理。

“为什么是现在”已获所有者答复：先核实本仓库之外没有项目仍依赖 `core/` 路径，无误则删除；追加答复进一步收窄为“没有外部依赖，仅需检查当前项目”，即由"来源引用"里活跃引用的清点覆盖（清点最初得六处，R2 结论确认再纳入仓库根 `AGENTS.md:13` 后共七处）。因此 R3 获批仍是唯一解锁条件，不新增独立前置（来源见 `QA.md` 第 1 轮问 1、第 2 轮）。

## 期望结果

`templates/.themis/core/`（当前 98 个文件）从代码库中整体消失（所有者已确认整体删除，见 `QA.md` 第 2 轮）。"来源引用"列出的七处活跃引用中，`templates/.themis/CLAUDE.themis.md`、`templates/.themis/README.md` 涉及 core 的相关内容按所有者确认删节，留待 Themis 更完善后再编写，两处处理方式一致（来源见 `QA.md` 第 1 轮问 2）；删节口径经 R2 结论确认为**宽读**——凡依赖 core 架构才有意义的整节内容一并处理，不局限于字面出现 `core/` 路径的行（来源见"来源引用"R2 结论新增条目；具体改法属结构决策，落在 `step1/design.md`，本文件只记这一口径本身）；`templates/.themis/spec/README.md` 的处理方式确认沿用"约束"节所述的现有裁定（来源见 `QA.md` 第 1 轮问 3）；`templates/.themis/AGENTS.md`"与 core/ 的关系"一节确认删除（来源见"来源引用"R1 结论新增条目）；`.gitignore` 中 `/.themis/core/` 忽略规则确认列入本次处理范围（来源见"来源引用"新增条目，背景说明见该条）；仓库根 `AGENTS.md:13` 的索引描述经 R2 结论确认纳入本次范围，成为第七处引用点（来源见"来源引用"R2 结论新增条目）。`catalog.md:33` 的相对路径引用处理方式**仍未确定**——所有者已在同一次批复中明确要求延后：待本次其余处理完成后另行提出处理方案，由所有者单独审阅（来源同上）；本项作为开放决策点带入后续节点，不在本文件内定下做法。

## 核心链路

从当前状态（98 个文件、七处活跃引用——六处在 `templates/.themis/` 下、一处在仓库根 `AGENTS.md`（经 R2 确认纳入）、`.gitignore` 一条忽略规则）到目标状态（`core/` 不存在、引用已处理），需求本身的核心链路是：厘清七处活跃引用各自的处理方式 → 删除 `templates/.themis/core/` → 核验无残留引用与无失效忽略规则。

本 spec 实例走 `flow.md` 的十三个节点序列（抽象设计 → R2 → 详细设计+任务 → R3 → impl → verify → 人工验收）是这次 replay 验证控制面的手段，不是需求本身的核心链路——两者不应混同，避免后续 specify/design 把"流程要求"误当"需求要求"。删除动作仅在 impl 节点执行，且仅在 R3 批准后（计划全局约束）。

`docs/` 下历史文档对 `core/` 的引用是否需要同步处理：所有者已确认排除，不在本次核心链路范围内（来源见 `QA.md` 第 1 轮问 4）。

## 范围与非做

**范围**：删除 `templates/.themis/core/`；处理"来源引用"中列出的七处活跃引用（六处在 `templates/.themis/` 下，一处为仓库根 `AGENTS.md:13`，经 R2 结论确认纳入）；同步处理 `.gitignore` 对应规则。

**非做**：不处理 `docs/` 下历史文档（`docs/plan/35-core-prompt-flow/`、`docs/superpowers/plans/`、`docs/superpowers/specs/` 等）中对 `core/` 路径的历史引用——这些是 Plan 35 已完成工作的证据记录，数量远大于七处活跃引用（见"来源引用"）。所有者已确认排除，见 `QA.md` 第 1 轮问 4。

不修改 `.themis/spec/` 四份只读控制面文件本身（计划全局约束）。

## 约束

- 删除动作仅在 impl 节点执行，且仅在 R3 获得批准后（计划全局约束）；批准前不得删除任何文件。
- `.themis/workspace/spec/core-removal/` 是本实例唯一可写处，结构与小节按 `template.md`。
- 本工件引用控制面处的方式，判据见 `templates/.themis/AGENTS.md` "引用只指向，不复述"一节。
- `templates/.themis/spec/README.md` 既是本次删除要改动的对象，又是 replay 正依据的只读控制面 `.themis/spec/README.md` 的包源；处理方式沿用既有裁定——replay 期间不重装，分歧记入 `step1/design.md` 与漂移清单，具体决定权在抽象设计节点。所有者已确认沿用此裁定，见 `QA.md` 第 1 轮问 3。

## step 分解

> 本小节为 2026-08-24 新增，依 `flow.md`「R1 意图评审」节的失效级联例外：仅新增分解项、不改变任何已有 step 的目标语义，因此**不使已 accepted 的 step1 失效**。step1 当初被批准时所依据的前提（目标、期望结果、核心链路、范围与非做）本次一字未改。新增的 step2 分解项须经 R1 评审者确认。

本需求是**清除 `templates/.themis/` 下的旧 core 体系残留**，拆为两个大步骤，全部完成才算需求达成：

- **step1 — 删除 `core/` 目录本体与其活跃引用。** 承担"期望结果"所载的主体：`templates/.themis/core/` 98 个文件整体消失，七处活跃引用与 `.gitignore` 一条规则处理完毕。**状态：已完成，2026-08-22 验收 accepted**（见 `step1/acceptance.md`）。
- **step2 — 清除范围外残留的 Core 主语描述。** 承担 step1 判据范围之外、但同属本需求的一处残留：`templates/.themis/workspace/README.md:5` 一句以 Core 为主语、陈述 Core 与 Workspace 读写关系的话。它在 step1 的 verify/detail 中被发现并如实标出（不含带斜杠的 `core/` 字串，不进 `SPEC-COREREMOVAL-001` 命中集；也不在 `design.md`「架构与边界」清点的 5 个文件内），由所有者在 step1 人工验收中裁定"验收后作为新 step 处理"。**状态：未开始。**

**不在本需求范围内、不作为 step 存在**：`templates/.themis/workspace/context/catalog.md:33` 的相对路径引用。它是所有者自 R1 起点名延后的开放决策点，"延后"是一个明确决定而非待办；何时处理、是否处理由所有者另行决定，不由本需求的完成判定牵制。

## 来源引用

- 代码#`templates/.themis/core/policies/README.md:14,47`（`selected_path` 为控制规则四维之一、`Planning` route 含 `themis-simple-plan` capability，为 simple/full 双路径模型的直接代码痕迹）
- 代码#`templates/.themis/core/kernel/orchestrator/rules.md:84`（"Simple/full 只在 Plan 前分叉，形成同一 Plan family 并在 Review 前汇合"，双路径模型的更直接代码佐证）
- spec#`docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md:20`（已批准单一路径契约："Themis 不设简易/完整之分,流程是唯一单一路径,且不为任何未来的双路径做预留、开关或切换"）——本 claim 以上两条代码引用为主，本条为辅，判据见 `rules.md` §1
- 用户确认#`是 整体删除。没有外部依赖 仅需要检查当前项目是否有依赖。`（`QA.md` 第 2 轮答复，闭合了"core 是否整体删除"这条目标 claim 此前只有 spec 来源的缺口，判据见 `rules.md` §1）
- spec#`docs/superpowers/specs/2026-08-12-themis-spec-control-plane-design.md:15`（处置已定："spec 完全独立于 core,不引用它的任何合同;core 在 spec 落地后删除"）——现为辅助来源，主来源为上一条用户确认
- 代码#`templates/.themis/core`（`find templates/.themis/core -type f | wc -l` 得 98；`git grep -n 'core/' -- templates/.themis/` 排除 `.themico/core` 与 `core/` 自身后得六处活跃引用；命令与完整输出见 `task-1-report.md`）
- 代码#`.gitignore:8`（`/.themis/core/` 忽略规则）
- 代码#`docs`（`git grep -c 'templates/\.themis/core|\.themis/core' -- 'docs/**'` 得 36 个文件、396 行历史引用，不在"六处活跃引用"之列；命令与输出见 `task-1-report.md`）
- 用户确认#`「1. .gitignore列入本次范围。」`（R1 结论所附表态，见 `intent-review.md` 结论；闭合"`.gitignore` 忽略规则是否处理"这一此前只是清点推导的追加项，判据见 `rules.md` §1）
- 用户确认#`「2. 删除。」`（R1 结论所附表态，见 `intent-review.md` 结论；对应"未解决反馈"第 2 条——`templates/.themis/AGENTS.md`"与 core/ 的关系"一节的处理方式）
- 用户确认#`「3. 完成以上任务后再描述第3点的处理方案由我审阅」`（R1 结论所附表态，见 `intent-review.md` 结论；明确延后 `catalog.md:33` 相对路径引用的处理方案，本条只记录"延后、待单独审阅"这一状态本身，不构成处置结论）
- 用户确认#`「appreved。 1. 接受。2. 宽度。3. 纳入」`（R2 结论逐字原话，见 `step1/design-review.md` 结论；`appreved` 为 `approved` 笔误、`宽度` 为"宽读"笔误，原样记录不改错字。落点：1. `design.md` 顺序偏离——按接受处理；2. `CLAUDE.themis.md`/`README.md` 涉及 core 内容的删节口径确认为宽读；3. 仓库根 `AGENTS.md:13` 纳入本次范围，成为第七处引用点。`catalog.md:33` 不在本次批复范围内，仍未解决）
