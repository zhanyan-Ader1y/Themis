# Plan 35 收尾与 Capability 执行模型设计

> 历史状态：本文已被 `docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement-design.md` 取代，仅保留为历史记录，不是 current authority。

## 1. 背景

Plan 35 已建立 Prompt-first 双路径生命周期、唯一 Global Control Rule、十五项语义能力、统一 Plan、Review-before-Impl、独立 Verification、Human Acceptance、Summary、粘性完整路径升级和三次失败预算。

实施审计确认核心语义已经落地，但仍有三类结构问题：

1. `core.yaml` 仍以负向字段保留功能版本、upgrade 和 migration 概念，没有成为纯粹的无版本身份声明；
2. `transitions.yaml` 已声明阶段、状态、门禁、失效和失败预算，但能力状态到控制动作的详细路由仍复制在 Global Rule 中；
3. 十五项 Themis 语义能力全部注册为 Claude Code project Skills，扩大了自动发现和绕过控制面的入口，也把能力合同绑定到了具体 Agent 平台机制。

此外，Attribution 的非阻断 Rule 仍使用 `Specifications` 和 `Archive` 等旧生命周期术语。它不进入核心路由，但会造成 active guidance 语义漂移。

### 1.1 与既有 Plan 35 设计的关系

本文是 [Plan 35 Core Prompt Flow 设计](2026-07-29-plan-35-core-prompt-flow-design.md) 的增量修订。经批准后，本文只在以下方面取代原设计的对应表述：

- `core.yaml` 的身份字段；
- `transitions.yaml` 与 Global Rule 的路由所有权；
- 十五项语义能力的安装位置与发现方式；
- Capability、Agent Profile 和临时 Invocation 的执行模型；
- Plan 36/37 关于这些对象及最小写入安全的边界。

原设计中的 Current Request、Questioning、simple/full 路径、统一 Plan、Review-before-Impl、Verify、Human Acceptance、Summary、粘性升级、失效和三次失败预算继续有效。发生冲突时仅上述修订范围以本文为准，不得借本文重新解释其他已批准语义。

Plan 35 只有在本文对应修改完成、静态检查与人工 replay 通过并由用户明确接受后，才满足 Plan 36 的实施前置条件。

本设计关闭上述 Plan 35 缺口，并为 Plan 36 的严格合同和 Plan 37 的执行承载建立无歧义基线。

## 2. 目标

- 使 `core.yaml` 只表达无版本的安装包组合身份；
- 使 `transitions.yaml` 成为唯一完整状态路由声明源；
- 收缩 Global Rule，使其只解释和执行政策，不复制能力状态映射；
- 区分 Themis semantic capability 与 Claude Code project Skill；
- 只注册一个公共 `themis` Skill，将十五项能力迁入 Core 内部；
- 使用少量 Agent Profile 约束临时 Agent invocation，而不是注册十五个持久 Agent；
- 保持 Plan 35 的所有生命周期、门禁、失效和失败预算语义不变；
- 清理 active Attribution Rule 的旧生命周期术语；
- 明确多 lifecycle、worktree 隔离以及最小写入安全边界；
- 调整 Plan 36/37 的后续设计边界。

## 3. 非目标

本设计不：

- 实现 Plan 36 的 strict Schema、validator、canonicalization、digest 计算或 fixtures；
- 实现 Plan 37 的 production runtime、CLI、installer 或 state recorder；
- 引入通用锁、事务、复杂 rollback 或自动恢复引擎；
- 创建十五个 `.claude/agents` 持久角色；
- 允许 Agent 调用 Agent、Capability 调用 Capability 或共享 Agent memory；
- 创建持久 Specification artifact、`spec.yaml` 或 Specification approval；
- 增加功能版本、兼容矩阵、upgrade 或 migration；
- 覆盖或转换已经安装的 `.themis`；
- 改变 Plan 35 已确认的产品语义和 Human Gate。

