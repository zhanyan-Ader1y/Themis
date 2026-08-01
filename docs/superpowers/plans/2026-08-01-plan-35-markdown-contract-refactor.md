# Plan 35 Markdown 合同重构实施计划

> **供 Agent 执行时使用：** 必须使用 `superpowers:subagent-driven-development`（推荐）或 `superpowers:executing-plans`，按任务逐项实施本计划。所有步骤使用复选框（`- [ ]`）跟踪。

**目标：** 在不改变 replacement Plan 35 已实现功能的前提下，将所有无 Go CLI 消费者的 YAML 合同迁移为按功能拆分、可按需加载的自然语言 Markdown，并重建静态核验、人工 replay 和重新接受证据。

**架构：** 保留一个公共 `themis` 治理入口、一个 Global Rule、两个隔离 authority scope、十六个 Capability、四个 Agent Profile 和现有 lifecycle 语义。大型权威与控制文件改为短入口加 `references/`；原 YAML 路由逐条改写为按阶段组织的自然语言控制规则；不可变 paired artifacts 使用 Markdown `record.md` 与 `content.md` 两个组件。

**技术栈：** 自然语言 Markdown、Claude project Skill、人工语义 parity review、人工 replay。项目不使用 Python；需要自动执行的项目脚本只能由已批准并已实现的 Themis Go CLI 提供。当前没有可用的 Go CLI 验证命令，因此本计划不虚构命令，也不以临时脚本替代。无产品 YAML、无 Plan 36/37 实现。

## 全局约束

- 本文件只定义实施步骤，不授权立即修改 Plan 35；执行前仍需用户明确批准开始实施。
- 保留 replacement Plan 35 的产品语义，不借表示迁移重新设计 Intake、Capability、Review、Verify、Failure Learning、Workspace 或 lifecycle。
- 默认使用自然语言 Markdown 表达产品语义、流程、状态、合同、模板和示例；除宿主强制的 `SKILL.md` 最小 frontmatter 外，本次目标范围不得保留或新增 YAML。
- 当前仓库没有 Go 文件，所以 `templates/.themis/` 下现有 27 个活动 YAML 均必须迁移并删除；不得以“未来 runtime”“结构化展示”或“Prompt 路由”为理由保留。
- 保留一个名为 `themis` 的公共治理 Skill；不得把“整个项目只能有一个 Skill”写成产品约束，以免耦合独立的 `themis-skill-creator`。
- 保留两个 authority scope：`request-intake` 与 `lifecycle`；二者只能共享 stable immutable references，不得共享动态状态、Execution Identity、failure budget、continuation authority、current pointer 或 completion state。
- 保留十六个 Capability identity、四个 Agent Profile，以及只有 `themis-impl` 使用 `implementation-writer` 的固定映射。
- 保留 route decision identity `capability + selected_path + profile + status` 作为自然语言规则的定位信息；当前从旧 YAML 观察到的 98 个合法结果组合必须逐项迁移，但不得升级为永久产品版本、常量身份或可解析 Markdown DSL。
- 保留十一类 paired semantic artifact，但把 `machine record + Markdown` 改为 `Markdown control record + Markdown governed content`；任一组件缺失或 identity/digest/scope/binding 不一致时，整个 revision 仍无效。
- 保留 Intake-first、Source Event、changed-only confirmation、多目标 assignment、partial recovery、逐 target freeze、整体 `dormant-read-only`、新消息创建新 Intake 等语义。
- 保留 Review-before-Impl，Verify 固定为 `themis-impl → independent themis-verification`，并保留 Verification、Human Acceptance、Summary 的门禁顺序。
- 保留 Intake/lifecycle 隔离的三次 counted failure 上限，以及 Impl/Verification/Acceptance implementation-defect repair 共享 lifecycle Plan Task Execution Identity 的规则。
- 不实现 Plan 36 strict Schema、canonicalization、validator、issue taxonomy、semantic oracle 或 fixtures。
- 不实现 Plan 37 evaluator、recorder、Invocation host、digest/write service、installer、command runner、transaction 或 recovery runtime。
- 不引入功能版本、版本目录、compatibility、安装/版本 upgrade、runtime migration mechanism、Shell fallback、第二套 policy 或持久 Specification；本计划中的“迁移”只指一次性表示重构与 authority cutover，不形成产品能力。
- 所有新建或重写的 Markdown 正文使用中文；稳定 identity、字段名、状态值和路径保持原英文值。
- 大文件只保留短入口、不可绕过不变量和 references 索引；实施 Agent 只读取当前任务 brief、目标入口和对应 reference，不得要求其一次读取全部拆分文件。
- 项目不使用 Python；不得新增 Python 源码、脚本、一次性断言或执行依赖。
- 所有需要自动执行的项目脚本只能由已批准并已实现的 Themis Go CLI 提供；当前仓库尚无可用 Go CLI 命令时，计划必须把相应自动检查标为 unavailable，不得发明子命令或以 Shell/其他临时脚本替代。
- `git status` 与 `git diff` 只用于只读观察版本控制状态和人工审阅差异，不属于项目自动化脚本；不得使用 Shell 管道转换文件、生成合同或代替 Go CLI 核验。
- 本计划的静态核验采用人工文件树、字段、引用、自然语言规则覆盖与 diff 审查；这些观察不得成为产品 runtime、隐藏 Schema、route parser 或第二 policy source。
- 执行时先保存 `git status --short` 基线；不得 reset、restore、clean、stash、覆盖或迁移现有用户修改。
- 未经用户另行明确授权，不得 commit、amend、push 或创建 PR。

---

## 目标文件结构

### 跨模块 Plan 35 权威

```text
docs/superpowers/specs/
├── 2026-07-31-plan-35-core-contract-replacement-design.md
└── 2026-07-31-plan-35-core-contract-replacement/
    ├── authority-model.md
    ├── request-intake.md
    ├── current-request-and-dialogue.md
    ├── capabilities-and-profiles.md
    ├── public-entry-and-control.md
    ├── lifecycle-flow.md
    ├── artifacts-and-workspace.md
    ├── review-and-delivery.md
    ├── currentness-failure-recovery.md
    └── verification-and-acceptance.md
```

原 dated spec 保持 current authority 路径，但只保存目标、边界、核心不变量和加载索引；详细合同移入同 stem 目录。

### 唯一 Policy 包

```text
templates/.themis/core/policies/
├── README.md
└── references/
    ├── authority-scopes.md
    ├── intake-and-retention.md
    ├── capability-bindings.md
    ├── materialization-and-currentness.md
    ├── guards-invalidation-and-recovery.md
    ├── failure-control.md
    ├── assurance-boundary.md
    └── routes/
        ├── intake.md          # Current Request Dialogue 的自然语言控制规则
        ├── understanding.md   # Questioning、Grounding、Complexity Assessment
        ├── planning.md        # Simple Plan、Specification、Planning、Plan Check
        ├── review.md          # Review Projection、Review Check、Review Dialogue
        ├── delivery.md        # Impl、Verification、Acceptance、Summary
        └── learning.md        # scope/path-bound Failure Learning
```

`policies/README.md` 是唯一 policy entry；reference 文件只是该 policy 的自然语言分片，不是多个独立 policy。`routes/` 按阶段帮助 Agent 定位规则，但不得使用固定表格、可解析行格式或 parser；`transitions.yaml` 保留到任务 9 全局 cutover，再由任务 9 统一删除。

### 常驻 Global Rule

```text
templates/.themis/core/kernel/orchestrator/
├── README.md
├── rules.md
└── references/
    ├── intake-entry.md
    ├── invocation-and-materialization.md
    ├── lifecycle-continuation.md
    ├── review-and-completion.md
    ├── failure-invalidation-recovery.md
    └── safe-degradation.md
```

`rules.md` 常驻，只保存 Intake-first、authority boundary、non-bypass、reference 选择规则和停止条件；阶段细节按当前 durable gate 加载。

### 工件模板

```text
templates/.themis/core/templates/
├── README.md
├── request-intake/
│   ├── source-event.md
│   ├── proposal.md
│   └── decision.md
├── current-request/
│   ├── record.md
│   └── content.md
├── questioning-round/
│   ├── record.md
│   └── content.md
├── grounding/
│   └── record.md
├── complexity-assessment/
│   └── record.md
├── plan/
│   ├── record.md
│   └── content.md
├── plan-check/
│   └── record.md
├── review-projection/
│   ├── record.md
│   └── content.md
├── review-check/
│   └── record.md
├── review-approval/
│   ├── record.md
│   └── content.md
├── review-feedback/
│   ├── record.md
│   └── content.md
├── impl-result/
│   ├── record.md
│   └── content.md
├── verification/
│   ├── record.md
│   └── content.md
├── acceptance/
│   ├── record.md
│   └── content.md
├── summary/
│   ├── record.md
│   └── content.md
├── failure-learning/
│   ├── record.md
│   └── content.md
└── context/
    ├── resolution.md
    └── summary.md
```

Paired family 的运行时 revision shape 保持：

```text
<artifact-family>/<opaque-revision-id>/
  record.md
  content.md
```

`record.md` 使用 Markdown 标题、字段表和枚举表表达控制记录；不得使用 YAML frontmatter 或 fenced YAML。

### Core、Workspace 与 Context

```text
templates/.themis/core/
├── README.md
└── protocols/context/
    ├── README.md
    └── references/
        ├── common-fields.md
        ├── context-item.md
        ├── catalog.md
        ├── bundle.md
        └── signal.md

templates/.themis/workspace/
├── README.md
├── project.md
├── references/
│   ├── directory-ownership.md
│   ├── intake-and-lifecycle-isolation.md
│   ├── artifact-and-state-model.md
│   ├── completion-retention.md
│   └── recovery-and-cache.md
└── context/
    └── catalog.md
```

`core.yaml`、`workspace/manifest.yaml`、五个 Context schema YAML 和 `workspace/context/catalog.yaml` 只作为候选 Markdown 的旧来源保留；任务 9 全局 cutover 后统一删除。

### 27 个 YAML 的完整迁移矩阵

