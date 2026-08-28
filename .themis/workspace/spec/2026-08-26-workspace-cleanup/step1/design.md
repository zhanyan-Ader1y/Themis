# design.md — 2026-08-26-workspace-cleanup / step1

> 本文件是详细设计节点的实例工件（按 `flow.md`「详细设计 + 任务」节归属；本次为 R2 投影需要 Overview 而提前产出，与 `2026-08-19-core-removal` step1 同型，该顺序张力已记在 `docs/plan/spec-replay/drift-log.md`「抽象设计」条目）。结构决策归属见 `rules.md` §6。以上各处只指向位置，本文件不复述其文字。

## 架构与边界

本 step 改动落在**四个位置**，全部已由命令核实：

| 位置 | 当前状态 | 目标状态 |
| --- | --- | --- |
| `templates/.themis/` | 48 个文件 | 不存在 |
| `.gitignore` | 4 条控制面忽略规则 | 0 条 |
| `.themis/spec/` | 4 份，未跟踪（`git ls-files` 全部 UNTRACKED） | 4 份，已入库 |
| 仓库中的活引用 | 6 处（`AGENTS.md` 2、`README.md` 2、`templates/.themico/AGENTS.md` 1、`CLAUDE.md` 1） | 0 处 |

**核实过的边界**：`templates/.themico/` 27 份 reference 不在改动范围（`Intent.md`「范围与非做」），但**它有一处引用指向本 step 要删的目录**——见「结构决策」第 3 条。

## 结构决策

### 1. `spec/` 四份：删包源，安装副本转入库

`.themis/spec/` 四份与包源逐字相同（`scope.md` 比对表，四份全部通过）。做法：删 `.gitignore` 忽略规则 → `git add .themis/spec/` → 删包源。

**次序不可颠倒**（`Intent.md`「核心链路」的唯一风险点）：先删包源、后改忽略规则，中间会出现控制面在 git 中不存在的窗口。本 step 把「改忽略规则 + 入库」放在 basic 段、「删包源」放在 detail 段，用段间次序保证这一点，具体分类由 R3 判定。

### 2. `skills/` 两份与顶层三份 md：无安装副本，须单独决定

`scope.md` 核实到：四条忽略规则中只有 `.themis/spec/` 真实存在，`.themis/skills/`、`.themis/README.md`、`.themis/CLAUDE.themis.md` **从未被安装过**。它们只在包源一侧，包源一删即无。

**本设计的决定**：

- **`skills/themis/SKILL.md`（36 行）——迁入 `.themis/skills/themis/`**。它是唯一公共入口，正文已指向当前 `.themis/spec/`（`Intent.md` 核实），删掉即无入口。
- **`skills/themico/SKILL.md`（42 行）——迁入 `.themis/skills/themico/`**。理由见第 3 条。
- **顶层 `README.md`（112 行）、`CLAUDE.themis.md`（130 行）——直接删除，不迁**。它们是 Plan 35 安装包的自述与路由表，含 16 行旧索引；R1 已批准的第 4 项要求消除这些索引，而其余内容描述的是已退役体系。**不改写、不迁移**——改写等于为一个已死的体系维护文档。
- **顶层 `AGENTS.md`（45 行）——迁入 `.themis/AGENTS.md`,不删**。**本条是本节点自查时推翻的一个初判,如实记录经过**:初稿写的是"直接删除",理由是"其约束已写在 `.themis/spec/` 控制面自身（`rules.md` §9）"。核实该理由时命令 9 给出相反结果——`.themis/spec/` 全文**不含**「只指向」「不复述」任何一处,`rules.md` §9 管的是工件内控制事实与人类语义的配比,与"引用别处内容时只写去哪找"不是同一件事。

  该文件三节各是一条独立的控制面写作约束,且**每一条都来自 replay 的实际教训**:「引用只指向，不复述」对应强制清单第 2 项（实发 7 次）；「判据必须有判定者」对应 R1/R3 的零反馈闸门缺口（第 7 项，实发 4 次）；「失败去向必须镜像前置闸门的分支」正是 Ruling 18 那处空段互斥读法的成因。**删掉即丢失这三条,且丢失的是本项目付过代价才得到的东西。**

  迁入位置取 `.themis/AGENTS.md`（与 `spec/` 平级）而非并入 `spec/` 四份之一:它约束的是**修改控制面的人**,不是流程本身;并入任何一份都会破坏那四份"各答一个问题"的分界。

