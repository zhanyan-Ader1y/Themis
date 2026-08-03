# Impl Result Content 模板

> 本文件保存一次 approved Plan task 的实际实现语义。它不是 Verification verdict；Verify 后续必须由独立 `themis-verification` 完成。

## Binding 摘要

- Lifecycle identity：
- Impl Result revision identity：
- Current Request revision：
- Review Approval revision：
- Plan revision/digest 与 task identity：
- Shared Plan Task Execution Identity：
- Impl Invocation/attempt identities：
- Approved implementation baseline：
- Expected delta reference：
- Allowed write/command scope：
- Selected path/profile 与 full path required：

## Result 结论

| Selected path/profile | Status |
|---|---|
| `simple/lightweight` | `implemented | needs-planning | escalate-full | blocked` |
| `full/full` | `implemented | needs-planning | blocked` |

Full path 不得使用 `escalate-full`。

- Started at：
- Finished at：

## Actual changes 记录

| Path or resource | Approved expected delta | Actual delta | Evidence reference |
|---|---|---|---|

## Completion conditions 观察

| Condition | Observed result | Evidence |
|---|---|---|

## Commands 与 post-state

| Command/action | CWD/environment | Exit/result | Evidence reference |
|---|---|---|---|

- Observed post-state：

## Deviations 与 external drift

- Approved deviations：
- Unauthorized deviations：
- External drift：
- Remaining work：

## Finding 或 blocker

- Classification：
- Failed assertion：
- Direct evidence：
- Human-unblock requirement：
- Preserved continuation：

## 边界

Verify 固定为 `themis-impl → independent themis-verification`。Writer 不能签发 Verification verdict；单独 content、项目文件变化或命令成功都不能证明 pair 已完整物化或成为 current。
