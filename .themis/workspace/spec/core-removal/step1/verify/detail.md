# verify/detail.md — core-removal / step1

> 本文件是 verify/detail 节点的实例工件。本节点的前置闸门、产出、失效波及与失败去向见 `flow.md`「verify/detail」节；本节点的断言范围、身份独立要求与拒绝条件见 `rules.md` §7，孤儿判定的判据与判定者见 §8；五个小节的固定划分、以及「执行身份」作为身份独立判定落点、「说明」作为人类语义落点这两项用途见 `template.md`（`verify/basic.md`、`verify/detail.md` 一行及其下的说明段）。以上各处只指向位置，本文件不复述其文字。
>
> **本文件里的每个数字与每条存在性断言，都由本节点当场跑命令得出，输出原样粘在「命令证据」，并在收尾时重跑过一遍比对。** `impl/detail.md` 的自述在本文件中只是**被核验的对象**，不作为证据使用；该文件「命令记录」里的任何输出都没有被搬进本文件。

## 执行身份

- **身份**：Claude Opus 5（模型标识 `claude-opus-5`），以 SDD 派发的任务 6b（verify/detail）**独立验证者**身份运行；工作树 `C:/Coding/Themis/.claude/worktrees/spec-flow-replay`，分支 `spec-flow-replay`。本次会话开始时 HEAD 为 `2daa931`、工作树干净（命令 V1）。当前强制水平下没有独立的验证者角色账户，身份即这一次 agent 会话本身。
- **与 `impl/detail.md`「执行身份」比对的结果：不相同——身份独立成立。** 对方那栏记的是"SDD 派发的任务 6 前半程（impl/detail）执行者"，动手前 HEAD 为 `3b2dde0`；本栏是另一次派发、另一次会话，角色是 verify/detail 验证者，起始 HEAD 已是 `2daa931`——其间隔着 `c6417e9`（impl/detail 的落地提交）与 `2daa931`（其后一次计划口径订正）。派发任务、会话、起始 HEAD 三项都不同。对方那栏明写不预写、不猜测本栏，本栏也不替对方那栏背书；两栏各自独立填写后一比即得，这正是控制面把该判定的落点设在两处「执行身份」小节的用法。
- **本栏能自证到哪一步**：本次会话在写下本文件之前，对 `templates/**`、`.gitignore`、仓库根 `AGENTS.md` 没有做过任何写操作——落地改动在本次会话开始前就已经在 `c6417e9` 里（提交时刻 `2026-08-21 14:36:49`，命令 V1），本次会话对仓库的全部动作是读取与运行只读命令。**核验不动的地方如实写在「说明」第 2 条**：两栏的模型标识相同，且当前没有任何机器签名把"两次会话"这件事固定下来，本条独立性成立于控制面指定的比对方式，不是密码学证明。
- **与 basic 段的对照**：`verify/basic.md`「执行身份」明写与 `impl/basic.md` 相同、该条在本 step 的 basic 段未成立。本轮 detail 段不再如此，差别来自派发把两个节点拆给两次会话，不是本节点的自证。
- **本文件的所有者**：验证角色。四条判据的结论与孤儿判定结论只写在本文件，未写进任何实现者所有的工件。

## 断言与实际结果

下面 A 组是 `specify.md` 四条行为条目的**逐条**断言，四条全在，未合并、未省略；B 组核实实现者上报的空行规则；C 组是孤儿判定；D 组是所有者划定的六项边界。

### A 组 — `specify.md` 四条验收判据

#### 断言 1 — `SPEC-COREREMOVAL-001`

- **判据所要求的**：跑该条给出的 `git grep` 命令（`templates/.themis/` 路径前缀，滤掉 `.themico/core` 与 `core/` 目录自身），**剩余的每一条命中**都必须能在 `step1/design.md`「结构决策」里找到一条对应的、明确保留或明确延后的决定；找不到对应决定的命中即断链。该条判据明确不接受"输出为空"这种读法。
- **实际跑出的**（命令 V2）：剩余命中 **2 条**——
  1. `templates/.themis/spec/README.md:5`
  2. `templates/.themis/workspace/context/catalog.md:33`
- **逐条对回 `design.md`「结构决策」**：
  - 第 1 条命中 → 「结构决策」**第 5 条**，对该文件给出的是明确的"不修改"决定，并把 `core/` 删除后这句话语义如何变化、包源与已装副本此后为何会不一致，都作为被记录而非被修复的状态写下了。**有对应决定。**
  - 第 2 条命中 → 「结构决策」**第 6 条**，对该行给出的是明确的"不定处理方案、按所有者 R1 结论延后单独审阅"，并预先写明本条判据会命中这一行、属已知例外、不据此判 failed，同时点明它也不等于"已处理"。**有对应决定。**
