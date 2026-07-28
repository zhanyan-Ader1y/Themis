# Themis 加载链与阶段资产映射分析

> **2026-07-28 更新说明**：本文的启动、Planning 及后续阶段分析继续有效；Specification 章节已按 P5.3 更新为 Project Skill `Themis-Q` 的提问方法、Specification 工作流与无版本 Spec 最终语义链。旧 `spec-questioning.md` / `spec-adversarial-checklist.md` 已退役。

本文以项目 agent 视角，追踪 Themis 从启动到各 SDD 阶段的完整 Prompt、YAML、Shell 脚本读取顺序，并标记结构性问题与增强建议。

> 分析基准：Themis 0.4.0（P5.3 `Themis-Q`、Artifact v2 下无版本 Spec 双视图与最终语义 readiness 已落地；P6/P8 状态执行层及后续能力尚未实施）。

## 图例

| 符号 | 含义 |
|---|---|
| `@import` 实线 | 启动时自动加载，agent 无需主动读取 |
| `Read` 虚线 | agent 必须显式读取，依赖规则中的文本指引 |
| `Write` 点线 | agent 输出工件 |
| 🔴 | 结构性缺陷 |
| 🟡 | 设计上需注意 |
| 🟢 | 已满足要求 |

---

## 一、Agent 启动：基线加载

```mermaid
flowchart TD
    CLAUDE_MD["① 项目根 CLAUDE.md<br/>含 Init 追加的受管 import 块"]
    GUIDANCE["② .themis/CLAUDE.themis.md<br/>跨阶段边界 · Source of Truth · Lifecycle Routing · Key Paths"]
    ORCH["③ .themis/core/kernel/orchestrator/rules.md<br/>Operating Contract · Authority Order ·<br/>Artifact-First Routing · Safe Degradation · Non-Bypass"]
    SPEC_RULES["④ specification/rules.md<br/>职责 · 输入输出 · 边界 ·<br/>P5 追问路由指引"]
    PLAN_RULES["⑤ planning/rules.md<br/>职责 · 输入输出 · 边界"]
    CTX_RULES["⑥ context/rules.md<br/>职责 · 输入输出 · 边界"]
    VERIFY_RULES["⑦ verification/rules.md<br/>职责 · 输入输出 · 边界"]
    REVIEW_RULES["⑧ review/rules.md<br/>职责 · 输入输出 · 边界"]
    KNOWL_RULES["⑨ knowledge/rules.md<br/>职责 · 输入输出 · 边界"]
    ATTR_RULES["⑩ attribution/rules.md<br/>✅ 已接入 @import 图<br/>职责 · 输入输出 · 边界"]

    CLAUDE_MD -->|"@import（自动）"| GUIDANCE
    CLAUDE_MD -->|"@import（自动）"| ORCH
    ORCH -->|"@import（自动）"| SPEC_RULES
    ORCH -->|"@import（自动）"| PLAN_RULES
    ORCH -->|"@import（自动）"| CTX_RULES
    ORCH -->|"@import（自动）"| VERIFY_RULES
    ORCH -->|"@import（自动）"| REVIEW_RULES
    ORCH -->|"@import（自动）"| KNOWL_RULES
    ORCH -->|"@import（自动）"| ATTR_RULES

    classDef auto fill:#e8f3ec,stroke:#247047,color:#153b28;
    classDef broken fill:#fce4e4,stroke:#b91c1c,color:#7f1d1d;
    class CLAUDE_MD,GUIDANCE,ORCH,SPEC_RULES,PLAN_RULES,CTX_RULES,VERIFY_RULES,REVIEW_RULES,KNOWL_RULES,ATTR_RULES auto;
    classDef broken fill:#fce4e4,stroke:#b91c1c,color:#7f1d1d;
```

**关键事实**：启动阶段全部 9 个文件通过 `@import` 链一次性加载。这是唯一有结构性保证的加载层。之后每个阶段的 Prompt、YAML 策略、脚本都需要 agent 显式 `Read`。

---

## 二、Specification（Draft）：Themis-Q 与 Spec 加载链

这是当前 Themis 唯一具有 Project Skill + YAML 策略 + 确定性 executor 的阶段。

