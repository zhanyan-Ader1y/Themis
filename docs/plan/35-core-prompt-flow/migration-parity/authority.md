# 跨模块权威迁移核验

## 核验范围

本分片核验任务 2 将原 1293 行 replacement Plan 35 dated authority 拆为一个短入口与十个功能 references，同时保留原二十二章全部产品语义、稳定 identity、不变量和三十二条验收标准。它不切换 Policy、Global Rule、Capability、模板或 Workspace 消费者，也不删除旧 YAML 来源。

## 旧来源与新目标

- 旧来源：`docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement-design.md` 的原二十二章，包含 YAML Policy 和 machine-record/Markdown pair 的旧表示。
- 新入口：同一路径继续作为唯一 cross-module authority entry。
- 新 references：`docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement/*.md` 十个功能文件，共同构成入口的详细合同，不单独形成第二份设计权威。
- 允许的表示修订：`transitions.yaml` 改述为 `templates/.themis/core/policies/README.md` 与 references 组成的唯一自然语言 Policy package；paired semantic artifact 改述为同一 immutable revision 下的 `record.md + content.md`。
- 禁止的语义变化：不得改变字段、状态、门禁、authority owner、scope 隔离、failure budget、invalidation、recovery 或 acceptance criteria 的产品行为。

## 逐项迁移观察

### 原章节到 reference 的完整映射

| 原设计章节 | 新 reference 与标题 | 观察 |
|---|---|---|
| 1 背景；2 目标；3 设计边界；4 核心权威模型 | `authority-model.md`：背景、目标、设计边界、单 Policy/双 scope、Authority owner、Authority 成立条件、表示修订 | 已搬迁；只把旧 Policy/artifact 表示改为批准的 Markdown-first 表示 |
| 5 Request Intake；11.2 外部消息 interception；15.6 Lifecycle completion 与 Intake retention | `request-intake.md`：Intake identity、Source Event、Intake assignment、外部消息 interception、Lifecycle completion 与 retention | 已搬迁；该文件是 interception 和 completion retention 的唯一详细 owner |
| 6 Current Request claims；7 Current Request Dialogue Capability | `current-request-and-dialogue.md`：Claim model、Current Request revision、需要确认的变化、Capability identity、固定 Profile/scope、Invocation bundle、三种 legal status、两次确认协议 | 已搬迁 |
| 8 Capability 与 Agent Profile | `capabilities-and-profiles.md`：固定十六个 Capability、四个 fixed Profile、Temporary Invocation、Proposal 与 materialization | 已搬迁 |
| 9 Public Skill 与 Global Rule；10 Policy | `public-entry-and-control.md`：唯一公共 Skill、Global Rule、单一自然语言 Policy、控制规则定位、Current Request Dialogue 控制语义、自然语言规则完整性、执行边界 | 已搬迁；98 仅保留为旧 YAML 迁移覆盖观察值 |
| 11.1 前台流程；11.3 Questioning；11.4 Simple/full 与 sticky escalation | `lifecycle-flow.md`：前台流程、外部消息 interception 引用、Questioning、Simple/full 与 sticky escalation | 已搬迁；重复 interception 正文改为指向 Request Intake owner |
| 12 Immutable artifact model；13 Workspace scoping | `artifacts-and-workspace.md`：paired/structured/operational records、immutable revisions、Questioning round、attempt 分离、Workspace scoping | 已搬迁；paired shape 改为 `record.md + content.md` |
| 14 Review、Approval 与返工；15.1–15.5 Impl、Verification、Acceptance 与 Summary | `review-and-delivery.md`：Review Projection、Review Dialogue、Review Approval、Verify、Impl Result、Verification、Human Acceptance、Summary | 已搬迁；completion retention 只链接 Request Intake owner |
| 16 Currentness 与 invalidation；17 Failure control；18 Duplicate、stale 与 interruption | `currentness-failure-recovery.md`：currentness/invalidation、双 Execution Identity、failure classification、Failure Learning、checkpoints、uniqueness、recovery | 已搬迁 |
| 19 Verification strategy；20 Implementation impact；21 Completion and re-acceptance；22 Acceptance criteria | `verification-and-acceptance.md`：静态一致性、人工重放、实施影响、完成与重新接受、三十二条验收标准 | 已搬迁；criterion 32 明确绑定新的 Markdown-first 实际证据与用户重新接受 |

原二十二章均可由上述映射唯一定位，没有遗漏章节。

### 短入口观察

新的 dated entry 保留：

1. current authority 身份与适用范围；
2. Markdown-first amendment；
3. 十五项不可绕过产品摘要；
4. 十个 reference 的选择表；
5. 合同优先级；
6. 跨模块修改规则；
7. 当前核验与重新接受边界。

入口没有复制 98 个旧 route 结果组合、artifact 字段全集或三十二条验收矩阵。

### 文件体积观察

使用文件读取工具观察末行，实际行数如下；该观察不是 Go CLI 自动输出：

| 文件 | 实际行数 | 上限 | 结果 |
|---|---:|---:|---|
| `2026-07-31-plan-35-core-contract-replacement-design.md` | 107 | 180 | 范围内 |
| `authority-model.md` | 122 | 220 | 范围内 |
| `request-intake.md` | 115 | 220 | 范围内 |
| `current-request-and-dialogue.md` | 171 | 220 | 范围内 |
| `capabilities-and-profiles.md` | 88 | 220 | 范围内 |
| `public-entry-and-control.md` | 106 | 220 | 范围内 |
| `lifecycle-flow.md` | 73 | 220 | 范围内 |
| `artifacts-and-workspace.md` | 192 | 220 | 范围内 |
| `review-and-delivery.md` | 150 | 220 | 范围内 |
| `currentness-failure-recovery.md` | 156 | 220 | 范围内 |
| `verification-and-acceptance.md` | 143 | 220 | 范围内 |