| 旧 YAML | 新 Markdown authority |
|---|---|
| `core/policies/transitions.yaml` | `core/policies/README.md` + `core/policies/references/**` |
| `core/core.yaml` | `core/README.md` |
| `workspace/manifest.yaml` | `workspace/project.md` + `workspace/references/**` |
| `workspace/context/catalog.yaml` | `workspace/context/catalog.md` |
| `core/protocols/context/common-schema.yaml` | `core/protocols/context/references/common-fields.md` |
| `core/protocols/context/context-item-schema.yaml` | `core/protocols/context/references/context-item.md` |
| `core/protocols/context/catalog-schema.yaml` | `core/protocols/context/references/catalog.md` |
| `core/protocols/context/bundle-schema.yaml` | `core/protocols/context/references/bundle.md` |
| `core/protocols/context/signal-schema.yaml` | `core/protocols/context/references/signal.md` |
| `core/templates/request-intake-source-event.yaml` | `core/templates/request-intake/source-event.md` |
| `core/templates/request-intake-proposal.yaml` | `core/templates/request-intake/proposal.md` |
| `core/templates/request-intake-decision.yaml` | `core/templates/request-intake/decision.md` |
| `core/templates/current-request.yaml` | `core/templates/current-request/record.md` |
| `core/templates/questioning-round.yaml` | `core/templates/questioning-round/record.md` |
| `core/templates/grounding.yaml` | `core/templates/grounding/record.md` |
| `core/templates/complexity-assessment.yaml` | `core/templates/complexity-assessment/record.md` |
| `core/templates/plan.yaml` | `core/templates/plan/record.md` |
| `core/templates/plan-check.yaml` | `core/templates/plan-check/record.md` |
| `core/templates/review.yaml` | `core/templates/review-projection/record.md` |
| `core/templates/review-check.yaml` | `core/templates/review-check/record.md` |
| `core/templates/review-approval.yaml` | `core/templates/review-approval/record.md` |
| `core/templates/review-feedback.yaml` | `core/templates/review-feedback/record.md` |
| `core/templates/impl-result.yaml` | `core/templates/impl-result/record.md` |
| `core/templates/verification.yaml` | `core/templates/verification/record.md` |
| `core/templates/acceptance.yaml` | `core/templates/acceptance/record.md` |
| `core/templates/summary.yaml` | `core/templates/summary/record.md` |
| `core/templates/failure-learning.yaml` | `core/templates/failure-learning/record.md` |

该表只表达表示迁移位置；新 Markdown 必须逐字段保留旧合同，不能仅创建同名空壳。

### 迁移与 Replay 证据

```text
docs/plan/35-core-prompt-flow/
├── migration-parity.md
├── migration-parity/
│   ├── baseline.md
│   ├── authority.md
│   ├── policy.md
│   ├── control-entry.md
│   ├── intake-and-planning-templates.md
│   ├── review-and-delivery-templates.md
│   ├── capabilities.md
│   ├── core-workspace-context.md
│   └── cutover.md
├── static-verification.md
├── manual-replay.md
├── manual-replay/
│   ├── scenario-01-new-intake-confirmation.md
│   ├── scenario-02-active-no-change-and-dormancy.md
│   ├── scenario-03-multi-target-completion.md
│   ├── scenario-04-partial-target-recovery.md
│   ├── scenario-05-questioning-claim-change.md
│   ├── scenario-06-review-acceptance-intake-first.md
│   ├── scenario-07-review-feedback-owner.md
│   ├── scenario-08-sticky-full-escalation.md
│   ├── scenario-09-paired-artifact-pointer-failure.md
│   ├── scenario-10-invalid-result.md
│   ├── scenario-11-intake-failure-isolation.md
│   ├── scenario-12-shared-delivery-failure-budget.md
│   ├── scenario-13-failure-learning.md
│   ├── scenario-14-completion-and-retention-gates.md
│   ├── scenario-15-interruption-recovery.md
│   └── scenario-16-rejection-abandonment-new-intake.md
├── acceptance-audit.md
└── evidence-summary.md
```

### 迁移 parity evidence 合同

`docs/plan/35-core-prompt-flow/migration-parity.md` 是唯一索引，只保存核验边界、九个 evidence 分片的链接、每个分片的实际观察结论和未裁决 GAP 汇总，不复制完整迁移清单。

每个 `migration-parity/*.md` 分片必须使用相同章节：核验范围、旧来源与新目标、逐项迁移观察、实施者核对、fresh reviewer 核对、未裁决 GAP、自动 Go CLI 检查状态。实施者填写迁移观察；task reviewer 只读复核，不直接修改产品或 evidence 文件；协调者根据 reviewer 报告把确认结论、发现和报告引用追加到“fresh reviewer 核对”章节。没有已批准并已实现的 CLI 能力时，最后一项必须写 `unavailable`，不能用临时脚本生成结论。

文件 owner 固定如下：

| Evidence 分片 | 唯一写入任务 | 覆盖范围 |
|---|---:|---|
| `baseline.md` | 任务 1 | 工作树、27 个 YAML、大文件与旧证据适用边界 |
| `authority.md` | 任务 2 | current authority entry、十个 references、32 条标准定位 |
| `policy.md` | 任务 3 | 顶层 Policy 主题、98 个旧合法结果组合、guard/failure/invalidation |
| `control-entry.md` | 任务 4 | Global Rule、六个 references、公共 `themis` 入口 |
| `intake-and-planning-templates.md` | 任务 5 | Intake、Current Request、Questioning、Grounding、Assessment、Plan/Check |
| `review-and-delivery-templates.md` | 任务 6 | Review、Delivery、Outcome、Learning 与 Context 辅助模板 |
| `capabilities.md` | 任务 7 | 十六个 Capability 与 common result envelope |
| `core-workspace-context.md` | 任务 8 | Core、Workspace、Context protocol 与配置槽 |
| `cutover.md` | 任务 9 | 消费者切换、27 项删除矩阵、旧 flat template 删除与双人式复核 |

各任务只能写自己的分片，并在 `migration-parity.md` 更新对应链接、实际结论和 GAP 摘要。任务 9 只有在索引链接齐全、任务 1–8 分片均有实施者与 fresh reviewer 观察且索引无未裁决 GAP 时才能执行删除。任务 10 与任务 11 只消费该证据包来重建静态证据和验收，不得反向改写迁移观察。

---

### 任务 1: 冻结迁移基线并撤销过期的当前 PASS 声明

**文件：**
- 修改： `docs/plan/35-core-prompt-flow/impl.md`
- 新建： `docs/plan/35-core-prompt-flow/migration-parity.md`
- 新建： `docs/plan/35-core-prompt-flow/migration-parity/baseline.md`
- 修改： `docs/plan/35-core-prompt-flow/static-verification.md`
- 修改： `docs/plan/35-core-prompt-flow/manual-replay.md`
- 修改： `docs/plan/35-core-prompt-flow/acceptance-audit.md`
- 修改： `docs/plan/35-core-prompt-flow/evidence-summary.md`
- 修改： `docs/plan/README.md`

**接口：**
- 输入： `AGENTS.md` 的 Markdown-first 规则、2026-07-31 已接受的 Plan 35 产品语义、当前 27 个活动 YAML 和旧证据。
- 产出： 一个明确的迁移基线：历史 re-acceptance 仍被记录，但当前表示层重新核验处于 pending，不再声称新规则下 `32 PASS, 0 GAP`；`migration-parity/baseline.md` 保存实施者观察，task reviewer 的独立复核在任务完成前追加，索引同步链接、结论和 GAP。

- [ ] **步骤 1: 保存受保护工作树基线**

运行：

```bash
git status --short
```

将完整输出写入 `docs/plan/35-core-prompt-flow/migration-parity/baseline.md` 的工作树基线章节，并在 `migration-parity.md` 记录该分片链接与基线状态。后续只允许修改本计划列出的文件；任何预先存在的修改都不得被清理、回滚或覆盖。

- [ ] **步骤 2: 人工记录当前 YAML 与大文件基线**

使用文件搜索工具列出 `templates/.themis/` 下全部 `*.yaml`，把 27 个实际路径逐项写入 `migration-parity/baseline.md`；再记录以下入口的当前行数和主题范围：

```text
docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement-design.md
templates/.themis/core/policies/transitions.yaml
templates/.themis/core/kernel/orchestrator/rules.md
docs/plan/35-core-prompt-flow/manual-replay.md
```

当前没有已批准并已实现的 Themis Go CLI 基线命令，因此该步骤明确标记 `automated-go-check: unavailable`。不得用 Python、Shell 管道或临时脚本替代；由实施者和独立 reviewer 分别核对清单。

- [ ] **步骤 3: 将活动 Plan 35 状态改为“表示迁移待核验”**

在 `impl.md` 和 `docs/plan/README.md` 中明确：

- 2026-07-31 re-acceptance 证明当时的产品语义曾被接受；
- 新的 Markdown-first 仓库规则使 YAML 表示与旧证据失效；
- 当前任务是表示与加载粒度重构，不是 lifecycle 重设计；
- Plan 36/37 在新的 Plan 35 证据完成前继续暂停。

- [ ] **步骤 4: 冻结旧证据而不是删除历史事实**

在四个 evidence 文件顶部增加醒目标记：旧结果只证明 YAML 表示下的历史一致性，不能作为当前 Markdown-first 合规证明。把 `acceptance-audit.md` 当前结果暂时改为：

```text
31 项产品语义待重新映射；criterion 32 待用户审阅新证据后重新确认
```

不得改写旧 replay 场景主体，也不得把历史 re-acceptance 描述成从未发生。

- [ ] **步骤 5: 人工核对所有活动状态入口已停止宣称当前 32/32**

逐个阅读 `impl.md`、`static-verification.md`、`manual-replay.md`、`acceptance-audit.md`、`evidence-summary.md` 和 `docs/plan/README.md`，确认每个入口都明确写出 Markdown 表示迁移待核验，且没有把历史 `32/32` 当作当前表示合规结果。

把核对路径和原文位置写入 `migration-parity/baseline.md`，并把未裁决 GAP 汇总到 `migration-parity.md`。Go CLI 自动检查当前为 unavailable；不得创建替代脚本。

- [ ] **步骤 6: 审查本任务 diff，不提交**

运行：

```bash
git diff -- docs/plan/35-core-prompt-flow docs/plan/README.md
```

确认只改变状态与证据适用边界，不改变产品语义。不得 commit 或 push。

---

### 任务 2: 将 current Plan 35 authority 拆为短入口与功能 references

