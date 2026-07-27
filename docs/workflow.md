# Themis 完整工作流程

本文描述 Themis 从安装、需求进入、上下文加载、需求追问、规范与计划、任务实施、验证评审、交付结果、归因分析，到人机混合知识治理与后续升级的完整工作流程。

> 图中“已落地”表示当前仓库已有契约、模板、指引或脚本支持；“规划中”表示已进入后续设计但尚未形成可执行运行时。P5/P5.2 已提供 Prompt、策略、Spec v2 双视图、确定性校验/渲染/发布和人工批准证据；P8 尚未提供持久生命周期状态迁移执行器。缺少规划中能力时，Themis 必须停留在当前阶段并明确报告，不得虚构状态、证据或执行结果。

## 状态与所有权图例

| 标记 | 含义 |
|---|---|
| 已落地 | 当前已有模板契约、顶层指引、Init、Upgrade 或模块边界定义 |
| 规划中 | 已设计但尚未实现的自动化能力、Agent、Command、Skill 或确定性脚本 |
| Core | 定义规则、协议、策略和控制能力，不保存项目内容 |
| Workspace | 保存项目配置、上下文、Spec、Plan、状态、证据、结果与知识治理数据 |
| 人工门禁 | 需求批准、冲突裁决、知识提升、迁移授权等不能由模型自行越过的决策 |

## 项目事实可信边界

```text
受治理 Context → 项目应当是什么
当前代码/配置/Schema → 项目现在是什么
State/Run/Evidence → 流程与 Gate 发生了什么
Spec/Plan → 希望改变什么、准备如何改变
```

只有前两类能够支撑项目事实。Context 与代码冲突时产生持久 `context_code_drift` Signal；Spec、Plan、Evidence、Outcome、对话、摘要或 Agent 推断不得替它们静默选边。Context Resolution 按 `Catalog → L1 → L2 → L3 → 当前代码` 装配可追溯 Bundle，Bundle 和 Cache 都不是新的事实源。

## 端到端总流程

