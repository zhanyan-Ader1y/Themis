# Intent.md — workspace-cleanup

> 状态：追问第 1、2 轮均已获所有者答复（`QA.md`），六个问题全部闭合，无悬而未答项。Agent 依 `rules.md` §2 提出收敛主张——**确认权归 R1 评审者**，R1 批准前本文件仍为待评审状态。
>
> **需求范围在追问中扩大**：初始 Intake 的范围是 `templates/.themis/workspace/` 一个包（39 个文件）；所有者答复 4 与问 5 将其扩大为**清空整个 `templates/.themis/`**（75 个文件中的 48 个，含控制面包源与两份公共入口），并由问 6 确定控制面改为 `.themis/` 直接入库。下文各节已按扩大后的范围重写，扩大经过与原话见 `QA.md` 第 1 轮答复与第 2 轮。

## 问题

`templates/.themis/workspace/` 是 Plan 35 lifecycle-first 体系的安装包骨架，共 39 个文件。Plan 35 已于 2026-08-22 整体退役（`docs/plan/retired/README.md`），其实现载体 `templates/.themis/core/` 已删除，该 workspace 包随之失去它所服务的体系。

**它当前不被任何活的东西引用**：`templates/.themis/spec/` 四份控制面文件与 `templates/.themis/skills/` 两份 SKILL.md 对它零引用（来源见"来源引用"命令 3、4）。

**但它仍被两份入口文档以 Plan 35 结构索引**：`templates/.themis/README.md:44–51`（八行目录说明）与 `templates/.themis/CLAUDE.themis.md:7、71–77`（一句职责 + 七行路径表）。这两处指向的 `intakes/`、`changes/`、`state/`、`runs/`、`evidence/`、`outcomes/`、`knowledge/` 全是 lifecycle-first 布局，与当前 spec 流程的实例结构（`spec/<spec-id>/step<N>/`）完全不同。

**由此产生的实际危害**：读 `templates/.themis/` 的人会看到两套互不相干的结构并存，且入口文档只索引了已退役的那套。这不影响 spec 流程运行（零引用），但会让人分不清哪套是活的。

**一处必须辨明、极易搞错的事实**：当前 spec 流程**确实使用** `.themis/workspace/`——实例面 `.themis/workspace/spec/<spec-id>/` 是运行时唯一可写处（`templates/.themis/spec/README.md:3`、`template.md:5,10`）。但**该 `spec/` 子目录不在包内**（命令 5 确认包内只有 cache/changes/context/evidence/intakes/knowledge/outcomes/policies/references/runs/state 十一个目录加两份 md），它由运行时创建。**删的是 `templates/` 下的包源，不是运行时的 `.themis/workspace/` 路径本身。**

**追问后暴露的第二层问题**（本节初稿未含，扩大范围后成立）：`templates/` 包源 + `.themis/` 安装副本这套两层模型本身也是 Plan 35 的产物。安装动作至今由人工承担（`.gitignore` 注释明写"安装动作由 Go CLI 承担，能力尚未实现，当前人工"），而两份必须逐字同步——本会话每次改控制面都要手工 `cp` 一遍并 `diff` 核对。**清空 `templates/.themis/` 同时取消这层模型，两份同步的负担与漂移风险一并消失。**

## 期望结果

**`templates/.themis/` 整个目录不再存在**（48 个文件全部删除，命令 9），**且控制面在此之后仍在 git 中可得**。

两半缺一不可——只删不迁会让控制面只剩一份被 `.gitignore` 忽略的工作区副本，`git clean` 即失、clone 者拿不到。因此本需求的达成状态是：

1. `templates/.themis/` 不存在：`workspace/` 39 份、`spec/` 4 份、`skills/` 2 份、顶层 3 份 md 全部删除。
2. `.gitignore` 中 `/.themis/spec/`、`/.themis/skills/`、`/.themis/README.md`、`/.themis/CLAUDE.themis.md` 四条忽略规则删除。
3. 现有 `.themis/spec/` 四份与 `.themis/skills/` 两份**入库**，成为唯一一份控制面。
4. 仓库中不再有任何位置以 Plan 35 结构索引已删内容。

**追问闭合的确定结论**（原话见 `QA.md`）：

