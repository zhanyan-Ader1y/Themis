# Plan 35：Core Contract Replacement Design

> 状态：replacement 设计、Prompt/template/policy/Workspace implementation、静态核验、十六类人工 replay 与验收审计均已完成；用户已于 2026-07-31 审阅证据并明确重新接受。本文现为 Plan 35 current product authority；2026-07-29 与 2026-07-30 的旧设计仅保留为历史记录。

## 1. 背景

原 Plan 35 建立了 Prompt-first 双路径生命周期、十五个内部 Capability、四个 Agent Profile、唯一公共 `themis` Skill、单一 `transitions.yaml`、Review-before-Impl、`Impl → independent Verification`、Human Acceptance、Summary 和三次失败预算。

后续设计 Plan 36 strict assurance 时发现，原模型没有完整定义以下产品合同：

- 外部用户消息在 lifecycle 归属前的来源权威；
- Current Request 如何从用户原文形成、确认、修正、分流和追溯；
- Capability result、持久记录、Markdown 与 machine record 何时获得 authority；
- artifact revision、execution attempt、current pointer 和 incomplete operation 的关系；
- 对话确认如何跨一次性 Invocation 持久续接；
- Intake 失败预算如何与 lifecycle task budget 隔离。

这些不是 Plan 36 validator 可以自行决定的技术细节，而是 Plan 35 必须先定义的产品语义。因此原 Plan 35 已立即失效，Plan 36/37 暂停，当前模板只作为可观察实现事实和 replacement 输入。

项目尚未投入使用。本次 replacement 直接替换旧合同，不提供兼容层、migration 或 upgrade。

## 2. 目标

本设计重建 Themis 核心产品合同，使以下事项具有唯一、可追溯且可被后续确定性实现验证的定义：

1. 每条外部用户消息先成为不可变 Request Intake Source Event；
2. 用户来源语义以可追溯 requirement claims 表达；
3. claim 变化和 lifecycle assignment 在进入 lifecycle 前获得用户明确确认；
4. 一个公共入口、一个 Global Rule 和一个 `transitions.yaml` 同时治理 Intake 与 Lifecycle，但二者不共享动态 authority；
5. 原十五个 Capability 保持职责边界，新增 `themis-current-request-dialogue`，总数固定为十六个；
6. 四个 Agent Profile 保持不变，任何 Profile 都不直接拥有 Workspace 治理记录的持久化权威；
7. paired semantic artifact 由 machine record 与 Markdown 共同构成不可分割的不可变逻辑 revision；
8. Capability Invocation Result 永远只是 proposed output，必须经过 policy control、完整持久化和重读后才能物化为 authority；
9. Intake 与 Lifecycle 分别拥有失败预算、continuation 和恢复边界；
10. Review、Approval、Impl、Verification、Acceptance 与 Summary 保持清晰且不可互相替代。

## 3. 设计边界

Plan 35 定义：

- stable contract identities；
- authority owner 与 authority scope；
- 输入、输出和必要 bindings；
- closed semantic statuses；
- representation requirements；
- lifecycle、currentness、invalidation、failure 和 materialization invariants；
- Prompt/template/policy 层应表达的合同；
- 静态检查与人工 replay 的验收范围。

Plan 35 不选择或实现：

- Go module、runtime 或 CLI；
- JSON Schema dialect；
- canonical serialization 或 digest 算法；
- validator、semantic oracle 或 fixture runner；
- 文件系统原子替换的具体平台机制；
- locks、transactions、rollback 或 automatic recovery；
- multi-Agent execution；
- Attribution analytics；
- installer、upgrade、migration 或兼容层。

strict Schema、canonicalization、validator 和 accepted/rejected fixtures 留给重新基线后的 Plan 36；native runtime、recorder、write safety 和 command execution 留给 Plan 37。

## 4. 核心权威模型

采用“单政策、双 authority scope”架构：

```text
用户消息
→ immutable Request Intake Source Event
→ themis-current-request-dialogue
→ transitions.yaml 选择合法 control action
→ recorder 完整持久化并重读
→ confirmed assignment 创建或更新 lifecycle
→ lifecycle Capability flow
```

### 4.1 Authority scopes

固定两种动态 authority scope：

- `request-intake`：管理 Source Event、claim/assignment proposal、用户确认、assignment decision、Intake execution 与 scope-local continuation；
- `lifecycle`：管理 Current Request、Questioning、Assessment、Plan、Review、Approval、Impl、Verification、Acceptance、Summary、Task Execution 与 lifecycle continuation。

二者可以通过 stable references 关联，但不得共享：

- dynamic state；
- Execution Identity；
- attempt budget；
- continuation authority；
- current pointer；
- completion status。

### 4.2 Authority owners

- **Source Event**：用户原始输入的永久来源权威；
- **Current Request claims**：经用户确认后，对目标语义的 lifecycle 权威；
- **Capability**：拥有本领域语义判断，只返回 proposed result；
- **Agent Profile**：拥有工具、读取、实现写入和隔离边界；
- **`transitions.yaml`**：唯一 route、control action、failure class 和 invalidation policy；
- **Global Rule**：解释政策并协调 invocation、result validation、control action 和 observed result；
- **Recorder observed result**：证明记录或 artifact 已完整持久化并被重读；
- **Lifecycle state**：仅保存 current refs、gate 和控制事实，不复制业务或设计语义。

### 4.3 Authority 成立条件

Capability Invocation Result 永远不是持久 authority。只有经过以下完整链路，记录或 artifact 才能成为 current candidate：

```text
validate proposed result and bindings
→ match exactly one policy route
→ execute the declared control action
→ persist every required component
→ record completion or incomplete observation
→ reread record and content
→ verify identity, digest and bindings
→ create immutable revision observation
→ update current pointer
```

缺少任一步骤时：

- 不推进 gate；
- 不声称 persistence；
- 不从 prose、文件存在或 Agent summary 推断成功；
- 保持或返回 last proven gate。

## 5. Request Intake

### 5.1 Intake identity

每条外部用户消息必须先记录为一个不可变 Source Event，并绑定一个 Intake identity。Intake 在 lifecycle assignment 之前提供独立 authority scope，不使用 provisional lifecycle。

Intake identity 的选择只能来自 durable control facts：

