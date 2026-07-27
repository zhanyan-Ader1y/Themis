# P6.8 前置 Review 实施索引

P6.8 将 Review 落地为 Implementation 前的只读设计与计划批准。机器结果保存在 versioned Review evidence 中，`review.md` 是确定性 Human projection；Review 批准 current Spec/Plan、设计、风险、scope lock、回滚与验收方案后，才允许 Implementation。

**状态**：实施设计待用户确认。原计划中“Verification 后审查实现”的方向已被正式设计替代；实施时以本索引和 `docs/design/core/kernel/review.md` 为准。

## 设计决策

| # | 决策 |
|---|---|
| D1 | Review 只读消费 current Spec pair、Plan、Context/源码依据、设计、风险、实施边界、回滚和验收方案，不消费已完成 implementation diff 或 Verification evidence。 |
| D2 | 评审维度、severity、blocking 规则和 result 聚合由 YAML policy 定义。 |
| D3 | Prompt 产生结构化 finding candidate；确定性 lint 校验引用、severity、failure scenario、result 门禁和 bound revision。 |
| D4 | 机器权威是 versioned Review evidence；`review.md` 是可重建 Human projection，不作为 lifecycle evidence parser 输入。 |
| D5 | 未解决 `critical` 或 `major` 阻止 `approved`；事实、设计或验收 evidence 不可核验时返回 `blocked`。 |
| D6 | `approved` 绑定 current Spec/Plan revision/digest，并构成 Implementation authorization；任一受绑定工件变化后失效。 |
| D7 | Review 不修改代码、不执行 Gate、不计算 Verification verdict、不写 lifecycle transition。 |
| D8 | Implementation 发现 Plan 不足时返回 Planning/Specification；更新后必须重新 Review。 |
| D9 | finding 涉及项目意图时引用 Context ID；涉及当前实现依据时引用 path + revision/digest。 |
| D10 | `summary.md` 由 Human Acceptance `accepted` 后生成，不属于 Review。 |

## Policy

目标：`templates/.themis/core/policies/review.yaml`

至少声明：

- schema/version；
- dimensions：spec completeness、plan traceability、architecture/interfaces/state、security/data risk、scope lock、rollback、verification design、human acceptance design；
- severity：`critical | major | minor | suggestion`；
- result：`approved | changes_requested | blocked`；
- required finding fields；
- blocking severity 和 evidence 条件；
- Context/code reference requirements；
- approval binding 与 invalidation 规则；
- projection limits：首屏最大 finding 数、排序规则、完整 finding 不截断；
- override 只能收紧，不能允许 major/critical 绕过。

## Review evidence Protocol

目标：`templates/.themis/core/protocols/review/v1/review-schema.yaml`

至少记录：

- Review ID、project/workspace/source revision；
- bound Spec/Plan revision/digest；
- effective review policy digest；
- reviewed design/interface/state/security/data/scope/rollback/verification/acceptance inputs；
- findings map，稳定 `FND-*` ID；
- dimension、severity、summary、failure scenario；
- code path/revision/digest 或 Context ID；
- evidence refs、required change、disposition/status；
- blockers/evidence gaps；
- final result、reviewed_at、reviewer record；
- Implementation authorization 标志及其 bound digests；
- projection source/body digest。

Schema 必须拒绝缺失 failure scenario 的 critical/major finding、存在 unresolved major/critical 的 approved、未知 severity/result、越界引用和未绑定 current Spec/Plan 的 approved。

## Prompt

目标：`templates/.themis/core/templates/review-execution.md`

流程：

1. 校验 current `spec.yaml` 和 projection currency；Markdown 只供导航。
2. 读取 Plan scope、Task DAG、AC traceability、Context 与当前源码依据。
3. 检查需求完整性、设计与接口、状态和数据、安全、实施边界、回滚、Verification 方案和人工验收方案。
4. 每个 finding 给出可复现 failure scenario 和精确 evidence。
5. 项目意图声明引用 Context；当前实现依据引用源码 revision/digest。
6. 不可核验时输出 evidence gap/blocked，不凭信心批准。
7. 输出 Review evidence candidate，不直接写 `review.md` 或状态。

## Deterministic executor

目标：`templates/.themis/core/kernel/review/themis-review.sh`

这是生命周期领域 runner，因此与 `review/rules.md` 共置；跨领域 Context/Knowledge 数据服务仍位于 `core/bin/`。

### CLI

```text
themis-review.sh lint --workspace <path> --input <review.yaml>
themis-review.sh publish --workspace <path> --spec <id> --input <review.yaml>
themis-review.sh validate --workspace <path> --spec <id>
themis-review.sh render --workspace <path> --input <review.yaml> --output <review.md>
```

### `lint`

