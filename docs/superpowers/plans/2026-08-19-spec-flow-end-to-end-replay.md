# spec 流程端到端 replay 实施计划（落地⑤）

> **给执行者：** 必需子技能——用 `superpowers:subagent-driven-development`（推荐）或 `superpowers:executing-plans` 逐任务实施本计划。步骤使用 `- [ ]` 复选框语法跟踪。

**目标：** 用一个真实需求（删除 `templates/.themis/core/`）作为 spec 实例，按 `.themis/spec/flow.md` 的十三个节点走完全程，产出真实工件，暴露 Agent 在哪些闸门漂移。

**架构：** replay 的**产品是漂移清单**，`core/` 删除只是载体——选它是因为它真实待做、边界明确，且正好是 replay 要解锁的下一步。每个节点执行后立即记录该节点是否发生漂移、漂移形态、以及控制面有没有拦住它。人工节点四处（R1/R2/R3/验收）由项目所有者参与，Agent 不得代答。

**技术栈：** 纯 Markdown 工件。无代码、无测试框架、无脚本。核验方式是对照 `.themis/spec/` 四份文件的静态检查与人工判定。

**Spec：** `.themis/spec/flow.md`（流程契约）、`.themis/spec/rules.md`（判定规则）、`.themis/spec/template.md`（实例结构）、`.themis/spec/README.md`（加载链与强制水平）。已批准行为契约在 `docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md`（落地⑤定义见其 §5 P4）。执行者必须先读这四份控制面文件。

## 全局约束

- **replay 的目的是暴露漂移，不是把流程走漂亮。** 遇到闸门判不动、规则说不清、工件不知道写哪，**如实记录并停下**，不要绕过去——绕过去就丢掉了这次 replay 唯一的产出。
- 控制面 `.themis/spec/` 是**只读**的。replay 期间不得修改它的任何一份文件；发现的缺口写进漂移清单，修复是 replay 之后的独立决定。
- 实例面 `.themis/workspace/spec/<spec-id>/` 是唯一可写处。目录结构与文件小节严格按 `.themis/spec/template.md`，不自创文件、不自创小节。
- **人工节点不得由 Agent 代答**。R1、R2、R3、验收四处必须停下等项目所有者答复。把"我认为所有者会批准"当作批准，即是本次 replay 最该抓的漂移，不是效率。
- 每个节点完成后必须更新 `state.md` 的当前节点、该节点闸门结论、当前性三项（`flow.md` 通用状态条款）。
- 失败一律 **fail-closed**：停在 last proven gate，等待决定。不得进行失败次数预算，不得把失败转为经验学习。
- 引用控制面小节时**只指向不复述**（见 `templates/.themis/AGENTS.md`）：写"判据见 `rules.md` §4"，不把 §4 的判据抄进工件。
- `.themis/spec/`、`.themis/core/`、`.themis/skills/` 等安装副本已在 `.gitignore` 中，不入库。实例工件 `.themis/workspace/spec/<spec-id>/` **入库**，作为 replay 证据。
- 删除 `core/` 的实际动作在 impl 节点执行，但**只在 R3 获得批准后**。批准前不得删除任何文件。
- 所有 Markdown 内容使用中文。不得新增 YAML、Python、Shell 脚本、版本概念或版本目录。
- 执行前保存 `git status --short`；不得 reset、restore、clean、stash 或覆盖用户既有修改。

---

## 目标文件结构

```text
.themis/workspace/spec/core-removal/        实例面（入库，replay 证据）
├── Intent.md            问题 / 期望结果 / 核心链路 / 范围与非做 / 约束 / 来源引用
├── intent-review.md     投影 / 未解决反馈 / 结论
├── QA.md                第 N 轮 → 问 / 答 / 来源（追加写入）
├── state.md             当前节点 / 各闸门 / 当前性
└── step1/
    ├── specify.md       行为条目（### SPEC-<主题>-<序号> + 验收判据）/ 来源覆盖
    ├── design.md        架构与边界 / 结构决策 / 取舍 / 事实依据
    ├── design-review.md 投影 / 未解决反馈 / 结论
    ├── task/
    │   ├── basic.md     基础任务 → ### T-B<n>
    │   ├── detail.md    详细实现任务 → ### T-D<n>
    │   └── review.md    评审范围 / 分类核查 / 未解决反馈 / 结论
    ├── impl/
    │   ├── basic.md     执行身份 / 实际改动 / 与批准范围的偏差 / 命令记录
    │   └── detail.md    同上
    ├── verify/
    │   ├── basic.md     执行身份 / 断言与实际结果 / 命令证据 / 结论 / 说明
    │   └── detail.md    同上
    ├── acceptance.md    交付视图 / 阻断核查 / 用户原话 / 结论
    └── summary.md       交付摘要 / 绑定的验收结论 / 中性工件说明

docs/plan/spec-replay/drift-log.md          漂移清单（本 replay 的真正产品）
```

**spec-id 固定为 `core-removal`。**

**被删除的载体**（在 impl 节点执行，R3 批准后）：`templates/.themis/core/`（98 个文件）。

**六处活跃引用**（已逐一核实，写计划时清点为"三处"是错的——`catalog.md` 用相对路径写引用，逃过了 `.themis/core` 的 grep；`.gitignore` 的忽略规则也会一并失效）：

