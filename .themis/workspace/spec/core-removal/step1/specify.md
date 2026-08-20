# specify.md — core-removal / step1

> 本文件是抽象设计（specify）节点的实例工件。行为条目的 EARS 表达要求与 `[basic]` 标识含义见 `rules.md` §5；来源与分层事实源要求见 `rules.md` §1；本节点前置闸门与产出范围见 `flow.md` "抽象设计（specify）" 节。前置闸门核验记录见 `state.md`。

## 行为条目

### SPEC-COREREMOVAL-001

当 `templates/.themis/core/` 删除完成后，`templates/.themis/` 目录下不得存在任何未经 `design.md`「结构决策」显式记录为保留的 `core/` 路径引用。

- 验收判据：`git grep -n 'core/' -- templates/.themis/ | grep -v '\.themico/core' | grep -v '^templates/\.themis/core/'` 的每一条剩余命中，都能在 `step1/design.md`「结构决策」小节中找到对应的、明确保留（或明确延后）的决定；找不到对应决定的命中即为断链，判 failed。
- **不要把这条判据写成"输出为空"。** 除任务书已指出的 `templates/.themis/skills/themico/SKILL.md` 合法引用 `.themico/core/references/` 外，本次重新清点还发现另一类同形陷阱：`docs/plan/themico-core/` 这一目录名本身包含 `core` 子串（与 `.themis/core/` 无关，是 Themico 自己的实施计划目录），若判据只看"有没有 core 字样"会被这类不相关命中污染。裁定范围只限 `templates/.themis/` 路径前缀，且要求逐条能在 `design.md` 里找到明确决定——不满足即失败，这是为了让 `catalog.md:33`（延后审阅）与 `spec/README.md:5`（既有裁定保留分歧）这两条"故意不处理"的残留命中，与真正的断链（遗漏、未决定）区分开。

### SPEC-COREREMOVAL-002

当删除完成后，`.gitignore` 中不得存在指向已删除路径的 `/.themis/core/` 忽略规则。

- 验收判据：`grep -n '/.themis/core/' .gitignore` 输出为空。此处允许用"输出为空"判定——`.gitignore` 全文仅 10 行、目标字符串是精确的单一已知行，不存在类似 `.themico/core` 那种合法命中会被误伤的噪音源（已核实全文见 `design.md`「事实依据」）。

### SPEC-COREREMOVAL-003

当删除完成后，`templates/.themis/core/` 目录本身不得包含任何文件。

- 验收判据：`test -d templates/.themis/core && echo EXISTS || echo GONE` 输出 `GONE`；或 `find templates/.themis/core -type f 2>/dev/null | wc -l` 输出 `0`。

### SPEC-COREREMOVAL-004

当 `templates/.themis/AGENTS.md`「与 `core/` 的关系」一节删除完成后，仓库根 `AGENTS.md` 不得存在依赖该节存在性的索引描述残留，除非该残留经 `design.md`「结构决策」显式记录为保留的决定。

- 验收判据：`grep -n '与.*core.*的关系' AGENTS.md`（仓库根文件）的每一条剩余命中，都能在 `step1/design.md`「结构决策」小节中找到对应的、明确保留的决定；找不到对应决定的命中即为断链，判 failed。
- 判据范围精确限定在仓库根单个 `AGENTS.md` 文件、匹配一个具体短语（`templates/.themis/AGENTS.md` 被删除章节的标题文字），不复用 SPEC-COREREMOVAL-001 面向 `templates/.themis/` 的宽范围 `core/` 搜索——这样不会重新引入 `docs/`、`.themico/core`、`docs/plan/themico-core/` 等已在 001/`design.md`「事实依据」中核实过的噪音源，也不与 001 已覆盖的范围重复计入。本条独立成条而非并入 001，是因为它的观测对象（仓库根文件）、命中对象（章节标题短语而非路径字符串 `core/`）与 001 都不同；已核实当前仓库根 `AGENTS.md` 内该短语只出现这一处（`grep -n '与.*core.*的关系' AGENTS.md` 只命中第 13 行），判据无歧义。

## 来源覆盖

- 代码#`templates/.themis/core`（`find templates/.themis/core -type f | wc -l` = 98，命令与输出见 `design.md`「事实依据」）→ 支撑 SPEC-COREREMOVAL-003。
- 代码#`git grep -n 'core/' -- templates/.themis/`（排除 `.themico/core` 与 `core/` 自身后的完整命中列表，命令与输出见 `design.md`「事实依据」）→ 支撑 SPEC-COREREMOVAL-001。
- 代码#`.gitignore:8`（`/.themis/core/` 忽略规则，全文见 `design.md`「事实依据」）→ 支撑 SPEC-COREREMOVAL-002。
- 用户确认#（R1 结论「1. .gitignore列入本次范围」「2. 删除」，`intent-review.md` 结论小节）→ 确认 SPEC-COREREMOVAL-001、002 覆盖的对象在批准范围内，不新增独立判据（这些答复决定的是 `design.md` 里"怎么改"的具体做法，不改变"改完后不得存在引用"这条外部可观测判据本身）。
- 用户确认#`「appreved。 1. 接受。2. 宽度。3. 纳入」`（R2 结论逐字原话，见 `design-review.md` 结论；`appreved`/`宽度` 为笔误，原样记录）→ 第 3 点确认仓库根 `AGENTS.md:13` 纳入本次范围，支撑新增 SPEC-COREREMOVAL-004；第 2 点确认 `CLAUDE.themis.md`/`README.md` 的删节口径为宽读，属 `design.md` 结构决策范畴，不改变 001 已有判据文字。

**`[basic]` 边界判断**：本次未标注任何 `[basic]` 条目。判据位置见 `rules.md` §5，不复述其文字；本次删除类改动检查后只落在两类——要么改变已发布路径/文件的存在性（进 specify 作为行为条目），要么是 `core/` 目录内部文件之间的相互引用随整体删除一并消亡（从未对外发布过，不进 specify，只进 `design.md`/`task/basic.md`）。两类之外没有找到第三种中间形态，因此判断为无 `[basic]` 条目，而非遗漏未判。

**覆盖缺口已闭合**：上一程曾如实记录一处已知缺口——SPEC-COREREMOVAL-001 的判据范围锚定在 `templates/.themis/` 路径前缀，检测不到仓库根 `AGENTS.md:13` 这条依赖 `templates/.themis/AGENTS.md`「与 `core/` 的关系」一节存在性的索引描述。R2 结论第 3 点已确认将其纳入本次范围（来源见上），本轮据此新增 SPEC-COREREMOVAL-004 专门覆盖这一观测对象，缺口不再存在。选择"新增独立条目"而非"扩大 001 判据范围"，理由见 SPEC-COREREMOVAL-004 条目本身；判断依据是二者观测对象（仓库根单文件 vs `templates/.themis/` 路径树）与命中形态（章节标题短语 vs `core/` 路径字符串）不同，合并会让 001 的判据重新暴露在 `docs/`、`.themico/core` 等已排除的噪音源风险中。
