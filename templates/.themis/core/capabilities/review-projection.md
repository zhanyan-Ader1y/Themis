# themis-review-projection

## 内部执行合同

- Stable identity：`themis-review-projection`。
- 固定 Agent Profile：`semantic-readonly`。
- 合法生命周期绑定：`simple/lightweight` 或 `full/full`；`profile` 只绑定上游 Plan，不改变投影标准。
- 不得修改项目实现，不拥有全局路由、lifecycle state 或持久化权威。
- 不调用其他 Capability 或 Agent；`review.md` 始终是 checked Plan 的只读投影。

## 能力目标

把 checked Plan 压缩为只读 Human Review 投影。投影帮助理解和导航，不替代 Plan，也不评价 Plan 设计质量。

## 输入

- Current Request Revision；
- selected path 与 `full_path_required`；
- 当前 Plan 内容、revision 和 digest；
- 已通过的 Plan Check profile 和结果；
- `core/templates/review.md`。

只有当前 Plan Check `pass` 时才能生成。

## 投影规则

`review.md` 必须包含：

- 按实际需要生成的流程图或时序图 Overview；
- 目标与总体方案；
- 关键架构和模块边界；
- 重要行为、合同与不变量；
- 关键技术取舍与风险；
- 验收与 Verification 设计。

Review 项按抽象到具体、影响从高到低排列。每项包含精简结论、Agent 推荐、主要依据、影响或取舍、Plan 追溯位置。压缩自然推导和低价值细节；用户需要时由 Review Dialogue 从 Plan 展开。

## 合法状态

```text
ready
blocked
```

- `ready`：生成完整投影内容。
- `blocked`：Plan、Plan Check 或必要 binding 不可访问。

## 输出

```yaml
capability: themis-review-projection
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
    review_content: ""
    projection_map: []
    diagram_rationale: ""
  artifact_references: []
diagnostics:
  gaps: []
  evidence: []
  affected_semantics: [review_projection]
recommended_route: review-check | request-unblock
```

## 权限与边界

- 只读 Plan 和相关 bindings；不得修改项目实现或 Plan。
- 返回完整 `review.md` 内容，由控制面持久化。
- 不引入 Plan 中不存在的决定、风险或推荐。
- 不默认展示内部覆盖映射或低价值细节。
- 不调用其他 Capability 或 Agent，不批准 Plan，不计算或发明 digest。