- **处置形态取删除**，不移入退役位置（问 1 答"删除"）。
- **8 份有内容文件无一保留**（问 2 答"没有价值"）。含 `project.md` 的项目配置形态——Agent 已在提问时指出"将来 hard 执行器要跑命令时，从哪读项目的构建/测试命令是个真问题"，所有者知悉该顾虑后仍判不保留；该问题若将来成立，由届时的需求另行解决。
- **`context/` 子树删除**，Themis 不再需要自己的 Context 概念（问 3 答"不需要，删除"）。
- **范围扩至整个 `templates/.themis/`**（问 4 答 + 问 5 确认"真的清空 templates/.themis/ 全部"）。
- **控制面改为 `.themis/` 直接入库**（问 6 答）。"两份控制面会漂移"是原忽略规则的理由，改为单份后该理由消失，也不再需要安装动作。

**本需求消除的一个结构**：`templates/` 包源 + `.themis/` 安装副本这套两层模型，对 `.themis` 而言就此取消。`templates/.themico/` 不受影响，仍是包源（见"范围与非做"）。

## 核心链路

从当前状态（`templates/.themis/` 48 个文件；控制面以"包源入库 + 安装副本被忽略"两层存在）到目标状态（该目录不存在；控制面以 `.themis/` 单份入库存在）。

**核心链路只有一条,且有严格次序**：**先把控制面迁为入库，再删包源。** 次序颠倒会出现一个窗口——包源已删而 `.gitignore` 仍在忽略 `.themis/spec/`，此刻控制面在 git 中不存在。这不是风格问题，是本需求唯一的真实风险点。

处理对象已清点完毕（命令 1、2、6、9）：48 个文件 = `workspace/` 39（31 个空骨架 + 8 个有内容）+ `spec/` 4 + `skills/` 2 + 顶层 md 3。两份入口文档的 16 行索引位置已定位（命令 7），它们本身也在删除之列，故索引问题随之消失，不需单独改写。

**一处必须核实的等价性**：现有 `.themis/spec/` 安装副本与 `templates/.themis/spec/` 包源当前逐字相同（本会话此前多次 `diff -q` 确认）。迁移入库的是安装副本那一份，因此**入库前必须再次逐字比对两者**——若不同，则包源里有未同步到副本的内容，直接删包源会丢失它。

**不属于本需求核心链路**：`templates/.themico/`（27 份 reference）——有真实 Go 实现支撑（`cmd/themico`、`internal/themico`，39 个 Go 源文件，命令 8），是活的合同，且本需求只清 `.themis`，不动 `.themico` 的两层模型。

## 范围与非做

**范围**：

- `templates/.themis/` 全部 48 个文件（`workspace/` 39、`spec/` 4、`skills/` 2、顶层 md 3）。
- `.gitignore` 中针对 `.themis/` 的四条忽略规则。
- 现有 `.themis/spec/` 与 `.themis/skills/` 转为入库。
- 仓库中其他位置对已删内容的索引——以实际核实为准，不预设只有那两份入口文档。

**非做**：

- 不动 `templates/.themico/`（有 Go 实现支撑的活合同，其两层包源模型不在本需求内）。
- 不动运行时的 `.themis/workspace/spec/<spec-id>/`（实例面，本次 replay 自己的工件就在其中）。
- 不动 `docs/` 下任何历史记录——含 `docs/plan/retired/`，那是不得改写的历史证据。
- **不改控制面四份文件的内容**：本需求只改变它们在 git 中的存放位置与入库方式，`README.md`/`flow.md`/`rules.md`/`template.md` 正文一字不动。两份 SKILL.md 同理。

## 约束

- 遵循 `.themis/spec/` 控制面四份文件的流程契约走完本 spec——**本 spec 正在被它自己所迁移的那套控制面治理**，迁移期间该契约必须始终可用。
- 历史证据不得改写：`docs/` 下记录已删内容曾存在的文档一律不改。
- 不引入版本概念、不建 compatibility/migration 路径。
- 迁移必须保证控制面在 git 中**不出现空窗**：任一提交点上，控制面都应可从该提交恢复。

## step 分解

**待 R1 确认。** 本需求拆为**一个大步骤**，全部完成才算需求达成：

