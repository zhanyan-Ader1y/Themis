# `.themis/spec/` 控制面实施计划

> **给执行者：** 必需子技能——用 `superpowers:subagent-driven-development`（推荐）或 `superpowers:executing-plans` 逐任务实施本计划。步骤使用 `- [ ]` 复选框语法跟踪。

**目标：** 把 spec 流程的定义面从实例骨架中抽出，建成 `.themis/spec/` 控制面四份文件（README/flow/rules/template），使定义有唯一的家、不再随实例复制而扩散漂移。

**架构：** 控制面四份文件各答一个问题（能不能走下一步 / 这步怎么判 / 产物长什么样 / 去哪找前三个），职责互不渗透；实例骨架树由 `template.md` 的结构记录取代。`.themis/spec/` 运行时只读，`.themis/workspace/spec/<spec-id>/` 是唯一可写处。与 `core/` 零引用。

**技术栈：** 纯 Markdown 合同。无代码、无测试框架、无脚本。核验方式是静态检查与人工 replay。

**Spec：** `docs/superpowers/specs/2026-08-12-themis-spec-control-plane-design.md`（设计）；行为契约在已审批的 `docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md`（本计划不改动其 §2 任何条目）。执行者必须同时阅读这两份。

## 全局约束

- 本计划**不改动** `mvp.md` §2 的任何行为契约条目；唯一例外是任务 7 对 `mvp.md:174` 落地②描述的路径与形态更新，且该更新需人工重新批准。
- 控制面四份文件的职责分界是硬约束：`flow.md` 只答"现在能不能走到下一步"，`rules.md` 只答"这一步怎么判过不过"，`template.md` 只答"产物长什么样、放在哪"，`README.md` 只答"去哪找上面三个"，**不含任何流程或判定内容**。
- `template.md` **只记录结构，不做任何定义**；含义一律归 `rules.md`。
- `rules.md` 每节固定四项：**适用节点 / 判据 / 拒绝条件 / 判定者**。任何判据没有判定者就不是闸门，缺第四项即为不合格。两条推论：**适用节点必须覆盖判据实际涉及的全部节点**（否则单读该节会误判适用范围，破坏"每节自足"）；**判定者必须对每个适用节点都有真实存在、有权做该判定的角色**（含链尾节点——链尾工件没有下游评审者，需显式兜底）。
- `flow.md` 每个节点固定四件事：**前置闸门 / 产出 / 失效波及 / 失败去向**。判定规则一律不写在这里，指向 `rules.md` 对应小节。
- `flow.md` 永久单文件，长到五百行也不拆，只在内部分节。
- `rules.md` 暂不拆分；拆分触发条件写入 README 且必须可判定：单节超过全文三分之一、连续三次修改都只动同一节、全文超过 300 行——满足任一条即抽为独立文件。
- 与 `core/` **零引用**：不得引用 `core/` 的任何路径，也不得整段复制其合同。可查阅取经，产出必须重新写、只覆盖新流程所需的最小合同。
- 人工节点固定四处：R1、R2、R3、验收。两次验证（basic/detail）均无人工节点。
- 不实现机器强制：validator、evaluator、recorder、digest 均为 unavailable，任何文本不得声称闸门已由机器执行。
- 不新增 YAML（无 Go CLI 消费者）、不新增 Python/Shell 脚本、不引入版本概念或版本目录。
- 不设 simple/full 分叉，不为双路径预留开关。
- 不删除 `core/`、不做端到端 replay——均不在本计划范围。
- 所有 Markdown 内容使用中文。
- `templates/` 是安装包源，仓库根 `.claude/` 是本项目工作区，两者不迁移（见 `AGENTS.md` 的安装包与项目工作区边界）。
- 执行前保存 `git status --short`；不得 reset、restore、clean、stash 或覆盖用户既有修改。

---

## 目标文件结构

```text
templates/.themis/spec/
├── README.md      包身份、四份文件索引、当前强制水平、rules.md 拆分退出条件
├── flow.md        流程契约 —— 永久单文件，按节点分 ## 小节
├── rules.md       判定规则与禁令 —— 十个主题 ## 小节，每节自足
└── template.md    实例结构：目录树 + 文件小节，不做定义

templates/.themis/skills/themis/SKILL.md   公共入口（已存在，任务 6 更新加载链）

docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md   任务 7 更新第 174 行
```

**退场：** `templates/.themis/workspace/spec/template/**`（26 个文件）由 `template.md` 取代，在任务 8 删除。

**实例面（本计划不创建，仅由 `template.md` 描述）：**

```text
.themis/workspace/spec/<spec-id>/
  Intent.md  intent-review.md  QA.md  state.md
  step<N>/
    specify.md  design.md  design-review.md
    task/   basic.md  detail.md  review.md
    impl/   basic.md  detail.md
    verify/ basic.md  detail.md
    acceptance.md
```

---

## 核验方式说明

本计划无自动化测试框架。每个任务的"核验"是**静态检查 + 实际读取**，执行者必须真实运行命令并粘贴输出，不得以"文件已写"替代核验。三类检查贯穿全程：

1. **结构存在**：文件路径、章节标题存在且拼写正确（`grep -c`、`ls`）。
2. **定义唯一性**：定义只出现在 `rules.md`/`flow.md`，骨架与 `template.md` 中不得残留（`grep` 反向断言）。
3. **引用可达**：文中引用的每个 `SPEC-*` 条目在 `mvp.md` 中真实存在（`grep` 正向断言）。

---

### 任务 1：建立包骨架与 README

**文件：**
- 新建：`templates/.themis/spec/README.md`

**接口：**
- 产出：`.themis/spec/` 目录与包身份文件。后续任务在此目录内新增三份文件。
- README 只做索引，**不含流程或判定内容**——这条在任务 9 受检。

- [ ] **步骤 1：确认目录尚不存在**

```bash
ls templates/.themis/spec/ 2>/dev/null || echo "尚不存在（预期）"
```

预期：输出"尚不存在（预期）"。若已存在，停止并报告——说明有人已部分落地，需先核对。

- [ ] **步骤 2：写 README.md**

创建 `templates/.themis/spec/README.md`。文件正文如下（不含本行说明）：

