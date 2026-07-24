# Themis 模块合作关系、加载机制与结构审计

## 一、项目如何加载 Themis

### 1.1 业界实践对比

| | Lattice | Superpowers | Themis 当前 |
|---|---|---|---|
| 入口文件 | `CLAUDE.lattice.md`（单行 @import） | Plugin 机制（SessionStart hook 注入 bootstrap） | `.themis/CLAUDE.themis.md`（Themis 管理的顶层指引） |
| 加载路径 | `@import lattice/kernel/orchestrator/rules.md` | hook 自动加载 `using-superpowers` skill | Init 在项目 `CLAUDE.md` 末尾直接追加 `.themis/CLAUDE.themis.md` 与 `.themis/core/kernel/orchestrator/rules.md` import |
| 是否需要安装脚本 | 是（/init command 写入 CLAUDE.md） | 是（plugin install + hook 注册） | 计划中（P3 Init） |
| 依赖外部工具 | yq + bash | 无（纯 Markdown + SKILL 机制） | 计划中（yq + bash 仅用于 Init 校验） |

### 1.2 Lattice 的 @import 注入模式

Lattice 通过 Init 将 `@import lattice/kernel/orchestrator/rules.md` 写入项目的 `CLAUDE.md`。这使得：

- Claude Code 启动时自动加载 orchestrator 的全部规则
- 单文件入口 → 链式 import → 全量内核规则加载
- 用户无需执行任何命令即可获得 Lattice 全部行为约束

**评估**：这是当前 Claude Code 生态下**最简洁且有效的加载模式**。

### 1.3 Superpowers 的 Plugin + Hook 模式

Superpowers 不依赖 @import，而是：

1. 作为 Plugin 安装到 `.claude/plugins/`
2. 通过 SessionStart hook 注入 `using-superpowers` bootstrap
3. bootstrap 强制 Agent 在**任何回答前**先检查是否有匹配的 skill
4. 各 skill 由 Agent 自行通过 `Skill` 工具按需加载

**评估**：Plugin 模式更正交、可卸载、不影响 CLAUDE.md 结构。但依赖 hook 基础设施。

### 1.4 对 Themis 的建议（结论）

**推荐方案：@import 注入 + Skill 收口双轨制**

```
项目加载路径：
┌─────────────────────────────────────────────┐
│ CLAUDE.md（Init 在末尾写入唯一标记块）               │
│   @import .themis/CLAUDE.themis.md                  │
│   @import .themis/core/kernel/orchestrator/rules.md │
│                                                     │
│   → orchestrator/rules.md（路由中枢）                 │
│       ├── @import specification/rules.md      │
│       ├── @import planning/rules.md           │
│       ├── @import verification/rules.md       │
│       ├── @import review/rules.md             │
│       ├── @import context/rules.md            │
│       └── @import knowledge/rules.md          │
└─────────────────────────────────────────────┘

用户入口（Skill 斜杠命令）：
┌─────────────────────────────────────────────┐
│ .claude/commands/                            │
│   ├── clarify.md  → 需求追问 skill            │
│   ├── spec.md     → Specification skill       │
│   ├── plan.md     → Planning skill            │
│   ├── implement.md → Implementation skill     │
│   ├── review.md   → Review skill              │
│   ├── verify.md   → Verification skill        │
│   └── capture.md  → Knowledge capture skill   │
└─────────────────────────────────────────────┘
```

**理由**：
- @import 提供**被动约束**：Agent 在任意对话中自动继承 Themis 行为规则
- Skill/Command 提供**主动路由**：用户显式调用，收口关键入口
- 双轨互补：@import 管"always-on 的行为边界"，Skill 管"按需触发的流程路由"

---

## 二、工作流编排与保证

### 2.1 Lattice 的编排方式

Lattice 通过 `flow.yaml` 声明式定义流程，通过 shell 脚本执行操作。

**声明层**（`flow.yaml`）：
```yaml
stages:
  - name: specification
    output: ["lattice/specs/{spec-id}/spec.md"]
    gate: spec-lint
    layers: [orchestrator, context]

  - name: planning
    output: "lattice/specs/{spec-id}/plan.md"
    layers: [orchestrator]

transitions:
  specification -> planning: "spec is reviewable"
  planning -> implementation: "plan complete"
  implementation -> review: "task evidence exists"
  review -> verification: "review passes or risk accepted"
  verification -> implementation: "pipeline fails, fix and retry"
```

