# design.md — core-removal / step1

> 本文件的小节结构定义见 `template.md`（`design.md` 一行）；结构决策的归属判据见 `rules.md` §6。按 `flow.md` 节点序列，`design.md` 正式归属"详细设计 + 任务"节点，其前置闸门见 `flow.md` 同节；本文件提前于该前置闸门在本 step（抽象设计 + R2）内成形，供 R2 投影承载 Overview（位置见 `rules.md` §3）。这一提前发生的顺序本身已作为本节点漂移记入 `docs/plan/spec-replay/drift-log.md`，此处不重复其内容。

## 架构与边界

- 本 step 的处理边界锚定 `Intent.md`「范围」小节已批准的表述：`templates/.themis/` 下六处活跃引用点 + `.gitignore` 一条规则。六处引用点各自可能横跨多行/多个列表项/多个表格行，"六处"指引用点（文件内的一处独立位置），不是行数；六处的逐行清点见「事实依据」。
- **"涉及 core 的内容删节"的解释边界**：本设计把这句 R1 结论只解释为"删除字面引用 `core/` 路径的具体行/列表项/表格行"，不延伸到 `CLAUDE.themis.md`、`README.md` 中虽以 core 特有架构为背景、但字面未出现 `core/` 路径的其他叙述（例如"产品流程"一节的 simple/full 分支描述、"控制架构"一节的 Global Control Rule/Capability/Agent Profile 链路描述）。理由：Intent.md 的"范围"本身是通过字面 `git grep 'core/'` 清点得出的，若把"涉及 core 的内容"扩大解释为"任何以 core 架构为背景的叙述"，等同于把这次请求从"清理 core/ 目录残留路径引用"单方面升级为"重写整份项目治理文档"——这是比 R1 已批准范围大得多的决定，不应由 design 节点在没有新一轮确认的情况下自行做出。这条边界选择记入「取舍」，其代价（残留的架构性叙述）记入同处。
- **范围外新发现，本设计不处理**：用「事实依据」中的命令重新清点整个仓库（不止 `templates/.themis/`）后，另发现仓库根 `AGENTS.md:13` 存在一条索引描述引用了 `core/`；该文件不在 `templates/.themis/` 之下，不属于 `Intent.md` 已批准的范围。扩大处理范围需要新的 Intake/QA 确认，不是 design 节点单方面能决定的事——本设计对这条只记录、不处理，详见「结构决策」第 7 条。

## 结构决策

以下六处（对应 `Intent.md`「范围」中已批准的"六处活跃引用"）逐条定死做法；第 6 条（`catalog.md:33`）按所有者 R1 结论明确延后，本设计不为其定做法，只记录延后状态本身；第 7 条是范围外新发现，同样不定做法、只记录。

1. **`templates/.themis/CLAUDE.themis.md`**（行 3、7、118–121）：
   - 行 3：删除句中提及 `.themis/core/kernel/orchestrator/rules.md`、`.themis/core/capabilities/`、`.themis/core/agent-profiles/` 的从句，只保留首句"本托管指南定义安装后项目的控制边界。`.claude/skills/themis/SKILL.md` 是唯一公共项目 Skill。"
   - 行 7：整条列表项（"`.themis/core/` 归 Themis 所有，在正常项目工作中只读。"）删除。
   - 行 118–121：「关键路径」表格中 Global Control Rule / route-control Policy / internal Capability contracts / fixed Agent Profile contracts 四行删除，表格其余行（公共入口、项目配置、`.themis/workspace/**` 各路径）保留。
   - 按 R1 结论"留待 Themis 更完善后再编写"：本次只删节，不补写替代内容，不改写为 spec 流程描述。

2. **`templates/.themis/README.md`**（行 41–44 + 46）：
   - 行 41–44：四条 core 组件索引列表项（`core/kernel/orchestrator/rules.md`、`core/policies/README.md`、`core/capabilities`、`core/agent-profiles`）整条删除。
   - 行 46：保留列表项主体（说明 `spec/README.md` 索引 spec 流程定义面、安装后只读），只删除句尾"，与上述 `core/` 组件零引用"这半句——该半句的语义依附于"上述 core/ 组件"这个即将消失的列表，保留会指代不存在的内容。
   - 同样不补写替代内容。