```mermaid
flowchart TD
    START([用户或项目发起工作])

    subgraph INSTALL[安装与加载边界 · 已落地]
        I0{项目是否已经安装 Themis?}
        I1[Init 校验 Bash、Git 与 mikefarah/yq v4]
        I2[校验源模板契约]
        I3[复制 templates/.themis 到项目 .themis]
        I4[写入 Workspace manifest 项目配置]
        I5[向项目 CLAUDE.md 追加受管 import]
        I6[项目加载 Themis Guidance 与 Orchestrator]
        IF[Init 失败：回滚本次修改]
    end

    subgraph ROUTING[请求识别与 Context Resolution · P5.4 设计]
        R0{是否为受管理的项目变更?}
        R1[只读解释、调查或研究]
        R2[Orchestrator 读取持久工件与流程状态]
        R3[提取 Context ID、domain、entity、operation 与 state]
        R31[Catalog 过滤并按 L1 → L2 → L3 渐进加载]
        R32[按声明类型读取当前代码、配置与 Schema]
        R4{Context 与代码是否完整且一致?}
        R5[持久化 missing/stale/conflict/drift Signal 并请求处置]
        R6[生成可追溯 Context Bundle]
    end

    subgraph SPEC[Draft → Specified 证据契约]
        S0[创建或继续 Draft Spec]
        S1[Step 0：意图发现与根因确认 · P5]
        S2[Step 1：范围、Pre-mortem 与复杂度确认 · P5]
        S3[Step 2：上下文、约束、证据与 Option Zero · medium/high · P5]
        S4[Step 3：方案取舍与分段 Acceptance Criteria · P5]
        S5[Step 4：对抗验证 · P5]
        S6[写入临时 spec.yaml candidate，并由 publisher 生成 canonical pair]
        S7[Spec validator：结构、引用、readiness 与 projection OID]
        S8{用户是否明确批准 Draft Spec?}
        S9[记录批准证据；Spec 仍保持 Draft]
        S10[[P8 规划中：校验 Gate 并记录 Specified 状态]]
        S11([P8 未实施：停止于 Draft，不得进入 Planning])
    end

    subgraph PLAN[Specified → Planned]
        P0[Planning 读取已验证的 spec.yaml、validator JSON 与 Context]
        P1[Behavior Map 逐层定位行为与代码 · P6 规划中]
        P2[拆分会话级 Task、依赖 DAG 与完成标准]
        P3[建立 AC → Task → 代码位置 → Gate 追踪]
        P4[写入 workspace/specs/spec-id/plan.md]
        P5{AC 覆盖、依赖、粒度和证据要求是否完整?}
        P6[[记录 Planned 状态迁移]]
    end

    subgraph IMPLEMENT[Planned → Implemented]
        T0[选择依赖已满足的当前 Task]
        T1[仅加载当前 Task 所需 AC、约束与代码]
        T2[实施限定范围内的代码或文档变更]
        T3[保存 Task evidence 与执行状态]
        T4{Task 完成标准与证据是否满足?}
        T5{Plan 是否仍足够且未超出 Spec?}
        T6{还有未完成 Task?}
        T7[[记录 Implemented 状态迁移]]
    end

    subgraph VERIFY[Implemented → Verified]
        V0[Verification 读取 Gate 与有效策略]
        V1[通过 Adapter 执行 Lint、Build、Test 等 Gate]
        V2[保存 workspace/runs 与 workspace/evidence]
        V3[分类瞬态、代码、配置或策略失败]
        V4{Verdict}
        V5[按策略重试]
        V6[请求运维或人工解决]
        V7[[记录 Verified 状态迁移]]
    end

    subgraph REVIEW[Verified → Reviewed]
        W0[Review 只读检查 Spec、Plan、Diff 与证据]
        W1[记录 correctness、安全、性能、维护性等发现]
        W2[写入 review.md 与 review evidence]
        W3{评审结果}
        W4[[记录 Reviewed 状态迁移]]
    end

    subgraph OUTCOME[交付、结果与归因]
        O0[交付或部署]
        O1[记录 success、rework、defect、incident 或 rollback]
        O2[Attribution 关联 Spec、Task、Commit、Run、部署与 Outcome]
        O3[分析返工、缺陷逃逸和验证薄弱点]
    end

    subgraph KNOWLEDGE[人机混合知识治理]
        K0[AI 从执行、失败、评审和 Outcome 提取知识候选]
        K1[写入 workspace/knowledge/candidates]
        K2[去重、事实锚定与冲突检查]
        K3{人工或受治理审核}
        K4[Promote：提升为正式 Context]
        K5[Reject：写入 rejected]
        K6[Revise：修改后重新提交]
        K7[原子更新 L3 Context Item 与 catalog.yaml]
        K8[Context Freshness 检测过期知识或 Behavior Map]
        K9{确认已过期?}
        K10[归档到 workspace/knowledge/archive]
    end

    A0{归档条件是否全部满足?}
    A1[[记录 Archived 状态迁移]]
    NEXT([后续需求复用更新后的 Context])

    START --> I0
    I0 -- 否 --> I1
    I1 --> I2
    I2 --> I3
    I3 --> I4
    I4 --> I5
    I5 --> I6
    I1 -. 失败 .-> IF
    I2 -. 失败 .-> IF
    I3 -. 失败 .-> IF
    I4 -. 失败 .-> IF
    I5 -. 失败 .-> IF
    I0 -- 是 --> I6

    I6 --> R0
    R0 -- 否 --> R1
    R1 --> NEXT
    R0 -- 是或不确定 --> R2
    R2 --> R3 --> R31 --> R32 --> R4
    R4 -- 否或未知 --> R5
    R5 --> R3
    R4 -- 是或职责互补 --> R6 --> S0

    S0 --> S1
    S1 --> S2
    S2 --> S3
    S3 --> S4
    S4 --> S5
    S5 --> S6
    S6 --> S7
    S7 -- 不通过 --> S4
    S7 -- 通过 --> S8
    S8 -- 否，修订 --> S4
    S8 -- 是，人工门禁 --> S9
    S9 --> S10
    S10 -. 未实施 .-> S11
    S10 -- 已实施且 Gate 通过 --> P0
    P0 --> P1
    P1 --> P2
    P2 --> P3
    P3 --> P4
    P4 --> P5
    P5 -- 否 --> P2
    P5 -- 是 --> P6

    P6 --> T0
    T0 --> T1
    T1 --> T2
    T2 --> T3
    T3 --> T4
    T4 -- 否 --> T2
    T4 -- 是 --> T5
    T5 -- Plan 不足但仍在 Spec 内 --> P0
    T5 -- 超出已批准 Spec --> S0
    T5 -- 足够 --> T6
    T6 -- 是 --> T0
    T6 -- 否 --> T7

    T7 --> V0
    V0 --> V1
    V1 --> V2
    V2 --> V3
    V3 --> V4
    V4 -- 瞬态失败 --> V5
    V5 --> V1
    V4 -- 代码失败 --> T0
    V4 -- 配置或策略问题 --> V6
    V6 --> V0
    V4 -- 证据不足 --> T3
    V4 -- Pass --> V7

    V7 --> W0
    W0 --> W1
    W1 --> W2
    W2 --> W3
    W3 -- changes requested --> T0
    W3 -- blocked --> R5
    W3 -- approved --> W4

    W4 --> O0
    O0 --> O1
    O1 --> O2
    O2 --> O3
    O3 --> K0
    W1 -. 评审模式 .-> K0
    V3 -. 失败陷阱 .-> K0
    T3 -. 执行经验 .-> K0

    K0 --> K1
    K1 --> K2
    K2 --> K3
    K3 -- promote --> K4
    K3 -- reject --> K5
    K3 -- revise --> K6
    K6 --> K1
    K4 --> K7
    K7 --> K8
    K8 --> K9
    K9 -- 否 --> A0
    K9 -- 是，人工确认 --> K10
    K10 --> K7
    K5 --> A0

    A0 -- 否 --> K0
    A0 -- 是 --> A1
    A1 --> NEXT
    NEXT --> R0

    classDef current fill:#e8f3ec,stroke:#247047,color:#153b28;
    classDef planned fill:#fff4d6,stroke:#9a6b00,color:#4f3800,stroke-dasharray:5 3;
    classDef human fill:#f8e8ef,stroke:#9d3f68,color:#4f2035;
    classDef data fill:#e8effa,stroke:#315f9b,color:#173453;

    class I0,I1,I2,I3,I4,I5,I6,IF,R0,R1,R2,R3,R4,R5,S0,S1,S2,S3,S4,S5,S6,S7,S8,S9,P0,P2,P3,P4,P5,P6,T0,T1,T2,T3,T4,T5,T6,T7,V0,V1,V2,V3,V4,V5,V6,V7,W0,W1,W2,W3,W4,O0,O1,O2,O3,K0,K1,K2,K3,K4,K5,K6,K7,K8,K9,K10,A0,A1,NEXT current;
    class S10,S11,P1 planned;
    class S8,K3,K9 human;
    class S6,S9,P4,T3,V2,W2,O1,K1,K7,K10 data;
```

