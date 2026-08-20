# design.md — core-removal / step1

> 本文件的小节结构定义见 `template.md`（`design.md` 一行）；结构决策的归属判据见 `rules.md` §6。按 `flow.md` 节点序列，`design.md` 正式归属"详细设计 + 任务"节点，其前置闸门见 `flow.md` 同节；本文件提前于该前置闸门在本 step（抽象设计 + R2）内成形，供 R2 投影承载 Overview（位置见 `rules.md` §3）。这一提前发生的顺序本身已作为本节点漂移记入 `docs/plan/spec-replay/drift-log.md`，此处不重复其内容。**本轮（任务 4）修订**：随 R2 批准，本文件正式归属"详细设计 + 任务"节点，并按所有者 R2 批复第 2、3 条完成三项修订——`CLAUDE.themis.md`/`README.md` 删节口径改为宽读、纳入仓库根 `AGENTS.md:13` 并给出处理方案、订正两处事实错误（命中行数、`docs/core/` 存在性前提）。修订前的草稿状态见 `state.md`「当前性」与 `docs/plan/spec-replay/drift-log.md` R2 条目。**另有四处行号区间错误在本轮自查重跑命令时发现并订正**（`CLAUDE.themis.md`「控制架构」「关键路径」、`README.md`「产品主链」与「Authority scopes」/「权威模型」两节被合并记为一节）：它们不是 R2 批复要求的修订项，而是宽读逐节判定新引入的数字，命令核验见「事实依据」命令 8，逐条标注在对应决策里。

## 架构与边界

- 本 step 的处理边界锚定 `Intent.md`「范围」小节已批准的七处活跃引用点。**七处的实际构成（本轮任务 4 据命令 10 重新核对）**：`templates/.themis/` 下 **5 处**——`CLAUDE.themis.md`、`README.md`、`AGENTS.md`、`spec/README.md`、`workspace/context/catalog.md`；加仓库根 `.gitignore:8` **1 处**；加仓库根 `AGENTS.md:13` **1 处**（经 R2 结论确认纳入）；5 + 1 + 1 = 7。"处"指引用点（文件内的一处独立位置），不是行数；引用点可横跨多行/多个列表项/多个表格行，逐行清点见「事实依据」命令 2。
- **一处继承自已批准工件的计数缺陷，本设计只标注、不静默修改**：`Intent.md`「来源引用」及其「范围」小节把这批引用记为"六处在 `templates/.themis/` 下"——把仓库根的 `.gitignore:8` 一并算进了 `templates/.themis/` 名下。上一版 `design.md` 沿用该表述后又把 `.gitignore` 作为"+ 一条规则"再加一次，使"合计七处"的算式**重复计入** `.gitignore`（5 个 templates 文件被说成 6 个，再加 1 条规则、再加根 `AGENTS.md`，得数虽仍是 7，路径归属却是错的）。命令 10 重跑 `git grep … -- templates/.themis/` 的文件枚举，输出恰为上述 5 个文件，`.gitignore` 不在其中（该命令路径限定使它不可能出现）。`Intent.md` 已获 R1/R2 批准，本任务不得改动，故此处只作显式标注；总数 7 不受影响，受影响的只是"哪一处在哪个路径下"这一归属。
- **"涉及 core 的内容删节"的解释边界（本轮按 R2 结论修订）**：R2 批复第 2 条已确认采**宽读**——删除依赖 core 架构（Capability/Agent Profile/Policy/Invocation 链路、simple/full 分支）才有意义的整节内容，不局限于字面出现 `core/` 路径的行。上一版草稿选择的窄读（只删字面 `core/` 路径行）已被 R2 否决，不再适用。宽读的判定单位是"节"：一节的内容脱离 core 的具体机制后是否仍然成立——不成立则整节（或节内可清晰界定的整块）删除，成立则保留，即便其中夹杂个别提及"Core"字样的短句（残留清单与边界见「取舍」）。
- **权威归属，必须先说清（本轮任务 4 订正的一处严重错误）**：所有者在 R2 给出的是**口径**，**没有点过任何一个章节名**。他的逐字原话见 `design-review.md`「结论」（`appreved。 1. 接受。2. 宽度。3. 纳入`），`Intent.md`、`QA.md`、`intent-review.md`、`design-review.md` 四份工件全文检索"产品流程""控制架构""Sticky"均零命中（核验见「事实依据」命令 11）。因此「结构决策」第 1、2 条里**每一节**的删或留，都是本节点应用该口径做出的推广判定，不是所有者的指令。上一版曾把「控制架构」「Sticky Full Path、Failure 与 Recovery」两节标为"R2 批复第 2 条明确点名"、把 `README.md`「控制架构」标为"点名的同类章节"——**这三处是无据的权威归属**，把 Agent 自己的推论写成了人的要求，会让 R3 读者误以为这些章节已经过所有者确认而放弃独立判断，本轮已全部改为事实表述。这一错误已单独记入 `docs/plan/spec-replay/drift-log.md`。R3 判定的正是这些推广是否得当。
- **范围外新发现，已随 R2 纳入范围**：用「事实依据」中的命令重新清点整个仓库（不止 `templates/.themis/`）时，曾发现仓库根 `AGENTS.md:13` 存在一条索引描述引用了 `core/`；该文件不在 `templates/.themis/` 之下，上一版草稿判断扩大范围需要新的 Intake/QA 确认，记为"范围外、不处理"。所有者已在 R2 批复第 3 条明确将其纳入本次范围（`design-review.md`"未解决反馈"第 3 条），`Intent.md`"范围"小节与 `specify.md`（新增 `SPEC-COREREMOVAL-004`）均已同步；本设计据此在「结构决策」第 7 条给出处理方案，不再是"只记录、不处理"。