- 校验 Protocol、Spec/Plan refs 和 project/revision 一致；
- 校验 critical/major 有 failure scenario 和 evidence；
- 重新计算 result：存在 unresolved critical/major 时拒绝 approved；
- 事实或验收方案证据不足时只允许 blocked/changes_requested；
- 检查 Context ID/path/revision/digest 引用格式；
- approved 必须绑定 current Spec/Plan digest 并明确允许 Implementation。

### `publish`

- 在 staging 中 lint、render、计算 source/body digest；
- 写入 `workspace/evidence/review/<review-id>.yaml`；
- 生成 `workspace/specs/<spec-id>/review.md`；
- 使用备份、原子替换和 read-back，避免 evidence/projection half-pair；
- 重复同内容返回 unchanged；失败恢复旧 pair 或报告 recovery path。

### `validate`

- 重新 lint machine evidence 并 render expected body；
- 检测 source/body digest、Spec/Plan revision 和手改 drift；
- Spec/Plan 或绑定设计依据变化时返回 stale，不声称 approved current。

## `review.md` 投影

固定章节：

1. **Review Summary**：result、Implementation authorization、blockers、bound Spec/Plan。
2. **Priority Findings**：所有 critical/major，按 severity 和稳定 ID 排序。
3. **Evidence Gaps and Required Changes**：缺口及返工目标。
4. **Context and Code References**：CTX ID、path、revision/digest。
5. **Scope, Rollback, Verification and Acceptance Review**：实施与验收边界。
6. **All Findings**：完整 finding、scenario、evidence、required change、disposition。
7. **Traceability**：Spec/Plan/policy/source digests。

首屏限制只影响摘要展示，不得从 All Findings 删除任何 finding。renderer 不总结或推断 Prompt 语义。

## Workspace 边界

```text
读取:
  workspace/specs/<spec-id>/{spec.yaml,spec.md,plan.md}
  workspace/context/
  当前源码、配置与 Schema

写入:
  workspace/evidence/review/<review-id>.yaml
  workspace/specs/<spec-id>/review.md
```

executor 只处理一个显式 Workspace，不跨项目查找 Context 或 Evidence。

## 目标文件

### Core assets

- `templates/.themis/core/policies/review.yaml`
- `templates/.themis/core/protocols/review/v1/review-schema.yaml`
- `templates/.themis/core/templates/review-execution.md`
- `templates/.themis/core/templates/review.md` 或 projection protocol
- `templates/.themis/core/kernel/review/themis-review.sh`
- `templates/.themis/core/kernel/review/rules.md`
- `templates/.themis/core/kernel/orchestrator/rules.md`

### Checks/tests

- `bin/themis-template-check.sh`
- `tests/template-contract/test.sh`
- `tests/review-artifact/test.sh`
- `tests/init/test.sh`

### Design/release

- `docs/design/workflow.md`
- `docs/design/core/kernel/{orchestrator,planning,review}.md`
- `docs/design/core/{policies,protocols,templates}.md`
- `docs/design/workspace/overview.md`
- `docs/plan/68-review-enhancement/README.md`（添加 expanded/superseded 注记）
- `docs/plan/README.md`
- `CHANGES.md`
- Core/Bundle version files

## Task DAG

| Task | 内容 | 依赖 |
|---|---|---|
| REV-01 | Review policy 与 evidence Protocol | Planning machine contract |
| REV-02 | Review Prompt | REV-01 |
| REV-03 | lint/result/authorization aggregation | REV-01 |
| REV-04 | deterministic renderer/publisher/validator | REV-03 |
| REV-05 | rules、template checks、module tests | REV-02、REV-04 |
| REV-06 | 正式设计、版本和全量回归 | REV-05 |

## 验证矩阵

| 场景 | 预期 |
|---|---|
| complete Spec/Plan/design | evidence approved，review.md 稳定生成，Implementation authorized。 |
| unresolved critical/major | approved 被 lint 拒绝，结果 changes_requested。 |
| minor/suggestion only | 可按 policy approved，但 findings 完整保留。 |
| missing Context/code/design evidence | Review blocked，不能授权 Implementation。 |
| missing failure scenario | critical/major candidate 无效。 |
| missing Context ref | 涉及意图的 finding 无效或 blocked。 |
| stale code revision/digest | validate 返回 stale/blocked。 |
| Spec/Plan changed after Review | Review authorization invalidated，必须重新 Review。 |
| projection ordering | severity/ID 排序稳定，相同输入字节一致。 |
| summary limits | 首屏受限但 All Findings 无丢失。 |
| manual edit/drift | validate 检测，不能把手改 Markdown 当 machine evidence。 |
| interrupted publish | evidence/review.md 恢复旧 pair 或保留 recovery path。 |
| project isolation | 相邻 Workspace 与 Core 零变更。 |
| Init | 新 Core assets 可由 fresh Init 安装；已有 Workspace 不被覆盖。 |

## 确认门禁

用户确认本扩展索引前，不得创建 Review policy/protocol/executor/tests 或修改正式设计。Planning machine contract 尚未实现时，P6.8 不得通过 Markdown 或对话模拟 current Plan 输入。