```mermaid
flowchart TD
    RULES["specification/rules.md<br/>已通过 @import 常驻内存"]
    CLARIFY{"当前请求仍有重要不确定性?"}
    SKILL[".claude/skills/Themis-Q/SKILL.md<br/>提问方式 · 覆盖范围 · 收敛摘要"]
    POLICY["core/policies/specification.yaml<br/>复杂度 · 对抗策略 · semantic consistency"]
    ADV_LIB["Themis-Q/references/adversarial-checklist.md<br/>快速检查 · 六维攻击场景"]
    CONTEXT["workspace/context/ + 既有 Specs + 当前代码<br/>事实核验"]
    SUMMARY{"用户确认 Specification 的规范化摘要?"}
    STOP["停留 Specification<br/>不创建 candidate"]
    CANDIDATE["workspace/cache/spec-candidates/spec-id.yaml<br/>唯一 candidate"]
    PROTOCOL["core/protocols/artifact/v2/<br/>无版本 Spec schema + projection"]
    EXECUTOR["specification/themis-spec.sh<br/>validate · render · publish · pair rollback"]
    TRANSITIONS["core/policies/transitions.yaml<br/>draft_to_specified · 8 个 validator check ID"]

    RULES --> CLARIFY
    CLARIFY -- "是" --> SKILL
    SKILL -->|"按需读取"| ADV_LIB
    SKILL --> CONTEXT
    CLARIFY -- "否" --> CONTEXT
    CONTEXT --> POLICY
    POLICY --> SUMMARY
    SUMMARY -- "拒绝/调整" --> CLARIFY
    SUMMARY -- "确认" --> CANDIDATE
    SKILL -. "缺失/调用失败" .-> STOP
    CANDIDATE --> PROTOCOL
    PROTOCOL --> EXECUTOR
    EXECUTOR -->|"readiness JSON"| TRANSITIONS

    classDef auto fill:#e8f3ec,stroke:#247047,color:#153b28;
    classDef manual fill:#fff4d6,stroke:#9a6b00,color:#4f3800,stroke-dasharray:5 3;
    classDef broken fill:#fce4e4,stroke:#b91c1c,color:#7f1d1d;
    classDef output fill:#e8effa,stroke:#315f9b,color:#173453;
    class RULES auto;
    class SKILL,POLICY,ADV_LIB,CONTEXT,PROTOCOL,EXECUTOR,TRANSITIONS manual;
    class CLARIFY,SUMMARY broken;
    class STOP broken;
    class CANDIDATE output;
```

### 已修复：软 Prompt 依赖与边追问边持久化

Specification 不再读取 Core questioning Prompt。`rules.md` 要求在当前请求需要澄清时通过 Skill 工具调用精确名称 `Themis-Q`；Skill 缺失或调用失败时 fail closed，不创建 candidate。

`Themis-Q` 只提供一次一问、适应性深度、需求覆盖、假设挑战、Acceptance Criteria 和对抗问题指导。Specification 读取 `specification.yaml`、相关 Context、既有 Specs 与必要代码，负责复杂度、收敛、规范化摘要、用户确认和唯一 candidate 创建；Skill 不定义执行上下文、持久化或 handoff。

| 资产 | 加载方式 | 边界 |
|---|---|---|
| `Themis-Q/SKILL.md` | Specification 通过 Skill 工具调用 | 提问方法与覆盖范围；不定义流程或 artifact |
| `specification.yaml` | Specification 与 executor 显式读取 | 复杂度、攻击深度、semantic consistency |
| `references/adversarial-checklist.md` | Skill 按需读取 | quick/focused/comprehensive 场景库 |
| Context/既有 Specs/代码 | Specification 核验 | 需求证据，不提升 Context |
| `spec-schema.yaml` / `spec-projection.yaml` | Specification/executor 读取 | 无版本 Spec 字段、稳定引用、Human 投影与漂移 |
| `themis-spec.sh` | 用户确认后调用 | candidate 验证、渲染、事务发布；不进行追问 |
| `transitions.yaml` | validator JSON 消费方读取 | 八个稳定 transition evidence ID |

---

## 三、Planning 加载链