> `# .themis/spec/ 控制面`
>
> 本目录是 spec 流程的**定义面**，安装后运行时只读，不被任何流程修改。实例面在 `.themis/workspace/spec/<spec-id>/`，是运行时唯一可写处。
>
> 本包与 `.themis/core/` 零引用：不引用其路径，也不复制其合同。
>
> `## 四份文件`
>
> 用表格列出四行：`flow.md` → 现在能不能走到下一步；`rules.md` → 这一步怎么判过不过；`template.md` → 产物长什么样、放在哪；`README.md` → 去哪找上面三个。表头为"文件 | 只回答一个问题"。
>
> 表格后写明：这条分界是硬约束。**理由是现成的教训：正是因为没有这条分界，判定规则才被写进了实例骨架，随每个实例复制并各自漂移。** 没有明文分界，四份文件会重新互相渗透。因此本文件不含任何流程或判定内容。
>
> `## 加载链`
>
> 用 `text` 代码块写出五级链：`SKILL.md` → `README.md`（索引，确认当前强制水平）→ `flow.md`（定位当前节点、前置闸门是否满足）→ `rules.md` 中该节点对应的小节（这一步怎么判）→ `template.md`（要产出或更新哪些文件、哪些小节）。
>
> `## 当前强制水平`
>
> **soft 执行器**。机器强制 unavailable：validator、evaluator、recorder、digest 均未实现。闸门靠 Agent 遵守，状态记录在实例的 `state.md`。任何文本不得声称闸门已由机器执行。`themis` Go CLI 可用后按 `SPEC-ENFORCE-002` 切换为 hard 执行器，执行同一份 flow 契约，切换不改变流程语义。
>
> `## rules.md 拆分退出条件`
>
> `rules.md` 现为单文件。满足以下任一条即把对应小节抽为独立文件，原处留一行索引：**单节失衡**——某一节超过全文三分之一，它已经不是"一节"了；**独立演进**——连续三次修改都只动同一节，该节有自己的变更节奏；**总量阈值**——全文超过 300 行。三条都可数，不留解释空间，避免"要不要拆"每次重新变成主观争论。

- [ ] **步骤 3：核验结构与分界**

```bash
ls templates/.themis/spec/README.md
grep -c '^## ' templates/.themis/spec/README.md
```

预期：文件存在，`## ` 小节数为 4（四份文件 / 加载链 / 当前强制水平 / 拆分退出条件）。

```bash
grep -nE '前置闸门|判据|拒绝条件|判定者' templates/.themis/spec/README.md || echo "无判定内容（预期）"
```

预期：输出"无判定内容（预期）"——README 不得含判定词汇。

- [ ] **步骤 4：提交**

```bash
git add templates/.themis/spec/README.md
git commit -m "feat: 建立 .themis/spec 控制面包与 README 索引"
```

---

### 任务 2：写 flow.md 的节点序列与前四个节点

**文件：**
- 新建：`templates/.themis/spec/flow.md`

**接口：**
- 消费：任务 1 的 `README.md` 加载链。
- 产出：`flow.md` 的节点序列图与 Intake、追问、R1、抽象设计四个节点。任务 3 在同一文件追加其余节点。
- 每个节点固定四件事，**行首格式必须逐字为** `- **前置闸门**：`、`- **产出**：`、`- **失效波及**：`、`- **失败去向**：`——任务 3 与任务 9 的断言依赖此格式。

- [ ] **步骤 1：写文件头与节点序列**

创建 `templates/.themis/spec/flow.md`，文件头写明：本文件回答一个问题——**现在能不能走到下一步**；判定规则一律不在此处，指向 `rules.md` 的对应小节。

随后写明单文件理由：本文件**永久单文件**。流程契约本质是一张图，闸门的前置是上游节点的产出，失效级联跨节点波及，价值在于能被一次读完。拆成 `nodes/*.md` 后，读某一节点的人看不到"它的失效会波及谁"，而漏读上下游关系正是失效级联最易出错处。**这条与体量无关**：长到五百行也不拆，只在内部分节。

接着写 `## 节点序列`，用 `text` 代码块给出：

```text
Intake（不可变来源 + 来源绑定 claims）
→ 追问（多轮，未答不得判收敛）
→ R1 意图评审 ────────────── 人工
→ 抽象设计（specify）
→ R2 抽象设计评审 ────────── 人工
→ 详细设计 + 任务（分 basic / detail 两组）
→ R3 详细方案评审 ────────── 人工
→ impl/basic
→ verify/basic ───────────── 机器判，无人工节点
→ impl/detail
→ verify/detail ──────────── 机器判，无人工节点
→ 人工验收 ───────────────── 人工
→ 摘要
```

代码块后写一句：人工节点固定四处——R1、R2、R3、验收；两次验证均无人工节点。

再写 `## 通用失败去向`：任一节点失败（工具错误、验证不过、依赖缺失）时 **fail-closed**，停在 last proven gate（最近已证闸门），等待人类或 Agent 决定。系统**不得**进行失败次数预算，也**不得**把失败转为经验学习（`SPEC-FAIL-001`，判定见 `rules.md` §10）。

- [ ] **步骤 2：追加 Intake 与追问节点**

在 `flow.md` 末尾追加两个 `## ` 小节，各含四件事：

`## Intake`
- 前置闸门：收到新用户请求。
- 产出：不可变来源记录；`Intent.md` 的来源引用小节获得初始条目。
- 失效波及：本节点是链首，无上游可失效；其自身变更使全部下游工件 stale。
- 失败去向：无 last proven gate，停在链首等待重新提交请求。

四件事之后补一段：用户确认 source-bound claims 之前，不得进入任何设计或实现节点（`SPEC-INTAKE-001`）。claims 的来源引用格式与分层事实源规则见 `rules.md` §1。

`## 追问`
- 前置闸门：Intake 已产出不可变来源。
- 产出：`QA.md` 追加第 N 轮问答（追加写入，不覆盖）；`Intent.md` 的问题/期望结果/核心链路小节被更新。
- 失效波及：`Intent.md` 变更使 R1 结论及其下游全部 stale。
- 失败去向：停在 Intake 已证闸门。

补一段：多轮进行，每轮问答形成不可变记录。收敛判据见 `rules.md` §2——未回答的问题不得判定为"已收敛"。

- [ ] **步骤 3：追加 R1 与抽象设计节点**

`## R1 意图评审（人工）`
- 前置闸门：意图已判定收敛（`rules.md` §2）。
- 产出：`intent-review.md` 的投影 / 未解决反馈 / 结论三节。
- 失效波及：结论为 approved 才解锁抽象设计；`Intent.md` 任何后续变更使本结论 stale，需重新评审。
- 失败去向：未批准则停在追问节点，继续追问或修订 `Intent.md`。

