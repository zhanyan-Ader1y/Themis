# themis-summary

## 内部执行合同

- Stable identity：`themis-summary`。
- 固定 Agent Profile：`semantic-readonly`。
- 合法生命周期绑定：`simple/lightweight` 或 `full/full`。
- 不得修改项目实现，不拥有全局路由、lifecycle state 或持久化权威。
- 不调用其他 Capability 或 Agent；只有 current Verification `passed` 且 durable Human Acceptance `accepted` 后才可调用。

## 能力目标

描述本次实际交付结果并结束 lifecycle。Summary 不是中间阶段摘要，不产生新的需求、设计、实现或知识权威。

## 调用门禁

必须同时满足：

```text
Verification passed
Human Acceptance accepted
```

任一 binding 过期、证据失效或状态不满足时不得生成。

## 输入

- Current Request Revision；
- approved Plan identity/revision/digest；
- Review Approval；
- current Verification passed 结果和证据；
- Human Acceptance accepted 记录；
- 实际实现位置和已知限制；
- `core/templates/summary.md`。

## 内容

- 原始目标；
- 实际落地结果；
- 关键设计和实现位置；
- Verification 结论及证据入口；
- Human Acceptance 结果；
- 已知限制和明确未完成事项；
- 对应 Plan revision 与 Approval；
- 可选的项目经验候选和项目知识变更候选。

候选不会自动发布；候选治理失败不影响已完成交付。

## 合法状态

```text
ready
blocked
```

- `ready`：门禁和 bindings 当前有效，形成完整 Summary。
- `blocked`：必要记录、证据或 binding 不可访问或不再有效。

## 输出

```yaml
capability: themis-summary
status: ready | blocked
input_bindings:
  current_request_revision: ""
  questioning_round_digest: ""
  governed_design_constraint_digests: []
  selected_path: simple | full
  profile: lightweight | full
  artifact_evidence_digests: []
output:
  structured_result:
    summary_content: ""
    experience_candidates: []
    project_knowledge_candidates: []
  artifact_references: []
diagnostics:
  gaps: []
  evidence: []
  affected_semantics: [delivery_summary]
recommended_route: complete-lifecycle | request-unblock
```

## 权限与边界

- 只读 approved Plan、实际实现、Verification 和 Acceptance。
- 返回 Summary 内容，由控制面持久化；不得修改项目实现或上游工件。
- 不调用其他 Capability 或 Agent。
- 不把 Summary 当作当前实现事实源。
- 不直接发布 Themico、themis-context 或其他正式知识。
