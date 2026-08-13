# `.themis/spec/` 控制面实施计划

> **给执行者：** 必需子技能——用 `superpowers:subagent-driven-development`（推荐）或 `superpowers:executing-plans` 逐任务实施本计划。步骤使用 `- [ ]` 复选框语法跟踪。

**目标：** 建立 `.themis/spec/` 定义面（四份文件 + SKILL.md），把落地分段的全部定义从实例骨架外移，并让实体骨架树退场。

**架构：** `.themis/spec/` 运行时只读，承载流程契约、判定规则与实例结构；`.themis/workspace/spec/<spec-id>/` 是运行时唯一可写处。四份文件职责互不渗透：`flow.md` 答"能不能走到下一步"，`rules.md` 答"这一步怎么判"，`template.md` 答"产物长什么样"，`README.md` 只做索引。

**技术栈：** 纯 Markdown 合同。无代码、无测试框架、无脚本。

**设计来源：** `docs/superpowers/specs/2026-08-12-themis-spec-control-plane-design.md`（已确认）。行为契约在已审批的 `docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md`，本计划不改动其 §2 任何条目。

---

## 全局约束

- 所有 Markdown 内容使用中文（`AGENTS.md:53`）。
- 不新增 YAML 文件、YAML 模板或 YAML 语义合同（`AGENTS.md:41-44`）。
- 不新增 Python、Shell 或任何临时脚本（`AGENTS.md:45-46`）。
- 不引入版本概念或版本形式的目录（`AGENTS.md:51`）。
- WIKI 类文件不记录任务状态（`AGENTS.md:50`）。
- 单一路径：不得出现 simple/full 分叉，不得为"是否分段"预留判断分支或开关。
- **`.themis/spec/` 内不得出现任何指向 `.themis/core/` 的路径引用**——core 将被删除，引用即断链。可查阅 core 原设计取经，但产出必须重新写、不得整段复制。
- **定义不得写进实例骨架**；`template.md` 只记录结构，一个字的解释都不写。
- 机器强制一律 unavailable：任何文本不得声称闸门已由机器执行。

## 验证方式说明

本仓库没有测试框架，且禁止新增脚本。每个任务的验证循环是：**改动前观察（确认目标不存在）→ 改动 → 改动后观察（确认命中）**。

**`rg` 默认跳过隐藏目录，而 `templates/.themis/` 以点号开头。** 递归检索该树必须加 `--hidden`，否则空输出会被误读成"确认不存在"。显式文件路径不受影响。这是上一轮踩过的坑。

## 执行前置

当前分支 `themis-spec-control-plane`（worktree `.claude/worktrees/themis-spec-control-plane`），基于 `main` 的 `488ef51`。

---

## 文件结构

| 文件 | 动作 | 职责 |
|---|---|---|
| `templates/.themis/spec/README.md` | 新建 | 包身份、四份文件索引、职责分界、当前强制水平、拆分退出条件 |
| `templates/.themis/spec/flow.md` | 新建 | 流程契约：节点、前置闸门、产出、失效波及、失败去向 |
| `templates/.themis/spec/rules.md` | 新建 | 十个主题的判定规则与禁令 |
| `templates/.themis/spec/template.md` | 新建 | 实例目录树与文件小节，不做定义 |
| `templates/.themis/skills/themis/SKILL.md` | 新建 | 公共入口，唯一副本 |
| `templates/.claude/skills/themis/SKILL.md` | 删除 | 安装产物不随包 |
| `templates/.themis/workspace/spec/template/**` | 删除 | 由 `template.md` 取代 |
| `docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md` | 修改 | 仅同步 §5 P4 落地②的路径与形态描述 |

**不动的文件：** `templates/.themis/core/**`（随 core 一并删除，另行安排）、`templates/.themis/workspace/` 下 `spec/` 以外的一切、`docs/plan/**`。

---

## Task 1：`.themis/spec/README.md`

**文件：** 新建 `templates/.themis/spec/README.md`

**接口：**

- 消费：设计 §3.2 职责分界表、§5.3 拆分退出条件。
- 产出：四份文件的索引与职责分界，Task 2–4 的文件名与职责以此为准。

- [ ] **步骤 1：观察改动前状态**

```bash
ls templates/.themis/spec 2>&1
```

预期：`No such file or directory`。目录尚不存在。

- [ ] **步骤 2：创建文件，内容如下**

