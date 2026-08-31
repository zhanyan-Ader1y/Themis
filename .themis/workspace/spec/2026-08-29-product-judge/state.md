# state.md — 2026-08-29-product-judge

> 各闸门行内格式：`- <节点名>：<结论> — <证据路径>`。结论取值由 `flow.md` 通用状态条款按节点类型固定，本文件不自建约定。

## 当前节点

**本需求已完成。** step1 走完十四个节点并经人工验收（`accepted`），摘要已产出。

**本实例走完全流程的两处非常规**：一是曾停在 R2——执行者依 §11 判定所引原话不支持对全文的批准，退回澄清后方证；二是验证给出 `passed` 后实现者又改了两处（均为验证角色报出的问题），**使验证工件的行号引用 stale，已在验收前完整披露**。

**本节点曾一度停在 R2**：详细设计的前置闸门是"R2 结论为 approved"，而执行者依 §11 判定所引原话不支持对全文的批准，**判不过则不得引用**，回评审者处澄清。所有者答「是」后闸门方证，记于 `step1/design-review.md`「结论」。

**本文件是补写的。** 产出时机晚于 R2，**由主会话在准备进入详细设计节点时发现缺失**，非判据抓到。**这是同型遗漏的第六次**——`Intent.md` 已记在案的六次里有三次就是 `state.md`，本需求正是为修它而立，却在自己身上又犯了一次。

**同批发现的第二处**：`step1/design-review.md`（R2 闸门工件）同样缺失，一并补写。**合计使同型实发计数由 `6` 增至 `8`**。

**这两次遗漏对本需求的意义**：它们是 `SPEC-PJUDGE-003` 那条"十四条产出项必须都能被判"的现场证据——**遗漏就发生在没有判定者的那十四条产出项上**。

## 各闸门

### spec 级

- Intake：已走完 — `Intent.md`（实测六次工件遗漏分布在四个实例；最近两次都是独立验证子代理在链条倒数第三个节点才报出）
- 追问：已走完 — `QA.md` 第 1 轮问 1（判定时机）、第 2 轮问 2（六条是否一并补全）。两项自行判定未提出，理由记于该文件末节
- R1 意图评审：approved — `intent-review.md`（第 1 轮所有者原话「b」；第 2 轮所有者原话「a」，**该轮扩大了 R1 批准的范围**，执行者呈现时已明写 (a) 超出原分解项字面）

### step 级

### step1 — 配判定者 + 定义 product-judge + 补全小节名（进行中）

- step 定界：已走完 — `step1/scope.md`（**新暴露事实（2）**：`product-judge` 的"小节齐不齐"只覆盖 `8/14`，其余六节点的小节名住在 `template.md`，而 ADR 禁止援引它作事实）
- 抽象设计：已走完 — `step1/specify.md`（六条条目。**判据 005 初稿恒真并当场订正**——初稿断言的是 Intake 节本就写着的内容，与本 step 无关，第 `35` 次同型实发）
- R2 抽象设计评审：approved — `step1/design-review.md`（所有者原话「成立。没有机器兜底是指不确定何时执行还是流程不是规范、固定的」，**前半句覆盖 004/005 所依据的收窄**；效力是否及于全部六条，执行者依 §11 判不过、退回澄清，所有者答「是」后方证。**追问经过已记入该文件**）
- 详细设计+任务：已走完 — `step1/design.md` 与 `step1/task/basic.md`、`step1/task/detail.md`（**六条**结构决策，第六条为落地期回填；**basic 段为空**，三条任务逐条判定依据已写入 basic 文件。**新暴露一处：T-D2 无判据承担**，见 `design.md` 取舍一）
- R3 详细方案评审：approved — `step1/task/review.md`（所有者原话「a，下一份spec补齐」。**裁定一取 (a)**——不回抽象设计补判据，缺口留到下一份 spec；**裁定二（分类核查）所有者未单独作答，执行者不代判，记为中等强度推断**，复核去向为人工验收）
- impl/basic：不适用 — basic 段为空，按 `flow.md` 该节正文不产生调用，**无 `impl/basic.md`，这是正确状态**
- verify/basic：不适用 — `step1/verify/basic.md`（空段三项无断言对象；未派发子代理并写明理由：派人去验"没有东西可验"不产生证据）
- impl/detail：已走完 — `step1/impl/detail.md`（三条任务落地，改 `rules.md` 与 `flow.md` 两份控制面文件，零 Go 改动。**三处偏差如实记明**，其三为验证后的两处订正）
- verify/detail：passed — `step1/verify/detail.md`（**由独立子代理写出**。六条判据全满足，§12 环 2、环 3 差集均为 `0`。**报出五处问题，其中两处是实现者未标出的**——见下）
- 人工验收：accepted — `step1/acceptance.md`「结论」（所有者原话「接受」。**一处推断如实标明**：所有者未就"是否重跑验证"单独表态，投影把两项写成同一问句且 stale 范围同屏，据此读作覆盖。**顺带复核并转正了 R3 的分类推断**——basic 段为空成立）
- 摘要：已走完 — `step1/summary.md`（绑定 accepted；带出未关闭的五项，记三条经验）

