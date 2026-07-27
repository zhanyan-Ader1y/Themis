# P6.5 — 验证增强（Verification Enhancement）

**优先级**：P6.5
**依赖**：[P1 Template Contract](../10-template-contract/README.md)、[P5 Requirement Questioning](../50-requirement-questioning/README.md)、[P5.8 Planning Enhancement](../58-planning-enhancement/README.md)、[P6.8 Review Enhancement](../68-review-enhancement/README.md)、[P5.9 Implementation Enhancement](../59-implementation-enhancement/README.md)
**状态**：待用户主动发起

## 目标

在 Implementation 完成后执行可重复 Gate，记录命令支持的事实，并生成稳定 Verification verdict：

```text
pass | fail | inconclusive
```

Verification 必须消费 current Spec、Plan、已批准且未过期的 Review authorization，以及当前 Implementation revision。完整状态机、协议、CLI、repair/resume 和测试设计见 [impl.md](impl.md)。

## 记录内容

每次 Run 至少绑定：

- Spec、Plan、approved Review 的 revision/digest；
- Implementation revision/digest 和 Task evidence；
- AC→Gate 与 AC→evidence 覆盖；
- effective policy、manifest command、准确 args/cwd、相关环境和工具版本；
- exit code、stdout/stderr 引用、开始/结束时间；
- 失败分类、可复现场景、修复交接、变更 revision、失效证据与重跑记录；
- unavailable checks、evidence gaps、最终 verdict 和人工验收说明。

Verification 不读取自由文本 Review 作为授权，不修改实现代码，也不生成 `summary.md`。

## Gate 与失败处理

Gate execution status：

```text
pending | running | passed | failed | skipped | error
```

失败分类：

```text
transient
code_failure
configuration_failure
policy_conflict
evidence_insufficient
assumption_violated
unknown
```

首个 blocking Gate 失败后停止并持久化证据，生成有界 repair handoff。外部 Agent 或用户修复后，`resume` 绑定新 revision、使受影响证据失效，并只重跑必要 Gate。初次失败后最多允许三轮 repair/rerun；耗尽时写入 escalation 并返回进程退出码 `2`。

## 生命周期边界

```text
Reviewed → Implemented → Verified → Human Acceptance → Summary → Archived
```

- Review 在 Implementation 前批准 Spec、Plan、风险、实施边界与验收方案；
- Verification 在 Implementation 后记录 Gate 事实；
- `pass` 只允许进入 Human Acceptance，不等于人工接受；
- Human Acceptance `accepted` 后才能由确定性操作生成 `summary.md`；
- `summary.md` 是最终交付的 Human projection，不是 Verification verdict、机器状态或独立事实源。

## 与退役能力的关系

Behavior Map、Upgrade 与 Migration 已从当前产品退役，不是 Verification 的依赖或回归目标。需要代码事实时直接检查 current source/config/schema 并记录 revision/digest；不依赖第二套源码表示。

## 验收条件

1. Gate policy、Run/Evidence/Verdict/Repair/Escalation 协议使用稳定 ID 和枚举。
2. 每次 Gate 可由记录的命令、环境、revision 和输出引用重复执行。
3. stale Review authorization 在执行 Gate 前被拒绝。
4. `pass`、`fail`、`inconclusive` 与 Gate execution status 保持独立命名空间。
5. repair/resume、证据失效、尝试预算和 exhaustion 跨进程持久化。
6. Verification 不修改实现，也不绕过 Human Acceptance 或生成 Summary。
7. Template Contract、Verification 模块、fresh Init 与相关回归测试全部通过。

## 非范围

- Review executor、Implementation executor、Human Acceptance 或 Summary runtime；
- 自动修改代码或配置；
- Behavior Map、Schema Migration 或 Core 原地更新；
- P8 Agent/Command/Skill 路由。
