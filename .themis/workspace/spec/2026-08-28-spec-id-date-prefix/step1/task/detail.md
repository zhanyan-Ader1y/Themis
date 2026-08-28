# task/detail.md — 2026-08-28-spec-id-date-prefix / step1

> 本文件是详细设计+任务节点的实例工件之一。本节点的前置闸门与产出见 `flow.md`「详细设计+任务」节；每个 `### T-D<n>` 的固定三项见 `template.md`。编号引用写法见 `template.md`「编号引用写法」。以上只指向位置，本文件不复述其文字。

## T-D1 — `template.md` 规定 spec-id 形态

**行为目标**：`template.md` 含 spec-id 的形态规定。

**做法**：

1. 写明格式为 `yyyy-MM-dd-<主题>`。
2. **写明日期取实例创建日**（Intake 产出之日），并写明**它可从 git 取得，不需任何人记忆或约定**。
3. **写明不用序号的理由**——序号需要维护"下一个用几"这个状态；日期前缀天然有序、可从内容自证。**此理由与 `docs/adr/AGENTS.md` 同源，本处只写一层，不复述该文件的论证。**

**对应 `specify.md` 条目**：判据 SPEC-SPECID-001。

**依赖的基础任务**：无。

## T-D2 — 八个目录 `git mv` 改名

**行为目标**：`.themis/workspace/spec/` 下八个目录全部为 `2026-` 前缀。

**做法**：

1. 按 `Intent.md` 表逐个 `git mv`，八个映射为：`core-removal`、`workspace-cleanup`、`authorization-traceability`、`claim-command-evidence`、`trace-number-scan`、`question-eligibility`、`citation-overlap-check`、`gate-value-integrity`，各自加上 `Intent.md` 表所列的创建日期前缀。**此处保留改名前的原名**——写成新名会使映射变成 `X→X`。
2. **用 `git mv` 不用删建**（`design.md` 结构决策一）——保历史。

**对应 `specify.md` 条目**：判据 SPEC-SPECID-002。

**依赖的基础任务**：无。

## T-D3 — 引用分两轮替换，两处例外加注

**行为目标**：指向旧 id 的引用全部更新；两处例外保持原文并各加脉络注。

**做法**：

1. **第一轮**：替换 `workspace/spec/<旧 id>` 这种带路径前缀的形态——**可全自动**，路径不会出现在两处例外里。
2. **第二轮**：逐处确认剩余的裸 id。**不可全自动**（`design.md` 结构决策二）——两处例外正是裸 id 形态。
3. **两处例外**：`docs/superpowers/plans/2026-08-19-spec-flow-end-to-end-replay.md` 与两份 `spec-review-presentation/SKILL.md`（`.themis/` 与 `.claude/` 各一），**原文一字不动**，各加一句"该实例现名 `<新 id>`"，**紧邻原文**。
4. **`testing-notes.md` 与 `docs/plan/README.md` 属正常引用**，照第二轮处理。

**对应 `specify.md` 条目**：判据 SPEC-SPECID-003、004。

**依赖的基础任务**：无。**但须在 T-D2 之后执行**——先改名再更新引用，否则引用会指向尚不存在的目录。

## 判据 005 无任务承担，理由

`SPEC-SPECID-005` 带 `[横切]` 标识，验证对象是既有工件与既有测试，**不是本 step 的产出**。

## 执行次序

**T-D1 → T-D2 → T-D3**，**T-D2 与 T-D3 有实质依赖**：必须先改名，再更新引用。