- 若 active Intake-local continuation 明确等待某个 `open` Intake 下特定 proposal 的用户确认，新消息作为 confirmation Source Event 加入该 Intake；
- 若 active Intake-local continuation 明确等待用户对 terminated Intake Execution 的 restart/unblock 决定，新消息作为 restart decision Source Event 加入该 Intake，但只有明确授权才能创建显式关联的 replacement Execution Identity；
- `dormant-read-only` Intake 的全部 continuation 都是 inactive，不能接受 Source Event、恢复、重激活或调度 Invocation；
- 其他所有外部消息都创建新的 Intake identity，即使消息将继续既有 lifecycle 的 Questioning、Review 或 Acceptance 对话，或涉及曾与 dormant Intake 关联的 lifecycle；
- 仅因存在一个 open/assigned Intake、消息文本像确认/重试，或聊天顺序相邻，都不得把消息附加到已有 Intake；
- public Skill 和 Global Rule 只读取 active continuation binding，不对消息语义进行 Intake 归属判断。

Intake disposition 只有：

- `open`；
- `assigned`；
- `rejected`；
- `abandoned`。

`rejected` 只表示用户明确决定该请求不进入受治理变更。`abandoned` 只由宿主观察到的明确会话终止或离开事件记录；Capability 和控制面不得从沉默推断 `rejected` 或 `abandoned`。

`dormant-read-only` 不是第五种 disposition，而是 `assigned` Intake 在其关联 lifecycle 完结后的派生保留模式。它不得改写原 disposition、Source Event、proposal、decision、target observation 或历史绑定。

执行失败不是第五种 disposition。第三次 counted failure 后，Intake 保持 `open`，但当前 Intake Execution Identity 为 terminated，禁止第四次 Invocation。

### 5.2 Source Event

Source Event 至少拥有：

- stable event identity；
- Intake identity；
- actor/source identity；
- observed time；
- original UTF-8 bytes；
- content digest；
- transport metadata；
- recorded result。

原始 bytes 不执行 Unicode 或换行 normalization。规范化文本只能作为可重建 projection，不能替换 Source Event authority。

对用户语义的精确引用必须绑定：

```text
event identity
+ UTF-8 byte range
+ quoted fragment digest
```

引用范围和 digest 与原始 bytes 不一致时必须拒绝。

### 5.3 Intake assignment

一个 Intake 可以显式分流到一个或多个 lifecycle，也可以更新既有 lifecycle。每个目标操作必须具有稳定 identity，并明确为：

- `create-lifecycle`；
- `update-current-request`；
- `no-change`。

同一 Source Event 片段可以被显式引用到多个目标，但每次共享都必须出现在用户确认的 assignment decision 中；禁止隐式多重归属。

多目标 assignment 使用逐目标可恢复持久化：

1. assignment decision 不可变；
2. 每个目标操作单独执行、观察和记录；
3. 全部 assignment target 物化成功后 Intake 才成为 `assigned`；
4. 部分成功时保持 `open + incomplete`；
5. 不自动 rollback 已成功目标；
6. 恢复时重读实际目标状态，只继续未完成操作；
7. lifecycle-bearing target 完结后单独记录 completion observation，并冻结该 target 的历史绑定为只读；
8. 只要任一关联 lifecycle target 尚未 observed completed，Intake retention mode 仍为 `active`，且已完成 target 不得影响未完成 target；
9. 所有关联 lifecycle target 都 observed completed 后，Intake 才整体进入 `dormant-read-only`。

同一 lifecycle 可以被多个历史 Intake 的显式 assignment target 引用。lifecycle completion observation 必须按 lifecycle identity 找到并冻结所有匹配 target，再分别判断每个 Intake 的整体休眠 gate；不得只更新创建该 lifecycle 的最初 Intake。没有 lifecycle identity 的 target 不得被虚构为一个待完成 lifecycle。

## 6. Current Request claims

### 6.1 Claim model

Current Request 不再是对用户原文的无来源摘要，而是可追溯 requirement claims 的不可变集合。

每条 claim：

- 具有 stable claim identity；
- 每次内容或结构变化产生不可变 claim revision；
- 引用一个或多个 Source Event 精确片段；
- disposition 为 `active | ambiguous | superseded`；
- 可以显式绑定 `supersedes`、`split-from` 或 `merged-from` 关系；
- 不得把 Agent 分析、Plan、Specification、历史需求或其他推理伪装成用户语义。

### 6.2 Current Request revision

一个 Current Request revision 是某个 lifecycle 下已确认 claim revisions 的不可变集合，并至少绑定：

- lifecycle identity；
- confirmed Intake assignment decision；
- active、ambiguous 和 superseded claim refs；
- Source Event refs；
- previous Current Request revision；
- materialization observation。

current pointer 与 revision 分离。内容或 claim set 改变时创建新 revision；不得原地覆盖旧 revision。

### 6.3 需要用户确认的变化

以下变化必须通过 `themis-current-request-dialogue` 向用户展示语义 diff 并获得明确 disposition：

- 新增 claim；
- 改写 claim；
- 废止 claim；
- 标记或解除 ambiguity；
- lifecycle assignment 或 Source Event 片段归属变化。

以下情况不要求额外确认：

- 新消息与现有 confirmed claim 完全匹配；
- 用户回答只补足当前对话，不改变 claim 或 assignment；
- 仅记录新的 Source Event 和原 continuation 的输入。

用户看到的 diff 只呈现变化项，每项包含：

- stable diff item identity；
- 短原文引用；
- `add | rewrite | supersede | ambiguity | assignment-change`；
- 旧语义与建议新语义；
- 受影响 lifecycle；
- 允许的 `confirm | correct | keep-ambiguous` disposition。

整体确认必须绑定当前完整 diff digest。未提及或缺少 disposition 的必需项不能被推断为已确认。

## 7. Current Request Dialogue Capability

新增第十六个 Capability：

```text
themis-current-request-dialogue
```

### 7.1 职责

该 Capability：

- 处理每条外部用户消息的 Intake；
- 比较 Source Event 与已确认 claims；
- 提议 claim diff；
- 提议 lifecycle assignment、split 或 no-change；
- 生成低负担用户语义 diff；
- 处理新的用户确认 Source Event；
- 返回结构化 assignment decision proposal；
- 保留原 dialogue continuation。