## 结构决策

以下七处逐条定死做法（七处的构成与计数口径见「架构与边界」首条）；`catalog.md:33` 按所有者 R1 结论明确延后，本设计不为其定做法，只记录延后状态本身，这是本设计**唯一**保留的开放决策点。

1. **`templates/.themis/CLAUDE.themis.md`**：删节口径按 R2 结论确认为宽读——删除依赖 core 架构（Capability/Agent Profile/Policy/Invocation 链路、simple/full 分支）才有意义的整节内容，不局限于字面出现 `core/` 路径的行。逐节判定如下（判定依据：该节内容脱离 core 的具体机制后是否仍然成立）：

   - 首段（行 3）：删除提及 `.themis/core/kernel/orchestrator/rules.md`、`.themis/core/capabilities/`、`.themis/core/agent-profiles/` 的从句，只保留首句"本托管指南定义安装后项目的控制边界。`.claude/skills/themis/SKILL.md` 是唯一公共项目 Skill。"（与草稿一致，未因本轮修订改变）。
   - `## 安装边界`（行 5–10）：只删行 7 这一条列表项（"`.themis/core/` 归 Themis 所有，在正常项目工作中只读。"）；其余三条列表项（Workspace 所有权、fresh template 不做迁移、installer/runtime 限制）不描述 core 的具体机制，脱离 core 仍然成立，保留（与草稿一致）。
   - `## Intake-first 入口`（行 12–28）：不含 core 相关内容，不改。
   - `## 产品流程`（行 30–46）：**整节删除（本设计据宽读口径判定）**。该节代码块直接呈现 Complexity Assessment 的 simple/full 分支（`simple → Simple Plan …` / `full → temporary Specification …`），行 46 紧接着说明"两条路径创建同一个 immutable paired Plan family，并在 Review 前汇合"——这正是 `core/kernel/orchestrator/rules.md:84`（见 `Intent.md`"来源引用"）描述的双路径模型本身，脱离 core 该节没有意义。窄读（草稿）因该节不含字面 `core/` 字符串而完全未触及，是本轮要修正的遗漏之一。**整节删除的一处代价，如实记录**：行 46 尾部还夹带了非 core 专属的内容——Summary 前置条件、Summary pair 与 lifecycle completion 被观察后冻结 Intake target、以及 Intake 进入 `dormant-read-only` 的语义。整节删除会一并删掉这几句。本设计判断代价可接受：同类陈述在 `README.md:94,95`（`## Review、Verify 与门禁` 节内，本设计保留）仍在，信息不丢失；若逐句保留行 46 尾部，等于在整节删除里再开一层句级例外，与本设计申明的"节"为判定单位不一致。是否接受这一代价由 R3 判定。
   - `## 权威模型`（行 48–59）：本节整体是关于 Source Event/claim/evidence 的通用权威原则，脱离 core 仍然成立，不整节删除。但行 54 有一句"temporary Specification 是 full-path handoff，不具有 persistent artifact/current pointer"——"full-path"是双路径模型的残留提法。本设计选择不单独删这一句：宽读的判定单位是"整节"，本节作为整体不满足"依赖 core 才有意义"，若逐句再筛一层等于引入介于窄读与整节宽读之间的第三种粒度，本设计不擅自扩大到这一层。这是本节遗留的已知残留，记入「取舍」，供 R3 复核是否需要单独处理。
   - `## 控制架构`（行 61–79）：**整节删除（本设计据宽读口径判定）**。该节代码块（行 63–72）与其后六条列表项（行 74–79）完整描述 Markdown Policy package / 十六个内部 Capability / 四个 fixed Agent Profile / Invocation 绑定模型——全部是 core 的具体实现机制，没有一条脱离 core 仍然成立。（**本轮任务 4 订正**：上一版把本节范围记为"行 61–72"，只覆盖到代码块结束，把随后的六条列表项排除在外，与同一句自述的"代码块与其后六条列表项"自相矛盾；重跑「事实依据」命令 8 确认本节实际止于行 79。）
   - `## Scope 与 Artifact 隔离`（行 81–87）：描述 `request-intake` 与 `lifecycle` 两个 scope 的隔离规则、artifact revision 与 record/content 配对模型，不依赖 Capability/Profile/Policy 等 core 专属机制，脱离 core 仍可成立，不改。
   - `## Review、Verify、Acceptance 与 Summary`（行 89–97，共 **7 条**列表项，命令 9 核验）：**部分删除（本轮任务 4 新增，上一版整节标"不改"）**——只删行 96 的后半句"，但共享同一个 Plan Task Execution Identity 与 failure budget"，保留前半句（删后为"Impl 与 Verification 使用不同 Invocation。"）。理由：本设计删除本文件「Sticky Full Path、Failure 与 Recovery」节所依据的正是 failure budget 与 `rules.md` §10 冲突，同一理由不能既用于删除该节、又不适用于本行；上一版把整节标为"不改"是未作区分。其余 6 条描述 Review Dialogue/Approval/Impl/Verification/Acceptance/Summary 的通用流程原则，不依赖 core 的具体机制，保留。
   - `## Sticky Full Path、Failure 与 Recovery`（行 99–105）：**整节删除（本设计据宽读口径判定）**。章节名"Sticky Full Path"本身就是 simple/full 双路径模型的产物——没有 full path 就没有"是否 sticky"这个问题；第二段 Failure/Recovery 的三次 counted failure 与 failure budget 机制绑定在 Invocation/Execution Identity 模型（`控制架构`节所定义）之上，随 core 一并失去意义，且与本次 replay 依据的 `rules.md` §10（fail-closed、不做失败预算）直接冲突，是应随 core 一并清理的旧模型残留。
   - `## 安全降级`（行 107–111）：描述 Plan 35/36/37 的分阶段能力边界（evaluator/recorder/validator 等尚未实现），这是贯穿 Themis 全局的分阶段强制水平概念（`.themis/spec/README.md`"当前强制水平"一节的 soft/hard 执行器分级是同一类概念的另一处实例），不是 core 独有机制，不改。
   - `## 关键路径`（行 113–130，本文件末节）：只删表格中 Global Control Rule / route-control Policy / internal Capability contracts / fixed Agent Profile contracts 四行（行 118–121），其余表格行（公共入口、项目配置、`.themis/workspace/**` 各路径）与表格之后的行 130 不描述 core 机制，保留（与草稿一致）。（**本轮任务 4 订正**：上一版把本节范围记为"行 113–128"，止于表格最后一行，漏掉表格之后仍属本节的行 130；重跑「事实依据」命令 8 确认本文件共 130 行、本节自行 113 起至文末。）
   - 按 R1 结论"留待 Themis 更完善后再编写"：本次只删节，不补写替代内容，不改写为 spec 流程描述（与草稿一致，未因本轮修订改变）。