**文件：**
- 修改： `docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement-design.md`
- 新建： `docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement/authority-model.md`
- 新建： `docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement/request-intake.md`
- 新建： `docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement/current-request-and-dialogue.md`
- 新建： `docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement/capabilities-and-profiles.md`
- 新建： `docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement/public-entry-and-control.md`
- 新建： `docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement/lifecycle-flow.md`
- 新建： `docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement/artifacts-and-workspace.md`
- 新建： `docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement/review-and-delivery.md`
- 新建： `docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement/currentness-failure-recovery.md`
- 新建： `docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement/verification-and-acceptance.md`
- 新建： `docs/plan/35-core-prompt-flow/migration-parity/authority.md`
- 修改： `docs/plan/35-core-prompt-flow/migration-parity.md`

**接口：**
- 输入：原 1292 行 current authority 的全部章节和 任务 1 的表示迁移状态。
- 产出： 同一 current authority 的分层 Markdown 版本；dated spec 路径继续是唯一 cross-module 入口，references 只承载详细合同；`migration-parity/authority.md` 保存实施者观察，task reviewer 的独立复核在任务完成前追加，索引同步链接、结论和 GAP。

- [ ] **步骤 1: 建立章节到 reference 的完整映射**

按以下映射搬迁，不遗漏原章节；把每个原章节、目标 reference 和标题定位写入 `migration-parity/authority.md`：

| Reference | 原设计章节 |
|---|---|
| `authority-model.md` | 背景、目标、设计边界、核心权威模型 |
| `request-intake.md` | Request Intake、外部消息 interception、lifecycle completion 与 Intake retention |
| `current-request-and-dialogue.md` | Current Request claims、Current Request Dialogue Capability |
| `capabilities-and-profiles.md` | 十六个 Capability、四个 Agent Profile、temporary Invocation |
| `public-entry-and-control.md` | Public Skill、Global Rule、Policy、自然语言规则定位信息 |
| `lifecycle-flow.md` | 前台流程、Questioning、simple/full、sticky escalation |
| `artifacts-and-workspace.md` | immutable artifact model、Workspace scoping |
| `review-and-delivery.md` | Review、Approval、Impl、Verification、Acceptance、Summary |
| `currentness-failure-recovery.md` | currentness、invalidation、failure control、duplicate/stale/interruption |
| `verification-and-acceptance.md` | verification strategy、implementation impact、completion/re-acceptance、32 条验收标准 |

- [ ] **步骤 2: 创建十个中文 reference 文件**

每个文件开头写明：

- 它属于哪个 current authority entry；
- 它拥有的主题；
- 它不单独成为第二份设计权威；
- 相关稳定 identity 和不变量。

搬迁时把 `transitions.yaml` 改为 `templates/.themis/core/policies/README.md` policy package，把 paired artifact 改为 `record.md + content.md`，但不得改变字段、状态、门禁或行为。

- [ ] **步骤 3: 重写 dated spec 为短入口**

入口只保留：

1. current authority 身份与适用范围；
2. Markdown-first amendment；
3. 十六 Capability、四 Profile、双 scope、Intake-first、Review-before-Impl、Verify、失败预算等不可绕过摘要；
4. reference 选择表；
5. 修改规则：跨模块行为改变必须同时更新相应 reference、policy、Capability、模板和证据。

入口不得复制 98 条 route、全部 artifact 字段或 32 条验收矩阵。

- [ ] **步骤 4: 人工检查入口和 reference 体积**

使用文件读取工具记录 dated entry 与十个 reference 的实际行数，并把观察写入 `migration-parity/authority.md`。目标上限仍为 entry 180 行、每个 reference 220 行；超过上限时继续按主题拆分，不为满足数字删减合同。

Go CLI 尚未提供文档体积检查命令，因此自动检查标为 unavailable，不得创建 Python 或临时替代脚本。

- [ ] **步骤 5: 人工验证关键语义与 32 条标准仍可定位**

在 `migration-parity/authority.md` 建立 trace checklist，逐项记录以下语义所在的 reference 标题和段落：双 scope、十六 Capability、四 Profile、Current Request Dialogue、`dormant-read-only`、三种 target operation、Review-before-Impl、Impl 后独立 Verification、三次失败预算和 32 条验收标准。

同时确认新 authority 不再把 `transitions.yaml` 或 machine record 当作 current 表示。任何找不到唯一位置的语义都在 `migration-parity/authority.md` 保留为 GAP，并同步更新索引 GAP 汇总。

- [ ] **步骤 6: 审查 reference 链接，不提交**

运行：

```bash
git diff -- docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement-design.md docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement
```

确认入口链接全部存在，且不存在任务状态、占位符或新的 YAML 合同。

---

### 任务 3: 将 `transitions.yaml` 迁移为唯一分层自然语言 Policy

**文件：**
- 修改： `templates/.themis/core/policies/README.md`
- 新建： `templates/.themis/core/policies/references/authority-scopes.md`
- 新建： `templates/.themis/core/policies/references/intake-and-retention.md`
- 新建： `templates/.themis/core/policies/references/capability-bindings.md`
- 新建： `templates/.themis/core/policies/references/materialization-and-currentness.md`
- 新建： `templates/.themis/core/policies/references/guards-invalidation-and-recovery.md`
- 新建： `templates/.themis/core/policies/references/failure-control.md`
- 新建： `templates/.themis/core/policies/references/assurance-boundary.md`
- 新建： `templates/.themis/core/policies/references/routes/intake.md`
- 新建： `templates/.themis/core/policies/references/routes/understanding.md`
- 新建： `templates/.themis/core/policies/references/routes/planning.md`
- 新建： `templates/.themis/core/policies/references/routes/review.md`
- 新建： `templates/.themis/core/policies/references/routes/delivery.md`
- 新建： `templates/.themis/core/policies/references/routes/learning.md`
- 新建： `docs/plan/35-core-prompt-flow/migration-parity/policy.md`
- 修改： `docs/plan/35-core-prompt-flow/migration-parity.md`

**接口：**
- 输入： `transitions.yaml` 的所有顶层 section、十六 Capability 合同、任务 2 current authority。
- 产出： 一个由 `policies/README.md` 进入、按主题和阶段加载的自然语言 Markdown policy candidate；旧 YAML 中观察到的 98 个合法结果组合均能追溯到自然语言规则，但新 Policy 不形成表格 DSL 或机器可解析合同；`migration-parity/policy.md` 保存实施者逐组合观察，task reviewer 的独立复核在任务完成前追加，索引同步链接、结论和 GAP。

- [ ] **步骤 1: 人工建立旧 Policy 迁移清单**

逐段阅读 `transitions.yaml`，在 `migration-parity/policy.md` 中列出十六个顶层主题：policy binding、authority model/scopes、external message interception、completion retention、vocabulary、capabilities、materialization、currentness、recovery、failure control、lifecycle control、invalidation、routes、invalid result 和 assurance。

同时按阶段记录旧 YAML 当前观察到的合法结果组合数量：Intake 3、Understanding 8、Planning 20、Review 24、Delivery 31、Learning 12，合计 98。该数字只用于人工迁移覆盖，不成为新 Policy identity、固定常量或 Go CLI 输入。

- [ ] **步骤 2: 创建 Policy entry 和七个主题 references**

`policies/README.md` 必须声明：

- policy identity 仍为 `themis-core-control`；
- 自然语言规则通过 Capability、selected path、Profile 和 status 定位；
- references 合起来构成一个 Policy，而不是多个 Policy；
- Global Rule 如何按 scope、durable gate 和当前 Capability 选择 reference；
- Capability result 仍只是 proposal；
- 98 只是旧表示的迁移覆盖观察值；
- 当前没有 Go evaluator、parser 或 recorder，不得声称 Markdown 已被机器执行。

七个主题文件逐项迁移旧 YAML section，不压缩掉稳定 identity、枚举、guard、invalidation、failure 和 assurance 语义。

- [ ] **步骤 3: 使用自然语言描述每个控制决定**

六个阶段 reference 不使用固定列、Markdown route table、JSON/YAML 片段或可解析行格式。每个规则组以 Capability 和适用 path/Profile 为标题，并用完整中文句子依次说明：

1. 当 Capability 返回哪个合法 status 时，本规则适用；
2. 哪些 current binding、guard 和 durable fact 必须成立；
3. control plane 必须物化或记录什么；
4. 成功后继续到哪个 Capability、Human Dialogue 或 completion gate；
5. guard 不成立时执行什么替代动作并继续到哪里；
6. 哪些下游 authority、pointer 或 gate 失效；
7. 该结果属于 none、counted 或 non-counted failure；
8. 哪些情况必须停止而不能从自由文本猜测路由。

字段名、状态值和 stable identity 可以保留英文，但它们只能嵌入自然语言合同，不能组合成隐藏 DSL。

- [ ] **步骤 4: 逐项迁移旧 YAML 的 98 个合法结果组合**

按 Intake、Understanding、Planning、Review、Delivery、Learning 六个文件迁移。对每个旧 YAML route，在 `migration-parity/policy.md` 的逐组合清单中记录：旧 Capability/path/Profile/status、对应的新规则标题、next、control action、guard/guard-failure、invalidation 和 failure classification 是否已完整表达。

允许多个完全相同的控制结果共享一段自然语言说明，但迁移清单必须分别证明每个旧合法组合均被覆盖。Complexity Assessment 的 `simple-qualified` 必须同时说明正常 simple 分支和 `full_path_required` guard failure 的 sticky-full action、next 与 invalidation。

- [ ] **步骤 5: 迁移 invalid-result、failure budget 和 unavailable assurance**

`failure-control.md` 必须完整保留：

- Intake/lifecycle identity 和隔离预算；
- 每个 scope-local Execution Identity 最多三次 counted failure；
- counted/non-counted 分类；
- ordered failure actions；
- Failure Learning non-blocking/non-recursive；
- invalid result 的所有适用原因；
- 第三次终止和禁止第四次 Invocation。

`assurance-boundary.md` 必须保留八项 unavailable/forbidden 声明。

- [ ] **步骤 6: 人工执行双向语义核对**

从旧 YAML 到新 Markdown 逐项检查 98 个合法组合，再从新 Markdown 反向检查每个自然语言规则是否都有旧来源或已批准的 Plan 35 authority。重点比较 next、control action、guard-failure、invalidation、failure class 和 stop condition，不能只比较数量或标题。

任何来源冲突都在 `migration-parity/policy.md` 记录为 GAP，并同步更新索引 GAP 汇总；不得由实施 Agent 自行选择或把旧模板漂移提升为新合同。裁决顺序为：current Plan 35 cross-module authority → sole Policy → Capability contract → template → guidance/evidence。

