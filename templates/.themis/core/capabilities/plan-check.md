# themis-plan-check

## 内部执行合同

- Stable identity：`themis-plan-check`。
- 固定 Agent Profile：`independent-checker`。
- 合法生命周期绑定：`simple/lightweight` 或 `full/full`，两组状态集合分别锁定。
- 不得修改项目实现，不拥有全局路由、lifecycle state 或持久化权威。
- 不调用其他 Capability 或 Agent；不继承 Plan 生成者的临时推理。

## 能力目标

在与 Plan 生成过程隔离的上下文中检查当前 Plan。Checker 只评价 Plan 是否满足指定 profile，不修改 Plan，也不继承生成者未写入 Plan 的临时推理。

## 输入

- Current Request Revision；
- Current Questioning round 与 digest；
- 受治理设计约束 revisions/digests；
- Complexity Assessment 与 selected path；
- 当前 Plan 内容、revision/digest；
- 当前实现事实 baseline 与直接证据；
- profile：`lightweight | full`；
- full profile 时的临时 Specification handoff。

## 合法状态

### Lightweight profile

检查：Current Request 覆盖、直接事实证据、范围与排除项、可执行步骤、完成条件、Verification 方法、继续满足简单条件、未解释假设。

合法状态：

```text
pass
needs-simple-planning
escalate-full
blocked
```

## Full profile

检查：Current Request 与 handoff 一致性、完整技术设计、架构/模块/接口/数据/状态/失败行为、直接事实证据、每项验收的 Verification、任务可执行性、冲突和分类覆盖映射。

合法状态：

```text
pass
needs-planning
needs-specification
needs-grounding
blocked
```

两种 profile 都不能降低需求覆盖、事实证据、验证设计或可执行性。`needs-simple-planning` 和 `escalate-full` 仅在 simple 且 `full_path_required = false` 时合法。

## 输出

```yaml
capability: themis-plan-check
status: <profile-legal status>
input_bindings:
  current_request_revision: ""
  questioning_round_digest: ""
  governed_design_constraint_digests: []
  selected_path: simple | full
  profile: lightweight | full
  artifact_evidence_digests: []
output:
  structured_result:
    checks:
      - check: ""
        conclusion: pass | fail | blocked
        evidence: []
        affected_plan_location: ""
    plan_check_result: ""
  artifact_references: []
diagnostics:
  gaps: []
  evidence: []
  affected_semantics: [plan_quality]
recommended_route: review-projection | regenerate-plan | specification | grounding | set-full-path-required | request-unblock
```

## 权限与边界

- 只读项目和工件；不得修改项目实现、Plan 或 lifecycle state。
- 不调用其他 Capability 或 Agent。
- 不把 Review presentation 质量纳入本检查。
- 未知状态、错误 profile 状态、缺少或过期 binding 必须返回非法结果，由控制面拒绝；不得用自由文本建议绕过。
