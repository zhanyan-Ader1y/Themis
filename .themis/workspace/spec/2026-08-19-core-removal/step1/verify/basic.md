# verify/basic.md — 2026-08-19-core-removal / step1

> 本文件是 verify/basic 节点的实例工件。本节点的前置闸门、产出、失效波及、失败去向，以及本节点有无人工参与见 `flow.md`「verify/basic」节；判定者、身份独立要求与 basic 段的断言范围见 `rules.md` §7；落地有没有替 `design.md` 定结构，这一项的判定归属见 `rules.md` §6；本节点断言的事实源要求见 `rules.md` §1；五个小节的固定划分、以及「执行身份」与「说明」两节各自的落点见 `template.md`（`verify/basic.md`、`verify/detail.md` 一行，与其下的说明段）。以上各处只指向位置，本文件不复述其文字。
>
> 下文按 `rules.md` §7 中 basic 段那三项判据的行文次序，称其为**第一项**、**第二项**、**第三项**，不重述三项的文字本身。这一称法沿用 `task/basic.md` 对 §4 两条判据已采用的同一做法。

## 执行身份

- **身份**：Claude Opus 5，以 SDD 派发的任务 5 执行者身份运行；工作树 `.claude/worktrees/spec-flow-replay`，分支 `spec-flow-replay`。
- **与 `impl/basic.md`「执行身份」比对的结果：相同**——同一个 agent、同一次会话既写了 `impl/basic.md`，也写了本文件。`rules.md` §7 把两份工件的执行身份小节定为该判定的落点，本次比对即在此处得出结论：**身份独立不成立**。
- **为什么没有第二个身份**：本次 replay 的任务分解把 impl/basic 与 verify/basic 派给同一个任务、由同一个 agent 承担；当前强制水平下也没有任何机制在派发时把两者分开。此处不虚构一个"验证者角色"来满足该条——伪造身份会让这道闸门在看起来通过的同时实际失效。形态与后果记入 `docs/plan/spec-replay/drift-log.md`「verify/basic」条目。
- **本文件的所有者**：验证角色。结论只写在这里，未写进 `impl/basic.md`。这一条与身份独立无关，即使身份重合也照常成立，故如实记为满足。

## 断言与实际结果

**前提**：本 step 的 basic 段为空，impl/basic 零落地调用（`impl/basic.md`「实际改动」与其「命令记录」）。因此本节点的三项判据面对的是一个**空的断言对象**。以下逐项给出实际结果，不做汇总性推断。

- **第一项——不可判。** 本段没有产生任何实现，不存在可被读取的落地物。§7 为该项指定了两种可接受的得出方式（见该节），本节点用了其中的命令那一种（V1、V2），但命令给出的是"零改动、`templates/.themis/core/` 仍为 98 个文件"这一**否定性事实**，而不是该项所要求的那种正面存在结论。把空集判成满足，等于用"没有东西可查"换取"查过了"，因此本项记为不可判，不记通过。

- **第二项——可跑，但对本段空转。** 本仓库确有可运行的构建入口：Go module 一个，`go build ./...` 退出码 0（命令 V3）。但它构建的是 `cmd/themico` 与 `internal/themico/**` 的 Go 代码（包清单即命令 V5 输出所枚举的 11 个包），而本 step 的交付物是 `templates/**` 下的 Markdown、`.gitignore` 一行忽略规则与仓库根 `AGENTS.md` 一行索引（清单见 `step1/task/detail.md` T-D1–T-D6），两者没有任何编译期或运行期关系；本段又是零改动，更不可能影响它。绿色结果属实，但它不是本段的证据——它在本次落地之前、之中、之后都会是绿色。故记为可跑而空转，不作为通过依据。

- **第三项——可跑，但对本段空转。** 仓库确有既有测试：16 个 `_test.go`（命令 V4），其中位于 `internal/themico/` 之外的有 0 个（命令 V4b），`go test ./...` 全部包通过、退出码 0（命令 V5）。与第二项同理：测试对象与本 step 的交付物不相交，本段零改动亦不可能造成回归。属实但空转，不作为通过依据。

- **`rules.md` §6 交给本节点验证角色的那一项——满足，且这一项是本节点唯一判得实的断言。** 该项问的是落地有没有替 `design.md` 把结构定了。本段零改动（命令 V1 输出为空），不存在任何可承载新结构的落地点，因此不可能引入。这一条不是空集豁免，而是由命令直接得出的否定性结论。

- **不涉及外部行为。** `step1/specify.md` 的四条行为条目在本节点全部未被触及，本文件不对其中任何一条给出结论，也不声称本 step 交付了任何外部可观测结果。删除动作尚未执行（命令 V2）。

