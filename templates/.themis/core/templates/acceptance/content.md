# Human Acceptance Content 模板

> 本文件保存用户对 actual delivered result 的明确观察。它不重复 technical Verification，也不把 Agent 解释写成用户结论。

## Binding 摘要

- Lifecycle identity：
- Acceptance revision identity：
- Acceptance Source Event references 与 exact fragments：
- Current Request revision：
- Plan revision/digest：
- Review Approval revision：
- Current Verification revision/evidence：
- Actual delivered delta/evidence：
- Shared Plan Task Execution Identity：
- Selected path/profile 与 full path required：

## 精简 Acceptance view

- Delivered result：
- Acceptance requirements and conclusions：
- Key evidence entry points：
- Known limitations：

## 保留的用户反馈

逐项保存 exact Source Event fragments，不得改写为 Agent conclusions。

## Classification 分类

| Selected path/profile | Status |
|---|---|
| `simple/lightweight` | `accepted | implementation-defect | needs-planning | needs-specification | escalate-full` |
| `full/full` | `accepted | implementation-defect | needs-planning | needs-specification` |

Full path 不得使用 `escalate-full`。

- Observed difference：
- Affected semantics：
- Classification reason：
- Classified at：

## Repair 约束

`implementation-defect` 只返回 current Approval 范围内 Impl，继续使用同一 Plan Task Execution Identity/budget，并在 repair 后重新 independent Verification。

## 边界

Dialogue result 只是 proposal；只有完整 pair、重读和 separate pointer observation 后才可能 current。Silence 不等于 acceptance，非 `accepted` 不能进入 Summary。