## 4. 总体架构

```text
.claude/skills/themis/SKILL.md
        │
        ▼
Global Control Rule
        │
        ├── core/policies/transitions.yaml
        │     唯一声明合法状态路由
        │
        ├── core/capabilities/*.md
        │     十五项语义能力合同
        │
        └── core/agent-profiles/*.md
              执行权限与隔离约束
                        │
                        ▼
               temporary Agent invocation
                        │
                        ▼
                 structured result
                        │
                        ▼
              transitions.yaml next route
```

稳定职责为：

```text
Capability        = 语义合同
Agent Profile     = 执行权限和隔离合同
Agent Invocation  = 执行一次 Capability 的临时载体
transitions.yaml  = 全局路由政策
Global Rule       = 政策解释与生命周期协调
Workspace         = 每个 lifecycle 的实际记录和引用
```

## 5. Core 身份合同

`templates/.themis/core/core.yaml` 只保留：

```yaml
schema: themis-core
workspace_schema: themis-workspace
artifact_schema: themis-artifact
```

这些字段是无版本的 package/schema identity：

- `schema` 表明目录属于 Themis Core；
- `workspace_schema` 表明配套 Workspace 使用 `themis-workspace` 身份；
- `artifact_schema` 表明工件引用使用 `themis-artifact` 身份。

它们不表示 Schema 文件已经存在或被机器验证，也不表达兼容范围、功能版本或升级能力。

以下内容不得出现在 `core.yaml`：

- `version`、`core_version` 或版本目录；
- supported/writable compatibility matrix；
- upgrade、migration 或 conversion 声明；
- 生命周期状态、路由或项目配置；
- validator/runtime 可用性声明。

禁止功能版本、upgrade 和 migration 的治理规则继续由项目指导、安装包合同和模块 README 表达，不通过负向功能字段混入身份文件。

## 6. `transitions.yaml` 的职责

`transitions.yaml` 是项目安装的 Themis Core 中唯一的全局生命周期路由政策。它是只读策略声明，不是状态文件，也不是执行程序。

它负责声明：

- 生命周期阶段与 simple/full 路径；
- 每项 Capability 的合法状态；
- `capability + selected_path + profile + status` 的合法组合；
- 每个组合对应的下一目标、控制动作、失效范围和失败分类；
- Review、Verify、Acceptance 与 Summary 门禁；
- `full_path_required` 的单向粘性升级；
- counted/non-counted failure 分类；
- 全局非法结果的 fail-closed 行为。

它不负责：

- 判断需求复杂度、Plan 质量或 Verification 业务结论；
- 保存 lifecycle 当前状态；
- 保存项目事实、Plan、Approval 或 evidence；
- 调用 Agent、执行文件写入或运行 Git；
- 提供锁、事务、rollback 或 recovery；
- 替代 Plan 36 strict contracts 或 Plan 37 runtime。

## 7. 完整状态路由表

路由以展开列表表达，每个合法组合独立成项，不使用隐藏条件表达式或二级自由解析：

```yaml
routes:
  - capability: themis-complexity-assessment
    selected_path: null
    profile: null
    status: simple-qualified
    next: themis-simple-plan
    control_action: select-simple-path
    invalidate: []
    failure_class: none

  - capability: themis-plan-check
    selected_path: simple
    profile: lightweight
    status: escalate-full
    next: themis-spec
    control_action: set-sticky-full-path
    invalidate:
      - quick-plan
      - plan-check
      - review-projection
      - review-check
      - review-approval
      - unfinished-downstream
    failure_class: non-counted

  - capability: themis-verification
    selected_path: full
    profile: full
    status: failed
    next: themis-impl
    control_action: bounded-implementation-repair
    invalidate:
      - affected-verification-evidence
      - human-acceptance
      - summary
    failure_class: counted
```

### 7.1 组合键

每条路由使用：

```text
capability + selected_path + profile + status
```

