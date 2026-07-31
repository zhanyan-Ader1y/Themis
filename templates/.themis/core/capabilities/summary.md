# themis-summary

## 内部执行合同

- Stable identity：`themis-summary`。
- Authority scope：`lifecycle`。
- 固定 Agent Profile：`semantic-readonly`。
- 合法绑定：`simple/lightweight` 或 `full/full`。
- Materialization target：immutable paired Summary revision。
- 结果只是 bound delivery projection proposal；policy/recorder 物化后才可成为 current Summary。
- 不调用其他 Capability 或 Agent；只有 current Verification `passed` 且 current Human Acceptance `accepted` 后才可调用。

## 能力目标

描述 actual delivered result 并提供可选 governed knowledge candidates。Summary 不是中间阶段摘要，不产生新的需求、设计、实现、完成或知识 authority。

## 输入

- Current Request revision；
- approved Plan revision/digest 和 Review Approval；
- current Verification passed pair/evidence；
- current Human Acceptance accepted pair；
- actual implementation locations、limitations 和 explicit non-deliverables；
- lifecycle、Execution Identity、Invocation/attempt、policy 和 continuation bindings；
- Summary pair template。

## 合法状态

```text
ready
blocked
```

- `ready`：全部 gates 和 bindings current，形成完整 Summary proposal。
- `blocked`：必要 record/evidence/binding 不可访问或失效。

## 输出

```yaml
capability: themis-summary
authority_scope: lifecycle
agent_profile: semantic-readonly
status: ready | blocked
input_bindings:
  lifecycle_identity: ""
  execution_identity: ""
  invocation_identity: ""
  attempt_identity: ""
  current_request_revision: ""
  approval_revision: ""
  plan_revision: ""
  verification_revision: ""
  acceptance_revision: ""
  policy_identity: ""
  policy_digest: ""
  continuation_identity: ""
  selected_path: simple | full
  profile: lightweight | full
output:
  structured_result:
    summary_content: ""
    experience_candidates: []
    project_knowledge_candidates: []
  proposed_artifact_references: []
  materialization_target: summary-pair
diagnostics:
  gaps: []
  evidence: []
  affected_semantics: [delivery_summary]
recommended_route: complete-lifecycle | request-unblock
```

## 权限与边界

- 只读 approved Plan、actual implementation、Verification 和 Acceptance。
- 不得修改项目实现或 upstream artifacts，不调用其他 Capability 或 Agent。
- 不把 Summary 当作实现事实源、完成替代或知识发布动作。
- knowledge candidate 治理失败不改变 completed delivery。

## 停止条件

- Verification 非 current `passed`、Acceptance 非 current `accepted` 或 evidence/binding stale 时停止。
- actual result 与 records 无法追溯时不得返回 `ready`。
- 工具、结果合同或 Invocation 失败属于 counted failure；不得凭旧 Summary 推断完成。