## 命令证据

以下命令在本节点实际运行，输出原样粘贴，未事后重构。

**命令 V1**——本次落地范围内全部目标（五个待编辑文件，加上待整体删除的 `templates/.themis/core/` 目录）所在路径的工作树状态，三条路径合起来覆盖这六项：

```bash
git status --porcelain -- templates/ .gitignore AGENTS.md
```

输出为空（零行）。

**命令 V2**——`templates/.themis/core/` 当前受版本控制的文件数：

```bash
git ls-files templates/.themis/core/ | wc -l
```

```text
98
```

**命令 V3**——构建：

```bash
go build ./... ; echo "exit=$?"
```

```text
exit=0
```

（该命令无其他输出。`go version` 为 `go version go1.26.5 windows/amd64`。）

**命令 V4**——既有测试文件计数：

```bash
git ls-files '*_test.go' | wc -l
```

```text
16
```

**命令 V4b**——上述 16 个文件中不在 `internal/themico/` 之下的个数：

```bash
git ls-files '*_test.go' | grep -vc '^internal/themico/'
```

```text
0
```

**命令 V5**——既有测试执行（下方代码块共 12 行：前 11 行是 `go test` 的完整输出——1 个包无测试文件、10 个包通过，末行是同一条命令里 `echo` 打印的退出码）：

```bash
go test ./... ; echo "exit=$?"
```

```text
?   	github.com/zhanyan-Ader1y/Themis/cmd/themico	[no test files]
ok  	github.com/zhanyan-Ader1y/Themis/internal/themico/candidate	4.811s
ok  	github.com/zhanyan-Ader1y/Themis/internal/themico/canonical	0.854s
ok  	github.com/zhanyan-Ader1y/Themis/internal/themico/cli	0.923s
ok  	github.com/zhanyan-Ader1y/Themis/internal/themico/governance	4.968s
ok  	github.com/zhanyan-Ader1y/Themis/internal/themico/integration	13.969s
ok  	github.com/zhanyan-Ader1y/Themis/internal/themico/model	1.020s
ok  	github.com/zhanyan-Ader1y/Themis/internal/themico/query	8.679s
ok  	github.com/zhanyan-Ader1y/Themis/internal/themico/result	1.146s
ok  	github.com/zhanyan-Ader1y/Themis/internal/themico/store	5.896s
ok  	github.com/zhanyan-Ader1y/Themis/internal/themico/validate	3.838s
exit=0
```

（上方是首次运行的输出，故带各包耗时。自查时按同一命令重跑一次核对：包名与顺序完全一致，10 个 `ok` 包的耗时位置改显 `(cached)`，退出码仍为 0。耗时会随缓存变化，包清单与退出码不变。）

## 结论

**既不判 `passed`，也不判 `failed`。** 不判 `passed` 有三条理由，任一单独成立即足以阻止本文件被当作通过凭据：

1. **第一项没有断言对象**，且 §7 为该项指定的得出方式在空段上无法执行。判 `passed` 就是把"无可查"写成"已查过"。
2. **第二、三项虽然真跑了且为绿，但与本段无因果关系**——它们的对象是 `internal/themico/**`，与本 step 的交付物不相交。以它们作为本段的通过凭据，是把不相关的绿色借来充当证据。
3. **身份独立不成立**（见「执行身份」）。即便前两条都不存在，`rules.md` §7 拒绝条件的第一条也已命中，本结论不满足该节的成立前提。

**同时不判 `failed`。** 没有任何断言得出否定结果：零改动属实，构建与既有测试均为绿，`rules.md` §6 那一项判得实且满足。把"不可判"写成 `failed` 同样是伪造结论，且会按 `flow.md`「verify/basic」节的失败去向条款把流程停在 R3，而本节点并未发生该节点意义上的失败。

**本文件不构成任何下游节点的通过凭据。** 按 `flow.md`「impl/detail」节的前置闸门条款，本 step 的 impl/detail 在空段下不以本文件的结论为前置。也就是说：本结论悬空，不阻塞、也不解锁下一节点——这一点由控制面本身规定，不是本节点的裁量。**下一节点的放行不由本节点给出**：impl/detail 能否开始曾卡在「说明」第 2 点那处互斥读法上，本节点当时不代为落定、停下等待；**该处现已由控制器裁定（Ruling 18：以前置闸门的空段取值为准，detail 段可以开始），fail-closed 一处同样已裁（Ruling 20）**。因此本文件的结论不再悬在一个未决问题上——它照旧不构成通过凭据，但下一节点的依据已经有了，且那依据是裁定而非本节点的判断。裁定内容、代价与仍待修的控制面缺口见 `docs/plan/spec-replay/drift-log.md`「verify/basic」条目 (3)。