它不：

- 直接创建 lifecycle；
- 直接写 Current Request revision；
- 修改 Intake 或 lifecycle state；
- 执行 route；
- 修改项目实现；
- 从模糊确认、沉默或聊天历史推断用户决定。

### 7.2 固定 Profile 与 scope

```text
agent_profile: human-dialogue
authority_scope: request-intake
selected_path: null
profile: null
```

`human-dialogue` 保持只读。Capability 可以返回 proposal 或 confirmed decision result，但只有 policy control action 和 observed recorder result 可以物化治理记录。

### 7.3 Invocation input bundle

至少绑定：

- authority scope；
- Intake identity；
- Intake Execution Identity；
- Invocation identity 与 attempt；
- 新 Source Event；
- pending proposal、proposal digest 与 prior confirmation refs；
- 相关 lifecycle 的 current Current Request refs；
- current claim revisions；
- original dialogue continuation；
- policy identity/digest；
- remaining failure budget；
- allowed reads 和禁止写入声明。

### 7.4 Legal statuses

#### `needs-request-confirmation`

必需输出：

- immutable proposal identity；
- proposal digest；
- stable diff item identities；
- 每项 Source Event fragment refs；
- proposed claim revisions；
- proposed target lifecycle operations；
- 每项允许 disposition；
- 用户可见精简 diff；
- confirmation continuation。

控制操作只持久化 proposal 并等待新的用户 Source Event，不创建或更新 lifecycle。

#### `assignment-confirmed`

当 diff 非空时，必需绑定：

- pending proposal identity/digest；
- 新的用户确认 Source Event；
- 每个必需 diff item 的明确 disposition；
- 完整 diff digest；
- immutable assignment decision proposal；
- 逐目标 operations；
- original dialogue continuation。

当 diff 为空时，必需绑定：

- 新 Source Event；
- current confirmed assignment 和 Current Request refs；
- claims/assignment unchanged 的结构化结论；
- `no-change` operation；
- original dialogue continuation。

无变化时不要求用户重复确认。

#### `rejected`

必需绑定：

- 用户明确拒绝的 Source Event；
- immutable rejection decision proposal；
- 空 lifecycle operations；
- Intake identity。

控制操作持久化 rejection 后将 Intake 标记为 `rejected`。

### 7.5 两次 Invocation 确认协议

存在语义变化时必须使用：

```text
Source Event
→ first Current Request Dialogue Invocation
→ needs-request-confirmation
→ persist proposal
→ user confirmation becomes a new Source Event
→ second Current Request Dialogue Invocation
→ assignment-confirmed
→ policy-controlled materialization
```

一个 Invocation 不得跨多轮保留临时 context authority，Global Rule 也不得直接把自然语言“确认”映射为 confirmed。

## 8. Capability 与 Agent Profile

### 8.1 固定十六个 Capability

| Capability | Agent Profile | Authority scope | 核心职责 |
|---|---|---|---|
| `themis-current-request-dialogue` | `human-dialogue` | Request Intake | Source Event、claim diff、assignment 和用户确认 |
| `themis-q` | `human-dialogue` | Lifecycle | Why、impact、expected result 与 abstract What 追问 |
| `themis-grounding` | `semantic-readonly` | Lifecycle | 读取代码、配置、Schema 与 observed behavior 的当前事实 |
| `themis-complexity-assessment` | `semantic-readonly` | Lifecycle | 证明 simple 条件或要求 full path |
| `themis-simple-plan` | `semantic-readonly` | Lifecycle | 在已证明简单边界内生成统一 Plan |
| `themis-spec` | `semantic-readonly` | Lifecycle | full path 的临时需求细化 handoff |
| `themis-planning` | `semantic-readonly` | Lifecycle | full path 技术设计、取舍、任务与验证方案 |
| `themis-plan-check` | `independent-checker` | Lifecycle | 隔离检查 lightweight/full Plan |
| `themis-review-projection` | `semantic-readonly` | Lifecycle | 从 checked Plan 生成低负担 Review Projection |
| `themis-review-check` | `independent-checker` | Lifecycle | 检查 projection 忠实度和呈现负担 |
| `themis-review-dialogue` | `human-dialogue` | Lifecycle | 展示、解释、分类反馈和批准 proposal |
| `themis-impl` | `implementation-writer` | Lifecycle | 按 current Approval 绑定的 Plan 修改实现 |
| `themis-verification` | `independent-checker` | Lifecycle | 独立验证 current implementation 与交付证据 |
| `themis-acceptance-dialogue` | `human-dialogue` | Lifecycle | 展示验收视图并形成 acceptance proposal |
| `themis-failure-learning` | `semantic-readonly` | Request Intake 或 Lifecycle | 生成 scope-bound 非阻塞经验候选 |
| `themis-summary` | `semantic-readonly` | Lifecycle | 在 passed + accepted 后生成交付投影 |

除以下扩展外，原十五个 Capability 的职责和 legal status 边界保持不重组：

- `themis-q` 输入改为 user-confirmed Current Request claims/revision；
- `themis-failure-learning` 支持两种 authority scope；
- 所有 Capability 明确 materialization target 和不可变 revision requirement；
- 所有用户消息统一经过 Intake interception 后再恢复 lifecycle continuation。

### 8.2 四个固定 Agent Profile

#### `semantic-readonly`

允许语义分析、候选生成和只读事实引用，不得修改项目实现或 Workspace authority。

#### `independent-checker`

在隔离上下文中检查输入和直接证据，不继承 producer 的临时推理，不得修改被检查对象。

#### `human-dialogue`

允许与用户交互、生成语义 diff、feedback、approval 或 acceptance proposal。不得直接写 Intake/lifecycle state、artifact、route 或项目实现。

#### `implementation-writer`

是唯一可以修改 current Approval 所允许项目实现范围的 Profile。它仍不得：

- 修改 Core policy 或 Workspace governance state；
- 自行扩张 scope；
- 给出 Verification verdict；
- 将写入成功等同于 artifact/state 持久化成功。

不新增 governance-writer Profile。

### 8.3 Temporary Invocation

每次 Invocation 只能绑定：

```text
one authority scope
+ one Execution Identity
+ one Invocation/attempt identity
+ one Capability
+ its fixed Agent Profile
+ selected path/profile
+ current policy binding
+ current source/artifact bindings
+ exact continuation
+ allowed reads/writes/commands
```

