# Plan 37：Native Runtime

> 状态：暂停。等待 replacement Plan 35 重新接受、Plan 36 完整重基线并实施接受后，再对本文重基线并由用户单独确认。依赖满足不构成实施授权；以下正文仅作为未来设计输入。

## 1. 目标

实现一个无功能版本的 Go runtime 和 `themis` CLI，只承担四类确定性职责：

1. 读取并执行通过 Plan 36 验证的 route policy；
2. 承载一个内部 Capability 的一次性临时 Agent invocation；
3. 记录 lifecycle-scoped state、attempt、artifacts 与 evidence references；
4. 提供 worktree-bound、fail-closed 的最小写入安全。

Runtime 不拥有 Questioning、Complexity Assessment、Specification、Planning、Review、Impl、Verification、Acceptance、Failure Learning 或 Summary 的语义判断。

## 2. 明确边界

- 一个无功能版本 Go module；不得建立 `v1`/`v2` module path 或版本目录。
- 一个 CLI 入口：`themis`。
- 生产路径不依赖 Bash、`yq` 或 `.sh` fallback。
- 不创建持久 Specification artifact 或独立 Delivery stage。
- 不实现跨 worktree locks、通用 transaction engine、rollback journal、automatic recovery planner、cross-worktree merge 或 conflict adjudication。
- 不实现 upgrade、migration、Core 原地更新或 Workspace conversion。
- 不实现 persistent Agents、Agent-to-Agent delegation、shared Agent memory、voting、consensus 或 Plan 80 orchestration。
- 不实现 Plan 90 analytics。
- 不提供通用 installer；future fresh Init 若另行批准，只能复用本计划的最小写入 primitive，并必须在已有 `.themis` 或 conflicting managed target 时于任何写入前失败，且 observed result 必须证明没有 partial managed write。

## 3. 执行模型

```text
public themis Skill or explicitly approved host adapter
→ invokes the themis CLI/runtime as a machine backend
→ runtime loads current lifecycle and bound policy
→ strict Plan 36 validation
→ transitions.yaml selects one Capability and fixed Profile
→ runtime creates one Invocation Identity
→ host runs one temporary Agent invocation
→ runtime validates Capability Invocation Result
→ runtime matches exactly one route
→ runtime records observed action/invalidation/next
```

Public `themis` Skill remains the sole public lifecycle entry. An approved host adapter may transport an already-authorized request to the CLI/runtime, but neither the adapter nor CLI/runtime may independently start, continue, restore, route or reinterpret a lifecycle.

Runtime 不解析 diagnostics 或 `recommended_route` 来覆盖政策，也不从聊天或 Agent summary 重建 state。

## 4. 核心组件

```text
cmd/themis/            CLI entry
internal/contract/     Plan 36 schema/fixture conformance
internal/policy/       closed route lookup and guard evaluation
internal/invocation/   one-Capability request/result boundary
internal/profile/      fixed permission validation
internal/workspace/    lifecycle-scoped path and record discovery
internal/state/        current gate, bindings, attempts, invalidation, markers
internal/gitstate/     object, status, diff, baseline and delta observations
internal/safepath/     root confinement and allowed-path enforcement
internal/write/        temp write, atomic replace, completion marker, reread
internal/process/      constrained explicit project commands
```

不得增加 `lock/`、`txn/`、`rollback/` 或 `recovery/` 子系统。

## 5. Policy evaluator

- strict parse and validate `transitions.yaml` against Plan 36 contracts；
- verify policy identity/digest binding；
- verify Capability/Profile mapping and route-key uniqueness；
- match exactly one `capability + selected_path + profile + status` route；
- apply declared guards, control action, invalidation and next target；
- zero/multiple match or invalid result enters global `invalid_result`；
- precondition failure causes no success transition。

Evaluator 不判断 Capability 语义。

## 6. Temporary Capability invocation

Invocation request binds：

- lifecycle、Task Execution、Invocation identity；
- selected Capability and fixed Agent Profile；
- current authoritative revisions/digests；
- selected path/profile and continuation；
- minimum input bundle；
- allowed reads/writes/commands；
- worktree identity、pre-Impl baseline and expected state；
- expected artifact/evidence destination；
- attempt and remaining budget。

Runtime validates returned Capability Invocation Result, Profile boundary and current bindings. Invocation completes after one result; temporary Agent context is discarded and never becomes shared state.

Runtime may call only an actually available host Agent interface. If unavailable, return a stable unavailable result and remain at the current proven gate.

## 7. Lifecycle-scoped recorder

Recorder writes only under the current lifecycle scope：

```text
workspace/changes/<lifecycle-id>/
workspace/state/<lifecycle-id>/
workspace/runs/<lifecycle-id>/
workspace/evidence/<lifecycle-id>/
workspace/outcomes/<lifecycle-id>/
```

It records observed facts only：

- current gate and bound policy；
- Current Request/Questioning references and pointer；
- assessment/path/sticky flag；
- Task Execution/Invocation/attempt identities；
- Plan/Review/Approval references；
- baseline, expected/actual delta and external drift；
- Impl/Verification/Acceptance/Summary references；
- invalidation, replacement, termination；
- completion/incomplete operation and last proven gate；
- Failure Learning references。

Recorder does not copy target semantics or Plan content into state records and does not invent missing operations.

## 8. Minimal write safety

### 8.1 Worktree ownership

- concurrent mutating tasks require exclusive worktree identity；
- one worktree binds one mutating lifecycle/task invocation；
- runtime verifies repository root, baseline, allowed paths and current Git state；
- if exclusive ownership cannot be proven, use one serial writer or fail closed。