| 引用点 | 形态 | 删除后 |
| --- | --- | --- |
| `templates/.themis/CLAUDE.themis.md` | 6 处（行 3、7、118–121），行 118–121 是路由表 | 断链，需重写或整体退场 |
| `templates/.themis/README.md` | 5 处（行 41–44 索引条目 + 行 46 的"零引用"表述） | 断链 |
| `templates/.themis/AGENTS.md` | "与 `core/` 的关系"一节（行 47–51） | 前提消失（该节写的正是"待 replay 后删除"） |
| `templates/.themis/workspace/context/catalog.md` | 行 33，相对路径 `../../core/protocols/context/references/catalog.md`，**目标当前存在** | 活链变断链 |
| `templates/.themis/spec/README.md` | 行 5 的 `.themis/core/` 零引用声明 | 指向不存在的路径 |
| `.gitignore` | 行 8 `/.themis/core/` | 忽略规则失效（无可安装物） |

**注意 `templates/.themis/spec/README.md` 的特殊性**：它既是本次要改的对象，又是 replay 正在依据的只读控制面 `.themis/spec/README.md` 的包源。改包源会让两者产生分歧。处理方式在 `design.md` 中明确决定，并在漂移清单记录——replay 期间不重新安装，分歧是已知且被记录的状态，不是遗漏。

---

## 漂移清单格式

`docs/plan/spec-replay/drift-log.md` 是本计划的核心产出。每个节点走完后**立即**追加一条，不要等到最后回忆——回忆会自动把磕碰抹平，而那些磕碰正是要找的东西。

每条固定五项：

```markdown
### <节点名>

- **控制面怎么说**：读了 `flow.md` 的哪一节、`rules.md` 的哪几节，它们要求什么。
- **实际怎么做的**：真实动作，含偏离。没有偏离就写"无偏离"。
- **漂移**：有/无。有则写清形态——是判不动、说不清、还是想当然跳过了。
- **控制面拦住了吗**：拦住 / 没拦住 / 不适用。没拦住的说明缺口在哪一份文件。
- **给 hard 执行器的启示**：这个闸门将来该由机器强制什么。无则写"无"。
```

**"无漂移"也要记录。** 十三个节点里哪些顺畅、哪些卡顿，对比本身就是信息；只记问题会让清单看起来像流程失败，而实际可能只有两三处需要机器强制。

---

## 核验方式说明

本计划无自动化测试框架。每个任务的核验是**对照控制面的静态检查 + 人工判定**，执行者必须真实运行命令并粘贴输出。三类检查贯穿全程：

1. **结构存在**：工件路径与小节标题符合 `template.md`（`ls`、`grep -c`）。
2. **闸门已证**：`state.md` 记录了该节点的闸门结论，且上游闸门为已证（`grep`）。
3. **引用只指向**：工件引用控制面小节时不复述其内容（人工逐条读括注）。

---

### 任务 1：Intake 与追问，产出 Intent.md 与 QA.md

**文件：**
- 新建：`.themis/workspace/spec/core-removal/Intent.md`
- 新建：`.themis/workspace/spec/core-removal/QA.md`
- 新建：`.themis/workspace/spec/core-removal/state.md`
- 新建：`docs/plan/spec-replay/drift-log.md`

**接口：**
- 消费：`.themis/spec/flow.md` 的 Intake 与追问节点、`rules.md` §1（来源与分层事实源）、§2（意图收敛判据）、`template.md` 的文件小节表。
- 产出：`Intent.md` 六个小节、`QA.md` 至少一轮问答、`state.md` 三个小节、漂移清单前两条。

- [ ] **步骤 1：读控制面，记下这两个节点要求什么**

```bash
sed -n '/^## Intake/,/^## R1/p' .themis/spec/flow.md
sed -n '/^## §1/,/^## §3/p' .themis/spec/rules.md
```

把它们要求的前置闸门、产出、判据抄进你的工作笔记（不是抄进工件——工件里只写指向）。

- [ ] **步骤 2：建立实例目录与漂移清单骨架**

```bash
mkdir -p .themis/workspace/spec/core-removal/step1/{task,impl,verify}
mkdir -p docs/plan/spec-replay
```

`drift-log.md` 写文件头：说明这是 spec 流程首次端到端 replay 的漂移记录，载体是 `core/` 删除，每条五项格式（见本计划"漂移清单格式"一节）。

- [ ] **步骤 3：写 Intent.md**

六个小节严格按 `template.md`：问题 / 期望结果 / 核心链路 / 范围与非做 / 约束 / 来源引用。

内容取自这些**真实事实**（每条都要在"来源引用"里按 `<类型>#<定位>` 格式记录，格式要求见 `rules.md` §1）：

- `core/` 是 simple/full 双路径模型 —— 来源：`代码#templates/.themis/core/policies/README.md`
- 与已批准单一路径契约冲突 —— 来源：`spec#docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md:20`（注意 §1 规定 spec 只作补充、不作事实源，所以还需代码侧来源）
- 设计已定 core 在 spec 落地后删除 —— 来源：`spec#docs/superpowers/specs/2026-08-12-themis-spec-control-plane-design.md:17`（行 15 是冲突陈述，行 17 是"处置（已定）"）
- 98 个文件、六处活跃引用 —— 来源：`代码#templates/.themis/core`。**必须自己跑命令得出数字，不要照抄本计划**：

```bash
find templates/.themis/core -type f | wc -l
git grep -n 'core/' -- templates/.themis/ | grep -v '\.themico/core' | grep -v '^templates/\.themis/core/'
grep -n '/\.themis/core/' .gitignore
```