**执行层**（shell 脚本）：
- `task-next.sh <spec-id> --json` — 解析 plan.md 找下一任务
- `task-complete.sh <spec-id> <task-id> --json` — 带证据门禁的任务完成
- `spec-status.sh <spec-id> planned --from=drafted` — 状态迁移 + 前置条件检查
- `pipeline.sh --json-out` — Gate 流水线执行

**编排保证机制**：
1. **硬门禁**：`hard_gate: specification` — 没有任何东西能在 Spec 批准前进入实现
2. **状态迁移前置条件**：`--from=drafted` 确保状态机合法迁移
3. **证据门禁**：`task-complete.sh` 检查证据文件存在性
4. **Shell 脚本作为可执行契约**：Agent 通过 bash 命令调用，结果可审计

### 2.2 Superpowers 的编排方式

Superpowers 完全通过 **SKILL.md 内的流程指令**实现编排，无 shell 脚本。

- `using-superpowers`: 启动 skill 匹配的 bootstrap
- `brainstorming`: 9 步检查清单（上下文探索→追问→方案→设计→自审→批准）
- `writing-plans`: 输出后交给 `subagent-driven-development` 或 `executing-plans`
- `test-driven-development`: RED-GREEN-REFACTOR 流程
- `requesting-code-review`: 审查→通过→`finishing-a-development-branch`

**编排保证机制**：
1. **SKILL 优先级**：`using-superpowers` 强制"先查 skill，再做任何事"
2. **HARD-GATE 硬门禁**：brainstorming skill 内的 `<HARD-GATE>` 标记阻止跳过设计
3. **显式技能交接**：`Invoke writing-plans skill` — 每个阶段明确指定下一个 skill
4. **Red Flags 防绕过**：12 条 Agent 自我合理化拦截规则

### 2.3 对 Themis 的建议（结论）

**推荐方案：声明式 Flow + Shell 执行 + SKILL 路由三层编排**

```
Layer 1 — 声明式流程定义（flow.yaml）
  ├── 阶段定义（名称、产出、Gate、依赖层）
  ├── 迁移规则（前置条件、合法路径）
  └── 硬门禁列表

Layer 2 — Shell 执行器（可审计操作）
  ├── themis-spec-status.sh    → 状态迁移 + 前置条件检查
  ├── themis-task-next.sh       → Plan 解析 + 任务路由
  ├── themis-task-complete.sh   → 证据门禁完成
  └── themis-pipeline.sh        → Gate 流水线

Layer 3 — SKILL 路由（用户 + Agent 入口）
  ├── .claude/commands/  → 用户斜杠命令
  └── @import rules.md   → Agent 自动行为约束
```

**编排保证汇总**：

| 机制 | 来源 | Themis 适配 |
|---|---|---|
| 硬门禁（Draft→Specified） | Lattice `hard_gate` + Superpowers `HARD-GATE` | Orchestrator Transitions |
| 状态迁移前置条件 | Lattice `--from=drafted` | `themis-spec-status.sh` 检查 |
| 证据门禁（task-complete 检查证据文件） | Lattice `task-complete.sh` | `themis-task-complete.sh` |
| Red Flags 防绕过 | Superpowers 12 条拦截规则 | Orchestrator rules.md 内嵌 |
| Skill 优先级（先查 skill 再行动） | Superpowers `using-superpowers` | `using-themis` skill |

---

## 三、知识 Context 的统一维护入口

### 3.1 当前知识分类

| 知识类型 | 来源 | 维护方式 | Themis 位置 |
|---|---|---|---|
| **Behavior Map** | 静态分析 + LLM 结构化 | 工具生成 + 新鲜度标记 | `workspace/context/architecture/behavior-map/` |
| **架构知识** | 人工编写 | 人工维护 | `workspace/context/architecture/` |
| **领域规则** | 人工编写 + AI 提取 | 人工 + AI 混合 | `workspace/context/domain/` |
| **ADR** | 人工决策记录 | 人工 | `workspace/context/decisions/` |
| **陷阱/反模式** | 执行过程沉淀 | AI 提取 + 人工确认 | `workspace/context/pitfalls/` |
| **术语表** | 人工 + AI | 混合 | `workspace/context/glossary/` |
| **外部引用** | 人工配置 | 人工 | `workspace/context/external/` |

