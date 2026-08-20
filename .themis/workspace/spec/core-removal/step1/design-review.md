# design-review.md — core-removal / step1

> 本文件是 R2 抽象设计评审的实例工件。投影的低负担要求与 Overview 要求见 `rules.md` §3；本节点前置闸门与产出见 `flow.md` "R2 抽象设计评审" 节。以下"投影"是 Agent 呈现的抽象设计层增量，不构成评审结论（判定者见 `rules.md` §3）。

## 投影

### Overview：删除前后 `.themis/` 形态变化

```text
templates/.themis/                                   templates/.themis/
├── core/                     98 个文件      ──删除──▶  ├── core/                     [不存在]
├── skills/themico/SKILL.md                            ├── skills/themico/SKILL.md
│   （引用 .themico/core/，另一模块，不在范围内）        │   （不变）
├── spec/README.md                                     ├── spec/README.md
│   （"与 .themis/core/ 零引用"声明）           ──不改──▶ │   （原样保留，与已删除的 core 之间
│                                                        │    产生已知分歧，见 design.md 结构决策5）
├── workspace/context/catalog.md:33                     ├── workspace/context/catalog.md:33
│   （相对路径引用 core/protocols/...）         ──不改──▶ │   （原样保留——开放决策点，延后审阅）
├── CLAUDE.themis.md（3 处含 core 路径的行/行段）──删节──▶ ├── CLAUDE.themis.md（对应行段已删除，
│                                                        │    不补写替代内容）
├── README.md（4 条索引项 + 1 处表述半句）      ──删节──▶ ├── README.md（对应条目/半句已删除）
└── AGENTS.md「与 core/ 的关系」一节             ──删除──▶  └── AGENTS.md（该节整节消失）

.gitignore:8 `/.themis/core/`                  ──删除──▶  .gitignore（该行删除，其余 4 条安装副本
                                                            忽略规则保留不动）

仓库根 AGENTS.md:13（索引描述提及"与 core/ 的关系"）────── 不变（新发现，落在批准范围外，
                                                            design 节点不处理，见下）
```

### 抽象设计层增量

- `specify.md` 新增三条外部可观测行为判据（`SPEC-COREREMOVAL-001/002/003`），分别对应"`templates/.themis/` 下不留非明确保留的 `core/` 路径引用"“`.gitignore` 不留失效忽略规则”“`core/` 目录本身不留文件”。判据范围与豁免规则见 `specify.md`，不在此重复其判据文字。
- `design.md` 对 `Intent.md` 已批准范围内的六处引用点，逐条定死了处理做法（`CLAUDE.themis.md`/`README.md` 删节、`AGENTS.md` 整节删除、`.gitignore` 删行、`spec/README.md` 不改并记录分歧）；`catalog.md:33` 按 R1 结论明确保持不定、延后审阅，未被强行归类。
- 新发现一处范围外活跃依赖（仓库根 `AGENTS.md:13`），design 节点判断处理它需要新的 Intake/QA，本 step 不处理，只记录。
- `[basic]` 边界判断：本次删除类改动未识别出符合"契约存在但非行为"定义的条目，`specify.md` 不含 `[basic]` 标识，判断依据见 `specify.md`「来源覆盖」。

## 未解决反馈

以下三项是本轮评审呈现时提出的确认请求，所有者已在批复中逐条表态（原话见"结论"）：

1. **`design.md` 提前于 `flow.md` 字面所属节点（详细设计 + 任务）在本 step 产出，是否可接受这一顺序偏离**——**已获表态，关闭**：所有者确认接受。已产出的 `design.md` 作为草稿持有，R2 批准后正式成为「详细设计 + 任务」节点的产出；`design.md` 本身的后续修改不在本节点范围内，归下一任务处理。
2. **`CLAUDE.themis.md`/`README.md`"涉及 core 的内容删节"的范围口径**——**已获表态，关闭**：所有者确认采用宽读——删除依赖 core 架构才有意义的整节内容，不局限于字面出现 `core/` 路径的行。具体改法属结构决策，落在下一任务的 `design.md` 修订中，本节点不代做。
3. **仓库根 `AGENTS.md:13` 是否纳入处理范围**——**已获表态，关闭**：所有者确认纳入，成为第七处引用点。`specify.md` 已据此新增 `SPEC-COREREMOVAL-004` 闭合原有的判据覆盖缺口；`AGENTS.md:13` 具体的处理做法同样属结构决策，留给下一任务的 `design.md`。

**`catalog.md:33` 的处理方案——仍未解决**，不因本次 R2 通过而视为已决。所有者本轮批复未涉及这一条（R2 批复三点分别对应上述①②③，均与 `catalog.md` 无关）；它仍按 R1 结论延后，等待所有者在完成前述各项后单独提出方案审阅。

## 结论

**approved**

所有者原话（逐字，未转述、未润色、未改错字）：

> appreved。 1. 接受。2. 宽度。3. 纳入

理解旁注（不代替原话，仅供阅读辅助）："appreved" 为 "approved" 笔误；"宽度" 为"宽读"笔误。三点分别对应本节"未解决反馈"关闭的第 1、2、3 条：①`design.md` 顺序偏离——接受；②`CLAUDE.themis.md`/`README.md` 删节口径——宽读；③仓库根 `AGENTS.md:13`——纳入本次范围。`catalog.md:33` 不在本次批复涉及范围内，仍未解决，见上「未解决反馈」。
