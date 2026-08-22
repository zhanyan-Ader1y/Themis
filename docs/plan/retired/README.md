# 已退役的编号 Plan

本目录保存**已退役、不再推进**的编号 Plan。它们是 `templates/.themis/` 旧 core 体系的产物，与当前主线（根目录 `.themis/spec/`）不共用一套合同。

**内容完整保留，不得改写。** 这里的文件是历史证据——Plan 35 的验收审计、静态核验输出、十六场景人工 replay 记录等，记录的是当时的事实。`core-removal` replay 实例的 `Intent.md`、`QA.md`、`verify/detail.md` 都明确把这些归档记录排除在改写范围之外，并把"零改动"作为验收判据之一核验过。退役是**停止推进**，不是删除，也不是修订。

## 退役日期与依据

**2026-08-22**，经项目所有者(zhanyan)批准。

直接依据是 `templates/.themis/core/` 已于同日被删除（98 个文件，由 `.themis/spec/` 落地⑤ 端到端 replay 的 impl/detail 节点在 R3 批准后执行，见 `docs/plan/spec-replay/`）。**Plan 35/36/37 的实现载体已不存在**：Plan 35 定义的十六个 Capability、Prompt-level 合同与工件模板全部位于被删除的 `core/` 下；Plan 36 依赖 Plan 35 重新接受后才能重基线；Plan 37 依赖 Plan 36。

Plan 80/90 不依赖 `core/`，但同属旧编号体系，一并退役以免 `docs/plan/` 长期并存两套计划体系。

## 退役时各 Plan 的状态

| Plan | 退役时状态 |
| --- | --- |
| 35 Core Contract Replacement | Markdown authority cutover、静态证据、十六场景人工 replay 与 criteria 1–31 重映射已完成；**criterion 32 始终未获用户明确重新接受** |
| 36 Deterministic Assurance | 未实施。暂停中，等待 Plan 35 criterion 32 通过后完整重基线 |
| 37 Native Runtime | 未实施。暂停中，等待 Plan 36 |
| 80 Multi-Agent Execution | 未实施。可选，待单独确认 |
| 90 Attribution Analytics | 未实施。可选，待单独确认 |

Plan 35 于 2026-07-31 在当时 YAML 表示下完成过实现、核验与明确重新接受，**该事实作为历史基线保留，不因退役而改写为从未发生**。其后的 Markdown-first 表示迁移未走完最后一步。

## 关于指向旧路径的引用

本次退役用 `git mv` 整体移动,历史可追。仓库里仍有多处文本写着移动前的路径(`docs/plan/35-core-prompt-flow/…` 等),主要在 `docs/superpowers/plans/` 下的历史实施计划,以及 `core-removal` replay 实例工件中。

**这些一律不改写。** 它们记录的是当时的事实——历史计划写的是它当时要改哪个文件,replay 工件写的是它当时核验了哪个目录零改动。改写它们会把证据改成结论,与本目录内容"不得改写"是同一条理由。读者按本 README 的映射自行换算即可。

## 若将来要重启

不得直接从本目录取用。这些计划的 authority 已随 `core/` 一同退场，**必须依届时的 current contracts 整体重基线并重新审批**，本目录内容只作历史参考。

当前主线的已批准行为契约在 `docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md`，控制面在 `.themis/spec/`。