- [ ] **步骤 7: 保留旧 YAML 到全局切换**

本任务只建立并审查自然语言 Policy candidate。`transitions.yaml` 在 任务 9 完成所有消费者引用切换前继续保留，避免中间工作树失去可追溯的旧 Policy；旧文件存在不表示它符合新的 Markdown-first 规则。

- [ ] **步骤 8: 审查 Policy diff，不提交**

运行：

```bash
git diff -- templates/.themis/core/policies
```

确认自然语言规则完整保留 Intake、sticky guard、dormancy、failure budget、invalid-result 和八项 assurance，且不存在固定 route table、parser 指令或 fenced YAML。

---

### 任务 4: 拆分 Global Rule 并更新公共 `themis` 入口

**文件：**
- 修改： `templates/.themis/core/kernel/orchestrator/rules.md`
- 修改： `templates/.themis/core/kernel/orchestrator/README.md`
- 新建： `templates/.themis/core/kernel/orchestrator/references/intake-entry.md`
- 新建： `templates/.themis/core/kernel/orchestrator/references/invocation-and-materialization.md`
- 新建： `templates/.themis/core/kernel/orchestrator/references/lifecycle-continuation.md`
- 新建： `templates/.themis/core/kernel/orchestrator/references/review-and-completion.md`
- 新建： `templates/.themis/core/kernel/orchestrator/references/failure-invalidation-recovery.md`
- 新建： `templates/.themis/core/kernel/orchestrator/references/safe-degradation.md`
- 修改： `templates/.claude/skills/themis/SKILL.md`
- 新建： `docs/plan/35-core-prompt-flow/migration-parity/control-entry.md`
- 修改： `docs/plan/35-core-prompt-flow/migration-parity.md`

**接口：**
- 输入： 任务 3 Markdown policy package 和现有 307 行 Global Rule。
- 产出： 一个短常驻 Rule、六个按 gate 加载的 reference，以及只引用 Markdown policy 的公共治理入口；`migration-parity/control-entry.md` 保存实施者观察，task reviewer 的独立复核在任务完成前追加，索引同步链接、结论和 GAP。

- [ ] **步骤 1: 将现有 Rule 章节分配到六个 references**

使用以下映射：

| Reference | Rule 内容 |
|---|---|
| `intake-entry.md` | Source Event、attachment、Current Request confirmation、assignment materialization |
| `invocation-and-materialization.md` | preflight、temporary Invocation、proposed result、唯一适用的自然语言控制规则、record/reread/pointer |
| `lifecycle-continuation.md` | Questioning、Grounding、Assessment、simple/full、Plan Check |
| `review-and-completion.md` | Review、Approval、Verify、Acceptance、Summary、completion retention |
| `failure-invalidation-recovery.md` | sticky escalation、invalidation、failure、last proven gate recovery |
| `safe-degradation.md` | unavailable runtime、fail-closed、禁止模拟执行 |

- [ ] **步骤 2: 创建六个中文 reference 文件**

每个 reference 必须：

- 引用 `../../../policies/README.md` 或其具体 reference；
- 只解释通用控制顺序，不复制六个阶段的具体自然语言规则；
- 明确加载条件和返回到哪个 durable continuation；
- 保留 scope、binding、currentness 和 non-bypass 规则。

- [ ] **步骤 3: 重写 `rules.md` 为常驻最小入口**

`rules.md` 只保留：

1. 唯一 always-loaded 控制职责；
2. Intake-first；
3. authority scopes 与不可共享内容；
4. policy/Capability/Profile/Workspace ownership；
5. 如何按当前 durable gate 加载一个或多个 references；
6. 必须选择唯一适用的自然语言控制规则，且 complete materialization 不可绕过；
7. chat、summary、file existence、recommended route 不构成 authority；
8. 缺失 runtime 时停止。

不得在 `rules.md` 内复制六个阶段的全部自然语言规则或全部 artifact 字段。

- [ ] **步骤 4: 更新 orchestrator README**

README 说明 package 文件角色、reference 索引和加载顺序，不再引用 `transitions.yaml`、machine record 或 YAML。

- [ ] **步骤 5: 更新公共 `themis` Skill**

把 Skill 的加载流程改为：

```text
rules.md
→ policies/README.md
→ 当前 gate 对应的 orchestrator reference
→ 当前 Capability/Profile 对应的自然语言 Policy 阶段 reference
→ one temporary Invocation
```

保留最小 `name`/`description` frontmatter；正文不得增加其他 frontmatter 字段或 YAML 合同。把“唯一公共项目 Skill”改为“唯一公共 `themis` 治理入口”。

- [ ] **步骤 6: 人工验证文件体积和引用边界**

在 `migration-parity/control-entry.md` 中记录 `rules.md`、六个 orchestrator references 和公共 `SKILL.md` 的实际行数与链接。目标上限为 `rules.md` 140 行、每个 reference 180 行；逐项确认：

- `rules.md` 不复制阶段规则或 artifact 字段；
- Skill 指向 `policies/README.md`；
- Rule 与 Skill 均不再把 `transitions.yaml` 当作 current authority；
- references 加载条件覆盖 Intake、Invocation、Lifecycle、Review/Completion、Failure/Recovery 和 safe degradation。

自动 Go 检查当前 unavailable；不得用其他脚本代替。

- [ ] **步骤 7: 审查控制流，不提交**

运行：

```bash
git diff -- templates/.themis/core/kernel/orchestrator templates/.claude/skills/themis/SKILL.md
```

确认 Intake-first、materialization、recovery、dormancy 和 safe degradation 没有被入口缩短而删除。

---

### 任务 5: 创建 Intake、需求与 Planning Markdown 工件模板

**文件：**
- 新建： `templates/.themis/core/templates/request-intake/source-event.md`
- 新建： `templates/.themis/core/templates/request-intake/proposal.md`
- 新建： `templates/.themis/core/templates/request-intake/decision.md`
- 新建： `templates/.themis/core/templates/current-request/record.md`
- 新建： `templates/.themis/core/templates/current-request/content.md`
- 新建： `templates/.themis/core/templates/questioning-round/record.md`
- 新建： `templates/.themis/core/templates/questioning-round/content.md`
- 新建： `templates/.themis/core/templates/grounding/record.md`
- 新建： `templates/.themis/core/templates/complexity-assessment/record.md`
- 新建： `templates/.themis/core/templates/plan/record.md`
- 新建： `templates/.themis/core/templates/plan/content.md`
- 新建： `templates/.themis/core/templates/plan-check/record.md`
- 新建： `docs/plan/35-core-prompt-flow/migration-parity/intake-and-planning-templates.md`
- 修改： `docs/plan/35-core-prompt-flow/migration-parity.md`

**接口：**
- 输入： 对应的九个旧 YAML、三个旧 Markdown content、任务 2 artifact model、任务 3 materialization policy。
- 产出： 尚未切换 authority 的候选 Markdown templates；任务 6 完成其余候选与全模板 parity 检查后，仍由任务 9 全局 cutover 统一删除旧 YAML 与 flat templates；`migration-parity/intake-and-planning-templates.md` 保存实施者观察，task reviewer 的独立复核在任务完成前追加，索引同步链接、结论和 GAP。

- [ ] **步骤 1: 为每个旧模板建立字段迁移清单**

逐个读取旧文件，把每个字段记录到目标 Markdown 的“字段合同”表。表列统一为：

```text
字段 | 必填性 | 合法值/格式 | 来源或绑定 | 语义
```

嵌套列表使用独立子表；不得把旧字段折叠成一个泛化的“metadata”或“details”。

- [ ] **步骤 2: 迁移三个 Intake 记录**

保持：

- exact Source Event bytes reference、length、digest placeholder、transport metadata、attachment reason；
- changed-only claim/assignment proposal、item dispositions、original continuation；
- immutable decision、per-target operation/status/observation、remaining target identities、resume-only recovery。

这些文件是结构化 Markdown 记录，不创建额外 content half。

- [ ] **步骤 3: 迁移 Current Request pair**

`record.md` 拥有 identity、scope、lifecycle、assignment decision、claim revisions、content path/digest、materialization observation、disposition 和 pointer observation；`content.md` 只呈现确认 claims 与 exact Source Event fragments。

- [ ] **步骤 4: 迁移 per-round Questioning pair**

保留 previous round、question proposal/continuation、answer Source Event refs、post-answer Current Request revision、Why/abstract What、materialization observation。明确 unanswered question 仍是 proposal/continuation，不形成 completed round。

- [ ] **步骤 5: 迁移 Grounding 与 Complexity Assessment records**

保持 evidence、unknowns、status、binding、selected path 候选和 sticky-full 相关字段；只改变表示，不增加 validator 或自动判断。

- [ ] **步骤 6: 迁移统一 Plan pair 与 Plan Check record**

`plan/content.md` 保留 simple/full 共用的目标、范围、核心 flow、contracts、acceptance、facts、trade-offs、impact、failure/recovery、Impl tasks、Verification tasks 和四类 authority coverage。`plan/record.md` 保留所有旧 `plan.yaml` bindings。Plan Check 保持 lightweight/full 两套合法状态。

- [ ] **步骤 7: 人工验证候选文件完整且不含 YAML**

按照本任务文件清单逐项确认 12 个候选 Markdown 存在，并阅读其字段合同。对三个 paired record 逐项核对 revision、content、materialization 和 pointer 语义；确认所有候选均无 fenced YAML。

把逐文件结论写入 `migration-parity/intake-and-planning-templates.md`，并把未裁决 GAP 同步到索引。当前没有 Go CLI 文档合同检查命令，自动化状态为 unavailable。

- [ ] **步骤 8: 不切换 authority、不删除旧文件、不提交**

本任务只建立候选模板并做 parity review。旧 templates 继续存在到任务 9 全局 cutover，防止出现部分 family 使用旧 authority、部分使用新 authority 的未声明状态。

---

### 任务 6: 迁移 Review、Delivery、Outcome 与 Learning 模板候选