Intake Capability 固定使用 `selected_path: null` 和 `profile: null`。

任何 Capability 或 Agent 都不得：

- 调用其他 Capability 或 Agent；
- 选择或扩张自身 Profile；
- 保留跨 Invocation shared memory 或 authority；
- 直接执行 route；
- 把 chat、summary 或 temporary reasoning 作为 state；
- 返回多个相互竞争的终态结果。

## 9. Public Skill 与 Global Rule

### 9.1 唯一公共 Skill

fresh template 恰好注册一个公共入口：

```text
.claude/skills/themis/SKILL.md
```

它只负责：

- 接收外部消息并确保 Source Event 被记录；
- 加载 Global Rule、current policy、一个 Capability 及固定 Profile；
- 运输用户回答和 Capability result；
- 请求从 durable facts 恢复中断流程。

它不拥有：

- claims 或 lifecycle assignment；
- Capability 语义；
- route lookup；
- persistence/currentness；
- Approval、failure count 或 invalidation；
- Verification、Acceptance 或 Summary 判断。

### 9.2 Global Rule

Global Rule 是唯一常驻控制说明，只执行通用控制：

1. 读取 current scope、identity、policy、current refs 和 continuation；
2. 验证进入 Invocation 的前置 bindings；
3. 选择 policy 指定的一个 Capability 和 fixed Profile；
4. 创建一次性 Invocation；
5. 验证 proposed result 的 identity、scope、Profile、status 和 bindings；
6. 精确匹配一条 policy route；
7. 请求 route 声明的 control action；
8. 根据 observed recorder result 更新 current refs 或 gate；
9. 任一缺失、歧义、stale 或 unsupported 情况 fail closed。

Global Rule 不：

- 内嵌十六个 Capability 的推理方法；
- 维护第二份 legal status 或 route 表；
- 解析 `recommended_route` 覆盖 policy；
- 从自然语言猜测用户确认、lifecycle state 或恢复点；
- 声称未观察到的 persistence。

## 10. Policy

### 10.1 单一 policy

继续只有一个 `transitions.yaml`。它同时声明：

- `request-intake` 与 `lifecycle` authority scopes；
- 十六个 Capability stable identities；
- 十六个 Capability 的 fixed Profile；
- 每个 Capability 的 legal scope 和 required identity bindings；
- closed vocabularies；
- routes；
- control actions；
- invalidation；
- failure classes；
- guards；
- dynamic continuation invariants。

不得建立第二份 Intake policy 或由 Global Rule 硬编码 Intake 状态。

### 10.2 Route key

route key 保持：

```text
capability + selected_path + profile + status
```

不增加 scope 作为第五维度。每个 Capability 的 legal scope 由 capability contract 和 policy 唯一约束。

`themis-failure-learning` 可以运行于两种 scope，但只使用其统一 semantic route；control action 必须读取 Invocation 中已验证的 `authority_scope` 和 scope-local continuation，不得跨 scope 修改动态状态。

### 10.3 Current Request Dialogue routes

```text
needs-request-confirmation
→ persist-intake-proposal-and-await-confirmation
→ human-request-confirmation

assignment-confirmed
→ materialize-confirmed-assignment
→ decision-bound-continuations

rejected
→ persist-intake-rejection
→ intake-closed
```

`decision-bound-continuations` 只能来自 confirmed decision 中逐目标绑定的 continuation，不能由 Agent prose 或 Global Rule 自行决定。

## 11. Lifecycle flow

### 11.1 前台流程

```text
public themis Skill
→ record Source Event under Intake
→ themis-current-request-dialogue
   ├─ needs-request-confirmation
   │  → user confirmation Source Event
   │  → second dialogue Invocation
   ├─ rejected
   │  → persist rejection and close Intake
   └─ assignment-confirmed
      → materialize assignment
      → create/update lifecycle Current Request revision
      → themis-q
      → optional Grounding
      → Complexity Assessment
         ├─ simple → Simple Plan → Lightweight Plan Check
         └─ full   → temporary Specification → Planning → Full Plan Check
      → Review Projection
      → Review Check
      → Review Dialogue
      → Review Approval
      → Impl
      → independent Verification
      → Acceptance Dialogue
      → Summary
      → completed
```

多目标 assignment 的各 lifecycle 独立按上述流程推进，不构成 Plan 80 multi-Agent execution。

### 11.2 外部消息 interception

无论 lifecycle 当前处于 Questioning、Review、Acceptance 或其他等待用户输入的 gate，每条外部消息都先成为新的 Source Event，并调用 `themis-current-request-dialogue`。

- **无 claim/assignment 变化**：返回 `assignment-confirmed + no-change`，物化 Intake decision 后，把原消息 Source Event 交给 durable continuation 指定的 lifecycle Capability；
- **有变化**：持久化 proposal，等待确认 Source Event；确认和 Current Request materialization 完成后再回原 continuation；
- confirmation Source Event 只确认 governance diff，不自动替代触发原 lifecycle 对话的 Source Event。

控制面只能依据 durable continuation identity 恢复，不能依据聊天上下文猜测消息属于哪个阶段。

### 11.3 Questioning

`themis-q` 继续只拥有：

- Why；
- impact；
- expected result；
- trigger；
- necessary abstract action；
- result；
- weak-point questioning。

它不拥有：

- claim authority；
- lifecycle assignment；
- persistence；
- scope contract；
- implementation design。

Questioning 回答先经过 Intake。若回答改变 claims，只展示和确认 changed diff；若不改变 claims，则恢复当前 questioning continuation。

### 11.4 Simple/full 与 sticky escalation

simple path 只有在 Complexity Assessment 逐项证明简单条件后才合法。unknown、无法证明或后续发现隐藏复杂度必须进入 full path。

`full_path_required` 在一个 lifecycle 内保持 sticky：

- simple path 任一阶段触发 `escalate-full` 或发现 full-only 需求后设为 true；
- Current Request 新 revision、retry、Agent restart、session resume 或新 Intake 均不能清除；
- 只影响当前 lifecycle；独立新 lifecycle 拥有自己的 sticky state。

两条路径只在 Plan 形成前不同，之后共享 Review、Approval、Impl、Verification、Acceptance 和 Summary。

