# Intent.md — core-removal

> 状态：Intake 已产出来源引用初始条目；追问第 1、2 轮均已获所有者答复，见 `QA.md`。Agent 据此提出收敛主张，判据与判定者见 `rules.md` §2——确认权归 R1 评审者，R1 批准前本文件仍为待评审状态。

## 问题

`core/` 是 simple/full 双路径模型，与已批准的单一路径契约冲突（来源见"来源引用"）。设计已定 core 在 spec 落地后整体删除；该 claim 此前只有 spec 来源，来源缺口已由所有者确认闭合（见"来源引用"该条）。删除动作至今未执行，且 `templates/.themis/` 下仍有六处活跃引用指向它，删除前需先厘清这些引用如何处理。

“为什么是现在”已获所有者答复：先核实本仓库之外没有项目仍依赖 `core/` 路径，无误则删除；追加答复进一步收窄为“没有外部依赖，仅需检查当前项目”，即由"来源引用"里六处活跃引用的清点覆盖。因此 R3 获批仍是唯一解锁条件，不新增独立前置（来源见 `QA.md` 第 1 轮问 1、第 2 轮）。

## 期望结果

`templates/.themis/core/`（当前 98 个文件）从代码库中整体消失（所有者已确认整体删除，见 `QA.md` 第 2 轮）。"来源引用"列出的六处活跃引用中，`templates/.themis/CLAUDE.themis.md`、`templates/.themis/README.md` 涉及 core 的相关内容按所有者确认删节，留待 Themis 更完善后再编写，两处处理方式一致（来源见 `QA.md` 第 1 轮问 2）；`templates/.themis/spec/README.md` 的处理方式确认沿用"约束"节所述的现有裁定（来源见 `QA.md` 第 1 轮问 3）；`AGENTS.md`"与 core/ 的关系"一节与 `catalog.md` 的相对路径引用尚未单独确认处理方式，留待抽象设计节点具体化；`.gitignore` 中对应的忽略规则同步处理，不留失效条目。

## 核心链路

从当前状态（98 个文件、`templates/.themis/` 下六处活跃引用、`.gitignore` 一条忽略规则）到目标状态（`core/` 不存在、引用已处理），需求本身的核心链路是：厘清六处活跃引用各自的处理方式 → 删除 `templates/.themis/core/` → 核验无残留引用与无失效忽略规则。

本 spec 实例走 `flow.md` 的十三个节点序列（抽象设计 → R2 → 详细设计+任务 → R3 → impl → verify → 人工验收）是这次 replay 验证控制面的手段，不是需求本身的核心链路——两者不应混同，避免后续 specify/design 把"流程要求"误当"需求要求"。删除动作仅在 impl 节点执行，且仅在 R3 批准后（计划全局约束）。

`docs/` 下历史文档对 `core/` 的引用是否需要同步处理：所有者已确认排除，不在本次核心链路范围内（来源见 `QA.md` 第 1 轮问 4）。

## 范围与非做

**范围**：删除 `templates/.themis/core/`；处理"来源引用"中列出的 `templates/.themis/` 下六处活跃引用；同步处理 `.gitignore` 对应规则。

**非做**：不处理 `docs/` 下历史文档（`docs/plan/35-core-prompt-flow/`、`docs/superpowers/plans/`、`docs/superpowers/specs/` 等）中对 `core/` 路径的历史引用——这些是 Plan 35 已完成工作的证据记录，数量远大于六处活跃引用（见"来源引用"）。所有者已确认排除，见 `QA.md` 第 1 轮问 4。

不修改 `.themis/spec/` 四份只读控制面文件本身（计划全局约束）。

## 约束

- 删除动作仅在 impl 节点执行，且仅在 R3 获得批准后（计划全局约束）；批准前不得删除任何文件。
- `.themis/workspace/spec/core-removal/` 是本实例唯一可写处，结构与小节按 `template.md`。
- 本工件引用控制面处的方式，判据见 `templates/.themis/AGENTS.md` "引用只指向，不复述"一节。
- `templates/.themis/spec/README.md` 既是本次删除要改动的对象，又是 replay 正依据的只读控制面 `.themis/spec/README.md` 的包源；处理方式沿用既有裁定——replay 期间不重装，分歧记入 `step1/design.md` 与漂移清单，具体决定权在抽象设计节点。所有者已确认沿用此裁定，见 `QA.md` 第 1 轮问 3。

## 来源引用

- 代码#`templates/.themis/core/policies/README.md:14,47`（`selected_path` 为控制规则四维之一、`Planning` route 含 `themis-simple-plan` capability，为 simple/full 双路径模型的直接代码痕迹）
- 代码#`templates/.themis/core/kernel/orchestrator/rules.md:84`（"Simple/full 只在 Plan 前分叉，形成同一 Plan family 并在 Review 前汇合"，双路径模型的更直接代码佐证）
- spec#`docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md:20`（已批准单一路径契约："Themis 不设简易/完整之分,流程是唯一单一路径,且不为任何未来的双路径做预留、开关或切换"）——本 claim 以上两条代码引用为主，本条为辅，判据见 `rules.md` §1
- 用户确认#`是 整体删除。没有外部依赖 仅需要检查当前项目是否有依赖。`（`QA.md` 第 2 轮答复，闭合了"core 是否整体删除"这条目标 claim 此前只有 spec 来源的缺口，判据见 `rules.md` §1）
- spec#`docs/superpowers/specs/2026-08-12-themis-spec-control-plane-design.md:15`（处置已定："spec 完全独立于 core,不引用它的任何合同;core 在 spec 落地后删除"）——现为辅助来源，主来源为上一条用户确认
- 代码#`templates/.themis/core`（`find templates/.themis/core -type f | wc -l` 得 98；`git grep -n 'core/' -- templates/.themis/` 排除 `.themico/core` 与 `core/` 自身后得六处活跃引用；命令与完整输出见 `task-1-report.md`）
- 代码#`.gitignore:8`（`/.themis/core/` 忽略规则）
- 代码#`docs`（`git grep -c 'templates/\.themis/core|\.themis/core' -- 'docs/**'` 得 36 个文件、396 行历史引用，不在"六处活跃引用"之列；命令与输出见 `task-1-report.md`）