**这五份的处置须经 R2 确认**——`specify.md`「来源覆盖」末段明写：若 design 决定保留其中任何一份，须新增对应行为条目并重走 R2。本设计决定保留两份 SKILL.md，**因此 R2 批准后须回抽象设计节点补 SPEC-WSCLEAN-006**（见「取舍」第 1 条）。

### 3. `templates/.themico/AGENTS.md:19` —— 本 step 发现的真实依赖

该行原文写明：themico 的 `SKILL.md` 随包放在 `templates/.themis/skills/themico/`，安装后到目标项目的 `.claude/skills/`，因为宿主只从那里发现 Skill。

**这是活的包对本 step 删除目标的依赖**，不是 Plan 35 残留：`templates/.themico/` 有真实 Go 实现支撑（39 个 Go 源文件），是 `Intent.md` 明确的非做项。

**本设计的决定**：`themico/SKILL.md` 迁入 `.themis/skills/themico/`，并**同步更新 `templates/.themico/AGENTS.md:19` 的路径**。这是对非做项文件的一处改动——**范围上属越界**，因此单独标出：它不是"顺手改"，而是第 4 项达成状态（消除指向已删内容的活引用）在该文件上的必然落点。若不改，该行将指向不存在的路径。

**须由 R2 确认此项越界是否被接受。** 替代方案是把它记为已知残留、留待后续需求处理——但那会让 SPEC-WSCLEAN-004 判据不通过（该行是 6 处活引用之一）。

### 4. 另外三处活引用：改写而非删除

- `AGENTS.md:13` — 模块规范索引表，指向 `templates/.themis/AGENTS.md`。该文件将被删，此行须改为指向 `.themis/spec/README.md`。
- `AGENTS.md:48-52`「安装包与项目工作区的边界」整节 — 描述的正是本 step 取消的两层模型（"`templates/` 下是安装包源"、"安装动作由 Themis Go CLI 承担，能力尚未实现"）。**整节改写或删除**，具体做法列入任务。
- `README.md:44`、`README.md:56` — 文档索引两条，分别指向将被删的 `templates/.themis/README.md` 与 `templates/.themis/skills/themico/SKILL.md`。前者删除该条，后者改指新位置。
- `CLAUDE.md:5` — 本会话此前已改过，当前指向 `.themis/spec/`，但含 `templates/.themis/**/README.md` 一句需复核。

## 取舍

1. **补 SPEC-WSCLEAN-006 而非在无判据下落地两份 SKILL.md。** 代价是要回一次抽象设计节点、重走 R2；收益是保留"每条落地都有可执行判据"这一性质。`2026-08-19-core-removal` 的 verify/detail 零漂移正来自此。**不接受"反正只是两个文件、判据可省"的读法。**

2. **顶层三份 md 中,两份删、一份迁。** `README.md` 与 `CLAUDE.themis.md` 直接删——代价是 `templates/` 下从此没有 `.themis` 自述文档,收益是不为已退役体系维护文档。`AGENTS.md` 迁入 `.themis/AGENTS.md`,理由见「结构决策」第 2 条。

   **这一条是本节点自查推翻初判的结果,值得单记。** 初稿判"三份全删",依据是一句我自己写下、未经核实的断言("其约束已写在 `rules.md` §9")。跑命令核实时结果相反:`.themis/spec/` 全文不含该约束。**若不跑那条命令,三条来自 replay 教训的写作约束会随本 step 一起消失,而删除理由在文本上看起来完全成立。** 这正是强制清单第 1 项（数值/存在性 claim 必须由命令产生,实发 8 次以上）所防的形态——本次它发生在"某处是否已有对应物"这类存在性断言上,与前八次同族。