## 12. Immutable artifact model

### 12.1 Paired semantic artifacts

以下对象由 machine record 与 Markdown 共同组成不可分割的逻辑 revision：

- Current Request；
- completed Questioning round；
- Plan；
- Review Projection；
- Review Approval；
- Review feedback；
- Impl Result；
- Verification；
- Human Acceptance；
- Summary；
- governed knowledge candidate。

machine record 负责：

- identity；
- revision；
- typed fields；
- source/current bindings；
- content path；
- content digest；
- disposition/currentness；
- materialization observation。

Markdown 负责保存经治理的人类语义和人类可读内容。

任一组件缺失、content digest mismatch 或 binding mismatch 时，整个逻辑 revision invalid。machine record 不能把 Markdown 降格为无权威 projection，Markdown 也不能脱离 machine record 单独成为执行 authority。

Review Projection 与 Summary 虽然是 paired artifacts，但其语义权限仍受来源限制：

- Review Projection 是 checked Plan 的绑定投影，不拥有 Plan 或 execution semantics；
- Summary 是 Verification、Acceptance 与 actual delta 的绑定交付投影，不创建 completion 事实，不替换 Verification 或 Acceptance。

### 12.2 Structured semantic records

以下对象默认只要求 machine-readable record，不机械生成 Markdown：

- Grounding；
- Complexity Assessment；
- Plan Check；
- Review Check；
- route-affecting checker results；
- confirmed Intake assignment decision。

### 12.3 Operational and evidence records

以下对象不是 semantic artifact revision：

- lifecycle/Intake state；
- Task/Intake Execution Identity；
- Invocation；
- attempt；
- raw Capability result evidence；
- control action/recorder result；
- current pointer；
- completion/incomplete marker；
- command/stdout/stderr evidence；
- Git baseline/status/diff observation；
- last proven gate。

### 12.4 Immutable revisions

所有逻辑 artifacts 使用不可变 revision：

```text
<artifact-family>/<opaque-revision-id>/
  <artifact>.yaml
  <artifact>.md        # paired artifact only
```

规则：

- 内容或结构变化创建新 revision；
- current pointer 单独保存；
- 不原地覆盖；
- 不使用 symlink 作为 authority；
- 旧 revision 保留 observed disposition，例如 `stale | superseded | failed | rejected | invalidated`；
- 不从 revision 编号、时间或缺号推断 attempt 或 failure count；
- pointer 更新失败时 revision 可以存在，但不成为 current。

### 12.5 Questioning round

不再维护一个不断追加的大 `questioning.md`。一次已完成问答交换形成一个独立 immutable round revision：

```text
questioning/<round-revision>/
  round.yaml
  round.md
```

每轮至少绑定：

- previous round revision；
- question proposal/continuation；
- answer Source Event refs；
- post-answer Current Request revision；
- Why/abstract What result；
- materialization observation。

尚待回答的问题只存在于 durable dialogue continuation/proposal，不伪装成 completed round。

### 12.6 Attempt 与 artifact 分离

- attempt 属于 Execution Identity；
- attempt 开始和失败必须记录；
- artifact revision 只在完整持久化和重读后产生；
- 一个 attempt 可以没有 artifact；
- 一个 attempt 可以引用合同允许的多个 artifacts；
- incomplete marker 属于 operation record，不属于 artifact revision。

## 13. Workspace scoping

fresh Workspace 使用：

```text
workspace/
  intakes/<intake-id>/
    source-events/
    proposals/
    decisions/
    state/

  changes/<lifecycle-id>/
    current-request/
    questioning/
    plan/
    review/
    approval/
    feedback/

  state/<lifecycle-id>/
    lifecycle-state
    current-pointers/
    invalidations/
    markers/

  runs/<lifecycle-id>/
    task-executions/
    invocations/
    attempts/
    impl-results/
    verification-results/

  evidence/<lifecycle-id>/
    commands/
    git-observations/
    external-evidence/

  outcomes/<lifecycle-id>/
    acceptance/
    summary/

  knowledge/
    intakes/<intake-id>/
    lifecycles/<lifecycle-id>/
```

路径只表达归属，不因目录或文件存在而证明 authority。所有 currentness 仍依赖 identity、bindings、完整物化和 observed reread。

`workspace/intakes/<intake-id>/state/` 保存 Intake 控制事实和 post-completion retention facts。休眠记录必须引用 immutable assignment decision、对应 target identity 和 observed lifecycle completion records；它不能写回或替换 assignment decision。

当 Summary pair 完整物化且 lifecycle completion 被观察后，对应 lifecycle target 的历史绑定冻结为只读。只有所有关联 lifecycle-bearing target 都 observed completed，assigned Intake 才进入派生的 `dormant-read-only` mode，并将全部 Intake-local continuation 标记为 inactive/non-attachable。Source Event、proposal、confirmation/assignment decision、target observation、completion observation 和历史绑定继续只读保留；只允许清理可重建 cache，不允许删除来源 authority、调度新 Invocation、恢复、重激活或修改 dormant Intake。后续外部消息创建新 Intake。

Intake 与 lifecycle 可以引用同一个 Source Event，但不能共享动态 state、Execution Identity、attempt budget 或 continuation authority。

Lifecycle state 是最小引用状态，只保存：

- current gate；
- current artifact revision refs；
- policy identity/digest；
- sticky flag；
- Task Execution identities；
- attempt refs；
- currentness；
- markers；
- invalidation；
- incomplete operation；
- last proven gate。

Lifecycle state 不复制 Current Request claims、scope、Plan、design、acceptance semantics 或 artifact prose。

## 14. Review、Approval 与返工

### 14.1 Review Projection

Review Projection 是 checked Plan 的独立、不可变、可验证绑定投影。

machine record 至少绑定：

- source checked Plan revision；
- projection profile；
- coverage map；
- content path/digest；
- materialization observation。

Markdown 按由抽象到具体、高影响优先、异常优先和按需展开原则降低理解成本，可包含必要的时序图或流程图。它不拥有目标或执行语义。

### 14.2 Review Dialogue

Review Dialogue：

- 展示和解释 Review Projection；
- 按需定位 checked Plan；
- 保存用户反馈原意；
- 将反馈分类到正确 owner；
- 返回 feedback 或 approval proposal。