```markdown
# Spec 包

## 包身份

- Package identity：`themis-spec`。
- 本包只提供 Prompt-level 流程契约、判定规则与实例结构。
- 本包**运行时只读**：安装进项目后不被任何流程修改。运行时产物一律落在 `.themis/workspace/spec/<spec-id>/`。
- 本包没有功能版本，不声明任何机器身份。
- 本包不引用 `.themis/core/`。

## 合同入口

| 合同 | 入口 | 只回答一个问题 |
|---|---|---|
| 流程契约 | [flow.md](flow.md) | 现在能不能走到下一步 |
| 判定规则 | [rules.md](rules.md) | 这一步怎么判过不过 |
| 实例结构 | [template.md](template.md) | 产物长什么样、放在哪 |

本 README 只做索引与元信息，**不含任何流程或判定内容**。四份文件的职责边界不得互相渗透——判定规则不写进 `flow.md`，流程顺序不写进 `rules.md`，任何定义都不写进 `template.md`。评审时按此受检。

## 加载链

```text
SKILL.md
→ README.md（索引，确认当前强制水平）
→ flow.md（定位当前节点、前置闸门是否满足）
→ rules.md 中该节点对应的小节（这一步怎么判）
→ template.md（要产出或更新哪些文件、哪些小节）
```

## 当前强制水平

本包全部规则**没有机器强制**：仓库尚无 Themis Go CLI 的对应能力，validator、evaluator、recorder、digest 均为 `unavailable`。规则依赖 Agent 遵守与人工评审。

不得声称任何闸门已由机器执行，也不得用文件存在、目录结构或 Markdown 措辞冒充机器强制。

## rules.md 的拆分退出条件

`rules.md` 现为单文件、按主题分节。满足以下任一条时，把对应小节抽为独立文件，原处留一行索引：

- **单节失衡**：某一节超过全文三分之一。
- **独立演进**：连续三次修改都只动同一节。
- **总量阈值**：`rules.md` 全文超过 300 行。

三条都可数，不留解释空间——避免"要不要拆"每次重新变成主观争论。

`flow.md` 不适用本条件：流程契约本质是一张图，闸门的前置是上游节点的产出、失效级联跨节点波及，拆开后读者看不到上下游关系。**它永久保持单文件**，只在内部分节。
```

- [ ] **步骤 3：观察改动后状态**

```bash
rg -c "themis-spec" templates/.themis/spec/README.md
rg -n "运行时只读|没有机器强制|永久保持单文件" templates/.themis/spec/README.md
```

预期：第一条命中 1；第二条三处各命中一次。

- [ ] **步骤 4：提交**

