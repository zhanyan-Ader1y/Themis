# Intent.md — core-removal

> 状态：Intake 已产出来源引用初始条目；追问第 1 轮问题已提出，答复待所有者回复。本文件"问题 / 期望结果 / 核心链路"三节为当前理解草稿，收敛判据见 `rules.md` §2，未收敛前不得视为定案——详见 `QA.md`。

## 问题

`core/` 是 simple/full 双路径模型，与已批准的单一路径契约冲突（来源见"来源引用"）。设计已定 core 在 spec 落地后整体删除（来源缺口待复核，见"来源引用"该条），但删除动作至今未执行，且 `templates/.themis/` 下仍有六处活跃引用指向它，删除前需先厘清这些引用如何处理。

“为什么是现在”这一层仍待所有者确认，见 `QA.md` 第 1 轮问 1。

## 期望结果

`templates/.themis/core/`（当前 98 个文件）从代码库中整体消失；`templates/.themis/` 下六处活跃引用（见"来源引用"）不再指向不存在的路径——具体是重写还是整体退场，待所有者确认，见 `QA.md` 第 1 轮问 2；`.gitignore` 中对应的忽略规则同步处理，不留失效条目。

## 核心链路

从当前状态（98 个文件、`templates/.themis/` 下六处活跃引用、`.gitignore` 一条忽略规则）到目标状态（`core/` 不存在、引用已处理），必须经过本 spec 实例走完 `flow.md` 的节点序列：抽象设计 → R2 → 详细设计+任务 → R3 → impl（删除动作只在 R3 批准后执行，计划全局约束）→ verify → 人工验收。

是否还有本计划未枚举的必要动作（例如 `docs/` 下历史文档对 `core/` 的引用是否需要同步处理），待所有者确认，见 `QA.md` 第 1 轮问 4。

## 范围与非做

**范围**：删除 `templates/.themis/core/`；处理"来源引用"中列出的 `templates/.themis/` 下六处活跃引用；同步处理 `.gitignore` 对应规则。

**非做（暂定，待 QA 确认）**：不处理 `docs/` 下历史文档（`docs/plan/35-core-prompt-flow/`、`docs/superpowers/plans/`、`docs/superpowers/specs/` 等）中对 `core/` 路径的历史引用——这些是 Plan 35 已完成工作的证据记录，数量远大于六处活跃引用（见"来源引用"）。是否需要同步处理待所有者确认，见 `QA.md` 第 1 轮问 4。

不修改 `.themis/spec/` 四份只读控制面文件本身（计划全局约束）。

## 约束

- 删除动作仅在 impl 节点执行，且仅在 R3 获得批准后（计划全局约束）；批准前不得删除任何文件。
- `.themis/workspace/spec/core-removal/` 是本实例唯一可写处，结构与小节按 `template.md`。
- 本工件引用控制面处的方式，判据见 `templates/.themis/AGENTS.md` "引用只指向，不复述"一节。
- `templates/.themis/spec/README.md` 既是本次删除要改动的对象，又是 replay 正依据的只读控制面 `.themis/spec/README.md` 的包源，二者处理方式的决定权在抽象设计节点（`step1/design.md`），本节点不预判。

## 来源引用

- 代码#`templates/.themis/core/policies/README.md:14,47`（`selected_path` 为控制规则四维之一、`Planning` route 含 `themis-simple-plan` capability，为 simple/full 双路径模型的直接代码痕迹）
- 代码#`templates/.themis/core/kernel/orchestrator/rules.md:84`（"Simple/full 只在 Plan 前分叉，形成同一 Plan family 并在 Review 前汇合"，双路径模型的更直接代码佐证）
- spec#`docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md:20`（已批准单一路径契约："Themis 不设简易/完整之分,流程是唯一单一路径,且不为任何未来的双路径做预留、开关或切换"）——本 claim 以上两条代码引用为主，本条为辅，判据见 `rules.md` §1
- spec#`docs/superpowers/specs/2026-08-12-themis-spec-control-plane-design.md:15`（处置已定："spec 完全独立于 core,不引用它的任何合同;core 在 spec 落地后删除"）——本 claim 目前只找到本条来源，判据见 `rules.md` §1；记为一处来源缺口，见 `docs/plan/spec-replay/drift-log.md` Intake 条目
- 代码#`templates/.themis/core`（`find templates/.themis/core -type f | wc -l` 得 98；`git grep -n 'core/' -- templates/.themis/` 排除 `.themico/core` 与 `core/` 自身后得六处活跃引用；命令与完整输出见 `task-1-report.md`）
- 代码#`.gitignore:8`（`/.themis/core/` 忽略规则）
- 代码#`docs`（`git grep -c 'templates/\.themis/core|\.themis/core' -- 'docs/**'` 得 36 个文件、396 行历史引用，不在"六处活跃引用"之列；命令与输出见 `task-1-report.md`）
