# impl/detail.md — 2026-08-19-core-removal / step1

> 本文件是 impl/detail 节点的实例工件。本节点的前置闸门、产出、失效波及与失败去向见 `flow.md`「impl/detail」节；本节点适用的判定条款见该节末尾所指的 `rules.md` 一处；四个小节的固定划分、以及「执行身份」小节作为身份独立判定落点这一用途见 `template.md`（`impl/basic.md`、`impl/detail.md` 一行及其下的说明段）。以上各处只指向位置，本文件不复述其文字。
>
> **本文件不含验证结论。** 本节点只落地并如实记录。`specify.md` 四条判据是否满足、以及孤儿判定，都属 verify/detail 的独立验证角色，本文件不预判、不代答。下文各处命令输出是落地过程的记录，不是对任何一条判据的裁断。

## 执行身份

- **身份**：Claude Opus 5（模型标识 `claude-opus-5`），以 SDD 派发的任务 6 前半程（impl/detail）执行者身份运行；工作树 `C:/Coding/Themis/.claude/worktrees/spec-flow-replay`，分支 `spec-flow-replay`，动手前 HEAD 为 `3b2dde0`、工作树干净（命令 D1）。当前强制水平下没有独立的实现者角色账户，身份即这一次 agent 会话本身。
- **本节点不承担 verify/detail**：本轮派发把两个节点拆给两个 agent，verify/detail 由另一次独立会话执行。本栏只记本次会话；对方那一栏由对方填写，两栏一比即是 `rules.md` §7 的判定落点。**本文件不预写、不猜测对方身份**——上一程两栏相同是派发模型造成的，本轮的分开同样来自派发，而不是本节点的自证。
- **授权来源**：R3 approved（`state.md`「各闸门」R3 行，原话见 `step1/task/review.md`「结论」）。本节点得以开始的直接依据是 `state.md`「当前节点」所载的控制器裁定 Ruling 18；**该依据的性质是裁定，不是控制面条款直接给出的结论**——`flow.md`「impl/detail」节末那句按字面读仍没有空段豁免，两读互斥并未因裁定而消解，控制面待修（经过见 `docs/plan/spec-replay/drift-log.md`「verify/basic」条目）。本节点未在 R3 授权之外取得任何新授权，也未自行解释那处矛盾。

## 实际改动

`task/detail.md` 的六个任务全部落地。改动落在 5 个文件加 1 个目录：5 处文件编辑合计 `+7 −105` 行（命令 D4），加 `templates/.themis/core/` 98 个文件整体删除（命令 D6）。逐条对回任务编号：

- **T-D1 — `templates/.themis/CLAUDE.themis.md`（130 → 79 行，命令 D2、D5）**，按 `design.md`「结构决策」第 1 条落地七处：（1）行 3 首段整行替换为该条给出的目标形态，删去提及三条 `.themis/core/**` 路径的两个从句；（2）行 7 那条列表项整行删除，`## 安装边界` 余 3 条（命令 D5）；（3）`## 产品流程` 整节（行 30–46）删除；（4）`## 控制架构` 整节（行 61–79）删除；（5）行 96 只删后半句、保留前半句，该列表项本身仍在，所以 `## Review、Verify、Acceptance 与 Summary` 仍为 7 条（命令 D5）；（6）`## Sticky Full Path、Failure 与 Recovery` 整节（行 99–105）删除；（7）`## 关键路径` 表格四行（行 118–121）删除，该表余 8 个数据行、节末那一行保留（命令 D5）。改后该文件 `##` 节共 7 个（命令 D5），即该条判定保留的那几节，被判整节删除的三节不再存在。
- **T-D2 — `templates/.themis/README.md`（112 → 72 行，命令 D2、D5）**，按第 2 条落地十处：（1）`## 产品主链` 代码块（行 9–23）删除，行 7 那句保留；（2）行 25 中那一分句删除，同行其余保留；（3）`## 控制架构` 代码块（行 29–38）删除；（4）行 41–45 五条列表项删除；（5）行 46 末尾半句删除、列表项主体保留，该节余 2 条列表项（命令 D5）；（6）行 93 后半句删除、前半句保留；（7）行 96 整条删除，`## Review、Verify 与门禁` 余 6 条（命令 D5）；（8）`## Failure 与 recovery` 整节（行 98–102）删除；（9）行 106 整条删除；（10）行 109 中那两项枚举删除，`## 不变量与当前能力边界` 余 6 条（命令 D5）。改后该文件 `##` 节共 7 个（命令 D5）。
- **T-D3 — `templates/.themis/AGENTS.md`（51 → 45 行，命令 D2、D5）**：末节「与 `core/` 的关系」（行 47–51）整节删除，做法按第 3 条、不重新讨论。改后该文件标题行余 5 个（命令 D5），末行是上一节最后一段。
- **T-D4 — `.gitignore`（11 → 10 行，命令 D2、D5）**：第 8 行删除。其余四条忽略规则与说明性注释未动——命令 D5 显示以 `/` 开头的规则行为 4 条，文件全文见该命令输出。
- **T-D5 — 仓库根 `AGENTS.md`（1 行改写，命令 D4 的 `+1 −1`）**：第 13 行按第 7 条给出的目标形态改写，删去末尾那半句失效描述，链接与列表项主体保留。
- **T-D6 — `templates/.themis/core/`**：`git rm -r` 整体删除。落地前该目录 98 个文件（命令 D2），落地后目录不存在、文件数 0、暂存的删除条目 98（命令 D6）。