2. **`templates/.themis/README.md`**：同一宽读口径，逐节判定：

   - 首段（行 1–3）：说明本目录定义"Core 与 Workspace 基线"，属包范围声明而非 core 机制描述；删除或改写这句需要重写范围声明本身（例如改口径为仅"Workspace 基线"），超出 R1"只删节、不重写"的授权，本设计不改，作为已知残留记入「取舍」。
   - `## 产品主链`（行 5–25）：**部分整节删除（宽读新增）**——保留开头一句"安装包共同强化：详细细化前的需求追问、低负担 Plan Review、可沉淀的 Agent Plan，以及受治理、持续进化的项目知识库。"（Themis 四项产品特点的通用陈述，脱离 core 仍然成立，与仓库根 `AGENTS.md`"产品身份"一节同源）；删除紧随其后的代码块（行 9–23，Complexity Assessment simple/full 分支图，与 `CLAUDE.themis.md`"产品流程"节同一内容）；行 25 中"快速与完整路径只在统一 Plan 形成前不同"这一分句一并删除（删除后语句为"每条外部消息，包括 Questioning 回答、Review 反馈/批准、Acceptance 和 restart/unblock，都先经过 Intake interception。Review 始终位于项目实现前；Summary 只在 current Verification `passed` 且 Human Acceptance `accepted` 后生成。"，可读、不留断句），其余部分保留。保留的开头一句在行 7。（**本轮任务 4 订正**：上一版把本节范围记为"行 5–23"，止于代码块结束，却在同一条里处置了行 25，范围与处置对象自相矛盾；重跑「事实依据」命令 8 确认本节实际止于行 25。）
   - `## 控制架构`（行 27–46）：**部分整节删除（本设计据宽读口径判定）**——删除代码块（行 29–38，与 `CLAUDE.themis.md` 同一 Policy/Capability/Profile/Invocation 链路图）；保留行 40（"`skills/themis/SKILL.md` 是唯一公共 Themis 入口……"，描述 SKILL.md 本身，不依赖 core）；行 41–44 四条 core 组件索引删除（草稿已有，不变）；行 45（"一次 Invocation 只执行一个 Capability，Capability/Agent 不得嵌套调度……"）**新增删除**——不含字面 `core/`，但描述的正是 core 的 Capability/Agent 调度模型，脱离 core 不再有意义；行 46 保留列表项主体、删除"，与上述 `core/` 组件零引用"半句（草稿已有，不变）。
   - `## Authority scopes`（行 48–58，含 `### request-intake`（行 50–52）与 `### lifecycle`（行 54–58）两个子节）：描述 `request-intake` 与 `lifecycle` 两个 scope 各自拥有什么、以及二者只能交换稳定不可变引用，与 `CLAUDE.themis.md`"Scope 与 Artifact 隔离"节同源，不依赖 Capability/Profile/Policy 等 core 专属机制，脱离 core 仍可成立，不改。
   - `## 权威模型`（行 60–69）：本节整体是关于 Source Event/claim/evidence 的通用权威原则，与 `CLAUDE.themis.md`"权威模型"节同源，脱离 core 仍然成立，不整节删除。行 66"Specification 只是完整路径中的临时非权威 handoff"同样残留"完整路径"提法，处理方式与 `CLAUDE.themis.md` 行 54 一致：不单独删，作为已知残留记入「取舍」。（**本轮任务 4 订正**：上一版把本文件的 `## Authority scopes` 与 `## 权威模型` 合并记为一节"行 48–69"，并把行 66 挂到了 `Authority scopes` 名下；重跑「事实依据」命令 8 确认这是两个独立的 `##` 节——`Authority scopes` 止于行 58，行 66 属 `权威模型`。合并记法使 `Authority scopes` 一节实际上未被逐节判定过，本轮补判为"不改"。）
   - `## Artifact 与 Workspace`（行 71–86）：描述 workspace 各子目录用途与 artifact revision/record-content 配对模型，不依赖 core 机制，不改。
   - `## Review、Verify 与门禁`（行 88–96，共 **7 条**列表项，命令 9 核验）：**部分删除**——删行 96 整条（"`full_path_required` 在 lifecycle 内只允许 `false → true`，不会因 restart、retry 或 reassessment 清除。"），这是 Sticky Full Path 概念在 README.md 的对应表述；**本轮任务 4 新增**：删行 93 的后半句"；两个 Invocation 共享一个 Plan Task Execution Identity 和失败预算"，保留前半句（删后为"Verify 固定为 `themis-impl → independent themis-verification`。"）——本设计删除两份文件的 Failure 节所依据的正是 failure budget 与 `rules.md` §10 冲突，同一理由不能既用于删除又不适用于本行，上一版把整条保留是未作区分。其余 5 条（Plan Check、Review Dialogue、Approval、Verification/Acceptance/Summary 前置、Intake `dormant-read-only`）不依赖 core 机制，保留。删后该节仍为 **6 条**（**本轮任务 4 订正**：上一版写"其余七条保留"，该节实为 7 条、删一条后余 6 条，且原句自己只枚举出 6 项；数字未跑命令核对，本轮据命令 9 订正）。
   - `## Failure 与 recovery`（行 98–102）：**整节删除（宽读新增，与 `CLAUDE.themis.md`"Sticky Full Path、Failure 与 Recovery"节同类）**——三次 counted failure、failure budget 与 Execution Identity 模型绑定，随 core 一并失去意义，且与 `rules.md` §10 冲突。
   - `## 不变量与当前能力边界`（行 104–112，共 **7 条**列表项，命令 9 核验）：**部分删除**——删行 106 整条（"Core 管理控制合同；Workspace 保存项目拥有的记录与引用，但不实现控制逻辑。"，不含字面 `core/`，但直接陈述 Core 的所有权角色，脱离 core 不再有意义）；**本轮任务 4 新增**：删行 109 中"十六个内部 Capability、四个 Profile"两项枚举，保留该条其余部分（删后为"Plan 35 只提供一个公共 Skill、一个 Global Rule、一个双作用域 policy、immutable templates、static verification 和 manual replay semantics。"）——这两项与行 41–44 被删的 core 组件索引是同一份清单，删索引却留枚举自相矛盾，上一版把整条按"跨阶段路线图"保留，该理由对这两项不成立。其余 5 条（版本概念、Behavior Map/Shell fallback 范围、Plan 36/37 能力边界、runtime 声称限制）描述的是跨阶段路线图或通用不变量，不是 core 专属机制，保留（判断理由与 `CLAUDE.themis.md`"安全降级"节一致，不重复）。删后该节仍为 **6 条**（**本轮任务 4 订正**：上一版写"其余五条保留"，该节实为 7 条、删一条后余 6 条，且原句自己只枚举出 4 类；数字未跑命令核对，本轮据命令 9 订正）。
   - 同样不补写替代内容。

