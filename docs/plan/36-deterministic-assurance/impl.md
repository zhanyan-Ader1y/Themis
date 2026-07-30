# Plan 36：Deterministic Assurance

> 状态：待 Plan 35 实施结果被用户单独接受后，再由用户单独确认。依赖满足不构成实施授权。

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
- Capability/Profile/Invocation mismatch；
- missing or stale binding、digest mismatch、policy-binding mismatch；
- quick-only status on full path；
- ambiguous route、zero route、duplicate route；
- permission expansion；
- invalid completion/incomplete marker combination；
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

### 4.3 Agent Profile and Invocation

定义：

- 四个 Profile 的闭集权限；
- Capability 到 Profile 的 15/15 唯一映射；
- 一次 Invocation 只能绑定一个 Capability 与固定 Profile；
- lifecycle/task/invocation/worktree identity；
- minimum input bundle；
- allowed reads/writes/commands；
- pre-Impl baseline、expected state、artifact/evidence destination；
- attempt 与 remaining failure budget。

只有 `implementation-writer` 可声明项目实现写权限。

### 4.4 Policy schema

为 `transitions.yaml` 定义 strict Schema 和 fixtures，验证：

- closed vocabularies；
- 15 个 Capability/Profile mappings；
- route key `capability + selected_path + profile + status` 唯一；
- route status 与 Capability contract 一致；
- action、next、invalidation、failure class 合法；
- guards 与 global `invalid_result` 结构合法；
- policy identity/digest binding 可追溯。

Plan 36 只验证政策，不执行 route。

### 4.5 Current Request and Questioning

定义 immutable Current Request Revision、append-only Questioning round、previous-round reference、post-answer revision、Current Questioning Pointer 和 currentness 关系。

Fixtures 验证历史修改、pointer mismatch、missing answer payload 和 stale revision 被拒绝。Plan 36 不执行 append 或 pointer update。

### 4.6 Canonical artifacts and projections

定义统一 Plan、Review projection、Review Approval、Impl Result、Verification、Human Acceptance、Summary、Failure Learning candidate 与必要 Context candidate 的 strict shape、identity、bindings、digest 和 currentness。

`review.md` 只能绑定 checked Plan，且不是 execution input。临时 Specification handoff 只作为当前 Invocation payload 被验证，不获得 durable artifact identity。

### 4.7 Lifecycle and invalidation shapes

定义 Plan 35 阶段、simple/full path、sticky `full_path_required`、Review-before-Impl、`Impl → independent Verification`、`passed → accepted → Summary`、shared failure budget、termination 与 invalidation graph 的可验证结构。

Plan 36 验证 proposed transition request/result 是否符合合同，但不改变 machine state。

### 4.8 Plan, Review, execution, and evidence

定义：

- Plan Task ID、dependency DAG、scope、owned paths、done conditions 和 traceability；
- Approval 的完整 bindings 与 pre-Impl baseline；
- expected delta、actual delta、external drift；
- Verification Gate/attempt、argv、cwd、environment allow-list、stdout/stderr refs、coverage 和 verdict；
- Human Acceptance 与 Summary source gates；
- third-failure termination 和 no-fourth-attempt invariants。

### 4.9 Worktree and minimal write safety

只定义可验证的 request/result shape 与 fixtures：

- mutating Invocation 必须绑定 worktree identity、allowed paths、baseline 和 expected state；
- 并发写入必须声明 exclusive worktree ownership；
- pre-write validation result；
- temporary-write/atomic-replace capability and observed result；
- completion/incomplete marker；
- post-write reread、Git status/diff 和 observed state；
- last proven gate 与 fail-closed interruption result。

不定义通用 transaction、lock、rollback 或 recovery protocol。

### 4.10 Governed apply and fresh publish

为已批准知识 apply 与 future fresh Init 定义最小合同：

- exact approved content/source inventory；
- target root/path and precondition identity；
- existing `.themis` fail-before-write；
- allowed writes；
- individual atomic replacement；
- completion/incomplete marker；
- reread verification and stable result。

Plan 36 不实现 apply、publish、rollback 或 installer。

## 5. Fixture corpus

```text
tests/contracts/
  primitives/
  capability-result/
  agent-profile/
  invocation/
  policy/
  questioning/
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

每组至少包含 valid minimal、valid complete、unknown field、missing required、invalid enum/ID/path/digest、stale binding、wrong path/profile、conflict、unavailable、deterministic canonical output 和 stable issue IDs。

Fixture manifest 包含 stable case ID、input refs、validator operation、expected result、expected issues 和 expected canonical digest。不得包含 production side effects 或 Shell runner。

## 6. 任务拆分

1. 盘点 Plan 35 contracts，建立统一术语与 coverage map。
2. 定义 primitives、canonicalization 与 validation issue format。
3. 定义 Capability Invocation Result、Profile 和 Invocation contracts。
4. 定义 strict policy schema 与 route fixtures。
5. 定义 Questioning、artifacts、projection 与 currentness contracts。
6. 定义 lifecycle、invalidation、Plan/Review/Verification/failure contracts。
7. 定义 worktree/minimal-write-safety、governed apply 和 fresh publish shapes。
8. 建立完整 accepted/rejected fixture corpus。
9. 运行一致性审查，确认无 runtime side effects 或语义 ownership 泄漏。
10. 将实际验证结果交给用户并获得 Plan 36 单独接受。

## 7. 验证矩阵

| 领域 | 必需验证 |
|---|---|
| Primitives | canonical encoding/digest 稳定；非法 ID/path 拒绝 |
| Capability Invocation Result | identity/status/path/profile/bindings/payload 严格校验 |
| Profiles | 15/15 固定映射；权限不可扩张；仅 writer 可写 |
| Policy | route 唯一完整；unknown/duplicate/zero-match 结构被拒绝 |
| Questioning | append-only shape 与 pointer binding 可验证 |
| Artifacts | source binding、digest、current/stale/invalid 稳定 |
| Lifecycle | sticky full、Review-before-Impl、Verify order 与 gates 可验证 |
| Plan/Review | DAG、coverage、Approval bindings、baseline currentness 可验证 |
| Verification | missing/stale evidence 不得 `passed` |
| Failure | shared count、third termination、no fourth attempt 可验证 |
| Write safety | worktree ownership、allowed paths、markers、reread shape 可验证 |
| Fresh publish | existing `.themis` 写前拒绝合同可验证 |
| Fixtures | case IDs/issues/digests 稳定，无生产副作用 |

## 8. 完成与接受条件

- 所有合同具有唯一 current、语言中立定义。
- 十五个 Capability、四个 Profile、Invocation 和 route policy 可被严格验证。
- Plan 35 lifecycle、currentness、evidence、failure 和 write-safety boundaries 均有正反例 fixtures。
- 不存在持久 Specification、功能版本、Shell runner、runtime、state mutation、transaction/lock/rollback/automatic-recovery contract。
- 实际 validator/fixture checks 已运行并报告。
- 用户单独接受 Plan 36；该接受不自动授权 Plan 37。