- **判定：满足。断链 0 条。**
- 附带核实（不改变判定，只排除该判据自己点名的两类同形陷阱）：命令 V3 显示该命令滤掉的 `.themico/core` 一类当前实际存在 1 条（`templates/.themis/skills/themico/SKILL.md:10`），指向 Themico 自己的路径，与被删目录无关；判据的路径前缀限定使 `docs/plan/themico-core/` 一类目录名不可能进入命中集。

#### 断言 2 — `SPEC-COREREMOVAL-002`

- **判据所要求的**：`grep -n '/.themis/core/' .gitignore` 输出为空。该条判据本身写明此处允许用"输出为空"判定，并给出了理由。
- **实际跑出的**（命令 V2、V4）：输出为空，命中数 `0`，`grep` 退出码 1。`.gitignore` 现为 10 行；四条忽略规则（`/.themis/spec/`、`/.themis/skills/`、`/.themis/README.md`、`/.themis/CLAUDE.themis.md`）与行 4–6 的说明性注释仍在，与「结构决策」第 4 条要求保留的内容一致。该文件相对落地前只少了一行，即被删的那条规则（命令 V4 的 diff）。
- **判定：满足。**

#### 断言 3 — `SPEC-COREREMOVAL-003`

- **判据所要求的**：`test -d` 输出 `GONE`；或 `find … -type f | wc -l` 输出 `0`。
- **实际跑出的**（命令 V2）：`GONE`，且文件数 `0`。两种写法都跑了，两者都满足。
- 另据 git 侧核实（命令 V4）：`3b2dde0..HEAD` 之间该路径下被删除的文件数为 **98**，与 `task/detail.md` T-D6 所指的规模一致；工作树无未提交残留（命令 V1 的 `git status --porcelain` 计数为 0）。
- **判定：满足。**

#### 断言 4 — `SPEC-COREREMOVAL-004`

- **判据所要求的**：跑该条给出的 `grep -n '与.*core.*的关系' AGENTS.md`（仓库根单文件），**剩余的每一条命中**都必须能在「结构决策」找到对应的明确保留或延后的决定。
- **实际跑出的**（命令 V2）：命中 **0 条**，`grep` 退出码 1。既然剩余命中为空集，"每一条命中都有对应决定"无条件成立。
- 为免把零命中读成"命令写错了"，另跑两项旁证（命令 V5）：仓库根 `AGENTS.md` 全文对 `core`（不分大小写）也是 **0 命中**；该文件第 13 行现文与「结构决策」第 7 条给出的目标形态**逐字相同**，`git diff` 显示该文件在整个区间内只改了这一行，且只少了那半句。
- **判定：满足。**

### B 组 — 实际删除区间与 `design.md` 所载区间的差额

- **要核的**：实现者上报它当场定了一条空行分隔符规则，使实际删除区间比 `design.md` 各多一行。本组要核的不是这条规则该不该定（控制器已裁定可接受），而是**多删的是否确实只有空行、有没有非空内容被连带删掉**。多删非空内容即超出批准范围，判 `failed`。
- **实际跑出的**：
  - 三份受删节的文件（`templates/.themis/CLAUDE.themis.md`、`templates/.themis/README.md`、`templates/.themis/AGENTS.md`）在 `3b2dde0..HEAD` 之间被删除 **103** 行，其中**非空 85 行、空行 18 行**（命令 V6）。
  - `design.md`「结构决策」逐节判定所载的全部区间，在落地前的旧版文件里合计含**非空 85 行、空行 11 行**（命令 V7，三文件分别为 43/7、39/2、3/2）。
  - 两组相减：**非空行差额为 0**，空行差额为 7。
  - 7 个多删的空行逐个定位并当场读出长度（命令 V8）：`CLAUDE.themis.md` 旧行 47、80、106；`README.md` 旧行 24、39、97；`templates/.themis/AGENTS.md` 旧行 46——七行长度全部为 `0`。数量与三份文件里被整节/整块删除的处数（3 + 3 + 1）相符。
  - 逐行清单也单独看过一遍（命令 V9 抽样粘贴）：被删的每一条非空行都落在「结构决策」点名的区间或点名的单行之内，没有一条落在区间之外。
