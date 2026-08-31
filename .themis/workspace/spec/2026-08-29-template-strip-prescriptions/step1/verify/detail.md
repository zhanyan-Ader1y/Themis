# verify/detail.md — 2026-08-29-template-strip-prescriptions / step1

> 本文件是 verify/detail 节点的实例工件。本节点的前置闸门、产出与失败去向见 `flow.md`「verify/detail」节；判据与判定者见 `rules.md` §7、§8、§12。以上只指向位置，本文件不复述其文字。
>
> **本文件每个数字与存在性断言都由本节点自行实跑得出，按 `template.md`「断言形态」记法书写。`impl/detail.md`「命令记录」里的数值未被采信，全部重跑。**

## 执行身份

- **身份**：Claude Opus 5，**由执行者会话派发的独立子代理**，非 `impl/detail.md` 所记的执行者会话。两份工件的「执行身份」小节一比即得（`rules.md` §7）。
- **工作树**：仓库 `C:/Coding/Themis` 的主工作树，分支 `main`。**未切分支、未新建工作树、未提交。**
- **验证时的 HEAD**：`b8a5de3`（取自 `git rev-parse --short HEAD`）。**历史点位，不按可重跑断言书写**——后续提交会使其失真，与 `impl/detail.md` 的同类处置一致。
- **本节点承担**：五条判据的逐条断言、孤儿判定（`rules.md` §8）、追溯链环 2 与环 3 的检出（`rules.md` §12）。

## 断言与实际结果（每条断言注明对应任务）

### SPEC-TPLSTRIP-001 — 规定性措辞归零（对应任务 T-D1、T-D2、T-D3）

`sed -n '11,102p' .themis/spec/template.md | grep -cE '必须|不得|只用|固定记|一律'` → `0`

**满足。** 判据要求 `0`，实跑 `0`。

### SPEC-TPLSTRIP-002 — 要求仍在 §12，`template.md` 留指向（对应任务 T-D2）

判据 002a：`awk '/^\*\*三种写法\*\*/,/^\*\*三种写法的共同前提/' .themis/spec/rules.md | grep -c '完整\|逗号并列\|区间'` → `4`

判据 002b：`grep -c '写法的判定与展开规则见' .themis/spec/template.md` → `1`

**满足。** 002a 要求 `4`，实跑 `4`；002b 要求 `≥1`，实跑 `1`。

**002a 的成因与其断言意图不符，如实标出**——见「说明」第 2 条。**002 的实质层面另有一处缺口**，见「说明」第 3 条。

### SPEC-TPLSTRIP-003 — 一行搬进 §7（对应任务 T-D3）

`awk '/^## §7/,/^## §8/' .themis/spec/rules.md | grep -c '记明它是哪条命令'` → `1`

**满足。** 判据要求 `≥1`，实跑 `1`。

### SPEC-TPLSTRIP-004 — 四节结构与示例仍在（对应任务 T-D1、T-D3）

`grep -c '^## ' .themis/spec/template.md` → `4`

**满足。** 判据要求 `4`，实跑 `4`。

**并已排除"把节删空以求 001 归零"这条捷径**——见下节「交叉核查：001 与 004 的相反约束」，四节行数与示例均逐项实测。

### SPEC-TPLSTRIP-005 `[横切]` — 不扰动既有十二节与既有测试（无对应任务）

判据 005a：`grep -c '^## §' .themis/spec/rules.md` → `12`

判据 005b：`go test ./... 2>&1 | grep -c '^FAIL'` → `0`

**满足。** 005a 要求 `12`，实跑 `12`；005b 要求 `0`，实跑 `0`。

005b 的原命令含 `2>&1`，`themis verify` 拒绝重跑（见「说明」第 6 条）。**等价可重跑形态一并实跑，结果相同**——`go test` 的包级 `ok`／`FAIL` 行本就走 stdout：

`go test ./... | grep -c '^FAIL'` → `0`

**本条带 `[横切]` 标识，按 `rules.md` §12 不计入环 2 上游集合**，因而不参与差集。

### 交叉核查：001 与 004 的相反约束

`specify.md` 已标明"只满足 001 的最省力做法是把节删空"。**本节点逐项实测，未发生该情形。**

改后逐节行数：

