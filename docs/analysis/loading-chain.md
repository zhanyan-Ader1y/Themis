# Themis 加载链与阶段资产映射分析

本文以项目 agent 视角，追踪 Themis 从启动到各 SDD 阶段的完整 Prompt、YAML、Shell 脚本读取顺序，并标记结构性问题与增强建议。

> 分析基准：Themis 0.2.0（P5 已落地，P6/P8 及后续能力尚未实施）。

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

## 二、Specification（Draft）：需求追问加载链

这是当前 Themis 唯一具有完整 Prompt + YAML 策略的阶段。

```mermaid
flowchart TD
    RULES["specification/rules.md<br/>已通过 @import 常驻内存"]
    MANUAL_READ_1{"agent 是否遵循<br/>rules.md 的文本指引？"}
    POLICY["② core/policies/specification.yaml<br/>复杂度阈值 · flow 模式 · 六维攻击面 ·<br/>五项快速检查 · dispositions · Red Flags · 自检项"]
    PROMPT["③ core/templates/spec-questioning.md<br/>Role · 全局约束 · Available Scripts ·<br/>复杂度路由表 · Step 0–4 协议 · Final Approval"]
    SPEC_TEMPLATE["④ core/templates/spec.md<br/>themis-spec/v1 Draft 模板<br/>11 个固定 Section · YAML front matter"]
    ADV_LIB["⑤ core/templates/spec-adversarial-checklist.md<br/>五项快速检查 · 六维攻击场景库（29 个场景）<br/>结果记录规范"]
    TRANSITIONS["⑥ core/policies/transitions.yaml<br/>draft_to_specified · 7 项证据条件 ·<br/>adversarial_validation Gate"]

    RULES --> MANUAL_READ_1
    MANUAL_READ_1 -- "✅ 遵循" --> POLICY
    MANUAL_READ_1 -- "🔴 跳过" --> SKIP["直接开始追问<br/>丢失复杂度自适应和门禁"]
    POLICY --> PROMPT
    PROMPT -->|"Step 1 评估复杂度"| POLICY
    PROMPT -->|"Step 3 创建 Draft"| SPEC_TEMPLATE
    PROMPT -->|"Step 4 对抗验证"| ADV_LIB
    SPEC_TEMPLATE -->|"final approval 前"| TRANSITIONS

    classDef auto fill:#e8f3ec,stroke:#247047,color:#153b28;
    classDef manual fill:#fff4d6,stroke:#9a6b00,color:#4f3800,stroke-dasharray:5 3;
    classDef broken fill:#fce4e4,stroke:#b91c1c,color:#7f1d1d;
    classDef output fill:#e8effa,stroke:#315f9b,color:#173453;
    class RULES auto;
    class POLICY,PROMPT,ADV_LIB,TRANSITIONS manual;
    class MANUAL_READ_1,SKIP broken;
    class SPEC_TEMPLATE output;
```

### 🔴 核心问题：软依赖链（已部分修复）

specification/rules.md 中的**旧**原文是：

> "Before Spec validation, follow the Step 0–4 flow in `core/templates/spec-questioning.md`. Use `core/policies/specification.yaml` for complexity modes..."

这是**描述性指引**（"follow the flow"），不是**命令性指令**（"you MUST Read"）。

**修复后 (A1)**：

> "You MUST Read these files before any Specification work:
> 1. `core/templates/spec-questioning.md` — the Step 0–4 protocol.
> 2. `core/policies/specification.yaml` — complexity thresholds and flow modes.
> 3. `core/policies/transitions.yaml` — the `draft_to_specified` evidence contract.
> Do not begin Step 0, assess complexity, or create a Draft Spec until all three files have been read."

此外：
- **B1**：spec-questioning.md Step 4 首行新增 "开始 Step 4 前，你必须 Read `core/templates/spec-adversarial-checklist.md`。不要凭记忆或通用知识即兴攻击。"
- **B2**：复杂度判定伪代码从 Prompt 移入 specification.yaml 注释段，Prompt 只保留路径引用。agent 可能：

1. 凭训练记忆直接开始追问，跳过 `specification.yaml` 的复杂度判定；
2. 凭通用知识做对抗验证，跳过 `spec-adversarial-checklist.md` 的标准化场景库；
3. 在 low 复杂度时完全跳过 Step 4（而策略要求至少完成五项快速检查）。

### 读取链路脆弱性量化

| 文件 | 加载方式 | 被跳过的可能性 | 后果 |
|---|---|---|---|
| `specification.yaml` | rules.md 文本指引 → agent 主动 Read | **中高** | 丢失复杂度分类、强制 high 信号、flow 模式 |
| `spec-questioning.md` | 同上 | **中** | 丢失 Step 0 Five Whys、Step 4 对抗验证协议、Red Flags |
| `spec-adversarial-checklist.md` | questioning.md Step 4 的文本提及 | **高** | 对抗验证退化为 agent 即兴发挥，场景覆盖不完整 |
| `transitions.yaml` | questioning.md Final Approval 文本提及 | **高** | 丢失 7 项证据条件的具体定义 |

---

## 三、Planning 加载链