- path/profile 不适用时显式使用 `null`；
- 不创建 `not-applicable` 新枚举；
- path/profile 不同导致路由不同的组合必须逐项展开；
- 每个合法组合必须恰好存在一次；
- 找不到或匹配多条都不是语义 route，而是合同失败。

### 7.2 路由输出

每条路由至少声明：

- `next`：下一 Capability、Human Gate、控制步骤或终态；
- `control_action`：控制面执行的现有 Prompt 级动作；
- `invalidate`：必须失效的已有结果类别；
- `failure_class`：`none | non-counted | counted`。

`recommended_route` 仍只是 Capability 返回中的人类建议，不能覆盖路由表。

### 7.3 非法结果

未知状态、缺失 binding、stale digest、错误 path/profile、capability 不匹配和非法 payload 不写成 Capability 状态。它们统一进入顶层规则：

```yaml
invalid_result:
  control_action: fail-closed
  failure_class: counted
  next: failure-control
```

这保证 result-contract failure 不会伪装为 `blocked`、`full-required`、`needs-planning` 或其他语义判断。

### 7.4 Prompt-level 边界

Plan 35 只声明路由数据及含义。在 validator/runtime 不存在时，Global Rule 和 Agent 只能人工遵循并明确报告 assurance unavailable，不能声称唯一性、currentness、失效或状态写入已被机器强制。

Plan 36 才为路由表建立 strict Schema、唯一性校验、完整性检查和 fixtures。

## 8. Global Control Rule 的职责收缩

Global Rule 不再逐项复制：

```text
Capability.status → 下一能力或控制动作
```

它只保留以下通用解释流程：

1. 根据当前控制位置选择待调用 Capability；
2. 检查 Capability 合同和固定 Agent Profile 可用；
3. 创建单次临时 invocation；
4. 检查返回 capability 与 invocation 请求一致；
5. 检查必要 bindings、path/profile 和上游引用；
6. 用组合键查找 `transitions.yaml`；
7. 要求恰好匹配一条路由；
8. 执行该路由声明的 `control_action`、`invalidate`、`failure_class` 和 `next`；
9. counted failure 记录 attempt，并旁路调度 Failure Learning；
10. 第三次计数失败终止同一 Task Execution Identity；
11. recorder、validator 或 runtime 不可用时停止在当前门禁并报告 unavailable。

Global Rule 可以定义通用 action vocabulary 的含义，例如：

- append Questioning round；
- update Current Questioning Pointer；
- select simple/full path；
- set sticky full path；
- persist unified Plan；
- record Review Approval；
- request unblock；
- bounded implementation repair；
- enter Human Acceptance；
- complete lifecycle。

但 Rule 不再决定哪个 Capability 状态选择哪个 action。

最终所有权为：

```text
transitions.yaml = 路由数据与政策
Global Rule      = 通用解释流程
Capability       = 语义判断
Workspace        = lifecycle 实际状态
```

## 9. 公共 Skill 与内部 Capability

### 9.1 唯一公共入口

只向 Claude Code Agent 环境注册：

```text
.claude/skills/themis/SKILL.md
```

该 Skill 负责：

- 接收用户启动、继续或恢复 Themis lifecycle 的请求；
- 定位或建立当前 lifecycle 控制上下文；
- 加载 Global Control Rule；
- 将后续选择交给 `transitions.yaml`。

它不拥有 Questioning、Planning、Review、Impl、Verification、Acceptance 或 Summary 的语义判断。

### 9.2 十五项内部 Capability

现有十五个 `themis-*` Skill 转为 Core 内部 Capability：

```text
.themis/core/capabilities/
├── questioning.md
├── grounding.md
├── complexity-assessment.md
├── simple-planning.md
├── specification.md
├── planning.md
├── plan-check.md
├── review-projection.md
├── review-check.md
├── review-dialogue.md
├── implementation.md
├── verification.md
├── acceptance-dialogue.md
├── failure-learning.md
└── summary.md
```