- **另核六处"部分删除"（只删半句或一分句、不整节）的改后形态**：把旧行按 `design.md` 点名的片段机械剥离后，用 `grep -F -x` 对改后文件做整行精确匹配，六处全部命中 1 次（命令 V10）——`README.md` 行 25、46、93、109，`CLAUDE.themis.md` 行 3、96。即改后行与该条决策写下的目标形态逐字一致，没有多删也没有改写。
- **判定：满足。超出批准范围的非空内容删除：0 处。**

### C 组 — 孤儿判定（`rules.md` §8）

- **要核的**：§8 那条判据落到本 step 上，问的是两件事——有没有落了地却没人用的基础改动，以及基础任务点名的那个"用它的人"能不能在真实代码里找到。
- **实际跑出的**（命令 V11）：`task/basic.md` 中 `### T-B` 条目数为 **0**，且该文件全文不含任何 `### ` 三级标题；`task/detail.md` 有 6 条 `### T-D`，其"依赖的基础任务"一项逐条为"无"，共 6 处。**basic 段确为空**——这一条是本节点自己数出来的，不是引用该文件自述的结论。
- 相应地，`3b2dde0..HEAD` 之间没有任何"由 basic 任务落地、等待 detail 任务消费"的改动可指认：五处文件编辑与一次目录删除逐一对应 T-D1–T-D6，全部是 detail 任务自身的落地（命令 V4 的改动文件清单）。
- **判定：本 step 的 basic 段为空，没有 basic 改动，因而没有可判的孤儿；孤儿判定结论为「不存在孤儿」。** 此结论写在本节点工件，供 `acceptance.md` 的阻断核查引用。
- 本条在空段下退化为"确认空段确实为空"，判定动作本身仍然发生、并落在有代码证据的这一节点，未被跳过；这一形态是否合理已记入漂移清单本节点条目，不在本文件展开。

### D 组 — 所有者划定的六项边界

| # | 边界 | 实际结果 | 判定 |
| --- | --- | --- | --- |
| D1 | `templates/.themis/workspace/context/catalog.md:33` 原样未动 | `3b2dde0..HEAD` 对该文件 diff 为空；该文件最后一次提交为 `44207c2`，远早于本 replay；第 33 行现文仍是那条指向已删目录的相对路径引用（命令 V12） | 满足 |
| D2 | `templates/.themis/spec/README.md:5` 未改 | 同区间 diff 为空；该文件最后一次提交为 `2b229dd`；第 5 行现文与落地前逐字相同（命令 V12） | 满足 |
| D3 | `docs/` 下历史引用未被改写 | 整个 `3b2dde0..HEAD` 区间内 `docs/` 只有 2 个文件变动：`docs/plan/spec-replay/drift-log.md`（本 replay 自身的记录产出）与 `docs/superpowers/plans/2026-08-19-…replay.md`（`2daa931` 那次断言口径订正）。`docs/plan/35-core-prompt-flow/`、`docs/superpowers/specs/` 等归档记录零改动（命令 V13） | 满足 |
| D4 | 控制面 `.themis/spec/` 四份文件一字未改 | 该目录被 `.gitignore` 排除、不入库（`git ls-files .themis/spec` 计数 0），无法直接用 git 比对。改走内容层：四份文件与包源 `templates/.themis/spec/` 下同名文件逐一 `diff`，四次退出码全为 0（完全相同）；而包源这四份文件在 `3b2dde0..HEAD` 区间内 diff 为空。两步合起来即：控制面现内容 == 包源现内容 == 包源落地前内容。另：四份文件 mtime 均为 `8月 19 15:41`，早于 `c6417e9` 的提交时刻（命令 V14）。核验强度的边界见「说明」第 2 条 | 满足（在上述证据强度内） |
| D5 | 三处有意保留的漂移证据仍在（按内容认，不按行号认） | `Intent.md` 与 `state.md` 各有一行含「确认权归 R1 评审者」，检索命中 2 处；`QA.md` 的 Q4 答复行 `cat -A` 显示以 `排除$` 结尾、句末无标点。`Intent.md`、`QA.md` 在 `3b2dde0..HEAD` 区间 diff 为空；`state.md` 有改动，但其 diff 的全部增删行中不含追问闸门那一行（命令 V15） | 满足 |
| D6 | Go 侧无回归 | `go build ./...` 通过；`go test ./... -count=1 2>&1 \| grep -c '^ok'` 输出 **10**；非 `ok` 行只有一条 `[no test files]`，无 FAIL 行（命令 V16） | 满足 |

