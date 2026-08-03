# Plan 36：Deterministic Assurance

> 状态：暂停，等待 Markdown-first replacement Plan 35 完成新静态证据、人工 replay 和用户明确重新接受后，再完整重基线并由用户单独批准。本文正文中的 `transitions.yaml`、strict YAML Schema、十五个 Capability 等假设已被当前十六 Capability 与自然语言 Policy 架构取代，只作为历史设计输入，不代表当前可实施需求；本次不逐段修补或开始 Plan 36 实现。

## 1. 目标

把 Plan 35 的 Prompt-level 语义转成语言中立、严格、可验证的合同与 accepted/rejected fixtures，但不执行 lifecycle、调用 Agent、修改状态、运行项目命令或写入项目文件。

Plan 36 的合同对象是：

```text
15 internal Capability contracts
+ 4 fixed Agent Profile contracts
+ public-entry and temporary Invocation envelopes
+ transitions.yaml strict policy shape
+ lifecycle/artifact/currentness shapes
+ worktree/minimal-write-safety shapes
+ language-neutral validation fixtures
```

## 2. 边界

- 不实现 production runtime、CLI、Agent host、state recorder、policy evaluator、command runner、installer 或 writer。
- 不定义或实现跨 worktree locks、通用 transactions、rollback journals、automatic recovery、cross-worktree merge 或 conflict adjudication。
- 不创建持久 Specification artifact、`spec.yaml`、`spec.md`、Specification approval 或 Specification currentness。
- 不把 Capability 的语义判断搬进 Schema 或 validator。
- 不改变 `transitions.yaml` 的 policy ownership，也不允许 `recommended_route` 覆盖 route lookup。
- 不实现 Plan 80 multi-Agent 或 Plan 90 analytics。
- 所有合同只有一个 current definition，不建立功能版本或版本目录。

## 3. 严格拒绝原则

Validators 必须稳定拒绝：

- unknown field、unknown enum、duplicate identity、dangling reference；
- invalid relative path、path escape、wrong selected path/profile；
- Capability/Profile/Invocation mismatch、nested invocation、persistent Agent authority 或 shared memory 声明；
- public entry 重复、错误注册内部 Capability 或声明 lifecycle/semantic ownership；
- missing or stale binding、digest mismatch、policy-binding mismatch；
- 未授权 Current Request 来源、owner 已声明为独立交付但仍复用当前 lifecycle 的目标、cross-lifecycle reference；
- validator 根据结构化 owner decision 和 source references 校验归属结果，不得从自然语言自行判断需求是否独立；
- quick-only status on full path；
- ambiguous route、zero route、duplicate route，以及合法 vocabulary 组成但不符合 current semantic manifest 的 route/guard；
- permission expansion 或不可证明的 writer ownership；
- invalid completion/incomplete marker combination；
- cache-as-authority、越权 policy override、没有 observed recorder result 的 persistence claim；
- existing `.themis` 或 conflicting managed target 下的任何 fresh-init/fresh-publish write；
- prose-derived lifecycle state。

缺失或不确定信息不能通过默认值伪装为成功。Validation issue 必须具有稳定 ID、field path、category 和 machine-readable detail。

## 4. 合同范围

### 4.1 Primitives and references

定义 ID、relative path、timestamp、actor、digest、Git object ID、revision、reference、lifecycle、Task Execution、Invocation、attempt、worktree、artifact、evidence、validation issue 和 marker 类型。

明确 canonical serialization、排序、空值、Unicode、换行和 duplicate-key 规则。

### 4.2 Capability Invocation Result

统一 envelope：

```text
capability
status
input_bindings
output
  structured_result
  artifact_references
diagnostics
recommended_route
```

为十五个 Capability 锁定：

- stable identity；
- fixed `agent_profile`；
- legal `selected_path/profile`；
- legal statuses；
- required bindings；
- capability-specific payload；
- read/write/evidence permission assertions。

Result-contract failure 是 invalid invocation result，不是新的 semantic status。

### 4.3 Public entry, Agent Profile and Invocation

定义唯一公共 `themis` Skill 的入口合同：

- fresh template 中恰好注册一个公共 `themis` Skill；
- 只负责启动、继续或恢复 lifecycle，并加载 Global Rule、当前 policy、一个 Capability 与其固定 Profile；
- 不拥有 Capability 语义、route lookup、lifecycle state、artifact persistence、Approval、failure count、digest/currentness 或 invalidation；
- public entry 缺失、重复注册、引用未注册内部 Capability 或声明控制权时必须拒绝。

