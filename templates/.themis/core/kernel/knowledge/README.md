# Knowledge Package

## Responsibility

Knowledge 接收交付与失败流程产生的候选，并通过独立核验、Review 和人工授权决定是否发布。候选永远不是正式知识，不能改变原 lifecycle 结果。

## Capability mapping

- `themis-failure-learning`：counted failure 后的非阻塞经验候选分析。
- `themis-summary`：完成交付时识别可选项目经验和项目知识变更候选。
- `core/templates/context-summary.md`：来源支撑的治理候选结构。

## Boundaries

- Failure Learning 不改变 task state、attempt、重试决定或第三次失败终止；自身失败不递归。
- Summary 和失败记录不会自动发布为正式知识。
- 正式发布必须经过来源核验、重复/冲突检查、Review、明确授权、实际 apply 和 reread。
- `themis-context` 只收录可复用经验，不收录项目架构、设计决策或当前实现事实。
- 项目知识和项目经验必须进入各自治理区域；两者都不是当前代码事实源。

## Workspace interaction

`workspace/knowledge/` stores candidate, review, decision, and disposition. Governed project Context lives under `workspace/context/`. Plan 35 does not implement actual publication, Catalog updates, atomic apply, or interruption handling.

## Current status

Plan 35 provides internal Failure Learning and Summary Capability contracts plus candidate templates. Plan 36 owns strict candidate/apply contracts and fixtures; Plan 37 may implement only approved apply, atomic replacement, completion markers, and reread verification. Neither plan introduces a general transaction, lock, rollback, or automatic-recovery subsystem.