Capability 合同继续包含：

- stable capability identity；
- 语义责任和输入；
- current bindings；
- 合法状态和 structured payload；
- evidence 要求；
- 工具与写入边界；
- 停止条件；
- 不拥有的控制权。

Capability：

- 不参与 project Skill 自动发现；
- 不提供用户 slash-command 入口；
- 不调用其他 Capability 或 Agent；
- 不选择下一 Capability；
- 不拥有生命周期状态或持久权威。

Capability identity 可以继续使用现有 `themis-*` 名称，以保持路由和 result envelope 稳定；文件位置不赋予其 Claude Code Skill 身份。

## 10. Agent Profile

定义四类内部执行 Profile：

```text
.themis/core/agent-profiles/
├── semantic-readonly.md
├── independent-checker.md
├── human-dialogue.md
└── implementation-writer.md
```

Profile 只定义：

- 是否允许读取项目实现；
- 是否允许修改项目实现；
- 是否必须使用独立上下文；
- 是否允许继承前序 invocation 内容；
- 是否需要用户交互；
- 工具类别与 evidence 边界。

Profile 不拥有 Capability 语义、合法状态或路由。

### 10.1 固定映射

| Capability | Agent Profile |
|---|---|
| `themis-q` | `human-dialogue` |
| `themis-grounding` | `semantic-readonly` |
| `themis-complexity-assessment` | `semantic-readonly` |
| `themis-simple-plan` | `semantic-readonly` |
| `themis-spec` | `semantic-readonly` |
| `themis-planning` | `semantic-readonly` |
| `themis-plan-check` | `independent-checker` |
| `themis-review-projection` | `semantic-readonly` |
| `themis-review-check` | `independent-checker` |
| `themis-review-dialogue` | `human-dialogue` |
| `themis-impl` | `implementation-writer` |
| `themis-verification` | `independent-checker` |
| `themis-acceptance-dialogue` | `human-dialogue` |
| `themis-failure-learning` | `semantic-readonly` |
| `themis-summary` | `semantic-readonly` |

每个 Capability 恰好绑定一个 Profile，Agent 不能自行选择或扩张 Profile。

`implementation-writer` 是唯一允许修改项目实现的 Profile。`independent-checker` 不继承生成者临时推理，Verification 也不继承 Impl 写权限。

## 11. 临时 Agent Invocation

每次能力执行遵循：

```text
transitions.yaml 选择 Capability
→ 读取 Capability 合同
→ 读取其固定 Agent Profile
→ 创建一次性 Invocation Identity
→ 传入最小 current bindings
→ Agent 返回 structured result
→ 丢弃临时上下文
→ transitions.yaml 继续路由
```

Invocation 必须满足：

- 一次只加载一个 Capability；
- 只接收该能力需要的输入和 evidence references；
- result capability 必须与请求相同；
- Profile 权限不能被 Capability 输出扩张；
- Agent summary、聊天内容和临时推理不成为 lifecycle state；
- Agent 不能直接调度下一 Agent；
- 不存在持久 Agent、共享 memory、投票或共识。

### 11.1 对话型 Capability

`themis-q`、`themis-review-dialogue` 和 `themis-acceptance-dialogue` 不作为后台持续 Agent 会话运行：

```text
临时 invocation 生成当前展示或问题
→ Global Rule 向用户呈现
→ 用户原始回答写入对应 lifecycle 记录
→ 新 invocation 从 current record 继续
```

对话上下文不是正式状态源。

## 12. 多 lifecycle 与全局政策

`transitions.yaml` 不是每个 Specification、Plan 或 lifecycle 各有一份。安装包中只有一个当前全局政策：

```text
Lifecycle A ─┐
Lifecycle B ─┼── read ── transitions.yaml
Lifecycle C ─┘
```

Plan 35 不存在持久 Specification artifact；所谓多 Spec 实际是多个独立 lifecycle。