## 命令证据

以下命令全部由本节点在本次会话中实际运行，输出原样粘贴。凡标注行数或条数处，均为对应命令输出的真实行数。

**命令 V1**——本节点开始时的分支、HEAD、全树状态与近三次提交：

```bash
git rev-parse --abbrev-ref HEAD
git rev-parse --short HEAD
git status --porcelain | wc -l
git log --format='%h %ci %s' -3
```

```text
spec-flow-replay
2daa931
0
2daa931 2026-08-21 14:40:00 +0800 fix: 计划的残留断言排除实例工件路径
c6417e9 2026-08-21 14:36:49 +0800 replay: impl/detail 落地——删除 core 并处理五处引用
3b2dde0 2026-08-21 13:56:48 +0800 replay: 落 Ruling 18/20，补全 review.md 未声明删改，记控制器侧漂移
```

**命令 V2**——四条验收判据，按 `specify.md` 各条给出的命令原样运行：

```bash
git grep -n 'core/' -- templates/.themis/ | grep -v '\.themico/core' | grep -v '^templates/\.themis/core/'
grep -n '/.themis/core/' .gitignore
test -d templates/.themis/core && echo EXISTS || echo GONE
find templates/.themis/core -type f 2>/dev/null | wc -l
grep -n '与.*core.*的关系' AGENTS.md
```

```text
### AC-001（2 行）
templates/.themis/spec/README.md:5:本包与 `.themis/core/` 零引用：不引用其路径，也不复制其合同。
templates/.themis/workspace/context/catalog.md:33:未来每个 item index entry 必须符合 [Context Catalog 描述合同](../../core/protocols/context/references/catalog.md)，并保持 unique ID/path、existing references 与 acyclic dependency 约束。Catalog 只能索引受治理经验、背景、约束或核验线索，不拥有当前实现事实、Current Request、Plan、lifecycle state 或 current pointer authority。
### AC-002（0 行，退出码 1）
### AC-003
GONE
0
### AC-004（0 行，退出码 1）
```

**命令 V3**——AC-001 判据滤掉的那一类命中当前实际是什么（只为排除同形陷阱，不参与判定）：

```bash
git grep -n 'core/' -- templates/.themis/ | wc -l
git grep -n 'core/' -- templates/.themis/
```

```text
3
templates/.themis/skills/themico/SKILL.md:10:本 Skill 是 Themico 的唯一公共入口，只负责路由与解释。语义合同位于 `.themico/core/references/`，机器权威由 `themico` Go CLI 承担。
templates/.themis/spec/README.md:5:本包与 `.themis/core/` 零引用：不引用其路径，也不复制其合同。
templates/.themis/workspace/context/catalog.md:33:未来每个 item index entry 必须符合 [Context Catalog 描述合同](../../core/protocols/context/references/catalog.md)，并保持 unique ID/path、existing references 与 acyclic dependency 约束。Catalog 只能索引受治理经验、背景、约束或核验线索，不拥有当前实现事实、Current Request、Plan、lifecycle state 或 current pointer authority。
```

**命令 V4**——落地区间的改动面：`.gitignore` 的实际 diff、四份受编辑文件的现行数、被删除的 core 文件数：

```bash
git diff -U0 3b2dde0 HEAD -- .gitignore
wc -l templates/.themis/CLAUDE.themis.md templates/.themis/README.md templates/.themis/AGENTS.md .gitignore
git diff --name-only --diff-filter=D 3b2dde0 HEAD -- templates/.themis/core | wc -l
```

```text
diff --git a/.gitignore b/.gitignore
index f822bd4..48ddd05 100644
--- a/.gitignore
+++ b/.gitignore
@@ -8 +7,0 @@
-/.themis/core/
```

```text
   79 templates/.themis/CLAUDE.themis.md
   72 templates/.themis/README.md
   45 templates/.themis/AGENTS.md
   10 .gitignore
  206 total
98
```

**命令 V5**——AC-004 的两项旁证：仓库根 `AGENTS.md` 的 core 字样全量检索、第 13 行现文、该文件在区间内的完整 diff：

```bash
grep -n -i 'core' AGENTS.md
sed -n '13p' AGENTS.md
git diff -U0 3b2dde0 HEAD -- AGENTS.md
```

```text
（grep 输出为空，零行）
| `.themis` | [`templates/.themis/AGENTS.md`](templates/.themis/AGENTS.md) —— spec 控制面写作 |
```