## 生命周期与工件

当前默认生命周期采用：

```text
Draft → Specified → Planned → Implemented → Verified → Reviewed → Archived
```

| 阶段 | 控制模块 | 主要门禁 | Workspace 持久工件 |
|---|---|---|---|
| Draft | Orchestrator、Specification、Context | P5 追问、对抗验证、批准证据与八项 validator check；P8 前不记录状态迁移 | `specs/<spec-id>/spec.yaml` 权威 Draft、`spec.md` Human 投影 |
| Specified | P8 状态执行器（规划中） | 复用 P5.2 readiness JSON 并记录迁移，不重写 Spec 校验逻辑 | 已验证 Spec pair、`state/transitions/`（P8） |
| Planned | Planning | AC 全覆盖、Task DAG 合法、证据要求明确 | `plan.md`、`state/tasks/` |
| Implemented | Orchestrator、实施者 | 全部 Task 满足完成标准并有证据 | 项目源码、Task evidence、会话状态 |
| Verified | Verification | 所有阻塞 Gate 通过且证据充分 | `runs/<run-id>/`、`evidence/`、`verify.md` |
| Reviewed | Review | 无未解决的 critical/major 问题，评审证据完整 | `review.md`、`evidence/review/` |
| Archived | Orchestrator、Knowledge | Outcome 与知识处理完成，无阻塞项 | `outcomes/`、知识治理记录、迁移历史 |