3. **`templates/.themis/AGENTS.md`「与 `core/` 的关系」一节**（行 47–51）：整节删除。所有者已定（R1 结论"2. 删除"），不重新讨论。

4. **`.gitignore:8` `/.themis/core/`**：删除该行。其余四条忽略规则（`/.themis/spec/`、`/.themis/skills/`、`/.themis/README.md`、`/.themis/CLAUDE.themis.md`）与说明性注释（行 4–6）保留不动——它们对应仍存在的安装副本，删除会让入库风险重新出现。

5. **`templates/.themis/spec/README.md:5`**（"本包与 `.themis/core/` 零引用"声明）：**不修改**，沿用既有裁定。理由：该文件既是本次要处理的删除对象，又是 replay 正依据的只读控制面 `.themis/spec/README.md` 的包源；`Intent.md`「约束」小节已确认这条裁定——replay 期间不重装，不同步安装包源与已装副本。本次新增的分歧内容记录如下：`core/` 删除后，包源第 5 行这句话的字面意思从"陈述包与一个存在的目录零引用"变为"陈述包与一个已删除目录零引用"——命题本身仍然成立（对不存在的东西"零引用"逻辑上不假），但该陈述存在的原始意义（提醒读者"本包不碰 core"）会随 core 消失而失去讨论价值，是被记录、而非被修复的过时表述。包源文件（`templates/.themis/spec/README.md`，本次不写）与已安装只读副本（`.themis/spec/README.md`，禁止修改）在这句话上目前完全一致；本次决定生效后，包源会比已安装副本描述的世界更旧（包源仍谈论一个即将不存在的 `core/`）。这一分歧留到下一次独立的安装/更新动作解决，不在本 replay 处理范围内。

6. **`templates/.themis/workspace/context/catalog.md:33`**：**不定处理方案**。按 R1 结论第 3 点，所有者明确要求延后：完成前述各项后另行提出处理方案，由所有者单独审阅。本设计不在此定"改成相对路径以外的写法""删除该引用"或任何其他具体做法；只记录事实：目标文件 `templates/.themis/core/protocols/context/references/catalog.md` 当前存在（已用 `ls` 核验，见「事实依据」），删除 `core/` 后这条相对路径引用会变为断链。SPEC-COREREMOVAL-001 的判据会命中这一行；本条决策记录本身就是该判据要求的"明确保留（或明确延后）的决定"——`catalog.md:33` 的这条命中因所有者已决定延后审阅，属已知例外，不判 SPEC-COREREMOVAL-001 failed，但也不构成"已处理"，二者不可混同。**本条是本设计唯一保留的开放决策点，任务 4 不改变其状态。**