第二条命令是本计划清点引用点的方式：先取 `templates/.themis/` 下所有 `core/` 命中，再排除指向 `.themico/core` 的（那是另一个模块，不删）与 `core/` 目录自身内部的引用（随目录一起消失）。用 `.themis/core` 作为 grep 模式会漏掉 `catalog.md` 的相对路径写法——写本计划时就漏了。

**注意 §1 的分层事实源规则**：意图属抽象层，可以文档为事实；但"当前实现事实"（core 有多少文件、谁引用它）必须以代码为据。如果你发现某条 claim 只有文档来源、没有代码来源，这就是一处漂移，如实记录。

- [ ] **步骤 4：写 QA.md 第一轮**

按 `template.md`：第 N 轮 → 问 / 答 / 来源，追加写入。

第一轮至少要问清 `rules.md` §2 要求的三件事：Why（为什么现在删）、期望结果（删完什么样算成功）、核心链路（从现状到目标经过哪些必要动作）。

**这一步会遇到 replay 的第一个真实考验**：追问的对象是项目所有者，而你不能代答。如果你发现自己在"替所有者补全意图"，停下，把问题写进 `QA.md` 的"问"，答留空，然后在漂移清单记录这次代答冲动。

- [ ] **步骤 5：写 state.md**

三个小节：当前节点 / 各闸门 / 当前性。

当前节点写"追问"；各闸门记录 Intake 已证、追问进行中；当前性说明哪些工件是 current、哪些还没产出。

- [ ] **步骤 6：核验结构**

```bash
ls .themis/workspace/spec/core-removal/
grep -c '^## ' .themis/workspace/spec/core-removal/Intent.md
grep -c '^## ' .themis/workspace/spec/core-removal/state.md
```

预期：`Intent.md` 六个 `## ` 小节，`state.md` 三个。数量不符说明少写或自创了小节，按 `template.md` 修正。

- [ ] **步骤 7：核验引用只指向**

逐条读 `Intent.md` 与 `QA.md` 里对控制面的引用（如"判据见 `rules.md` §2"），确认没有把 §2 的判据内容抄进工件。这条 grep 抓不到（散文式复述不含行首格式），必须人工读。

- [ ] **步骤 8：追加漂移清单前两条**

为 Intake 与追问各写一条，五项齐全。**如实写**——包括步骤 3 若发现 claim 缺代码来源、步骤 4 若出现代答冲动。

- [ ] **步骤 9：提交**

```bash
git add .themis/workspace/spec/core-removal docs/plan/spec-replay
git commit -m "replay: Intake 与追问节点，产出 Intent/QA/state"
```

---

### 任务 2：R1 意图评审（人类闸门）

**文件：**
- 新建：`.themis/workspace/spec/core-removal/intent-review.md`
- 修改：`.themis/workspace/spec/core-removal/state.md`
- 修改：`docs/plan/spec-replay/drift-log.md`

**接口：**
- 消费：任务 1 的 `Intent.md` 与 `QA.md`；`flow.md` 的 R1 节点；`rules.md` §2（收敛判据）、§3（评审投影低负担）。
- 产出：`intent-review.md` 三个小节（投影 / 未解决反馈 / 结论）。**本任务以项目所有者的批准或驳回结束。**

- [ ] **步骤 1：判定意图是否收敛**

按 `rules.md` §2：Why、期望结果、核心链路三者均明确，且不存在未回答的问题。

注意 §2 的判定者规定——Agent 只能提出收敛主张，R1 评审者是唯一有权确认收敛的角色。所以这一步你产出的是"主张"，不是"结论"。

若 `QA.md` 有未答问题，**不得判收敛**，停在追问节点继续追问。

- [ ] **步骤 2：写投影小节**

按 `rules.md` §3：由抽象到具体渐进呈现，只含该抽象层增量，不重复下层细节。

R1 投影是**意图层**：写清为什么要删 core、删完什么样、经过哪些必要动作。**不写**技术方案（哪些文件怎么改是 R3 的事），不写任务分解。

投影是给人读的——项目所有者要能在两分钟内判断"这是我要的吗"。

- [ ] **步骤 3：写未解决反馈小节**

此刻应为空（还没收到反馈）。如实写"暂无"，不要预填。

- [ ] **步骤 4：呈现给项目所有者并等待**

**这是人类闸门，不是 Agent 任务。**

向项目所有者呈现投影，明确请求批准或驳回。等待明确答复。

**不得**把"我认为会批准"当作批准；**不得**因为等待而先开始抽象设计。未批准前抽象设计节点不得开始（`flow.md` R1 节点）。

- [ ] **步骤 5：记录结论并更新 state.md**

结论小节写所有者的**原话**与结论（approved / 驳回）。若驳回，记录反馈进"未解决反馈"，回到追问节点。

`state.md` 更新：当前节点、R1 闸门结论、当前性。

- [ ] **步骤 6：追加漂移清单**

R1 一条，五项齐全。特别记录：等待人类时有没有产生"先做下一步"的冲动，控制面有没有明确拦住它。

- [ ] **步骤 7：提交**

```bash
git add .themis/workspace/spec/core-removal docs/plan/spec-replay
git commit -m "replay: R1 意图评审，记录所有者结论"
```

---

### 任务 3：抽象设计与 R2 评审（含人类闸门）

**文件：**
- 新建：`.themis/workspace/spec/core-removal/step1/specify.md`
- 新建：`.themis/workspace/spec/core-removal/step1/design.md`
- 新建：`.themis/workspace/spec/core-removal/step1/design-review.md`
- 修改：`.themis/workspace/spec/core-removal/state.md`
- 修改：`docs/plan/spec-replay/drift-log.md`