> P8 的待实施设计中曾采用“Review → Verification”的顺序，但当前 Guidance、Orchestrator 与 Workspace 文档均以“Verification → Review”为基线。在 P8 实施设计明确解决该差异前，本流程遵循当前基线。

## 规划与变更定位流程

Planning 只定义和校验 Plan，不执行 Task；Behavior Map 只提供事实锚定的建议性定位依据，不直接修改代码、扩展 Plan 或形成 Gate verdict。

P6 使用以下契约，但仍处于规划状态：

- Context 拥有代码派生数据的生成治理、存储、冲突报告和新鲜度；语言 Adapter 只输出受支持的确定性事实；
- B1 描述系统和生命周期，B2 描述行为单元，B3 描述绑定 revision 的路径、符号、分支、副作用和 Evidence Anchor；
- 每个事实声明必须关联路径、符号、源码范围、revision/digest、提取方式和置信度；
- 新鲜度为 `current`、`stale`、`unknown`、`unsupported`；非 `current` 内容必须回退源码检查；
- 定位结果为 `AC → Behavior Unit → Candidate File/Symbol → Task → Gate`，候选包含角色、理由、锚点、revision、置信度和未决区域；
- Verification 可使用 Anchor 发现相关检查，但 Anchor 和 Behavior Map 本身不是 Evidence 或 verdict。

完整设计契约见 [P6 Behavior Map](plan/60-behavior-map/README.md)。

```mermaid
flowchart LR
    AC[已批准 Acceptance Criteria]

    subgraph BM[Behavior Map · P6 规划中]
        B1[System Context<br/>整体架构与请求生命周期]
        B2[Behavior Unit<br/>行为单元职责与状态]
        B3[Code Evidence<br/>文件、函数、调用路径与锚点]
    end

    CTX[人工维护 Context<br/>架构、领域、ADR、规则、陷阱]
    LOC[Planning 只读定位变更边界]
    TASK[拆分 Task 与依赖 DAG]
    TRACE[Traceability<br/>AC → Behavior Unit → Code Location → Task → Gate]
    PLAN[workspace/specs/spec-id/plan.md]
    CHECK{Plan Validation}
    READY[进入 Planned]
    REVISE[修订 Task、依赖或证据要求]

    AC --> B1 --> B2 --> B3
    CTX --> LOC
    B3 --> LOC
    AC --> LOC
    LOC --> TASK --> TRACE --> PLAN --> CHECK
    CHECK -- 不通过 --> REVISE --> TASK
    CHECK -- 通过 --> READY

    classDef planned fill:#fff4d6,stroke:#9a6b00,color:#4f3800,stroke-dasharray:5 3;
    classDef data fill:#e8effa,stroke:#315f9b,color:#173453;
    class B1,B2,B3 planned;
    class CTX,PLAN data;
```

### Behavior Map 的事实生成与刷新

```mermaid
flowchart TD
    SRC[受 manifest 限定的源码、配置、Schema 与构建元数据]
    ADAPTER[语言 Adapter<br/>按能力矩阵提取确定性事实]
    INVENTORY[Symbol Inventory + Relation Graph]
    CLASSIFY[AI 辅助行为归类与说明]
    ANCHOR[Anchor lint<br/>每条事实关联 revision/digest]
    MAP[B1/B2/B3 + Anchor Index<br/>写入 behavior-map]
    USE[Context 与 Planning 按需使用<br/>Verification 仅发现检查]
    CHANGE[Anchor 或相关依赖变化]
    FRESH{Freshness 判定}
    REGEN{是否手动重生成?}
    SOURCE[回退直接源码检查]

    SRC --> ADAPTER --> INVENTORY --> CLASSIFY --> ANCHOR
    ANCHOR -- 失败 --> CLASSIFY
    ANCHOR -- 通过 --> MAP --> USE
    USE --> CHANGE --> FRESH
    FRESH -- current --> USE
    FRESH -- stale --> REGEN
    FRESH -- unknown / unsupported --> SOURCE
    REGEN -- 是 --> ADAPTER
    REGEN -- 否 --> SOURCE

    classDef planned fill:#fff4d6,stroke:#9a6b00,color:#4f3800,stroke-dasharray:5 3;
    class ADAPTER,INVENTORY,CLASSIFY,ANCHOR,MAP,FRESH,REGEN planned;
```

