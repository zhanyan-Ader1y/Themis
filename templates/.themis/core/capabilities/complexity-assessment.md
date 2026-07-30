# themis-complexity-assessment

## 内部执行合同

- Stable identity：`themis-complexity-assessment`。
- 固定 Agent Profile：`semantic-readonly`。
- 合法生命周期绑定：`selected_path: null`、`profile: null`。
- 不得修改项目实现，不拥有全局路由、lifecycle state 或持久化权威。
- 不调用其他 Capability 或 Agent；`full_path_required` 由控制面按 policy guard 管理。

## 能力目标

在追问收敛后，独立判断当前需求能否安全跳过 Specification 与完整 Planning。只有全部简单条件被证明时才能返回 `simple-qualified`。

## 输入

- Requirement Input Bundle；
- Current Request Revision；
- Current Questioning Pointer 指向的 round 与 digest；
- 受治理设计约束 revisions/digests；
- 当前实现事实证据和 baseline；
- 用户明确声明的附加约束。

不读取其他需求的 Specification 或完整历史对话。

## 简单条件

逐项检查并引用直接证据：

1. 目标、范围与可观察结果清晰；
2. 修改局部且边界明确；
3. 不新增或改变外部行为合同；
4. 不涉及跨模块设计；
5. 不涉及权限或安全复杂度；
6. 不涉及并发复杂度；
7. 不涉及数据完整性复杂度；
8. 不改变状态模型；
9. 验收要求和验证方法明确；
10. 不依赖未核验事实或隐藏假设。

文件数、代码行数、API 数和预计耗时只能作为辅助信息。

## 合法状态

```text
simple-qualified
full-required
blocked
```

- `simple-qualified`：全部条件均被证明为满足。
- `full-required`：任一条件为 non-simple、uncertain 或缺少直接证据。
- `blocked`：必要读取权限、环境或外部条件不可获得。

工具、命令、Schema、Agent 或 binding 失败属于 invocation failure，不得改写为 `full-required`。

## 输出

```yaml
capability: themis-complexity-assessment
status: simple-qualified | full-required | blocked
input_bindings:
  current_request_revision: ""
  questioning_round_digest: ""
  governed_design_constraint_digests: []
  selected_path: null
  artifact_evidence_digests: []
output:
  structured_result:
    criteria:
      - criterion: ""
        conclusion: simple | non-simple | uncertain
        evidence: []
        rationale: ""
    assessment_digest: <control supplied | unavailable>
  artifact_references: []
diagnostics:
  gaps: []
  evidence: []
  affected_semantics: [path_selection]
recommended_route: simple-plan | full-path | request-unblock
```

## 权限与边界

- 使用独立只读 Agent；不得继承后续 Plan 生成者的临时推理。
- 可以读取项目事实，但不得修改项目实现、需求、Plan 或 lifecycle state。
- 不调用其他 Capability 或 Agent。
- 不设置 `full_path_required`；控制面根据合法结果设置。
- 不从 Specification、设计文档或知识库推导当前实现事实。
