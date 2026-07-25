# P5 子模块：策略配置

## 覆盖任务

- 任务 1：编写 `specification.yaml`
- 任务 5：创建 `transitions.yaml`

## 设计依据

- **D1**：追问在 Spec-Validation 之前 → `specification.yaml` 独立于已有的结构校验逻辑
- **D2**：复杂度自适应 → `specification.yaml` 中的 `complexity` 段定义三元组判定规则
- **D6**：声明式规则 → `transitions.yaml` 不包含执行脚本，仅声明条件

## 目标文件 1：`specification.yaml`

**路径**：`templates/.themis/core/policies/specification.yaml`

### 字段定义

```yaml
# Themis 需求追问策略配置
# 由 P5 Requirement Questioning 安装，在 Draft → Specified 阶段生效。

questioning:
  # 复杂度判定规则
  complexity:
    low:
      # 同时满足以下全部条件判定为低复杂度
      max_files_touched: 1          # 最多涉及文件数
      max_new_apis: 0               # 无新增 API
      state_change: false           # 无状态变更（DB schema、配置持久化等）
    medium:
      max_files_touched: 8
      max_new_apis: 3
      state_change: true            # 允许状态变更
    # 超出 medium 阈值则为 high

  # 各复杂度的流程启用
  flow:
    low:
      step_0: minimal               # 精简版（1 轮 Why 追问）
      step_1: full                  # 完整范围评估
      step_2: skip                  # 跳过详细上下文收集
      step_3: minimal               # 精简版（1 个方案 + 1-2 个 AC）
      step_4: quick                 # 快速检查表（5 项）
    medium:
      step_0: full
      step_1: full
      step_2: full
      step_3: full
      step_4: focused               # 聚焦核心 AC
    high:
      step_0: full
      step_1: full
      step_2: full
      step_3: full
      step_4: comprehensive         # 全覆盖，允许多轮迭代

  # AC 分段确认策略
  ac_segmentation:
    max_acs_per_segment: 3          # 每段最多确认 3 个 AC
    require_explicit_approval: true # 每段必须用户明确确认

  # Option Zero 检查
  option_zero:
    enabled: true                   # 是否询问"能否不改代码解决"
    skip_when: []                   # 可配置跳过场景（如紧急修复）

# 对抗验证配置
adversarial_validation:
  enabled: true                     # 全局开关

  # 完整模式攻击维度
  dimensions:
    boundary_conditions: true       # 边界条件
    concurrency_and_race: true      # 并发与竞态
    state_transitions: true         # 状态转换
    security_and_permissions: true  # 权限与安全
    dependency_failures: true       # 依赖失败
    data_integrity: true            # 数据完整性

  # 快速模式（low 复杂度使用）
  quick_checklist:
    items:
      - id: "empty-input"
        question: "如果输入为空或缺失，系统应该做什么？"
      - id: "failure-state"
        question: "如果操作失败，用户如何感知？系统如何恢复？"
      - id: "concurrency"
        question: "如果两个用户同时执行此操作，会发生什么？"
      - id: "backward-compat"
        question: "此变更是否影响现有功能？如何验证？"
      - id: "rollback"
        question: "如果需要撤销此变更，路径是否清晰？"

  # 迭代控制
  max_iterations:
    quick: 3                        # 快速模式最多 3 轮
    focused: 5                      # 聚焦模式最多 5 轮
    comprehensive: 10               # 全覆盖模式最多 10 轮

  # 攻击结果处理
  resolution:
    - cover      # 修改 Spec 覆盖该场景
    - accept     # 接受为已知限制，记录在 Spec Limitation 段
    - defer      # 标记为后续版本处理

# 防绕过机制（Red Flags）
red_flags:
  - id: "too-simple"
    trigger: "Agent 声称'这个需求很简单'"
    constraint: "即使简单需求也必须通过 Step 4 快速检查表"
  - id: "skip-spec"
    trigger: "Agent 声称'不需要正式 Spec'"
    constraint: "所有变更必须有 Spec，最小 Spec 包含至少一个可验证 AC"
  - id: "code-first"
    trigger: "Agent 试图在看代码之前就开始编码"
    constraint: "先读 Context → 追问 → 再看代码。看代码前必须陈述要验证的假设"
  - id: "already-clear"
    trigger: "Agent 声称'用户已经说清楚了'"
    constraint: "必须主动提出至少一个用户可能未考虑的场景"
  - id: "try-one-line"
    trigger: "Agent 试图'先改一行试试'"
    constraint: "任何代码变更前必须通过 Step 0（意图确认）"
  - id: "obviously-best"
    trigger: "Agent 声称'这个方案显然是最好的'"
    constraint: "必须至少提出一个可替代方案，即使被否决"

# Spec 自检清单
self_check:
  structural:
    - no_placeholders               # 无 TODO、FIXME 等占位符
    - no_contradictions             # 无内部矛盾陈述
    - no_ambiguous_terms            # 无模糊术语（如"快""稳定"）
    - scope_explicit                # 范围明确
  adversarial:
    - assumptions_traceable         # 关键假设显式列出并标注验证方式
    - failure_scenarios_covered     # 每个 AC 考虑至少一个失败/边界场景
    - evidence_anchored             # 关键决策有数据、经验或约束支撑
    - attack_residue_recorded       # 对抗验证的已知限制记录在 Limitation 段
    - root_cause_aligned           # 方案解决根因而非表面需求
    - rollback_feasible            # 回滚路径清晰
```

