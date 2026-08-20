# task/detail.md — core-removal / step1

> 本文件是"详细设计 + 任务"节点的详细实现任务工件，与 `task/basic.md` 构成有序两组。分类判据、拒绝条件与判定者见 `rules.md` §4；任务文件与结构决策的分工见 `rules.md` §6；消费者关系的判定见 `rules.md` §8；本节点的前置闸门与产出见 `flow.md`"详细设计 + 任务"节；每条 `### T-D<n>` 的固定三项及后两项各自的落点见 `template.md`（`task/detail.md` 一行）。以上各处只指向位置，本文件不复述其文字。
>
> 本 step 的 basic 段为空（判定依据见 `task/basic.md`），因此下列六个任务的"依赖的基础任务"一项均为"无"。各任务的行为目标只重述 `design.md`「结构决策」已定的改动范围，供落地时逐项对照；结构本身的定夺权在 `design.md`，本文件不新增。`specify.md` 四条行为条目与本文件任务的对应关系逐条记在各任务第二项，整体核对结果见 `task/review.md`「分类核查」。

## 详细实现任务

### T-D1

- **行为目标**：按 `design.md`「结构决策」第 1 条落地 `templates/.themis/CLAUDE.themis.md` 的宽读删节，分布在首段与六个章节、共七处删除：行 3 首段中提及三条 `.themis/core/**` 路径的部分、`## 安装边界` 行 7 一条列表项、`## 产品流程`整节（行 30–46）、`## 控制架构`整节（行 61–79）、`## Review、Verify、Acceptance 与 Summary` 行 96 的后半句"，但共享同一个 Plan Task Execution Identity 与 failure budget"（保留前半句）、`## Sticky Full Path、Failure 与 Recovery`整节（行 99–105）、`## 关键路径`表格中的四行（行 118–121）。其余各节（`## Intake-first 入口`、`## 权威模型`、`## Scope 与 Artifact 隔离`、`## 安全降级`，以及 `## 关键路径` 的其余行、`## Review、Verify、Acceptance 与 Summary` 的其余六条）按该条判定保持不动；不补写替代内容。行号区间以 `design.md`「事实依据」命令 8 的核验结果为准。
- **对应 `specify.md` 条目**：`SPEC-COREREMOVAL-001`。该判据是对剩余命中的逐条要求，`CLAUDE.themis.md` 只是它覆盖的三个文件之一，本任务与 T-D2、T-D3 合计才使它可能通过。
- **依赖的基础任务**：无（本 step 的 basic 段为空）。

### T-D2

- **行为目标**：按 `design.md`「结构决策」第 2 条落地 `templates/.themis/README.md` 的宽读删节，分布在五个章节、共十处删除：`## 产品主链` 的代码块（行 9–23）与行 25 中"快速与完整路径只在统一 Plan 形成前不同"一分句（保留行 7 的开头一句）、`## 控制架构` 的代码块（行 29–38）、行 41–45 五条列表项、行 46 末尾"，与上述 `core/` 组件零引用"半句（保留行 40 与行 46 的列表项主体）、`## Review、Verify 与门禁` 行 93 的后半句"；两个 Invocation 共享一个 Plan Task Execution Identity 和失败预算"与行 96 整条、`## Failure 与 recovery`整节（行 98–102）、`## 不变量与当前能力边界` 行 106 整条与行 109 中"十六个内部 Capability、四个 Profile"两项枚举。其余各节（首段、`## Authority scopes`、`## 权威模型`、`## Artifact 与 Workspace`，以及上述各节未点名的列表项）按该条判定保持不动；不补写替代内容。行号区间与列表条数以 `design.md`「事实依据」命令 8、9 的核验结果为准。
- **对应 `specify.md` 条目**：`SPEC-COREREMOVAL-001`（同一判据落在 `README.md` 这一个文件）。
- **依赖的基础任务**：无。

### T-D3

- **行为目标**：按 `design.md`「结构决策」第 3 条，整节删除 `templates/.themis/AGENTS.md`「与 `core/` 的关系」一节（行 47–51，该文件末节，核验见「事实依据」命令 8）。做法已由所有者 R1 结论定死，落地时不重新讨论。
- **对应 `specify.md` 条目**：`SPEC-COREREMOVAL-001`（同一判据落在 `templates/.themis/AGENTS.md` 这一个文件）。
- **依赖的基础任务**：无。本任务与 T-D5 之间存在内容衔接——本任务删掉该节后，仓库根 `AGENTS.md` 第 13 行那半句索引描述才失去指代对象——但两者是同层并列改动，各自单独落地即可核验，衔接关系不构成 `rules.md` §4 意义上的基础任务与消费者关系（判定过程见 `task/basic.md`）。落地顺序上建议本任务先于 T-D5，以免中途出现指向已删章节的描述。

### T-D4

- **行为目标**：按 `design.md`「结构决策」第 4 条，删除 `.gitignore` 第 8 行 `/.themis/core/`；其余四条忽略规则与行 4–6 的说明性注释保留不动（全文 11 行，见「事实依据」命令 4）。
- **对应 `specify.md` 条目**：`SPEC-COREREMOVAL-002`。
- **依赖的基础任务**：无。

### T-D5

- **行为目标**：按 `design.md`「结构决策」第 7 条，改写仓库根 `AGENTS.md` 第 13 行——删除末尾"、与 `core/` 的关系"半句，保留列表项主体与链接，改后行文见该条给出的目标形态；不补写替代内容。
- **对应 `specify.md` 条目**：`SPEC-COREREMOVAL-004`。
- **依赖的基础任务**：无（与 T-D3 的关系见 T-D3 该项）。

### T-D6

- **行为目标**：按 `design.md`「架构与边界」锚定的删除动作，整体删除 `templates/.themis/core/` 目录（当前 98 个文件，见「事实依据」命令 1）。本任务是本次需求的核心可观测结果；它与本 step 其余任务一样，落地时机受 `flow.md` 节点序列约束——实现节点各自的前置闸门见该文件对应各节，本节点只做分解，不解锁落地。
- **对应 `specify.md` 条目**：`SPEC-COREREMOVAL-003`。
- **依赖的基础任务**：无。