**接口：**
- 消费：任务 2 的 R1 approved 结论；`flow.md` 的抽象设计与 R2 节点；`rules.md` §1（分层事实源）、§3（低负担）、§5（`[basic]` 标识）、§6（结构决策归属）。
- 产出：`specify.md` 的行为条目与来源覆盖、`design.md` 四个小节、`design-review.md` 三个小节。**本任务以所有者的 R2 批准或驳回结束。**

- [ ] **步骤 1：确认前置闸门**

```bash
grep -A 3 'R1' .themis/workspace/spec/core-removal/state.md
```

R1 必须为 approved 且未 stale。否则停止——前置闸门未满足不得开始（`flow.md` 抽象设计节点）。

- [ ] **步骤 2：写 specify.md**

两个小节：行为条目（`### SPEC-<主题>-<序号>` + 验收判据）/ 来源覆盖。

行为条目写**外部可观测行为**，用 EARS 句式使每条可判定通过/失败。删除 core 的可观测行为例如：

```markdown
### SPEC-COREREMOVAL-001

当 `core/` 删除完成后，`templates/.themis/` 下不得存在任何指向 `core/` 路径的引用。

- 验收判据：`git grep -n 'core/' -- templates/.themis/ | grep -v '\.themico/core'` 的每一条剩余命中，都能对应 `design.md` 中一条明确保留的决定；无法对应的即为断链，判 failed。

**不要把这条判据写成"输出为空"。** `templates/.themis/skills/themico/SKILL.md` 合法引用 `.themico/core/references/`，那是另一个模块、不在删除范围内——所以裸 `core/` 的搜索永远非空，必须先排除 `.themico/core`。而剩下的命中是否允许存在（例如 `AGENTS.md` 里一条"core 已删除"的历史说明），属于 `design.md` 的结构决策，不由本计划预先裁定。
```

**注意 §5 的 `[basic]` 标识**：删除 core 涉及的"纯内部改动"（比如删掉一个只被 core 自己引用的文件）不进 specify；只有对外可观测的（安装包结构、公共入口路径）才进。判断不清的，如实记录为漂移。

- [ ] **步骤 3：写 design.md**

四个小节：架构与边界 / 结构决策 / 取舍 / 事实依据。

**结构决策小节是关键**——按 `rules.md` §6，一切结构决策以 `design.md` 为准，任务文件只做分解。所以这里必须定清：

- `CLAUDE.themis.md` 的 core 章节怎么处理（删除还是改写为 spec 流程）
- `README.md` 行 41–44 的 core 索引条目、以及行 46 的"与上述 `core/` 组件零引用"表述怎么处理
- `AGENTS.md` 的"与 core 的关系"一节怎么处理（core 删除后这节还有意义吗）
- `catalog.md:33` 的相对路径引用怎么处理（目标 `core/protocols/context/references/catalog.md` 当前存在，删除后变断链）
- `.gitignore:8` 的 `/.themis/core/` 忽略规则怎么处理（无可安装物后该规则失效）
- `spec/README.md:5` 的零引用声明怎么处理，以及包源与已安装只读副本的分歧如何记录
- 六处引用之外，有没有遗漏的活跃依赖——**用任务 1 步骤 3 的清点命令重跑一遍，不要相信本计划的清单**（它第一版就漏了两处）

**事实依据小节**按 §1：具体实现层必须以代码为事实源。用命令得到确切数字，粘贴输出，不要凭记忆写。

- [ ] **步骤 4：核验结构**

```bash
grep -c '^## ' .themis/workspace/spec/core-removal/step1/design.md
grep -c '^### SPEC-' .themis/workspace/spec/core-removal/step1/specify.md
```

预期：`design.md` 四个 `## ` 小节；`specify.md` 至少一条 `### SPEC-` 条目。

- [ ] **步骤 5：写 design-review.md 的投影**

按 `rules.md` §3：R2 投影须含**架构或时序 Overview**，只含抽象设计层增量，不重复 specify 的行为条目细节，不写任务分解。

Overview 可以是一张 `text` 代码块的结构图，说明删除前后 `.themis/` 的形态变化。

- [ ] **步骤 6：呈现给项目所有者并等待 R2 批准**

**人类闸门。** 呈现投影，请求批准或驳回，等待明确答复。未批准前详细设计节点不得开始。

- [ ] **步骤 7：记录结论并更新 state.md**

结论写所有者原话与结论。更新 `state.md` 的当前节点、R2 闸门结论、当前性。

- [ ] **步骤 8：追加漂移清单两条**

抽象设计一条、R2 一条。特别记录：`specify.md` 写"外部可观测行为"时有没有把内部改动混进去（§5 边界），`design.md` 的结构决策有没有留下"实现时再定"的空档（那是 §6 要防的）。

- [ ] **步骤 9：提交**

```bash
git add .themis/workspace/spec/core-removal docs/plan/spec-replay
git commit -m "replay: 抽象设计与 R2 评审，记录所有者结论"
```

---

### 任务 4：详细设计任务分段与 R3 评审（含人类闸门）

**文件：**
- 新建：`.themis/workspace/spec/core-removal/step1/task/basic.md`
- 新建：`.themis/workspace/spec/core-removal/step1/task/detail.md`
- 新建：`.themis/workspace/spec/core-removal/step1/task/review.md`
- 修改：`.themis/workspace/spec/core-removal/state.md`
- 修改：`docs/plan/spec-replay/drift-log.md`

