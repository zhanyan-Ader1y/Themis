# 失败控制

> 本文件属于 [`themis-core-control`](../README.md) 唯一 Policy，拥有 scope-local failure budget、failure classification、ordered failure actions、Failure Learning 和 global invalid-result 控制。它不是独立 Policy。

## 隔离的 Execution Identity

Request Intake 使用独立 Intake Execution Identity，最多允许三次 counted failure。第三次必须记录 termination、禁止同一 identity 的第四次 Invocation，并保持 Intake `open + terminated execution`；只有新的明确用户输入才能授权显式关联的 replacement execution。Intake failure 不创建 lifecycle，也不消耗 lifecycle budget。

Lifecycle 按 Plan task 使用 Plan Task Execution Identity，最多允许三次 counted failure。`themis-impl`、`themis-verification` 和 Acceptance 的 `implementation-defect` repair 共享该 identity 与 budget。第三次必须记录 termination、禁止第四次 Invocation，并失效 unfinished task downstream。

Agent restart、model change、tool retry、session resume、worktree replacement 或 simple→full escalation 都不重置 identity 或 budget。

## 计数失败

以下结果计为 `counted`：Invocation 已开始后的 Agent、工具或 command failure；missing、invalid、wrong-profile、wrong-scope 或 stale Capability result/binding；result-contract failure；declared execution failure；recorder/materialization failure；以及 `implementation-defect`。

Attempt 必须在执行前记录。Counted failure 必须先记录 attempt 和 observed failure，再触发 Failure Learning，最后在第三次终止或保留 exact continuation。

## 非计数控制结果

等待用户 confirmation、question answer、human review 或 human acceptance 为 `non-counted`。所有合法 `needs-*`、`blocked`、`partial`、`full-required`、`escalate-full`，以及 Invocation 后独立 external drift 的 stop-and-revalidate 都为 `non-counted`。

Invocation 开始前已观察到宿主能力 unavailable 时，不创建伪 attempt，也不制造 counted failure。

## Failure Learning

每次 counted failure 后必须创建 scope-bound、non-blocking Failure Learning request，绑定 authority scope、execution identity、failed attempt/evidence 和 scope-local main continuation。同一 execution identity 后续成功，或显式关联的 replacement execution 成功时，也必须再次创建 request；prose similarity 不能建立 linkage。

Failure Learning 只产生 governed candidate，可显式引用另一 scope 的相关证据，但不能共享或修改另一 scope 的动态状态。它自身失败不递归，不改变 assignment、route、failure count、Verification、Acceptance 或 lifecycle result，也不阻塞 scope-local main continuation 或已完成 delivery。

## Invocation 前的 fail-closed

Invocation 开始前若发现必需 Policy reference/package 缺失、不可读、冲突、无法唯一定位，或 observed Policy binding 无法建立，控制面必须停在 last proven gate 并报告 unavailable/ambiguous。该预检故障不创建 attempt，不进入 counted invalid-result，也不消耗 scope-local failure budget；不得反复创建伪 Invocation 来把 unavailable 转成 failure。

## 无效结果

只有 Invocation 已开始，或 Capability proposed result 已返回后，出现 zero route match、multiple route matches、unknown status、Capability/Invocation mismatch、missing/invalid binding、stale/duplicate/late result、wrong Profile、wrong scope、Policy binding mismatch、wrong selected path/profile、full path 上的 quick-only status、illegal payload、competing terminal results、tool/command/Agent/result-contract failure，或 recorder/materialization failure时，control plane 才必须进入 counted invalid-result 并 fail closed。

Invalid result 的 control action 是拒绝 proposed result、记录对应 observed failure，并应用当前 scope 的 failure control；failure class 为 `counted`，next 为 failure-control continuation。不得从 `recommended_route`、自由文本、相近 status 或旧 Agent context 选择替代 route。

## Result uniqueness 与第四次 Invocation 禁令

一个 Invocation 只接受一个合法终态 result。第三次 counted failure 后，即使 retry、resume、换 Agent、换 model 或切换 simple/full path，也禁止同一 Execution Identity 的第四次 Invocation。

## 必须停止的情况

若无法唯一证明 Execution Identity、attempt count、failure class、scope-local continuation 或 third-failure state，控制面必须停止并要求人工裁决；不能猜测剩余预算、自动创建 replacement identity 或通过删除 attempt record 清零。