补一段：投影必须由抽象到具体渐进呈现，只含该抽象层增量（`rules.md` §3）。未批准前抽象设计节点不得开始。

`## 抽象设计（specify）`
- 前置闸门：R1 结论为 approved 且未 stale。
- 产出：`step<N>/specify.md` 的行为条目与来源覆盖两节。
- 失效波及：本文件变更使 R2 结论、design.md、任务、验证、验收全部 stale。
- 失败去向：停在 R1 已证闸门。

补一段：specify 即抽象设计——同一节点的两个叫法，不存在独立于抽象设计之外的第二份 specify 工件。行为条目用 EARS 句式表达使每条可判定通过/失败（`SPEC-EARS-001`）。`[basic]` 标识的含义见 `rules.md` §5。

- [ ] **步骤 4：核验四件事齐全**

```bash
for n in "Intake" "追问" "R1 意图评审（人工）" "抽象设计（specify）"; do
  printf "%-24s " "$n"
  awk -v n="## $n" '$0==n{f=1;next} /^## /{f=0} f' templates/.themis/spec/flow.md \
    | grep -cE '^- \*\*(前置闸门|产出|失效波及|失败去向)\*\*'
done
```

预期：四个节点各输出 `4`。任一少于 4 说明缺项或行首格式不符，补齐后重跑。

- [ ] **步骤 5：核验引用的条目真实存在**

```bash
for id in SPEC-INTAKE-001 SPEC-FAIL-001 SPEC-EARS-001; do
  printf "%-18s " "$id"
  grep -q "$id" docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md && echo "存在" || echo "缺失（须修正）"
done
```

预期：三项均"存在"。

- [ ] **步骤 6：提交**

```bash
git add templates/.themis/spec/flow.md
git commit -m "feat: flow.md 节点序列与前四个节点"
```

---

### 任务 3：补齐 flow.md 其余节点

**文件：**
- 修改：`templates/.themis/spec/flow.md`

**接口：**
- 消费：任务 2 的文件头与四件事行首格式（`- **前置闸门**：` 等）。
- 产出：R2、详细设计+任务、R3、impl/basic、verify/basic、impl/detail、verify/detail、人工验收、摘要九个节点。至此 `flow.md` 十三个节点完整。

- [ ] **步骤 1：追加 R2 与详细设计+任务节点**

`## R2 抽象设计评审（人工）`
- 前置闸门：`specify.md` 成形。
- 产出：`step<N>/design-review.md` 的投影 / 未解决反馈 / 结论三节。
- 失效波及：结论 approved 才解锁详细设计；`specify.md` 变更使本结论 stale。
- 失败去向：未批准则停在抽象设计节点。

补一段：投影须含架构或时序 Overview（`SPEC-REVIEW-R2`），低负担要求见 `rules.md` §3。

`## 详细设计 + 任务`
- 前置闸门：R2 结论为 approved 且未 stale。
- 产出：`step<N>/design.md`；`step<N>/task/basic.md` 与 `task/detail.md`（有序两组）。
- 失效波及：design.md 变更使两份任务、两次实现、两次验证、验收全部 stale；单份任务变更只使其对应实现与验证 stale。
- 失败去向：停在 R2 已证闸门。

补一段：任务必须在 R3 之前完成 basic/detail 分类（`SPEC-IMPL-002`），判定见 `rules.md` §4。结构决策归属见 `rules.md` §6——任务文件只做分解与依赖声明，不得引入 design.md 未定的结构。两段恒定存在，**允许为空**；空段不产生落地调用，也不构成路径分支。

`## R3 详细方案评审（人工）`
- 前置闸门：design.md 与两份任务成形，且 basic/detail 分类已完成。
- 产出：`step<N>/task/review.md` 的评审范围 / 分类核查 / 未解决反馈 / 结论四节。
- 失效波及：结论 approved 才解锁实现；design.md 或任务变更使本结论 stale。
- 失败去向：未批准则停在详细设计+任务节点。

补一段：一次评审同时覆盖 `task/basic.md` 与 `task/detail.md`，不拆成两次人工评审。未解决反馈必须为空才可批准（`SPEC-REVIEW-R3`）。

- [ ] **步骤 2：追加两段实现与两次验证节点**

`## impl/basic`
- 前置闸门：R3 结论为 approved 且未 stale。
- 产出：`step<N>/impl/basic.md` 的执行身份 / 实际改动 / 与批准范围的偏差 / 命令记录四节，以及实际代码改动。
- 失效波及：本节点产出变更使 verify/basic 结论 stale。
- 失败去向：停在 R3 已证闸门。

补一段：实现必须在 R3 批准范围内——不得修改 current-request、plan 或验收要求，不得做无关重构（`SPEC-IMPL-001`）。basic 段为空时本节点不产生调用，直接进入 impl/detail。

`## verify/basic`
- 前置闸门：impl/basic 完成。
- 产出：`step<N>/verify/basic.md` 的执行身份 / 断言与实际结果 / 命令证据 / 结论 / 说明五节。
- 失效波及：结论通过才解锁 impl/detail；impl/basic 变更使本结论 stale。
- 失败去向：结论不通过则停在 R3 已证闸门，由重规划处理。

补一段：**无人工节点**——机器判。只判三项：结构存在、可构建、既有测试（若有）无回归。判定者与断言范围见 `rules.md` §7。结论必须写入验证角色所有的工件，不得写入实现者所有的工件。

`## impl/detail`
- 前置闸门：verify/basic 结论通过；basic 段为空时前置闸门为 R3 approved。
- 产出：`step<N>/impl/detail.md` 的四节，以及实际代码改动。
- 失效波及：本节点产出变更使 verify/detail 结论 stale。
- 失败去向：停在 verify/basic 已证闸门；basic 段为空时停在 R3 已证闸门。

**失败去向必须镜像前置闸门的每个分支。** 本节点的前置闸门带空段分支，失败去向就必须一并给出空段时的停靠点——basic 段为空时 verify/basic 从未产出结论，指向它等于停在一个从未被证明的闸门，与 fail-closed 冲突。写其余节点时同样检查这一点。

补一段：basic 段通过结构性验证前，detail 段不得开始（`SPEC-IMPL-002`）。