```mermaid
flowchart TD
    RULES["planning/rules.md<br/>已通过 @import 常驻内存"]
    SPEC["workspace/specs/spec-id/spec.yaml<br/>已验证的权威 Spec"]
    CTX["workspace/context/<br/>架构 · 领域 · 工程 · ADR · 陷阱"]
    PLAN_OUT["workspace/specs/spec-id/plan.md<br/>Task 拆分 · 依赖 · AC 追踪"]

    RULES --> SPEC
    SPEC --> CTX
    CTX --> PLAN_OUT

    GAP["🟡 无 Prompt 模板<br/>🟡 无 YAML 策略<br/>🟡 无 Shell 脚本<br/>🟡 Task 模型、DAG、Traceability<br/>全部留给后续能力"]

    classDef auto fill:#e8f3ec,stroke:#247047,color:#153b28;
    classDef output fill:#e8effa,stroke:#315f9b,color:#173453;
    classDef gap fill:#fff4d6,stroke:#9a6b00,color:#4f3800;
    class RULES auto;
    class SPEC,CTX auto;
    class PLAN_OUT output;
    class GAP gap;
```

---

## 四、Implementation 加载链

```mermaid
flowchart TD
    ORCH["Orchestrator Artifact-First Routing<br/>已通过 @import 常驻内存"]
    SPEC["workspace/specs/spec-id/spec.yaml<br/>批准范围与稳定 ID"]
    PLAN["workspace/specs/spec-id/plan.md<br/>当前 Task"]
    SRC["项目源代码"]
    EVIDENCE["workspace/evidence/<br/>Task 执行记录"]

    ORCH --> SPEC
    SPEC --> PLAN
    PLAN --> SRC
    SRC --> EVIDENCE

    GAP["🟡 Implementation 无独立 kernel 模块<br/>🟡 由 Orchestrator 简短规则直接描述<br/>🟡 'one bounded task at a time'<br/>🟡 无 Prompt · 无策略 · 无脚本"]

    classDef auto fill:#e8f3ec,stroke:#247047,color:#153b28;
    classDef output fill:#e8effa,stroke:#315f9b,color:#173453;
    classDef gap fill:#fff4d6,stroke:#9a6b00,color:#4f3800;
    class ORCH auto;
    class SPEC,PLAN,SRC auto;
    class EVIDENCE output;
    class GAP gap;
```

---

## 五、Verification 加载链

```mermaid
flowchart TD
    RULES["verification/rules.md<br/>已通过 @import 常驻内存"]
    MANIFEST["workspace/manifest.yaml<br/>commands.lint · commands.build · commands.test<br/>gates 列表"]
    COMMANDS{"commands 是否<br/>全部为 null？"}
    EXEC["执行配置的命令<br/>收集输出"]
    OUTPUT["workspace/runs/run-id/<br/>workspace/evidence/"]
    STOP["🔴 停止：无可用命令<br/>'Do not invent a default command'<br/>但规则未说明接下来该做什么"]

    RULES --> MANIFEST
    MANIFEST --> COMMANDS
    COMMANDS -- "有值" --> EXEC
    COMMANDS -- "null" --> STOP
    EXEC --> OUTPUT

    GAP["🟡 无 Prompt 模板<br/>🟡 无 YAML 策略<br/>🟡 无 Shell 脚本<br/>🟡 Gate 执行、失败分类、重试策略<br/>全部留给后续能力"]

    classDef auto fill:#e8f3ec,stroke:#247047,color:#153b28;
    classDef output fill:#e8effa,stroke:#315f9b,color:#173453;
    classDef broken fill:#fce4e4,stroke:#b91c1c,color:#7f1d1d;
    classDef gap fill:#fff4d6,stroke:#9a6b00,color:#4f3800;
    class RULES auto;
    class MANIFEST auto;
    class EXEC auto;
    class OUTPUT output;
    class STOP broken;
    class GAP gap;
```

---

## 六、Review 加载链

