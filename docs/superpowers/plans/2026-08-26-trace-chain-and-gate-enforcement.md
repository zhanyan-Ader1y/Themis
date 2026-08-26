# 追溯链检出与闸门强制通则 实施计划

> **给执行者：** 必需子技能——用 `superpowers:subagent-driven-development`（推荐）或 `superpowers:executing-plans` 逐任务实施本计划。步骤使用 `- [ ]` 复选框语法跟踪。

**目标：** 让追溯链的断裂能被一条命令扫出，并把"前置闸门未满足即不得开始"从执行者自觉变成有落点、有判定者的条款。

**架构：** 只改三份控制面文件的条款文本，不写代码、不建新文件、不引入工具。追溯链靠**引用计数对齐**检出——上游条目数与下游引用到的不同编号数相等则通；闸门通则靠 `state.md` 的闸门结论记录，缺结论即缺口可查。

**技术栈：** 纯 Markdown。判据是 `grep`/`awk` 命令，无测试框架、无脚本、无 Go 代码。

**Spec：** `docs/superpowers/specs/2026-08-26-trace-chain-and-gate-enforcement-design.md`

## 全局约束

- **不实现 `themis` Go CLI，不为它预留接口或占位。** 本项目无此工具（`cmd/` 下只有 `themico`）。
- **不声称任何机器强制。** 当前强制水平见 `.themis/spec/README.md`；`docs/plan/README.md`「通用限制」明写不得用 Prompt/README/template/policy 的存在冒充 machine enforcement。
- **不改已批准契约 `docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md` 的任何条目**——本计划是兑现它，不是改它。
- **新增或修改的任何判据必须带判定者与判定时机**（`.themis/AGENTS.md`「判据必须有判定者」）。没有判定者的判据不是闸门。
- **不给 `Intent.md` 的诉求编号**；不做双向引用；不建 `trace.md`。三者均在 spec §3.2、§3.4 排除。
- 所有 Markdown 内容使用中文。不新增 YAML、Python、Shell 脚本、版本概念或版本目录。
- 引用控制面小节时**只指向不复述**（`.themis/AGENTS.md`）：写"判据见 `rules.md` §12"，不把判据抄进别处。
- 执行前保存 `git status --short`；不得 reset、restore、clean、stash 或覆盖既有修改。

## 本计划的"测试"是什么

本计划不产出代码，因此没有单元测试。**每条新增条款的测试 = 它自带的扫描命令在真实实例上跑出预期值。**

三个已闭合实例是天然的测试数据：

| 实例 | 已知性质 |
| --- | --- |
| `authorization-traceability` | **环 2 断裂**——抽象设计 5 条，任务只引 3 条 |
| `workspace-cleanup` | 环 2 完好——抽象设计 5 条，任务 6 条全部标注出处 |
| `core-removal` | 环 2 完好 |

**RED 判据**：扫描命令在 `authorization-traceability` 上必须报出断裂（否则命令无效）。
**GREEN 判据**：同一命令在另两个实例上必须报通过（否则命令误报）。

**一条命令若在三个实例上给出相同结果，它就是恒真的，不是判据**——这是本项目已记过四次的缺陷形态（`hard-enforcement-list.md` 第 1 项）。

---

## 目标文件结构

```text
.themis/spec/
  template.md   ← 任务 1 改：补环 1、3、4 的引用落点（三行小节划分 + 说明段）
  rules.md      ← 任务 2 改：新增 §12 追溯链检出（四字段 + 三条扫描命令）
  flow.md       ← 任务 3 改：通用条款补闸门强制通则

.themis/workspace/spec/<spec-id>/   ← 不改。三个已闭合实例只作测试数据读取，一字不动
```

**不创建任何新文件。**

---

## 任务 1：`template.md` 补三处引用落点

**文件：**
- 修改：`.themis/spec/template.md`（小节划分表三行 + 表下说明段）

**接口：**
- 消费：`template.md` 现有小节划分表；环 2 的既有落点写法（第 64 行）作为形态样板。
- 产出：三处新落点的确切措辞，任务 2 的扫描命令依赖它们规定的编号形态。

- [ ] **步骤 1：记录落地前基线**

```bash
cd /c/Coding/Themis
git rev-parse --short HEAD
git status --short
```

把 HEAD 短哈希记下，任务 4 的一致性核验要用。工作区应无本计划之外的改动。

- [ ] **步骤 2：跑三条扫描命令，确认当前全部无法执行**