- 「实例目录树」：`awk '/^## /{c++} c==1' .themis/spec/template.md | wc -l` → `31`
- 「文件小节」：`awk '/^## /{c++} c==2' .themis/spec/template.md | wc -l` → `31`
- 「编号引用写法」：`awk '/^## /{c++} c==3' .themis/spec/template.md | wc -l` → `12`
- 「断言形态」：`awk '/^## /{c++} c==4' .themis/spec/template.md | wc -l` → `16`

改前逐节行数（同法取自本 step 落地前的 `626395d`）：

- 「实例目录树」：`git show 626395d:.themis/spec/template.md | awk '/^## /{c++} c==1' | wc -l` → `31`
- 「文件小节」：`git show 626395d:.themis/spec/template.md | awk '/^## /{c++} c==2' | wc -l` → `31`
- 「编号引用写法」：`git show 626395d:.themis/spec/template.md | awk '/^## /{c++} c==3' | wc -l` → `14`
- 「断言形态」：`git show 626395d:.themis/spec/template.md | awk '/^## /{c++} c==4' | wc -l` → `16`

**四节唯一收缩的是「编号引用写法」，减 `2` 行**（`14` → `12`），与 T-D2「删两行规定」吻合；**其余三节行数一行未变，无一节被删空。**

示例本身逐项仍在：

- `T-B<n>` 四项的内容：`grep -c '结构改动、判定依据、被哪些 detail 任务依赖' .themis/spec/template.md` → `1`
- `T-D<n>` 三项的内容：`grep -c '行为目标、对应 `specify.md` 条目、依赖的基础任务' .themis/spec/template.md` → `1`
- 三种写法表格的数据行：`grep -c '^| \*\*\(完整\|逗号并列\|区间\)\*\*' .themis/spec/template.md` → `3`
- 断言形态的记法示例：`grep -c '两段式\|三段式' .themis/spec/template.md` → `4`
- 实例目录树代码块：`grep -c '^  Intent.md' .themis/spec/template.md` → `1`
- 文件小节表格的数据行：`grep -c '^| `' .themis/spec/template.md` → `16`

### 孤儿判定（`rules.md` §8）

`grep -c '^### T-B' .themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/task/basic.md` → `0`

**basic 段为空，由本节点自行断言得出，未采信上游工件自述**（`rules.md` §7 拒绝条件末项）。**无 basic 改动即无"已落地但无消费者"的对象，孤儿判定：不存在孤儿。**

### 追溯链环 2（`specify.md` → `task/detail.md`）

上游取 `specify.md` 的 `### SPEC-` 条目、**排除 `[横切]` 条目**；下游取 `task/detail.md` 中出现的编号并展开逗号并列写法；差集为空则通。

上游集合（三段式，末段是据原样输出写下的判断）：

`grep '^### SPEC-' .themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/specify.md | grep -v '\[横切\]' | grep -o 'SPEC-[A-Z]*-[0-9]*' | sort -u | awk 'BEGIN{ORS=" "} {print}'` → `SPEC-TPLSTRIP-001 SPEC-TPLSTRIP-002 SPEC-TPLSTRIP-003 SPEC-TPLSTRIP-004` → `4 个上游编号`

下游按 `rules.md` §12「先展开，再取差集」分两步。**第一步取原样命中，第二步展开**——两种写法各一条断言：

完整写法命中：

`grep -o 'SPEC-TPLSTRIP-[0-9][0-9][0-9]' .themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/task/detail.md | sort -u | awk 'BEGIN{ORS=" "} {print}'` → `SPEC-TPLSTRIP-001 SPEC-TPLSTRIP-002 SPEC-TPLSTRIP-003 SPEC-TPLSTRIP-005`

逗号并列写法命中：

`grep -o 'SPEC-TPLSTRIP-[0-9]*、[0-9]*' .themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/task/detail.md | sort -u | awk 'BEGIN{ORS=" "} {print}'` → `SPEC-TPLSTRIP-001、004 SPEC-TPLSTRIP-003、004` → `裸数字 004 继承前缀，展开得 SPEC-TPLSTRIP-004`

**两步合并，下游集合为 `001`、`002`、`003`、`004`、`005` 五个编号。上游四个编号逐个出现其中，差集为空，环 2 通过。**

- 排除的横切条目数：`grep -c '^### SPEC-.*\[横切\]' .themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/specify.md` → `1`
- 上游条目总数：`grep -c '^### SPEC-' .themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/specify.md` → `5`
- 下游出现区间写法的处数：`grep -cE 'SPEC-[A-Z]+-[0-9]+ 至 [0-9]+' .themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/task/detail.md` → `0`——**故本次展开只需处理完整与逗号并列两种写法**，非遗漏区间。