```mermaid
flowchart TD
    RULES["review/rules.md<br/>已通过 @import 常驻内存"]
    SPEC["workspace/specs/spec-id/spec.yaml + spec.md<br/>机器语义 + 人类投影"]
    PLAN["workspace/specs/spec-id/plan.md"]
    DIFF["实现 diff"]
    EVIDENCE["workspace/evidence/ · workspace/runs/"]
    REVIEW_OUT["review.md · review evidence"]

    RULES --> SPEC
    SPEC --> PLAN
    PLAN --> DIFF
    DIFF --> EVIDENCE
    EVIDENCE --> REVIEW_OUT

    GAP["🟡 无 Prompt 模板<br/>🟡 无 YAML 策略<br/>🟡 无 Shell 脚本<br/>🟡 评审维度、严重级别、独立证据审查<br/>全部留给后续能力"]

    classDef auto fill:#e8f3ec,stroke:#247047,color:#153b28;
    classDef output fill:#e8effa,stroke:#315f9b,color:#173453;
    classDef gap fill:#fff4d6,stroke:#9a6b00,color:#4f3800;
    class RULES auto;
    class SPEC,PLAN,DIFF,EVIDENCE auto;
    class REVIEW_OUT output;
    class GAP gap;
```

---

## 七、Knowledge + Attribution 加载链

```mermaid
flowchart TD
    KNOWLEDGE["knowledge/rules.md<br/>✅ 已通过 @import 常驻内存"]
    ATTR["attribution/rules.md<br/>✅ 已修复：已通过 @import 接入"]
    OUTCOMES["workspace/outcomes/"]
    CANDIDATES["workspace/knowledge/candidates/"]
    CTX["workspace/context/"]
    NOPATH["🟡 已可达；无 Prompt · 无策略 · 无脚本"]

    KNOWLEDGE --> OUTCOMES
    OUTCOMES --> CANDIDATES
    CANDIDATES --> CTX
    ATTR -.-> NOPATH

    GAP["🟡 Knowledge 无 Prompt 模板 · 无策略 · 无脚本<br/>🟡 Attribution 已接入但无 Prompt · 无策略 · 无脚本"]

    classDef auto fill:#e8f3ec,stroke:#247047,color:#153b28;
    classDef broken fill:#fce4e4,stroke:#b91c1c,color:#7f1d1d;
    classDef gap fill:#fff4d6,stroke:#9a6b00,color:#4f3800;
    class KNOWLEDGE auto;
    class OUTCOMES,CANDIDATES,CTX auto;
    class ATTR,NOPATH broken;
    class GAP gap;
```

---

## 八、完整加载全景图

```mermaid
flowchart LR
    subgraph AUTO["@import 自动加载（agent 启动时）"]
        direction TB
        A1["CLAUDE.md"]
        A2[".themis/CLAUDE.themis.md"]
        A3["orchestrator/rules.md"]
        A4["specification/rules.md"]
        A5["planning/rules.md"]
        A6["context/rules.md"]
        A7["verification/rules.md"]
        A8["review/rules.md"]
        A9["knowledge/rules.md"]
        A10["attribution/rules.md ✅ 已接入"]
    end

    subgraph MANUAL["Skill / agent 按需读取"]
        direction TB
        M1["Themis-Q Skill"]
        M2["specification.yaml"]
        M3["Themis-Q adversarial reference"]
        M4["transitions.yaml"]
        M5["spec.yaml template + Artifact v2 protocols"]
        M6["themis-spec.sh executor"]
    end

    subgraph WORKSPACE["运行时按需读取"]
        direction TB
        W1["manifest.yaml"]
        W2["workspace/context/"]
        W3["workspace/specs/"]
        W4["workspace/evidence/"]
        W5["workspace/runs/"]
        W6["workspace/outcomes/"]
    end

    subgraph MISSING["⚠️ 缺失"]
        direction TB
        D1["Planning Prompt 模板<br/>未创建"]
        D2["Verification 脚本<br/>未创建"]
        D3["Review Prompt 模板<br/>未创建"]
        D4["Knowledge 流程<br/>未定义"]
        D5["Attribution 流程<br/>未定义"]
    end

    A1 --> A2
    A1 --> A3
    A3 --> A4
    A3 --> A5
    A3 --> A6
    A3 --> A7
    A3 --> A8
    A3 --> A9
    A3 --> A10

    A4 -.->|"Skill 工具调用"| M1
    A4 -.->|"读取策略"| M2
    M1 -.->|"按需读取"| M3
    A4 -.->|"用户确认后映射"| M5
    M5 -.->|"validate/render/publish"| M6
    M6 -.->|"readiness JSON"| M4

    A4 --> W3
    A5 --> W2
    A7 --> W1
    A7 --> W4
    A7 --> W5
    A9 --> W6

    D1 -.-> A5
    D2 -.-> A7
    D3 -.-> A8
    D4 -.-> A9
    D5 -.-> A10

    classDef auto fill:#e8f3ec,stroke:#247047,color:#153b28;
    classDef manual fill:#fff4d6,stroke:#9a6b00,color:#4f3800,stroke-dasharray:5 3;
    classDef ws fill:#e8effa,stroke:#315f9b,color:#173453;
    classDef missing fill:#fce4e4,stroke:#b91c1c,color:#7f1d1d;
    class A1,A2,A3,A4,A5,A6,A7,A8,A9,A10 auto;
    class M1,M2,M3,M4,M5,M6 manual;
    class W1,W2,W3,W4,W5,W6 ws;
    class D1,D2,D3,D4,D5 missing;
```