```bash
cd /c/Coding/Themis
grep -c '来自 `Intent.md`' .themis/spec/template.md
grep -c '对应任务' .themis/spec/template.md
grep -c '引用验证断言' .themis/spec/template.md
```

预期：三条全部输出 `0`——三处落点均不存在。**这是 RED：落点没有，环 1、3、4 无从检出。**

- [ ] **步骤 3：改 `specify.md` 那一行小节划分（环 1 落点）**

把这一行：

```markdown
| `specify.md` | 行为条目（`### SPEC-<主题>-<序号>` + 验收判据）/ 来源覆盖 |
```

改为：

```markdown
| `specify.md` | 行为条目（`### SPEC-<主题>-<序号>` + 验收判据 + 来自 `Intent.md` 哪一节）/ 来源覆盖 |
```

- [ ] **步骤 4：改 `verify` 那一行小节划分（环 3 落点）**

把这一行：

```markdown
| `verify/basic.md`、`verify/detail.md` | 执行身份 / 断言与实际结果 / 命令证据 / 结论 / 说明 |
```

改为：

```markdown
| `verify/basic.md`、`verify/detail.md` | 执行身份 / 断言与实际结果（每条断言注明对应任务）/ 命令证据 / 结论 / 说明 |
```

- [ ] **步骤 5：改 `acceptance.md` 那一行小节划分（环 4 落点）**

把这一行：

```markdown
| `acceptance.md` | 交付视图 / 阻断核查 / 用户原话 / 结论 |
```

改为：

```markdown
| `acceptance.md` | 交付视图 / 阻断核查（引用验证断言的结论）/ 用户原话 / 结论 |
```

- [ ] **步骤 6：在表下说明段补一段，说明三处落点的用途**

在 `template.md` 中环 2 落点那句（`task/detail.md` 中每个 `### T-D<n>` 固定记三项……）之后，另起一段写入：

```markdown
`specify.md` 每个 `### SPEC-` 条目记「来自 `Intent.md` 哪一节」、`verify/detail.md` 每条断言注明「对应任务」、`acceptance.md`「阻断核查」引用验证断言的结论——这三项与上一段的环 2 落点合起来，构成 `SPEC-TRACE-001` 所要求的追溯链在本文件的四处落点。链的检出判据与判定者见 `rules.md` §12。
```

- [ ] **步骤 7：跑步骤 2 的三条命令，确认全部变为 1**

```bash
cd /c/Coding/Themis
grep -c '来自 `Intent.md`' .themis/spec/template.md
grep -c '对应任务' .themis/spec/template.md
grep -c '引用验证断言' .themis/spec/template.md
```

预期：三条全部输出 `1`（各在小节划分表命中一次；说明段用的是不同措辞，不重复命中）。**这是 GREEN。**

若某条输出 `2`，说明说明段的措辞与表格重复，改说明段措辞使其不与表格逐字相同——**不要改表格**，表格措辞是扫描锚点。

- [ ] **步骤 8：确认小节划分表仍是四份人工闸门工件齐备**

```bash
cd /c/Coding/Themis
grep -E '^\| `(intent-review|design-review|task/review|acceptance)\.md`' .themis/spec/template.md | grep -c '用户原话'
```

预期：`4`。改 `acceptance.md` 那行时不得碰掉「用户原话」——它是 `rules.md` §11 的落点。

- [ ] **步骤 9：提交**

```bash
cd /c/Coding/Themis
git add .themis/spec/template.md
git commit -m "feat(spec): template 补追溯链环 1、3、4 的引用落点"
```

---

## 任务 2：`rules.md` 新增 §12 追溯链检出

**文件：**
- 修改：`.themis/spec/rules.md`（在 §11 之后追加 §12）

**接口：**
- 消费：任务 1 规定的三处落点措辞；`rules.md` §1–§11 的四字段固定结构（适用节点 / 判据 / 拒绝条件 / 判定者）作为形态样板。
- 产出：三条扫描命令的确切写法，任务 4 的一致性核验直接跑它们。

- [ ] **步骤 1：在三个真实实例上跑环 2 扫描，确认命令能区分断裂与完好**

```bash
cd /c/Coding/Themis
for s in authorization-traceability workspace-cleanup core-removal; do
  d=.themis/workspace/spec/$s/step1
  a=$(grep -c '^### SPEC-' $d/specify.md)
  b=$(grep -oE 'SPEC-[A-Z]+-[0-9]+' $d/task/detail.md | sort -u | wc -l)
  echo "$s: specify=$a task引用=$b $([ "$a" = "$b" ] && echo OK || echo BROKEN)"
