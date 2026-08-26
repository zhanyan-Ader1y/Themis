# impl/detail.md — workspace-cleanup / step1

> 本文件是 impl/detail 节点的实例工件。本节点的前置闸门、产出、失效波及与失败去向见 `flow.md`「impl/detail」节；四个小节的固定划分见 `template.md`。以上各处只指向位置，本文件不复述其文字。
>
> **本文件不含验证结论。** 五条判据是否满足、以及三份迁移文件是否迁对，都属 verify/detail 的独立验证角色，本文件不预判、不代答。下文命令输出是落地过程的记录，不是对任何一条判据的裁断。

## 执行身份

- **身份**：Claude Opus 5（模型标识 `claude-opus-5`），本次 spec 流程执行者会话。工作树 `C:/Coding/Themis`，分支 `main`，动手前 HEAD 为 `7a068dc`。当前强制水平下没有独立的实现者角色账户，身份即这一次 agent 会话本身。
- **授权来源**：R3 approved（原话见 `step1/task/review.md`「结论」）。本节点得以开始的前置为 R3 approved——basic 段为空，`flow.md`「impl/detail」节前置闸门的空段取值即此，该取值自 2026-08-24 起由条款直接给出，无需裁定。
- **本节点不承担 verify/detail**：对方那一栏由对方填写，两栏一比即是 `rules.md` §7 的判定落点。本文件不预写、不猜测对方身份。**须先说明**：本次 soft 执行器下无派发层，verify/detail 很可能仍由本会话承担，届时身份独立不成立——该事实由 verify/detail 自行如实记录，本节点不代为断言。

## 实际改动

`task/detail.md` 的六条任务全部落地，另有两处必须标出的追加改动（见「与批准范围的偏差」）。

- **T-D1 — `.gitignore` 11 行 → 2 行（命令 D2）**：删除四条控制面忽略规则（`/.themis/spec/`、`/.themis/skills/`、`/.themis/README.md`、`/.themis/CLAUDE.themis.md`）及其上方三行说明理由的注释。注释与规则同去——其理由（"入库即两份控制面，改一处忘另一处就是漂移"）随两层模型取消而消失。剩余 `.idea/`、`*.iml` 两条与本 step 无关，未动。
- **T-D2 — 控制面四份入库（命令 D3、D4）**：`.themis/spec/` 的 `README.md`/`flow.md`/`rules.md`/`template.md` 由 UNTRACKED 转为 TRACKED。**内容一字未动**——四份的 git blob 哈希与落地前基线 `098fcd9` 的包源逐字相同（命令 D4）。
- **T-D3 — 三份文件迁入 `.themis/`（命令 D5、D6）**：`skills/themis/SKILL.md`、`skills/themico/SKILL.md`、`AGENTS.md` 三份用 `git mv` 迁移，git 全部记为 rename。**三份的 blob 哈希与基线逐字相同**（命令 D6）。
- **T-D4 — `templates/.themis/` 整体删除（命令 D7）**：迁走三份后剩余 45 个文件全部删除，目录本身不存在。`templates/` 下只余 `.themico`。
- **T-D5 — 五处活引用改写（命令 D8）**：仓库根 `AGENTS.md` 第 13 行改指 `.themis/AGENTS.md`；同文件「安装包与项目工作区的边界」一节四条改写（见下）；`README.md` 删除「安装包与模块合同」一条、公共 Skill 入口改指 `.themis/skills/themico/SKILL.md`；`CLAUDE.md` 末句由指向 `templates/.themis/**/README.md` 改为指向 `.themis/AGENTS.md`。
- **T-D6 — `templates/.themico/AGENTS.md` 一行路径改写**：该行中 `templates/.themis/skills/themico/` 改为 `.themis/skills/themico/`。**仅改此一行**，该文件其余部分与该包其余 26 份 reference 未动，符合 R2 裁定 A 的效力边界。

## 与批准范围的偏差