7. **（原"范围外新发现"）仓库根 `AGENTS.md:13`**：**处理（R2 批复第 3 条已纳入范围，`specify.md` 已新增 `SPEC-COREREMOVAL-004` 覆盖）**。当前行内容（核验见「事实依据」命令 6）：

   ```text
   | `.themis` | [`templates/.themis/AGENTS.md`](templates/.themis/AGENTS.md) —— spec 控制面写作、与 `core/` 的关系 |
   ```

   第 3 条决策删除 `templates/.themis/AGENTS.md`「与 `core/` 的关系」一节后，这行描述末尾"、与 `core/` 的关系"半句会指代一个不存在的章节。处理方式与本节第 2 条"README.md 行 46"同型——保留列表项主体、只删失效半句：链接与"spec 控制面写作"这半句仍然真实（`templates/.themis/AGENTS.md` 文件本身没有被删除，"控制面写作"一节也没有被删除），改为：

   ```text
   | `.themis` | [`templates/.themis/AGENTS.md`](templates/.themis/AGENTS.md) —— spec 控制面写作 |
   ```

   不补写替代内容，与其余各处同一口径。

## 取舍

- **catalog.md 是本设计唯一保留的开放决策点；根 AGENTS.md:13 已随 R2 转为已处理**：上一版草稿把 `catalog.md:33`（范围内、所有者要求延后）与根 `AGENTS.md:13`（范围外新发现、design 节点判断不能单方面处理）分列为两类不同性质的"暂不处理"，理由是二者能否被处理的前提不同。本轮 R2 批复第 3 条已解除根 `AGENTS.md:13` 的范围外状态并纳入处理（见「结构决策」第 7 条），二者不再同属"暂不处理"这一类；但历史上分列的记录本身保留，不回填合并——`catalog.md:33` 现在是「结构决策」中唯一没有具体做法、仍待所有者单独审阅的一条，其余六处全部已有明确处理方案，这条区分应当更清楚而不是更模糊。
- **CLAUDE.themis.md / README.md 采宽读，整节删除依赖 core 才有意义的内容（本轮按 R2 结论改写，替换上一版"只删字面路径行"的窄读取舍）**：宽读的代价是更大的改动面——`CLAUDE.themis.md` 的"产品流程""控制架构""Sticky Full Path、Failure 与 Recovery"三节、`README.md` 的"产品主链"（部分）、"控制架构"（部分）、"Failure 与 recovery"（整节）、"Review、Verify 与门禁"（部分）、"不变量与当前能力边界"（部分）均整节或部分删除，两份文件删节后剩余内容比窄读方案少得多。好处是不再留下"字面没有 `core/` 但实际描述 core 专属机制、SPEC-COREREMOVAL-001 判据也检测不到"的失真架构性叙述。
- **已知残留清单——本清单为"非穷尽"，边界如下（本轮任务 4 重写，上一版声称"这三处"是封闭清单，实测不成立）**：宽读的判定单位是"节"，节内个别短语提及 core 概念时本设计不逐句摘除，因此**保留节内必然留下短语级残留**，无法穷尽枚举。已核对出的残留分两类：
  - **本轮改为删除的（原被保留、但整条列表项确实依赖 core，理由与已删各节同源，留着即自相矛盾）**：`README.md:109` 的"十六个内部 Capability、四个 Profile"两项枚举——它与 `README.md:43,44` 被删的 core 组件索引是同一份清单，删索引留枚举说不通，本轮改为删这两项枚举、保留该条其余部分（见「结构决策」第 2 条）；`README.md:93` 与 `CLAUDE.themis.md:96` 的后半句（共享 Plan Task Execution Identity 与 failure budget）——本设计删除两份文件的 Failure 节所给的理由正是 failure budget 与 `rules.md` §10 冲突，同一理由不能在同一轮里既用于删除又不适用于保留，本轮改为删这两处后半句、保留各自前半句（见「结构决策」第 1、2 条）。
  - **仍保留、且已知含残留的（短语级，节内其余内容非 core 专属）**：`CLAUDE.themis.md`「权威模型」行 54、`README.md`「权威模型」行 66 各有一句"full-path handoff"提法（**本轮任务 4 订正**：上一版把行 66 记在 `README.md`「Authority scopes」名下，实际属该文件的「权威模型」节，核验见「事实依据」命令 8）；`README.md:58`、`CLAUDE.themis.md:83` 的 scope 隔离句中列举了 `Execution Identity`/`failure budget`（整句讲的是两个 scope 不共享什么，属通用隔离原则，删整句会丢掉非 core 内容）；`README.md:69` 提及 `Capability result`；`README.md` 首段"Core 与 Workspace 基线"这一范围声明未改（修改它需要重写范围声明本身，超出 R1 授权的"删节、不重写"）。
  - 以上均记录在此，不是被忽略、也不是被暗中修复，留给 R3 判断是否可接受。**若 R3 认为短语级残留也须清除，需要所有者对"删节 vs 重写"的边界再给一次明确表态**——那将不再是删节，而是重写这两份文件。
- **spec/README.md 与 catalog.md 都选择不修改，而非顺手一起处理**：`spec/README.md` 不改是因为它是 replay 正依据的只读控制面的包源，擅自改动会违反"replay 期间不重装"的既有裁定；`catalog.md` 不改是因为所有者明确要求延后。两者外观相似（都是"发现问题但不修"），但理由不同，「结构决策」第 5、6 条分别单独说明理由，不合并成一条笼统的"暂不处理"（与草稿一致，未因本轮修订改变）。

## 事实依据

事实源分层判据见 `rules.md` §1，不复述其文字。以下命令均在本次任务执行时于工作树 `C:/Coding/Themis/.claude/worktrees/spec-flow-replay` 内真实运行，输出如实粘贴，作为本 step 结构决策的代码层依据。

**本轮任务 4 把命令 1–7 逐条重跑并与下方所载输出逐字比对**（不是重读上一版写下的数字）：命令 1、2、3、4、6、7 输出与下方完全一致，命令 5 的命中范围亦未变化。命令 8 为本轮新增，用于核验「结构决策」第 1、2 条逐节判定所引的行号区间——上一版这些行号未经命令核验，本轮据命令 8 订正了四处（`CLAUDE.themis.md` 两处、`README.md` 两处，逐条标在对应决策里）。