### 关键语义 trace checklist

| 关键语义 | 唯一详细位置 | 定位观察 |
|---|---|---|
| 双 authority scope | `authority-model.md` → “单 Policy、双 authority scope” | 第 61–78 行定义 `request-intake`、`lifecycle` 与动态隔离 |
| 十六个 Capability | `capabilities-and-profiles.md` → “固定十六个 Capability” | 第 5–31 行列出全部 stable identity、Profile、scope 与职责 |
| 四个 Agent Profile | `capabilities-and-profiles.md` → 四个 Profile 标题 | 第 33–54 行定义 `semantic-readonly`、`independent-checker`、`human-dialogue`、`implementation-writer` |
| Current Request Dialogue | `current-request-and-dialogue.md` → “Capability identity”与“两次 Invocation 确认协议” | 第 58–77、156–171 行固定 identity、职责和两次确认 |
| `dormant-read-only` | `request-intake.md` → “Intake identity”“Intake assignment”“Lifecycle completion 与 retention” | 第 13、26、73、87–115 行固定派生 retention 与禁止行为 |
| 三种 target operation | `request-intake.md` → “Intake assignment” | 第 53–59 行固定 `create-lifecycle | update-current-request | no-change` |
| Review-before-Impl | `review-and-delivery.md` 文件导言与 Review/Approval 章节 | 第 3 行固定 Review 在 Impl 前，第 5–66 行定义投影、对话与 Approval |
| Impl 后 independent Verification | `review-and-delivery.md` → “Verify 定义” | 第 68–83 行固定 `themis-impl → independent themis-verification` 与共享 task budget |
| 三次失败预算 | `currentness-failure-recovery.md` → 两个 Execution Identity 章节 | 第 46–65 行固定 scope 隔离、Impl/Verification/Acceptance repair 共享 lifecycle task budget、第三次终止和禁止第四次 Invocation |
| 三十二条验收标准 | `verification-and-acceptance.md` → “验收标准” | 第 110–143 行完整保存 criteria 1–32 |

### 表示边界检查

- 十个 references 中没有 `TODO`、`TBD` 或占位章节。
- 对 `transitions.yaml`、YAML、machine execution 的提及只用于历史来源、禁止条件或 assurance boundary；没有把它们声明为新的 current representation。
- paired semantic artifact 的 current shape 统一为 `record.md + content.md`；structured record 使用 Markdown 字段合同。
- dated entry 的十个相对链接均有实际目标文件。
- 没有提前删除旧 Policy、模板或 YAML；全局消费者切换仍保留给任务 9。

## 实施者核对

- 原二十二章已全部映射到十个 references，并由同一路径 dated entry 继续提供唯一入口。
- 每个 reference 都声明所属 entry、拥有主题、非第二权威、stable identity 与核心不变量。
- 入口和全部 references 均低于批准计划的体积目标，不需要继续拆分。
- 双 scope、十六 Capability、四 Profile、Current Request Dialogue、`dormant-read-only`、三种 target operation、Review-before-Impl、independent Verification、三次失败预算和三十二条标准均有唯一详细位置。
- 只执行批准的表示 amendment，没有切换 Policy consumer、删除旧 YAML、启动 Plan 36/37 或实施 skill creator。
- `git diff --check` 成功；只观察到 Windows 工作副本的 LF→CRLF 提示，没有 whitespace error。
- 未 commit、amend、push、reset、restore、clean 或 stash。

## fresh reviewer 核对

2026-08-01 的独立只读 reviewer 首轮返回 `Verdict: CHANGES_REQUIRED`，同时确认：原二十二章 22/22 可定位、三十二条标准 32/32 保留、表示修订未越界、十个入口链接和首轮体积记录准确。reviewer 提出两个 Medium finding：

1. `artifacts-and-workspace.md` 重复叙述 completion retention gate，与 `request-intake.md` 形成双重 owner；已改为只声明 Workspace 存储职责并链接 Request Intake 唯一合同。
2. lifecycle Task Execution Identity 未明确 Acceptance 的 `implementation-defect` repair 共享同一 budget；已在 `currentness-failure-recovery.md` 补回同一 identity、返回 Impl 和重新 Verification 约束。

两项修复均已实施，`git diff --check` 再次成功。scoped re-review 返回 `Verdict: APPROVED` 且无 findings，并确认：

- Workspace 只保存已观察 completion/retention facts，完整 gate、逐 target 控制和禁止行为由 Request Intake 唯一拥有；
- Acceptance 的 `implementation-defect` repair 与 Impl/Verification 共用同一 Plan Task Execution Identity 和 budget，并在返回 Impl 后重新 Verification；
- evidence 已准确记录首轮 findings、修复和当前文件状态。

reviewer 始终只读，未修改文件、commit 或 push。

## 未裁决 GAP

无。任务 2 的实施者观察、首轮 findings 修复和 scoped re-review 均已完成。

## 自动 Go CLI 检查状态

`unavailable`。当前不存在已批准并已实现的 Themis Go CLI 文档体积、链接或语义 trace 核验命令；未使用 Python、Shell 临时脚本或虚构子命令替代。
