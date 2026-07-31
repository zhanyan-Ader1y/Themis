# themis-review-check

## 内部执行合同

- Stable identity：`themis-review-check`。
- Authority scope：`lifecycle`。
- 固定 Agent Profile：`independent-checker`。
- 合法绑定：`simple/lightweight` 或 `full/full`。
- Materialization target：immutable structured Review Check record。
- 结果只是 checker proposal；policy/recorder 物化后才可进入 Human Review。
- 不调用其他 Capability 或 Agent，不继承 projection producer 的临时推理。

## 能力目标

独立检查 Review Projection 的忠实度、可追溯性和呈现负担，不评价 Plan 方案优劣，也不形成额外人工审批关卡。

## 输入

- Current Request revision；
- current Plan pair revision/digest；
- current passed Plan Check；
- current Review Projection pair 和 projection map；
- selected path/profile；
- lifecycle、Execution Identity、Invocation/attempt、policy 和 continuation bindings。

## 检查项

关键决定是否呈现、压缩是否改变原意、图形是否符合核心链路、顺序是否由抽象到具体/影响由高到低、推荐是否有依据、是否暴露过量细节、projection map 是否追溯真实 Plan。

## 合法状态

```text
pass
needs-projection
```

`needs-projection` 只允许重新生成 projection，不得修改 Plan。

## 输出

```yaml
capability: themis-review-check
authority_scope: lifecycle
agent_profile: independent-checker
status: pass | needs-projection
input_bindings:
  lifecycle_identity: ""
  execution_identity: ""
  invocation_identity: ""
  attempt_identity: ""
  current_request_revision: ""
  plan_revision: ""
  plan_check_reference: ""
  review_revision: ""
  policy_identity: ""
  policy_digest: ""
  continuation_identity: ""
  selected_path: simple | full
  profile: lightweight | full
output:
  structured_result:
    checks: []
  proposed_artifact_references: []
  materialization_target: review-check-structured-record
diagnostics:
  gaps: []
  evidence: []
  affected_semantics: [review_projection]
recommended_route: human-review | regenerate-projection
```

## 权限与边界

- 只读 Plan、Projection 和 checks；不得修改实现或任何 artifact。
- 不调用其他 Capability 或 Agent，不把 Plan quality defect 包装为 projection defect。
- 不批准 Plan，不记录 Approval。

## 停止条件

- Plan、Projection、Plan Check、scope、Profile、policy 或 continuation binding 缺失/过期时停止。
- Evidence 不足或 projection map 不可验证时不得 `pass`。
- 工具、结果合同或 Invocation 失败属于 counted failure；不得伪装为 `needs-projection`。