3. **`templates/.themico/AGENTS.md` 的一处改动属越界，如实标出交 R2 裁定**，不自行放行、也不擅自缩小 SPEC-WSCLEAN-004 的判据范围来回避它。缩小判据等于替评审者改验收标准——这是 `2026-08-19-core-removal` 明确记过的一类漂移。

4. **不处理 `templates/.themico/` 的两层包源模型。** `Intent.md`「step 分解」明写属另一需求。本 step 只改它的一行路径引用，不动其模型。

## 事实依据

全部由本节点当场运行命令得出，输出原样如下。

**命令 1** — `templates/.themis/` 现状：

```
$ test -e templates/.themis && echo PRESENT || echo GONE
PRESENT
$ find templates/.themis -type f | wc -l
48
```

**命令 2** — `.gitignore` 四条规则：

```
$ grep -nE '^/?\.themis/(spec|skills)/?$|^/?\.themis/(README|CLAUDE\.themis)\.md$' .gitignore | wc -l
4
```

**命令 3** — 四条忽略路径的实际存在情况（本 step 的关键发现）：

```
.themis/spec: 存在          templates/.themis/spec: 存在
.themis/skills: 不存在      templates/.themis/skills: 存在
.themis/README.md: 不存在   templates/.themis/README.md: 存在
.themis/CLAUDE.themis.md: 不存在   templates/.themis/CLAUDE.themis.md: 存在
```

**命令 4** — 控制面入库状态：

```
$ for f in README flow rules template; do git ls-files --error-unmatch ".themis/spec/$f.md" ...; done
README UNTRACKED / flow UNTRACKED / rules UNTRACKED / template UNTRACKED
```

**命令 5** — 包源与安装副本逐字比对：`spec/` 四份全部 `相同`；`skills/` 两份报 `不同或缺失`（实为副本不存在，见命令 3）。

**命令 6** — 六处活引用：

```
./AGENTS.md:13          模块规范索引表
./AGENTS.md:52          「安装包与项目工作区的边界」节
./CLAUDE.md:5           已改过，需复核
./README.md:44          文档索引
./README.md:56          themico 公共 Skill 入口
./templates/.themico/AGENTS.md:19   活的包对删除目标的依赖
```

**命令 7** — Go 基线（SPEC-WSCLEAN-005 的比对基准）：

```
$ go build ./... → BUILD_OK
$ go test ./... | grep -c '^ok'   → 10
$ go test ./... | grep -c '^FAIL' → 0
```

**命令 8** — `specify.md` 五条判据的当前值（证实每条都能真正判失败，不是恒真）：

```
判据 1 → PRESENT / 48   （目标 GONE / 0）
判据 2 → 4              （目标 0）
判据 3 → 全部 UNTRACKED （目标全部 TRACKED + SAME）
判据 4 → 6              （目标 0）
判据 5 → BUILD_OK / 10 / 0（目标不劣于此）
```

**命令 9** — 「结构决策」第 2 条初判的核实（结果推翻初判）：

```
$ grep -n '^#\|^###' templates/.themis/AGENTS.md
1:# `.themis` 模块规范
7:## 控制面写作
11:### 引用只指向，不复述
32:### 判据必须有判定者
41:### 失败去向必须镜像前置闸门的分支

$ grep -n '只指向\|不复述' .themis/spec/rules.md .themis/spec/README.md
（无输出）
```

第二条命令无输出即证：`.themis/spec/` 控制面**不含**该约束的任何对应物。初稿据以判"直接删除"的理由不成立，已按此改为迁入。三节行数分别为 22、10、5。
