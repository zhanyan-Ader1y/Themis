# 场景 11：Intake failure 与 lifecycle budget 隔离

## 初始 durable facts

- 一个 open Intake 拥有 Intake Execution Identity `I`，累计 counted failure 为 2。
- 仓库中另有已分配 lifecycle，其 Plan Task Execution Identity `L` 累计 counted failure 为 1。
- 当前 Intake 尚未形成 fully materialized assignment decision，因此不能创建新的 lifecycle。

## 选择的 Capability / Profile / scope

`themis-current-request-dialogue` / `human-dialogue` / `request-intake` / `null/null`。Failure Learning 使用同一 `request-intake` scope 的 `semantic-readonly` Profile。

## proposed status

第三次 Invocation 返回 missing/stale binding 的非法 `assignment-confirmed` proposal，因此没有合法 Intake status 可接受。

## 适用的自然语言控制规则及其标题

- [失败控制 · 隔离的 Execution Identity](../../../../templates/.themis/core/policies/references/failure-control.md#隔离的-execution-identity)：Intake 与 lifecycle budget 独立。
- [失败控制 · 计数失败](../../../../templates/.themis/core/policies/references/failure-control.md#计数失败)：先记录 attempt/failure，再 Learning，第三次终止。
- [Intake 路由 · 共同停止条件](../../../../templates/.themis/core/policies/references/routes/intake.md#共同停止条件)：invalid binding 拒绝结果。

## control action

拒绝 proposal；记录 Intake attempt 3 与 observed failure；创建 scope-bound Failure Learning request；记录 `I` termination并禁止第四次 Invocation。保持 Intake `open + terminated execution`，只有新的明确用户输入和 durable restart/unblock decision 才可建立显式关联的 replacement execution。

## materialized record/revision

Intake attempt/failure、Failure Learning request/result 和 termination observation。没有 assignment decision、Current Request 或新 lifecycle revision。

## current pointer/gate

Intake 停在 terminated execution gate。既有 lifecycle `L` 的 gate、remaining budget和 continuation保持原值；Intake 不得读取或消耗 `L` 的预算。

## invalidation

新 Intake target 未创建，不存在 lifecycle downstream invalidation。`I` 的 Invocation continuation失活，但其他 Intake和 lifecycle state不受影响。

## failure class

第三次非法 Intake result 为 `counted`；Failure Learning 自身结果按其 route 为 `none` 或 `non-counted`，且不递归。

## 缺失 machine guarantees

Scope-local budget recorder、termination enforcement、replacement linkage、assignment materializer 和 cross-scope isolation runtime 均为 `unavailable`。

## replay result

**PASS（人工合同重放）**：Intake 第三次失败只终止 `I`，不创建 lifecycle、不改变 `L` 的一次失败记录，也不能以 retry伪造第四次 Intake Invocation。
