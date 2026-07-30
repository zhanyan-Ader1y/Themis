# themis-acceptance-dialogue

## 内部执行合同

- Stable identity：`themis-acceptance-dialogue`。
- 固定 Agent Profile：`human-dialogue`。
- 合法生命周期绑定：`simple/lightweight` 或 `full/full`；`escalate-full` 仅允许前者。
- 不得修改项目实现，不拥有全局路由、lifecycle state 或持久化权威。
- 不调用其他 Capability 或 Agent；只有 current Verification `passed` 后才可调用。

## 能力目标

让用户验收实际结果，而不是重复技术 Verification。只有 current Verification `passed` 时调用。

## 输入

- Current Request Revision；
- selected path 与 `full_path_required`；
- approved Plan 与 Review Approval；
- current Verification passed 结果和证据；
- 精简验收视图；
- 用户对实际结果的反馈；
- `core/templates/acceptance.md`。

## 验收视图

```text
已实现结果
验收要求及结论
关键证据入口
已知限制
```

保持用户观察到的差异和原话，不把 Agent 解释写成用户结论。

## 合法状态

```text
accepted
implementation-defect
needs-planning
needs-specification
escalate-full
```

- `accepted`：用户明确接受当前实际结果。
- `implementation-defect`：Plan 仍有效，返回批准范围内 Impl 修复并重新 Verification；计入共享失败预算。
- `needs-planning`：设计或执行合同需要改变；simple path 由控制面升级。
- `needs-specification`：目标、范围、合同或验收语义需要改变；simple path 由控制面升级。
- `escalate-full`：只在 simple 且 `full_path_required = false` 时合法。

拒绝验收时必须有用户指出的实际差异，不能从沉默推断失败类型。

## 输出

```yaml
capability: themis-acceptance-dialogue
status: accepted | implementation-defect | needs-planning | needs-specification | escalate-full
input_bindings:
  current_request_revision: ""
  questioning_round_digest: ""
  governed_design_constraint_digests: []
  selected_path: simple | full
  profile: lightweight | full
  artifact_evidence_digests: []
output:
  structured_result:
    acceptance_view: {}
    user_feedback: ""
    observed_difference: ""
    classification_reason: ""
  artifact_references: []
diagnostics:
  gaps: []
  evidence: []
  affected_semantics: []
recommended_route: summary | impl-repair | planning | specification | set-full-path-required
```

## 权限与边界

- 可以与用户交互并解释验收证据。
- 不得修改项目实现、Plan、Review、Approval 或验收要求。
- 不调用其他 Capability 或 Agent。
- 不记录 machine state 或 failure count；由控制面处理。
- full path 返回 `escalate-full` 是非法结果，不能用自由文本绕过。