**文件：**
- 新建： `templates/.themis/core/templates/review-projection/record.md`
- 新建： `templates/.themis/core/templates/review-projection/content.md`
- 新建： `templates/.themis/core/templates/review-check/record.md`
- 新建： `templates/.themis/core/templates/review-approval/record.md`
- 新建： `templates/.themis/core/templates/review-approval/content.md`
- 新建： `templates/.themis/core/templates/review-feedback/record.md`
- 新建： `templates/.themis/core/templates/review-feedback/content.md`
- 新建： `templates/.themis/core/templates/impl-result/record.md`
- 新建： `templates/.themis/core/templates/impl-result/content.md`
- 新建： `templates/.themis/core/templates/verification/record.md`
- 新建： `templates/.themis/core/templates/verification/content.md`
- 新建： `templates/.themis/core/templates/acceptance/record.md`
- 新建： `templates/.themis/core/templates/acceptance/content.md`
- 新建： `templates/.themis/core/templates/summary/record.md`
- 新建： `templates/.themis/core/templates/summary/content.md`
- 新建： `templates/.themis/core/templates/failure-learning/record.md`
- 新建： `templates/.themis/core/templates/failure-learning/content.md`
- 新建： `templates/.themis/core/templates/context/resolution.md`
- 新建： `templates/.themis/core/templates/context/summary.md`
- 修改： `templates/.themis/core/templates/README.md`
- 新建： `docs/plan/35-core-prompt-flow/migration-parity/review-and-delivery-templates.md`
- 修改： `docs/plan/35-core-prompt-flow/migration-parity.md`

**接口：**
- 输入： 任务 5 candidate templates、剩余九个 YAML、旧 flat Markdown halves、Review/Delivery policy。
- 产出： 完整 Markdown template candidate package；旧 YAML 和 flat templates 保留到任务 9 全局 authority cutover；`migration-parity/review-and-delivery-templates.md` 保存实施者观察，task reviewer 的独立复核在任务完成前追加，索引同步链接、结论和 GAP。

- [ ] **步骤 1: 迁移 Review Projection 与 Review Check**

保留 checked Plan binding、图形 Overview、抽象到具体的精简 review items、projection fidelity、presentation burden 和合法状态。Review Projection 仍是只读投影，不是执行输入。

- [ ] **步骤 2: 迁移 Review Approval 与 Review Feedback**

Approval 必须继续绑定 assignment decision、Current Request/claims、Questioning、constraints、Grounding/Assessment、path/profile/sticky flag、checked Plan/Plan Check、shown Projection/Review Check、approval Source Event/time 和 pre-Impl baseline。Feedback 保持七个 approved semantic owners，不能直接 patch Plan/projection。

- [ ] **步骤 3: 迁移 Impl Result 与 Verification**

Impl Result 保持 actual delta、task/attempt、commands、deviations、external drift 和非 Verification verdict。Verification 保持独立 checker、baseline/delta/evidence、passed/failed/rework 状态和 currentness。

- [ ] **步骤 4: 迁移 Acceptance、Summary 与 Failure Learning**

保持：

- Acceptance 是人工观察，不重复技术验证；
- Summary 只在 current Verification `passed` 且 Human Acceptance `accepted` 后产生；
- Failure Learning scope-bound、candidate-only、non-blocking、non-recursive；
- knowledge candidate 失败不阻塞已完成交付。

- [ ] **步骤 5: 移动 Context 辅助模板**

把 `context-resolution.md` 和 `context-summary.md` 移入 `templates/context/`，只更新路径，不扩张其职责或使其成为 lifecycle authority。

- [ ] **步骤 6: 重写 Templates README**

README 必须声明：

- 十一类 paired family；
- 七类结构化/操作 Markdown record（Intake 三类、Grounding、Assessment、Plan Check、Review Check）；
- `record.md + content.md` 缺失/mismatch 的整体 invalidation；
- revision、attempt、pointer、incomplete operation、retention fact 分离；
- template 只提供 Prompt-level shape，不证明 machine validation 或 persistence。

- [ ] **步骤 7: 人工执行全模板 parity 检查**

逐项确认十一类 paired family 都有 `record.md` 与 `content.md`，七类 structured record 和两个 Context aid 均存在。对每个旧 YAML/flat Markdown 字段，在 `migration-parity/review-and-delivery-templates.md` 中记录新位置、合法值和 disposition；任何无法追溯或合同冲突都保持 GAP，并同步更新索引。

由独立 reviewer 反向从新 Markdown 抽查回旧来源，防止同名空壳或字段折叠。自动 Go 检查当前 unavailable。

- [ ] **步骤 8: 保留旧模板到全局 authority cutover**

本任务不删除十八个 YAML 或旧 flat Markdown。只有任务 9 已完成所有 Capability、Rule、Workspace、guidance 引用切换，并且 `migration-parity.md` 及任务 1–8 分片无未裁决 GAP 后，才统一删除：

```text
current-request.md
questioning-round.md
plan.md
review.md
review-approval.md
review-feedback.md
impl-result.md
verification.md
acceptance.md
summary.md
failure-learning.md
context-resolution.md
context-summary.md
```

- [ ] **步骤 9: 人工核对候选 template package 的表示边界**

逐个检查新模板，确认无 fenced YAML、`machine record`、`<artifact>.yaml` 或其他旧 pair authority 术语，并确认 `record.md + content.md` 的整体 invalidation 仍有自然语言定义。

本步骤在全局 cutover 前只核对候选文件；YAML 清零由任务 9 删除后和 任务 10 evidence review 证明。

- [ ] **步骤 10: 审查 templates diff，不提交**

运行：

```bash
git diff -- templates/.themis/core/templates
```

重点核对所有旧字段、合法值、materialization observation、pointer 和 mismatch invalidation 都在新文件中有明确位置。

---

### 任务 7: 将十六个 Capability 的 YAML result envelope 改为 Markdown 字段合同

**文件：**
- 修改： `templates/.themis/core/capabilities/README.md`
- 修改： `templates/.themis/core/capabilities/current-request-dialogue.md`
- 修改： `templates/.themis/core/capabilities/questioning.md`
- 修改： `templates/.themis/core/capabilities/grounding.md`
- 修改： `templates/.themis/core/capabilities/complexity-assessment.md`
- 修改： `templates/.themis/core/capabilities/simple-planning.md`
- 修改： `templates/.themis/core/capabilities/specification.md`
- 修改： `templates/.themis/core/capabilities/planning.md`
- 修改： `templates/.themis/core/capabilities/plan-check.md`
- 修改： `templates/.themis/core/capabilities/review-projection.md`
- 修改： `templates/.themis/core/capabilities/review-check.md`
- 修改： `templates/.themis/core/capabilities/review-dialogue.md`
- 修改： `templates/.themis/core/capabilities/implementation.md`
- 修改： `templates/.themis/core/capabilities/verification.md`
- 修改： `templates/.themis/core/capabilities/acceptance-dialogue.md`
- 修改： `templates/.themis/core/capabilities/failure-learning.md`
- 修改： `templates/.themis/core/capabilities/summary.md`
- 新建： `docs/plan/35-core-prompt-flow/migration-parity/capabilities.md`
- 修改： `docs/plan/35-core-prompt-flow/migration-parity.md`

**接口：**
- 输入： 任务 3 capability bindings/routes、任务 5–6 materialization targets、现有 Capability 合同中的 fenced YAML output。
- 产出： 保持单一能力文件结构的十六个 Markdown-only result contracts；不机械创建十六个目录；`migration-parity/capabilities.md` 保存实施者观察，task reviewer 的独立复核在任务完成前追加，索引同步链接、结论和 GAP。

- [ ] **步骤 1: 人工确认 Capability 文件与 YAML block 基线**

逐项列出 README 和十六个 Capability 文件，记录每个文件当前 fenced YAML output 所在章节。基线应为十六个 Capability 加一个 README，共十七个包含 YAML block 的文件；任何差异先作为 GAP 调查。

不得用 Python 或临时脚本计数；Go CLI 自动检查当前 unavailable。

- [ ] **步骤 2: 重写 common result envelope**

在 README 中使用 Markdown 表格声明以下公共字段，不改名：

```text
capability
authority_scope
agent_profile
status
input_bindings
output.structured_result
output.proposed_artifact_references
output.materialization_target
diagnostics.gaps
diagnostics.evidence
diagnostics.affected_semantics
recommended_route
```

字段名必须与现有稳定合同逐字一致，不允许借表示迁移重命名。

- [ ] **步骤 3: 为每个 Capability 建立固定章节**

每个文件保持当前单文件，并统一包含：

```text
身份与固定绑定
能力目标
输入
合法状态
输出字段合同
权限与边界
停止条件
```

“输出字段合同”分为 input bindings、structured result、artifact refs/materialization、diagnostics/recommended route 四张表。

- [ ] **步骤 4: 逐文件迁移所有嵌套 output 字段**

不得只引用 common envelope 而删除 Capability-specific 字段。例如 `themis-impl` 必须继续列出：

```text
actual_changes
completion_results
deviations
external_drift
command_evidence_references
```

其他 Capability 同样逐字段保留现有 structured result、bindings、affected semantics 和 materialization target。

- [ ] **步骤 5: 保持合法状态和 path/profile 域**

每个 Capability 的“合法状态”增加表格列：

```text
Selected path | Profile | Status | 语义
```

必须保留 quick-only 状态限制，例如 full path 不允许 `escalate-full`，Plan Check 的 lightweight/full 状态集合不同。

- [ ] **步骤 6: 人工验证 Markdown-only 合同形状**

逐个 Capability 检查固定章节、common envelope 字段、Capability-specific structured result、合法 status、path/Profile 域、权限和停止条件。确认十六个文件及 README 均不含 fenced YAML，并把结果写入 `migration-parity/capabilities.md`；未裁决 GAP 同步更新索引。

该检查是人工合同审阅；不得声明 machine validation。Go CLI 自动检查当前 unavailable。

- [ ] **步骤 7: 交叉核对 policy mapping**

逐项比较 `capability-bindings.md` 与十六个文件的 stable identity、scope、Profile、selected path/profile、legal statuses 和 target。任何差异都修正为旧已接受合同的值，不通过新增 route 解决。

- [ ] **步骤 8: 审查 Capability diff，不提交**

运行：

```bash
git diff -- templates/.themis/core/capabilities
```

确认只改变表示形状，没有改变推理职责、权限、状态或 route ownership。

---

### 任务 8: 将 Core、Workspace 与 Context 的剩余 YAML 迁移为 Markdown