`## verify/detail`
- 前置闸门：impl/detail 完成。
- 产出：`step<N>/verify/detail.md` 的五节。
- 失效波及：结论通过才解锁人工验收；impl/detail 变更使本结论 stale。
- 失败去向：结论不通过则停在 verify/basic 已证闸门。

补一段：**无人工节点**——机器判。依据实际实现与证据判定 `passed`/`failed`，不得依据文档、Agent 自述或文件存在判定通过（`SPEC-VERIFY-002`）。验证者身份必须独立于实现者，判定见 `rules.md` §7。

- [ ] **步骤 3：追加验收与摘要节点**

`## 人工验收（人工）`
- 前置闸门：verify/detail 结论为 `passed`，且孤儿阻断核查通过（`rules.md` §8）。
- 产出：`step<N>/acceptance.md` 的交付视图 / 阻断核查 / 用户原话 / 结论四节。
- 失效波及：结论 accepted 才解锁摘要；任一上游变更使本结论 stale。
- 失败去向：未接受则停在 verify/detail 已证闸门。

补一段：存在已落地但无消费者的 basic 改动时不得进入本节点，必须由重规划显式处理（复用或删除）后才解除（`SPEC-ACCEPT-002`）。人工验收在 step 末尾**只有一次**，不因落地分两段而分两次。

`## 摘要`
- 前置闸门：验收结论为 accepted。
- 产出：摘要工件，绑定实际交付。
- 失效波及：本节点是链尾。
- 失败去向：停在验收已证闸门。

补一段：仅当验收 accepted 后 lifecycle 才可标记完成（`SPEC-SUMMARY-001`）。摘要产出中性工件；是否喂给 Themico 由可选 adapter 决定，不得成为流程运行前提（`SPEC-THEMICO-002`）。

- [ ] **步骤 4：核验全部十三个节点四件事齐全**

```bash
echo "小节总数（含节点序列与通用失败去向）：$(grep -c '^## ' templates/.themis/spec/flow.md)"
grep -c '^- \*\*前置闸门\*\*' templates/.themis/spec/flow.md
grep -c '^- \*\*产出\*\*' templates/.themis/spec/flow.md
grep -c '^- \*\*失效波及\*\*' templates/.themis/spec/flow.md
grep -c '^- \*\*失败去向\*\*' templates/.themis/spec/flow.md
```

预期：小节总数 15；后四个计数均为 **13**（十三个节点各一次）。任一不等于 13 即缺项。

- [ ] **步骤 5：核验判定规则未混入**

```bash
grep -nE '^- \*\*(判据|拒绝条件|判定者)\*\*' templates/.themis/spec/flow.md \
  || echo "无判定四项（预期）"
```

预期：输出"无判定四项（预期）"——判定属 `rules.md`，不得出现在 flow.md。

- [ ] **步骤 6：提交**

```bash
git add templates/.themis/spec/flow.md
git commit -m "feat: flow.md 补齐其余九个节点"
```

---

### 任务 4：写 rules.md 前五个主题

**文件：**
- 新建：`templates/.themis/spec/rules.md`

**接口：**
- 消费：`flow.md` 各节点指向的小节编号（§1–§10）。
- 产出：§1 来源与分层事实源、§2 意图收敛判据、§3 评审投影低负担、§4 basic/detail 判定、§5 `[basic]` 标识。任务 5 追加 §6–§10。
- 每节小节标题格式必须逐字为 `## §<n> <主题名>`；四项行首格式必须逐字为 `- **适用节点**：`、`- **判据**：`、`- **拒绝条件**：`、`- **判定者**：`——后续断言依赖此格式。

- [ ] **步骤 1：写文件头与 §1、§2**

创建 `templates/.themis/spec/rules.md`，文件头写明：本文件回答一个问题——**这一步怎么判过不过**；流程走向在 `flow.md`，产物结构在 `template.md`。

随后写明四项要求与其理由：每节固定四项——适用节点 / 判据 / 拒绝条件 / 判定者。第四项是教训换来的：孤儿阻断当初没写判定者，三份文档各指了一个互斥的角色，闸门退化成没人能合法勾上的框。**任何判据没有判定者就不是闸门。** 每节写成自足形态——读一节不需读另一节。拆分退出条件见 `README.md`。

`## §1 来源与分层事实源`
- 适用节点：Intake、追问、抽象设计、详细设计+任务、impl/basic、impl/detail、verify/basic、verify/detail。
- 判据：每个进入 current-request 的 claim 显式记录来源引用并写入工件文件，格式为 `<类型>#<定位>`，例如 `用户确认#<内容>`、`Themico#<记录>`、`代码#<路径>:<符号或行>`。按抽象层级施加事实源要求：意图、顶层设计、抽象设计等**抽象层**可以 Themico 或其他文档为事实；详细设计的实现依据、实现、验证等**具体实现层**必须以**代码**为事实源，文档仅作线索。
- 拒绝条件：claim 无来源引用；引用不合 `<类型>#<定位>` 格式；具体实现层以文档而非代码为事实源；以 `spec` 作为事实源。
- 判定者：Intake 与追问阶段由 Agent 自检并由 R1 评审者复核；抽象设计层由 R2 评审者判定；具体实现层由验证角色判定。

四项后补一句：`spec` 在任何层都只作补充，不得作为事实源。`用户确认的内容`在任何层都是目标语义权威（`SPEC-INTAKE-002`、`SPEC-SOURCE-001`）。

`## §2 意图收敛判据`
- 适用节点：追问 → R1 之间的收敛判定。
- 判据：Why（为什么）、期望结果、核心链路三者均明确，且不存在未回答的问题。
- 拒绝条件：三者任一不明确；存在未回答的问题；以"轮次已够"或"用户没再提问"代替三要素判定。
- 判定者：Agent 提出收敛主张，R1 评审者是唯一有权确认收敛的角色。

补一句：多轮追问的每轮问答形成不可变记录，追加写入 `QA.md`，不覆盖既有轮次（`SPEC-QUESTION-001/002`）。

- [ ] **步骤 2：追加 §3、§4**

`## §3 评审投影的低负担要求`
- 适用节点：R1、R2、R3。
- 判据：投影由抽象到具体渐进呈现，只包含该抽象层的增量，不重复下层细节。R2 投影含架构或时序 Overview。
- 拒绝条件：投影粘贴完整下层内容；同一细节在多层投影中重复出现；投影缺少该层增量而只有背景复述。
- 判定者：该次评审的人类评审者。

