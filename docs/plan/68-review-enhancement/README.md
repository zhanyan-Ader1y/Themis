# P6.8 — Review Enhancement（评审增强）

**优先级**：P6.8
**依赖**：[P1 Template Contract](../10-template-contract/README.md)、[P5 Requirement Questioning](../50-requirement-questioning/README.md)、[P5.8 Planning Enhancement](../58-planning-enhancement/README.md)
**状态**：实施设计待确认

## 目标

在实际 Implementation 前执行只读 Review，批准 current Spec、Plan、设计、风险、实施边界、回滚、Verification 方案与人工验收方案。只有 current Review result 为 `approved` 时，Implementation 才获得授权。

完整 Policy、Protocol、Prompt、renderer、CLI 和测试设计见 [impl.md](impl.md)。

## 生命周期位置

```text
Draft → Specified → Planned → Reviewed → Implemented → Verified
      → Human Acceptance → Summary → Archived
```

Review 不读取已完成 implementation diff，不消费 Verification evidence，也不执行 Gate。它回答的是“当前 Spec 和 Plan 是否足以、安全地授权实施”，而不是“实现是否已经正确完成”。

## 输入与绑定

Review 至少绑定：

- current `spec.yaml`/`spec.md` pair 与 Spec digest；
- current Plan 与 Plan digest；
- Context Bundle、直接源码/配置/Schema 依据及 revision/digest；
- 设计选项、接口、风险、范围锁、rollback；
- Task→AC→Gate→evidence 规划；
- Verification 与 Human Acceptance 方案。

Spec、Plan 或关键依据变更后，既有 approval 失效；Implementation 不得使用 stale Review authorization。

## 评审维度

```text
requirements_coverage
design_soundness
scope_and_task_completeness
risk_and_security
verification_and_acceptance_readiness
```

Finding severity：

```text
critical | major | minor | suggestion
```

Review result：

```text
approved | changes_requested | blocked
```

未解决的 `critical` 或 `major` finding 阻止 `approved`。`minor` 和 `suggestion` 可作为非阻塞记录，但不得掩盖范围、风险或验收缺口。

## 输出边界

机器事实保存在结构化 Review artifact；`review.md` 是确定性 Human projection。Review 输出 Implementation authorization evidence，但不生成 Verification verdict、Human Acceptance decision 或 `summary.md`。

当发现问题时：

- Spec 语义或 AC 缺陷返回 Specification；
- Plan、任务、范围或验收设计缺陷返回 Planning；
- 依据缺失或冲突时返回 `blocked` 并请求补充，不猜测批准。

## 与其他阶段的区别

- Specification 对抗验证攻击需求与设计完整性；
- Review 在实施前独立攻击 Spec/Plan 的可实施性、风险和验证设计；
- Implementation 只执行已批准范围；
- Verification 在实施后用命令 Evidence 判断 Gate；
- Human Acceptance 决定用户是否接受当前交付；
- Summary 只在 Acceptance `accepted` 后生成。

## 验收条件

1. Policy、Review artifact 与 finding 使用稳定 Schema、ID 和枚举。
2. `approved` 绑定 current Spec/Plan revision 与 digest。
3. Prompt 不读取 completed implementation diff 或 Verification evidence。
4. renderer 只投影结构化结果，不进行第二次语义裁决。
5. stale authorization 在 Implementation 前 fail closed。
6. Review 与 Gate status、Verification verdict、Acceptance decision 和 lifecycle state 命名空间独立。
7. Template Contract、Review 模块、fresh Init 与相关回归测试全部通过。

## 非范围

- Implementation code review、Gate execution 或 Verification verdict；
- Human Acceptance、Summary 或 Archive runtime；
- 多评审者编排和 P8 Agent/Command/Skill 路由；
- Behavior Map、Schema Migration 或 Core 原地更新。
