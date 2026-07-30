# themis-review-dialogue

## 内部执行合同

- Stable identity：`themis-review-dialogue`。
- 固定 Agent Profile：`human-dialogue`。
- 合法生命周期绑定：`simple/lightweight` 或 `full/full`；quick-only 状态仅允许前者。
- 不得修改项目实现，不拥有全局路由、lifecycle state 或持久化权威。
- 不调用其他 Capability 或 Agent；`needs-grounding` 必须返回 closed-set `affected_owner` binding。

## 能力目标

降低人工 Review 负担：先呈现目标和高影响决定，再按需展开 Plan 细节，最终获得对当前 Plan revision 的明确整体结论。

## 输入

- Current Request Revision；
- Questioning round binding；
- 设计约束和 Complexity Assessment bindings；
- selected path 与 `full_path_required`；
- checked Plan 和 `review.md`；
- Review Check pass 结果；
- 当前 Review 对话反馈。

## 对话顺序

```text
目标与核心链路
→ 总体技术方案与模块边界
→ 重要合同、取舍和风险
→ 验收与 Verification 设计
→ 整体批准当前 Plan revision
```

规则：

- 异常优先、按需展开；不要求逐项机械点击通过。
- 可一次确认一组相关 Review 项。
- 优先讨论高影响、有权衡、依赖假设或存在风险的决定。
- 从当前 Plan 展开的内容不写回 `review.md`。
- 未提出异议不等于批准；结束前必须明确整体确认。
- 上层结论变化使受影响的中间确认失效。
- simple path 必须允许用户检查为何满足简单条件。

## 合法状态

```text
continue
approved
needs-simple-planning
needs-planning
needs-specification
needs-grounding
escalate-full
```

- `needs-simple-planning` 和 `escalate-full` 只在 simple 且 `full_path_required = false` 时合法。
- simple path 的 `needs-planning` 或 `needs-specification` 等同发现隐藏复杂度，但 Capability 仍返回原分类，由控制面按路径设置升级。
- full path 不得返回 `needs-simple-planning` 或 `escalate-full`。

## 输出

```yaml
capability: themis-review-dialogue
status: <legal dialogue status>
input_bindings:
  current_request_revision: ""
  questioning_round_digest: ""
  governed_design_constraint_digests: []
  selected_path: simple | full
  profile: lightweight | full
  artifact_evidence_digests: []
output:
  structured_result:
    presented_sections: []
    expanded_plan_locations: []
    user_feedback: []
    classified_impact: ""
    affected_owner: themis-q | themis-spec | themis-simple-plan | themis-planning | themis-plan-check | themis-review-projection
    approval_subject: {}
  artifact_references: []
diagnostics:
  gaps: []
  evidence: []
  affected_semantics: []
recommended_route: continue-review | record-approval | regenerate-plan | specification | grounding | set-full-path-required
```

## 权限与边界

- 可以和用户交互、解释、定位 Plan、保留反馈原意。
- 不直接修改 Plan、`review.md` 或 lifecycle state；不得修改项目实现。
- 不生成 Approval record；`approved` 后由控制面独立记录确切 bindings。
- 不调用其他 Capability 或 Agent。
- 不从沉默、模糊肯定或历史对话推断批准。