**接口：**
- 消费：任务 3 的 R2 approved 结论与 `design.md` 的结构决策；`flow.md` 的详细设计+任务与 R3 节点；`rules.md` §3、§4（basic/detail 判定）、§6（结构决策归属）、§8（孤儿阻断）。
- 产出：`task/basic.md` 的 `### T-B<n>` 条目、`task/detail.md` 的 `### T-D<n>` 条目、`task/review.md` 四个小节。**本任务以所有者的 R3 批准或驳回结束。R3 批准是 impl 节点的唯一解锁条件。**

- [ ] **步骤 1：确认前置闸门**

```bash
grep -A 5 'R2' .themis/workspace/spec/core-removal/state.md
```

R2 必须为 approved 且未 stale。

- [ ] **步骤 2：做 basic/detail 分类**

按 `rules.md` §4：basic 任务必须**同时**满足"被本 step 其他任务依赖"与"单独不产生外部可观测行为"。两条同时满足才是 basic，判定依据必须写入 basic 任务工件。

对 core 删除这个需求，分类可能是这样（你要自己判，不要照抄）：

- 更新 `CLAUDE.themis.md`、`README.md` 的引用 → 是否被"删除 core 目录"这个任务依赖？
- 删除 `core/` 目录本身 → 单独会不会产生外部可观测行为？

**这一步可能暴露 §4 的一个真实边界问题**：如果删除 core 这个需求根本没有"被其他任务依赖且不产生可观测行为"的任务，basic 段就应该是**空的**——而 §4 明写"两段恒定存在，允许为空，空段不产生落地调用"。如果你发现自己在硬凑一个 basic 任务来填满两段，停下，如实记录这次凑数冲动。

- [ ] **步骤 3：写 task/basic.md**

每个 `### T-B<n>` 记四项：结构改动 / 判定依据（为何不单独产生外部可观测行为）/ 被哪些 detail 任务依赖 / `design.md` 中的出处。

若 basic 段为空，文件仍要存在，写明"本段为空"及为什么空（哪条判据不满足）。

- [ ] **步骤 4：写 task/detail.md**

每个 `### T-D<n>` 记三项：行为目标 / 对应 `specify.md` 条目 / 依赖的基础任务。

第二项是 trace 链的一环（`SPEC-TRACE-001`），第三项是 §8 孤儿判定的另一端——basic 任务的消费者关系就记在这里。

- [ ] **步骤 5：写 task/review.md 的前三节**

四个小节：评审范围 / 分类核查 / 未解决反馈 / 结论。

**分类核查**是 R3 的核心动作（`rules.md` §4 判定者：任务作者提出分类，R3 评审者判定）。核查项至少包括：每个 basic 任务都写明了判定依据与被谁依赖；没有 basic 任务单独产生外部可观测行为；没有无消费者的 basic 任务；任务未引入 `design.md` 未定的结构。

一次评审同时覆盖两份任务，不拆成两次（`flow.md` R3 节点）。

- [ ] **步骤 6：呈现给项目所有者并等待 R3 批准**

**人类闸门，且是最关键的一处**——R3 批准是删除动作的唯一解锁条件。未解决反馈必须为空才可批准。

呈现分类结果与任务清单，请求批准或驳回，等待明确答复。

**批准前不得删除任何文件。**

- [ ] **步骤 7：记录结论并更新 state.md**

结论写所有者原话与结论。更新 `state.md`。

- [ ] **步骤 8：追加漂移清单两条**

详细设计+任务一条、R3 一条。特别记录：basic/detail 分类判得动吗，§4 的两条件对这个需求够用吗，有没有出现"为了填满两段而凑任务"。

- [ ] **步骤 9：提交**

```bash
git add .themis/workspace/spec/core-removal docs/plan/spec-replay
git commit -m "replay: 任务分段与 R3 评审，记录所有者结论"
```

---

### 任务 5：impl/basic 与 verify/basic

**文件：**
- 新建：`.themis/workspace/spec/core-removal/step1/impl/basic.md`
- 新建：`.themis/workspace/spec/core-removal/step1/verify/basic.md`
- 修改：`.themis/workspace/spec/core-removal/state.md`
- 修改：`docs/plan/spec-replay/drift-log.md`
- 按 `task/basic.md` 实际改动的文件（若 basic 段非空）

**接口：**
- 消费：任务 4 的 R3 approved 结论与 `task/basic.md`；`flow.md` 的 impl/basic 与 verify/basic 节点；`rules.md` §1、§6、§7（验证身份独立、basic 三项）。
- 产出：`impl/basic.md` 四个小节、`verify/basic.md` 五个小节。

**前置：R3 已获批准。未批准不得开始。**

- [ ] **步骤 1：确认 R3 闸门已证**

```bash
grep -A 5 'R3' .themis/workspace/spec/core-removal/state.md
```

必须为 approved 且未 stale。这是删除动作的解锁条件。

- [ ] **步骤 2：执行 basic 段改动（若非空）**

严格在 R3 批准范围内：不得修改 `Intent.md`、任务或验收要求，不得做无关重构（`SPEC-IMPL-001`）。

若 basic 段为空，本节点不产生调用，直接进入步骤 4 并在 `impl/basic.md` 写明"本段为空，无落地调用"。

- [ ] **步骤 3：写 impl/basic.md**

四个小节：执行身份 / 实际改动 / 与批准范围的偏差 / 命令记录。

**执行身份小节**是 §7 身份独立判定的落点——写清是谁（哪个角色/agent）执行了这次实现。它将与 `verify/basic.md` 的执行身份对比。

**命令记录**粘贴真实执行的命令与输出，不要事后重构。