```bash
git add templates/.themis/spec/README.md
git commit -m "feat: 建立 .themis/spec 包索引与职责分界

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 2：`.themis/spec/flow.md`

**文件：** 新建 `templates/.themis/spec/flow.md`

**接口：**

- 消费：`mvp.md` §2 的 SPEC-REVIEW-R1/R2/R3、SPEC-GATE-001、SPEC-INVALIDATION-001、SPEC-IMPL-002、SPEC-FAIL-001；设计 §4.1 节点序列。
- 产出：节点名称与顺序，Task 3 的"适用节点"、Task 4 的产出映射均以此为准。

- [ ] **步骤 1：观察改动前状态**

```bash
ls templates/.themis/spec/flow.md 2>&1
```

预期：`No such file or directory`。

- [ ] **步骤 2：写入节点表**

文件以一段说明开头，写明三件事：本文件只回答"能不能走到下一步"；判定规则一律见 `rules.md`；本文件永久单文件。

随后是节点表，逐行照抄下表（这是本任务的核心交付物，不得增删节点、不得改动顺序）：

| # | 节点 | 前置闸门 | 产出 | 失效波及 | 失败去向 |
|---|---|---|---|---|---|
| 1 | Intake | 无 | 不可变来源记录；`Intent.md` 的来源引用 | 全部下游 | 停在 Intake |
| 2 | 追问 | Intake 完成且 claims 经用户确认 | `QA.md` 追加一轮 | 意图定稿及其后全部 | 停在 Intake |
| 3 | 意图定稿 | Why、期望结果、核心链路三者均明确 | `Intent.md` | R1 及其后全部 | 停在追问 |
| 4 | R1 意图评审 | 意图定稿完成 | `intent-review.md` | 抽象设计及其后全部 | 停在意图定稿 |
| 5 | 抽象设计 | R1 结论为批准 | `step<N>/specify.md` | R2 及其后 | 停在 R1 |
| 6 | R2 抽象设计评审 | 抽象设计成形 | `step<N>/specify-review.md` | 详细设计及其后 | 停在抽象设计 |
| 7 | 详细设计 | R2 结论为批准 | `step<N>/design.md` | 任务分组及其后 | 停在 R2 |
| 8 | 任务分组 | 详细设计成形 | `step<N>/task/basic.md`、`step<N>/task/detail.md` | R3 及其后 | 停在详细设计 |
| 9 | R3 详细方案评审 | 详细设计与两个 task 文件成形，且未解决反馈为空 | `step<N>/review.md` | 落地及其后 | 停在任务分组 |
| 10 | impl/basic | R3 结论为批准 | `step<N>/impl/basic.md` | verify/basic 及其后 | 停在 R3 |
| 11 | verify/basic | impl/basic 完成 | `step<N>/verify/basic.md` | impl/detail 及其后 | 停在 R3 |
| 12 | impl/detail | verify/basic 结论为通过 | `step<N>/impl/detail.md` | verify/detail 及其后 | 停在 verify/basic |
| 13 | verify/detail | impl/detail 完成 | `step<N>/verify/detail.md` | 验收及其后 | 停在 verify/basic |
| 14 | 人工验收 | verify/detail 结论为通过 | `step<N>/acceptance.md` | 摘要 | 停在 verify/detail |
| 15 | 摘要 | 验收结论为 accepted | `summary.md` | 无 | 停在验收 |

- [ ] **步骤 3：写入四条流程级不变量**

在节点表之后，逐条写入（措辞可调整，语义不得削弱）：

1. **人工节点固定四处**：R1、R2、R3、人工验收。第 11 与第 13 两次验证均由独立于实现者的角色判定，**无人工节点**。
2. **两段恒定存在**：basic 与 detail 是恒定的有序两段，允许为空。basic 段为空时不产生落地调用，顺序不变——空段是集合为空，不是路径分支，**不得为"是否分段"设置任何判断分支或开关**。
3. **失效级联作用于工件**：任一节点产出新修订时，其"失效波及"列所列的下游工件全部作废，不得继续当作最新使用。**已落地的 basic 代码不被自动失效**，也不得被自动回滚或删除；该情形由 `rules.md` 的孤儿阻断一节处理。
4. **失败即停**：节点失败时停在其"失败去向"列所指的已证闸门并等待人类或 Agent 决定。不进行失败次数预算，不做失败→经验学习。

- [ ] **步骤 4：观察改动后状态**

```bash
rg -c "^\| 1[0-5] \||^\| [1-9] \|" templates/.themis/spec/flow.md
rg -n "空段是集合为空|无人工节点|失败即停" templates/.themis/spec/flow.md
rg -n "core/" templates/.themis/spec/flow.md
```

预期：第一条命中 15（十五个节点行）；第二条三处各命中；**第三条无输出**（不得引用 core）。

- [ ] **步骤 5：提交**

```bash
git add templates/.themis/spec/flow.md
git commit -m "feat: 建立 spec 流程契约 flow.md

十五个节点的前置闸门、产出、失效波及与失败去向，加四条流程级不变量。

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 3：`.themis/spec/rules.md`

**文件：** 新建 `templates/.themis/spec/rules.md`

**接口：**

- 消费：Task 2 定义的节点名称；`mvp.md` §2 的条文原文。
- 产出：十个主题小节，Task 6 删除实例骨架时以本文件是否已覆盖对应定义为前提。

**本任务的写法：** 每节的**判据与拒绝条件逐字取自 `mvp.md` 的对应条文**，不得改写、不得"优化"措辞——那些条文已经过审批。你要做的是重新组织，不是重新表述。每节固定四项：**适用节点 / 判据 / 拒绝条件 / 判定者**。

- [ ] **步骤 1：观察改动前状态**

```bash
ls templates/.themis/spec/rules.md 2>&1
```

预期：`No such file or directory`。

- [ ] **步骤 2：按下表写入十节**