done
```

预期输出：

```
authorization-traceability: specify=5 task引用=3 BROKEN
workspace-cleanup: specify=5 task引用=5 OK
core-removal: specify=4 task引用=4 OK
```

**这一步是本任务最重要的验证**：命令必须在已知断裂的实例上报 `BROKEN`、在完好的实例上报 `OK`。**三个实例给出相同结果则命令无效**，须改命令再跑，不得继续。

- [ ] **步骤 2：确认 §12 尚不存在**

```bash
cd /c/Coding/Themis
grep -c '^## §12' .themis/spec/rules.md
```

预期：`0`。**这是 RED。**

- [ ] **步骤 3：在 `rules.md` 末尾追加 §12**

追加以下内容（`rules.md` 现以 §11 结尾）：

```markdown

## §12 追溯链检出

- **适用节点**：verify/detail（环 2、3）、人工验收（环 4）。
- **判据**：追溯链四环中，环 2、3 用**引用计数对齐**检出——上游条目数与下游引用到的不同编号数必须相等；环 4 检出验收的阻断核查是否引用了验证断言的结论；环 1 只检出 `specify.md` 每个条目是否声明了它来自 `Intent.md` 哪一节。四处落点见 `template.md`。
- **拒绝条件**：计数不等而判通过；未实际运行扫描命令即声称链完好；以"下游没写但意思在那里"代替引用；把环 1 的"有无指向"读作"数量对齐"。
- **判定者**：**verify/detail 的验证角色**在验证时判环 2、3，结论写入该节点工件；**人工验收的验收者**在验收时判环 4。

环 2 的扫描形态——上游取 `specify.md` 的 `### SPEC-` 条目数，下游取 `task/detail.md` 中出现的不同 `SPEC-` 编号数，二者相等则通。环 3 同形：上游取 `task/detail.md` 的 `### T-D` 条目数，下游取 `verify/detail.md` 中出现的不同 `T-D` 编号数。

**本节的能力边界，如实写明**：计数对齐只能发现**漏引**——下游少引了上游某条。它发现不了**引错**：引了一个存在的编号，但那条任务其实没有承担该条目。发现引错需要逐条读语义，不在本节能力内。

**环 1 的精度低于其余三环**：`Intent.md` 的诉求不编号（那会让 Intake 变成填表），因此环 1 只能查"有没有指向"，不能查"数量对不对"。

**本节不由机器执行。** 当前强制水平见 `README.md`；本节的判定全部由人类或 Agent 角色在上述节点完成。
```

- [ ] **步骤 4：确认 §12 四字段齐备**

```bash
cd /c/Coding/Themis
grep -c '^## §12' .themis/spec/rules.md
awk '/^## §12/,0' .themis/spec/rules.md | grep -cE '适用节点|判据|拒绝条件|判定者'
```

预期：第一条 `1`，第二条 `4`。**这是 GREEN。**

**注意 `awk` 范围写法**：用 `/^## §12/,0`（取到文件末），**不要用 `/^## §12/,/^## §13|^$/`**——后者会在标题后第一个空行即终止，只取到标题行。这是本项目已实测到的缺陷（`authorization-traceability` 实例 impl/detail「偏差 1」）。

- [ ] **步骤 5：确认 §12 不含声称机器执行的措辞**

```bash
cd /c/Coding/Themis
awk '/^## §12/,0' .themis/spec/rules.md | grep -nE '机器|自动|CLI|校验|拦截'
```

命令**只列候选、不给通过与否**。逐行读出每处命中：**"声称机器执行"违规，"声明不由机器执行"正是应写的内容。** 预期唯一命中是末段那句"本节不由机器执行"，属后者。

正则区分不了这两者（已实测：`本条不由机器强制` 照样命中 `机器强制`），故此处必须人读。

- [ ] **步骤 6：确认 §11 未被破坏**

```bash
cd /c/Coding/Themis
grep -c '^## §11' .themis/spec/rules.md
awk '/^## §11/,/^## §12/' .themis/spec/rules.md | grep -cE '适用节点|判据|拒绝条件|判定者'
```

预期：第一条 `1`，第二条 `4`。追加 §12 不得影响 §11。

- [ ] **步骤 7：确认未触发 `rules.md` 拆分阈值**

```bash
cd /c/Coding/Themis
wc -l < .themis/spec/rules.md
```

预期：小于 `300`。`.themis/spec/README.md`「rules.md 拆分退出条件」规定全文超 300 行即须拆分。当前 116 行加 §12 约 20 行，远低于阈值，**不需要拆分**。若实际超过 300，停下并报告——那是本计划未预期的情形。

