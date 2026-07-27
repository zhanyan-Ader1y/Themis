# P5 — Requirement Questioning（需求追问）

**优先级**：P5
**依赖**：[P1 Template Contract](../10-template-contract/README.md)、[P2 Top-level Guidance](../20-top-level-guidance/README.md)
**状态**：已完成；P8 确定性状态执行器待实施

## 背景

AI 编码 Agent 容易从模糊请求直接进入实现。P5 在 Specification 阶段提供结构化需求收敛：先理解真实意图，再确认范围、约束、可验证的验收标准和风险，最后由用户明确批准 Draft Spec。

## 目标

将 Five Whys、苏格拉底式提问、Pre-mortem、superpowers 的协作收敛，以及 grill-me 式对抗验证整合为 **五阶段（Step 0–4）** Requirement Questioning 流程：

```text
Draft
  → Step 0 Intent Discovery
  → Step 1 Scope Assessment
  → Step 2 Context Gathering（low 可跳过详细收集）
  → Step 3 Design Convergence
  → Step 4 Adversarial Validation
  → 用户明确批准证据
  → P8 将来记录 Specified 状态迁移
```

P5 创建并完善 Draft Spec，记录可复核的意图、范围、AC、假设、证据、攻击处置、限制、回滚与批准信息。持久格式固定为 `workspace/specs/<spec-id>/spec.yaml` 权威源与 `spec.md` Human 投影。P5 不写入机器生命周期状态，也不声称已执行 `draft → specified`；该确定性职责属于未来 P8。

## 三层执行模型

| 层 | P5 职责 |
|---|---|
| YAML Policy | 复杂度阈值、各阶段模式、AC 分段、攻击维度、迭代与延期限制、声明式门禁条件。 |
| Prompt | 一次一问、Five Whys、方案取舍、Pre-mortem、对抗场景、用户确认和语义判断。 |
| Script | `themis-spec.sh` 负责 Draft/readiness 校验、确定性渲染、漂移检测和事务式 pair 发布；模板检查器保护安装契约，不判断需求质量或批准语义。 |

## 核心流程

### Step 0 — Intent Discovery

通过比例适当的 Why 追问识别根因，区分用户提出的方案与真正需要的结果。若两者不一致，给出替代路径并记录核心意图与根因。

### Step 1 — Scope Assessment

识别多子系统需求并先拆解为一个可收敛子问题；执行 Pre-mortem，记录风险和关键假设。按政策确定 low、medium 或 high 复杂度，并要求用户确认。

### Step 2 — Context Gathering

仅对 medium/high 完整执行：收集目标、约束、量化成功标准、Option Zero、证据和假设验证方式。low 仍需在 Draft 中记录影响 AC 的关键约束。

### Step 3 — Design Convergence

提出方案与取舍，分段确认每组不超过三个 AC，创建或更新 Draft Spec，并进行结构性和对抗性自检。

### Step 4 — Adversarial Validation

Agent 明确切换到攻击者视角。low 使用五项快速检查；medium 聚焦核心 AC；high 覆盖全部 AC 和六个攻击维度。每个有效发现都以 `cover`、`accept` 或 `defer` 处置；critical 安全、权限或数据完整性风险不能只靠 `defer` 放行。

达到迭代上限仍有未决发现时，Spec 必须保持 Draft。

## 防绕过规则

- 所有行为变更均需要 Spec；简单变更使用最小 Spec 和快速检查，而不是跳过。
- 先读取 Context、澄清意图，再仅为验证明确假设进行最小只读代码检查。
- 未经用户明确批准，Draft 不得被描述为已批准。
- P5 只能记录批准证据；没有 P8 确定性执行器时，不得声明生命周期迁移已记录。

## 实现位置

- `core/policies/specification.yaml`：复杂度、对抗验证、Red Flags 与自检配置
- `core/policies/transitions.yaml`：唯一的 `draft_to_specified` 声明式证据契约
- `core/templates/spec.yaml`：P5.2 后的权威 Draft candidate 模板；`spec.md` 由 executor 生成
- `core/protocols/artifact/v2/`：Spec v2 与 Human projection 契约
- `core/kernel/specification/themis-spec.sh`：Draft/readiness 校验、渲染和 pair 发布
- `core/templates/spec-questioning.md`：五阶段 Prompt
- `core/templates/spec-adversarial-checklist.md`：快速检查和六维攻击场景库
- `core/kernel/specification/rules.md`：简洁路由与边界
- `bin/themis-template-check.sh`：确定性模板结构校验

## 非范围

- 不实现多轮会话持久化。
- 不实现命令、Skill、领域 Agent 或需求质量判断脚本。
- P5 初始版本不实现确定性状态转换或 `workspace/state/transitions/` 写入；P5.2 已实现单 Spec lint/render/publish，但 P8 仍拥有状态迁移。
- Artifact v2 与 Spec v2 是首次投入使用的原生契约；本阶段没有历史 Spec 转换或兼容模式。

## 验收条件

- Step 0–4 均由 Prompt 明确定义，low 仍执行五项快速对抗检查。
- 新建 Draft Spec 使用稳定的 `themis-spec/v2` 权威 YAML 契约，并通过确定性 Human 投影保留完整审批、攻击和限制审阅信息。
- `draft_to_specified` 声明八个稳定 validator check ID，且 policy 与 Prompt 不暗示 P5 已执行机器状态迁移。
- 模板检查器拒绝缺失、损坏或不完整的 P5 策略、模板及门禁结构。
- Specification 常驻 rules 保持在 50 行以内；详细行为位于按需 Prompt 模板。

详细实现设计见 [impl.md](impl.md) 和各子模块段落。
