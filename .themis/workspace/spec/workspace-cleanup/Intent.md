# Intent.md — workspace-cleanup

> 状态：Intake 已产出来源引用初始条目。**追问尚未开始**，本文件的问题/期望结果/核心链路三节均含待确认项，未主张收敛（判据与判定者见 `rules.md` §2——确认权归 R1 评审者）。

## 问题

`templates/.themis/workspace/` 是 Plan 35 lifecycle-first 体系的安装包骨架，共 39 个文件。Plan 35 已于 2026-08-22 整体退役（`docs/plan/retired/README.md`），其实现载体 `templates/.themis/core/` 已删除，该 workspace 包随之失去它所服务的体系。

**它当前不被任何活的东西引用**：`templates/.themis/spec/` 四份控制面文件与 `templates/.themis/skills/` 两份 SKILL.md 对它零引用（来源见"来源引用"命令 3、4）。

**但它仍被两份入口文档以 Plan 35 结构索引**：`templates/.themis/README.md:44–51`（八行目录说明）与 `templates/.themis/CLAUDE.themis.md:7、71–77`（一句职责 + 七行路径表）。这两处指向的 `intakes/`、`changes/`、`state/`、`runs/`、`evidence/`、`outcomes/`、`knowledge/` 全是 lifecycle-first 布局，与当前 spec 流程的实例结构（`spec/<spec-id>/step<N>/`）完全不同。

**由此产生的实际危害**：读 `templates/.themis/` 的人会看到两套互不相干的结构并存，且入口文档只索引了已退役的那套。这不影响 spec 流程运行（零引用），但会让人分不清哪套是活的。

**一处必须辨明、极易搞错的事实**：当前 spec 流程**确实使用** `.themis/workspace/`——实例面 `.themis/workspace/spec/<spec-id>/` 是运行时唯一可写处（`templates/.themis/spec/README.md:3`、`template.md:5,10`）。但**该 `spec/` 子目录不在本包内**（命令 5 确认包内只有 cache/changes/context/evidence/intakes/knowledge/outcomes/policies/references/runs/state 十一个目录加两份 md），它由运行时创建。**待清理的是包内那 39 个文件，不是 `.themis/workspace/` 这个路径本身。**

## 期望结果

**待追问确认**，当前只写已知边界：

`templates/.themis/workspace/` 包内的 Plan 35 骨架不再存在，或以明确标记的退役形态存在；`templates/.themis/README.md` 与 `CLAUDE.themis.md` 不再以 Plan 35 结构索引它。清理后 `templates/.themis/` 只余当前活的内容：`spec/`（控制面包源）、`skills/`（两份公共入口）、三份顶层 md。

**未确定、须由追问闭合的三点**：

1. **处置形态**：整体删除（如 step1 处理 `core/` 那样），还是移入退役位置保留（如 Plan 35 移入 `docs/plan/retired/` 那样）。两者对"历史证据不得改写"的满足方式不同。
2. **8 份有内容文件的去留**：`references/` 五份（67/38/36/31/26 行）、`project.md`（58 行）、`context/catalog.md`（33 行）、`README.md`（31 行）。其中是否有内容对**当前** spec 流程仍有参考价值——例如 `project.md` 的项目配置形态、`directory-ownership.md` 的目录归属思路。当前 spec 控制面没有对应物，这是缺失还是有意为之，未知。
3. **`context/` 子树的去留**：8 个空 `.overview.md`（各 15 行）加 `catalog.md`，属 Plan 35 的 Context 体系。Themis 是否仍需要 Context 概念、还是已由 Themico 承担，未知——本 spec 不预判。

## 核心链路

从当前状态（包内 39 个文件，其中 31 个空骨架、8 个有内容；两份入口文档共 16 行索引指向它）到目标状态（包按确认的形态处置、入口文档不再索引已退役结构）。

**处理对象已清点完毕**（命令 1、2、6）：39 个文件 = 31 个空骨架（`.gitkeep` 21 个、`.overview.md` 9 个、`.abstract.md` 1 个）+ 8 个有内容文件。两份入口文档的 16 行索引位置已定位（命令 7）。

**不属于本需求核心链路**：`.themico/` 包（27 份 reference）——它有真实的 Go 实现支撑（`cmd/themico`、`internal/themico`，39 个 Go 源文件，命令 8），是活的合同，不在清理范围。

## 范围与非做

**范围**：`templates/.themis/workspace/` 包内 39 个文件；`templates/.themis/README.md` 与 `CLAUDE.themis.md` 中指向该包的索引。

**非做**：

- 不动 `templates/.themis/spec/`（当前控制面包源）与 `templates/.themis/skills/`（两份公共入口，`themis/SKILL.md` 已指向当前 `.themis/spec/`）。
- 不动 `templates/.themico/`（有 Go 实现支撑的活合同）。
- 不动运行时的 `.themis/workspace/spec/<spec-id>/`（实例面，本次 replay 自己的工件就在其中）。
- 不动 `docs/` 下任何历史记录——含 `docs/plan/retired/`，那是不得改写的历史证据。
- 不改 `.themis/spec/` 控制面四份文件本身。

## 约束

- 遵循 `.themis/spec/` 控制面四份文件的流程契约走完本 spec。
- 历史证据不得改写：若处置形态取"保留"，保留物内容一字不改；若取"删除"，`docs/` 下记录其曾存在的文档同样不改写。
- 不引入版本概念、不建 compatibility/migration 路径。

## step 分解

**待 R1 确认。** 追问闭合前不写分解——分解方式取决于上面三个未确定点，尤其是处置形态（删除与保留的 step 拆法不同）。

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