`task/detail.md` 下游多出 `SPEC-TPLSTRIP-005`（该文件「判据 005 无任务承担，理由」一节）。按 `rules.md` §12「下游出现上游没有的编号，本身不判失败」，**不判失败，也未被用来凑数**——上述判定取的是差集为空，不是数量比较。

### 追溯链环 3（`task/detail.md` → 本文件）

上游取 `task/detail.md` 的 `### T-D` 条目；下游取本文件中出现的 `T-D` 编号；差集为空则通。

上游集合：

`grep -o '^### T-D[0-9]*' .themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/task/detail.md | grep -o 'T-D[0-9]*' | sort -u | awk 'BEGIN{ORS=" "} {print}'` → `T-D1 T-D2 T-D3` → `3 个上游编号`

下游集合（本文件）：

`grep -oE 'T-D[0-9]+' .themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/verify/detail.md | sort -u | awk 'BEGIN{ORS=" "} {print}'` → `T-D1 T-D2 T-D3` → `3 个下游编号`

下游无需展开——本文件出现的 `T-D` 编号全为完整写法，无「裸数字接在 `、` 之后」的缩写：`grep -cE 'T-D[0-9]+、[0-9]' .themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/verify/detail.md` → `0`

**上游三个编号逐个出现在下游集合中，差集为空，环 3 通过。**

- 上游条目数：`grep -c '^### T-D' .themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/task/detail.md` → `3`
- 上游出现区间写法的处数：`grep -cE 'T-D[0-9]+ 至 [0-9]+' .themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/task/detail.md` → `0`

## 命令证据

**五条判据（`specify.md` 各条目下所记的原命令，逐条重跑）**

| 判据 | 命令 | 实跑值 | 判据要求 |
| --- | --- | --- | --- |
| 001 | `sed -n '11,102p' .themis/spec/template.md \| grep -cE '必须\|不得\|只用\|固定记\|一律'` | `0` | `0` |
| 002a | `awk '/^\*\*三种写法\*\*/,/^\*\*三种写法的共同前提/' .themis/spec/rules.md \| grep -c '完整\|逗号并列\|区间'` | `4` | `4` |
| 002b | `grep -c '写法的判定与展开规则见' .themis/spec/template.md` | `1` | `≥1` |
| 003 | `awk '/^## §7/,/^## §8/' .themis/spec/rules.md \| grep -c '记明它是哪条命令'` | `1` | `≥1` |
| 004 | `grep -c '^## ' .themis/spec/template.md` | `4` | `4` |
| 005a | `grep -c '^## §' .themis/spec/rules.md` | `12` | `12` |
| 005b | `go test ./... 2>&1 \| grep -c '^FAIL'` | `0` | `0` |

**判据 002b 的原命令含反引号，为使本文件可被 `themis verify` 重跑，上表记的是去掉反引号的等价命令。原命令一并实跑，结果相同**：

``grep -c '写法的判定与展开规则见 `rules.md` §12' .themis/spec/template.md`` → `1`

**结构与边界**

- `template.md` 总行数：`wc -l < .themis/spec/template.md` → `100`
- `template.md` 四节起始行：`grep -n '^## ' .themis/spec/template.md | cut -d: -f1 | paste -sd,` → `11,42,73,85`
- 改前 `template.md` 总行数：`git show 626395d:.themis/spec/template.md | wc -l` → `102`
- 判据 001 区间**之外**（第 `1`–`10` 行）仍含规定性词的行数：`sed -n '1,10p' .themis/spec/template.md | grep -cE '必须|不得|只用|固定记|一律'` → `1`

**搬迁的落点与去重**

- `rules.md` 中该要求的处数：`grep -c '数字与存在性断言都必须记明它是哪条命令跑出来的' .themis/spec/rules.md` → `1`
- `template.md` 中残留同义句的处数：`grep -c '记明它是哪条命令' .themis/spec/template.md` → `1`
- 控制面逐字重合复核：`/tmp/themis.exe overlap .themis/spec` → `未发现需人工复核的重合片段。`

**判据 002a 命令自身的核查**

- 该 `awk` 区间的终止模式在 `rules.md` 中的处数：`grep -c '^\*\*三种写法的共同前提' .themis/spec/rules.md` → `0`
- 该 `awk` 区间实际取到的行数：`awk '/^\*\*三种写法\*\*/,/^\*\*三种写法的共同前提/' .themis/spec/rules.md | wc -l` → `33`