```text
@@ -13 +13 @@
-| `.themis` | [`templates/.themis/AGENTS.md`](templates/.themis/AGENTS.md) —— spec 控制面写作、与 `core/` 的关系 |
+| `.themis` | [`templates/.themis/AGENTS.md`](templates/.themis/AGENTS.md) —— spec 控制面写作 |
```

**命令 V6**——三份受删节文件被删除的行里，空行与非空行各多少：

```bash
git diff 3b2dde0 HEAD -- templates/.themis/CLAUDE.themis.md templates/.themis/README.md templates/.themis/AGENTS.md \
  | grep '^-' | grep -v '^---' | sed 's/^-//' \
  | awk 'length($0)==0{b++} length($0)>0{n++} END{printf "空行=%d 非空行=%d\n", b, n}'
```

```text
空行=18 非空行=85
```

**命令 V7**——`design.md`「结构决策」所载的全部区间，在**落地前**的旧版文件里各含多少空行与非空行：

```bash
git show 3b2dde0:templates/.themis/CLAUDE.themis.md | awk 'NR==3||NR==7||(NR>=30&&NR<=46)||(NR>=61&&NR<=79)||NR==96||(NR>=99&&NR<=105)||(NR>=118&&NR<=121){if(length($0)==0)b++; else n++} END{printf "CLAUDE 区间内 空行=%d 非空行=%d\n", b, n}'
git show 3b2dde0:templates/.themis/README.md | awk '(NR>=9&&NR<=23)||NR==25||(NR>=29&&NR<=38)||(NR>=41&&NR<=46)||NR==93||NR==96||(NR>=98&&NR<=102)||NR==106||NR==109{if(length($0)==0)b++; else n++} END{printf "README 区间内 空行=%d 非空行=%d\n", b, n}'
git show 3b2dde0:templates/.themis/AGENTS.md | awk 'NR>=47&&NR<=51{if(length($0)==0)b++; else n++} END{printf "AGENTS 区间内 空行=%d 非空行=%d\n", b, n}'
```

```text
CLAUDE 区间内 空行=7 非空行=43
README 区间内 空行=2 非空行=39
AGENTS 区间内 空行=2 非空行=3
```

区间内非空合计 43 + 39 + 3 = **85**，与命令 V6 实际删除的非空行数 **85** 相等；空行合计 7 + 2 + 2 = **11**，与实际删除的 18 相差 **7**。

**命令 V8**——那 7 个多删的行，逐个在旧版文件里读出内容与长度：

```bash
git show 3b2dde0:templates/.themis/CLAUDE.themis.md | awk 'NR==47||NR==80||NR==106 {printf "%d:[%s] len=%d\n", NR, $0, length($0)}'
git show 3b2dde0:templates/.themis/README.md      | awk 'NR==24||NR==39||NR==97  {printf "%d:[%s] len=%d\n", NR, $0, length($0)}'
git show 3b2dde0:templates/.themis/AGENTS.md      | awk 'NR==46                  {printf "%d:[%s] len=%d\n", NR, $0, length($0)}'
```

```text
47:[] len=0
80:[] len=0
106:[] len=0
24:[] len=0
39:[] len=0
97:[] len=0
46:[] len=0
```

**命令 V9**——被删非空行是否越出区间。第一条给出 `templates/.themis/AGENTS.md` 的**被删逐行清单**（该文件被删 6 行，可全量粘贴）；另两份文件被删共 97 行，逐行清单在本节点通读过一遍、非空行无一落在区间外，此处不全量粘贴，改粘它们的**全部新增行**——新增行少且能直接看出改写落在哪几处：

```bash
git diff -U0 3b2dde0 HEAD -- templates/.themis/AGENTS.md | awk '/^@@/{split($2,a,","); ln=substr(a[1],2)+0; next} /^-/{if(!/^---/){printf "%3d |%s|\n", ln, substr($0,2,70); ln++}} /^ /{ln++}'
git diff -U0 3b2dde0 HEAD -- templates/.themis/CLAUDE.themis.md | grep '^+' | grep -v '^+++'
git diff -U0 3b2dde0 HEAD -- templates/.themis/README.md | grep '^+' | grep -v '^+++'
```

```text
 46 ||
 47 |## 与 `core/` 的关系|
 48 ||
 49 |`core/` 是 simple/full 双路径模型，与已批准契约 `docs/superpowers/specs/2026-08-07-|
 50 ||
 51 |在此之前：`spec/` 与 `skills/` 不得引用 `core/` 的任何路径（引用即断链），也不得复制其合同。查阅取经可以，产出必|