补一句：低负担不等于少评审——三个评审节点各自存在，每次呈现降低理解成本，越早拦截越省返工（`SPEC-REVIEW-LOWBURDEN`）。

`## §4 basic/detail 判定`
- 适用节点：详细设计+任务（分类必须在 R3 之前完成）。
- 判据：basic 任务必须**同时**满足两条——"被本 step 其他任务依赖"与"单独不产生外部可观测行为"。两条同时满足才是 basic，判定依据必须写入 basic 任务工件。不满足则属 detail。
- 拒绝条件：只满足一条即归入 basic；判定依据未写入工件；basic 任务无任何 detail 任务依赖它（孤儿，见 §8）。
- 判定者：任务作者提出分类，R3 评审者在 `task/review.md` 的分类核查中判定。

补一句：两段恒定存在，**允许为空**。空段不产生落地调用，也不改变流程走向，不构成路径分支（`SPEC-IMPL-002/003`）。

- [ ] **步骤 3：追加 §5**

`## §5 [basic] 标识`
- 适用节点：抽象设计（specify.md 撰写）。
- 判据：**对外契约性基础**（字段进入 API 响应或对外数据契约）可观测但不构成行为，属契约存在性条目，出现在 `specify.md` 中并标 `[basic]`，验收方式是结构性断言。**纯内部基础**（数据库列、内部类型、私有签名）不进 specify，只出现在 `design.md` 与 `task/basic.md`。
- 拒绝条件：把纯内部基础写进 specify；`[basic]` 标识用于描述行为而非契约存在性；标了 `[basic]` 却用行为断言验收。
- 判定者：specify 作者标注，R2 评审者判定标注是否成立。

补一句：`[basic]` 的含义是"该条目为契约存在性、由基础落地承担"，**不是**"这是一条基础行为"。specify 只写外部可观测行为，而 basic 按定义不产生行为——这条规则处理两者的交集，使 specify 定位不被破坏。

- [ ] **步骤 4：核验五节四项齐全**

```bash
grep -c '^## §' templates/.themis/spec/rules.md
grep -c '^- \*\*适用节点\*\*' templates/.themis/spec/rules.md
grep -c '^- \*\*判据\*\*' templates/.themis/spec/rules.md
grep -c '^- \*\*拒绝条件\*\*' templates/.themis/spec/rules.md
grep -c '^- \*\*判定者\*\*' templates/.themis/spec/rules.md
```

预期：五个计数均为 **5**。任一不等于 5 即缺项——**没有判定者就不是闸门**，必须补齐。

- [ ] **步骤 5：提交**

```bash
git add templates/.themis/spec/rules.md
git commit -m "feat: rules.md 前五个主题小节"
```

---

### 任务 5：补齐 rules.md 后五个主题

**文件：**
- 修改：`templates/.themis/spec/rules.md`

**接口：**
- 消费：任务 4 的小节标题与四项行首格式。
- 产出：§6 结构决策归属、§7 验证、§8 孤儿阻断、§9 工件阐述方式、§10 失败处置。至此 `rules.md` 十节完整。

- [ ] **步骤 1：追加 §6、§7**

`## §6 结构决策归属`
- 适用节点：详细设计+任务、impl/basic。
- 判据：结构决策（字段、类型、签名、迁移方向、配置项）一律以 `design.md` 为准。任务文件只做分解与依赖声明，实现只落地已定结构。
- 拒绝条件：`task/basic.md` 或实现引入 `design.md` 未定的字段、类型、签名、迁移方向或配置项；实现期临时决定结构而不回填 design.md。
- 判定者：R3 评审者在分类核查中判定任务是否越界；verify/basic 的验证角色判定实现是否引入未定结构。

补一句：发现越界时停在 R3 已证闸门，由重规划处理——不得在实现期就地补决策（`SPEC-IMPL-003/AC3`）。

`## §7 验证：身份独立、basic 三项、detail 断言范围`
- 适用节点：verify/basic、verify/detail。
- 判据：验证角色必须独立于实现者——两份工件的**执行身份**小节一比即得。basic 段只判三项：结构存在、可构建、既有测试（若有）无回归；"结构存在"必须由实际读取实现或运行命令得出。detail 段依据实际实现与证据判定 `passed`/`failed`。
- 拒绝条件：impl 与 verify 的执行身份相同；basic 验证声称交付了外部行为（此刻行为尚未实现，任何行为结论都是假的）；以文档、Agent 自述或文件存在判定通过；basic 结论写入实现者所有的工件。
- 判定者：验证角色本人给出结论并对结论负责；人工验收节点复核身份独立性是否成立。

补一句：两次验证均**无人工节点**（`SPEC-VERIFY-001/002/003`）。

- [ ] **步骤 2：追加 §8、§9**

`## §8 孤儿阻断`
- 适用节点：人工验收（前置核查）。
- 判据：不存在"已落地但无消费者"的 basic 改动。每个 basic 任务都能指出被哪些 detail 任务依赖。
- 拒绝条件：存在无消费者的 basic 改动而进入人工验收；以"将来会用到"作为消费者；以删除记录代替显式重规划处理。
- 判定者：**验收节点的人类验收者**在 `acceptance.md` 的阻断核查中判定。

补一句：存在孤儿时不得进入人工验收，必须由重规划显式处理（复用或删除）后才解除。失效级联作用于工件；已落地的 basic 代码不被自动失效，改由本条阻断处理（`SPEC-ACCEPT-002`、`SPEC-INVALIDATION-001`）。

`## §9 工件阐述方式`
- 适用节点：全部产出工件的节点。
- 判据：每个工件文件必须**同时**承载可核验的控制事实（绑定了什么上游、执行身份、结论、证据）与人类语义（说明、理由），缺一不可。
- 拒绝条件：工件只有结论没有证据；只有叙述没有可核验事实；控制事实与人类语义混在同一小节而无法分辨哪部分可核验。
- 判定者：该工件所属节点的下一个评审或验证角色；链尾工件（摘要）由验收节点的人类验收者一并核查。

补一句：本条约束的是**工件文件内的阐述方式**，**不要求**把工件拆成两个物理文件。`template.md` 的小节划分即按此配比：控制事实与人类语义各有落点（`SPEC-ARTIFACT-001`）。

- [ ] **步骤 3：追加 §10**