## 目标文件 2：`transitions.yaml`

**路径**：`templates/.themis/core/policies/transitions.yaml`

### 字段定义

```yaml
# Themis 生命周期状态迁移门禁条件
# 由 P5 Requirement Questioning 安装 Draft → Specified 门禁。
# 其他迁移的门禁条件留待 P8 实现。

transitions:

  "Draft→Specified":
    description: "需求追问与对抗验证完成，用户批准 Spec"
    conditions:
      - id: "intent_confirmed"
        description: "Step 0 意图发现完成，根因已识别"
        required: true
      - id: "scope_assessed"
        description: "Step 1 范围评估完成，复杂度等级已确定"
        required: true
      - id: "context_gathered"
        description: "Step 2 上下文收集完成，假设清单和证据链已建立"
        required: true
        # medium 和 high 复杂度必须，low 可跳过
        skip_when: "complexity == 'low'"
      - id: "design_converged"
        description: "Step 3 设计收敛完成，Spec 草稿已写入 workspace/specs/<spec-id>/spec.md"
        required: true
      - id: "adversarial_validated"
        description: "Step 4 对抗验证完成，所有攻击场景已处理（覆盖、接受或延迟）"
        required: true
      - id: "spec_self_check_passed"
        description: "Spec 自检清单全部通过（结构 4 项 + 对抗 6 项）"
        required: true
      - id: "user_approved"
        description: "用户明确批准 Spec 内容与复杂度等级"
        required: true
        type: "human_gate"

  # 以下迁移门禁留待 P8 实现
  "Specified→Planned":
    status: "planned"
    description: "Planning 模块接管，AC → Task 覆盖检查"

  "Planned→Implemented":
    status: "planned"
    description: "Task 依赖满足，有明确完成标准"

  "Implemented→Verified":
    status: "planned"
    description: "所有 Task 有 durable evidence，Verification Gate 执行"

  "Verified→Reviewed":
    status: "planned"
    description: "Review 只读检查 Spec、Plan、Diff 与 Evidence"

  "Reviewed→Archived":
    status: "planned"
    description: "Outcome 与 Knowledge 处理完成"

# 对抗验证参数（在 transitions 读取）
adversarial_validation_params:
  unresolved_attack_block: true     # 存在未处理的攻击场景时阻止迁移
  allow_deferred_attacks: true      # 允许将非关键攻击标记为后续版本
  max_deferred_per_spec: 5          # 每个 Spec 最多延迟 5 个攻击场景
```

## 验证要求

- `specification.yaml` 通过 `yq eval '.'` 语法检查
- `transitions.yaml` 通过 `yq eval '.'` 语法检查
- `transitions.yaml` 中的 `Draft→Specified` 条件数量 = 7
- 两个 YAML 文件的字段名与其在 `specification/rules.md` 和 `spec-questioning.md` 中的引用一致