```

```text
+本托管指南定义安装后项目的控制边界。`.claude/skills/themis/SKILL.md` 是唯一公共项目 Skill。
+- Impl 与 Verification 使用不同 Invocation。
```

```text
+每条外部消息，包括 Questioning 回答、Review 反馈/批准、Acceptance 和 restart/unblock，都先经过 Intake interception。Review 始终位于项目实现前；Summary 只在 current Verification `passed` 且 Human Acceptance `accepted` 后生成。
+- [`spec/README.md`](spec/README.md) 索引 spec 流程的定义面（`flow.md`/`rules.md`/`template.md`/`README.md`），是独立于本控制架构的另一套流程合同：安装后运行时只读。
+- Verify 固定为 `themis-impl → independent themis-verification`。
+- Plan 35 只提供一个公共 Skill、一个 Global Rule、一个双作用域 policy、immutable templates、static verification 和 manual replay semantics。
```

两份文件的全部新增行合计 6 行，即六处"部分删除"改后的行；三份文件无其他新增。`templates/.themis/AGENTS.md` 零新增，其被删区间 46–51 中唯一越出 `design.md`（47–51）的第 46 行长度为 0（命令 V8）。

**命令 V10**——六处"部分删除"的机械等值检验：把旧行按 `design.md` 点名的片段剥离，再对改后文件做整行精确匹配（`grep -c -F -x`，输出 1 即改后文件中存在逐字相同的一整行）：

```bash
git show 3b2dde0:templates/.themis/README.md | sed -n '25p'  | sed 's|快速与完整路径只在统一 Plan 形成前不同；||' | grep -c -F -x -f - templates/.themis/README.md
git show 3b2dde0:templates/.themis/README.md | sed -n '46p'  | sed 's|，与上述 `core/` 组件零引用||'            | grep -c -F -x -f - templates/.themis/README.md
git show 3b2dde0:templates/.themis/README.md | sed -n '93p'  | sed 's|；两个 Invocation 共享一个 Plan Task Execution Identity 和失败预算。|。|' | grep -c -F -x -f - templates/.themis/README.md
git show 3b2dde0:templates/.themis/README.md | sed -n '109p' | sed 's|十六个内部 Capability、四个 Profile、||'   | grep -c -F -x -f - templates/.themis/README.md
git show 3b2dde0:templates/.themis/CLAUDE.themis.md | sed -n '96p' | sed 's|，但共享同一个 Plan Task Execution Identity 与 failure budget。|。|' | grep -c -F -x -f - templates/.themis/CLAUDE.themis.md
grep -c -F -x '本托管指南定义安装后项目的控制边界。`.claude/skills/themis/SKILL.md` 是唯一公共项目 Skill。' templates/.themis/CLAUDE.themis.md
```

```text
1
1
1
1
1
1
```

**命令 V11**——孤儿判定的代码层依据：basic 段是不是真的空、detail 任务声明了什么依赖：

```bash
grep -c '^### T-B' .themis/workspace/spec/core-removal/step1/task/basic.md
grep -c '^### ' .themis/workspace/spec/core-removal/step1/task/basic.md
grep -c '^### T-D' .themis/workspace/spec/core-removal/step1/task/detail.md
grep -c '依赖的基础任务\*\*：无' .themis/workspace/spec/core-removal/step1/task/detail.md
```

```text
0
0
6
6
```

**命令 V12**——D1、D2 两处"不动"对象的核验：

```bash
git diff --stat 3b2dde0 HEAD -- templates/.themis/workspace/context/catalog.md templates/.themis/spec/README.md
git log --oneline -1 -- templates/.themis/workspace/context/catalog.md
git log --oneline -1 -- templates/.themis/spec/README.md
sed -n '5p' templates/.themis/spec/README.md
```

```text
（git diff --stat 输出为空，零行）
44207c2 refactor: migrate Plan 35 contracts to Markdown
2b229dd feat: 建立 .themis/spec 控制面包与 README 索引
本包与 `.themis/core/` 零引用：不引用其路径，也不复制其合同。
```

**命令 V13**——D3：整个落地区间内 `docs/` 下到底改了哪些文件：

```bash
git diff --name-only 3b2dde0 HEAD -- docs/
```

```text
docs/plan/spec-replay/drift-log.md
docs/superpowers/plans/2026-08-19-spec-flow-end-to-end-replay.md
```

**命令 V14**——D4：控制面四份文件的核验（先确认不入库，再走内容层比对，最后看包源在区间内有无改动）：

```bash
git ls-files .themis/spec | wc -l
diff .themis/spec/rules.md    templates/.themis/spec/rules.md;    echo "rules.md diff-exit=$?"
diff .themis/spec/flow.md     templates/.themis/spec/flow.md;     echo "flow.md diff-exit=$?"
diff .themis/spec/template.md templates/.themis/spec/template.md; echo "template.md diff-exit=$?"
diff .themis/spec/README.md   templates/.themis/spec/README.md;   echo "README.md diff-exit=$?"
git diff --stat 3b2dde0 HEAD -- templates/.themis/spec/
ls -la .themis/spec/
```

```text
0
rules.md diff-exit=0
flow.md diff-exit=0
template.md diff-exit=0
README.md diff-exit=0
（git diff --stat 输出为空，零行）
total 32
drwxr-xr-x 1 lin10 197609     0  8月 19 15:41 .
drwxr-xr-x 1 lin10 197609     0  8月 19 15:41 ..
-rw-r--r-- 1 lin10 197609  9920  8月 19 15:41 flow.md
-rw-r--r-- 1 lin10 197609  1980  8月 19 15:41 README.md
-rw-r--r-- 1 lin10 197609 10536  8月 19 15:41 rules.md
-rw-r--r-- 1 lin10 197609  3869  8月 19 15:41 template.md
```

四次 `diff` 均无输出、退出码 0（内容完全相同）；包源四份文件在区间内零改动；四份文件 mtime 早于 `c6417e9` 的提交时刻。

**命令 V15**——D5：三处有意保留的漂移证据（按内容检索，不按行号）：

```bash
grep -n -o '确认权归 R1 评审者' .themis/workspace/spec/core-removal/Intent.md .themis/workspace/spec/core-removal/state.md
grep -n '（Q4）' .themis/workspace/spec/core-removal/QA.md
grep -n '（Q4）' .themis/workspace/spec/core-removal/QA.md | cat -A
git diff --stat 3b2dde0 HEAD -- .themis/workspace/spec/core-removal/Intent.md .themis/workspace/spec/core-removal/QA.md
git diff -U0 3b2dde0 HEAD -- .themis/workspace/spec/core-removal/state.md | grep -c '确认权归 R1 评审者'
```

```text
.themis/workspace/spec/core-removal/Intent.md:3:确认权归 R1 评审者
.themis/workspace/spec/core-removal/state.md:21:确认权归 R1 评审者
19:4.（Q4）确认排除
19:4.M-oM-<M-^HQ4M-oM-<M-^IM-gM-!M-.M-hM-.M-$M-fM-^NM-^RM-iM-^YM-$$
（git diff --stat 输出为空，零行）
0
```

第一条命令用 `-o` 只打印命中片段，因此两行分别就是 `Intent.md` 第 3 行与 `state.md` 第 21 行各含一处该措辞（检索路径限定为这两个文件，避免命中本文件自身）。第三条的 `cat -A` 输出以 `$`（行尾标记）紧接 `排除` 的字节收尾，其间无任何标点字节，即该答复行句末确无标点。第五条输出 `0`，即 `state.md` 的全部增删行中不含追问闸门那一行。

**命令 V16**——D6：Go 侧构建与测试：

```bash
go build ./... && echo "build ok"
go test ./... -count=1 2>&1 | grep -c '^ok'
go test ./... -count=1 2>&1 | grep -v '^ok' | head -10
```

```text
build ok
10
?   	github.com/zhanyan-Ader1y/Themis/cmd/themico	[no test files]
```

## 结论

**passed。**

- `specify.md` 四条行为条目逐条断言，四条全部满足：`SPEC-COREREMOVAL-001` 剩余命中 2 条、逐条在 `design.md`「结构决策」第 5、6 条找到对应的明确决定，断链 0 条；`SPEC-COREREMOVAL-002` 命中 0；`SPEC-COREREMOVAL-003` 输出 `GONE` 且文件数 0；`SPEC-COREREMOVAL-004` 命中 0。
- 实际删除区间与 `design.md` 所载区间的差额**只有 7 个空行**，非空行差额为 0——没有非空内容被多删，未越出批准范围。
- 所有者划定的六项边界逐项满足（D4 的证据强度限制见「说明」第 2 条）。
- **孤儿判定：不存在孤儿。** 本 step 的 basic 段为空（`### T-B` 条目数 0），没有已落地的 basic 改动，因而没有可判的孤儿。此结论供 `acceptance.md` 的阻断核查引用。