**文件：**
- 新建： `templates/.themis/core/README.md`
- 修改： `templates/.themis/workspace/README.md`
- 新建： `templates/.themis/workspace/project.md`
- 新建： `templates/.themis/workspace/references/directory-ownership.md`
- 新建： `templates/.themis/workspace/references/intake-and-lifecycle-isolation.md`
- 新建： `templates/.themis/workspace/references/artifact-and-state-model.md`
- 新建： `templates/.themis/workspace/references/completion-retention.md`
- 新建： `templates/.themis/workspace/references/recovery-and-cache.md`
- 新建： `templates/.themis/workspace/context/catalog.md`
- 修改： `templates/.themis/core/protocols/README.md`
- 新建： `templates/.themis/core/protocols/context/README.md`
- 新建： `templates/.themis/core/protocols/context/references/common-fields.md`
- 新建： `templates/.themis/core/protocols/context/references/context-item.md`
- 新建： `templates/.themis/core/protocols/context/references/catalog.md`
- 新建： `templates/.themis/core/protocols/context/references/bundle.md`
- 新建： `templates/.themis/core/protocols/context/references/signal.md`
- 修改： `templates/.themis/core/adapters/README.md`
- 新建： `docs/plan/35-core-prompt-flow/migration-parity/core-workspace-context.md`
- 修改： `docs/plan/35-core-prompt-flow/migration-parity.md`

**接口：**
- 输入： `core.yaml` package paths、`manifest.yaml` project settings、六个 Context YAML、Workspace README 的 ownership/retention/recovery 合同。
- 产出： Markdown-only Core package index、project configuration template、Workspace references 和 Context descriptive protocols；`migration-parity/core-workspace-context.md` 保存实施者观察，task reviewer 的独立复核在任务完成前追加，索引同步链接、结论和 GAP。

- [ ] **步骤 1: 创建 Core package index**

`core/README.md` 用链接表替代 `core.yaml`，保留：

```text
package identity
public entry
Global Rule
policy entry
Capability contracts
Agent Profile contracts
template contracts
Workspace boundary
```

不保留 `schema`/`workspace_schema`/`artifact_schema` 作为虚假机器 Schema identity；用自然语言说明这些当前是 Prompt-level package contracts。

- [ ] **步骤 2: 创建 `workspace/project.md`**

使用 Markdown 表格保留原 manifest 的所有配置槽：

- project name/root；
- lint/build/test commands；
- Context entry points/external sources；
- gates；
- adapters；
- restricted policy overrides；
- policies/context/intakes/changes/state/runs/evidence/outcomes/knowledge/cache paths。

空值使用 `未配置`，不得使用 YAML `null` block。

- [ ] **步骤 3: 拆分 Workspace README**

README 只保留职责、不可绕过 scope/authority 边界和 reference 索引。把 directory ownership、scope isolation、artifact/state、completion retention、recovery/cache 分别迁入五个 references。

- [ ] **步骤 4: 迁移 Workspace Context catalog**

`workspace/context/catalog.md` 使用“绑定”“项目”“revision 观察”“条目索引”章节和 Markdown 表格替代 YAML；保持 `unbound`、root、commit/worktree observation、digest placeholder 和 items 语义。

- [ ] **步骤 5: 迁移五个 Context descriptive protocols**

建立短 `protocols/context/README.md` 和五个 references。逐项保留 common result、Context item、catalog、bundle、signal 的字段、枚举、约束和引用关系。

`context-item.md` 必须把旧 `markdown-with-yaml-frontmatter` 改为纯 Markdown 固定章节与字段表，不得继续要求 YAML frontmatter。

- [ ] **步骤 6: 更新 Protocols 与 Adapters 边界**

把 `protocols/README.md` 中 descriptive YAML 改为 descriptive Markdown；把 `adapters/README.md` 的输入路径从 `workspace/manifest.yaml` 改为 `workspace/project.md`。不得实现 adapter runtime。

- [ ] **步骤 7: 保留八个旧 YAML 到全局切换**

本任务创建并审查 Core、Workspace 与 Context Markdown candidates，但不立即删除以下旧文件：

```text
core/core.yaml
workspace/manifest.yaml
workspace/context/catalog.yaml
core/protocols/context/common-schema.yaml
core/protocols/context/context-item-schema.yaml
core/protocols/context/catalog-schema.yaml
core/protocols/context/bundle-schema.yaml
core/protocols/context/signal-schema.yaml
```

这些文件只在任务 9 全局 authority cutover、所有引用已切换且 `migration-parity.md` 及任务 1–8 分片无未裁决 GAP 后统一删除。

- [ ] **步骤 8: 人工核对 Core、Workspace 与 Context candidates**

逐项确认 `core/README.md`、`workspace/project.md`、`workspace/context/catalog.md`、Workspace 五个 references、Context protocol entry 和五个 references 均存在，并能追溯旧 YAML 的全部配置槽、字段、枚举和边界。把逐项观察写入 `migration-parity/core-workspace-context.md`，并将未裁决 GAP 同步到索引。

此时旧 YAML 仍作为迁移来源存在；YAML `27 → 0` 只能在 任务 9 cutover 后声明。Go CLI 自动检查当前 unavailable。

- [ ] **步骤 9: 人工检查入口体积**

记录 Workspace README、Context protocol README 和 Core README 的实际行数，目标上限分别为 140、120、120。若超限，按职责继续拆 reference，不删减合同。自动 Go 检查当前 unavailable。

- [ ] **步骤 10: 审查 package diff，不提交**

运行：

```bash
git diff -- templates/.themis/core templates/.themis/workspace
```

确认 Context 仍只提供经验/候选相关描述和 resolution 支持，不被扩张为当前代码事实或 lifecycle authority。

---

### 任务 9: 对齐全部消费者并执行全局 Markdown authority cutover

**文件：**
- 修改： `templates/.themis/README.md`
- 修改： `templates/.themis/CLAUDE.themis.md`
- 修改： `templates/.themis/core/kernel/orchestrator/README.md`
- 修改： `templates/.themis/core/kernel/specification/README.md`
- 修改： `templates/.themis/core/kernel/planning/README.md`
- 修改： `templates/.themis/core/kernel/implementation/README.md`
- 修改： `templates/.themis/core/kernel/verification/README.md`
- 修改： `templates/.themis/core/kernel/knowledge/README.md`
- 修改： `docs/plan/35-core-prompt-flow/impl.md`
- 修改： `docs/plan/README.md`
- 修改： `docs/plan/36-deterministic-assurance/impl.md`
- 修改： `docs/plan/37-native-runtime/impl.md`
- 修改： `docs/plan/80-multi-agent-execution/impl.md`
- 修改： `docs/superpowers/plans/2026-07-31-plan-35-core-contract-replacement.md`
- 修改： `docs/superpowers/plans/2026-07-30-plan-35-policy-capability-execution.md`
- 修改： `docs/superpowers/specs/2026-07-30-plan-35-policy-capability-execution-design.md`
- 修改： `docs/superpowers/specs/2026-07-29-plan-35-core-prompt-flow-design.md`
- 新建： `docs/plan/35-core-prompt-flow/migration-parity/cutover.md`
- 修改： `docs/plan/35-core-prompt-flow/migration-parity.md`
- 删除： `templates/.themis/core/policies/transitions.yaml`
- 删除： `templates/.themis/core/core.yaml`
- 删除： `templates/.themis/workspace/manifest.yaml`
- 删除： `templates/.themis/workspace/context/catalog.yaml`
- 删除： `templates/.themis/core/protocols/context/common-schema.yaml`
- 删除： `templates/.themis/core/protocols/context/context-item-schema.yaml`
- 删除： `templates/.themis/core/protocols/context/catalog-schema.yaml`
- 删除： `templates/.themis/core/protocols/context/bundle-schema.yaml`
- 删除： `templates/.themis/core/protocols/context/signal-schema.yaml`
- 删除： `templates/.themis/core/templates/request-intake-source-event.yaml`
- 删除： `templates/.themis/core/templates/request-intake-proposal.yaml`
- 删除： `templates/.themis/core/templates/request-intake-decision.yaml`
- 删除： `templates/.themis/core/templates/current-request.yaml`
- 删除： `templates/.themis/core/templates/questioning-round.yaml`
- 删除： `templates/.themis/core/templates/grounding.yaml`
- 删除： `templates/.themis/core/templates/complexity-assessment.yaml`
- 删除： `templates/.themis/core/templates/plan.yaml`
- 删除： `templates/.themis/core/templates/plan-check.yaml`
- 删除： `templates/.themis/core/templates/review.yaml`
- 删除： `templates/.themis/core/templates/review-check.yaml`
- 删除： `templates/.themis/core/templates/review-approval.yaml`
- 删除： `templates/.themis/core/templates/review-feedback.yaml`
- 删除： `templates/.themis/core/templates/impl-result.yaml`
- 删除： `templates/.themis/core/templates/verification.yaml`
- 删除： `templates/.themis/core/templates/acceptance.yaml`
- 删除： `templates/.themis/core/templates/summary.yaml`
- 删除： `templates/.themis/core/templates/failure-learning.yaml`
- 删除： `templates/.themis/core/templates/current-request.md`
- 删除： `templates/.themis/core/templates/questioning-round.md`
- 删除： `templates/.themis/core/templates/plan.md`
- 删除： `templates/.themis/core/templates/review.md`
- 删除： `templates/.themis/core/templates/review-approval.md`
- 删除： `templates/.themis/core/templates/review-feedback.md`
- 删除： `templates/.themis/core/templates/impl-result.md`
- 删除： `templates/.themis/core/templates/verification.md`
- 删除： `templates/.themis/core/templates/acceptance.md`
- 删除： `templates/.themis/core/templates/summary.md`
- 删除： `templates/.themis/core/templates/failure-learning.md`
- 删除： `templates/.themis/core/templates/context-resolution.md`
- 删除： `templates/.themis/core/templates/context-summary.md`
- 删除： `templates/.themis/core/templates/.gitkeep`

**接口：**
- 输入： 任务 1 的基线 evidence 与任务 2–8 的最终路径、terminology 和迁移分片。
- 产出： 所有活动消费者统一引用自然语言 Markdown Policy、record/content artifacts、project.md 和拆分 references；在 `migration-parity.md` 及任务 1–8 分片无未裁决 GAP 后一次删除 27 个旧 YAML 与被替代的 flat templates，避免跨任务 authority 断裂；`migration-parity/cutover.md` 保存实施者删除矩阵观察，task reviewer 的独立复核在任务完成前追加，索引同步最终 cutover 结论和 GAP。

- [ ] **步骤 1: 更新安装包总览**

`templates/.themis/README.md` 与 `CLAUDE.themis.md` 必须说明：

```text
一个公共 `themis` 治理入口
→ 一个 Global Rule 入口和按需 references
→ 一个 Markdown Policy 包
→ 一个 Capability 与固定 Profile
→ proposed result
→ 唯一适用的自然语言控制规则
→ 完整物化并重读 record/content
```