**命令 1**：`find templates/.themis/core -type f | wc -l`
```text
98
```

**命令 2**：`git grep -n 'core/' -- templates/.themis/ | grep -v '\.themico/core' | grep -v '^templates/\.themis/core/'`（`templates/.themis/` 下 **5 个文件**的完整命中；第 6、7 个引用点是仓库根的 `.gitignore:8` 与 `AGENTS.md:13`，不在本命令的路径限定内，证据分别见命令 4、命令 6）
```text
templates/.themis/AGENTS.md:47:## 与 `core/` 的关系
templates/.themis/AGENTS.md:49:`core/` 是 simple/full 双路径模型，与已批准契约 `docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md` 的单一路径要求冲突，待端到端 replay 验证后整体删除。
templates/.themis/AGENTS.md:51:在此之前：`spec/` 与 `skills/` 不得引用 `core/` 的任何路径（引用即断链），也不得复制其合同。查阅取经可以，产出必须重新写。
templates/.themis/CLAUDE.themis.md:3:本托管指南定义安装后项目的控制边界。`.claude/skills/themis/SKILL.md` 是唯一公共项目 Skill，`.themis/core/kernel/orchestrator/rules.md` 是唯一常驻加载的控制 Rule。语义合同与权限边界保留在内部 `.themis/core/capabilities/` 和 `.themis/core/agent-profiles/` 中。
templates/.themis/CLAUDE.themis.md:7:- `.themis/core/` 归 Themis 所有，在正常项目工作中只读。
templates/.themis/CLAUDE.themis.md:118:| Global Control Rule | `.themis/core/kernel/orchestrator/rules.md` |
templates/.themis/CLAUDE.themis.md:119:| 唯一 route/control Policy | `.themis/core/policies/README.md` 与 `references/` |
templates/.themis/CLAUDE.themis.md:120:| internal Capability contracts | `.themis/core/capabilities/` |
templates/.themis/CLAUDE.themis.md:121:| fixed Agent Profile contracts | `.themis/core/agent-profiles/` |
templates/.themis/README.md:41:- [`core/kernel/orchestrator/rules.md`](core/kernel/orchestrator/README.md) 是唯一常驻 Rule，按 durable gate 加载通用 references，并协调双作用域。
templates/.themis/README.md:42:- [`core/policies/README.md`](core/policies/README.md) 与其 references 共同构成 route/control、固定 Profile/scope、guards、invalidation 和失败控制的唯一自然语言 Policy。
templates/.themis/README.md:43:- [`core/capabilities`](core/capabilities/README.md) 中十六个内部 Capability 分别拥有一个 proposed semantic judgment；它们不是公共 Skills。
templates/.themis/README.md:44:- [`core/agent-profiles`](core/agent-profiles/README.md) 中四个固定 Profile 只约束工具、权限与隔离；没有 governance writer。
templates/.themis/README.md:46:- [`spec/README.md`](spec/README.md) 索引 spec 流程的定义面（`flow.md`/`rules.md`/`template.md`/`README.md`），是独立于本控制架构的另一套流程合同：安装后运行时只读，与上述 `core/` 组件零引用。
templates/.themis/spec/README.md:5:本包与 `.themis/core/` 零引用：不引用其路径，也不复制其合同。
templates/.themis/workspace/context/catalog.md:33:未来每个 item index entry 必须符合 [Context Catalog 描述合同](../../core/protocols/context/references/catalog.md)，并保持 unique ID/path、existing references 与 acyclic dependency 约束。Catalog 只能索引受治理经验、背景、约束或核验线索，不拥有当前实现事实、Current Request、Plan、lifecycle state 或 current pointer authority。
```
共 16 行，覆盖 **5 个文件**：`templates/.themis/AGENTS.md`、`CLAUDE.themis.md`、`README.md`、`spec/README.md`、`workspace/context/catalog.md`（`git grep … | cut -d: -f1 | sort -u` 本轮重跑，输出即这 5 个，见命令 10）。这 5 个文件各含一个引用点，其中 AGENTS.md/CLAUDE.themis.md/README.md 内部横跨多行/多列表项/多表格行。**本轮任务 4 订正两处计数与归属错误**：（1）上一版此处写"覆盖 6 个引用点"却只枚举 5 个文件——本命令的路径限定是 `-- templates/.themis/`，`.gitignore:8` 不可能出现在它的输出里（`.gitignore` 在仓库根），第 6 个引用点是 `.gitignore:8`，其证据在命令 4 而非本命令；（2）行数 14→16 的订正（任务 3 执行者重跑 `SPEC-COREREMOVAL-001` 判据命令时自己发现，已记入 `docs/plan/spec-replay/drift-log.md` R2 条目）上一轮虽已改对，却没有同时发现紧邻的引用点计数错误——本轮声称"重跑同一条命令核对"时只核对了行数，未核对同段的文件枚举，这一点如实记录。本轮重跑输出与上方所载完全一致，确认 16 行、5 个文件。

**命令 3**：`ls -la templates/.themis/core/protocols/context/references/catalog.md`（核验 `catalog.md:33` 目标当前存在）
```text
-rw-r--r-- 1 lin10 197609 2396  8月 19 15:41 templates/.themis/core/protocols/context/references/catalog.md
```