| # | 小节标题 | 适用节点 | 判据与拒绝条件的来源 | 判定者 |
|---|---|---|---|---|
| 1 | 来源与分层事实源 | Intake、追问、意图定稿、抽象设计、详细设计、落地、验证 | `SPEC-INTAKE-002`、`SPEC-SOURCE-001` 全文含各 AC | 各节点执行者，评审时受检 |
| 2 | 意图收敛判据 | 追问、意图定稿 | `SPEC-QUESTION-001`、`SPEC-QUESTION-002` 含 AC | 意图定稿执行者 |
| 3 | 评审投影的低负担要求 | R1、R2、R3 | `SPEC-REVIEW-LOWBURDEN` 含 AC1 | 投影产出者，Human 在评审时受检 |
| 4 | basic/detail 判定 | 任务分组、R3 | `SPEC-IMPL-003` 含 AC1、AC2、AC3 | R3 评审（`review.md` 的分类核查） |
| 5 | `[basic]` 标识 | 抽象设计、任务分组、验证 | 落地分段设计 §3.3 | 抽象设计执行者，R2 受检 |
| 6 | 结构决策归属 | 详细设计、任务分组 | `SPEC-IMPL-003/AC3` | R3 评审 |
| 7 | 验证 | verify/basic、verify/detail | `SPEC-VERIFY-001` 含 AC1、`SPEC-VERIFY-002`、`SPEC-VERIFY-003` 含 AC1–AC3 | 独立于实现者的验证角色 |
| 8 | 孤儿阻断 | verify/detail、人工验收 | `SPEC-ACCEPT-002` 含 AC1、AC2 | **verify/detail**；验收只引用其结论，不自行判定 |
| 9 | 工件阐述方式 | 全部产出工件的节点 | `SPEC-ARTIFACT-001` | 各节点执行者，评审时受检 |
| 10 | 失败处理 | 全部节点 | `SPEC-FAIL-001` | 各节点执行者 |

- [ ] **步骤 3：为第 7、8 两节补写额外要点**

这两节承载本轮新增的语义，除条文原文外还需写明：

**第 7 节补充：**

- `verify/basic` 只判三项：结构存在、可构建、既有测试（若有）无回归。
- `verify/basic` 不得声称交付任何外部行为——此刻行为尚未实现，任何行为结论都是假的。
- `verify/basic` 的结论必须写入验证角色所有的工件，**不得写入 `impl/` 下任何文件**。
- `verify/detail` 逐条对 `specify.md` 的验收判据断言；标 `[basic]` 的契约存在性条目由 `verify/basic` 以结构性断言覆盖，不重复计入行为断言。

**第 8 节补充：**

- `verify/detail` 必须断言：每个 `task/basic.md` 声明的被依赖关系，其消费者在实际代码中存在。
- 该判定不由人承担。三条已批准约束同时指向 `verify/detail`：闸门要成立必须有判定者；判定者必须独立于实现者（`SPEC-VERIFY-001`）；实现层判据必须以代码为事实源（`SPEC-SOURCE-001`）。
- 要挡住的具体场景是 `SPEC-ACCEPT-002/AC1` 挡不住的那条：**detail 段重规划后消费者被删除**——此时剩余 detail 任务可以全部通过，basic 改动已成孤儿，且并不存在"被打回"这一事实。

- [ ] **步骤 4：观察改动后状态**

```bash
rg -c "^## " templates/.themis/spec/rules.md
rg -n "适用节点" templates/.themis/spec/rules.md
rg -n "core/" templates/.themis/spec/rules.md
```

预期：第一条命中 10（十个主题小节）；第二条命中 10（每节都有"适用节点"项）；**第三条无输出**。

- [ ] **步骤 5：提交**

```bash
git add templates/.themis/spec/rules.md
git commit -m "feat: 建立 spec 判定规则 rules.md

十个主题小节，每节写明适用节点、判据、拒绝条件与判定者。

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 4：`.themis/spec/template.md` 与 `mvp.md` 落地②同步

**文件：**

- 新建 `templates/.themis/spec/template.md`
- 修改 `docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md`（仅 §5 P4 的落地②一行）

**接口：**

- 消费：Task 2 的节点产出映射。
- 产出：实例结构，Task 6 删除实体骨架树以本文件存在为前提。

- [ ] **步骤 1：观察改动前状态**

```bash
ls templates/.themis/spec/template.md 2>&1
rg -n "落地② 工件模板" docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md
```

预期：第一条 `No such file or directory`；第二条命中一行，内容为 `` 落地② 工件模板(`.themis/spec/templates/`,配对 record/content + trace + EARS) ``。

- [ ] **步骤 2：创建 `template.md`，内容如下**

```markdown
# 实例结构