3. **`templates/.themis/AGENTS.md`「与 `core/` 的关系」一节**（行 47–51）：整节删除。所有者已定（R1 结论"2. 删除"），不重新讨论。

4. **`.gitignore:8` `/.themis/core/`**：删除该行。其余四条忽略规则（`/.themis/spec/`、`/.themis/skills/`、`/.themis/README.md`、`/.themis/CLAUDE.themis.md`）与说明性注释（行 4–6）保留不动——它们对应仍存在的安装副本，删除会让入库风险重新出现。

5. **`templates/.themis/spec/README.md:5`**（"本包与 `.themis/core/` 零引用"声明）：**不修改**，沿用既有裁定。理由：该文件既是本次要处理的删除对象，又是 replay 正依据的只读控制面 `.themis/spec/README.md` 的包源；`Intent.md`「约束」小节已确认这条裁定——replay 期间不重装，不同步安装包源与已装副本。本次新增的分歧内容记录如下：`core/` 删除后，包源第 5 行这句话的字面意思从"陈述包与一个存在的目录零引用"变为"陈述包与一个已删除目录零引用"——命题本身仍然成立（对不存在的东西"零引用"逻辑上不假），但该陈述存在的原始意义（提醒读者"本包不碰 core"）会随 core 消失而失去讨论价值，是被记录、而非被修复的过时表述。包源文件（`templates/.themis/spec/README.md`，本次不写）与已安装只读副本（`.themis/spec/README.md`，禁止修改）在这句话上目前完全一致；本次决定生效后，包源会比已安装副本描述的世界更旧（包源仍谈论一个即将不存在的 `core/`）。这一分歧留到下一次独立的安装/更新动作解决，不在本 replay 处理范围内。

6. **`templates/.themis/workspace/context/catalog.md:33`**：**不定处理方案**。按 R1 结论第 3 点，所有者明确要求延后：完成前述各项后另行提出处理方案，由所有者单独审阅。本设计不在此定"改成相对路径以外的写法""删除该引用"或任何其他具体做法；只记录事实：目标文件 `templates/.themis/core/protocols/context/references/catalog.md` 当前存在（已用 `ls` 核验，见「事实依据」），删除 `core/` 后这条相对路径引用会变为断链。SPEC-COREREMOVAL-001 的判据会命中这一行；本条决策记录本身就是该判据要求的"明确保留（或明确延后）的决定"——`catalog.md:33` 的这条命中因所有者已决定延后审阅，属已知例外，不判 SPEC-COREREMOVAL-001 failed，但也不构成"已处理"，二者不可混同。

7. **（范围外新发现）仓库根 `AGENTS.md:13`**：**不处理**。理由见「架构与边界」——该文件不在 `Intent.md` 已批准的 `templates/.themis/` 范围内，扩大范围需要新的 Intake/QA，design 节点不单方面决定。记录：该行当前写"`templates/.themis/AGENTS.md`] —— spec 控制面写作、与 `core/` 的关系"，是对 `templates/.themis/AGENTS.md` 内容的索引式描述；第 3 条决定生效、"与 `core/` 的关系"一节被删除后，这条索引描述会指代一个不存在的章节。这条遗留断链落在 SPEC-COREREMOVAL-001 判据范围（`templates/.themis/`）之外，不会被本次验收判据捕捉到——是判据覆盖范围与实际影响范围之间的一处已知缺口，不做任何处理（既不修，也不为了覆盖它而扩大判据范围），已记入漂移清单，交由所有者决定是否需要新一轮 Intake。

## 取舍

