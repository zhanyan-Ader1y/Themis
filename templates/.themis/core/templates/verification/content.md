# Verification Content 模板

> 本文件保存一次 independent Verification 的人类语义。Verification 只读实际实现，不能修改项目使检查通过。

## Binding 摘要

- Lifecycle identity：
- Verification revision identity：
- Current Request revision：
- Review Approval revision：
- Plan revision/digest 与 task identity：
- Shared Plan Task Execution Identity：
- Verification Invocation/attempt identities：
- Approved pre-Impl baseline：
- Expected delta reference：
- Impl Result revision references：
- Actual implementation revision/delta reference：
- Selected path/profile 与 full path required：

## Verdict 结论

| Selected path/profile | Status |
|---|---|
| `simple/lightweight` | `passed | failed | needs-planning | needs-specification | escalate-full | blocked` |
| `full/full` | `passed | failed | needs-planning | needs-specification | blocked` |

Full path 不得使用 `escalate-full`。

- Failure classification：`implementation-defect | none`

## Current Request 与 Plan assertions

| Assertion | Expected result | Actual result | Evidence | Conclusion |
|---|---|---|---|---|

## Commands 与 observations

| Command or observation | CWD | Environment | Exit/result | stdout/stderr or evidence reference |
|---|---|---|---|---|

## Coverage 与 residual risk

| Requirement/task location | Evidence | Covered | Residual risk |
|---|---|---|---|

## Delta 与 drift

- Expected approved delta：
- Observed actual delta：
- Unauthorized external drift：
- Baseline applicability：

## Simple-path boundary 简单路径边界

- Applicable：`yes | no`
- Still simple-qualified：
- Hidden contract/data/permission/state/cross-module complexity：

## Failure、finding 或 blocker

- Classification：
- Failed assertion/blocked condition：
- Actual result：
- Evidence：
- Impacted scope：
- Human-unblock requirement：
- Preserved continuation：

## 边界

只有完整、重读并经 separate pointer 更新的 Verification pair 才可能成为 current。Writer 不能验证自身，producer self-report 不能代替 direct evidence，单独 content 文件不能建立 `passed`。
