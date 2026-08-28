# QA.md — 2026-08-26-workspace-cleanup

> 追加写入，不覆盖、不回填。每轮记 问 / 答 / 来源三项。"答"栏在获得所有者答复前一律写"待所有者答复"，Agent 不代答（`flow.md`「追问」节，判据见 `rules.md` §2）。

## 第 1 轮

### 问 1（期望结果）处置形态取哪一种？

`templates/.themis/workspace/` 包内 39 个文件是删除，还是移入退役位置保留？

两者都有本项目的先例，且对"历史证据不得改写"的满足方式不同：

- **删除**——如 step1 处理 `templates/.themis/core/`（98 个文件整体删除，git 历史可回溯）。
- **移入退役位置保留**——如 Plan 35 的五个编号 Plan 移入 `docs/plan/retired/`（`git mv`，35 个文件 100% rename，内容逐字未变）。当时的理由是那些文件是验收审计与 replay 证据，是不得改写的历史证据。

本包的性质更接近哪一类，我判不了：它既不是证据记录（不像 `docs/plan/retired/`），也不像 `core/` 那样有明确的"已被新体系取代"关系——当前 spec 控制面根本没有与它对应的东西。

**答**：待所有者答复。

**来源**：代码#`docs/plan/retired/README.md`（Plan 35 退役形态）、代码#`.themis/workspace/spec/2026-08-19-core-removal/step1/impl/detail.md`（core/ 删除形态）。

---

### 问 2（期望结果）8 份有内容的文件里，有没有对当前 spec 流程仍有价值的？

31 个是空骨架，删去无争议。有内容的 8 份是：

| 文件 | 行数 | 内容 |
| --- | --- | --- |
| `references/directory-ownership.md` | 67 | Family roots、路径 ownership 与 fresh scaffold 边界 |
| `project.md` | 58 | 项目 identity、commands、Context 来源、Gates、adapters、Workspace paths |
| `references/artifact-and-state-model.md` | 38 | Paired revisions、structured/operational records、最小 state 与 currentness |
| `references/completion-retention.md` | 36 | Lifecycle completion observation、target freezing |
| `context/catalog.md` | 33 | Context 目录索引 |
| `references/recovery-and-cache.md` | 31 | Direct evidence、last proven gate、恢复 reread |
| `README.md` | 31 | 包职责与边界 |
| `references/intake-and-lifecycle-isolation.md` | 26 | 双 authority scope、assignment gate |

**为什么单问这条**：其中两份处理的问题当前 spec 控制面**没有对应物**——

- `project.md`：项目级配置（commands、Gates、adapters）。当前 `.themis/spec/` 四份文件不含任何项目配置形态；将来 hard 执行器要跑命令时，"从哪读项目的构建/测试命令"是个真问题。
- `artifact-and-state-model.md` 的 currentness 与 paired revision 思路，与当前 `state.md`「当前性」小节同源。

这是当前控制面的**缺失**，还是有意为之（例如决定不做项目配置、由 Agent 每次现问）？我不知道，也不该替你决定。

**答**：待所有者答复。

**来源**：代码#`templates/.themis/workspace/`（命令 6 逐文件行数）、代码#`templates/.themis/spec/`（四份文件无项目配置形态）。

---

### 问 3（范围）`context/` 子树怎么处理？

`context/` 有 8 个空的 `.overview.md`（各 15 行模板）加 `catalog.md`（33 行），是 Plan 35 的 Context 体系——按 architecture / decisions / domain / engineering / external / glossary / pitfalls 分类沉淀项目知识。

**它与 Themico 职责重叠**：Themico 是知识库引擎（有 Go 实现），承担知识记录的沉淀与治理。Themis 是否仍需要自己的 Context 概念？

- 若不需要 → `context/` 随包一并处置。
- 若需要 → 它不该跟着 Plan 35 一起退场，得单独考虑归属。

按已批准契约 `SPEC-THEMICO-001/002`，Themis 必须在无 Themico 时完整运行——**这似乎意味着 Themis 不能把知识沉淀完全交给 Themico**。但当前 spec 流程实际上确实没用到任何 Context，本次 replay 全程也没用。