- [ ] **步骤 4：写 verify/basic.md**

五个小节：执行身份 / 断言与实际结果 / 命令证据 / 结论 / 说明。

按 `rules.md` §7，basic 段只判三项：结构存在、可构建、既有测试（若有）无回归。"结构存在"必须由实际读取实现或运行命令得出，不得凭文档或文件存在判定。

**不得声称交付任何外部行为**——此刻行为尚未实现，任何行为结论都是假的。

**执行身份必须不同于 `impl/basic.md` 的执行身份。** 这是 replay 要真实检验的一处：soft 执行器下没有机器强制身份，如果你发现同一个 agent 既实现又验证，这就是漂移，如实记录。

- [ ] **步骤 5：核验身份独立**

```bash
grep -A 2 '执行身份' .themis/workspace/spec/core-removal/step1/impl/basic.md
grep -A 2 '执行身份' .themis/workspace/spec/core-removal/step1/verify/basic.md
```

两处一比即得。相同即为漂移。

- [ ] **步骤 6：更新 state.md 并追加漂移清单两条**

impl/basic 一条、verify/basic 一条。特别记录：身份独立在 soft 执行器下靠什么保证，basic 三项判得动吗。

- [ ] **步骤 7：提交**

```bash
git add -A
git commit -m "replay: impl/basic 与 verify/basic"
```

---

### 任务 6：impl/detail 与 verify/detail

**文件：**
- 新建：`.themis/workspace/spec/core-removal/step1/impl/detail.md`
- 新建：`.themis/workspace/spec/core-removal/step1/verify/detail.md`
- 修改：`.themis/workspace/spec/core-removal/state.md`
- 修改：`docs/plan/spec-replay/drift-log.md`
- 删除：`templates/.themis/core/`（98 个文件）
- 修改：六处活跃引用（清单见本计划"目标文件结构"一节的表），按 `design.md` 的结构决策处理——`templates/.themis/CLAUDE.themis.md`、`templates/.themis/README.md`、`templates/.themis/AGENTS.md`、`templates/.themis/workspace/context/catalog.md`、`templates/.themis/spec/README.md`、`.gitignore`

**接口：**
- 消费：任务 5 的 verify/basic 结论与 `task/detail.md`；`flow.md` 的 impl/detail 与 verify/detail 节点；`rules.md` §1、§7、§8（孤儿阻断）。
- 产出：`impl/detail.md` 四个小节、`verify/detail.md` 五个小节。**孤儿判定在本节点完成**（`rules.md` §8）。

- [ ] **步骤 1：确认前置闸门**

```bash
grep -A 8 'verify/basic\|basic' .themis/workspace/spec/core-removal/state.md
```

verify/basic 结论须为通过；basic 段为空时前置闸门为 R3 approved（`flow.md` impl/detail 节点）。

- [ ] **步骤 2：执行 detail 段改动**

按 `task/detail.md` 与 `design.md` 的结构决策执行：

```bash
git rm -r templates/.themis/core
```

以及六处引用的更新。严格在 R3 批准范围内，不得引入 `design.md` 未定的结构（`rules.md` §6）。

`.gitignore` 的 `/.themis/core/` 一行随之删除——`templates/.themis/core/` 不存在后，安装动作不会再产生 `.themis/core/`，留着该规则就是留一条指向不存在之物的忽略。注意 `/.themis/spec/`、`/.themis/skills/` 等其余忽略规则**必须保留**，它们对应仍然存在的安装物。

- [ ] **步骤 3：写 impl/detail.md**

四个小节：执行身份 / 实际改动 / 与批准范围的偏差 / 命令记录。

实际改动要具体到文件数与路径，命令记录粘贴真实输出。

- [ ] **步骤 4：写 verify/detail.md**

五个小节：执行身份 / 断言与实际结果 / 命令证据 / 结论 / 说明。

按 `rules.md` §7：依据实际实现与证据判定 `passed`/`failed`，**逐条**对照 `specify.md` 的验收判据断言，不得只覆盖其中一部分条目。

对每条 `### SPEC-COREREMOVAL-<n>` 跑它自己写明的验收判据命令，粘贴输出。

**执行身份必须不同于 `impl/detail.md`。**

- [ ] **步骤 5：做孤儿判定**

按 `rules.md` §8，孤儿判定在本节点完成、结论写入本节点工件：核实每个 basic 任务声明的消费者在实际代码中存在。

若 basic 段为空，写明"basic 段为空，无孤儿可判"。

- [ ] **步骤 6：核验全仓无残留引用**

```bash
git grep -n 'core/' -- templates/.themis/ | grep -v '\.themico/core' || echo "  templates/.themis 无残留"
git grep -n '\.themis/core' -- ':!docs' || echo "  全仓（除 docs）无 .themis/core 残留"
go test ./... -count=1 2>&1 | tail -5
go build ./... && echo "build ok"
```

前两条命令的预期：

- 第一条的每条剩余命中都必须对应 `design.md` 中一条明确保留的决定（判据同 `SPEC-COREREMOVAL-001`）。无法对应即为断链。
- 第二条应为空。若 `.gitignore` 仍命中，说明步骤 2 漏了那一行。

**`docs/` 被排除是有意的**：`docs/plan/35-core-prompt-flow/` 等历史文档中的 core 引用是归档记录，记录的是当时的事实，**不得改写**。改写历史记录来让 grep 变干净，是把证据改成结论。

Go 测试与构建须仍通过——core 是 Markdown 合同，删它不该影响 Go 代码，若影响了说明有隐藏依赖。