首版计划采用“手动触发重生成 + 四态新鲜度”，不承诺全自动增量同步。Behavior Map 是可重新生成的 Context 派生数据；缺失、过期、未知或 Adapter 不支持时必须回退源码检查，且不得把低置信度推断伪装成事实。Map 只参与定位和检查发现，不取代 Spec、Plan、Evidence 或 Verification verdict。

## 人机混合知识记录与治理

正式项目知识只有一个权威位置：`workspace/context/`。`workspace/knowledge/` 保存候选、审核、拒绝和归档等治理过程，不形成第二套正式知识库。

```mermaid
flowchart TD
    E1[Task 实施经验]
    E2[Verification 失败与证据]
    E3[Review 发现]
    E4[Outcome 与 Attribution 分析]
    E5[人工新增架构、领域、ADR、规则或陷阱]

    AI[AI 提取并结构化知识候选]
    HUMAN_DRAFT[人工直接提交知识候选]
    CAND[workspace/knowledge/candidates]
    DEDUP[与正式 Context 和其他候选去重]
    CONFLICT[冲突检查与事实来源核验]
    REVIEW{人工或受治理审核}
    PROMOTE[提升]
    REJECT[拒绝]
    REVISE[修改后重审]

    subgraph AUTH[workspace/context · 正式权威知识]
        ARCH[architecture<br/>含 Behavior Map]
        DOMAIN[domain]
        ENG[engineering]
        ADR[decisions / ADR]
        PIT[pitfalls]
        GLOSS[glossary]
    end

    INDEX[原子更新 L3 Context Item 与 Catalog]
    FRESH[Context Freshness 检测]
    STALE{知识是否过期或与代码冲突?}
    DEP_REVIEW{人工确认废弃?}
    ARCHIVE[workspace/knowledge/archive]
    NEXT[后续 Spec 与 Plan 读取更新后的 Context]

    E1 --> AI
    E2 --> AI
    E3 --> AI
    E4 --> AI
    AI --> CAND
    E5 --> HUMAN_DRAFT --> CAND
    CAND --> DEDUP --> CONFLICT --> REVIEW
    REVIEW -- promote --> PROMOTE
    REVIEW -- reject --> REJECT
    REVIEW -- revise --> REVISE --> CAND

    PROMOTE --> ARCH
    PROMOTE --> DOMAIN
    PROMOTE --> ENG
    PROMOTE --> ADR
    PROMOTE --> PIT
    PROMOTE --> GLOSS

    ARCH --> INDEX
    DOMAIN --> INDEX
    ENG --> INDEX
    ADR --> INDEX
    PIT --> INDEX
    GLOSS --> INDEX
    INDEX --> NEXT
    INDEX --> FRESH --> STALE
    STALE -- 否 --> NEXT
    STALE -- 是 --> DEP_REVIEW
    DEP_REVIEW -- 否，继续有效 --> NEXT
    DEP_REVIEW -- 是 --> ARCHIVE --> INDEX

    classDef human fill:#f8e8ef,stroke:#9d3f68,color:#4f2035;
    classDef data fill:#e8effa,stroke:#315f9b,color:#173453;
    class REVIEW,DEP_REVIEW,E5,HUMAN_DRAFT human;
    class CAND,ARCH,DOMAIN,ENG,ADR,PIT,GLOSS,ARCHIVE,INDEX data;
```

### 人与 AI 的职责边界

| 环节 | AI 可执行 | 必须由人工或治理门禁确认 |
|---|---|---|
| 候选发现 | 从执行、验证、评审和 Outcome 中提取模式 | 可补充遗漏或直接提交候选 |
| 结构化 | 生成标题、类型、来源、证据引用和建议归类 | 确认内容没有误解业务语义 |
| 去重与冲突 | 检索相似记录、标记潜在冲突 | 决定哪一条事实有效以及是否合并 |
| 提升 | 根据审核结果执行移动和索引更新 | 决定 `promote`、`reject` 或 `revise` |
| 废弃 | 根据代码变化和新鲜度标记提出候选 | 确认知识确实不再适用 |
| 正式 Context | 可读取并引用 | 未经审核不得直接写入观察性结论 |