**三处未触碰的对象，逐条对回其依据**（依据是本节点实际编辑过的文件清单，见命令 D8，不是事后回忆）：

- `templates/.themis/spec/README.md:5`——`design.md`「结构决策」第 5 条的"不动"决定，本节点未编辑该文件。
- `templates/.themis/workspace/context/catalog.md:33`——第 6 条记录的唯一开放决策点，所有者要求延后单独审阅，本节点未编辑该文件，也未为它定任何做法。
- `docs/` 下的历史引用——`Intent.md`「范围与非做」已排除，本节点未改写其中任何一条。本次唯一写入 `docs/` 的是漂移清单自身，属本 replay 的记录产出，不是对历史引用的改写。

**三处有意保留的漂移证据也未被顺手抹平**：`Intent.md` 与 `state.md` 追问闸门行的那半句、`QA.md` 那条答复行缺句末标点。`Intent.md` 与 `QA.md` 本节点未编辑；`state.md` 本节点编辑了，但只改「当前节点」「各闸门」「当前性」中与本节点相关的行，追问闸门那一行原样未动（命令 D8）。

## 与批准范围的偏差

**落地范围：无偏差。** 六个任务逐条落在 `design.md` 已定的做法上，未新增、未合并、未跳过；未修改 `Intent.md`、`QA.md`、`specify.md`、`design.md`、`task/basic.md` 与 `task/detail.md`；未做无关重构；`design.md` 判定为"不动"的第 5、6 两条对应的文件一字未改。**`task/review.md` 是例外，本节点确实改了它**——只在既有补记上增加披露，不属落地范围改动，边界与依据见下面第 3、4 条。

**需如实标出的四点。前两点是本节点的判断，后两点是顺带修复的记录缺陷，都不改变已批准的落地范围：**

