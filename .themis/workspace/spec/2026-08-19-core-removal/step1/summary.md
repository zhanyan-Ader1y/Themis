# summary.md — 2026-08-19-core-removal / step1

> 本文件是摘要节点的实例工件,是本 step 的链尾产出。本节点的前置闸门、产出、失效波及与失败去向见 `flow.md`「摘要」节;三个小节的固定划分见 `template.md`(`summary.md` 一行);工件阐述方式见 `rules.md` §9——链尾工件在产出时由摘要作者自检,并在下一次被引用时由引用方复核。以上各处只指向位置,本文件不复述其文字。
>
> **前置已满足**:`acceptance.md`「结论」为 accepted。本文件绑定的是该结论所放行的实际交付(`SPEC-SUMMARY-001`),不绑定任何未经验收的内容。

## 交付摘要

**做了什么。** 删除 `templates/.themis/core/`,并处理因此断链的活跃引用。这是旧 Plan 35 Prompt-level 合同包的退场——`core/` 承载的十六个 Capability 模板与 protocols 不再是 Themis 的合同来源,当前合同来源是根目录 `.themis/spec/` 控制面四份文件。

**实际交付。** `templates/.themis/core/` **98 个文件**整体删除;5 个文件改动,合计 `+7 −105` 行:

| 文件 | 改动 | 任务 |
| --- | --- | --- |
| `templates/.themis/CLAUDE.themis.md` | 130 → 79 行,七处 | T-D1 |
| `templates/.themis/README.md` | 112 → 72 行,十处 | T-D2 |
| `templates/.themis/AGENTS.md` | 51 → 45 行,末节整节删除 | T-D3 |
| `.gitignore` | 11 → 10 行,`/.themis/core/` 一行删除 | T-D4 |
| 仓库根 `AGENTS.md` | R2 结论纳入的第七处引用 | T-D5 |

`task/detail.md` 六个任务(T-D1 至 T-D6)全部落地,无遗留任务。`task/basic.md` 为空段,本 step 未产生 basic 落地。

**验证结论。** `verify/detail.md` 判 `passed`:`specify.md` 四条行为条目逐条断言、四条全部满足;实际删除区间与批准区间相减,非空行差额 0、仅多删 7 个空行,未越出 R3 批准范围;Go 侧构建与测试通过(10 个包)。判定由独立于实现者的验证角色作出(`rules.md` §7 身份独立成立:派发任务、会话、起始 HEAD 三项均不同)。

**带出的两项,均未随本 step 关闭。**

1. `templates/.themis/workspace/README.md:5` 一句以 Core 为主语的读写关系描述,不落在本 step 任何判据范围内。所有者裁定**作为新 step 处理**,不并入本 step、不触发本 step 回退。
2. `templates/.themis/workspace/context/catalog.md:33` 的相对路径引用,自 R1 起是所有者点名延后的唯一开放决策点。本 step 的判据由"找到'延后'这一明确决定"满足,**决定内容仍是延后**——验收放行不等于该决策点关闭。

**本 step 作为 replay 载体的产出。** 本 step 的真正目的不是删除 `core/`,而是暴露 Agent 在哪些闸门漂移(落地⑤ 的定义,见 `docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md` §5 P4)。漂移记录不在本文件,在 `docs/plan/spec-replay/drift-log.md`——那份清单是落地⑤ 的产品,本文件只记交付事实。本 step 期间控制器对控制面的两处互斥读法下过裁定(Ruling 18、Ruling 20),**两处缺口均未修复**,控制面待修。

## 绑定的验收结论

- **验收结论**:accepted — `acceptance.md`「结论」小节。
- **所有者原话**:`acceptance.md`「用户原话」小节,三条逐字录入(`a` / `accepted` / `验收后作为新 step 处理`),含录入说明——首条只回残留项选项字母、不含验收结论,验收结论由随后追问取得。
- **验收所依据的证据**:`verify/detail.md`「结论」`passed` 与其「命令证据」;三项阻断核查(孤儿不存在、verify 通过、§7 身份独立)见 `acceptance.md`「阻断核查」。
- **授权边界**:本摘要绑定的交付以 R3 批准的 `task/detail.md` 六个任务为界。验收放行的是这个范围内的交付,不含上节「带出的两项」。

本文件不重述上述结论的判定过程,也不为其增加任何未经验收的内容。若后续引用本摘要,应回到上列各工件核对,而非以本文件为事实源。

## 中性工件说明

本摘要是**与 Themico 无关的中性工件**。它的产出、内容与有效性都不依赖 Themico 存在:本 step 从 Intake 到摘要全程未调用 Themico,`.themis/spec/` 控制面四份文件也不含任何 Themico 概念。

是否把本摘要喂给 Themico 作为经验候选,由**可选 adapter** 决定,该决定在本流程之外;无论是否接入,都**不构成本流程的运行前提**(`SPEC-THEMICO-002`)。Themico 缺席时,本 step 的流程完整性、验收有效性与本摘要的可用性均不受影响。

本 step 未产生任何失败预算计数,也未把任何失败转为经验学习——这两项属 Themico,不在 Themis 实现(`SPEC-FAIL-001`)。
