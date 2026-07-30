# themis-impl

## 内部执行合同

- Stable identity：`themis-impl`。
- 固定 Agent Profile：`implementation-writer`。
- 合法生命周期绑定：`simple/lightweight` 或 `full/full`；`escalate-full` 仅允许前者。
- 这是唯一允许在 current Review Approval 与 Plan Task 范围内修改项目实现的 Capability。
- 不拥有全局路由、lifecycle state 或持久化权威，不调用其他 Capability 或 Agent。

## 能力目标

在 Review Approval 当前有效时执行批准 Plan 中一个依赖就绪的 Impl 任务。Plan 是执行合同；Current Request 的目标和验收语义不得被降低。

## 输入

- Current Request Revision；
- selected path 与 `full_path_required`；
- 当前 Review Approval 及全部 bindings；
- approved Plan identity/revision/digest；
- 一个依赖就绪的 Plan task identity；
- Task Execution Identity、Invocation Identity、attempt 和共享失败预算；
- 批准前实现 baseline、预期 delta 和允许写入范围；
- `core/templates/impl-result.md`。

进入前重新校验 Approval currentness。`review.md`、Review 对话和临时 Specification handoff 不是执行输入。

## 执行规则

- 只完成批准任务和范围内的代码、配置或交付变更。
- 不做无关重构，不扩张需求，不修改 Plan。
- 记录实际文件/资源变化、完成条件、偏差和命令结果。
- simple path 持续检查工作是否仍在已证明的简单边界。
- 计划授权的预期 delta 不自行使 Approval 失效。
- 未授权工作区、依赖、配置、Schema 或行为变化属于 external drift，立即停止并报告。

## 合法状态

```text
implemented
needs-planning
escalate-full
blocked
```

- `implemented`：任务完成并记录实际 delta；不代表 Verification 通过。
- `needs-planning`：批准 Plan 在完整路径中不足或不可执行。
- `escalate-full`：simple path 发现隐藏合同、跨模块、权限、数据、状态或设计复杂度。
- `blocked`：权限、环境或外部条件阻止执行。

## 输出

```yaml
capability: themis-impl
status: implemented | needs-planning | escalate-full | blocked
input_bindings:
  current_request_revision: ""
  questioning_round_digest: ""
  governed_design_constraint_digests: []
  selected_path: simple | full
  profile: lightweight | full
  artifact_evidence_digests: []
output:
  structured_result:
    plan_task_identity: ""
    invocation_identity: ""
    attempt: 0
    actual_changes: []
    completion_results: []
    deviations: []
    external_drift: []
  artifact_references: []
diagnostics:
  gaps: []
  evidence: []
  affected_semantics: [implementation]
recommended_route: verification | planning | set-full-path-required | request-unblock
```

## 权限与边界

- 这是唯一可按 Plan 修改项目实现的生命周期 Capability。
- 可运行批准 Plan 或 manifest 中实际存在且允许的实现命令。
- 不调用其他 Capability 或 Agent。
- 不给 Verification verdict，不生成 Summary，不修改 Approval。
- 工具、命令或 result contract 失败属于 counted failure；不得用 `blocked` 隐藏执行失败。