1. **空行分隔符怎么处理是本节点当场定的，`design.md` 未写。** `design.md` 给出的整节行号区间只覆盖节内容本身，不含节与节之间的空行。若严格只删区间内的行，`CLAUDE.themis.md` 与 `README.md` 会各留下连续两个空行，`templates/.themis/AGENTS.md` 会以一个空行收尾。本节点统一采一条规则：整节删除时连同与该节**相邻的一个**空行分隔符一并删除——有后继节时取节后那一个，末节（`templates/.themis/AGENTS.md` 那一节）取节前那一个。这使实际删除的行数比 `design.md` 所载区间各多一行。作此判断的理由是它不改变任何保留内容、只维持段落间距；但它确实是 `design.md` 未定、由本节点当场定的，因此列出来，不藏进 diff。
2. **`design.md` 的行号区间与真实文件全部对得上，没有一处落不下去。** 动手前逐处比对了七个整节区间、四处半句或整条删除、两处表格/列表行区间，并把四条待替换或待删的字串各跑一次计数确认唯一命中（命令 D2）。上一轮任务 4 订正过的四处行号本轮实测与订正后的值一致。**没有出现需要临场改做法的情形**，因此本节点未引入任何 `design.md` 未定的结构。
3. **顺带修复三处结转的记录缺陷**（控制器在任务 5 复核中指出），均只改记录准确性，不动任何已批准结论、判定或落地范围：（a）`state.md`「当前性」`verify/basic.md` 那一行仍按 Ruling 20 之前的口径写着两处控制面均无一致答案，与同文件其余行的口径不齐，已补记其中一处已由该裁定给出取向、而条款本身的空白仍在；（b）`step1/impl/basic.md`「与批准范围的偏差」第 2 条（c）把对 `task/review.md` 的修改描述为只补记了第 8 条第二项那次修剪，而披露范围其后已扩到「分类核查」第 5 条与四段加一处词级改动，该描述已失准（准确版本在 `state.md`「当前性」`task/review.md` 一行），已就地更正；（c）`step1/task/review.md` 的那份补记对第 5 条只列了四处改动，重跑比对后核出实际不止四处、且其中一处的定性不准，已补披露，边界与依据见下一条。
4. **第 3 条（c）触碰的是已批准的 R3 评审工件 `task/review.md`，此处单列其边界与依据。** 处置口径与任务 5 那次补记相同：**只增加披露文字**，不恢复被删原文、不改动「结论」原话、不改动任何分类判定；理由同样是被删各段多用"本轮"指代任务 4 那一轮，原样放回会造出指代错误，且其中两条请求都已获所有者答复。依据是重跑 `git diff f04d721 c675c07` 取出该条的前后两版，按标点切段后逐段机械比对（命令 D7），而不是重读补记本身。核出的实情是：补记已列的四处之外，第 5 条同一次编辑另有四处未列的字词级改动，且补记第（4）项把一处整句改写描述成了"删去一处限定语"——原句与现句在主语、谓语与句尾都不同，不止少了一个限定成分。合计八处，清单已写进补记。**这是同一盲区在同一处的第三轮显形**：第一版补记只凭眼看、披露两段；第二版跑 diff 补到四段；本次改用按标点切段的机械比对，才把余下四处字词级改动一并找出。三次的共同点是**披露范围由人挑，而挑的人正是改动者**。同一次比对也覆盖了「分类核查」第 8 条第二项——补记对该项所列五处与逐段比对结果一致，未发现遗漏，如实记下（命令 D7）。

**本节点写下的全部文字已做过一次机械滑窗复检**（去掉标点与空白后取 12 字滑窗，对四份控制面文件全量比对，范围含本文件、漂移清单新增条目、以及三份被编辑工件的全部新增行）：唯一命中是 `rules.md` §6 那句结构决策枚举中的一段，它出现在两处——命令 D7 粘贴的 `diff` 输出里（逐字粘贴的命令输出，不能改），以及 `task/review.md` 第 5 条的既有原文里（本节点只改了该行末尾那句指向的条数，那段文字不是本节点所写）。本文件与漂移清单条目的行文本身无命中。

## 命令记录

以下命令在本节点实际运行，输出原样粘贴，未事后重构。

**命令 D1**——本节点开始前的分支、HEAD 与全树状态：

```bash
git status --short
git rev-parse --abbrev-ref HEAD
git log --oneline -3
```

```text
（git status --short 输出为空，零行）
spec-flow-replay
3b2dde0 replay: 落 Ruling 18/20，补全 review.md 未声明删改，记控制器侧漂移
342a4a4 replay: impl/basic 与 verify/basic（空段，两处判不动已停下）
c675c07 replay: 记录 R3 所有者结论 approved，实现节点解锁
```

**命令 D2**——落地前的基线：待删目录的文件数、Go 构建、Go 测试通过包数，以及三份模板文件与 `.gitignore` 的行数；随后逐条确认待替换/待删字串在各自文件中唯一命中，并确认三处整节删除相邻的分隔行确为空行：

```bash
find templates/.themis/core -type f | wc -l
go build ./... && echo "build ok"
go test ./... -count=1 2>&1 | grep -c '^ok'
```

```text
98
build ok
10
```

```bash
grep -c '，但共享同一个 Plan Task Execution Identity 与 failure budget。' templates/.themis/CLAUDE.themis.md
awk 'NR==47||NR==80||NR==106 {printf "%d:[%s]\n", NR, $0}' templates/.themis/CLAUDE.themis.md
```

```text
1
47:[]
80:[]
106:[]
```

```bash
grep -c '快速与完整路径只在统一 Plan 形成前不同；' templates/.themis/README.md
grep -c '，与上述 `core/` 组件零引用' templates/.themis/README.md
grep -c '；两个 Invocation 共享一个 Plan Task Execution Identity 和失败预算。' templates/.themis/README.md
grep -c '十六个内部 Capability、四个 Profile、' templates/.themis/README.md
awk 'NR==24||NR==39||NR==103 {printf "%d:[%s]\n", NR, $0}' templates/.themis/README.md
awk 'NR==46 {printf "%d:[%s]\n", NR, $0}' templates/.themis/AGENTS.md
```

