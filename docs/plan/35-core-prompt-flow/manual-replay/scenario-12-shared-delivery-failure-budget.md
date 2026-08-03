# 场景 12：Delivery 共享三次失败预算

## 初始 durable facts

- Current Approval、Plan task、baseline、expected delta、path/profile 与 Plan Task Execution Identity `T` 均 current。
- `T` 初始 counted failure 为 0；Impl writer 与 Verification checker 必须使用不同 Invocation/attempt。

## 选择的 Capability / Profile / scope

- `themis-impl` / `implementation-writer` / `lifecycle`。
- `themis-verification` / `independent-checker` / `lifecycle`。
- `themis-acceptance-dialogue` / `human-dialogue` / `lifecycle`。

## proposed status

- Attempt 1：Impl command/result failure，counted；后续 retry `implemented`。
- Attempt 2：independent Verification 返回 `failed`，counted；bounded repair后重新 Verification并 `passed`。
- Attempt 3：Acceptance 返回 `implementation-defect`，counted。

## 适用的自然语言控制规则及其标题

- [交付阶段路由 · Impl](../../../../templates/.themis/core/policies/references/routes/delivery.md#themis-impl--implementation-writer)：`implemented` 后只进入 independent Verification。
- [交付阶段路由 · Verification](../../../../templates/.themis/core/policies/references/routes/delivery.md#themis-verification--independent-checker)：`failed` 返回 bounded Impl repair并共享 budget。
- [交付阶段路由 · Acceptance](../../../../templates/.themis/core/policies/references/routes/delivery.md#themis-acceptance-dialogue--human-dialogue)：`implementation-defect` 共享同一 task identity并要求 re-Verification。
- [失败控制 · 隔离的 Execution Identity](../../../../templates/.themis/core/policies/references/failure-control.md#隔离的-execution-identity)：第三次终止且禁止第四次 Invocation。

## control action

每次 counted failure 都按序记录 attempt/failure、创建 non-blocking Failure Learning request，并保留同一 `T`。成功 retry不清零累计数。第三次 Acceptance defect 后记录 `T` termination，失活 repair continuation，禁止第四次 Impl Invocation。

## materialized record/revision

Impl Result pairs、Verification failure/passed pairs、Acceptance defect observation、各 attempt/failure、Learning requests和最终 termination observation；所有记录绑定同一 `T`，但使用各自 Invocation/attempt identity。

## current pointer/gate

Attempt 2 repair完成后必须由新的 independent Verification `passed` 才可进入 Acceptance。Attempt 3 后停在 terminated Plan task；不能进入 Summary或继续 repair。

## invalidation

每次 implementation/verification defect失效 affected Verification evidence、Human Acceptance与 Summary。第三次终止还失效 unfinished task downstream；Approval范围外变化另走 revalidation。

## failure class

Impl execution failure、Verification `failed` 与 Acceptance `implementation-defect` 均为 `counted`；合法 `implemented`、`passed` 为 `none`，但不重置 count。

## 缺失 machine guarantees

Command runner、evidence recorder、shared budget counter、writer/checker isolation、termination enforcement 和 re-Verification runtime 均为 `unavailable`。

## replay result

**PASS（人工合同重放）**：Impl、Verification 与 Acceptance repair 使用不同 Invocation但共享 `T` 的累计三次预算；第三次 defect终止 task并禁止第四次 repair。