### 3.2 Lattice 的知识维护模式

Lattice 通过 shell 脚本提供 AI 知识操作入口：

```
lattice/kernel/context/
  ├── loader.sh              → 按需加载上下文
  ├── backends/knowledge.sh  → 语义搜索已有知识（可选）
  ├── learn-draft.sh         → 从执行过程提取知识草稿
  ├── summary-learn-draft.sh → 生成知识摘要
  ├── knowledge-lint.sh      → 知识格式校验
  ├── knowledge-review.sh    → 知识审核
  └── sync.sh                → 同步上下文索引
```

Lattice 的架构知识模板（`lattice/context/knowledge/architecture.md`）：
```yaml
---
owner: "project"
verified_at: "2026-06-28"
applies_to: ["architecture", "module-boundaries"]
---
# Architecture
（结构和来源标记）
```

### 3.3 对 Themis 的建议（结论）

**推荐方案：Skill + Command 收口入口，统一知识写入路径**

```
所有知识维护操作通过统一的 .claude/commands/ 入口：

/themis-capture  → Knowledge Capture Skill
  ├── 来源：Spec 执行 / Review 发现 / Verification 失败
  ├── 流程：候选识别 → 去重 → 审核 → 提升
  ├── 行为地图更新（触发 Behavior Map 重生成）
  └── 写入 workspace/context/ 对应子目录

/themis-context  → Context Discovery Skill
  ├── 按需加载：通过 workspace/context/README.md 索引路由
  ├── 搜索：bash .themis/core/kernel/context/backends/knowledge.sh <keywords>
  └── 只读：不修改已有知识
```

**为什么需要 Skill + Command 收口**：
1. **统一入口**：所有写入经过同一个审核流程，避免两套正式知识目录
2. **可审计**：每次知识变更通过 `/capture` 触发，有明确记录
3. **防止污染**：Agent 不能绕过审核直接写 `workspace/context/`
4. **后续处理统一**：Behavior Map 重生成、新鲜度标记、冲突检查都在统一入口完成

---

## 四、Themis 当前结构审计

### 4.1 已知问题

| # | 问题 | 严重程度 | 状态 |
|---|------|---------|------|
| 1 | `templates/.themis/core/kernel/konwledge/` — 拼写错误 | 中 | 计划 P1 修复 |
| 2 | `templates/.themis/core/migations/` — 拼写错误 | 中 | 计划 P1 修复 |
| 3 | `templates/CLAUDE.themis.md` 位于工程根的旧布局 | 高 | 已由 P3 修订：指引移入 `templates/.themis/CLAUDE.themis.md`，并由项目 `CLAUDE.md` 直接 import |
| 4 | `templates/.themis/core/core.yaml` — 空文件 | 高 | 计划 P1 修复 |
| 5 | `templates/.themis/workspace/manifest.yaml` — 空文件 | 高 | 计划 P1 修复 |
| 6 | 所有模板子目录为空（无 .gitkeep 或 rules.md） | 中 | 计划 P1 修复 |
| 7 | `bin/` 目录不存在 — 无 init/upgrade 脚本 | 高 | 计划 P3/P4 |
| 8 | 无 `.claude/commands/` — 无用户入口 | 中 | 计划 P2/P5 |
| 9 | AGENTS.md 缺少具体 Init/Upgrade 实现说明 | 低 | 可延后 |
| 10 | 无 `page.html` 关联文档（根目录存在 page.html） | 低 | 已归类为 Harness Handbook 研究页面，移至 `docs/references/harness-handbook.html` |

### 4.2 模板目录对比（文档 vs 实际）