```text
1
1
1
1
24:[]
39:[]
103:[]
46:[]
```

落地前三份模板文件与 `.gitignore` 的行数取自动手前对各文件的 `cat -n` 与 `wc -l` 读取——`CLAUDE.themis.md` 130 行、`README.md` 112 行、`templates/.themis/AGENTS.md` 51 行、`.gitignore` 11 行——与 `design.md`「事实依据」命令 4、8 所载一致。落地后的对应行数见命令 D5，两组相减即「实际改动」各条给出的 `130 → 79`、`112 → 72`、`51 → 45`、`11 → 10`。

**命令 D3**——六个任务的落地命令，原样粘贴（同一文件的多处改动合并在一次 `sed` 调用里，因此全部行号都指向该文件改动前的原始行，不受先后顺序影响）：

```bash
sed -i -e '3s|.*|本托管指南定义安装后项目的控制边界。`.claude/skills/themis/SKILL.md` 是唯一公共项目 Skill。|' -e '7d' -e '30,47d' -e '61,80d' -e '96s|，但共享同一个 Plan Task Execution Identity 与 failure budget。|。|' -e '99,106d' -e '118,121d' templates/.themis/CLAUDE.themis.md
sed -i -e '9,24d' -e '25s|快速与完整路径只在统一 Plan 形成前不同；||' -e '29,39d' -e '41,45d' -e '46s|，与上述 `core/` 组件零引用||' -e '93s|；两个 Invocation 共享一个 Plan Task Execution Identity 和失败预算。|。|' -e '96d' -e '98,103d' -e '106d' -e '109s|十六个内部 Capability、四个 Profile、||' templates/.themis/README.md
sed -i '46,51d' templates/.themis/AGENTS.md
sed -i '8d' .gitignore
sed -i '13s|spec 控制面写作、与 `core/` 的关系|spec 控制面写作|' AGENTS.md
git rm -r -q templates/.themis/core
```

各命令均以退出码 0 结束，无输出（`git rm` 加了 `-q`）。前三条命令里出现的比 `design.md` 区间多一行的删除范围（`30,47` / `61,80` / `99,106` / `9,24` / `29,39` / `98,103` / `46,51`），就是「与批准范围的偏差」第 1 条所述的空行分隔符处理。

**命令 D4**——五个受编辑文件的 diffstat：

```bash
git diff HEAD --stat -- templates/.themis/CLAUDE.themis.md templates/.themis/README.md templates/.themis/AGENTS.md .gitignore AGENTS.md
```

```text
warning: in the working copy of '.gitignore', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'AGENTS.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'templates/.themis/AGENTS.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'templates/.themis/CLAUDE.themis.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'templates/.themis/README.md', LF will be replaced by CRLF the next time Git touches it
 .gitignore                         |  1 -
 AGENTS.md                          |  2 +-
 templates/.themis/AGENTS.md        |  6 -----
 templates/.themis/CLAUDE.themis.md | 55 ++------------------------------------
 templates/.themis/README.md        | 48 +++------------------------------
 5 files changed, 7 insertions(+), 105 deletions(-)
```

那五行 `warning` 是 `core.autocrlf=true` 对任何被 Git 触及的文本文件都会给出的提示，不表示本次改动动过行尾。核对如下——受编辑文件与未被本次触碰的文件同为 LF，两者都没有 CR：

```bash
git config core.autocrlf
awk '/\r$/{n++} END{print FILENAME": "n+0}' templates/.themis/CLAUDE.themis.md
awk '/\r$/{n++} END{print FILENAME": "n+0}' CHANGES.md
```

```text
true
templates/.themis/CLAUDE.themis.md: 0
CHANGES.md: 0
```

**命令 D5**——落地后的结构计数，覆盖「实际改动」里每一个数字：

```bash
wc -l templates/.themis/CLAUDE.themis.md templates/.themis/README.md templates/.themis/AGENTS.md .gitignore
```

```text
   79 templates/.themis/CLAUDE.themis.md
   72 templates/.themis/README.md
   45 templates/.themis/AGENTS.md
   10 .gitignore
  206 total
```