它不直接 patch Plan 或 Review Projection。用户不手工修改 Plan Markdown 作为治理操作。

合法 feedback owners 包括：

- Current Request Dialogue；
- `themis-q`；
- Specification；
- Simple Planning；
- Planning；
- Plan Check；
- Review Projection。

反馈首先形成独立 immutable feedback revision，再由 owner 产生新的 semantic artifact 或 checker result。Plan 或 projection 新 revision 会使旧 Approval stale。

### 14.3 Review Approval

Review Approval 是不可变 paired artifact，至少绑定：

- lifecycle identity；
- confirmed Intake assignment decision；
- current Current Request revision 与 active claim revisions；
- current Questioning round；
- governed design constraints；
- relevant Grounding/Complexity Assessment refs；
- selected path/profile；
- sticky `full_path_required`；
- checked Plan revision；
- Plan Check result；
- 用户实际看到的 Review Projection revision；
- Review Check result；
- unresolved feedback 为空；
- approver decision Source Event；
- approval time；
- pre-Impl implementation baseline。

Approval 批准的是 checked Plan，不是 Review Projection；绑定 projection 只证明用户批准时实际看到的内容。

Review Dialogue 的 `approved` result 仍只是 proposal。Approval 必须完整物化并重读后才能进入 Impl。

## 15. Impl、Verification、Acceptance 与 Summary

### 15.1 Verify 定义

Verify 固定为：

```text
themis-impl
→ independent themis-verification
```

Impl 与 Verification：

- 使用不同 Invocation；
- 共享同一 Plan Task Execution Identity 和 failure budget；
- 绑定同一 current Approval、Plan task、baseline 和 expected delta；
- Implementation writer 不验证自身；
- Review Markdown 不是 execution input。

### 15.2 Impl Result

每次完整实现结果形成独立 immutable paired revision，至少绑定：

- Approval、Plan task 和 Task Execution Identity；
- Invocation/attempt；
- pre-Impl baseline；
- expected delta；
- actual changed paths/delta；
- commands/evidence refs；
- deviations；
- observed post-state。

写入或 attempt 失败可以没有 Impl Result revision。旧结果保留其 failed、stale、superseded 或 invalidated disposition。

### 15.3 Verification

每次完整 Verification 形成独立 immutable paired revision，至少绑定：

- current Approval 和 Plan revision；
- current Impl Result；
- exact implementation revision/delta；
- independent Invocation/attempt；
- exact commands/observations；
- stdout/stderr/evidence refs；
- coverage；
- verdict；
- residual risk。

只有 current `passed` 可以进入 Acceptance。Verification 不接受 stale、missing 或 producer-only evidence。

### 15.4 Human Acceptance

Acceptance Dialogue 形成 acceptance proposal；Human Acceptance paired artifact 只有在 control action 完整物化后获得 authority。

Acceptance 至少绑定：

- current Verification；
- current Approval/Plan/Current Request；
- delivered actual delta；
- user decision Source Event；
- observed result/feedback；
- decision。

非 `accepted` 不能进入 Summary。implementation defect 返回 current Approval 范围内的 Impl 并重新 Verification；需求、Plan 或 complexity 问题按 owner 失效上游。

### 15.5 Summary

Summary 是不可变交付投影，必须绑定：

- current Verification `passed`；
- current Human Acceptance `accepted`；
- actual delta；
- current artifact revisions；
- source evidence refs。

Summary 不能：

- 创建新事实；
- 改变 completion；
- 替换 Verification 或 Acceptance；
- 自动发布知识。

Summary 或知识候选生成失败不改变已经 observed 的 passed/accepted，但在 Summary 未完整物化前 lifecycle 不标记 completed。

### 15.6 Lifecycle completion 与 Intake retention

Summary pair 完整物化和重读之后，policy 才能记录 lifecycle completion observation。Summary 内容本身不创建 completion 事实。

完成后置控制固定为：

```text
Summary fully materialized and reread
→ lifecycle completion observed
→ resolve every immutable assignment decision + target identity bound to the lifecycle
→ record completion observation and freeze each matching target read-only
→ for each affected Intake, if every associated lifecycle target is observed completed:
     preserve Intake disposition assigned
     set retention mode dormant-read-only
     deactivate all Intake-local continuations
```

该控制不是新的 Capability、Capability status、route key dimension 或第五种 Intake disposition。它只通过 stable immutable references 连接 lifecycle completion 与 Intake retention，不能共享两个 scope 的动态状态。

当其他关联 lifecycle target 尚未完成时，Intake 保持 `active`，且该 target 的 continuation、failure budget 与执行不受已完成 target 影响。进入 `dormant-read-only` 后，Intake 不可附加新 Source Event、不可调度 Invocation、不可恢复、不可重激活、不可修改；历史记录只用于来源和决定核验。未来外部消息必须创建新 Intake。

若 recorder/runtime 不能观察并记录 completion 或 retention transition，控制面停在最后已证明 gate，报告 assurance unavailable，不能手写 machine-owned state 冒充休眠完成。

## 16. Currentness 与 invalidation

### 16.1 Source Event 与 claim changes

Source Event 的存在本身不使 lifecycle 失效。只有 confirmed decision 改变 claims 或 assignment 才触发 invalidation。

- claim revision 或 active set 改变
  → 新 Current Request revision
  → 失效受影响的 Questioning、Assessment、Plan 和下游；
- 不改变 claims 的回答
  → 保留 Current Request revision，形成新 Questioning round或恢复原 dialogue；
- lifecycle assignment 改变
  → 只影响 decision 明确列出的 lifecycle，禁止隐式搬运动态 state。

### 16.2 Facts、constraints 与 Plan

- Grounding fact、governed design constraint 或 pre-approval baseline 变化
  → 失效依赖其内容的 Assessment、Plan 和下游；
- Plan 新 revision
  → 失效 Plan Check、Review Projection、Review Check、Approval 和 unfinished downstream；
- Review feedback
  → 记录 feedback，路由 owner，新 artifact materialization 后按其影响传播。

### 16.3 Delivery

- implementation delta 变化
  → 失效 affected Verification、Acceptance 和 Summary；
- Verification 非 current `passed`
  → 禁止 Acceptance 和 Summary；
- Acceptance 非 current `accepted`
  → 禁止 Summary；