`## §10 失败：fail-closed，不预算不学习`
- 适用节点：全部节点。
- 判据：节点失败（工具错误、验证不过、依赖缺失）时停在 last proven gate，等待人类或 Agent 决定。各节点的具体停靠点见 `flow.md` 每个节点的"失败去向"。
- 拒绝条件：进行失败次数预算；把失败转为经验学习；自动重试后声称通过；跳过失败节点继续下游；以"稍后修复"推进闸门。
- 判定者：遇到失败的执行角色必须立即停止并声明；下一个人类节点复核是否真的停在了已证闸门。

补一句：失败预算与失败→经验学习属 Themico 的治理范畴，**不在 spec 流程内实现**（`SPEC-FAIL-001`）。

- [ ] **步骤 4：核验十节四项齐全且记录规模**

```bash
grep -c '^## §' templates/.themis/spec/rules.md
grep -c '^- \*\*适用节点\*\*' templates/.themis/spec/rules.md
grep -c '^- \*\*判据\*\*' templates/.themis/spec/rules.md
grep -c '^- \*\*拒绝条件\*\*' templates/.themis/spec/rules.md
grep -c '^- \*\*判定者\*\*' templates/.themis/spec/rules.md
wc -l < templates/.themis/spec/rules.md
```

预期：五个计数均为 **10**；行数记录进报告——若已超过 300 行，按 README 的总量阈值条件在报告中标注需要拆分（本任务不执行拆分，只记录）。

- [ ] **步骤 5：核验 flow.md 指向的小节都存在**

```bash
grep -oE '`rules\.md` §[0-9]+' templates/.themis/spec/flow.md | grep -oE '[0-9]+' | sort -u -n | while read -r n; do
  printf "flow 指向 §%-4s " "$n"
  grep -q "^## §$n " templates/.themis/spec/rules.md && echo "存在" || echo "缺失（须修正）"
done
```

预期：每一条都"存在"，且输出行数不为零。这是控制面内部引用完整性的核心检查。

**注意模式中的反引号不可省略**：正文里写的是 `` `rules.md` §1 ``，`rules.md` 与 `§` 之间隔着反引号。漏掉反引号会让 `grep` 匹配不到任何内容，检查静默通过却什么都没查——**输出为空即是失败，不是通过**。

- [ ] **步骤 6：提交**

```bash
git add templates/.themis/spec/rules.md
git commit -m "feat: rules.md 补齐后五个主题小节"
```

---

### 任务 6：写 template.md 并更新 SKILL 加载链

**文件：**
- 新建：`templates/.themis/spec/template.md`
- 修改：`templates/.themis/skills/themis/SKILL.md`

**接口：**
- 消费：`rules.md` 的十个小节编号、`flow.md` 的节点名。
- 产出：`template.md`（实例目录树 + 文件小节表，**不做任何定义**）；`SKILL.md` 的加载链指向 `.themis/spec/` 四份文件。
- 至此控制面四份文件齐备，加载链可用——这是任务 8 删除骨架的前提。

- [ ] **步骤 1：写 template.md**

创建 `templates/.themis/spec/template.md`，文件头写明：本文件回答一个问题——**产物长什么样、放在哪**；只记录结构，**不做任何定义**，含义一律见 `rules.md`，流程走向见 `flow.md`。实例面 `.themis/workspace/spec/<spec-id>/` 是运行时唯一可写处。

`## 实例目录树`，用 `text` 代码块给出：

```text
.themis/workspace/spec/<spec-id>/
  Intent.md
  intent-review.md
  QA.md
  state.md
  step<N>/
    specify.md
    design.md
    design-review.md
    task/
      basic.md  detail.md  review.md
    impl/
      basic.md  detail.md
    verify/
      basic.md  detail.md
    acceptance.md
```

代码块后补两段：`Intent.md`、`intent-review.md`、`QA.md`、`state.md` 每个 spec 一份放在根——R1 只发生一次，故 `intent-review.md` 不在 step 下；其余按 step 分目录。step 编号规则：大步骤为整数，小步骤为小数；用户描述多个无关联需求时拆为不同大步骤，大步骤内自顶向下、由抽象到具体拆为小步骤。

`## 文件小节`，用表格给出（表头"文件 | 小节"）：

| 文件 | 小节 |
| --- | --- |
| `Intent.md` | 问题 / 期望结果 / 核心链路 / 范围与非做 / 约束 / 来源引用 |
| `QA.md` | 第 N 轮 → 问 / 答 / 来源（追加写入） |
| `intent-review.md` | 投影 / 未解决反馈 / 结论 |
| `state.md` | 当前节点 / 各闸门 / 当前性 |
| `specify.md` | 行为条目（`### SPEC-<主题>-<序号>` + 验收判据）/ 来源覆盖 |
| `design.md` | 架构与边界 / 结构决策 / 取舍 / 事实依据 |
| `design-review.md` | 投影 / 未解决反馈 / 结论 |
| `task/basic.md` | 基础任务 → `### T-B<n>` |
| `task/detail.md` | 详细实现任务 → `### T-D<n>` |
| `task/review.md` | 评审范围 / 分类核查 / 未解决反馈 / 结论 |
| `impl/basic.md`、`impl/detail.md` | 执行身份 / 实际改动 / 与批准范围的偏差 / 命令记录 |
| `verify/basic.md`、`verify/detail.md` | 执行身份 / 断言与实际结果 / 命令证据 / 结论 / 说明 |
| `acceptance.md` | 交付视图 / 阻断核查 / 用户原话 / 结论 |

表格后补两段：`impl` 与 `verify` 的**执行身份**小节是身份独立判定的落点，两处一比即得（判定见 `rules.md` §7）；`verify` 的**说明**小节是人类语义的落点，其余四节均为控制事实（配比要求见 `rules.md` §9）。`task/basic.md` 的每个 `### T-B<n>` 记四项——结构改动、判定依据、被哪些 detail 任务依赖、design.md 中的出处（判定见 `rules.md` §4、§6）。

- [ ] **步骤 2：核验 template.md 不含定义**

```bash
grep -nE '^- \*\*(判据|拒绝条件|判定者|前置闸门|失效波及|失败去向)\*\*' \
  templates/.themis/spec/template.md || echo "无定义内容（预期）"
grep -c '`rules\.md` §' templates/.themis/spec/template.md
```

预期：第一条输出"无定义内容（预期）"；第二条 ≥ 3——含义必须指向 `rules.md` 而非就地展开。模式中的反引号不可省略，正文写的是 `` `rules.md` §7 ``。

