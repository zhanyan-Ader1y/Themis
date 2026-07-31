# themis-failure-learning

## 内部执行合同

- Stable identity：`themis-failure-learning`。
- Authority scope：`request-intake | lifecycle`，每次 Invocation 只能选择其中一个。
- 固定 Agent Profile：`semantic-readonly`。
- Intake 合法绑定：`selected_path: null`、`profile: null`；lifecycle 合法绑定：`null/null`、`simple/lightweight` 或 `full/full`。
- Materialization target：对应 scope 下 immutable paired Failure Learning candidate revision。
- 结果只是 candidate proposal，不发布正式知识、不改变主流程，也不替换失败事实。
- 不调用其他 Capability 或 Agent；自身失败不递归触发 Failure Learning。

## 能力目标

每次 counted failure 记录后，或同一/显式关联 replacement Execution Identity 后续成功时，独立判断是否形成可治理的 scope-bound failure/correction/success experience candidate。

## 输入

- exactly one authority scope 与 scope identity；
- scope-local Execution Identity、Invocation/attempt 和 failure record；
- authoritative input bindings 与 direct evidence；
- 已采取动作和同一 identity 的 prior attempts；
- explicitly linked later-success reference/evidence（存在时）；
- scope-local main-route continuation；
- policy binding 和 remaining budget。

prose 相似不能建立 replacement linkage。request-intake 与 lifecycle 的 state、budget、continuation 和 completion 不得互用。

## 候选条件

只在背景和证据明确、可能形成可复用 warning/diagnostic/avoidance/correction practice 时提出。偶发环境噪声、猜测、仅会话信息和未脱敏敏感内容不得形成候选。

## 合法状态

```text
candidate-ready
not-reusable
needs-more-evidence
blocked
```

## 输出

```yaml
capability: themis-failure-learning
authority_scope: request-intake | lifecycle
agent_profile: semantic-readonly
status: candidate-ready | not-reusable | needs-more-evidence | blocked
input_bindings:
  scope_identity: ""
  execution_identity: ""
  invocation_identity: ""
  attempt_identity: ""
  failure_reference: ""
  explicitly_linked_success_reference: null
  main_route_continuation: ""
  policy_identity: ""
  policy_digest: ""
  continuation_identity: ""
  selected_path: simple | full | null
  profile: lightweight | full | null
output:
  structured_result:
    reuse_assessment: ""
    candidate: {}
    related_failure_and_success: []
  proposed_artifact_references: []
  materialization_target: failure-learning-pair
diagnostics:
  gaps: []
  evidence: []
  affected_semantics: [knowledge_candidate]
recommended_route: knowledge-governance | retain-for-later | none
```

## 权限与边界

- 只读 failure/success records 和 evidence；不得修改实现、原任务、attempt、budget、continuation 或 authority state。
- 不调用其他 Capability 或 Agent，只能提出候选，不能批准或发布正式知识。
- 该能力失败、blocked 或未物化不阻塞 main route。

## 停止条件

- scope、identity、failure reference 或 main-route continuation 缺失/交叉时停止。
- later success 未显式绑定原 failure/replacement relation 时不得形成 correction/success linkage。
- 自身 Invocation 失败只记录为非递归旁路失败，不再次调用本能力。
- materialization 失败不得改变已记录 failure、failure budget 或第三次终止决定。