- Summary source binding stale
  → Summary 不再 current，但不反向改写原 Verification 或 Acceptance 历史事实。

### 16.4 Policy currentness

policy digest 变化时：

- 停在 last proven gate；
- 重新验证 current bindings 和 legal continuation；
- 不从聊天或旧 Agent context 恢复；
- 不让旧 proposed result 在新 policy 下自动物化。

## 17. Failure control

### 17.1 Intake Execution Identity

Intake proposal、confirmation 和 assignment materialization 使用独立 Intake Execution Identity：

- 最大 counted failures 为三次；
- 第三次记录 termination，禁止同一 identity 的第四次 Invocation；
- 不创建 lifecycle；
- 不消耗任何 lifecycle Task Execution budget；
- Intake 保持 `open + terminated execution`；
- 只有新的明确用户输入可以授权一个显式关联的 replacement execution。

### 17.2 Lifecycle Task Execution Identity

lifecycle 保持按 Plan task 的 Task Execution Identity：

- Impl 与 Verification 共享 budget；
- retry、Agent restart、model change、session resume、worktree replacement 或 simple→full escalation 不清零；
- 第三次终止该 identity；
- 禁止第四次 Invocation；
- 失效 unfinished downstream。

### 17.3 Failure classification

Counted failure 包括：

- 已开始 Invocation 后 Agent、工具或 command failure；
- missing、invalid、wrong-profile、wrong-scope 或 stale binding 的 Capability result；
- result-contract failure；
- declared execution failure；
- recorder/materialization operation failure；
- `implementation-defect`。

Non-counted control result 包括：

- 等待用户 confirmation、answer、review 或 acceptance；
- `needs-*`；
- `blocked`；
- `partial`；
- `full-required`；
- `escalate-full`。

Invocation 开始前已观察到的宿主能力 unavailable 不创建伪 attempt。Invocation 完成后由独立 external drift 导致的 currentness 失效时，丢弃 proposed result并 stop-and-revalidate，不将外部漂移计作该 Invocation failure。

attempt 必须在执行前记录。counted failure 必须先记录 observed failure，再触发 Failure Learning 和终止/继续决定。

### 17.4 Failure Learning

每次 counted failure 后创建非阻塞、scope-bound Failure Learning request：

```text
authority_scope
execution identity
failed attempt/evidence
scope-local main continuation
```

同一 execution identity 后续成功，或显式关联的 replacement execution 成功时，必须再次创建 Failure Learning request。仅凭 prose 相似不能形成 replacement linkage。

Failure Learning：

- 可以显式引用另一 scope 的相关证据；
- 不共享或修改另一 scope 的动态 state；
- 只产生候选；
- 自身失败不递归；
- 不改变 assignment、route、count、Verification、Acceptance 或 lifecycle result；
- 不阻塞 scope-local main continuation 或已完成 delivery。

## 18. Duplicate、stale 与 interruption

### 18.1 Currentness checkpoints

至少在以下位置验证 current bindings：

- Invocation 前；
- Capability result 返回后；
- control action 前；
- current pointer 更新前。

Invocation 使用错误前置 binding，或 result 自身 wrong-profile、wrong-scope、invalid/stale 时，进入 global invalid result，并按 policy counted fail-closed。

若 Invocation 完成后发生独立 external drift，result 不物化，记录 drift 并 non-counted stop-and-revalidate。

### 18.2 Result uniqueness

- 一个 Invocation 只接受一个终态 result；
- duplicate、late 或 cancelled Invocation result 永远不能成为 current；
- pending Intake proposal 在 Source Event、claim set、assignment target 或 policy 改变后 stale；
- stale proposal 不能被旧 confirmation Source Event 复活。

### 18.3 Interruption recovery

恢复必须重读：

```text
Intake/lifecycle state
+ current pointers
+ complete/incomplete markers
+ artifact components
+ Invocation/attempt records
+ Git facts where applicable
→ identify last proven gate
```

规则：

- 不从聊天、Agent summary 或 temporary reasoning 恢复；
- `dormant-read-only` Intake 不参与中断恢复、重激活或新 Invocation；它的只读 Source Event、decision 和 observation records 只用于历史 authority 核验；
- 完整 revision 已形成但 pointer 未更新时，保留 revision，并重新判断 currentness 后再决定是否更新 pointer；
- paired artifact 只完成一部分时，记录 incomplete，不创建 revision；
- 多目标 assignment 部分成功时保留成功目标，只继续未完成项；已完成 lifecycle target 的 binding 保持 frozen read-only；
- 无法证明唯一合法恢复动作时，返回 required-human/fail-closed；
- 不自动 repair、rollback、merge 或推断完成。

## 19. Verification strategy for Plan 35

Plan 35 只验证 Prompt/template/policy 产品合同的一致性和人工可重放性，不声称 strict machine enforcement。

### 19.1 Static consistency

实施后必须观察并报告：

- 恰好一个公共 `themis` Skill；
- 恰好十六个内部 Capability stable identities；
- 十六个 Capability 的 fixed Profile 映射唯一；
- 只有 `themis-impl` 使用 `implementation-writer`；
- 每个 Capability 声明 authority scope、inputs、outputs、legal statuses、permissions、stop conditions 和 materialization target；
- `transitions.yaml` 是唯一 route/control policy；
- Global Rule 不维护第二状态表或领域推理；
- active guidance 不声称 lifecycle 在 Intake 前创建；
- 不存在单一可变 `questioning.md`、artifact 原地覆盖或 Markdown-only authority；
- Workspace paths、artifact refs、Approval bindings 和 invalidation 一致；
- 不声称已有 Plan 36 validator、Plan 37 runtime、Plan 80 orchestration、upgrade 或 migration；
- `git diff --check` 通过。

### 19.2 Manual replay

至少覆盖以下场景：

