# P5.5 / impl-01 — 策略与持久工件契约

## 目标

定义 Knowledge Governance 的 YAML 权威策略，以及 candidate、review、action 三类持久工件。Prompt 不得独立重定义枚举、顺序、门禁或目标目录。

## `knowledge-governance.yaml`

根结构：

```yaml
knowledge_governance:
  schema: themis-knowledge-governance-policy/v1
  sources: []
  categories: []
  flows: {}
  duplicate_detection: {}
  review: {}
  approval: {}
  sensitivity: {}
  execution: {}
```

### 稳定来源 ID

```yaml
sources:
  - implementation_experience
  - verification_failure
  - review_finding
  - outcome
  - manual
```

每个非 `manual` 来源必须包含实际存在的 artifact/evidence 引用。上游模块尚未实现或工件不可访问时，候选提取必须报告 unavailable，不得根据对话补造来源。

`verification_failure` 只表示 Verification repair/retry 预算耗尽或已触发 escalation 的失败。retry window 内的单次 transient failure 不具备候选来源资格；candidate 必须引用达到 exhaustion/escalation 的具体 Verification Run。

### Context 分类

```yaml
categories:
  architecture: workspace/context/architecture
  domain: workspace/context/domain
  engineering: workspace/context/engineering
  decisions: workspace/context/decisions
  pitfalls: workspace/context/pitfalls
  glossary: workspace/context/glossary
  external: workspace/context/external
```

正式知识分类不允许写入 Behavior Map 或其他派生源码表示。

### 固定流程顺序

```yaml
flows:
  candidate_capture:
    - validate_source
    - extract_candidate
    - sensitivity_review
    - record_candidate
    - lint_candidate
  candidate_review:
    - load_candidate
    - exact_duplicate_check
    - semantic_duplicate_assessment
    - conflict_assessment
    - dimension_review
    - recommend_disposition
    - record_human_decision
    - apply_disposition
  context_deprecation:
    - load_context
    - validate_staleness_signal
    - dimension_review
    - record_human_decision
    - apply_disposition
```

### 去重边界

- 脚本对规范化 payload 摘要和精确来源引用执行确定性比较。
- Prompt 可标记 `potential_duplicate`、`potential_conflict`，但不得自行合并、覆盖或删除。
- v1 不提供 `0.8` 一类语义相似度阈值，因为没有确定的 embedding 模型、向量空间或索引实现。

### 审核维度

稳定维度 ID：

1. `factual_support`
2. `reuse_value`
3. `scope_and_clarity`
4. `duplicate_and_conflict`
5. `sensitivity_and_redaction`
6. `actionability`

候选处置：

- `promote`
- `reject`
- `revise`
- `merge_duplicate`

废弃处置：

- `retain`
- `archive`
- `revise`

所有最终处置均要求 `approval.mode: human`、`status: approved`、非空 `approved_by` 和合法 `approved_at`。

## Candidate 工件

模板：`core/templates/knowledge-candidate.md`

YAML front matter 最低字段：

```yaml
knowledge_candidate_schema: themis-knowledge-candidate/v1
id: ""
status: candidate
category: ""
source:
  type: ""
  artifacts: []
  evidence: []
project: ""
workspace_root: ""
source_revision: ""
confidence: null
content_digest: ""
digest_algorithm: git-hash-object/v1
sensitivity:
  reviewed: false
  disposition: pending
supersedes: null
created_at: ""
created_by: ""
```

固定正文标题：

- `## Summary`
- `## Proposed Knowledge`
- `## Provenance and Evidence`
- `## Existing Knowledge Comparison`
- `## Sensitivity and Redaction`
- `## Candidate Notes`

存储位置：

```text
workspace/knowledge/candidates/<candidate-id>.md
```

ID 由 record 脚本对规范化语义 payload 和 provenance 计算 Git object digest 后生成，格式为 `KNC-<full-digest>`。创建时间不参与摘要，保证同一候选重复记录时返回同一 ID。

## Review 工件

模板：`core/templates/knowledge-review-record.md`