- [ ] **步骤 7：更新 state.md 并追加漂移清单两条**

impl/detail 一条、verify/detail 一条。特别记录：逐条断言做到了吗，孤儿判定判得动吗，删除动作有没有超出 R3 批准范围。

- [ ] **步骤 8：提交**

```bash
git add -A
git commit -m "replay: impl/detail 与 verify/detail，删除 core"
```

---

### 任务 7：人工验收（人类闸门）与摘要

**文件：**
- 新建：`.themis/workspace/spec/core-removal/step1/acceptance.md`
- 新建：`.themis/workspace/spec/core-removal/step1/summary.md`
- 修改：`.themis/workspace/spec/core-removal/state.md`
- 修改：`docs/plan/spec-replay/drift-log.md`

**接口：**
- 消费：任务 6 的 verify/detail `passed` 结论与孤儿判定结论；`flow.md` 的人工验收与摘要节点；`rules.md` §7（复核身份独立）、§8（据结论阻断）、§9（工件阐述方式）。
- 产出：`acceptance.md` 四个小节、`summary.md` 三个小节。**本任务以所有者的验收结论结束。**

- [ ] **步骤 1：确认前置闸门**

verify/detail 结论须为 `passed`，且孤儿阻断核查通过（`flow.md` 人工验收节点）。

- [ ] **步骤 2：写 acceptance.md 的交付视图与阻断核查**

四个小节：交付视图 / 阻断核查 / 用户原话 / 结论。

**交付视图**给所有者看：删了什么、改了什么、验证跑了什么、结果如何。这是验收判断的依据，要能独立读懂。

**阻断核查**两项：不存在已落地但无消费者的 basic 改动（引用 `verify/detail.md` 的孤儿判定结论，不重新做代码层判定——`rules.md` §8）；`verify/detail.md` 结论为通过。

还要复核 §7 要求的身份独立性：impl 与 verify 的执行身份是否真的不同。

- [ ] **步骤 3：呈现给项目所有者并等待验收**

**人类闸门。** 呈现交付视图与阻断核查结果，请求验收（accepted）或退回。等待明确答复。

**verify 提供的是证据，不构成授权——人工验收是流程中唯一的授权点**（`flow.md` 人工验收节点）。

- [ ] **步骤 4：记录用户原话与结论**

"用户原话"小节写所有者的**原话**，不要转述。这是 `SPEC-ACCEPT-001` 的证据。

- [ ] **步骤 5：写 summary.md**

三个小节：交付摘要 / 绑定的验收结论 / 中性工件说明。

摘要必须绑定实际交付（`SPEC-SUMMARY-001`），仅当验收 accepted 后才可产出。

"中性工件说明"写明：本摘要是与 Themico 无关的中性工件，是否喂给 Themico 由可选 adapter 决定，不构成流程运行前提（`SPEC-THEMICO-002`）。

- [ ] **步骤 6：更新 state.md 为终态**

当前节点写"摘要（已完成）"，各闸门记录全部结论，当前性说明全部工件为 current。

- [ ] **步骤 7：追加漂移清单两条**

人工验收一条、摘要一条。特别记录：阻断核查能只靠引用结论完成吗（还是忍不住重做判定），摘要的判定者问题（§9 的链尾兜底在实践中可行吗）。

- [ ] **步骤 8：提交**

```bash
git add -A
git commit -m "replay: 人工验收与摘要，流程走完"
```

---

### 任务 8：整理漂移清单，产出 hard 执行器强制清单

**文件：**
- 修改：`docs/plan/spec-replay/drift-log.md`
- 新建：`docs/plan/spec-replay/hard-enforcement-list.md`

**接口：**
- 消费：任务 1–7 累积的十三条漂移记录。
- 产出：按"该由机器强制什么"归类的强制清单，作为未来 hard/CLI 的输入（这是落地⑤在 `mvp.md` §5 P4 中被赋予的目的）。

- [ ] **步骤 1：通读漂移清单，统计**

```bash
grep -c '^### ' docs/plan/spec-replay/drift-log.md
grep -c '漂移\*\*：有' docs/plan/spec-replay/drift-log.md
grep -c '控制面拦住了吗\*\*：没拦住' docs/plan/spec-replay/drift-log.md
```

预期：十三条记录（十三个节点）。发生漂移的条数与"没拦住"的条数是本次 replay 的核心数字。

- [ ] **步骤 2：写 hard-enforcement-list.md**

按"机器该强制什么"归类，每条写：

```markdown
### <强制项>

- **来自哪个节点的漂移**：<节点名>
- **soft 执行器下靠什么**：<Agent 自觉 / 人工评审 / 无保障>
- **hard 执行器该怎么强制**：<具体机制>
- **优先级依据**：<为什么这条比别的更该先做——用 replay 中的实际发生说话，不用推测>
```

**优先级必须由 replay 的实际发生决定**，不是由"理论上更重要"决定。真的漂移过的排在前面，没漂移但理论上有风险的排后面并注明"本次未发生"。

- [ ] **步骤 3：在漂移清单末尾写总结**

三段：十三个节点里哪几处顺畅、哪几处卡顿；控制面拦住了什么、没拦住什么；如果只能给 hard 执行器做三件事，是哪三件。

- [ ] **步骤 4：核验清单自洽**

```bash
grep -c '^### ' docs/plan/spec-replay/hard-enforcement-list.md
grep -oE '来自哪个节点的漂移\*\*：.*' docs/plan/spec-replay/hard-enforcement-list.md
```