- [ ] **步骤 8：提交**

```bash
cd /c/Coding/Themis
git add .themis/spec/rules.md
git commit -m "feat(spec): rules 新增 §12 追溯链检出"
```

---

## 任务 3：`flow.md` 补闸门强制通则

**文件：**
- 修改：`.themis/spec/flow.md`（「通用失败去向」节之后、各节点小节之前）

**接口：**
- 消费：`flow.md` 现有的「闸门结论取值按节点类型固定」取值表（该表规定 `state.md` 记什么）。
- 产出：闸门通则条款，任务 4 核验它与取值表不冲突。

- [ ] **步骤 1：确认通则尚不存在**

```bash
cd /c/Coding/Themis
grep -c '前置闸门未满足' .themis/spec/flow.md
```

预期：`0`。**这是 RED**——每个节点各写了自己的前置，但没有一条通则。

- [ ] **步骤 2：确认现有取值表在位（通则依赖它）**

```bash
cd /c/Coding/Themis
grep -c '闸门结论取值按节点类型固定' .themis/spec/flow.md
```

预期：`1`。通则的第 2 部分依赖该表——`state.md` 的闸门结论正是"前置是否满足"的可查形态。

- [ ] **步骤 3：在取值表所在段落之后追加通则**

在 `flow.md`「通用失败去向」节内、闸门结论取值表及其说明段之后，追加：

```markdown

**闸门强制通则**：任一节点在其前置闸门未满足时**不得开始**；已开始的须停止并退回该前置所在节点。各节点的前置闸门见其自身小节，本条不复述。

**前置的可查形态**：每个节点开始时，须能从实例 `state.md`「各闸门」读出其前置闸门的结论。**这把"前置是否满足"从执行者的记忆变成可查记录**——某节点有结论而其上游没有，即是跳过留下的缺口。

**判定者**：该节点自身在开始前自查；**下一个人工闸门在其评审或验收时复核**——人工闸门本就要读 `state.md`，复核"上游各闸门是否都有结论"不增加负担（`SPEC-GATE-001`）。

**本条的边界，如实写明**：它**阻止不了**不自觉的执行体跳过前置——当前强制水平下没有拦截点（见 `README.md`）。它能做到的是让跳过在 `state.md` 留下可查缺口，由下一个人工闸门发现。
```

- [ ] **步骤 4：确认通则已在位且四部分齐备**

```bash
cd /c/Coding/Themis
grep -c '闸门强制通则' .themis/spec/flow.md
grep -cE '前置的可查形态|判定者|本条的边界' .themis/spec/flow.md
```

预期：第一条 `1`；第二条 `≥3`。**这是 GREEN。**

- [ ] **步骤 5：确认通则不与各节点自身的前置条款冲突**

```bash
cd /c/Coding/Themis
grep -c '^- \*\*前置闸门\*\*' .themis/spec/flow.md
```

预期：`14`（十四个节点各有自己的前置闸门行）。通则说的是"未满足即不得开始"，各节点说的是"我的前置是什么"——**两者互补不冲突**。若该数不是 14，停下并报告。

**这个数写计划时实跑核对过，起初误写为 13**——那是旧节点数。`flow.md` 现有十四个节点：Intake、追问、R1、**step 定界**、抽象设计、R2、详细设计 + 任务、R3、impl/basic、verify/basic、impl/detail、verify/detail、人工验收、摘要。`step 定界` 是 2026-08-24 意图分两层时新增的，早期文档中的"十三个节点"是那之前的说法。

- [ ] **步骤 6：确认未声称机器强制**

```bash
cd /c/Coding/Themis
grep -n '闸门强制通则' -A 12 .themis/spec/flow.md | grep -nE '机器|自动|CLI|拦截'
```

命令只列候选。逐行读出：预期唯一命中在"边界"段的"没有拦截点"——那是**声明不存在拦截**，正是应写的内容。

- [ ] **步骤 7：提交**

```bash
cd /c/Coding/Themis
git add .themis/spec/flow.md
git commit -m "feat(spec): flow 补闸门强制通则与前置可查形态"
```

---

## 任务 4：三处产物一致性核验

**文件：**
- 不修改任何文件。本任务只跑命令并记录真实输出。

**接口：**
- 消费：任务 1、2、3 的全部产物。
- 产出：可核验的结论，供本计划的完成判定引用。

- [ ] **步骤 1：跑环 2 扫描，三实例对照**