| 文档要求的目录 | 模板中是否存在 | 是否为空 |
|---|---|---|
| `core/kernel/knowledge/` | ✅（但有拼写错误 konwledge） | 空 |
| `core/migrations/` | ✅（但有拼写错误 migations） | 空 |
| `core/kernel/*/rules.md` | ❌ 不存在 | — |
| `core/policies/*.yaml` | ❌ 不存在 | — |
| `core/templates/*.md` | ❌ 不存在 | — |
| `core/protocols/*/` | ✅（有子目录，无文件） | 空 |
| `core/adapters/*/` | ❌ 无子目录 | — |
| `workspace/policies/` | ✅ | 空 |
| `workspace/context/*/` | ❌ 无子目录（仅 context/ 目录） | 空 |
| `workspace/state/*/` | ❌ 无子目录（仅 state/ 目录） | 空 |
| `workspace/runs/` | ✅ | 空 |
| `workspace/evidence/*/` | ❌ 无子目录（仅 evidence/ 目录） | 空 |
| `workspace/outcomes/*/` | ❌ 无子目录（仅 outcomes/ 目录） | 空 |
| `workspace/knowledge/*/` | ❌ 无子目录（仅 knowledge/ 目录） | 空 |
| `workspace/cache/*/` | ❌ 无子目录（仅 cache/ 目录） | 空 |

### 4.3 缺失的功能模块

根据 Lattice 和 Superpowers 的对比分析，Themis 当前 WIKI 文档已覆盖但**模板中完全缺失**的功能：

| 缺失项 | 对应模块 | Lattice 参考 | Superpowers 参考 |
|---|---|---|---|
| `flow.yaml`（声明式流程定义） | Orchestrator | `kernel/orchestrator/flow.yaml` | brainstorming SKILL checklist |
| 状态迁移脚本（`themis-spec-status.sh`） | Orchestrator | `kernel/orchestrator/sdd/spec-status.sh` | — |
| 任务路由脚本（`themis-task-next.sh`） | Planning | `kernel/orchestrator/sdd/task-next.sh` | writing-plans SKILL |
| Gate 流水线（`themis-pipeline.sh`） | Verification | `kernel/delivery/pipeline.sh` | — |
| 证据检查脚本（`themis-task-evidence-lint.sh`） | Verification | `kernel/orchestrator/sdd/task-evidence-lint.sh` | verification-before-completion |
| 知识加载/提取脚本 | Context + Knowledge | `kernel/context/` 脚本集 | — |
| Red Flags 防绕过规则 | Orchestrator | — | using-superpowers Red Flags |
| Slash Commands（`themis-clarify/themis-spec/themis-plan/themis-implement/themis-review/themis-verify/themis-capture`） | 全域 | `.claude/commands/` | 各 SKILL 的 invocation 机制 |
| 共享库（`_themis-lib.sh`） | 全域 | `kernel/_lib.sh` | — |
| Bootstrap skill（`using-themis`） | 全域 | — | `using-superpowers` SKILL |

### 4.4 计划的覆盖缺口

| 缺失功能 | 已有计划覆盖？ | 建议 |
|---|---|---|
| `flow.yaml` | P1（模板契约间接涉及） | P1 impl 时需明确包含 |
| Shell 脚本集合（_themis-lib.sh, themis-spec-status.sh, themis-task-next.sh 等） | ❌ 无单独计划 | 建议新增 P8：Shell Scripts & Execution Layer |
| Slash Commands（.claude/commands/） | P2（顶层指引间接涉及） | P2 impl 时需明确包含 |
| Bootstrap skill（using-themis） | ❌ 无单独计划 | 建议新增 P8：Bootstrap Skill & Red Flags |
| Gate 流水线 | ❌ 无单独计划 | 建议并入 P7 或 Verification 模块规则 |

---

## 五、总结与行动计划

### 加载机制结论

**Themis 应使用 @import 注入 CLAUDE.md + Skill/Command 收口**。这综合了 Lattice 的简洁有效（@import 单行注入）和 Superpowers 的强制路由（Skill 优先级检查）。

### 工作流编排结论

**三层编排**：声明式 flow.yaml（阶段+迁移） → Shell 执行器（可审计操作） → SKILL 路由（用户+Agent 入口）。编排保证来自硬门禁 + 状态迁移前置条件 + 证据门禁 + Red Flags 防绕过。

### 知识维护结论

**Skill + Command 统一收口**：所有知识写入通过 `/themis-capture` 命令进入统一的候选→去重→审核→提升流程。Behavior Map 和人工维护知识共用同一个入口和审核链。

### 结构缺失

当前模板与文档之间存在显著差距：模板仅为空目录骨架，无任何 rules.md、flow.yaml、shell 脚本或 slash commands。建议在 P1-P6 之外补充 P7（Shell Scripts & Execution Layer）和 P8（Bootstrap Skill & Red Flags）。