定义四个 Agent Profile 和 temporary Invocation：

- 四个 Profile 的闭集权限；
- Capability 到 Profile 的 15/15 唯一映射；
- 一次 Invocation 只能绑定一个 Capability 与固定 Profile；
- lifecycle/task/invocation/worktree identity；
- minimum input bundle；
- allowed reads/writes/commands；
- pre-Impl baseline、expected state、artifact/evidence destination；
- attempt 与 remaining failure budget；
- Capability 或 Agent 不得嵌套调度其他 Capability/Agent；
- temporary context、Agent summary、chat 和临时推理不得成为 lifecycle state；
- Invocation 完成后不得保留持久 Agent 权威或共享 memory。

只有 `implementation-writer` 可声明项目实现写权限。

### 4.4 Policy schema

为 `transitions.yaml` 定义 strict Schema、current semantic manifest 和 fixtures，验证：

- closed vocabularies；
- 15 个 Capability/Profile mappings；
- route key `capability + selected_path + profile + status` 唯一；
- 当前 Capability 合同中每个合法 path/profile/status 组合恰好存在一条 route，且不存在额外组合；
- 每条 route 的 `next`、`control_action`、`invalidate` 和 `failure_class` 与当前唯一政策定义精确一致，而不只是在 vocabulary 中合法；
- `authority`、`lifecycle`、guards、Review/Verify/Summary gates、failure control、invalidation 和 `assurance` 的当前语义值精确一致；
- global `invalid_result` 的适用集合与 counted fail-closed 行为精确一致；
- policy identity/digest binding 可追溯。

当前 semantic manifest 是由已接受 Plan 35 policy/Capability contracts 生成并用于 fixtures 的测试 oracle；不得被 production runtime 读取为第二路由源，也不得允许其覆盖 `transitions.yaml`。当前 route 行数只作为由 current contracts 推导出的回归观察值，不成为版本号或永久常量。Plan 36 只验证政策，不执行 route。

### 4.5 Current Request and Questioning

定义 immutable Current Request Revision、append-only Questioning round、previous-round reference、post-answer revision、Current Questioning Pointer 和 currentness 关系。

Current Request 合同必须验证：

- revision 内容只能来自用户原始请求、明确补充、纠正和明确决定；
- Agent 总结、Specification、Plan、历史需求和其他分析不得伪装为用户语义；
- 可独立批准和交付的新目标必须由拥有该判断的对话/控制合同记录为新 lifecycle decision，validator 只校验该结构化 decision、source references 与 lifecycle binding，不能自行解释自然语言；
- 新 revision 或新 lifecycle 不得清除原 lifecycle 已设置的 `full_path_required`；
- 归属不明确的输入只能保持原意并形成待澄清状态，不能由 validator 合并语义。

Fixtures 验证非法来源、错误 lifecycle 归属、历史修改、pointer mismatch、missing answer payload 和 stale revision 被拒绝。Plan 36 不执行 revision 创建、append、pointer update 或 lifecycle 分裂。

### 4.6 Canonical artifacts and projections

定义统一 Plan、Review projection、Review Approval、Impl Result、Verification、Human Acceptance、Summary、Failure Learning candidate、`experience_candidates` 和 `project_knowledge_candidates` 的 strict shape、identity、bindings、digest 和 currentness。候选对象只表达待治理内容，不获得正式知识 authority、publication status 或 lifecycle control 权限。

`review.md` 只能绑定 checked Plan，且不是 execution input。临时 Specification handoff 只作为当前 Invocation payload 被验证，不获得 durable artifact identity。

### 4.7 Lifecycle and invalidation shapes

定义 Plan 35 阶段、simple/full path、sticky `full_path_required`、Review-before-Impl、`Impl → independent Verification`、`passed → accepted → Summary`、shared failure budget、termination 与 invalidation graph 的可验证结构。

Plan 36 验证 proposed transition request/result 是否符合合同，但不改变 machine state。

### 4.8 Workspace lifecycle scoping

定义 lifecycle-scoped Workspace path、reference 和 authority contracts：

