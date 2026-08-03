# Failure、失效与恢复控制

> 本文件属于 [Themis Global Control Rule](../rules.md) 的按 gate 加载 reference。它解释 sticky escalation、currentness invalidation、scope-local failure budget、Failure Learning 与 last-proven-gate recovery；具体 route、failure class 和 invalidation set 由唯一 [自然语言 Policy](../../../policies/README.md) 决定。

## 加载条件

出现 sticky-full signal、bound input 变化、external drift、counted/non-counted result、invalid-result、interruption、partial materialization、third failure、unblock/restart 或 Failure Learning continuation 时加载本文件。

## 粘性升级

`full_path_required` 是 lifecycle-local 且单向 `false → true`。它跨 Questioning re-entry、reassessment、restart、resume、retry 和 implementation/verification attempt 保持，不重置 failure budget。

Policy 声明的任一 quick-path complexity signal 都必须：

1. 物化对应 finding/feedback/result；
2. 设置或保持 sticky full；
3. 应用 Policy 声明的 quick downstream invalidation；
4. 返回 full-path Specification/Planning continuation；
5. 禁止后来 `simple-qualified` 清除或绕过 sticky flag。

## Currentness 与 invalidation

只依据 observed revision/digest、Source Event binding、Current Request、Questioning、design constraints、Assessment、path/profile、Plan、Plan Check、Review Projection、Review Check、Feedback、Approval、baseline、expected delta、actual delta、Verification、Acceptance 与 Policy binding 判断 currentness。

只应用 Policy rule 明确声明的 invalidation。不得因 prose 看起来等价而保留下游 currentness，也不得扩大 invalidation 到另一 authority scope 的动态状态。

Expected approved implementation delta 不使 Approval 失效。Independent external drift 停在 revalidation gate，属于 non-counted control，除非 Policy 对 Invocation/result 的其他失败另有分类。

## Scope-local 失败预算

Request Intake 与 lifecycle 使用隔离的 Execution Identity 与预算：

- Intake Execution Identity 最多三次 counted failure；
- 每个 lifecycle Plan task 的 Plan Task Execution Identity 最多三次 counted failure；
- Impl、Verification 与 Acceptance `implementation-defect` repair 共享 lifecycle task identity/budget；
- Intake failure 不创建或消耗 lifecycle budget；
- 第三次 counted failure 终止该 identity 并禁止第四次 Invocation。

Agent restart、model change、tool retry、session resume、worktree replacement 或 simple→full escalation 都不能清零 identity/budget。

每次 counted failure 必须按序：

1. 记录 attempt 与 observed failure；
2. 建立 scope-bound Failure Learning request，绑定 failed attempt/evidence 与 exact main continuation；
3. Failure Learning 不得改变 route、budget、Verification、Acceptance 或 completion，也不递归；
4. 第一次或第二次失败保留 Policy continuation；
5. 第三次记录 termination，失活该 identity 的 Invocation continuation。

同一 identity 或明确关联的 replacement execution 后续成功时，再以 success evidence 请求 Failure Learning。Prose similarity 不能建立 linkage。

等待用户、合法 `needs-*`、`blocked`、`partial`、`full-required`、`escalate-full` 与 independent external drift 属于 non-counted control，除非具体 Policy rule 明确声明其他分类。

## 无效结果

Invocation 前 Policy package/reference unavailable 或 ambiguous 属于 preflight fail-closed：停在 last proven gate，不创建 attempt、不计入 budget。

Invocation 已开始或 result 返回后，zero/multiple rule match、unknown status、identity/binding mismatch、wrong Profile/scope/path、stale/duplicate/late result、illegal payload、competing terminal results 或 recorder/materialization failure，按 Policy 进入 counted invalid-result。不得从 diagnostics、`recommended_route` 或自由文本选择替代 route。

## 持久事实恢复

中断后重读：

```text
scope state
+ current pointers
+ complete/incomplete/termination markers
+ required artifact components
+ Invocation/attempt records
+ applicable Git facts
→ last proven gate
```

只从该 gate 的 exact durable continuation 恢复。Temporary Specification、chat、Agent report、summary、文件存在或 inferred completion 不是恢复来源。

Incomplete multi-target Intake 必须重读每个 target observation，保留 completed target，只恢复 `remaining_target_identities`。不得自动 repair、rollback、merge、resolve conflict、mutate pointer、replay completed write，或继续没有明确 Policy recovery action 的 partial write。

Terminated Intake execution 只有新的 explicit Source Event 与 durable restart/unblock continuation 才能建立 replacement execution；不得复活旧 identity。Terminated required lifecycle Plan task 阻止成功 Acceptance 与 Summary。

## 返回与停止

Failure Learning 完成或不可用后返回保存的 scope-local main continuation；Learning 自身失败不阻塞主流程。无法唯一证明 Execution Identity、attempt count、failure class、third-failure state、currentness 或 exact recovery continuation 时停止并要求人工裁决，不能猜测剩余预算或自动创建 replacement identity。