每个 lifecycle 分别拥有：

- Current Request Revision；
- Questioning round/pointer；
- selected path 与 `full_path_required`；
- Plan、Review Approval；
- Task/Invocation/attempt identities；
- evidence、Acceptance 和 Summary。

这些动态数据按 lifecycle identity 隔离。`transitions.yaml` 只读且不保存任何 lifecycle 的当前值，因此多个 lifecycle 不会因共享政策而互相覆盖。

每个 lifecycle 应绑定其实际读取的：

```yaml
policy_binding:
  identity: themis-prompt-lifecycle
  digest: "..."
```

这里的 digest 用于事实追溯，不是功能版本。

普通 lifecycle 不得修改 Core policy。政策修改必须作为独立治理 lifecycle。政策 digest 变化后，受影响的运行中 lifecycle 不得静默采用新路由，必须停止并重新核验。

## 13. Worktree 与最小写入安全

并发执行单元使用独占 worktree，避免共享可写工作区：

```text
Worktree A → Lifecycle/Task A → Policy digest D
Worktree B → Lifecycle/Task B → Policy digest D
```

Worktree 提供：

- 文件系统写入隔离；
- 独立 Git baseline、status 和 diff；
- 最终合并时的代码冲突检测。

Worktree 不自动证明单次操作已经完整写入。因此后续合同只保留最小写入安全：

- 写前验证路径、binding 和预期状态；
- 单文件先完整写临时文件，再原子替换；
- 关键多步记录使用明确完成标记；
- 中断后重新读取实际状态并 fail closed；
- 不根据部分文件猜测操作成功；
- 不自动继续、回滚或跨 worktree 合并。

不设计：

- 跨 worktree 锁；
- 通用事务引擎；
- 复杂 rollback journal；
- 自动 recovery planner。

## 14. Attribution 术语收尾

`core/kernel/attribution/rules.md` 保持 Plan 90 的非阻断边界，但改用当前生命周期术语：

- `Specifications` 替换为 Current Request、Questioning、Plan 或 supporting delivery records；
- `Archive` 替换为 lifecycle completion 或 completed delivery；
- 不进入 Global Control Rule 路由；
- 不成为 Verification、Acceptance、Summary 或 completion 的门禁。

这只是 active terminology 清理，不实现 Attribution analytics。

## 15. Plan 35 收尾范围

Plan 35 收尾实施包括：

1. 简化 `core.yaml`；
2. 为 `transitions.yaml` 补齐全部合法状态路由；
3. 从 Global Rule 删除能力专属状态映射；
4. 建立一个公共 `themis` Skill；
5. 将十五项注册 Skill 迁为内部 Capability；
6. 建立四个 Agent Profile 及固定映射；
7. 更新安装 guidance、模块 README 和路径引用；
8. 清理 Attribution 旧术语；
9. 重跑静态一致性检查和人工 replay。

Fresh-template 边界：

- 只修改源模板；
- 不覆盖已经安装的 `.themis`；
- 不提供旧安装转换；
- 不增加 upgrade/migration；
- 新目录结构只适用于未来 fresh Init。

## 16. Plan 36 边界调整

Plan 36 的严格合同对象调整为：

```text
15 internal Capability contracts
+ 4 Agent Profile contracts
+ temporary invocation envelope
+ transitions.yaml strict Schema
+ lifecycle/artifact/currentness contracts
+ language-neutral fixtures
```

Plan 36 必须验证：

- 路由组合唯一、完整并 fail closed；
- Capability 与 Profile 映射合法且唯一；
- Invocation 一次只能加载一个 Capability；
- 输入最小化且 bindings current；
- result capability 与 invocation 请求一致；
- Profile 权限不能被 Capability 或 result 扩张；
- 公共 `themis` Skill 不是 lifecycle 语义所有者；
- policy digest 变化产生稳定 stale 结果；
- Worktree identity 与 lifecycle/task identity 可追溯。

