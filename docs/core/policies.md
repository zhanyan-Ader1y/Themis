# Policies — 策略层

## 职责边界

Policies 保存 Themis 的默认治理策略。这些是 Core 默认策略，不是具体项目规则。项目可以在 `workspace/policies/` 中扩展或收紧，但不能直接修改 Core 默认策略。

**Policies 是"默认规则书"，不是"最终执行规则"——有效策略 = Core 默认 + 项目覆盖。**

## 策略合并规则

```
Effective Policy = Core Default Policy + Project Policy Override
```

合并时遵循以下规则：

| 操作 | 规则 |
|---|---|
| 增加 Gate | 项目可以添加额外的 Gate |
| 收紧要求 | 项目可以提高阈值（如覆盖率从 80% → 90%） |
| 替换默认项 | 项目可以替换标记为 `overridable` 的默认值 |
| 修改协议语义 | **禁止**——项目不能修改 Gate 状态语义 |
| 重新定义失败 | **禁止**——项目不能把 `fail` 重新定义为 `pass` |

有效策略应在每次 Run 时写入 `workspace/runs/<run-id>/`，保证验证结果可解释。

## 策略文件

### lifecycle.yaml — 生命周期策略

定义 SDD 的标准生命周期：

```yaml
lifecycle:
  stages:
    - draft
    - specified
    - planned
    - implemented
    - verified
    - reviewed
    - archived
  entry_criteria:     # 每个阶段的进入条件
  exit_criteria:      # 每个阶段的退出条件
  default_stage: draft
```

### transitions.yaml — 状态迁移策略

定义合法的状态迁移：

```yaml
transitions:
  - from: draft
    to: [specified]
  - from: specified
    to: [planned, draft]      # 可回退到 draft
  - from: planned
    to: [implemented, specified]
  - from: implemented
    to: [verified, planned]
  - from: verified
    to: [reviewed, implemented]
  - from: reviewed
    to: [archived, implemented]
  forbidden:                  # 禁止的迁移
    - from: draft
      to: verified            # 不能跳过中间阶段
```

### artifact-rules.yaml — 工件规则

定义工件的约束规则：

```yaml
artifact_rules:
  spec:
    required_fields: [id, title, status, created_at, author]
    min_ac_count: 1
    max_ac_count: 50
    ac_format: "given-when-then"
  plan:
    required_fields: [spec_id, tasks, created_at]
    ac_coverage_required: true    # 每个 AC 必须被 Task 覆盖
    max_task_granularity: "1 session"
```

### verification.yaml — 验证策略

定义 Gate 的默认配置：

```yaml
verification:
  gates:
    - name: lint
      type: blocking
      adapter: command
      command: "${project.lint_command}"
    - name: build
      type: blocking
      adapter: command
      command: "${project.build_command}"
    - name: test
      type: blocking
      adapter: testing
      command: "${project.test_command}"
      coverage_threshold: 80%
    - name: schema
      type: conditional
      condition: "schema_files_changed"
      adapter: schema
    - name: review
      type: blocking
      adapter: agent
  parallel_gates: [lint, schema]    # 可并行执行的 Gate
  sequential_gates: [build, test]   # 必须串行执行的 Gate
```

### failure-categories.yaml — 失败分类

定义失败类型和恢复策略：

```yaml
failure_categories:
  transient:
    description: "环境问题、网络超时、资源竞争"
    recovery: auto_retry
    max_retries: 3
  code_failure:
    description: "编译错误、测试失败、Lint 违规"
    recovery: manual_fix
  config_failure:
    description: "环境变量缺失、权限不足、配置错误"
    recovery: manual_intervention
  policy_conflict:
    description: "Gate 规则本身矛盾"
    recovery: human_decision
```

### knowledge-governance.yaml — 知识治理策略

定义知识生命周期规则：

```yaml
knowledge_governance:
  candidate:
    sources: [spec_execution, review, verification_failure, outcome_analysis]
    min_confidence: 0.6
  deduplication:
    similarity_threshold: 0.8
    compare_against: [context, candidates]
  review:
    required_reviewers: 1
    decision_options: [promote, reject, revise]
  promotion:
    target_directories:
      architecture: workspace/context/architecture/
      domain: workspace/context/domain/
      pitfalls: workspace/context/pitfalls/
      decisions: workspace/context/decisions/
  deprecation:
    staleness_days: 90
    require_review: true
```

## 与 Workspace 的交互

```
Policies 读取:
  （无——Policies 是被读取的配置源）

Policies 被读取:
  Orchestrator 读取 lifecycle.yaml + transitions.yaml
  Verification 读取 verification.yaml + failure-categories.yaml
  Review 读取 review.yaml
  Knowledge 读取 knowledge-governance.yaml
  Specification 读取 artifact-rules.yaml

Workspace 覆盖:
  workspace/policies/ 中的同名文件覆盖 Core 默认值
```

## 策略加载顺序

```
1. 加载 core/policies/ 中的默认策略
2. 加载 workspace/policies/ 中的项目策略
3. 合并生成 Effective Policy
4. 在每次 Run 时写入 Effective Policy 快照
```