本文件只记录结构，**不做任何定义**。字段含义、判定规则与填写要求一律见 [rules.md](rules.md)，节点顺序见 [flow.md](flow.md)。

## 实例目录树

```text
.themis/workspace/spec/<spec-id>/
  Intent.md
  intent-review.md
  QA.md
  state.md
  summary.md
  step<N>/
    specify.md
    specify-review.md
    design.md
    task/
      basic.md  detail.md
    review.md
    impl/
      basic.md  detail.md
    verify/
      basic.md  detail.md
    acceptance.md
```

`<spec-id>` 为一次 spec 运行的标识。`<N>` 为实现步骤序号：大步骤为整数，小步骤为小数。

## 文件小节

| 文件 | 小节 |
|---|---|
| `Intent.md` | 问题 / 期望结果 / 核心链路 / 范围与非做 / 约束 / 来源引用 |
| `intent-review.md` | 投影 / 未解决反馈 / 结论 |
| `QA.md` | 第 N 轮 → 问 / 答 / 来源 |
| `state.md` | 当前节点 / 各闸门 / 当前性 |
| `summary.md` | 实际交付 / 绑定的验收结论 / 说明 |
| `specify.md` | 行为条目（`### SPEC-<主题>-<序号>` + 验收判据）/ 来源覆盖 |
| `specify-review.md` | 投影 / 未解决反馈 / 结论 |
| `design.md` | 架构与边界 / 结构决策 / 取舍 / 事实依据 |
| `task/basic.md` | 基础任务 → `### T-B<n>` |
| `task/detail.md` | 详细实现任务 → `### T-D<n>` |
| `review.md` | 评审范围 / 分类核查 / 未解决反馈 / 结论 |
| `impl/basic.md`、`impl/detail.md` | 执行身份 / 实际改动 / 与批准范围的偏差 / 命令记录 |
| `verify/basic.md`、`verify/detail.md` | 执行身份 / 断言与实际结果 / 命令证据 / 结论 / 说明 |
| `acceptance.md` | 交付视图 / 阻断核查 / 用户原话 / 结论 |

`QA.md` 追加写入，既有轮次不改写。三个评审工件与三个闸门一一对应：`intent-review.md` 对 R1，`specify-review.md` 对 R2，`review.md` 对 R3。
```

- [ ] **步骤 3：同步 `mvp.md` 的落地②描述**

把这一行：

```markdown
  - 落地② 工件模板(`.themis/spec/templates/`,配对 record/content + trace + EARS)
```

替换为：

```markdown
  - 落地② 实例结构(`.themis/spec/template.md`,单文件记录目录树与文件小节;`SPEC-ARTIFACT-001` 约束工件文件内的阐述方式,不要求物理配对)
```

这是**描述同步**，不改动 §2 的任何行为契约条目。依据是设计 §7.1 与 §7.4，已随设计一并确认。改完后在报告中原样附上新旧两行，供控制者核对。

- [ ] **步骤 4：观察改动后状态**

```bash
rg -n "summary.md|specify-review.md" templates/.themis/spec/template.md
rg -n "落地②" docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md
rg -n "SPEC-IMPL-002|SPEC-ACCEPT-002" docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md
```

预期：第一条两个文件名各命中；第二条命中新描述；第三条命中数与改动前一致（证明 §2 条目未被波及）。

- [ ] **步骤 5：提交**

```bash
git add templates/.themis/spec/template.md docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md
git commit -m "feat: 建立实例结构 template.md 并同步落地②描述

template.md 只记录目录树与文件小节；mvp.md 落地② 的路径与形态
同步为单文件形态，§2 行为契约条目未改动。

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 5：SKILL.md 迁位与重写

**文件：**

- 新建 `templates/.themis/skills/themis/SKILL.md`
- 删除 `templates/.claude/skills/themis/SKILL.md`

**接口：**

- 消费：Task 1 的加载链、Task 2 的节点名称。
- 产出：公共入口。没有它，`.themis/spec/` 里的定义无人加载。

- [ ] **步骤 1：观察改动前状态**

```bash
rg -n "core/" templates/.claude/skills/themis/SKILL.md | head
```