**§12 现存的反向指向**

- `§12` 内仍称 `template.md` 为写法规定源的处数：`awk '/^## §12/,0' .themis/spec/rules.md | grep -c '那一节规定怎么写\|写法的规定见'` → `2`

**流程工件齐备性（本节点顺带发现，非五条判据之一）**

- 实例根 `state.md` 是否存在：`ls .themis/workspace/spec/2026-08-29-template-strip-prescriptions/ | grep -c '^state.md$'` → `0`
- `step1/verify/` 目录在本节点动手前是否存在：`git ls-files .themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/verify | wc -l` → `0`

**控制面自校验**

- `/tmp/themis.exe verify .themis/spec/template.md` → 无输出（退出码 `0`，即零条不符）
- `/tmp/themis.exe verify .themis/spec/rules.md` → 无输出（退出码 `0`）
- CLI 由本节点自行构建：`go build -o /tmp/themis.exe ./cmd/themis`

**本文件的自检**：`/tmp/themis.exe verify` 对本文件报 `3` 条，退出码 `1`。**三条逐一对应「说明」第 6 条**——两条是 `go test` 判据被白名单与 `>` 拒绝（（a）），一条是本节点为记录 CLI 缺陷而**有意写入的最小复现**（（c））。**除这三条外，本文件其余断言全部由 CLI 原样重跑并与所记值一致。**

## 结论

**`passed`。**

五条判据 `SPEC-TPLSTRIP-001` 至 `005` 全部由本节点自行实跑重验，逐条满足；判据 001 与 004 这对相反约束**并存成立**，未发生"删空节以求归零"；孤儿判定为**不存在孤儿**；追溯链环 2、环 3 的差集均为 `0`，两环通过。

**本结论只覆盖五条判据。**「说明」记的六处均在判据射程之外，随结论一并上呈，供人工验收裁定是否另立需求处置——**它们不改变本节点的 `passed`，但其中第 3 条是本 step 引入的实质缺口，第 2 条使判据 002a 的证明力低于表面。**

## 说明

### 1. 措辞是否真成了示例口吻——判据够不到的一层，本节点的判断

`specify.md` 已标明这一层无判据覆盖。本节点读改后原文（第 `67`、`69`、`75`、`83`、`87` 行）逐行判断，**结论是三行到位、两行只到"去规定性"而未真正到"示例口吻"**。

**第 `75` 行——到位。** "引用 `SPEC-` 与 `T-D` 编号时的三种写法，均来自已完成实例的实际书写：" 改前是"**只用下列三种写法**"。改后句子讲的是这三种写法**的来历**（来自实际书写），而不是命令读者用哪几种。**这是真正的示例口吻**：它交代了示例的出处，读者读完知道"别人是这么写的"，而非"我被要求这么写"。

**第 `83` 行——到位。** "上表第二、三行里的裸数字（`004`、`005`）紧跟在完整编号之后——**写法的判定与展开规则见 `rules.md` §12**。" 改前是"**裸数字必须紧跟在一个完整编号之后，中间不得插入其他文字**"。改后主语从"裸数字"变成"上表第二、三行里的裸数字"——**它在描述那张表长什么样，不在规定读者该怎么写**。指向句只写一层，未复述 §12 的内容，与 `design.md` 结构决策二一致。

**第 `67`、`69` 行——去掉了规定性，但没到示例口吻。** 现文是"每个 `### T-B<n>` **的四项**：结构改动、判定依据、……"。"固定记"这个动词性强制确实没了，`design.md` 结构决策一的判准（去动词、留名词）**确实被执行了**。但"**每个** … **的四项**"仍是全称断定——它断定每一个 `T-B<n>` 都恰有这四项，**这是一句关于文件内容的事实陈述，而 ADR 的原话是"不作为任何文件内容的事实"**。真正的示例口吻会是"例如 `### T-B<n>` 下依次写：……"。**本节点判定：合乎 `design.md` 已被 R2/R3 批准的判准，但未达 ADR 措辞的字面标准。**