把 `transitions.yaml`、`manifest.yaml`、machine record 等旧路径全部替换。

- [ ] **步骤 2: 更新 kernel package READMEs**

更新以下六个实际包含旧 YAML 路径或表示术语的 package README：

```text
kernel/orchestrator/README.md
kernel/specification/README.md
kernel/planning/README.md
kernel/implementation/README.md
kernel/verification/README.md
kernel/knowledge/README.md
```

只改路径、表示术语和 references；不得改变模块职责。`kernel/context/README.md`、`kernel/review/README.md`、`kernel/attribution/README.md` 与 `agent-profiles/README.md` 当前没有旧 YAML 路径，不为制造 diff 而改写。

- [ ] **步骤 3: 更新 Plan 35 active implementation description**

`docs/plan/35-core-prompt-flow/impl.md` 改为 Markdown-first fixed architecture，并列出本重构的文件层次、验证步骤和重新接受门禁。删除“一个 transitions.yaml”和 YAML pair 的 current claim。

- [ ] **步骤 4: 暂停并标记 Plan 36/37/80 的旧 YAML 假设**

只更新顶部 status/rebaseline notice：

- 旧正文包含的 `transitions.yaml`、strict YAML Schema 或 runtime parse 假设已失效；
- 必须等待本重构完成和用户重新接受后，依据 Markdown-first Plan 35 重新设计；
- 不在本任务内实现或逐段修补后续计划。

Plan 90 如未引用这些表示，不修改主体。

- [ ] **步骤 5: 标记历史计划的表示层已被取代**

在历史 Plan 35 计划/设计顶部增加短说明：其执行记录保留为历史，但 YAML 表示说明已被 `2026-08-01-plan-35-markdown-contract-refactor.md` 取代。不得重写历史任务正文。

- [ ] **步骤 6: 人工扫描活动文件的旧表示引用**

逐项阅读以下活动范围，并记录每个旧术语命中的路径、语境和处置：`templates/.themis`、公共 `themis` Skill、Plan 35 active docs、Plan index 和 current authority entry/references。

禁止残留把 `transitions.yaml`、`manifest.yaml`、`core.yaml`、machine record 或 `<artifact>.yaml` 当作 current authority 的陈述；历史 supersession notice 可以保留旧路径，但必须明确标注为历史来源。

- [ ] **步骤 7: 人工验证固定产品不变量仍出现在活动 guidance**

逐项追溯并记录 `request-intake`、`lifecycle`、十六 Capability、四 Profile、Review-before-Impl、`themis-impl`、独立 `themis-verification`、Human Acceptance、Summary 与 `dormant-read-only` 的当前位置。任何语义只能在一个 authority owner 下有明确合同，不接受仅凭关键词出现的 PASS。

- [ ] **步骤 8: 执行全局 authority cutover**

只有以下条件全部满足时才切换：

- 任务 1–8 的所有 Markdown candidates 与迁移 evidence 已完成；
- Policy 的 98 个旧合法结果组合已有双向人工迁移记录；
- 十六 Capability、十一 paired family、七 structured records、Workspace 与 Context 对应 evidence 分片均有实施者与 fresh reviewer 核对，且 `migration-parity.md` 无未裁决 GAP；
- 所有活动消费者已经改为新路径；
- 合同冲突已按 authority precedence 裁决并记录。

随后一次删除迁移矩阵中的 27 个 YAML、十三个被目录结构替代的 flat Markdown template 和 `.gitkeep`。不得在更早任务中分批删除。

- [ ] **步骤 9: 双人式人工核对 cutover 结果**

实施者先按 27 项迁移矩阵逐项确认“旧路径不存在、新路径存在、消费者已切换”；fresh reviewer 再独立复核。两次核对结果都写入 `migration-parity/cutover.md`，分歧保持 GAP 并同步到索引。

当前没有已实现的 Themis Go CLI 命令可自动完成该检查，因此记录 `automated-go-check: unavailable`，不得虚构命令或创建临时脚本。

- [ ] **步骤 10: 审查 guidance 与 cutover diff，不提交**

运行：

```bash
git diff -- templates/.themis templates/.claude/skills/themis docs/plan docs/superpowers/specs docs/superpowers/plans
```

确认后续计划只更新状态 notice，历史正文未被伪装成新实施结果。

---

### 任务 10: 重建 Markdown-first 人工一致性证据

**文件：**
- 重写： `docs/plan/35-core-prompt-flow/static-verification.md`
- 修改： `docs/plan/35-core-prompt-flow/evidence-summary.md`

**接口：**
- 输入： 任务 2–9 的最终 Markdown contracts、`migration-parity.md`、九个 `migration-parity/*.md` 分片和任务 1 工作树基线。任务 10 只读迁移 evidence，不得改写其观察或 GAP。
- 产出： 新的人工静态观察结果；证明表示迁移经过逐项审阅并保持内部一致，但不声称 Go CLI、Plan 36 validator 或 Plan 37 runtime 已执行。

- [ ] **步骤 1: 编写核验边界**

`static-verification.md` 开头明确：

- 人工检查 Markdown 文件树、字段合同、引用、自然语言控制规则覆盖和不变量；
- 项目不使用 Python，本次不创建一次性验证脚本；
- 自动核验只允许由已批准并已实现的 Themis Go CLI 提供，当前状态为 unavailable；
- 不证明 digest、recording、transition、write、pointer 或 recovery 已运行；
- 工作树基线被保留。

- [ ] **步骤 2: 核验 YAML 清零和宿主 frontmatter 例外**

记录自然语言人工观察：

- `templates/.themis` 中活动产品 YAML 数量为 0，人工结论为通过；
- `templates/.claude/skills/themis/SKILL.md` 只包含宿主要求的 `name` 与 `description` frontmatter，人工结论为通过；
- 自动 Go CLI 检查为 `unavailable`。

检查 `templates/.themis` 无 YAML；`templates/.claude/skills/themis/SKILL.md` 只保留宿主要求的 `name` 和 `description`。

- [ ] **步骤 3: 核验 authority、Rule 和 references 体积**

记录 current spec entry、十个 spec refs、Global Rule、六个 Rule refs、policy entry、七个 policy refs、六个 route files、Workspace/Context entries 的文件数量与行数上限。

- [ ] **步骤 4: 核验 Capability/Profile 固定集合**

断言：

- 名为 `themis` 的公共治理 Skill 恰好一个；
- Capability contracts 恰好十六个；
- Profile contracts 恰好四个；
- fixed scope/Profile mappings 全部一致；
- 只有 `themis-impl` 使用 `implementation-writer`；
- Capability 文件无 fenced YAML，且均有输入、合法状态、输出字段、权限、停止条件。

- [ ] **步骤 5: 核验自然语言控制规则的完整 status coverage**

使用 `migration-parity/policy.md` 的逐组合迁移清单，逐项确认旧 YAML 中观察到的 98 个 Capability/path/Profile/status 组合都能定位到唯一自然语言规则，并核对：

- 没有两个规则对同一 durable facts 给出冲突控制动作；
- quick-only status 不出现在 full path；
- `full_path_required` guard failure 的 sticky-full 行为完整；
- dormancy 不成为 Capability status；
- next、control action、guard failure、invalidation、failure class 和 stop condition 均有自然语言说明；
- 新 Policy 不要求 parser、固定表格或机器行格式。

98 仅是迁移覆盖观察值。核验失败时记录具体组合和缺失语义，不得用数量相等代替语义等价。

- [ ] **步骤 6: 核验 artifacts、Workspace 与 retention**

断言：

- paired families 恰好十一类；
- structured records 恰好七类；
- legacy flat pair 和 YAML template 均不存在；
- per-round Questioning、separate pointer、attempt/revision 分离存在；
- target operations 恰好三种；
- partial recovery、逐 target freeze、all-target dormancy、preserve-assigned、future-message-new-intake 存在。

- [ ] **步骤 7: 核验 Review、Verify、failure 和 assurance**

断言：

- Review Approval bindings 完整；
- Review Feedback 七个 owner；
- Verify order 为 Impl 后 independent Verification；
- Intake/lifecycle budget 隔离；
- 最大 counted failures 为三次；
- Failure Learning non-blocking/non-recursive；
- 八项 unavailable/forbidden assurance 仍声明；
- Plan 80/90 不成为 completion gate。

- [ ] **步骤 8: 审查 whitespace 与工作树**

使用编辑工具和 diff review 检查新增/修改 Markdown 的 trailing whitespace、破损链接和意外文件变更。不得使用 Shell 或 Python 脚本替代 Go CLI；当前 Go CLI 尚无该能力，因此自动 whitespace check 记录为 unavailable。

执行 `git status --short` 保存工作树观察；该 Git 命令只读取版本控制状态，不是项目脚本。

- [ ] **步骤 9: 将实际输出写入 evidence**

只记录实际人工观察得到的计数和通过/失败结论，并为每项结论链接 `migration-parity.md` 或具体分片。任何失败必须保留为 GAP，不得手工把预期结果写成已观察结果，也不得伪装为 Go CLI 输出。

- [ ] **步骤 10: 更新 evidence summary 为“静态核验完成，replay/acceptance 待定”**

不得提前写 `32/32 PASS`；下一任务完成前，criterion 31/32 保持 pending。

---

### 任务 11: 拆分并重放十六类场景，重新审计 32 条验收标准