**命令 4**：`cat .gitignore`（全文 11 行；`wc -l < .gitignore` 输出 `11`，支撑 `specify.md` 的 `SPEC-COREREMOVAL-002` 判据里"全文仅 11 行"这一断言，本轮已重跑核对）
```text
.idea/
*.iml

# 安装到本仓库的 Themis 控制面副本——它只是 templates/.themis/ 的拷贝，
# 入库即两份控制面，改一处忘另一处就是漂移。安装动作由 Go CLI 承担
# （能力尚未实现，当前人工），副本不入库。
/.themis/spec/
/.themis/core/
/.themis/skills/
/.themis/README.md
/.themis/CLAUDE.themis.md
```

**命令 5**：`git grep -n 'core/' -- . ':!templates/.themis/core' ':!.themis/core' ':!docs' | grep -v '\.themico\|internal/themico'`（超出 `templates/.themis/` 与 `docs/` 之外的全仓库重新清点，核对 `templates/.themis/` 下那 5 个文件之外是否另有遗漏的活跃依赖；本轮已重跑，输出与命中范围与上一轮一致，未变化。**本轮第二次复核订正**：上一版题注写"核对是否有第六处之外的遗漏活跃依赖"，沿用的是 R2 前"六处"的旧计数口径，与本命令实际的比对基准——`templates/.themis/` 下 5 个文件——不符）

真实剩余命中除已识别的 `.gitignore:8`、`templates/.themis/{AGENTS,CLAUDE.themis,README}.md`、`templates/.themis/spec/README.md`、`catalog.md:33`、以及本实例工件自身（`.themis/workspace/spec/core-removal/**`，属本次生成的记录，不是待处理引用）外，新发现两类命中：

1. **`AGENTS.md:13`**（仓库根）：`| `.themis` | [`templates/.themis/AGENTS.md`](templates/.themis/AGENTS.md) —— spec 控制面写作、与 `core/` 的关系 |` —— 真实活跃引用，落在 `templates/.themis/` 范围外，处理方式见「结构决策」第 7 条。
2. **`CHANGES.md:78`**：`- 初始化 `.themis` 模板目录结构（`core/` + `workspace/` 双命名空间）` —— 这是历史变更日志条目，描述的是"当时做了什么"这一过去事实，不对当前结构做任何陈述，性质与 `Intent.md`「非做」小节已排除的 `docs/` 下历史证据记录相同（虽然 `CHANGES.md` 不在 `docs/` 路径下）。删除 `core/` 不会让这条历史记录变假，判定为不需处理，比照既有的历史文档排除口径，不单独列为第 8 条结构决策。

其余命中（`CHANGES.md:41,81,82` 的 `docs/core/**`、`README.md:58,80,101` 的 `docs/plan/themico-core/**`）核实为误报，但两者理由不同，**本轮予以订正**：

- `CHANGES.md:41,81,82` 三行与已判定"不需处理"的 `CHANGES.md:78`（见上）同属一份历史变更日志（`## 0.2.0`/`## 0.1.0` 版本条目），记的是"当时做了什么"这一过去事实，不对当前结构做任何陈述——删除 `templates/.themis/core/` 不会让这些历史记录变假，应套用与 `CHANGES.md:78` 相同的理由（历史变更日志不陈述当前结构），不单独列为结构决策。**订正**：上一版草稿在此处未套用同一理由，而是另编了"`docs/core/` 是另一套已归档的旧文档目录"这一说法来论证不处理——`git ls-files | grep '^docs/core/'` 核验为空（见命令 7），该目录当前并不存在，已被提交 `2c5835e docs: move docs`（2026-07-27）整体移出仓库；结论（不处理）本身没错，但依据是假的，本轮已改为套用 `CHANGES.md:78` 的正确理由，不再依赖"docs/core/ 是另一套目录"这一不成立的前提。
- `docs/plan/themico-core/**` 是 Themico 自己的实施计划目录（目录名恰好包含 `core` 子串，与本次删除对象 `templates/.themis/core/` 无关）——两者均非活跃依赖，不入清点。

**命令 6**（本轮新增）：`grep -n '与.*core.*的关系' AGENTS.md`（核验仓库根 `AGENTS.md` 中该短语只命中一处，支撑 `SPEC-COREREMOVAL-004` 判据边界与「结构决策」第 7 条）
```text
13:| `.themis` | [`templates/.themis/AGENTS.md`](templates/.themis/AGENTS.md) —— spec 控制面写作、与 `core/` 的关系 |
```

**命令 7**（本轮新增）：`git ls-files | grep '^docs/core/'`（核验 `docs/core/` 当前不存在，用于订正上一版对 `CHANGES.md:41,81,82` 的误报定性）
```text
（无输出）
```
`git show --stat 2c5835e | head -5`（该目录内容何时被移出仓库）
```text
commit 2c5835eefb1c87493b1c01daa87529ca4fa8b9d3
Author: zhanyan <1075465357lin@gmail.com>
Date:   Mon Jul 27 19:19:52 2026 +0800

    docs: move docs
```

**命令 8**（本轮新增）：`grep -n '^#' templates/.themis/CLAUDE.themis.md` 与 `wc -l < templates/.themis/CLAUDE.themis.md`（核验「结构决策」第 1 条逐节判定所引的行号区间）
```text
1:# Themis 项目指南
5:## 安装边界
12:## Intake-first 入口
30:## 产品流程
48:## 权威模型
61:## 控制架构
81:## Scope 与 Artifact 隔离
89:## Review、Verify、Acceptance 与 Summary
99:## Sticky Full Path、Failure 与 Recovery
107:## 安全降级
113:## 关键路径
--- wc -l ---
130
```