预期：多处命中——现有 SKILL.md 的稳定入口位置全部指向 `.themis/core/`，这正是它必须重写的原因。

- [ ] **步骤 2：创建新 SKILL.md**

frontmatter 只保留宿主发现所需的 `name` 与 `description` 两个字段（`AGENTS.md:43`：外部宿主强制要求的最小元数据不属于产品语义，流程与合同必须写在正文）。

`name` 为 `themis`。`description` 按 `AGENTS.md:30-36` 的规范优先描述：能完成什么任务、适用什么场景、关键产出是什么——边界与"不做什么"写在正文，不占 description 核心位置。

正文写四件事，不写第五件：

1. **本 Skill 的职责**：接收外部消息，加载 `.themis/spec/` 的定义，按 `flow.md` 定位当前节点，按 `rules.md` 判定，按 `template.md` 产出。它**不拥有任何语义判断**——判定属 `rules.md`，顺序属 `flow.md`。
2. **加载链**：逐字照抄 `templates/.themis/spec/README.md` 的"加载链"代码块。
3. **稳定入口位置**：`.themis/spec/README.md`、`.themis/spec/flow.md`、`.themis/spec/rules.md`、`.themis/spec/template.md`。**四条路径全部在 `.themis/spec/` 下，不得出现 `.themis/core/`。**
4. **安全降级**：当前 validator、evaluator、recorder、digest 与 Invocation host 均 unavailable。缺少当前动作所需支持时停在最近已证闸门、指明 unavailable 的保证、保留续接点；不手写机器拥有的状态，不声称任何转移、持久化、失效、恢复或完成已由机器执行。

- [ ] **步骤 3：删除旧入口**

```bash
git rm templates/.claude/skills/themis/SKILL.md
```

`.themis/skills/` 的内容在安装到实际项目时移动到 `.claude/skills/`，因此包内不保留安装产物——同时存在源与产物即是漂移源。

**该移动动作目前没有执行者**：Themis Go CLI 的安装能力尚未实现，标记为 unavailable，在其可用前由人工完成。不得为此新增脚本，也不得声称安装已自动化。

- [ ] **步骤 4：观察改动后状态**

```bash
rg -n "core/" templates/.themis/skills/themis/SKILL.md
ls templates/.claude/skills/themis/SKILL.md 2>&1
rg -n "^name:|^description:" templates/.themis/skills/themis/SKILL.md
```

预期：第一条**无输出**；第二条 `No such file or directory`；第三条恰好两行（frontmatter 只有这两个字段）。

- [ ] **步骤 5：提交**