---

## 九、各阶段资产覆盖矩阵

| 阶段 | @import 规则 | Prompt 模板 | YAML 策略 | Shell 脚本 | 完整性 |
|---|---|---|---|---|---|
| **启动** | ✅ 9 文件自动加载 | — | — | — | 🟢 完整 |
| **Specification** | ✅ rules.md | ✅ `Themis-Q` Project Skill + adversarial reference | ✅ specification.yaml + transitions.yaml + 无版本 Spec schema/projection | ✅ themis-spec.sh | 🟢 Skill 提问方法、Specification 单 candidate 流程与双视图发布完整；持久状态迁移仍属 P8 |
| **Planning** | ✅ rules.md | ❌ | ❌ | ❌ | 🔴 只有边界声明 |
| **Implementation** | ❌ 无独立模块 | ❌ | ❌ | ❌ | 🔴 靠 Orchestrator 三句话 |
| **Verification** | ✅ rules.md | ❌ | ❌ | ❌ | 🔴 manifest 命令为 null 时阻塞 |
| **Review** | ✅ rules.md | ❌ | ❌ | ❌ | 🔴 只有边界声明 |
| **Knowledge** | ✅ rules.md | ❌ | ❌ | ❌ | 🔴 只有边界声明 |
| **Attribution** | ✅ rules.md（已接入） | ❌ | ❌ | ❌ | 🟡 已可达但无流程 |

---

## 十、问题分级与建议

### 🔴 结构性缺陷（阻碍正确执行）

| # | 问题 | 影响范围 | 状态 |
|---|------|---------|------|
| **A1** | Specification 的追问能力仅靠软文本指引，agent 可能跳过或自行复刻 | Specification | ✅ 已修复：`rules.md` 必须通过 Skill 工具调用精确名称 `Themis-Q`；缺失或失败时 fail closed |
| **A2** | `attribution/rules.md` 未被任何文件 @import，完全不可达 | Attribution | ✅ 已修复：Orchestrator 末尾追加 `@import ../attribution/rules.md` |
| **A3** | Planning、Verification、Review、Knowledge、Attribution 只有职责声明，无操作流程 | P5 之后的所有阶段 | ⏳ 待后续模块补充 |
| **A4** | `manifest.yaml` 的 commands 全部为 null，Verification 无回退路径 | Verification | ⏳ 待后续模块补充 |

### 🟡 设计加固（当前可用但应加强）

| # | 问题 | 状态 |
|---|------|------|
| **B1** | 详细攻击库可能被 Agent 凭记忆替代 | ✅ 已修复：`Themis-Q` 在风险需要时读取 sibling adversarial reference，模板契约验证 quick checks 与六个维度 |
| **B2** | 复杂度和攻击阈值可能被复制到多份 Prompt | ✅ 已修复：确定性阈值只保存在 `specification.yaml`，由 Specification 读取；Skill 只保留提问方法 |
| **B3** | `workspace/context/` 子目录多，agent 无工具发现有哪些可用 | ⏳ 后续添加 `themis-context-list` 脚本 |
| **B4** | Implementation 无阶段入口，路由靠 Orchestrator 三条规则 | ⏳ 后续拆分独立 `implementation/rules.md` |

### 🟢 已满足要求

| # | 说明 |
|---|------|
| **C1** | 启动 @import 链一层加载全部领域规则，浅层图、无嵌套 |
| **C2** | Core/Workspace 所有权边界在每个规则文件中一致声明 |
| **C3** | Safe Degradation 规则完整禁止虚构不存在的能力 |
| **C4** | P5/P5.2/P5.3 的 YAML 策略、`Themis-Q` Skill、无版本 Spec protocol/template、攻击场景库和确定性 executor 已形成完整资产链 |