## 独立验证报出的问题及其处置

**主会话逐条核实，五处全部属实。**

| # | 问题 | 处置 |
| --- | --- | --- |
| 1 | `SPEC-PJUDGE-003` 改动前后恒为 `14`/`14`，**证不出本 step 做了什么**；且它与 `006` 同为防回归却未带 `[横切]`，处理不一致 | **未改**——改判据要动已批准的 `specify.md`。交人工验收裁定 |
| 2 | T-D2 无判据，子代理改为直读文本并逐字照录 | **非问题**，是 R3 取 (a) 的既定处置。文本已录入验证工件供验收直读 |
| 3 | 第 `133` 行 lint 告警非本次引入（`git diff` 已验），但仓库无 markdownlint 配置，**告警本身无法在仓库内复现** | **未改**——`SPEC-IMPL-001` 禁无关重构 |
| 4 | **实现者未标出**：`design.md`「`product-judge` 现存处数 `0`」不实（HEAD 实为 `49` 处 / `10` 文件，含本实例自己五份工件），且只给数字不给命令，违反 §7 | **已订正**：断言范围缩到控制面并补命令。**第 `36` 次同型实发**（自指判据） |
| 5 | **实现者未标出**：§13 四项被一个空行截成 3+1，与 §1–§12 不同构，**本次引入** | **已修**：删去该空行 |

**第 4、5 两处的修复发生在 `passed` 写出之后**，严格说使验证结论 stale——范围与复跑结果见 `step1/impl/detail.md`「偏差三」。**是否需要重新验证，交人工验收裁定。**

## 本实例期间在流程外核实的一项

**所有者提出"能否用 agent hook 在特定环节触发校验"，已实证。** 该核实**不属本 step 范围**，不改变本实例任何闸门，记此备查：

- **已证**：`PreToolUse` 会触发；`hookSpecificOutput.permissionDecision: "deny"` 拦得住写入且拒绝理由原样透传；退出码 `2` 同样拦得住；`SubagentStop` 的 payload 带 `agent_id` 与 `agent_type`。
- **两份资料都未写、实测发现**：`PreToolUse` 的 payload 含 `tool_input.content`；`SubagentStop` 的 payload 含 `agent_transcript_path` 与 `last_assistant_message`。
- **未证**：`type: "agent"` 钩子（"`product-judge` 可由 harness 自动跑"这一结论的承重点）。
- **处置**：所有者裁定走 (a)——本 spec 按已批准形态收尾，hook 另立需求。探针已全部撤除。

## 当前性

- `Intent.md`、`QA.md`、`intent-review.md`：current
- `step1/scope.md`、`step1/specify.md`、`step1/design-review.md`：current
- `step1/design.md`、`step1/task/basic.md`、`step1/task/detail.md`、`step1/task/review.md`：current
- `step1/verify/basic.md`、`step1/impl/detail.md`：current
- `step1/acceptance.md`、`step1/summary.md`：current
- `step1/verify/detail.md`：**结论 current，行号引用 stale**——`passed` 写出后实现者又改了两处（见「独立验证报出的问题」第 4、5 条）。**六条判据的值不受影响，已复跑一致**；受影响的是 `rules.md` 行数（`210`→`209`）、其 diff hunk（`+185,26`→`+185,25`）、以及 §13 内第 `190` 行之后的行号引用