```bash
grep -c '^## ' templates/.themis/CLAUDE.themis.md
awk 'NR>=6 && NR<=9 && /^- /' templates/.themis/CLAUDE.themis.md | wc -l
awk 'NR>=51 && NR<=58 && /^- /' templates/.themis/CLAUDE.themis.md | wc -l
awk 'NR>=70 && NR<=77 && /^\| /' templates/.themis/CLAUDE.themis.md | wc -l
```

```text
7
3
7
8
```

```bash
grep -c '^## ' templates/.themis/README.md
awk 'NR>=12 && NR<=15 && /^- /' templates/.themis/README.md | wc -l
awk 'NR>=57 && NR<=64 && /^- /' templates/.themis/README.md | wc -l
awk 'NR>=66 && NR<=72 && /^- /' templates/.themis/README.md | wc -l
```

```text
7
2
6
6
```

```bash
grep -c '^#' templates/.themis/AGENTS.md
grep -c '^/' .gitignore
cat .gitignore
```

```text
5
4
.idea/
*.iml

# 安装到本仓库的 Themis 控制面副本——它只是 templates/.themis/ 的拷贝，
# 入库即两份控制面，改一处忘另一处就是漂移。安装动作由 Go CLI 承担
# （能力尚未实现，当前人工），副本不入库。
/.themis/spec/
/.themis/skills/
/.themis/README.md
/.themis/CLAUDE.themis.md
```

**命令 D6**——删除动作的落点，以及落地后重跑构建与测试：

```bash
test -d templates/.themis/core && echo EXISTS || echo GONE
find templates/.themis/core -type f 2>/dev/null | wc -l
git diff --cached --name-only --diff-filter=D -- templates/.themis/core | wc -l
go build ./... && echo "build ok"
go test ./... -count=1 2>&1 | grep -c '^ok'
```

```text
GONE
0
98
build ok
10
```

构建与测试两行只是落地后的基线复跑记录，与命令 D2 的落地前基线同值；本文件不据此对任何一条判据下结论。

**命令 D7**——「与批准范围的偏差」第 4 条所依据的逐段机械比对。做法是取 `task/review.md` 第 5 条与第 8 条第二项在 `f04d721`（呈评审版本）与 `c675c07`（任务 4 编辑后）两版的原行，按句号、分号、逗号切段后逐段 `diff`：

```bash
git show f04d721:.themis/workspace/spec/2026-08-19-core-removal/step1/task/review.md | sed -n '25p' | sed 's/。/。@/g; s/；/；@/g; s/，/，@/g' | tr '@' '\n' | tee <scratch>/old5.txt | wc -l
git show c675c07:.themis/workspace/spec/2026-08-19-core-removal/step1/task/review.md | sed -n '25p' | sed 's/。/。@/g; s/；/；@/g; s/，/，@/g' | tr '@' '\n' | tee <scratch>/new5.txt | wc -l
diff -u <scratch>/old5.txt <scratch>/new5.txt
```

```text
18
20
```

```text
@@ -5,14 +5,16 @@
 `design.md`「结构决策」第 5、6 条不对应任何任务，
 因为二者是"不动"的决定，
 没有可落地的动作——这不是遗漏。
-**一处需要收窄措辞的自查**：`task/detail.md` T-D3 末句给了一条落地顺序建议（先于 T-D5 执行，
+**一处曾添加、经所有者裁定删除的内容（如实保留这一经过）**：呈评审时 `task/detail.md` T-D3 末句带了一条落地顺序建议（先于 T-D5 执行，
 以免中途出现指向已删章节的描述），
 `design.md` 未写过这条顺序。
-它不是字段、类型、签名、迁移方向或配置项，
-因此不落在 §6 所约束的结构决策范围内，
-但它确实是任务文件自行添加、`design.md` 未定的内容，
-不应被"未出现没写过的改法"一句笼统盖过。
-若 R3 认为任务文件不得携带任何 `design.md` 未写的内容，
-删去该句即可，
-不影响六个任务本身。
+本节点当时判断它不是字段、类型、签名、迁移方向或配置项，
+因而不落在 §6 所约束的结构决策范围内，
+但仍如实标出它是任务文件自行添加的内容，
+交 R3 裁定。
+所有者在 R3 批复中明确回应"删掉这句"（原话见「结论」），
+该句已从 `task/detail.md` 删除，
+六个任务本身不受影响。
+此处保留这一经过，
+不抹掉它发生过。
```