**答**：待所有者答复。

**来源**：代码#`templates/.themis/workspace/context/`、代码#`docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md`（`SPEC-THEMICO-001`、`SPEC-THEMICO-002`）、代码#`cmd/themico`（Themico 有实现）。

---

### 问 4（核心链路 / 范围）两份入口文档的索引怎么改？

`templates/.themis/README.md:44–51`（8 行）与 `CLAUDE.themis.md:7、71–77`（8 处）以 Plan 35 结构索引本包。

包处置后这些索引必然要动，但改成什么取决于问 1：

- 若删除 → 索引整段删除，或替换为当前 spec 流程的实例结构说明（`spec/<spec-id>/step<N>/`）。
- 若保留 → 索引改为"已退役"标注。

另需注意 `CLAUDE.themis.md:7` 那句"`.themis/workspace/` 归项目所有，用于保存 Intake/lifecycle 记录……"——**`.themis/workspace/` 这个路径本身仍在用**（实例面 `spec/<spec-id>/` 就在其下），只是用途完全变了。这句话不能简单删掉，得改写。

**答**：待所有者答复。

**来源**：代码#`templates/.themis/README.md:44-51`、代码#`templates/.themis/CLAUDE.themis.md:7,71-77`、代码#`templates/.themis/spec/template.md:5,10`（实例面路径仍是 `.themis/workspace/spec/`）。

---

## 第 1 轮答复（2026-08-26）

所有者一次性答复四问，原话逐字：

> 1. 删除。2. 没有价值。3. 不需要，删除。4. 删除整个templates/.themis下的内容

**问 1 答**：删除。处置形态取整体删除，不移入退役位置。

**问 2 答**：没有价值。8 份有内容文件无一需要保留——含 `project.md` 的项目配置形态与 `artifact-and-state-model.md` 的 currentness 思路。**注**：Agent 在提问时指出"将来 hard 执行器要跑命令时，从哪读项目的构建/测试命令是个真问题"，所有者答复"没有价值"即已知悉该顾虑仍判定不保留；该问题若将来成立，由届时的需求另行解决，不靠保留本包兜底。

**问 3 答**：不需要，删除。Themis 不再需要自己的 Context 概念，`context/` 子树随包删除。

**问 4 答**：删除整个 `templates/.themis` 下的内容。

---

## 第 2 轮

### 问 5（范围）答复 4 超出问题 4 的范围，实际要删到哪一层？

问题 4 原本只问两份入口文档的索引怎么改，答复 4 说的是删除整个 `templates/.themis` 下的内容——后者范围大得多，且会删掉活的东西：`spec/` 是当前控制面的包源（安装副本 `.themis/spec/` 按 `.gitignore` 不入库，包源是唯一入库的那份），`skills/themis/SKILL.md` 是唯一公共入口且已指向当前 `.themis/spec/`。

Agent 按 `flow.md` 停下确认，未擅自按任一读法执行。

**答**（所有者从给定选项中选定）：

> 真的清空 templates/.themis/ 全部

即含 `spec/` 包源与 `skills/` 两份入口。

**来源**：用户确认#真的清空 templates/.themis/ 全部。

---

### 问 6（核心链路）清空后控制面四份文件与两份 SKILL.md 存哪里？

它们必须在 git 中有一份，否则 clone 下来没有控制面。当前 `.gitignore` 忽略 `/.themis/spec/`、`/.themis/skills/`、`/.themis/README.md`、`/.themis/CLAUDE.themis.md`，理由写在该文件注释里：安装副本入库即两份控制面，改一处忘另一处就是漂移。**删掉包源后，控制面将只剩一份被忽略的工作区副本——`git clean` 即失，clone 者拿不到。**

**答**（所有者从给定选项中选定）：

> .themis/ 改为入库(推荐)

即：删除 `.gitignore` 中对应的忽略规则，把现有 `.themis/spec/` 与 `.themis/skills/` 直接入库。从此只有一份控制面，"两份会漂移"的原理由随之消失，也不再需要安装动作。

**来源**：用户确认#.themis/ 改为入库；代码#`.gitignore`（现有四条忽略规则及其注释理由）。