- `changes/state/runs/evidence/outcomes/<lifecycle-id>/` 中的治理记录、Invocation metadata、证据和结果必须绑定同一 lifecycle identity；
- Current Request、continuation、sticky state、Task Execution、Invocation、worktree、attempt、artifact、evidence、Acceptance、Summary、incomplete operation 和 last proven gate 不得跨 lifecycle 引用；
- 多个 lifecycle 可以绑定同一只读 policy identity/digest，但不能共享动态状态；
- `cache/` 只允许保存可重建派生数据，永非 authority；
- project policy override 必须受 closed contract 限制，不能绕过 global invariants；
- record、目录或 proposed write 的存在不证明持久化成功；需要 observed recorder result 与重读事实；
- temporary Specification handoff 不得获得 Workspace durable identity。

Fixtures 必须拒绝跨 lifecycle reference、路径 identity 不一致、cache-as-authority、越权 override 和没有 observed recorder result 的完成声明。Plan 36 不创建目录、写记录或实现 recorder。

### 4.9 Plan, Review, execution, and evidence

定义：

- Plan Task ID、dependency DAG、scope、owned paths、done conditions 和 traceability；
- Approval 的完整 bindings 与 pre-Impl baseline；
- expected delta、actual delta、external drift；
- Verification Gate/attempt、argv、cwd、environment allow-list、stdout/stderr refs、coverage 和 verdict；
- Human Acceptance 与 Summary source gates；
- counted failure 的 Task Execution Identity、attempt ordering、shared count、third-failure termination 和 no-fourth-attempt invariants；
- 每次 counted failure 必须在 observed attempt record 后形成非阻塞 Failure Learning side-path request，并保存 lifecycle-bound main-route continuation；
- Failure Learning result 不得改变主 route、failure count、verdict、Acceptance 或 lifecycle result，且该 Capability 自身失败不得递归触发 Failure Learning；
- 同一 Task Execution Identity 或显式 linked replacement task 的关联成功被观察后，必须再次形成非阻塞 Failure Learning request；仅有相似 prose 不构成 replacement linkage。

### 4.10 Worktree and minimal write safety

只定义可验证的 request/result shape 与 fixtures：

- mutating Invocation 必须绑定 worktree identity、allowed paths、baseline 和 expected state；
- 启用并发写入时必须声明 exclusive worktree ownership；
- 宿主无法提供独占 worktree 时，只允许声明 serial unique-writer ownership；无法证明唯一写入权时必须 fail closed；
- exclusive、serial 和 unavailable 三种 ownership/result shape 必须互斥且可验证；
- pre-write validation result；
- temporary-write/atomic-replace capability and observed result；
- completion/incomplete marker；
- post-write reread、Git status/diff 和 observed state；
- last proven gate 与 fail-closed interruption result。

不定义通用 transaction、lock、rollback 或 recovery protocol。

### 4.11 Governed apply and fresh publish

为已批准知识 apply 定义：

- exact approved content/source inventory；
- 已安装 Workspace 内的 target root/path、治理 decision 和 precondition identity；
- allowed writes、individual atomic replacement、completion/incomplete marker、reread verification 和 stable result；
- existing `.themis` 是合法前提，不得被误判为 fresh-init conflict。

为 future fresh Init/fresh publish 单独定义：

- source inventory、target root/path 和 managed-target precondition identity；
- existing `.themis` 或 conflicting managed target 均必须在任何写入前 fail closed；
- rejected precondition 必须证明没有 partial managed write；
- allowed writes、individual atomic replacement、completion/incomplete marker、reread verification 和 stable result。

Plan 36 不实现 apply、publish、rollback 或 installer。

## 5. Fixture corpus

```text
tests/contracts/
  primitives/
  public-entry/
  capability-result/
  agent-profile/
  invocation/
  policy/
  questioning/
  workspace/
  artifacts/
  projection/
  currentness/
  lifecycle/
  invalidation/
  plan-dag/
  review-approval/
  implementation-scope/
  verification/
  failure-control/
  acceptance/
  summary/
  governed-apply/
  fresh-publish/
  write-safety/
```

每组至少包含适用于该领域的 valid minimal、valid complete 和关键 rejected cases，以及 deterministic canonical output 与 stable issue IDs。不得为了矩阵整齐而给不适用领域制造 wrong path/profile、conflict 或 unavailable 案例。

全局 coverage matrix 必须证明以下错误类别均在具有相应语义的 fixture family 中至少覆盖一次：unknown field、missing required、invalid enum/ID/path/digest、stale binding、wrong path/profile、identity mismatch、semantic route mismatch、cross-lifecycle reference、permission expansion、writer ownership conflict、unavailable support、publish precondition conflict 和 prose-derived state。

