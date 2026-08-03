# Review Feedback Content 模板

> 本文件保存一次 source-bound Review feedback 的人类语义。它不 patch Plan 或 Review Projection。

## Binding 摘要

- Lifecycle identity：
- Feedback revision identity：
- Review revision shown to the user：
- Current checked Plan revision：
- Feedback Source Event references 与 exact fragments：
- Affected semantic owner：
- Owner continuation：

## 保留的用户反馈

不得把 Agent 解释改写成用户结论。

## 结构化分类

- Affected semantics：
- Reason current Plan or Projection cannot remain current：
- Required owner：
- Grounding needed：`yes | no`

## Invalidation 投影

- Current Request/Questioning made stale：
- Plan revision made stale：
- Review revision made stale：
- Approval revision made stale：
- Unfinished downstream made stale：

## Revision 边界

反馈必须先形成完整、重读的 immutable pair，再由 Policy 返回 owner。单独 content 文件或对话摘要不构成 governed feedback。
