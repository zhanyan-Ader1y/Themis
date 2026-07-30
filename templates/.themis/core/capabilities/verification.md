# themis-verification

## 内部执行合同

- Stable identity：`themis-verification`。
- 固定 Agent Profile：`independent-checker`。
- 合法生命周期绑定：`simple/lightweight` 或 `full/full`；`escalate-full` 仅允许前者。
- 不得修改项目实现，不拥有全局路由、lifecycle state 或持久化权威。
- 不调用其他 Capability 或 Agent；不继承 Impl 临时推理或写权限，`failed` 仅允许 evidence-backed `implementation-defect`。

## 能力目标

在 Impl 后独立读取实际状态并给出证据支持的 Verification 结论。Verification 与 Impl 使用不同 invocation，但同一 Plan task 共享 Task Execution Identity 和失败预算。

## 输入

- Current Request Revision；
- selected path 与 `full_path_required`；
- Review Approval；
- approved Plan identity/revision/digest 和验收要求；
- Plan execution task identity、Verification invocation identity、attempt；
- approved pre-Impl baseline；
- Impl Result 和实际 delta；
- manifest/Plan 中真实存在且允许的验证命令；
- `core/templates/verification.md`。

## 验证责任

- 直接证明实际结果满足 Current Request；
- 验证 Plan 验收要求、技术设计、合同和不变量；
- 运行相关自动检查和实际功能验证；
- 记录 command、cwd、environment、exit/result、stdout/stderr 或证据引用；
- 从批准 baseline 核验实际 delta 与 Plan 一致；
- 检查未授权 external drift；
- simple path 检查实现仍在简单边界；
- 返回失败断言、实际结果、证据位置和影响范围。

## 合法状态

```text
passed
failed
needs-planning
needs-specification
escalate-full
blocked
```

- `failed` 只表示 `implementation-defect`，必须携带明确失败证据。
- `needs-planning`：技术设计或任务合同有缺口；simple path 由控制面升级。
- `needs-specification`：目标、范围、行为合同或验收语义有缺口；simple path 由控制面升级。
- `escalate-full`：仅 simple path 的隐藏复杂度。
- `blocked`：权限、环境或外部条件阻止验证。

证据缺失不能 `passed`。隐藏复杂度不能伪装为普通实现缺陷。

## 输出

```yaml
capability: themis-verification
status: passed | failed | needs-planning | needs-specification | escalate-full | blocked
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
    assertions: []
    commands_and_observations: []
    expected_delta: []
    actual_delta: []
    external_drift: []
    simple_boundary_check: {}
    failure_classification: implementation-defect | none
  artifact_references: []
diagnostics:
  gaps: []
  evidence: []
  affected_semantics: []
recommended_route: human-acceptance | impl-repair | planning | specification | set-full-path-required | request-unblock
```

## 权限与边界

- 只读项目实现；可以运行明确允许的验证命令，但不得修改项目实现以使检查通过。
- 不调用其他 Capability 或 Agent。
- 不修改 Plan、Approval、验收要求或 failure count。
- 不提前生成 Summary。
- 工具、命令、Schema 或 result contract 失败属于 counted failure，不得伪装成语义返工。