## 说明

**这一节记的是本节点最值得留下的东西：空段该怎么走完两个节点，控制面给了什么、没给什么。**

**控制面确实为空段说了话，而且说得比预想的多。** `flow.md`「impl/basic」节末给出了空段下本节点之后的走向；「impl/detail」节的前置闸门与失败去向两处都为空段单列了取值。这三处合起来是一条完整的空段路径。执行前的预期是"控制面对空段只字未提"，实际不是——预期错了，如实记下。

**但这条路径与控制面另外两处正面冲突，冲突指向同一件事：空段到底算不算一条分支。**

1. `flow.md`「详细设计 + 任务」节末与 `rules.md` §4 末段都断言空段不会让流程分岔。而「impl/detail」节的前置闸门与失败去向各带一个条件取值、「impl/basic」节末给出一条只在空段下成立的走向——这三处按 `templates/.themis/AGENTS.md`「失败去向必须镜像前置闸门的分支」一节的用语，正是**条件分支**的标准形态。控制面一边说它不是分支，一边按分支写。
2. `flow.md`「impl/detail」节末那句援引 `SPEC-IMPL-002` 的话是**无条件**的：它要求 basic 段先拿到结构性核验的通过，detail 段才允许起步，没有为空段留出口。而空段下这个通过永远拿不到——本文件正是拿不到它的现场。同一节的前置闸门给了空段例外，节末这句没给。两句在空段下互相矛盾。

**verify/basic 这个节点在空段下是否发生，控制面没有一致的答案。** 「impl/basic」节末的走向绕过了它；而「verify/basic」节本身的前置闸门只要求上游完成，没有为空段设任何豁免，按其字面本节点照常适用——同节的失效波及还把本节点的通过写成 impl/detail 的解锁条件，同样无条件，与「impl/detail」节前置闸门给出的空段取值正相抵。`template.md` 的实例目录树把本文件列为固定文件，也没有条件。这几处并存，读者按不同入口进来会得到不同结论。

**本次的处置：产出本文件，但不让它承担闸门。** 理由是——产出一份如实说明"这里没有可判之物"的工件，比留一个空位更能被下游读懂，也符合 `template.md` 对文件集合的固定要求；而「结论」明确不取 `passed`/`failed`，正是为了不让这份工件在控制面本就规定它不承担前置的地方凭空造出一道闸门。这是本节点的解释，不是控制面给的答案。

**判不动的地方，以及为什么没有绕过去。** 第一项确实判不动，本文件把它记成不可判，没有借"空集满足"把它写成通过——`task/review.md`「分类核查」在 R3 曾对几项空集条目用过"空集满足"的写法，那里成立是因为那几项问的是"有没有违规条目"，空集下答案确实是没有；本节点第一项问的是"东西在不在"，空集下答案不是"在"，两者不能类推。第二、三项判得动但空转，也照实写成空转，没有拿两个绿色退出码去凑一个 `passed`。

**`state.md` 的取值集合在这里第二次不够用。** 任务 4 已记下 impl/basic 那一档缺失；本节点是同一缺口的第二次显形，而且更硬——验证型节点在本次 replay 的约定里只有 `passed`/`failed` 两档，本节点的结论两档都不是。本轮不新增取值，改在证据栏写明含义，缺口保持敞开，见 `docs/plan/spec-replay/drift-log.md`「verify/basic」条目。

**fail-closed 是否适用，控制面同样没说。** `rules.md` §10 列举了触发停靠的几种情形，"结论不可判"不在其列，也没有条款说它算不算。本节点按"不在其列"处理，即不触发停靠；但这是读法，不是条款，因此当时把它列为待裁并写明：若认为不可判应当等同于失败，本 step 应停回 R3 那道已证闸门。

**已裁（Ruling 20）："不可判"不等同于失败，不触发 fail-closed。** 依据两条——该节列举的三类触发条件本节点都不成立；且空段下本文件的结论根本不是 impl/detail 的前置，它可判与否对那道闸门不承载作用。代价一并记：若反过来认为凡结论非 `passed` 即应停，空段流程同样走不完。**裁定不填补条款本身的空白**——该节仍然没有一条讲"结论不可判"算不算失败；下一个空段实例还会撞上同一处，还要再裁一次。本 step 由此不再残留自陈的阻断条件。