**落地范围有两处超出 R3 批准内容，逐处如实标出。**

### 偏差 1（重要）：改动了一个 Go 测试文件，该文件不在任何任务的对象清单内

**经过**：T-D1 至 T-D6 全部落地后，跑判据 005 得到 `ok: 9 / FAIL: 3`，**低于落地前基线的 `ok: 10 / FAIL: 0`**（命令 D9）。定位到 `internal/themico/integration/skill_contract_test.go:24` 断言 themico 的 SKILL.md 位于 `templates/.themis/skills/themico/`——该路径已被 T-D4 删除。

**为什么六处活引用的清点漏掉了它**：`Intent.md` 命令 7 与 `design.md` 命令 6 的清点范围都是 `--include='*.md'`，**只查 Markdown，未查 Go 源码**。而该测试用 `filepath.Join(repository, "templates", ".themis", ...)` 分段拼路径，即便扩大到 `*.go`，`grep 'templates/\.themis'` 也命中不了（命令 D11 证实：Go 源码里对该字面量的匹配数为 0）。**这是一处双重漏检**：范围漏了 Go，而模式对分段拼接无效。

**处置**：把该行路径改为 `.themis/skills/themico/SKILL.md`，重跑判据 005 恢复到 `ok: 10 / FAIL: 0`（命令 D10）。该测试的语义合同（"themico 的 skill 目录只放 SKILL.md"）未改变，改的只是它断言的位置。

**为什么选择就地修复而不是停下**：判据 005 的存在理由正是"本 step 删的全是 Markdown，若影响了 Go 说明有隐藏依赖——这正是要测出来的东西"（`specify.md` SPEC-WSCLEAN-005 的理由段）。它测出来了，而修复方式是把断言指向文件的新位置，不引入新结构、不改变该测试的语义。**但这仍是一处越界**——`task/detail.md` 六条任务的对象清单里没有任何 Go 文件，R3 批准的范围不含它。如实记录，由 verify 与人工验收判定是否接受。

### 偏差 2：`AGENTS.md`「安装包与项目工作区的边界」一节取"改写"而非"删除"

R3 裁定允许本节点在实现期定夺该节做法（`task/review.md`「结论」的显式豁免），并要求如实记录所选做法与理由。

**所选做法：改写，保留该节位置与四条结构。**

**理由**：该节讲的是"包源与项目工作区的边界"这一概念。本 step 取消的只是 `.themis` 那一半——**`templates/.themico/` 仍然是安装包源，仍然需要安装动作**（命令 D12 证实该目录存在且含 27 份 reference）。整节删除会一并抹掉仍然成立的 Themico 那一半，使 `templates/.themico/` 失去它在跨模块规范里的唯一说明。改写后四条分别为：`.themis` 不再有包源、`templates/.themico/` 仍是包源、Themico SKILL.md 的位置与安装职责、`templates/.claude/` 不应存在（末条未改，与本 step 无关）。

**一处如实说明**：改写后第三条把"该安装动作由 Themis Go CLI 承担"改成了"由 Themico Go CLI 承担"。这不是顺手改——原文所述的 Themis CLI 安装动作随两层模型取消而不再存在，而 Themico 的安装动作仍然存在且仍未实现，保留原文会指向一个已消失的机制。

## 命令记录

**命令 D1** — 动手前状态与 `.gitignore` 原文：

```
$ git rev-parse --short HEAD
7a068dc
$ cat -n .gitignore
     1  .idea/
     2  *.iml
     3
     4  # 安装到本仓库的 Themis 控制面副本——它只是 templates/.themis/ 的拷贝，
     5  # 入库即两份控制面，改一处忘另一处就是漂移。安装动作由 Go CLI 承担
     6  # （能力尚未实现，当前人工），副本不入库。
     7  /.themis/spec/
     8  /.themis/skills/
     9  /.themis/README.md
    10  /.themis/CLAUDE.themis.md
```

**命令 D2** — T-D1 后：