```bash
cd /c/Coding/Themis
for s in authorization-traceability workspace-cleanup core-removal; do
  d=.themis/workspace/spec/$s/step1
  a=$(grep -c '^### SPEC-' $d/specify.md)
  b=$(grep -oE 'SPEC-[A-Z]+-[0-9]+' $d/task/detail.md | sort -u | wc -l)
  echo "$s: $a vs $b $([ "$a" = "$b" ] && echo OK || echo BROKEN)"
done
```

预期：`authorization-traceability` 报 `BROKEN`，另两个报 `OK`。**这证明判据能真判失败，不是恒真。**

- [ ] **步骤 2：跑环 3 扫描，三实例对照**

```bash
cd /c/Coding/Themis
for s in authorization-traceability workspace-cleanup core-removal; do
  d=.themis/workspace/spec/$s/step1
  a=$(grep -c '^### T-D' $d/task/detail.md)
  b=$(grep -oE 'T-D[0-9]+' $d/verify/detail.md | sort -u | wc -l)
  echo "$s: $a vs $b $([ "$a" = "$b" ] && echo OK || echo BROKEN)"
done
```

如实记录输出。**三个实例都是在环 3 落点存在之前走完的**，因此报 `BROKEN` 属预期——它们的验证工件没有按新落点写。这不是缺陷，是新条款生效前的历史状态。**须在结论中写明这一点，不得据此判定新条款无效。**

- [ ] **步骤 3：确认三份控制面文件的改动范围**

```bash
cd /c/Coding/Themis
git diff --stat <任务1步骤1记下的基线>..HEAD -- .themis/spec/
```

预期：恰三个文件被改——`template.md`、`rules.md`、`flow.md`。**若出现第四个文件，停下并报告越界。**

- [ ] **步骤 4：确认实例工件一字未改**

```bash
cd /c/Coding/Themis
git diff --stat <基线>..HEAD -- .themis/workspace/ | tail -3
```

预期：**无输出**。三个已闭合实例只作测试数据读取，本计划不改它们。若有输出，停下并报告。

- [ ] **步骤 5：确认已批准契约未被改动**

```bash
cd /c/Coding/Themis
git diff --stat <基线>..HEAD -- docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md
```

预期：**无输出**。本计划兑现契约，不改契约。

- [ ] **步骤 6：确认 Go 侧未受影响**

```bash
cd /c/Coding/Themis
go build ./... && echo BUILD_OK
go test ./... 2>&1 | grep -c '^ok'
go test ./... 2>&1 | grep -c '^FAIL'
```

预期：`BUILD_OK`、`ok` 计数 `10`、`FAIL` 计数 `0`。本计划全改 Markdown，若影响 Go 说明有隐藏依赖——那正是要测出来的（该形态在 `workspace-cleanup` 实例真实发生过一次）。

- [ ] **步骤 7：提交核验记录**

本步骤不产生文件改动。若前六步全部符合预期，本计划的实施部分完成；若任一步不符，**停下并报告，不得继续**。

---

## 完成判定

以下全部成立才可报告本计划完成：

1. `template.md` 三处落点在位，四份人工闸门工件的「用户原话」小节未被破坏（任务 1 步骤 7、8）。
2. `rules.md` §12 存在且四字段齐备，§11 未被影响，全文未超 300 行（任务 2 步骤 4、6、7）。
3. `flow.md` 闸门强制通则在位且四部分齐备，十三个节点各自的前置闸门行仍为 13 条（任务 3 步骤 4、5）。
4. 环 2 扫描在 `authorization-traceability` 报 `BROKEN`、另两实例报 `OK`——**判据能真判失败**（任务 4 步骤 1）。
5. 改动恰三个文件，实例工件与已批准契约零改动（任务 4 步骤 3、4、5）。
6. Go 构建与测试不劣于基线（任务 4 步骤 6）。

**不得声称的**：不得声称追溯链已被机器强制；不得声称环 1 的精度与其余三环相同；不得声称计数对齐能发现"引错"。这三处能力边界已写入 §12，报告时须与结论一并呈现。

## 本计划不做的

- 不实现 `themis` Go CLI，不为它预留接口。
- 不改三个已闭合实例的任何工件——它们只作测试数据。
- 不给 `Intent.md` 的诉求编号。
- 不做双向引用、不建 `trace.md`。
- 不解决身份独立问题（验证节点判环 2、3，而验证者与实现者在三个实例中只分开过一次）——该缺口随 spec §6 第 4 条一并带出，不在本计划范围。
