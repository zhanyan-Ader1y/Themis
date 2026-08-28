# scope.md — 2026-08-19-core-removal / step1

> 本文件是 step 定界节点的实例工件。本节点的前置闸门、产出与失效波及见 `flow.md`「step 定界（scope.md）」节；三个小节的固定划分见 `template.md`（`scope.md` 一行）。以上各处只指向位置，本文件不复述其文字。
>
> **本文件为 2026-08-24 补写，step1 执行时该节点尚不存在。** step1 于 2026-08-18 至 2026-08-22 走完时，控制面只有 spec 级 `Intent.md` 一层意图，`scope.md` 与「step 分解」小节都是本次结构修正才引入的。本文件**不追认、不改写** step1 当时的任何判断——它只是把 step1 实际承担的范围按新结构落到应有位置，内容全部取自 step1 已 accepted 的工件，无一处新增。补写本身不使 step1 失效（依据见 `Intent.md`「step 分解」小节的例外说明）。

## 承担的上层分解项

`Intent.md`「step 分解」的 **step1 — 删除 `core/` 目录本体与其活跃引用**。

该项承担上层需求"清除 `templates/.themis/` 下的旧 core 体系残留"的主体部分：目录本体消失，且因其消失而断链的活跃引用全部处理完毕。

## 本 step 边界

**做**：

- 删除 `templates/.themis/core/`（98 个文件）。
- 处理七处活跃引用：`templates/.themis/CLAUDE.themis.md`、`templates/.themis/README.md`、`templates/.themis/AGENTS.md`、`templates/.themis/workspace/context/catalog.md`、`templates/.themis/spec/README.md`、`.gitignore`、仓库根 `AGENTS.md:13`（末项经 R2 结论确认纳入）。

**不做**：

- `docs/` 下历史文档对 `core/` 的引用——归档证据，所有者已确认排除（`QA.md` 第 1 轮问 4）。
- 不修改 `.themis/spec/` 控制面四份文件本身。

**边界的实际判据**：本 step 的四条行为条目（`step1/specify.md` 的 `SPEC-COREREMOVAL-001` 至 `-004`）各自写死了检索范围与判定命令，边界以那四条为准，本文件不重复其内容。

## 与其他 step 的关系

**与 step2 的划界**：step1 的判据范围锚定在带斜杠的 `core/` 字串与 `design.md` 清点的具体文件上；`templates/.themis/workspace/README.md:5` 那句以 Core 为主语的读写关系描述**两项都不落**——不含该字串，也不在那份文件清单里。它因此不属于 step1，由 step2 承担。

这条划界不是事后划的：step1 的 verify/detail 在判定过程中发现了它，如实标出而未擅自扩大判据范围（扩大等于替所有者改验收标准），并交由人工验收决定处置；所有者裁定作为新 step 处理。经过见 `step1/verify/detail.md`「说明」第 4 条与 `step1/acceptance.md`「阻断核查」第 5 项。

**不与任何 step 相关的开放决策点**：`catalog.md:33` 的相对路径引用由所有者自 R1 起点名延后。step1 的 `design.md`「结构决策」第 6 条明写"延后、本轮不定做法"，`SPEC-COREREMOVAL-001` 的 2 条剩余命中之一即由该决定满足判据。它不由 step1 或 step2 承担，理由见 `Intent.md`「step 分解」末段。