- **step1 — 控制面迁为入库，随后清空 `templates/.themis/`。** 承担本需求全部四项达成状态。**不拆成两个 step**：迁移与删除之间有严格次序依赖，且中间态（包源已删、忽略规则仍在）是本需求唯一的真实风险窗口；拆成两个 step 意味着该窗口要跨越一次完整验收，反而把风险放大。放在一个 step 内由 basic/detail 分段承担次序更稳妥，具体分段由该 step 的 R3 判定。

无第二个大步骤。`templates/.themico/` 的两层包源模型是否也要取消，属另一个需求，不在本分解内。

## 来源引用

全部为代码来源，命令与真实输出如下；本节不含任何未经命令核实的数字。

- **命令 1** `find templates/.themis/workspace -type f | wc -l` → `39`。来源类型：代码#`templates/.themis/workspace/`。
- **命令 2** `find templates/.themis/workspace -type f \( -name '.gitkeep' -o -name '.overview.md' -o -name '.abstract.md' \) | wc -l` → `31`。
- **命令 3** `grep -rn 'workspace' templates/.themis/spec/`（排除 `.themis/workspace/spec` 实例面路径）→ 无输出，即控制面对本包零引用。
- **命令 4** `grep -rn 'workspace' templates/.themis/skills/` → 仅一处命中 `themico/SKILL.md:42` 的 `.themico/workspace/`，**属另一个包**，不构成对本包的引用。
- **命令 5** `ls templates/.themis/workspace/` → `cache changes context evidence intakes knowledge outcomes policies project.md README.md references runs state`。**无 `spec/` 子目录**——证实实例面 `spec/<spec-id>/` 由运行时创建，不在包内。
- **命令 6** 逐文件 `wc -l` → 8 份有内容文件：`references/directory-ownership.md` 67、`project.md` 58、`references/artifact-and-state-model.md` 38、`references/completion-retention.md` 36、`context/catalog.md` 33、`references/recovery-and-cache.md` 31、`README.md` 31、`references/intake-and-lifecycle-isolation.md` 26。
- **命令 7** `grep -rn '\.themis/workspace\|workspace/' --include='*.md' templates/` → `CLAUDE.themis.md` 第 7、71–77 行（8 处），`README.md` 第 44–51 行（8 处）。
- **命令 8** `find . -type d -name 'themico*'` → `./cmd/themico`、`./internal/themico`；`find . -name '*.go' | wc -l` → `39`。证实 `.themico/` 有真实实现支撑。
- **Plan 35 退役事实**：`docs/plan/retired/README.md`（2026-08-22 退役，经项目所有者批准）。类型：代码#`docs/plan/retired/README.md`。
- **`README.md:31` 自述**："Plan 35 只提供 scaffold 与 Prompt-level ownership contracts"——该包自己写明它属于 Plan 35。类型：代码#`templates/.themis/workspace/README.md:31`。
- **需求来源**：所有者 2026-08-26 答复"想清理 workspace 包"（选项选定）。类型：用户确认#想清理 workspace 包。**本需求的目标语义以此为权威**；上述代码来源只提供事实，不构成对"要不要清理"的授权。

### 追问闭合后追加的来源（第 1、2 轮）

- **命令 9** `find templates/.themis -type f | wc -l` → `48`；分包 `workspace/` 39、`spec/` 4、`skills/` 2、顶层 md 3。类型：代码#`templates/.themis/`。
- **命令 10** `ls -a templates/` → `.themico`、`.themis` 两项。证实清空 `.themis` 后 `templates/` 仍有 `.themico`，目录本身不会空置。
- **处置形态、8 份文件去留、`context/` 去留**：用户确认#`1. 删除。2. 没有价值。3. 不需要，删除。4. 删除整个templates/.themis下的内容`（`QA.md` 第 1 轮答复，逐字）。
- **范围扩至整个 `templates/.themis/`**：用户确认#真的清空 templates/.themis/ 全部（`QA.md` 问 5）。
- **控制面改为 `.themis/` 入库**：用户确认#.themis/ 改为入库（`QA.md` 问 6）。
- **原忽略规则及其理由**：代码#`.gitignore`（四条规则与注释"安装到本仓库的 Themis 控制面副本……入库即两份控制面，改一处忘另一处就是漂移"）。

**本需求的目标语义以上述用户确认为权威**；代码来源只提供事实，不构成对"要不要删、删到哪"的授权。