**文件：**
- 重写： `docs/plan/35-core-prompt-flow/manual-replay.md`
- 新建： `docs/plan/35-core-prompt-flow/manual-replay/scenario-01-new-intake-confirmation.md`
- 新建： `docs/plan/35-core-prompt-flow/manual-replay/scenario-02-active-no-change-and-dormancy.md`
- 新建： `docs/plan/35-core-prompt-flow/manual-replay/scenario-03-multi-target-completion.md`
- 新建： `docs/plan/35-core-prompt-flow/manual-replay/scenario-04-partial-target-recovery.md`
- 新建： `docs/plan/35-core-prompt-flow/manual-replay/scenario-05-questioning-claim-change.md`
- 新建： `docs/plan/35-core-prompt-flow/manual-replay/scenario-06-review-acceptance-intake-first.md`
- 新建： `docs/plan/35-core-prompt-flow/manual-replay/scenario-07-review-feedback-owner.md`
- 新建： `docs/plan/35-core-prompt-flow/manual-replay/scenario-08-sticky-full-escalation.md`
- 新建： `docs/plan/35-core-prompt-flow/manual-replay/scenario-09-paired-artifact-pointer-failure.md`
- 新建： `docs/plan/35-core-prompt-flow/manual-replay/scenario-10-invalid-result.md`
- 新建： `docs/plan/35-core-prompt-flow/manual-replay/scenario-11-intake-failure-isolation.md`
- 新建： `docs/plan/35-core-prompt-flow/manual-replay/scenario-12-shared-delivery-failure-budget.md`
- 新建： `docs/plan/35-core-prompt-flow/manual-replay/scenario-13-failure-learning.md`
- 新建： `docs/plan/35-core-prompt-flow/manual-replay/scenario-14-completion-and-retention-gates.md`
- 新建： `docs/plan/35-core-prompt-flow/manual-replay/scenario-15-interruption-recovery.md`
- 新建： `docs/plan/35-core-prompt-flow/manual-replay/scenario-16-rejection-abandonment-new-intake.md`
- 重写： `docs/plan/35-core-prompt-flow/acceptance-audit.md`
- 重写： `docs/plan/35-core-prompt-flow/evidence-summary.md`

**接口：**
- 输入： 任务 10 人工一致性 evidence、只读 `migration-parity.md` 与九个分片、任务 3 自然语言 Policy、任务 4 Rule references、任务 5–8 templates/Workspace contracts。任务 11 不得改写迁移 evidence。
- 产出： 十六类 Markdown-policy replay、32 条验收映射，以及明确等待用户重新接受的最终门禁。

- [ ] **步骤 1: 将 replay index 缩为覆盖矩阵**

`manual-replay.md` 只保留：

- assurance boundary；
- scenario index；
- 每个 scenario 覆盖的 capability/scope/invariant；
- 总体结论；
- 指向十六个独立文件的链接。

入口不复制每个场景的完整 ledger，行数不超过 160。

- [ ] **步骤 2: 创建十六个场景文件**

每个文件统一包含：

```text
初始 durable facts
选择的 Capability / Profile / scope
proposed status
适用的自然语言控制规则及其标题
control action
materialized record/revision
current pointer/gate
invalidation
failure class
缺失 machine guarantees
replay result
```

按旧 16 个 scenario 一一迁移，不合并、不采样、不新增第 17 个隐式场景。

- [ ] **步骤 3: 重放 Intake 与 assignment 场景 1–6**

覆盖：

1. 新 Intake、确认、lifecycle creation；
2. active no-change resume 与 dormant exclusion；
3. multi-target assignment 和 all-target dormancy；
4. partial target recovery；
5. Questioning answer 改 claim；
6. Review/Acceptance message 先过 Intake。

每个场景引用具体阶段 reference、Capability 规则标题和适用条件，而不是 `transitions.yaml`、固定表格行或机器可解析的控制身份。

- [ ] **步骤 4: 重放 Review、sticky、artifact、invalid-result 场景 7–10**

验证七个 feedback owner、sticky full guard、record/content mismatch、pointer failure、duplicate/late/wrong-profile/wrong-scope fail closed。

- [ ] **步骤 5: 重放 failure、delivery、learning 场景 11–13**

验证 Intake budget 不消耗 lifecycle budget，Impl/Verification/Acceptance repair 共享三次预算，Failure Learning scope-bound/non-blocking/non-recursive。

- [ ] **步骤 6: 重放 completion、recovery、termination 场景 14–16**

验证 Verification/Acceptance/Summary gates、per-target freeze、whole-Intake dormancy、last proven gate、dormant recovery exclusion、rejection、host-observed abandonment、silence 和 post-dormancy new Intake。

- [ ] **步骤 7: 人工验证 replay 文件数量与统一结构**

逐项确认 `scenario-01` 到 `scenario-16` 恰好各有一个文件，且每个文件都记录初始事实、Capability/Profile/scope、status、自然语言控制规则、control action、materialization、pointer、invalidation、failure class、machine guarantee 边界和 replay result。

确认 index 只保留覆盖矩阵和链接，未复制完整 ledger；确认场景不引用 `transitions.yaml`、固定 Markdown 行或其他隐藏控制 DSL。Go CLI 自动检查当前 unavailable。

- [ ] **步骤 8: 重写 32 条 acceptance matrix**

逐行把旧 YAML evidence 替换为新 Markdown 路径：

- criteria 1–31 只有在 contract、static observation 或 replay evidence 实际存在时标记 PASS；
- criterion 13 改为“一个公共 `themis` 治理入口、一个 Global Rule entry、一个 Markdown policy package”，不限制无关独立 Skill；
- criteria 16–18 改为 `record.md + content.md` pair；
- criterion 31 绑定新的 static evidence 和十六个 scenario；
- criterion 32 保持 `PENDING USER RE-ACCEPTANCE`，不得由 Agent 自行通过。

- [ ] **步骤 9: 更新最终 evidence summary**

若 criteria 1–31 全部有新证据，写明：

```text
Markdown-first 表示重构已完成；31 项技术/合同标准通过；criterion 32 等待用户审阅并明确重新接受。
```

同时保留：历史 2026-07-31 re-acceptance 是事实，但不代替本次 amendment 的新接受。

- [ ] **步骤 10: 执行最终人工综合检查**

使用 27 项迁移矩阵、`migration-parity.md`、九个 evidence 分片、文件清单和 replay index，分别由实施者与 fresh reviewer 核对：

- `templates/.themis` 活动 YAML 为 0；
- Capability contracts 为 16，Profile contracts 为 4；
- 六个阶段 Policy references 均存在，98 个旧合法结果组合都有自然语言覆盖；
- replay 场景为 16；
- acceptance audit 保持 `PENDING USER RE-ACCEPTANCE`，不得出现当前 `32 PASS`；
- 所有自动 Go 检查均如实记录为 available 或 unavailable，不得写入未运行的 PASS。

- [ ] **步骤 11: 最终 diff hygiene 人工审查**

逐文件审查 whitespace、链接、标题层级和意外修改；自动 Go CLI hygiene 命令当前 unavailable。记录 reviewer 观察，不得使用 Python 或 Shell 脚本替代。

- [ ] **步骤 12: 审查完整变更范围并停止**

运行：

```bash
git status --short
```

与任务 1 baseline 对照，报告：

- 修改/新增/删除路径；
- YAML `27 → 0`；
- spec/Rule/Workspace/replay entry 行数；
- Capability/Profile/自然语言规则覆盖/artifact/scenario/criteria 数量；
- 任何剩余 GAP；
- criterion 32 仍等待用户决定。

不得 commit、push，也不得把用户沉默解释为重新接受。

---

## 最终自审清单

实施者在请求用户审阅前必须逐项核对：

- [ ] current Plan 35 authority 仍由原 dated spec 路径进入，并拆为十个功能 references。
- [ ] `templates/.themis/` 下活动 YAML 从 27 个降为 0 个。
- [ ] `SKILL.md` 只保留宿主要求的最小 `name`/`description` frontmatter。
- [ ] policy 仍是一个 policy package；规则按 Capability、selected path、Profile 和 status 提供自然语言定位，但不形成 route key 或机器可解析 identity。
- [ ] 六个阶段 Policy references 对旧 YAML 中观察到的 98 个合法结果组合提供逐项自然语言语义覆盖；98 仅是迁移核对值，不要求 Markdown 中存在 98 行或固定组合键。
- [ ] 十六个 Capability identity 和四个 Agent Profile 完整，只有 `themis-impl` 是 implementation writer。
- [ ] Capability 合同无 fenced YAML，所有原 output bindings 和 nested result fields 已迁移。
- [ ] 十一类 paired artifact 全部使用 `record.md + content.md`，缺失/mismatch 仍整体 invalid。
- [ ] 七类 structured/operational record 和两个 Context aid 均存在。
- [ ] Source Event、Current Request、Questioning、Plan、Review、Approval、Impl、Verification、Acceptance、Summary、Failure Learning 语义未删减。
- [ ] Intake-first、changed-only confirmation、三种 target operation、partial recovery、逐 target freeze、整体 dormancy、新 Intake 规则未删减。
- [ ] Review-before-Impl、Verify 顺序、Acceptance/Summary gates 未改变。
- [ ] Intake/lifecycle budget 隔离、三次 counted failure、shared delivery budget 未改变。
- [ ] spec entry、Rule、policy、Workspace、Context 和 replay index 满足行数上限，Agent 可按 references 按需读取。
- [ ] 所有新/重写 Markdown 正文使用中文，稳定字段和值未翻译或改名。
- [ ] active guidance 不再引用 `transitions.yaml`、`manifest.yaml`、`core.yaml`、machine record 或 YAML pair。
- [ ] 历史设计/计划只增加 supersession notice，历史执行事实未被重写。
- [ ] Plan 36/37/80 只更新 rebaseline notice，没有在本次实现。
- [ ] 没有新增功能版本、版本目录、compatibility、安装/版本 upgrade、runtime migration mechanism、Shell fallback、第二 policy 或持久 Specification；一次性表示重构未被包装为产品迁移能力。
- [ ] `migration-parity.md` 是唯一迁移证据索引，九个分片均有明确 owner、实施者观察、fresh reviewer 报告引用和 GAP 汇总；任务 9 前不存在未裁决 GAP。
- [ ] `static-verification.md` 记录的是实际输出，不是预期结果。
- [ ] 十六个 replay 场景全部独立存在，并引用适用的自然语言控制规则标题与适用条件。
- [ ] acceptance criteria 1–31 有新证据；criterion 32 保持等待用户重新接受。
- [ ] 已人工审查 trailing whitespace、链接、标题层级和意外修改；自动 Go CLI hygiene 检查如实记录为 unavailable。
- [ ] 未 commit、amend、push、reset、restore、clean 或 stash。

## 执行交接

计划完成后只能提供两种实施方式，且两者都必须先获得用户明确授权：

1. **子 Agent 驱动（推荐）**：使用 `superpowers:subagent-driven-development`，按任务 1–11 逐任务派发全新实施 Agent；每个实施 Agent 只读取自己的任务说明、目标入口和对应 references，任务后执行规格与质量审阅。
2. **当前会话执行**：使用 `superpowers:executing-plans`，在当前会话按任务 1–11 顺序执行，每个任务完成人工静态检查和差异审阅后再进入下一项。

无论选择哪种方式，都不得在 criterion 32 之前自行宣布 Plan 35 已重新接受，也不得未经用户另行授权提交或推送。