```mermaid
flowchart TD
    RULES["planning/rules.md<br/>已通过 @import 常驻内存"]
    SPEC["workspace/specs/spec-id/spec.md<br/>已批准 Spec"]
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
    SPEC["workspace/specs/spec-id/spec.md<br/>批准范围"]
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
    SPEC["workspace/specs/spec-id/spec.md"]
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

    subgraph MANUAL["agent 显式 Read（依赖文本指引）"]
        direction TB
        M1["specification.yaml"]
        M2["spec-questioning.md"]
        M3["spec-adversarial-checklist.md"]
        M4["transitions.yaml"]
        M5["spec.md（模板）"]
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

    A4 -.->|"文本指引"| M1
    A4 -.->|"文本指引"| M2
    M2 -.->|"文本提及"| M3
    M2 -.->|"文本提及"| M4
    M2 -.->|"Step 3 创建"| M5

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
    class M1,M2,M3,M4,M5 manual;
    class W1,W2,W3,W4,W5,W6 ws;
    class D1,D2,D3,D4,D5 missing;
```

---

## 九、各阶段资产覆盖矩阵

| 阶段 | @import 规则 | Prompt 模板 | YAML 策略 | Shell 脚本 | 完整性 |
|---|---|---|---|---|---|
| **启动** | ✅ 8 文件自动加载 | — | — | — | 🟢 完整 |
| **Specification** | ✅ rules.md | ✅ spec-questioning.md | ✅ specification.yaml | — | 🟡 Prompt/策略靠软依赖 |
| | | ✅ spec-adversarial-checklist.md | ✅ transitions.yaml | | |
| | | ✅ spec.md（Draft 模板） | | | |
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
| **A1** | Specification Prompt 与 Policy 依赖软文本指引加载，agent 可能跳过 | Specification | ✅ 已修复：`rules.md` 改为命令式 "You MUST Read these files before any Specification work. Do not begin Step 0... until all three files have been read." |
| **A2** | `attribution/rules.md` 未被任何文件 @import，完全不可达 | Attribution | ✅ 已修复：Orchestrator 末尾追加 `@import ../attribution/rules.md` |
| **A3** | Planning、Verification、Review、Knowledge、Attribution 只有职责声明，无操作流程 | P5 之后的所有阶段 | ⏳ 待后续模块补充 |
| **A4** | `manifest.yaml` 的 commands 全部为 null，Verification 无回退路径 | Verification | ⏳ 待后续模块补充 |

### 🟡 设计加固（当前可用但应加强）

| # | 问题 | 状态 |
|---|------|------|
| **B1** | `spec-adversarial-checklist.md` 仅在 questioning Prompt Step 4 文本提及，agent 可能凭记忆即兴攻击 | ✅ 已修复：Step 4 首行新增 "你必须 Read，不要凭记忆或通用知识即兴攻击" |
| **B2** | 复杂度分类逻辑分散在 YAML（阈值）和 Prompt（判定流程）两处 | ✅ 已修复：判定伪代码写入 YAML 注释段，Prompt 只保留路径引用 |
| **B3** | `workspace/context/` 子目录多，agent 无工具发现有哪些可用 | ⏳ 后续添加 `themis-context-list` 脚本 |
| **B4** | Implementation 无阶段入口，路由靠 Orchestrator 三条规则 | ⏳ 后续拆分独立 `implementation/rules.md` |

### 🟢 已满足要求

| # | 说明 |
|---|------|
| **C1** | 启动 @import 链一层加载全部领域规则，浅层图、无嵌套 |
| **C2** | Core/Workspace 所有权边界在每个规则文件中一致声明 |
| **C3** | Safe Degradation 规则完整禁止虚构不存在的能力 |
| **C4** | P5 的 YAML 策略、Prompt 模板、Draft Spec 模板、攻击场景库四层资产齐全 |

---

## 十一、specification.yaml 的读取时机（精确追踪）

以一次 **medium 复杂度需求追问** 为例：

| 时刻 | 动因 | 读取的文件 | 读取的 Section |
|---|---|---|---|
| Agent 启动 | @import 链 | `specification/rules.md` | 全文（29 行） |
| 进入 Specification | rules.md 指引 | `spec-questioning.md` | Role、约束、Complexity Routing 表 |
| Step 0 | 无 | — | 从对话上下文获取用户请求 |
| Step 1 开始 | questioning.md Step 1 指引 | `specification.yaml` | `.questioning.complexity`（low/medium/high 阈值 + forced_triggers） |
| Step 1 判定 | YAML 阈值 | — | 比对请求特征得出复杂度 |
| Step 2 | questioning.md Step 2 指引 | `workspace/context/` | 相关架构、领域、工程文件 |
| Step 3 创建 Draft | questioning.md Step 3 指引 | `spec.md`（模板） | 全文，基于模板创建实例 |
| Step 4 开始 | questioning.md Step 4 指引 | `spec-adversarial-checklist.md` | 按 medium → focused 模式选择场景 |
| Step 4 处置 | specification.yaml | `.adversarial_validation` | dispositions、max_iterations、deferral 规则 |
| Final Approval | questioning.md Final Approval | `transitions.yaml` | `.transitions.draft_to_specified` 条件清单 |
| 批准后 | P5 边界 | — | 保持 `status: draft`，不写 transition history |

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
| `templates/.themis/core/policies/specification.yaml` | 复杂度、flow、攻击维度、门禁 |
| `templates/.themis/core/policies/transitions.yaml` | draft_to_specified 证据契约 |
| `templates/.themis/core/templates/spec-questioning.md` | Step 0–4 Prompt |
| `templates/.themis/core/templates/spec-adversarial-checklist.md` | 攻击场景库 |
| `templates/.themis/core/templates/spec.md` | Draft Spec 模板 |
| `templates/.themis/core/core.yaml` | Core 版本与兼容性元数据 |
| `templates/.themis/workspace/manifest.yaml` | 项目配置与 Gate 命令 |
