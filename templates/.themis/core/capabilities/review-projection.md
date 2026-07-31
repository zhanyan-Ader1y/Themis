# themis-review-projection

## 内部执行合同

- Stable identity：`themis-review-projection`。
- Authority scope：`lifecycle`。
- 固定 Agent Profile：`semantic-readonly`。
- 合法绑定：`simple/lightweight` 或 `full/full`。
- Materialization target：immutable paired Review Projection revision。
- 结果只是完整 projection content proposal；policy/recorder 才能建立 revision 和 current pointer。
- 不调用其他 Capability 或 Agent；Review Projection 始终是 checked Plan 的只读投影。

## 能力目标

把 current checked Plan 压缩为低负担 Human Review 投影，帮助理解和导航，不替代 Plan，也不重新评价技术设计。

## 输入

- Current Request revision；
- selected path、profile 和 `full_path_required`；
- current Plan pair revision/digest；
- current passed Plan Check record；
- lifecycle、Execution Identity、Invocation/attempt、policy 和 continuation bindings；
- Review Projection pair template。

## 投影规则

按实际需要生成流程图或时序图 Overview，并覆盖目标/总体方案、架构/模块边界、重要行为/合同/不变量、关键取舍/风险、验收/Verification。Review 项由抽象到具体、影响由高到低；每项包含精简结论、推荐、依据、影响/取舍和 Plan 追溯位置。

## 合法状态

```text
ready
blocked
```

- `ready`：生成忠实、完整且低负担的 projection proposal。
- `blocked`：Plan、Plan Check 或必要 binding 不可访问。

## 输出

```yaml
capability: themis-review-projection
authority_scope: lifecycle
agent_profile: semantic-readonly
status: ready | blocked
input_bindings:
  lifecycle_identity: ""
  execution_identity: ""
  invocation_identity: ""
  attempt_identity: ""
  current_request_revision: ""
  plan_revision: ""
  plan_digest: ""
  plan_check_reference: ""
  policy_identity: ""
  policy_digest: ""
  continuation_identity: ""
  selected_path: simple | full
  profile: lightweight | full
output:
  structured_result:
    review_content: ""
    projection_map: []
    diagram_rationale: ""
  proposed_artifact_references: []
  materialization_target: review-projection-pair
diagnostics:
  gaps: []
  evidence: []
  affected_semantics: [review_projection]
recommended_route: review-check | request-unblock
```

## 权限与边界

- 只读 Plan 和 bindings；不得修改实现或 Plan。
- 不引入 Plan 中不存在的决定、风险或推荐，不默认展示低价值内部细节。
- 不调用其他 Capability 或 Agent，不批准 Plan，不计算或发明 digest/currentness。

## 停止条件

- Plan Check 非 current `pass`、Plan/binding stale 或 path/profile 不匹配时停止。
- projection map 无法追溯关键 Review 内容时不得返回 `ready`。
- 工具、结果合同或 Invocation 失败属于 counted failure；external drift 单独 stop-and-revalidate。