本结论依据的是本节点自己运行的命令与其真实输出，不依据 `impl/detail.md` 的自述、也不依据任何工件文件存在与否。

## 说明

**1. 判定过程中"想让它通过"的冲动出现在三处，逐处写明它是怎么被按住的。** 其一是 `SPEC-COREREMOVAL-001` 那两条剩余命中：`core/` 已经删干净了，两条命中留在那里看着就像没做完，"输出为空才算过"这个念头很自然——但判据本身写死了不接受这种读法，要求的是逐条对回决定；反过来，"既然判据不要求为空，那对回决定这一步走个形式即可"也是同一个冲动的另一面，本节点是逐条翻到「结构决策」第 5、6 条读完其处置文字才判的。其二是空行那条：实现者已经上报、控制器也已裁定可接受，最省事的做法是照抄"多删的只是空行"这句话；本节点没有照抄，而是把两侧的空行/非空行分别数出来做减法——**如果多删的里面混进了非空内容，这个减法会立刻显形，而照抄不会**。其三是 `SPEC-COREREMOVAL-004` 的零命中：零命中天然像是"命令写错了"，也天然像是"当然过了"，两种读法都省事；本节点另跑了不分大小写的全文检索与该文件的完整 diff 才落判。

**2. 作为独立验证者，有三样东西本节点核验不动，如实写出来。** 第一是**控制面四份文件的"一字未改"**：`.themis/spec/` 被 `.gitignore` 排除、不入库，git 给不出历史，本节点能拿到的最强证据是"现内容与入库的包源逐字相同，而包源在区间内零改动"加上 mtime 早于落地提交。这条链能排除"被改了且没改回去"，但排除不了"被改后又精确改回原样"这种情形——那需要落地前的独立哈希留档，本 replay 没有。第二是**对方那栏的真伪**：本节点只能读到 `impl/detail.md` 写下的执行身份，读不到那次会话本身；本栏能自证的只有本节点这一半（本次会话没有对被验证的文件做过任何写操作，落地提交在本次会话开始前就已存在）。第三是**实现者的推理过程**：例如"为什么末节取节前那个空行、有后继节取节后那个"，本节点只能核这条规则实际落下来的后果（多删的是不是空行），核不了它当时是怎么想的、有没有第二种更合适的规则。这三样都不是本次判定的阻碍，但把它们写出来，是为了让下一个读到 `passed` 的人知道这个 `passed` 覆盖到哪里为止。