---

## 十一、specification.yaml 的读取时机（精确追踪）

以一次 **medium 复杂度需求追问** 为例：

| 时刻 | 动因 | 读取的文件 | 读取的 Section |
|---|---|---|---|
| Agent 启动 | @import 链 | `specification/rules.md` | 全文；识别 Skill 调用、职责分离和 fail-closed 边界 |
| 进入 Specification | 当前请求仍有重要不确定性 | `.claude/skills/Themis-Q/SKILL.md` | 一次一问、适应性深度、需求覆盖和收敛指导 |
| 风险追问 | 变更需要对抗检查 | `.claude/skills/Themis-Q/references/adversarial-checklist.md` | quick/focused/comprehensive 场景与六个攻击维度 |
| 复杂度判定 | Specification 组织流程 | `specification.yaml` | `.questioning.complexity` 的 precedence、forced triggers 与 flow |
| Context 核验 | medium/high 需要事实依据 | `workspace/context/`、既有 Specs 与相关代码/配置 | 收集证据并形成最终 `context_basis` |
| 需求收敛 | Specification 使用 Skill 指导 | 当前对话 | 方案、取舍、Requirements、Contracts、Invariants 与分段 AC |
| 对抗处置 | policy 决定 attack mode | `specification.yaml` | dispositions、max_iterations、critical defer 与 limitation 规则 |
| 最终确认 | Specification 已展示规范化摘要 | 当前对话 | 用户确认是否生成 Draft Spec；未确认则继续澄清 |
| 创建 candidate | 用户已确认 | `spec.yaml` template + Artifact v2 下的无版本 Spec protocol | 一次性创建 `workspace/cache/spec-candidates/<spec-id>.yaml` |
| 发布与 readiness | candidate 已完整 | `themis-spec.sh` + `transitions.yaml` | validate/render/publish，输出八个稳定 check；保持 `status: draft`，不写 transition history |

---

## 十二、相关文件

| 文件 | 角色 |
|---|---|
| `templates/.themis/CLAUDE.themis.md` | 跨阶段边界与路由入口 |
| `templates/.themis/core/kernel/orchestrator/rules.md` | 总调度 + 领域 @import 图 |
| `templates/.themis/core/kernel/specification/rules.md` | Specification 边界 + P5 路由指引 |
| `templates/.themis/core/kernel/planning/rules.md` | Planning 边界声明 |
| `templates/.themis/core/kernel/context/rules.md` | Context 边界声明 |
| `templates/.themis/core/kernel/verification/rules.md` | Verification 边界声明 |
| `templates/.themis/core/kernel/review/rules.md` | Review 边界声明 |
| `templates/.themis/core/kernel/knowledge/rules.md` | Knowledge 边界声明 |
| `templates/.themis/core/kernel/attribution/rules.md` | ✅ 已接入 @import 图 |
| `templates/.themis/core/policies/specification.yaml` | 复杂度、flow、攻击处置与 semantic consistency 策略 |
| `templates/.themis/core/policies/transitions.yaml` | draft_to_specified 八项稳定证据契约 |
| `templates/.claude/skills/Themis-Q/SKILL.md` | 一次一问、适应性深度、需求覆盖、对抗问题与收敛摘要 |
| `templates/.claude/skills/Themis-Q/references/adversarial-checklist.md` | quick/focused/comprehensive 攻击场景库 |
| `templates/.themis/core/templates/spec.yaml` | 无版本 Spec authoritative candidate 模板 |
| `templates/.themis/core/protocols/artifact/v2/spec-schema.yaml` | Artifact v2 下当前唯一 Spec 结构、ID、引用和 readiness 契约 |
| `templates/.themis/core/protocols/artifact/v2/spec-projection.yaml` | Human 投影顺序与漂移契约 |
| `templates/.themis/core/kernel/specification/themis-spec.sh` | validate/render/publish 确定性执行器 |
| `templates/.themis/core/core.yaml` | Core 版本与兼容性元数据 |
| `templates/.themis/workspace/manifest.yaml` | 项目配置与 Gate 命令 |