`grep -n '^#' templates/.themis/README.md` 与 `wc -l < templates/.themis/README.md`（核验「结构决策」第 2 条逐节判定所引的行号区间）
```text
1:# Themis 安装包合同
5:## 产品主链
27:## 控制架构
48:## Authority scopes
50:### `request-intake`
54:### `lifecycle`
60:## 权威模型
71:## Artifact 与 Workspace
88:## Review、Verify 与门禁
98:## Failure 与 recovery
104:## 不变量与当前能力边界
--- wc -l ---
112
```

每节的行号区间由"本节标题行 → 下一个同级或更高级标题行减一"取得，末节取至文件末行。据此比对上一版逐节判定所引的区间，四处不符已在「结构决策」对应条目逐条标注订正：`CLAUDE.themis.md`「控制架构」61–72→61–79、「关键路径」113–128→113–130；`README.md`「产品主链」5–23→5–25、「Authority scopes」48–69 拆为「Authority scopes」48–58 与「权威模型」60–69。两份文件的全部 `##` 节现已各自被逐节判定覆盖，无遗漏节。

`grep -n '^#' templates/.themis/AGENTS.md` 与 `wc -l < templates/.themis/AGENTS.md`（核验「结构决策」第 3 条所引的行 47–51 确为该文件末节的完整区间）
```text
1:# `.themis` 模块规范
7:## 控制面写作
11:### 引用只指向，不复述
32:### 判据必须有判定者
41:### 失败去向必须镜像前置闸门的分支
47:## 与 `core/` 的关系
--- wc -l ---
51
```

**命令 9**（本轮新增）：三条 `awk … | wc -l`，核验「结构决策」第 1 条一处、第 2 条两处的列表条数——`awk 'NR>=88 && NR<=96 && /^- /' templates/.themis/README.md | wc -l`、`awk 'NR>=104 && NR<=112 && /^- /' templates/.themis/README.md | wc -l`、`awk 'NR>=89 && NR<=97 && /^- /' templates/.themis/CLAUDE.themis.md | wc -l`
```text
7
7
7
```
三节各 7 条列表项：`README.md`「Review、Verify 与门禁」、`README.md`「不变量与当前能力边界」、`CLAUDE.themis.md`「Review、Verify、Acceptance 与 Summary」。据此订正上一版两处未经命令核对的计数：「Review、Verify 与门禁」原写"其余七条保留"（实为删 1 条后余 6 条）、「不变量与当前能力边界」原写"其余五条保留"（实为删 1 条后余 6 条）。第三条 `awk` 为本轮第二次复核时补入——「结构决策」第 26 行引用本命令核验 `CLAUDE.themis.md` 的 7 条，而本命令原先只覆盖 `README.md`，断言与证据对不上，按"断言旁必须有覆盖它的命令记录"就地补齐。
```text
7
7
```
两节各 7 条列表项。据此订正上一版两处未经命令核对的计数：「Review、Verify 与门禁」原写"其余七条保留"（实为删 1 条后余 6 条）、「不变量与当前能力边界」原写"其余五条保留"（实为删 1 条后余 6 条）。

`grep -n 'failure budget\|失败预算' templates/.themis/README.md templates/.themis/CLAUDE.themis.md`（核验保留节内 failure budget 残留的实际位置，支撑「取舍」残留清单与第 1、2 条本轮新增的两处半句删除）
```text
templates/.themis/README.md:58:两个 scope 只能交换稳定不可变引用，不能共享动态 state、Execution Identity、failure budget、continuation authority、current pointer 或 completion state。Confirmed assignment 完整物化并重读前，不得创建或继续 lifecycle。
templates/.themis/README.md:93:- Verify 固定为 `themis-impl → independent themis-verification`；两个 Invocation 共享一个 Plan Task Execution Identity 和失败预算。
templates/.themis/CLAUDE.themis.md:83:`request-intake` 与 `lifecycle` 只能交换 immutable stable references。二者不能共享 dynamic state、Execution Identity、failure budget、continuation authority、current pointer 或 completion state。
templates/.themis/CLAUDE.themis.md:96:- Impl 与 Verification 使用不同 Invocation，但共享同一个 Plan Task Execution Identity 与 failure budget。
```
行 93 与行 96 的后半句本轮改为删除（理由与删除两份文件 Failure 节的理由同源）；行 58 与行 83 整句讲两个 scope 不共享什么，属通用隔离原则，保留并记入「取舍」残留清单。

**命令 10**（本轮新增）：`git grep -n 'core/' -- templates/.themis/ | grep -v '\.themico/core' | grep -v '^templates/\.themis/core/' | cut -d: -f1 | sort -u`（核验命令 2 实际覆盖哪几个文件，用于订正"6 个引用点"的计数与 `.gitignore` 的路径归属）
```text
templates/.themis/AGENTS.md
templates/.themis/CLAUDE.themis.md
templates/.themis/README.md
templates/.themis/spec/README.md
templates/.themis/workspace/context/catalog.md
```
恰为 5 个文件。`.gitignore` 不在其中——本命令的路径限定为 `-- templates/.themis/`，仓库根文件不可能出现在输出里。第 6、7 个引用点（`.gitignore:8`、仓库根 `AGENTS.md:13`）的证据分别在命令 4 与命令 6。

**命令 11**（本轮新增）：`grep -n '产品流程\|控制架构\|Sticky' Intent.md QA.md intent-review.md step1/design-review.md`（在实例根目录下运行；核验所有者是否点过任何章节名，支撑「架构与边界」的权威归属订正）
```text
（无输出，exit=1）
```
四份工件——含所有者 R1、R2 两次批复的逐字原话——全文均无任何章节名命中。据此确认：所有者给的是口径，逐节的删或留全部是本设计的推广判定。