**3. 身份独立这次是靠派发成立的，不是靠节点自觉。** basic 段两栏明写相同，detail 段两栏不同——两段之间唯一变化的是派发把两个节点拆给了两次会话。这意味着这道闸门当前的成立与否**完全取决于派发层怎么分任务**，节点自身既没有能力也没有义务去创造第二个身份。这一点已单独记入漂移清单本节点条目，此处不重复。

**4. 一处观察到、但不落在任何一条判据范围内的残留，留给验收节点知情。** `templates/.themis/workspace/README.md:5` 有一句以 Core 为主语、陈述 Core 与 Workspace 之间读写关系的话。它不进 `SPEC-COREREMOVAL-001` 的命中集（该判据检索的是带斜杠的 `core/` 字串，这句话里没有），也不在 `design.md`「架构与边界」清点的那 5 个 `templates/.themis/` 文件里，因此既没有被判定过、也没有出现在「取舍」的已知残留清单上。**这不构成任何一条判据的不满足**——四条判据的范围都是明确写死的，本节点不擅自扩大。但它确实是一处描述已删对象的话，与「取舍」明写"清单非穷尽"、以及 R3 结论把"删节与重写的边界"留待所有者另行表态这两件事同源。记在这里，由人工验收决定是否需要另开处理。

**5. 本节点未修改任何已批准工件，也未为了让判据通过而改动代码。** 本次会话对仓库的写入只有两处：本文件（新增）与漂移清单的本节点条目（追加）。`Intent.md`、`QA.md`、`specify.md`、`design.md`、两份任务文件、`task/review.md`、`impl/detail.md` 一字未动；控制面四份文件一字未动；三处有意保留的漂移证据一字未动。四条判据全部满足，因此本节点没有遇到"判据不满足但想放宽"的情形——若遇到，处置是判 `failed` 并停在 `flow.md`「verify/detail」节所指的失败去向，不在本文件里放宽读法。