每条强制项引用的节点，必须在漂移清单中真实存在且确实记录了漂移。凭空生成的强制项要删掉——那是推测，不是 replay 产出。

- [ ] **步骤 5：提交**

```bash
git add docs/plan/spec-replay
git commit -m "docs: replay 漂移清单与 hard 执行器强制清单"
```

- [ ] **步骤 6：准备 `mvp.md` 落地⑤ 状态更新，请求批准**

`mvp.md` 目前记录 ⑤ 为未开始（文件头落地状态行、以及 `mvp.md:177` 的"**未开始**"标记），replay 完成后这两处成为过时描述。

**不得直接改。** `mvp.md` 是已批准契约，本项目历次改动均经项目所有者逐次批准。本步骤只做三件事：

1. 指出两处待更新位置与拟改后的措辞；
2. 说明依据——本次 replay 的实际产出（漂移清单十三条、强制清单若干条、`core/` 已删除）；
3. 请求批准，等明确答复后才落笔。

同时核验：`mvp.md` §2 的行为契约条目**一行未动**。落地状态的变化不改变契约本身，动了即是越界。

批准后单独提交，提交信息写明经批准。

---

## 完成判定

以下全部成立才可报告本计划完成：

1. `.themis/workspace/spec/core-removal/` 下的工件齐备，目录结构与文件小节符合 `.themis/spec/template.md`，无自创文件或小节。
2. 十三个节点各在 `state.md` 留下闸门结论，`state.md` 终态记录全部闸门。
3. 四处人类闸门（R1/R2/R3/验收）各有项目所有者的明确答复，`intent-review.md`、`design-review.md`、`task/review.md`、`acceptance.md` 的结论小节记录了原话。
4. `impl/basic.md` 与 `verify/basic.md`、`impl/detail.md` 与 `verify/detail.md` 的执行身份各自不同；相同则已作为漂移记录。
5. `templates/.themis/core/` 已删除；六处引用均按 `design.md` 的决定处理完毕，任务 6 步骤 6 的两条断言符合其预期（第二条为空）；`go build ./...` 与 `go test ./...` 通过。**基线：删除前三个包全绿**（`internal/themico/result`、`store`、`validate`），删除后须仍全绿——core 是 Markdown 合同，出现 Go 侧变化即说明有未预期的依赖。
6. `docs/` 下的历史 core 引用未被改写。
7. `docs/plan/spec-replay/drift-log.md` 有十三条记录，每条五项齐全，"无漂移"也已记录。
8. `docs/plan/spec-replay/hard-enforcement-list.md` 的每条强制项都能追溯到漂移清单中一条真实发生的漂移。
9. 控制面 `.themis/spec/` 四份文件在 replay 期间未被修改（`git status` 与 `.gitignore` 共同保证）。

该判定不表示 spec 流程已可用于所有需求——一次 replay 只覆盖了一个需求形态（纯删除、无新增行为）。也不等于用户接受，更不授权 push。

---

## 计划自检清单

- **Spec coverage**：`flow.md` 十三个节点 → 任务 1（Intake/追问）、2（R1）、3（抽象设计/R2）、4（详细设计+任务/R3）、5（impl/verify basic）、6（impl/verify detail）、7（验收/摘要）；`mvp.md` 落地⑤要求的"暴露 Agent 在哪些闸门漂移"→ 任务 8 的强制清单。
- **人类闸门**：四处各自独立成步并明文"不得由 Agent 代答"，R3 明文"批准前不得删除任何文件"。
- **控制面只读**：全局约束首条，并由 `.gitignore` 与完成判定第 9 条共同保证。唯一例外是**包源** `templates/.themis/spec/README.md`（删除的对象之一），其与已安装只读副本的分歧已在"目标文件结构"一节明确要求记录。
- **漂移记录时机**：每个任务末尾追加，不留到最后回忆——回忆会抹平磕碰。
- **"无漂移"也记录**：漂移清单格式一节明文要求，避免清单看起来像流程失败。
- **强制清单的可追溯性**：任务 8 步骤 4 反查每条强制项对应的真实漂移，凭空生成的要删。
- **引用只指向**：全局约束一条，任务 1 步骤 7 有人工核验（grep 抓不到散文式复述）。
- **Scope control**：不改控制面、不做 hard 执行器实现、不新增 YAML/Python/Shell 脚本文件、不引入版本概念。计划中的 `bash` 代码块是执行者手动运行的核验命令与 git 操作，不是落库的脚本文件，也不替代任何产品能力。
- **断言已实测**：任务 1 步骤 3、任务 2 步骤 2、任务 6 步骤 6 的 grep 断言已在写计划时于当前工作树实跑，确认能匹配真实文本并给出预期的删除前画面（六处引用、`.gitignore` 一行）。Go 基线也已实跑为全绿。
- **自检查出的两个真实错误**（已修，留在此处作为执行者的警示）：
  1. 引用点清点为"三处"，实为六处——`catalog.md` 用 `../../core/` 相对路径写引用，逃过了 `.themis/core` 的 grep；`.gitignore` 的忽略规则也会一并失效。
  2. `SPEC-COREREMOVAL-001` 原验收判据写作"`git grep 'core/' templates/.themis/` 输出为空"，而 `skills/themico/SKILL.md` 合法引用 `.themico/core/references/`，该断言永远不可能满足——会把一条正确的交付判成失败。

  两个错误同源：**用不精确的 grep 模式代替逐个核实**。执行 replay 时凡遇路径断言，先跑一遍看真实输出，再决定断言怎么写。