Fixture manifest 包含 stable case ID、input refs、validator operation、expected result、expected issues 和 expected canonical digest。不得包含 production side effects 或 Shell runner。

## 6. 任务拆分

1. 盘点 Plan 35 contracts，建立统一术语、current semantic manifest 与 coverage map。
2. 定义 primitives、canonicalization 与 validation issue format。
3. 定义 public-entry、Capability Invocation Result、Profile 和 temporary Invocation contracts。
4. 定义 strict policy schema、当前完整 route/guard semantic manifest 与正反 fixtures。
5. 定义 Current Request 来源、Questioning、Workspace lifecycle scoping、artifacts、projection 与 currentness contracts。
6. 定义 lifecycle、invalidation、Plan/Review/Verification、Failure Learning 调度与 failure-control contracts。
7. 定义 exclusive-or-serial writer ownership、minimal-write-safety、governed apply 和 fresh publish shapes。
8. 建立领域适配的 accepted/rejected fixture corpus 与全局错误类别 coverage matrix。
9. 运行一致性审查，确认无 runtime side effects、语义 ownership 泄漏、跨 lifecycle 引用或第二 route authority。
10. 将实际验证结果交给用户并获得 Plan 36 单独接受。

## 7. 验证矩阵

| 领域 | 必需验证 |
|---|---|
| Primitives | canonical encoding/digest 稳定；非法 ID/path 拒绝 |
| Public entry | 恰好一个公共 `themis`；只加载控制合同；无语义、路由或持久权威 |
| Capability Invocation Result | identity/status/path/profile/bindings/payload 严格校验 |
| Profiles/Invocation | 15/15 固定映射；权限不可扩张；仅 writer 可写；无嵌套调用、持久 Agent 或共享 memory |
| Policy | route key 唯一完整；每行 action/next/invalidation/failure class 与 guards/gates 精确符合 current semantic manifest；unknown/duplicate/zero-match 拒绝 |
| Questioning | 用户来源闭集、新 lifecycle 分裂、append-only shape 与 pointer binding 可验证 |
| Workspace | lifecycle-scoped paths/references；动态状态不跨 lifecycle；cache/override/recorder authority 边界可验证 |
| Artifacts | source binding、digest、current/stale/invalid 稳定；候选不获得正式知识 authority |
| Lifecycle | sticky full、Review-before-Impl、Verify order 与 gates 可验证 |
| Plan/Review | DAG、coverage、Approval bindings、baseline currentness 可验证 |
| Verification | missing/stale evidence 不得 `passed` |
| Failure | shared count、attempt-before-learning、非阻塞/非递归、关联成功后的强制再调度与 explicit linkage、third termination、no fourth attempt 可验证 |
| Write safety | exclusive worktree 或 serial unique writer；无法证明唯一写入权时 fail closed；allowed paths、markers、reread shape 可验证 |
| Fresh publish | existing `.themis` 与 conflicting managed target 均写前拒绝，且无 partial managed write |
| Fixtures | 领域适配案例、全局错误类别 coverage、case IDs/issues/digests 稳定，无生产副作用 |

## 8. 完成与接受条件

- 所有合同具有唯一 current、语言中立定义。
- 唯一公共 `themis` 入口、十五个 Capability、四个 Profile、temporary Invocation 和 route policy 可被严格验证，且不存在持久 Agent、共享 memory 或嵌套调度权威。
- Current Request 用户来源、新 lifecycle 分裂、Workspace lifecycle scoping 和 observed persistence 边界均有正反例 fixtures。
- route/guard/gate/failure/invalidation 不仅结构合法，而且与当前唯一 semantic manifest 精确一致；manifest 不成为第二 policy authority。
- Plan 35 lifecycle、currentness、evidence、Failure Learning 调度、failure budget 和 exclusive-or-serial write-safety boundaries 均有正反例 fixtures。
- governed knowledge apply 在已安装 Workspace 内验证批准内容、目标和原子写入结果；fresh publish 在已有 `.themis` 或 conflicting managed target 时写前拒绝，并能证明没有 partial managed write。
- 不存在持久 Specification、功能版本、Shell runner、runtime、state mutation、transaction/lock/rollback/automatic-recovery contract。
- 实际 validator/fixture checks 已运行并报告，且领域 fixture 与全局 coverage matrix 均通过。
- 用户单独接受 Plan 36；该接受不自动授权 Plan 37。