- **catalog.md 与根 AGENTS.md:13 不合并为同一类"开放决策点"**：catalog.md 是 `Intent.md` 已批准范围内、所有者主动要求延后的项；根 AGENTS.md:13 是范围外的新发现，处理它先要扩大范围（新 Intake），两者能否被处理的前提不同。取舍是把二者分开呈现（结构决策第 6、7 条分列），避免"唯一开放决策点是 catalog.md"这一表述因合并记录而失真。代价是 design-review.md 的投影需要多带一条说明，增加一点点评审负担，但换来的是不把范围外的发现悄悄归并进范围内的既有开放项，掩盖了它本不该在这次 R2 里被当成同类事项裁决。
- **CLAUDE.themis.md / README.md 只删字面路径行，不整体重写**：见「架构与边界」。代价是这两个文件删节后会残留大量描述 core 特有架构（Global Control Rule / Capability / Agent Profile / simple-full Complexity Assessment）却已经名不副实的叙述——`core/` 已删除，这些叙述描述的机制不复存在，但因未被字面 `core/` 路径命中，SPEC-COREREMOVAL-001 判据也检测不到。这是明确接受的已知限制，不是被忽略的问题：好处是不擅自扩大这次删除的处理范围；代价已记入漂移清单，供所有者判断是否要另开一次请求专门重写这两份文件。
- **spec/README.md 与 catalog.md 都选择不修改，而非顺手一起处理**：`spec/README.md` 不改是因为它是 replay 正依据的只读控制面的包源，擅自改动会违反"replay 期间不重装"的既有裁定；`catalog.md` 不改是因为所有者明确要求延后。两者外观相似（都是"发现问题但不修"），但理由不同，「结构决策」第 5、6 条分别单独说明理由，不合并成一条笼统的"暂不处理"。

## 事实依据

事实源分层判据见 `rules.md` §1，不复述其文字。以下命令均在本次任务执行时于工作树 `C:/Coding/Themis/.claude/worktrees/spec-flow-replay` 内真实运行，输出如实粘贴，作为本 step 结构决策的代码层依据。

**命令 1**：`find templates/.themis/core -type f | wc -l`
```text
98
```

**命令 2**：`git grep -n 'core/' -- templates/.themis/ | grep -v '\.themico/core' | grep -v '^templates/\.themis/core/'`（templates/.themis/ 范围内六处活跃引用点的完整命中）
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
共 14 行、覆盖 6 个引用点（AGENTS.md、CLAUDE.themis.md、README.md、spec/README.md、catalog.md 各一处，其中 AGENTS.md/CLAUDE.themis.md/README.md 内部各横跨多行/多列表项/多表格行）。

**命令 3**：`ls -la templates/.themis/core/protocols/context/references/catalog.md`（核验 `catalog.md:33` 目标当前存在）
```text
-rw-r--r-- 1 lin10 197609 2396  8月 19 15:41 templates/.themis/core/protocols/context/references/catalog.md
```

**命令 4**：`cat .gitignore`
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

**命令 5**：`git grep -n 'core/' -- . ':!templates/.themis/core' ':!.themis/core' ':!docs' | grep -v '\.themico\|internal/themico'`（超出 `templates/.themis/` 与 `docs/` 之外的全仓库重新清点，核对是否有第六处之外的遗漏活跃依赖）

真实剩余命中除已识别的 `.gitignore:8`、`templates/.themis/{AGENTS,CLAUDE.themis,README}.md`、`templates/.themis/spec/README.md`、`catalog.md:33`、以及本实例工件自身（`.themis/workspace/spec/core-removal/**`，属本次生成的记录，不是待处理引用）外，新发现两类命中：

1. **`AGENTS.md:13`**（仓库根）：`| `.themis` | [`templates/.themis/AGENTS.md`](templates/.themis/AGENTS.md) —— spec 控制面写作、与 `core/` 的关系 |` —— 真实活跃引用，落在 `templates/.themis/` 范围外，处理方式见「结构决策」第 7 条。
2. **`CHANGES.md:78`**：`- 初始化 `.themis` 模板目录结构（`core/` + `workspace/` 双命名空间）` —— 这是历史变更日志条目，描述的是"当时做了什么"这一过去事实，不对当前结构做任何陈述，性质与 `Intent.md`「非做」小节已排除的 `docs/` 下历史证据记录相同（虽然 `CHANGES.md` 不在 `docs/` 路径下）。删除 `core/` 不会让这条历史记录变假，判定为不需处理，比照既有的历史文档排除口径，不单独列为第 8 条结构决策。

其余命中（`CHANGES.md:41,81,82` 的 `docs/core/**`、`README.md:58,80,101` 的 `docs/plan/themico-core/**`）核实为误报：`docs/core/` 是另一套已归档的旧文档目录（与 `templates/.themis/core/` 无关），`docs/plan/themico-core/` 是 Themico 自己的实施计划目录（目录名恰好包含 `core` 子串，与本次删除对象无关）——两者均非活跃依赖，不入清点。