```bash
git add templates/.themis/skills/themis/SKILL.md templates/.claude/skills/themis/SKILL.md
git commit -m "feat: SKILL.md 迁入 .themis/skills 并重写为指向 spec

四条稳定入口全部指向 .themis/spec/，不再引用 core；
包内不再保留安装产物 .claude/skills/themis/SKILL.md。

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 6：实体骨架树退场

**前置：** Task 2、3、4 已完成——定义已在 `rules.md` 与 `flow.md`，结构已在 `template.md`。**前置未满足就删除，等于把定义直接丢掉。**

**文件：** 删除 `templates/.themis/workspace/spec/template/**`（26 个文件）

**接口：**

- 消费：Task 3 的 `rules.md`（承接原骨架中的全部定义）、Task 4 的 `template.md`（承接结构）。
- 产出：`workspace/spec/` 下不再有实体骨架，只有运行时创建的实例。

- [ ] **步骤 1：观察改动前状态并逐项核对定义已被承接**

```bash
find templates/.themis/workspace/spec/template -type f | sort
```

预期 26 个文件。随后**逐一打开这些文件中带内容的那些**（`README.md`、`step1/step2` 下的 `task/*`、`impl/*`、`verify/*`、`acceptance.md`），确认其中每一条规则性文字都能在 `templates/.themis/spec/rules.md` 或 `flow.md` 中找到对应。

**发现任何一条未被承接，立刻停止本任务并报告**——不要边删边补，那会让"漏了什么"无从核对。

- [ ] **步骤 2：删除整棵骨架树**

```bash
git rm -r templates/.themis/workspace/spec/template
```

- [ ] **步骤 3：观察改动后状态**

```bash
ls templates/.themis/workspace/spec 2>&1
rg -n --hidden "workspace/spec/template" templates/ docs/ | grep -v "^docs/superpowers/" | head
```

预期：第一条为空目录或 `No such file or directory`；第二条无输出（`docs/superpowers/` 下的设计与计划文档会提到该路径，属历史记录，不算悬空引用）。

- [ ] **步骤 4：提交**

```bash
git add -A templates/.themis/workspace/spec
git commit -m "refactor: 实例骨架树退场，由 template.md 取代

定义已迁入 .themis/spec/rules.md 与 flow.md，结构已由
template.md 记录；实体骨架不再随包分发。

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 7：一致性核验

**前置：** Task 1–6 全部完成。

**文件：** 不修改任何文件。本任务只产出观察结论；发现不符时回到对应任务修正，不在本任务内"顺手改"。

- [ ] **步骤 1：核验四份文件齐全且互相引用正确**

```bash
find templates/.themis/spec -type f | sort
rg -n "flow.md|rules.md|template.md" templates/.themis/spec/README.md
```

预期：四个文件；README 对另外三份各有引用。

- [ ] **步骤 2：核验全树无 core 引用**

```bash
rg -n --hidden "themis/core|\.themis/core" templates/.themis/spec templates/.themis/skills
```

预期：**无输出**。任何一处命中都意味着 core 删除后会断链。

- [ ] **步骤 3：核验职责未渗透**

逐份打开四个文件，按 `README.md` 的职责分界核对：`flow.md` 中不得出现判定规则（"必须满足…才算通过"类表述属 `rules.md`）；`rules.md` 中不得出现节点顺序（"下一步是…"属 `flow.md`）；`template.md` 中不得出现任何解释性文字。

发现渗透即报告，不自行搬移。

- [ ] **步骤 4：核验全局约束未被违反**

```bash
git diff --stat main...HEAD
find templates/ -name "*.py" -o -name "*.sh"
git diff --stat main...HEAD -- "*.yaml" "*.yml"
```

预期：改动只落在 `templates/.themis/` 与 `docs/superpowers/`；第二条无输出；第三条无输出。

- [ ] **步骤 5：核验三个闸门与三份评审工件一一对应**

```bash
rg -n "intent-review|specify-review|review.md" templates/.themis/spec/template.md
rg -n "R1|R2|R3" templates/.themis/spec/flow.md
```

预期：`template.md` 三份评审工件齐全；`flow.md` 中 R1、R2、R3 各作为独立节点出现，且各自的产出与 `template.md` 的三份工件对应。

- [ ] **步骤 6：向用户报告**

报告实际观察输出，不得用"应该没问题"替代证据。明确声明：本次交付是 Prompt 层定义面，**机器强制 unavailable**，闸门依赖 Agent 遵守与人工评审。

---

## 自查

**规格覆盖：** 设计 §3 控制面构成 → Task 1–5；§4 flow.md → Task 2；§5 rules.md → Task 3；§6 template.md → Task 4；§7.4 落地②同步 → Task 4 步骤 3；§8 迁移五项 → Task 1–4（第 1 项）、Task 3（第 2 项）、Task 6（第 3 项）、Task 5（第 4 项）；第 5 项 core 删除按设计声明不在范围。

**未覆盖并已声明的缺口：** `summary.md` 是本计划新增的落点——`SPEC-SUMMARY-001` 要求摘要绑定实际交付，而原实例树无处安放（旧 `acceptance.md` 的 `## summary` 小节在设计 §6.2 重定义时被去掉）。摘要属 lifecycle 级、验收属 step 级，故置于 spec 根。此项已在计划呈交时向用户声明。

**占位符扫描：** 无 TBD/TODO。Task 1、4 给出完整最终文本；Task 2、3、5 给出完整结构、逐条来源与必须写明的要点——来源条文原文已存在于 `mvp.md`，执行者做的是转录与重组，不是发明。

**命名一致性：** 节点名（Task 2）、`rules.md` 的"适用节点"（Task 3）、`template.md` 的产出文件（Task 4）三处使用同一套名称：Intake、追问、意图定稿、R1、抽象设计、R2、详细设计、任务分组、R3、impl/basic、verify/basic、impl/detail、verify/detail、人工验收、摘要。文件路径 `intent-review.md`、`specify-review.md`、`review.md`、`task/{basic,detail}.md`、`impl/{basic,detail}.md`、`verify/{basic,detail}.md`、`state.md`、`summary.md` 在 Task 2、4、7 中保持一致。