1. 新请求 → proposal → 明确确认 → 新 lifecycle；
2. 新消息完全匹配既有 claims → 无二次确认 → 恢复原 active continuation；dormant Intake 不可复用；
3. 一条消息显式分流到多个 lifecycle；单 target 完成只冻结自身，全部完成后才整体休眠；
4. 多目标 assignment 部分成功后恢复；
5. Questioning 回答改变 claim，只确认 changed diff；
6. Review/Acceptance 消息先经过 Intake，再恢复原 dialogue；
7. Review feedback 路由正确 owner，产生新 Plan，旧 Approval stale；
8. simple path 粘性升级到 full；
9. paired artifact 半写、digest mismatch 和 pointer 更新失败；
10. stale、duplicate、late、wrong-profile 或 wrong-scope Capability result；
11. Intake 三次失败不污染 lifecycle budget；
12. Impl/Verification 共享 lifecycle task budget并在第三次终止；
13. failure 与显式关联 later success 均触发非阻塞 Failure Learning；
14. Verification/Acceptance gates 阻止提前 Summary；Summary 完整物化与 lifecycle completion observation 后触发 Intake retention 后置控制；
15. 中断后只从 last proven gate 恢复，dormant Intake 不参与恢复；
16. 明确 rejection 与宿主观察到的 abandoned，不从沉默推断；dormant Intake 后续消息创建新 Intake。

每个 replay 必须记录：

- initial durable facts；
- selected Capability/Profile/scope；
- proposed status；
- matched route；
- control action；
- materialized records/revisions；
- current pointer/gate；
- invalidation；
- failure class；
- 缺失的 Plan 36/37 machine guarantees。

## 20. Implementation impact

replacement 实施必须直接替换旧 Prompt contracts，不增加兼容层。

至少影响：

- Plan 35 active plan 与 plan index；
- `core.yaml` package declarations；
- `transitions.yaml`；
- Global Control Rule；
- 唯一公共 `themis` Skill；
- Capability package 与新增 Current Request Dialogue contract；
- `themis-q`、Failure Learning 和 Profile contracts；
- artifact templates；
- Workspace manifest、README 与 scaffold；
- module README 和 installed guidance；
- static verification 与 manual replay evidence。

旧 Plan 35 两份设计文档保留为历史记录，但 active guidance 必须明确指向本文，不得继续把旧 fifteen-Capability、lifecycle-first 或 append-only single-file Questioning 模型当作 current。

## 21. Completion and re-acceptance

replacement Plan 35 的状态转换固定为：

```text
this design reviewed and approved
→ implementation plan reviewed and approved
→ Prompt/template/policy/Workspace implementation
→ static consistency verification
→ manual replay evidence
→ user reviews actual evidence
→ user explicitly re-accepts Plan 35
```

设计获批不等于实现接受。只有最后一步完成后：

- 本文定义的 replacement Plan 35 才成为 current product authority；
- 才允许完整重基线 Plan 36；
- Plan 37 继续等待重新设计和实施后的 Plan 36；
- Plan 80/90 只在各自启动时依据当时 current contracts 一次性重基线。

完成记录：用户已于 2026-07-31 审阅静态核验、十六类人工 replay 与验收审计证据，并明确重新接受 replacement Plan 35。本文自此恢复为 current product authority；该接受不构成 Plan 36 的批准。

## 22. Acceptance criteria

1. 每条外部用户消息在任何 lifecycle 语义处理前形成 immutable Source Event；
2. 只有 active durable Intake-local confirmation 或 restart/unblock continuation 可以把新消息加入已有 Intake，其他消息一律创建新 Intake；`dormant-read-only` Intake 永不可附加；
3. Intake 在 assignment 前拥有独立 authority scope，且不创建 provisional lifecycle；
4. Source Event 原始 bytes 永久保留，claim fragment 可精确验证；
5. Current Request 由 user-confirmed、source-bound claims 构成；
6. claim/assignment 变化必须显示 changed-only semantic diff 并获得逐项明确 disposition；
7. 无 claim/assignment 变化时不要求重复确认；
8. 一条 Intake 可以显式创建或更新多个 lifecycle，partial success 可恢复且不自动 rollback；completed target 独立冻结，全部关联 lifecycle 完成后 Intake 才整体休眠；
9. 固定十六个 Capability，原十五个不被全面重组；
10. `themis-current-request-dialogue` 使用只读 `human-dialogue`，不直接持久化治理状态；
11. 保持四个 Agent Profile，不新增 governance writer；
12. 所有外部消息统一经过 Intake interception，并依据 durable continuation 恢复原对话；
13. 一个公共 Skill、一个 Global Rule 和一个 `transitions.yaml` 保持唯一；
14. route key 保持 `capability + selected_path + profile + status`；
15. Capability result 只有经 policy control、完整持久化和重读后才可物化为 authority；
16. paired semantic artifact 的 machine record 与 Markdown 任一无效时，整个 revision invalid；
17. 所有逻辑 artifacts 使用 immutable revision 与独立 current pointer；Intake dormancy 是引用不可变 decision/completion observations 的独立 operational retention fact；
18. Questioning 使用 per-round immutable artifact，不再使用单一可变 append file；
19. attempt、artifact revision、pointer、incomplete operation 和 post-completion retention fact 保持不同概念；
20. Lifecycle state 只保存最小 refs 和控制事实，不复制 artifact semantics；Intake state 只保存 control/retention facts，不改写 source/decision semantics；
21. Review Projection 是 checked Plan 的绑定投影，Approval 批准 Plan 并绑定用户实际看到的 projection；
22. Review feedback 形成独立 record 并路由 owner，Review Dialogue 不 patch Plan；
23. Verify 固定为 Impl 后独立 Verification，共享 Plan task failure budget；
24. Verification、Acceptance 和 Summary 使用独立不可变 revisions 且 gates 不可绕过；Summary 完整物化与 completion observation 后才可执行 Intake dormancy 后置控制；
25. Intake 与 Lifecycle failure budgets 隔离，各自第三次 counted failure 终止对应 Execution Identity；
26. Failure Learning 支持两种 scope，但只产生非阻塞候选且不修改主流程；
27. duplicate、late、stale、wrong-profile、wrong-scope 或 incomplete result 不得成为 current；
28. interruption 只从 durable facts 和 last proven gate 恢复；`dormant-read-only` Intake 仅供历史核验，不参与恢复、重激活或 Invocation；
29. simple path 的 `full_path_required` 在 lifecycle 内 sticky；
30. Plan 35 不实现或声称 Plan 36/37/80/90 的能力；
31. 实施完成后，静态检查与十六类人工 replay 具有实际观察证据；
32. 用户审阅实际证据并明确重新接受前，Plan 35 不恢复 current authority。