两侧都取自不可变提交（`f04d721` 呈评审版本、`c675c07` 任务 4 编辑后），因此这条命令在此后任何时候重跑都得到同一输出；任务 5 补记时加在该条末尾的那句指向不在两侧任何一版里，天然不参与本次计数。上面 `−` 侧 8 段、`+` 侧 10 段（`diff -u … | grep -c '^-[^-]'` 与 `grep -c '^+[^+]'` 两条命令的输出分别为 8 和 10），归并为「与批准范围的偏差」第 4 条所列的八处改动——段数与改动数不相等，因为有的改动只动一个词却整段重出，有的改动把一段拆成了两段。

第 8 条第二项同法比对：

```bash
git show f04d721:.themis/workspace/spec/2026-08-19-core-removal/step1/task/review.md | sed -n '30p' | sed 's/。/。@/g; s/；/；@/g; s/，/，@/g' | tr '@' '\n' | tee <scratch>/old8.txt | wc -l
git show c675c07:.themis/workspace/spec/2026-08-19-core-removal/step1/task/review.md | sed -n '30p' | sed 's/。/。@/g; s/；/；@/g; s/，/，@/g' | tr '@' '\n' | tee <scratch>/new8.txt | wc -l
diff -u <scratch>/old8.txt <scratch>/new8.txt
```

```text
15
19
```

```text
@@ -2,14 +2,18 @@
 所有者 R2 给的是口径（宽读），
 **没有点过任何一个章节名**（四份实例工件全文检索零命中，
 核验见 `design.md`「事实依据」命令 11）。
-因此两份文件里每一节的删或留——包括本轮新增的几处部分删除——都是本节点应用该口径做出的判定，
+因此两份文件里每一节的删或留都是本节点应用该口径做出的判定，
 无一经所有者逐节确认。
 上一版 `design.md` 曾把其中三处标为"R2 批复明确点名"，
 那是无据的权威归属，
-本轮已订正（见 `design.md`「架构与边界」权威归属一条）。
+已订正（见 `design.md`「架构与边界」权威归属一条）。
 **已知残留清单是非穷尽的**，
-其构成、边界与本轮改为删除的几处见 `design.md`「取舍」，
-此处不重复枚举。
-推广是否得当、残留边界是否可接受，
-请一并判定。
+其构成与边界见 `design.md`「取舍」。
+**R3 结论对本条的处置**：所有者未逐节裁定推广是否得当，
+而是就残留边界给出安排——删节与重写之间的边界由控制器提出定义、经所有者审阅后决定（原话见「结论」第 3 点）。
+在该边界确定之前，
+按 `design.md`「取舍」现载的非穷尽清单执行；
+边界一旦定下，
+可能要求回头处理现被列为"保留"的短语级残留。
+本项不阻塞本次批准。
```

`<scratch>` 指本次会话的临时目录（会话专用、不在仓库内，因此不入库）。第 8 条第二项的比对结果与补记所列五处一致，无遗漏。

**命令 D8**——本节点结束时的全树状态，用以核对本节点实际编辑过哪些文件（在本文件与其余工件全部写完后运行）：

```bash
git status --porcelain | grep -v '^D '
git status --porcelain | grep -c '^D '
```

```text
 M .gitignore
 M .themis/workspace/spec/2026-08-19-core-removal/state.md
 M .themis/workspace/spec/2026-08-19-core-removal/step1/impl/basic.md
 M .themis/workspace/spec/2026-08-19-core-removal/step1/task/review.md
 M AGENTS.md
 M docs/plan/spec-replay/drift-log.md
 M templates/.themis/AGENTS.md
 M templates/.themis/CLAUDE.themis.md
 M templates/.themis/README.md
?? .themis/workspace/spec/2026-08-19-core-removal/step1/impl/detail.md
```

```text
98
```

第一条输出共 10 行：5 行是「实际改动」逐条记的落地对象，1 行是本文件（新增），其余 4 行是本节点写入的记录——`state.md`（节点状态）、`docs/plan/spec-replay/drift-log.md`（漂移清单）、`step1/impl/basic.md` 与 `step1/task/review.md`（「与批准范围的偏差」第 3、4 条所述的记录修复）。清单中没有 `Intent.md`、`QA.md`、`specify.md`、`design.md`、两份任务文件，也没有 `templates/.themis/spec/README.md` 与 `templates/.themis/workspace/context/catalog.md`，与「实际改动」末两段的断言一致。第二条输出 98，即 T-D6 暂存的删除条目数。
