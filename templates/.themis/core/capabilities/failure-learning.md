# themis-failure-learning

## 内部执行合同

- Stable identity：`themis-failure-learning`。
- 固定 Agent Profile：`semantic-readonly`。
- 合法生命周期绑定仅为 `null/null`、`simple/lightweight` 或 `full/full`。
- 不得修改项目实现，不拥有全局路由、lifecycle state 或持久化权威。
- 不调用其他 Capability 或 Agent；必须携带 lifecycle-bound `main_route_continuation`，且结果不能替换主流程或递归触发自身。

## 能力目标

每次 counted failure 记录后，独立判断该失败是否值得形成 Themico 项目经验候选。分析不改变原任务状态、重试预算、调度或第三次失败终止。

## 输入

- Task Execution Identity；
- invocation identity、attempt 和失败类型；
- authoritative input bindings；
- 失败断言和直接证据引用；
- 已采取的动作；
- 同一任务先前 attempts；
- 已知后续结果和成功 Verification（存在时）；
- `core/templates/failure-learning.md`。

## 候选条件

只有失败具有明确背景、可追溯证据，并可能形成可复用警告、诊断、规避或修正实践时提出候选。以下不得成为正式经验依据：

- 偶发环境噪声；
- 缺少证据的猜测；
- 仅当前会话有意义的信息；
- 未脱敏的敏感原始内容。

后续成功时可形成“失败后成功”候选，关联原始失败、原因或未知项、最终修正、成功证据和适用条件。

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
status: candidate-ready | not-reusable | needs-more-evidence | blocked
input_bindings:
  current_request_revision: ""
  lifecycle_identity: ""
  main_route_continuation: ""
  questioning_round_digest: ""
  governed_design_constraint_digests: []
  selected_path: simple | full | null
  profile: lightweight | full | null
  artifact_evidence_digests: []
output:
  structured_result:
    task_execution_identity: ""
    attempt: 0
    reuse_assessment: ""
    candidate: {}
    related_failure_and_success: []
  artifact_references: []
diagnostics:
  gaps: []
  evidence: []
  affected_semantics: [knowledge_candidate]
recommended_route: knowledge-governance | retain-for-later | none
```

## 权限与边界

- 只读失败记录和证据；不得修改项目实现、原任务、attempt 或 lifecycle state。
- 不调用其他 Capability 或 Agent。
- 只能提出候选，不能发布、批准或写入正式知识。
- 自身失败不得递归触发新的 Failure Learning。
- 该能力失败或 blocked 不阻塞原任务处理。