Plan 36 不再设计通用 transaction、lock、rollback 或 recovery contracts。原 Knowledge transaction 与 fresh Init 范围改为 governed apply/fresh publish 的最小写入安全合同：写前校验、临时写、原子替换、完成标记、重读核验和 fail-closed。

## 17. Plan 37 边界调整

Plan 37 负责：

- 读取已经通过 Plan 36 验证的政策、Capability、Profile 和 invocation contract；
- 在独占 worktree 中承载临时 Agent invocation；
- 使用 Git object/status/diff 核验 baseline 与 actual delta；
- 实现最小写前校验、原子文件替换、完成标记和重读核验；
- 中断后重新读取事实并 fail closed。

Plan 37 不实现通用锁、事务、复杂 rollback、自动恢复、跨 worktree 合并或冲突自动裁决。

## 18. 验证设计

### 18.1 静态检查

必须证明：

1. `core.yaml` 只包含三个无版本身份字段；
2. `.claude/skills/` 中只注册公共 `themis` 入口；
3. 十五个内部 Capability 均存在且 identity 唯一；
4. 每个 Capability 恰好绑定一个 Agent Profile；
5. 只有 `implementation-writer` 允许修改项目实现；
6. Checker 与 Verification 固定使用独立上下文；
7. 每个合法 `capability + path + profile + status` 组合恰有一条 route；
8. 不存在重复组合、未知 Capability、未知 action 或遗漏的合法状态；
9. `invalid_result` 独立于 Capability 状态并进入 counted failure；
10. Global Rule 不再复制逐状态路由；
11. Attribution active Rule 不再出现 `Specifications` 和 `Archive`；
12. guidance、README 和路径引用与新目录一致；
13. 不存在功能版本、upgrade/migration、持久 Spec、Delivery stage 或 Shell fallback。

### 18.2 人工 replay

至少重放：

- simple happy path；
- full happy path；
- Grounding partial/blocked；
- simple/full 的 needs-planning/needs-specification 差异；
- Plan Check 和后续阶段的粘性升级；
- Review Projection 返工与 Plan 返工；
- Verification implementation defect；
- invalid result counted failure；
- Impl/Verification 共享三次失败预算；
- Acceptance repair；
- Summary 门禁；
- 多 lifecycle 共享政策但隔离状态；
- policy digest 变化后的停止和重新核验。

实际输出必须被观察并交给用户。没有 Plan 36 validator 或 Plan 37 runtime 时，只能声明 Prompt-level 静态一致与人工 replay 通过。

## 19. 验收条件

本设计完成实施后，必须满足：

1. Core identity 不含功能版本、兼容矩阵、upgrade 或 migration 语义；
2. `transitions.yaml` 是能力状态路由的唯一声明源；
3. Global Rule 不复制 Capability-specific route；
4. 任一合法路由组合恰好出现一次，非法结果统一 fail closed；
5. Plan 35 生命周期、Review-before-Impl、Verify、Acceptance、Summary 和失败预算语义不变；
6. 只有一个公共 `themis` project Skill；
7. 十五项能力是不可直接发现的内部 Capability，而不是十五个注册 Skill 或持久 Agent；
8. 四个 Agent Profile 只约束执行权限，不拥有语义或路由；
9. 每次 invocation 只执行一个 Capability，完成后不保留临时 Agent 权威；
10. 多 lifecycle 共享只读政策且动态状态按 lifecycle identity 隔离；
11. 政策变化不能被运行中的 lifecycle 静默采用；
12. Worktree 提供并行写隔离，系统仅保留最小写入安全；
13. Attribution active Rule 使用当前生命周期术语；
14. 不提前实现或声称 Plan 36 strict assurance、Plan 37 runtime、Plan 80 multi-Agent 或 Plan 90 analytics；
15. 静态检查和 replay 有实际观察结果，且明确区分 Prompt-level 证明与机器保证。