```
$ cat -n .gitignore
     1  .idea/
     2  *.iml
$ grep -cE '^/?\.themis/(spec|skills)/?$|^/?\.themis/(README|CLAUDE\.themis)\.md$' .gitignore
0
```

**命令 D3** — T-D2 后入库状态：

```
README TRACKED / flow TRACKED / rules TRACKED / template TRACKED
```

**命令 D4** — 控制面四份 blob 与基线 `098fcd9` 包源比对：

```
README   blob 一致 (97c97c4684e59b5e6ff84bb2f7d94bdb7be90e2c)
flow     blob 一致 (dc5326d5655e5668d52f8572273337f75a079830)
rules    blob 一致 (6030fad880894706712a96ac726e128bee3d14dc)
template blob 一致 (48cbaf728a7fc076b8091cf6a18ce22ea50320ff)
```

**比对方式须说明**：先用 `diff` 直接比对，四份全部报 DIFF；查后确认是工作区 CRLF 与 git 存储 LF 的行尾差异，**内容本身逐字相同**（`diff --strip-trailing-cr` 四份全部 SAME）。改用 blob 哈希比对——它比较的是 git 实际存储的规范化内容，不受工作区行尾影响。**`specify.md` 的 SPEC-WSCLEAN-003 判据写的是 `git show <基线> | diff -q -`，该写法在本仓库（Windows，autocrlf 生效）会误报 DIFF**；此事记入本节，由 verify/detail 决定采用何种比对方式。

**命令 D5** — T-D3 迁移结果（git 记为 rename）：

```
R  templates/.themis/AGENTS.md -> .themis/AGENTS.md
R  templates/.themis/skills/themico/SKILL.md -> .themis/skills/themico/SKILL.md
R  templates/.themis/skills/themis/SKILL.md -> .themis/skills/themis/SKILL.md
```

**命令 D6** — 三份迁移文件 blob 与基线比对：三份全部 `blob 一致`。

**命令 D7** — T-D4 后判据 001：

```
$ find templates/.themis -type f | wc -l   （删除前）
45
$ test -e templates/.themis && echo PRESENT || echo GONE
GONE
$ find templates/.themis -type f 2>/dev/null | wc -l
0
$ ls -a templates/
.  ..  .themico
```

**命令 D8** — 判据 004：

```
$ grep -rn 'templates/\.themis' --include='*.md' . --exclude-dir=.git --exclude-dir=.claude --exclude-dir=docs --exclude-dir=workspace | wc -l
0
```

**命令 D9** — 判据 005 首次运行（**失败**）：

```
$ go build ./... → BUILD_OK
$ go test ./... | grep -c '^ok'    → 9      （基线 10）
$ go test ./... | grep -c '^FAIL'  → 3      （基线 0）
$ go test ./... | grep -E '^(FAIL|---)'
--- FAIL: TestSkillTreeMatchesFirstUsableDeliveryContract (0.00s)
FAIL	github.com/zhanyan-Ader1y/Themis/internal/themico/integration
$ go test ./internal/themico/integration/ -run TestSkillTreeMatchesFirstUsableDeliveryContract
    skill_contract_test.go:28: skill directory must hold only SKILL.md: [] open
    C:\Coding\Themis\templates\.themis\skills\themico: The system cannot find the path specified.
```

**命令 D10** — 修复后重跑判据 005：

```
$ go build ./... → BUILD_OK
$ go test ./... | grep -c '^ok'    → 10
$ go test ./... | grep -c '^FAIL'  → 0
```

**命令 D11** — 证实原清点模式对该引用无效：

```
$ grep -rn 'templates/\.themis\|templates.\.themis' --include='*.go' .
（无输出）
```

无输出即证：即便当初把清点范围扩到 `*.go`，该模式也命中不了分段拼接的路径。

**命令 D12** — 改写理由的事实依据（`templates/.themico/` 仍存在）：

```
$ ls -a templates/
.  ..  .themico
```