Worktree provides filesystem isolation and conflict visibility at later human-controlled integration; it does not prove operation completion.

### 8.2 Individual writes

For each write：

1. validate root containment, allowed path, bindings, baseline and expected state；
2. write complete content to a same-directory temporary file where replacement is applicable；
3. close and atomically replace one target when the platform supports the required guarantee；
4. record completion or incomplete marker for critical multi-step operations；
5. reread target, record, Git status/diff and observed post-state；
6. report success only when postconditions are observed。

If a platform cannot provide a required atomic replacement, return unsupported/unavailable rather than silently weakening the contract.

### 8.3 Interruption

After interruption：

- reread actual lifecycle records, files, markers and Git facts；
- identify the last proven gate；
- return resume-from-proven-gate or fail-closed-required-human；
- never infer success from partial files；
- never automatically roll back, repair, merge worktrees or adjudicate conflicts。

## 9. Constrained commands and evidence

Explicit project commands may be executed only from approved Plan/manifest references using argv arrays, governed cwd, environment allow-list, timeout/cancellation, stdout/stderr capture, exit classification and evidence references.

The command runner does not invent missing commands or semantic assertions. Verification verdict remains owned by the internal Verification Capability.

## 10. Failure control

- maintain capability task and Plan execution task identities；
- record counted attempt before Failure Learning side path；
- after each observed counted failure, create a lifecycle-bound non-blocking Failure Learning request and preserve the main-route continuation；
- Impl and Verification share one Plan task failure count；
- restart, model change, retry, resume and worktree replacement do not reset count；
- third counted failure records termination and rejects a fourth invocation；
- when later success is observed for the same Task Execution Identity or an explicitly linked replacement task, create another lifecycle-bound non-blocking Failure Learning request；
- prose similarity alone never creates replacement linkage；
- Failure Learning result cannot alter route, count, verdict, Acceptance or lifecycle result；
- Failure Learning invocation failure does not recursively schedule Failure Learning；
- Failure Learning remains semantic and non-blocking。

## 11. 任务拆分

1. 建立无版本 Go module、CLI machine-result contract 和测试基线。
2. 实现 Plan 36 strict contract loading and conformance。
3. 实现 policy evaluator、guards、invalid result and route lookup。
4. 实现 fixed Profile and temporary Invocation boundary。
5. 实现 lifecycle-scoped state recorder and currentness checks。
6. 实现 safepath、Git baseline/status/diff observations。
7. 实现 worktree ownership validation and serial-writer fallback。
8. 实现 temp write、atomic single-file replacement、markers、reread verification and fresh-publish precondition rejection evidence。
9. 实现 constrained command/evidence runner、failure budget recording and Failure Learning dispatch bookkeeping。
10. 执行 unit、contract、integration、security and supported-platform validation。
11. 将实际证据交给用户并获得 Plan 37 单独接受。

## 12. 测试策略

### Unit

覆盖 strict parsing、route lookup、guards、Profile permissions、currentness、safe paths、Git observations、state records、failure count、markers and atomic replacement capability detection。

### Contract conformance

读取 Plan 36 fixtures，验证 stable result、issue IDs、canonical digests and zero unintended side effects。

### Integration

至少覆盖：

- public `themis` Skill authorization reaches the machine backend, while an unbound direct CLI/host request cannot start, continue, restore or route a lifecycle；
- one Capability per invocation；
- valid/invalid/stale/wrong-profile Capability Invocation Result；
- simple/full route and sticky escalation；
- Review-before-Impl and `Impl → independent Verification`；
- lifecycle isolation and shared policy；
- exclusive worktree validation and overlapping-write rejection；
- serial writer fallback；
- interruption with complete/incomplete markers；
- third failure termination and no fourth attempt；
- counted failure is recorded before a non-blocking Failure Learning request；
- explicitly linked later success schedules Failure Learning again, while prose-only similarity does not create linkage；
- Failure Learning self-failure is non-recursive and never changes the main route or failure count；
- non-passed Acceptance rejection and Summary gate；
- existing `.themis` or a conflicting managed target rejects any future fresh-publish call path before its first write；
- rejected fresh-publish preconditions leave no partial managed write and return observed proof。

### Security and platform

覆盖 traversal、symlink/junction/reparse-point escape、case collision、unsafe replacement、disk-full、permission failure、process injection、secret redaction、concurrent writers and interruption。只对实际运行的平台声明通过。

## 13. 完成与接受条件

- 一个无功能版本 Go module 和一个 `themis` CLI 可构建。
- Plan 36 contracts and fixtures are implemented and pass。
- policy evaluator, temporary Capability invocation, per-lifecycle recorder and minimal write safety are operational。
- public `themis` Skill remains the sole public lifecycle entry；CLI/runtime and approved host adapters are machine transports without independent lifecycle authority。
- one-Capability/fixed-Profile boundary、route uniqueness、sticky full、Review-before-Impl、Verify order、shared failure budget and Summary gate are enforced。
- counted-failure and explicitly linked later-success Failure Learning dispatches are recorded as non-blocking side paths, and Failure Learning self-failure is non-recursive。
- future fresh-publish preconditions reject existing `.themis` or conflicting managed targets before any write and prove no partial managed write。
- only `implementation-writer` can modify project implementation。
- no persistent Specification、Delivery、Shell fallback、upgrade/migration、general locks/transactions/rollback/automatic recovery or multi-Agent orchestration exists。
- supported-platform evidence, `go test ./...`, build, contract corpus and `git diff --check` pass。
- unsupported or unavailable guarantees are reported explicitly。
- 用户审阅实际证据并单独接受 Plan 37。
