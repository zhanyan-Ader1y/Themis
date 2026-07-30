# themis-review-check

## 内部执行合同

- Stable identity：`themis-review-check`。
- 固定 Agent Profile：`independent-checker`。
- 合法生命周期绑定：`simple/lightweight` 或 `full/full`；`profile` 只绑定上游 Plan，不改变检查标准。
- 不得修改项目实现，不拥有全局路由、lifecycle state 或持久化权威。
- 不调用其他 Capability 或 Agent；不继承投影生成者的临时推理。

## 能力目标

检查 Review Projection 的忠实度和呈现质量。该能力不评价 Plan 方案优劣，也不形成额外人工审批关卡。

## 输入

- Current Request Revision binding；
- 当前 Plan 内容、revision/digest；
- Plan Check profile 和 pass 结果；
- 当前 `review.md` 内容和 projection map；
- selected path。

Checker 必须与投影生成过程隔离，不继承生成者临时上下文。

## 检查项

- 需要人工批准的关键决策是否呈现；
- 压缩是否改变 Plan 原意；
- 图形 Overview 是否与核心链路一致；
- 内容是否从抽象到具体、影响从高到低；
- 推荐是否附主要依据；
- 是否暴露过量低价值细节；
- projection map 是否可追溯到真实 Plan 内容。

## 合法状态

```text
pass
needs-projection
```

检查失败只允许重新生成投影，不得修改 Plan。

## 输出

```yaml
capability: themis-review-check
status: pass | needs-projection
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
        conclusion: pass | fail
        plan_reference: ""
        review_reference: ""
        reason: ""
  artifact_references: []
diagnostics:
  gaps: []
  evidence: []
  affected_semantics: [review_projection]
recommended_route: human-review | regenerate-projection
```

## 权限与边界

- 只读 Plan、Review 和检查结果；不得修改项目实现或任何工件。
- 不调用其他 Capability 或 Agent。
- 不把 Plan 质量问题包装为 projection 问题；只能判断真实投影缺陷。
- 缺少或过期 binding 时不得报告 `pass`。