- [ ] **步骤 3：更新 SKILL.md 加载链**

先读现有结构：

```bash
grep -nE '^#{1,3} ' templates/.themis/skills/themis/SKILL.md | head -20
```

在 `SKILL.md` 中加入 `## spec 流程加载链` 小节，用 `text` 代码块写出五级链（`SKILL.md` → `.themis/spec/README.md` → `flow.md` → `rules.md` 对应小节 → `template.md`），并补两段：四份文件职责互不渗透——`flow.md` 只答能不能走下一步，`rules.md` 只答怎么判，`template.md` 只答产物长什么样，`README.md` 只答去哪找前三个；当前为 soft 执行器，机器强制 unavailable，闸门靠 Agent 遵守，状态记在实例的 `state.md`，不得声称闸门已由机器执行。

不改动 `SKILL.md` 的其他既有内容。

- [ ] **步骤 4：核验加载链四份文件都真实存在**

```bash
for f in README flow rules template; do
  printf "%-12s " "$f.md"
  ls "templates/.themis/spec/$f.md" >/dev/null 2>&1 && echo "存在" || echo "缺失（须修正）"
done
grep -c '\.themis/spec/' templates/.themis/skills/themis/SKILL.md
```

预期：四份均"存在"；SKILL.md 中引用 `.themis/spec/` 计数 ≥ 4。

- [ ] **步骤 5：提交**

```bash
git add templates/.themis/spec/template.md templates/.themis/skills/themis/SKILL.md
git commit -m "feat: template.md 实例结构与 SKILL 加载链"
```

---

### 任务 7：更新 mvp.md 落地②描述并请求重新批准

**文件：**
- 修改：`docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md` 第 174 行

**接口：**
- 消费：任务 6 完成的 `template.md` 实际形态与路径。
- 产出：`mvp.md` 落地②描述与实际落地一致。**本任务以人工重新批准结束**，任务 8 在批准前不得开始。

- [ ] **步骤 1：确认当前描述与偏离**

```bash
sed -n '174p' docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md
```

预期输出为落地②那一行，内容含 `.themis/spec/templates/` 与"配对 record/content + trace + EARS"。

两处偏离：**形态**上不建 `templates/` 目录、不产出配对 record/content 文件，改为单份 `template.md` 只记录结构；**路径**为 `.themis/spec/template.md`。依据是 `SPEC-ARTIFACT-001` 约束的是文件内的阐述方式，不要求物理配对（设计 §7.1、§7.4）。

- [ ] **步骤 2：更新该行**

把第 174 行的括注部分替换为：`.themis/spec/template.md`，单文件记录实例结构；并说明 `SPEC-ARTIFACT-001` 约束的是工件文件内的阐述方式——控制事实与人类语义各有落点，不要求拆成配对 record/content 物理文件。

保持该行的列表缩进与"落地②"前缀不变。

- [ ] **步骤 3：核验只改了这一行**

```bash
git diff --stat docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md
git diff docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md
```

预期：1 file changed, 1 insertion(+), 1 deletion(-)。**§2 的任何行为契约条目都不得出现在 diff 中**——若出现，回退并重做。

- [ ] **步骤 4：提交**

```bash
git add docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md
git commit -m "docs: mvp 落地②改为 template.md 单文件形态"
```

- [ ] **步骤 5：请求人工重新批准**

**这是人类闸门，不是 Agent 任务。** 任务 8 及之后的全部任务在本任务关闭前不得开始。

向项目所有者呈现：改动的确切行、两处偏离及其依据（`SPEC-ARTIFACT-001` 的读法）、以及 §2 行为契约未被改动的证据（步骤 3 的 diff）。等待明确批准，并把批准日期与结论记入 `mvp.md` 文件头的状态行。

批准前不得进入任务 8——这正是本流程要建立的 gate 语义，执行者若跳过即自我否定。

---

### 任务 8：外移骨架定义并删除实体骨架树

**文件：**
- 删除：`templates/.themis/workspace/spec/template/**`（26 个文件）
- 核对：`templates/.themis/spec/rules.md`、`flow.md`

**接口：**
- 消费：任务 1–6 的控制面四份文件；任务 7 的人工批准。
- 产出：定义只存在于 `.themis/spec/`，实例骨架树退场。

**前置：任务 7 的人工批准已完成。未批准不得开始。**

- [ ] **步骤 1：清点骨架中的定义内容**

```bash
find templates/.themis/workspace/spec/template -name '*.md' | sort
grep -rn '^> ' templates/.themis/workspace/spec/template/ | wc -l
```

记录文件数（预期 26）与引用块行数。这些 `> ` 引用块是待外移的定义。

- [ ] **步骤 2：逐条核对定义已被控制面覆盖**

```bash
grep -rh '^> ' templates/.themis/workspace/spec/template/ | sort -u
```

把输出逐条比对下表，确认每条都有控制面落点：

| 骨架中的定义 | 控制面落点 |
| --- | --- |
| basic 判定两条件、判定依据写入工件 | `rules.md` §4 |
| 结构决策以 design.md 为准、不得引入未定结构 | `rules.md` §6 |
| 空段合法、不产生落地调用、不改变走向 | `rules.md` §4 末段、`flow.md` 详细设计+任务节点 |
| verify 由独立角色所有、只判三项 | `rules.md` §7 |
| 不得声称交付外部行为 | `rules.md` §7 拒绝条件 |
| 不得以文档/自述/文件存在判定通过 | `rules.md` §7 拒绝条件 |
| 一次评审覆盖两份任务、不拆两次 | `flow.md` R3 节点 |
| 孤儿阻断、验收只一次 | `rules.md` §8、`flow.md` 人工验收节点 |
| `[basic]` 标识含义 | `rules.md` §5 |
| 执行顺序（basic 先于 detail） | `flow.md` impl/detail 节点前置闸门 |

**任一条未覆盖时停止**，回到任务 4/5 补入对应小节后再继续——这是本任务的核心风险：定义在外移中丢失比留在骨架里更糟。

骨架 README 中属于个人笔记与教学内容的部分（spec 核心思想、关键判断、Intent 与 Specify 的区分示例等）不是控制面定义，随骨架一并退场，不迁入 `rules.md`。

- [ ] **步骤 3：核对 template.md 已记录全部实例结构**