## 验证、评审与返工闭环

```mermaid
flowchart TD
    DONE[Task 全部完成且证据齐全]
    GATES[Verification 执行确定性 Gate]
    VERDICT{Verdict}
    TRANSIENT[瞬态失败：按策略重试]
    CODE[代码失败：返回当前 Task 修复]
    CONFIG[配置失败：请求运维或人工处理]
    POLICY[策略冲突：停止并请求裁决]
    INCONCLUSIVE[证据不足：补充 Evidence]
    VERIFIED[记录 Verified]
    REVIEW[只读 Review]
    RESULT{Review Result}
    FIX[修复评审发现]
    RERUN[代码变化使旧证据失效]
    REVIEWED[记录 Reviewed]

    DONE --> GATES --> VERDICT
    VERDICT -- pass --> VERIFIED --> REVIEW --> RESULT
    VERDICT -- transient --> TRANSIENT --> GATES
    VERDICT -- code failure --> CODE --> RERUN --> GATES
    VERDICT -- configuration --> CONFIG --> GATES
    VERDICT -- policy conflict --> POLICY --> GATES
    VERDICT -- inconclusive --> INCONCLUSIVE --> GATES
    RESULT -- approved --> REVIEWED
    RESULT -- changes requested --> FIX --> RERUN
    RESULT -- blocked --> POLICY
```

任何代码变更都会使之前的验证证据失效，必须重新执行相关 Gate。Review 不能以主观信心代替 Verification 的命令输出；证据不足只能得到 `inconclusive` 或 `blocked`，不能得到通过。

## Themis 源仓库自身的计划执行协议

`docs/plan/` 管理的是 Themis 框架本身的模块计划，与安装后项目在 `workspace/specs/<spec-id>/plan.md` 中保存的工程 Plan 不同。

```mermaid
flowchart TD
    IDEA[新增 Themis 能力提案]
    README[创建 docs/plan/priority-slug/README.md]
    WAIT[等待用户主动发起]
    START[用户明确要求 impl 某计划]
    IMPL[第一步：创建或更新同目录 impl.md]
    DETAIL[记录设计决策、任务拆分、目标文件与验证矩阵]
    APPROVE{用户是否确认 impl.md?}
    BUILD[修改该计划涉及的实现文件]
    VERIFY[执行计划定义的验证矩阵]
    RECORD[更新计划状态与实施记录]

    IDEA --> README --> WAIT --> START --> IMPL --> DETAIL --> APPROVE
    APPROVE -- 否 --> IMPL
    APPROVE -- 是 --> BUILD --> VERIFY --> RECORD
```

计划文档不是实现授权；`impl.md` 未经确认前不得修改目标实现文件。

## 安装与升级维护流程

```mermaid
flowchart TD
    ENTRY{目标项目状态}

    subgraph INIT[Init · 已落地]
        NEW[不存在 .themis]
        ENV[校验 Bash、Git、yq]
        SOURCE[校验源模板]
        COPY[复制完整模板]
        CONFIG[写入项目名与命令配置]
        IMPORT[追加 CLAUDE.md 受管 import]
        VALIDATE[按 installed 模式校验]
        ROLLBACK[失败时回滚本次修改]
    end

    subgraph UPGRADE[Upgrade · 已落地]
        EXIST[已存在 .themis]
        PREFLIGHT[校验已安装与候选元数据]
        COMPAT{Workspace 与 Artifact Schema 是否直接兼容?}
        DRY{是否 dry-run?}
        BACKUP[持久备份非 Workspace 受管内容]
        REPLACE[仅替换 .themis 中 workspace 之外的内容]
        CHECK[校验 Workspace 与 CLAUDE.md 指纹未变]
        RESTORE[失败时恢复旧受管内容]
        MIGRATE[显式 Workspace/Artifact 迁移 · 已落地]
    end

    ENTRY -- 新项目 --> NEW --> ENV --> SOURCE --> COPY --> CONFIG --> IMPORT --> VALIDATE
    ENV -. 失败 .-> ROLLBACK
    SOURCE -. 失败 .-> ROLLBACK
    COPY -. 失败 .-> ROLLBACK
    CONFIG -. 失败 .-> ROLLBACK
    IMPORT -. 失败 .-> ROLLBACK
    VALIDATE -. 失败 .-> ROLLBACK

    ENTRY -- 已安装 --> EXIST --> PREFLIGHT --> COMPAT
    COMPAT -- 是 --> DRY
    DRY -- 是 --> PREFLIGHT
    DRY -- 否 --> BACKUP --> REPLACE --> CHECK
    REPLACE -. 失败 .-> RESTORE
    CHECK -. 失败 .-> RESTORE
    COMPAT -- 有迁移描述符但不直接兼容 --> MIGRATE
    COMPAT -- 不支持 --> STOP[拒绝升级并给出诊断]

```