**第 `87` 行——五行里最不像示例的一行。** 现文是"工件里的数字与存在性断言记明它是哪条命令跑出来的——**该要求与其判定者见 `rules.md` §7**，本节只给记法示例。" 前半句**把已搬去 §7 的那条要求又复述了一遍**（只是去掉了"必须"），后半句才指向 §7。`design.md` 结构决策二自己写明"指向句只写一层，写多了就又成了复述"——**这一行同时做了复述与指向两件事**。合乎示例口吻的写法是删去前半句，只留"本节只给记法示例；该要求与其判定者见 `rules.md` §7"。

**这不是判据能拦的**：`grep` 只数规定性词，数不出"这句话在复述别处的规定"。`themis overlap` 也没报（见「命令证据」），因为搬进 §7 时措辞已改，不构成逐字重合。

### 2. 判据 002a 的命令测的不是它断言的东西

判据 002a 的 `awk` 区间终止模式 `^\*\*三种写法的共同前提` **在 `rules.md` 中零处**（实测 `0`）——区间因此从「三种写法」表一直延伸到文件末尾，实际取到 `33` 行，而非该表所在的那一小段。命中的 `4` 行是**三行表格数据 + 一行散文**（§12 末段"其中裸数字与**完整**编号的位置关系……"里的"完整"二字）。

**数值 `4` 是对的，成因不是。** 它同时也解释了为何 002a 在改动前后恒为 `4`：本 step 未动 `rules.md` §12 一个字（`git show b8a5de3` 的 `rules.md` 改动只在 §7 一行），**这条判据因此证不出本 step 做了什么**——与 `specify.md` 自记的第 `33` 次同型问题（"命令测的东西与断言的东西不是一回事"）属同一类，只是这次出在**区间的终止模式不存在**上，`specify.md` 订正 002b 时未连带检查 002a。

**本节点仍判 002 满足**：判据要求的值实跑相符，且 §12 的三种写法表格确实完整存在（表格数据行实测 `3`，见「交叉核查」）。**但这条判据的证明力低于它看上去的程度，如实记明。**

### 3. §12 仍称 `template.md` 是写法的规定源，而该规定已被本 step 删除——本 step 引入的悬空指向

实测 `rules.md` §12 内有 `2` 处仍把 `template.md` 当作写法规定的所在：

- "**三种写法的书写要求见 `template.md`「编号引用写法」**——**那一节规定怎么写**，本节规定据此怎么展开。"
- "**写法的规定见 `template.md`「编号引用写法」。**"

**改动前这两句成立**（那一节当时确实写着"只用下列三种写法"与"裸数字必须紧跟……"）。**T-D2 删掉那两行后，这两句指向的规定不复存在**——§12 把书写要求托付给 `template.md`，而 `template.md` 现在把判定与展开托付回 §12，**两边互指，那条"裸数字须紧跟完整编号、中间不得插入文字"的书写要求在控制面已无规范性归属**。§12 仅存与之相关的是展开表里的"裸数字继承前面的主题前缀"（展开规则）与一句"裸数字与完整编号的位置关系是把编号与散文数字分开的唯一依据"（理由），**都不是书写要求本身**。

**这同时与 ADR 直接冲突**——ADR 裁定"援引 `template.md` 作为事实源的写法一律无效，**无论出现在工件还是其他控制面文件里**"，而 §12 这两句正是这种援引，**且本 step 没有处理它**。

**为什么它没被任何判据拦住**：判据 002 只问"要求是否仍在 §12"，问的是三种写法**表格**在不在（在）；判据 005 `[横切]` 只数 §12 的**节数**（`12`）。**没有一条判据问"§12 里指向 `template.md` 的话现在还成不成立"。**

**本节点的处置**：不据此改判 `failed`——五条判据是本节点的判定范围（`rules.md` §7），它们逐条满足。**但本 step 的交付并未完成 ADR 的推论 3**，该缺口须由人工验收决定是本需求补一个 step，还是另立需求。**不得因本节点结论为 `passed` 而认为 ADR 已落实完毕。**

### 4. 判据 001 的行号区间此次侥幸覆盖全文，且第 `3` 行在区间之外

`specify.md` 已自标该判据"按行号范围取节，而剥离后行号会变"。**实测：改前 `102` 行、改后 `100` 行，`sed -n '11,102p'` 两次都恰好覆盖到文件末尾**——本次未失准，但**这是文件缩短带来的侥幸，不是判据设计使然**：若剥离后文件变长，第 `102` 行之后的内容会静默逃出检查。