```bash
find templates/.themis/workspace/spec/template -name '*.md' -printf '%P\n' | sort
grep -oE '`[A-Za-z<>/.-]+\.md`' templates/.themis/spec/template.md | sort -u
```

确认骨架中每个文件在 `template.md` 的目录树或文件小节表中都有对应记录（骨架的 `step1`/`step2` 是实例编号示例，对应 `template.md` 的 `step<N>`）。

- [ ] **步骤 4：删除骨架树**

```bash
git rm -r templates/.themis/workspace/spec/template
```

- [ ] **步骤 5：核验骨架已退场且无残留引用**

```bash
ls templates/.themis/workspace/spec/ 2>/dev/null || echo "spec 目录已空（预期）"
git grep -n 'workspace/spec/template' -- ':!docs/superpowers/plans' ':!docs/superpowers/specs' \
  || echo "无残留引用（预期）"
```

预期：骨架目录已删除；除计划与设计文档外无残留路径引用。

- [ ] **步骤 6：提交**

```bash
git add -A templates/.themis/workspace/spec
git commit -m "refactor: 实例骨架树退场，定义归入 .themis/spec 控制面"
```

---

### 任务 9：职责分界终检与产品说明对齐

**文件：**
- 修改：`templates/.themis/README.md`
- 核对：控制面四份文件

**接口：**
- 消费：任务 1–8 的全部产出。
- 产出：四份文件职责分界受检通过；安装包 README 索引到 `spec/`。

- [ ] **步骤 1：终检职责分界**

```bash
echo "--- README 不含判定或流程内容 ---"
grep -nE '^- \*\*(判据|拒绝条件|判定者|前置闸门|产出|失效波及|失败去向)\*\*' \
  templates/.themis/spec/README.md || echo "通过"

echo "--- flow.md 不含判定四项 ---"
grep -nE '^- \*\*(判据|拒绝条件|判定者)\*\*' templates/.themis/spec/flow.md || echo "通过"

echo "--- rules.md 不含节点四件事 ---"
grep -nE '^- \*\*(前置闸门|失效波及|失败去向)\*\*' templates/.themis/spec/rules.md || echo "通过"

echo "--- template.md 不含判定或流程内容 ---"
grep -nE '^- \*\*(判据|拒绝条件|判定者|前置闸门|失效波及|失败去向)\*\*' \
  templates/.themis/spec/template.md || echo "通过"
```

预期：四项均输出"通过"。任一失败即修正后重跑。

- [ ] **步骤 2：终检与 core 零引用**

```bash
git grep -n 'core/' -- templates/.themis/spec/ || echo "无 core 引用（预期）"
```

预期：输出"无 core 引用（预期）"。

- [ ] **步骤 3：终检引用的 SPEC 条目都真实存在**

```bash
git grep -ohE 'SPEC-[A-Z]+-[0-9A-Z]+' templates/.themis/spec/ | sort -u | while read -r id; do
  printf "%-24s " "$id"
  grep -q "$id" docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md && echo "存在" || echo "缺失（须修正）"
done
```

预期：全部"存在"。任一缺失说明引用了不存在的条目，必须修正。

- [ ] **步骤 4：更新安装包 README 索引**

在 `templates/.themis/README.md` 的目录或索引处加入一行，说明 `spec/` 是 spec 流程的定义面、运行时只读、与 `core/` 零引用，并指向 `spec/README.md`。

不改动该文件的其他内容——`core/` 的现有描述保持原样（`core/` 删除不在本计划范围）。

- [ ] **步骤 5：核验改动范围**

```bash
git diff --stat
git status --short
```

确认只改了 `templates/.themis/README.md`，无编译产物、无 Python、无 YAML、无版本目录进入。

- [ ] **步骤 6：提交**

```bash
git add templates/.themis/README.md
git commit -m "docs: 安装包 README 索引 spec 控制面"
```

---

## 完成判定

以下全部成立才可报告本计划完成：

1. `templates/.themis/spec/` 下四份文件齐备。
2. `flow.md` 十三个节点各写齐前置闸门 / 产出 / 失效波及 / 失败去向四件事。
3. `rules.md` 十个小节各写齐适用节点 / 判据 / 拒绝条件 / 判定者四项——**没有判定者就不是闸门**。
4. `template.md` 只记录结构，不含任何定义。
5. `README.md` 只做索引，不含流程或判定内容。
6. 四份文件职责分界的四条断言全部通过（任务 9 步骤 1）。
7. 与 `core/` 零引用。
8. 引用的每个 `SPEC-*` 条目在 `mvp.md` 中真实存在。
9. 实例骨架树已删除，且其全部定义在控制面中有对应落点（任务 8 步骤 2 的逐条核对）。
10. `mvp.md` 第 174 行已更新且获得人工重新批准；§2 行为契约条目未被改动。
11. `SKILL.md` 加载链指向 `.themis/spec/` 四份文件。

该判定不表示 spec 流程已可端到端运行——落地⑤（端到端 replay）与 `core/` 删除均不在本计划范围，需各自单独展开。也不等于用户接受，更不授权 push。

---

## 计划自检清单

- **Spec coverage**：设计 §3（控制面构成）→ 任务 1、6；§4（flow.md）→ 任务 2、3；§5（rules.md）→ 任务 4、5；§6（template.md）→ 任务 6；§7.4（mvp 偏离）→ 任务 7；§8（迁移）→ 任务 8、9。§9 非目标全部写入全局约束。
- **职责分界**：四份文件各答一个问题，任务 9 以四条可运行断言终检，不靠人工判断。
- **定义唯一性**：任务 8 步骤 2 逐条核对骨架定义的控制面落点，未覆盖即停止——外移中丢失定义比留在骨架里更糟。
- **闸门完整性**：`rules.md` 每节必有判定者，任务 4/5 用 `grep -c` 断言计数相等。
- **引用完整性**：任务 5 步骤 5 检查 flow → rules 的内部引用，任务 9 步骤 3 检查 → `mvp.md` 的外部引用。
- **格式一致性**：四件事与四项的行首格式在任务 2、任务 4 的接口块中逐字规定，后续断言依赖该格式。
- **人工闸门**：任务 7 是人类批准闸门，任务 8 明文写"未批准不得开始"。
- **Scope control**：不删 `core/`、不做端到端 replay、不实现机器强制、不新增 YAML/Python/Shell、不引入版本概念——均在全局约束中列明。
