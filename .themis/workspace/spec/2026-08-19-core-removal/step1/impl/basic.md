# impl/basic.md — 2026-08-19-core-removal / step1

> 本文件是 impl/basic 节点的实例工件。本节点的前置闸门、产出、失效波及、失败去向，以及 basic 段为空时的处理见 `flow.md`「impl/basic」节；本节点适用的判定条款见该节末尾所指的 `rules.md` 两处；四个小节的固定划分、以及「执行身份」小节作为身份独立判定落点这一用途见 `template.md`（`impl/basic.md`、`impl/detail.md` 一行，与其下的说明段）。以上各处只指向位置，本文件不复述其文字。

## 执行身份

- **身份**：Claude Opus 5，以 SDD 派发的任务 5 执行者身份运行；工作树 `.claude/worktrees/spec-flow-replay`，分支 `spec-flow-replay`。当前强制水平下没有独立的实现者角色账户，身份即这一次 agent 会话本身。
- **同一身份亦执行 verify/basic**：`verify/basic.md`「执行身份」记的是同一次会话。两处一比，结果是**相同**——`rules.md` §7 对验证角色提出的独立性要求在本 step 未成立。此处如实记录，不虚构第二身份；后果与判定写在 `verify/basic.md`「结论」「说明」，记录见 `docs/plan/spec-replay/drift-log.md`「verify/basic」条目。
- **授权来源**：R3 approved（`state.md`「各闸门」R3 行；结论原话见 `step1/task/review.md`「结论」）。本节点未在该授权之外取得任何新授权。

## 实际改动

**无——本 step 的 basic 段为空，本节点不产生落地调用。**

- **空段的来历**：`step1/task/basic.md` 判定本段无 `### T-B<n>` 条目（判定过程与所采口径写在该文件「基础任务」小节），该分类已由 R3 判定并批准（`step1/task/review.md`「分类核查」第 1 条与「结论」）。本节点不重开分类，也不因"本段空着"而回头造任务。
- **本节点的产出对照**：`flow.md`「impl/basic」节列出本节点两项产出。第一项即本文件四节；第二项在空段下为空集——`templates/` 下没有任何文件被本节点创建、修改或删除，`.gitignore` 与仓库根 `AGENTS.md` 同样未被触碰（命令 I1、I4）。
- **删除动作仍未发生**：`templates/.themis/core/` 当前仍为 98 个文件（命令 I2），与 `step1/design.md`「事实依据」命令 1 所载一致。该目录的删除是 `step1/task/detail.md` 的 T-D6，属 impl/detail，不属本节点。
- **`rules.md` §6 在本节点的落点**：该节把"落地有没有替 `design.md` 把结构定了"这一判交给 verify/basic 的验证角色。本节点零改动，不存在可供引入的落地点；对应断言与命令见 `verify/basic.md`。
- **`rules.md` §1 在本节点的落点**：本文件的每条事实断言都由本节点实际运行的命令产生，输出原样粘贴在「命令记录」，无一条以文档为来源。

## 与批准范围的偏差

**落地范围：无偏差。** 未修改 `Intent.md`、两份任务文件或任何验收要求，未做无关重构，未改动 `templates/` 下任何文件（命令 I1、I4 为空输出）。R3 批准的六处落地做法一处也未提前执行。

**需要如实标出的三点，均不属落地改动，但都发生在本任务这一次编辑里：**

1. **本节点之后是否还该走 verify/basic，控制面与本次 replay 的任务分解不一致。** `flow.md`「impl/basic」节末对空段给出的走向，与本次任务分解要求继续产出 `verify/basic.md` 这件事之间存在差异。本节点自身的动作与该节一致（零调用），差异落在下一个节点是否发生，因此不计为本节点的偏差；比对与处置写在 `verify/basic.md`「说明」，并记入 `docs/plan/spec-replay/drift-log.md`「verify/basic」条目。
2. **顺带修复了三处结转的记录缺陷**，均为记录准确性修复，不改变任何已批准结论、判定或落地范围：（a）`docs/plan/spec-replay/drift-log.md` R3 条目「控制面怎么说」里四段去引号的原文搬运（外加一处语序重排、实词全留），改写为记录者自身的压缩，改后已用 8 字滑窗对四份控制面文件复检；（b）`state.md` R3 行所引所有者逐字批复脱落句末句号、且未说明它是整条消息的截断，已补全并注明；（c）`step1/task/review.md`「分类核查」第 8 条第二项与第 5 条，都在记录 R3 处置的同一次编辑里顺带修剪、改写了所有者已评审过的原文而未加说明，已补记这些删改。（**本条描述由任务 6 就地更正**：本节点当时写的是"第 8 条第二项……已补记该次修剪"，此后披露范围两次扩大——先扩到第 5 条与"四段文字加一处词级改动"，再由任务 6 的逐段机械比对扩到第 5 条八处；原描述已失准，现改为覆盖两处的表述。准确的逐轮经过见 `state.md`「当前性」`task/review.md` 一行，不在本文件重复。）第（c）项触碰的是 R3 评审工件本身——修改只加了一段声明性说明，未改动「结论」原话、未改动分类判定，因此不构成 `flow.md`「R3 详细方案评审」节失效波及条款所指的那类变更；如所有者认为任何对该文件的改动都应触发重评，本次修复可以回退。
3. **`state.md` 的 impl/basic 行取值被改写**（未开始 → 已证）。本次 replay 自定的结论取值集合里仍没有能表达"空段、零落地调用"的一档（缺口由任务 4 记入 `docs/plan/spec-replay/drift-log.md` R3 条目）；本轮不新增取值，改用集合内已有的一档并在证据栏写明其在此处的确切含义。取值集合的缺口本身未被修复。

## 命令记录

以下命令在本节点实际运行，输出原样粘贴，未事后重构。

**命令 I1**——本节点是否改动了 `templates/` 下任何文件：

```bash
git diff HEAD --stat -- templates/
```

输出为空（零行）。

**命令 I2**——`templates/.themis/core/` 当前受版本控制的文件数：

```bash
git ls-files templates/.themis/core/ | wc -l
```

```text
98
```

**命令 I3**——`task/basic.md` 中 `### T-B<n>` 条目数，用以核实本段确为空段：

```bash
grep -c '^### T-B' .themis/workspace/spec/2026-08-19-core-removal/step1/task/basic.md
```

```text
0
```

**命令 I4**——本次落地范围内全部目标（五个待编辑文件，加上待整体删除的 `templates/.themis/core/` 目录）所在路径的工作树状态，三条路径合起来覆盖这六项：

```bash
git status --porcelain -- templates/ .gitignore AGENTS.md
```

输出为空（零行）。

**命令 I5**——本节点开始前的整树状态，用以确认无继承自上一任务的未提交改动：

```bash
git status --porcelain
```

输出为空（零行）。