Init 只用于尚未安装 Themis 的项目；Upgrade 不加载 Init 环境校验，也绝不复制、删除、修改或恢复 `.themis/workspace/`。当前首次发布原生使用 Artifact v2，不提供 Artifact v1 兼容或迁移能力。未来出现 Workspace 或 Artifact Schema 演进时，独立的 `themis-migrate.sh` 仍必须要求显式用户授权、持久备份、验证与回滚；Upgrade 只安装受支持的 Core，绝不自动迁移 Workspace。

## 当前实现边界

| 能力 | 当前状态 |
|---|---|
| P0 Init 环境校验 | 已落地 |
| P1 模板、Schema、版本和目录契约 | 已落地 |
| P2 顶层 Guidance 与生命周期路由规则 | 已落地 |
| P3 Init 安装与失败回滚 | 已落地 |
| P4 非 Workspace 受管内容升级、备份与回滚 | 已落地 |
| P5 自适应需求追问、Spec v2 双视图、确定性 lint/render/publish 与批准证据 | 已落地；持久 `Specified` 状态迁移留待 P8 |
| P6 Behavior Map、事实提取与变更定位 | 规划中，仅目录占位已存在 |
| P7 跨模块集成审计 | 分析已完成，不是运行时执行层 |
| P8 专用 Agent、Command、Skill 与确定性 SDD 脚本 | 规划中，尚未实施 |
| 自动 Attribution、知识提升和废弃执行器 | 仅有架构与边界定义，尚未实施 |
| Workspace 与 Artifact Schema 迁移执行器 | 通用显式迁移基础设施已落地；当前原生 Artifact v2 不声明 Artifact migration，未来 Schema 演进仍须独立授权执行 |

## 关键不变规则

1. Core 定义能力，不保存项目内容。
2. Workspace 保存项目内容，不实现控制逻辑。
3. 生命周期状态以持久工件、机器状态和证据为准，不以对话声明为准。
4. 未批准 Spec 不进入实施；未满足证据门禁不声明 Task 完成。
5. 缺少证据不是成功证据；无法验证不能判定通过。
6. Review 只读，Verification 只陈述 Gate 事实，Attribution 只记录关联关系。
7. AI 可生成知识候选，但未经审核不得直接写入正式 Context。
8. Upgrade 绝不覆盖 Workspace；Schema 迁移必须显式授权。
9. 规划中的 Agent、Command、Skill 或 Shell 执行器在文件不存在时不得假定可用。

## 相关文档

- [Orchestrator](core/kernel/orchestrator.md)
- [Specification](core/kernel/specification.md)
- [Planning](core/kernel/planning.md)
- [Context](core/kernel/context.md)
- [Verification](core/kernel/verification.md)
- [Review](core/kernel/review.md)
- [Attribution](core/kernel/attribution.md)
- [Knowledge](core/kernel/knowledge.md)
- [Workspace 概述](workspace/overview.md)
- [实施计划索引](plan/README.md)
- [P5 需求追问](plan/50-requirement-questioning/README.md)
- [P6 Behavior Map](plan/60-behavior-map/README.md)
- [P8 多 Agent 架构](plan/80-multi-agent-architecture/README.md)