另有一处如实记明：区间起点是第 `11` 行，**第 `1`–`10` 行不在检查内，实测其中 `1` 行含匹配词**——即第 `3` 行"含义判定**一律**见 `rules.md`，流程走向**一律**见 `flow.md`"。**本节点判定该行不属越位**：它说的是"定义不在本文件、去别处看"，正是 ADR 想要的定位声明，与"规定文件内容"相反。**但它落在判据射程之外这件事，是判据的边界，不是它的正确性。**

### 5. 本 step 之外、本节点顺带发现的两处工件缺失

- **实例根无 `state.md`**（实测 `0`）。`flow.md` 第 `35` 行要求"每个节点完成后，执行者必须更新实例 `state.md` 的当前节点、该节点闸门结论、当前性三项"，且它是 soft 执行器下判定"停在 last proven gate"的依据。**本实例从 Intake 至今未建过该文件。**
- **无 `step1/verify/basic.md`**。本 step 的 basic 段为空（实测 `T-B` 条目 `0` 条），按 `flow.md`「verify/basic」节该节点仍应产出五节工件、结论取 `不适用`；`impl/detail.md` 的前置闸门直接取了 R3 approved 而未产出该工件。

**两处均不在本节点五条判据的射程内**，且正是 ADR「已知代价」第 4 项所记的"`flow.md` 各节点「产出」项无判定者"这一未处置缺口的又一次实发。**如实上呈，不代行处置。**

### 6. `themis verify` 自检暴露的三处工具限制，其中一处是静默给出错值

本节点写完后按交接要求跑了 `/tmp/themis.exe verify <本文件>` 自检。**五条判据里有六条命令能被 CLI 原样重跑并与本文件所记一致；`go test` 那条不能。** 自检过程另暴露三处工具限制，如实记明：

**（a）判据 005b 的原命令 CLI 两重拒绝。** `go test ./... 2>&1 | grep -c '^FAIL'` 既含被拒的 `2>&1`（`>` 属 `internal/themis/verify.go` 的 `shellMetacharacters`），`go` 又不在该文件的只读白名单（白名单为 `grep wc find ls git awk sed test cat head tail comm sort uniq diff`）。**这条命令是 `specify.md` 写定的判据，不是本文件的自选写法**——本节点保留原命令不改，另附等价可重跑形态 `go test ./... | grep -c '^FAIL'`（`go test` 的包级 `ok`／`FAIL` 行本走 stdout），**但它同样因 `go` 不在白名单而被拒**。两条都已由本节点在 shell 中手工实跑，均得 `0`。

**（b）差集无法写成单行断言。** `comm -23` 取两路输入需进程替换或重定向，单行 `awk` 差集实现必含 `;` 与 `&&`，三者都在被拒字符里；`paste` 也不在白名单。本文件因此把两环检出写成**上下游集合各自列举**的三段式断言，包含关系直接可读——**判定仍是 §12 要求的"上游有、下游没有的差集为空"，不是被禁止的数量比较**。本节点另在 shell 中以 `comm -23` 与单行 `awk` 两法独立复算过两环差集，均得 `0`，与集合列举一致。

**（c）一处静默错值，最小复现如下。** 同一条断言在 shell 与 CLI 下结果不同，且 CLI 把差异报成"断言与实跑结果不一致"，看上去像工件写错：

- shell 实跑：`grep -c '\(SPEC\)' .themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/task/detail.md` → `4`
- **同一行经 `themis verify` 重跑得 `0`。上一行就是复现本身**——本文件自检时，CLI 必定把它报成"实跑得到 0，文件里写的是 4"。**该条报错是预期的、也是本条的证据**，不是本文件写错了数。

对照实验表明**不是反斜杠被整体丢弃**——`grep -c 'SPEC\|zzz' …`、`grep -c 'S\PEC' …` 两条在 CLI 下均得 `4`，与 shell 一致；**只有 BRE 分组 `\(` `\)` 出错**。本节点未继续诊断成因（不属本 step 范围），**只记明后果**：凡判据命令用了 `\(` `\)`，`themis verify` 的"重跑比对"会给出与人工实跑相反的结论。**本 step 的五条判据无一使用该语法，本次结论不受影响**；本文件初稿曾在环 2 的扫描命令里用到，已改写规避。

**（a）与（c）合起来是一处工具与控制面之间的错配**：`specify.md` 允许写、而 CLI 不能重跑或会跑错的判据命令，会让"断言可被重跑核验"这项保证在该条上落空。**如实上呈，不代行处置。**