最低字段：

```yaml
knowledge_review_schema: themis-knowledge-review/v1
id: ""
operation: candidate_review
candidate_id: ""
candidate_digest: ""
context_id: null
context_digest: null
evidence_refs: []
dimensions: {}
potential_duplicates: []
potential_conflicts: []
recommendation: pending
decision: pending
canonical_ref: null
target_category: null
approval:
  mode: human
  status: pending
  approved_by: null
  approved_at: null
created_at: ""
created_by: ""
project: ""
workspace_root: ""
source_revision: ""
```

`operation` 允许：

- `candidate_review`
- `context_deprecation`

review 必须绑定 candidate 或 context 的当前 digest。apply 时摘要不一致即视为 stale review，拒绝执行。

固定正文标题：

- `## Reviewed Material`
- `## Dimension Findings`
- `## Duplicate and Conflict Analysis`
- `## Recommendation`
- `## Final Decision and Rationale`
- `## Approval`

审核记录存储在：

```text
workspace/knowledge/reviews/<review-id>.md
```

## Action 工件

模板：`core/templates/knowledge-action-record.md`

Action 是脚本执行结果，不由 Prompt 伪造：

```yaml
knowledge_action_schema: themis-knowledge-action/v1
id: ""
review_id: ""
review_digest: ""
project: ""
workspace_root: ""
source_revision: ""
evidence_refs: []
decision: ""
status: applied
inputs: []
outputs: []
context_id: null
context_path: null
index_path: null
applied_at: ""
executor: themis-knowledge-apply/v1
```

存储规则：

- 所有 `promote`、`reject`、`revise`、`merge_duplicate`、`retain`、`archive` 的 `KAC-*` 记录统一写入 `workspace/knowledge/actions/<action-id>.md`；
- `reject` 可额外在 `workspace/knowledge/rejected/<action-id>.md` 保存拒绝投影或引用，但 candidate 与 canonical action 仍保留；
- `archive` 可额外在 `workspace/knowledge/archive/<action-id>/` 保存被废弃 Context 的完整历史快照或快照引用。

## Context 写入与 Catalog

`promote` 生成符合 `themis-context-item/v1` 的 L3 Item：

```text
workspace/context/<category>/<context-id>.md
```

Context ID 格式：`CTX-<candidate-digest>`。正式 Context 必须保留 candidate、review、action、来源 artifact/evidence 和内容摘要引用，并记录 P5.4 要求的 authority、Scope、status、digest、dependencies 和 supersession。

`workspace/context/catalog.yaml` 使用 P5.4 的 `themis-context-catalog/v1`，P5.5 不定义第二套 Schema。Apply 只能在同一原子处置内更新 L3 Item 与 Catalog，并执行 read-back 校验：

- Context ID、path、category、status 与 Catalog 一致；
- `content_digest` 与实际 L3 内容一致；
- candidate、review、action provenance 可解析；
- 依赖和 supersession 引用存在；
- 处置后 Context lint 与 Catalog lint 均通过；
- Context Item 保留 candidate/review/action 贯穿传递的 `project`、`workspace_root`、`source_revision` 与 `evidence_refs`，这些 provenance 字段不得为空。

脚本不得创建旧 `context-map.yaml`，也不得覆盖不可解析或 Schema 不兼容的 Catalog。

## Workspace Schema 边界

所有脚本都必须在路径规范化后拒绝任何位于 `--workspace` 根之外的输入或输出，包括 `..` 逃逸、外部绝对路径、符号链接穿越、相邻 Workspace 和 Core 路径。Apply 必须校验 action record 的 `inputs`、`outputs`、`context_path`、`index_path` 与全部 evidence refs 均位于当前 Workspace。

P5.5 消费 P5.4 最终确认且已存在的 Workspace Schema 与 Context Protocol。若目标 Workspace 不具备受支持的 Catalog/Signal layout，Apply 必须返回 `unsupported_workspace_layout` 或 `unavailable`，不得按需创建不兼容结构、改写 Schema 或转换旧 Context 数据。
