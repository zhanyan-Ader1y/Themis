# Themis Specification

## 职责边界

Specification 定义项目变更必须达成什么、为什么需要、批准范围以及什么证据能证明验收。它拥有意图和 Acceptance Criteria，不拥有实施设计、任务排序或机器生命周期状态。

## 核心能力

| 能力 | 说明 |
|---|---|
| Spec-Model | 定义 Spec 的稳定结构、元数据和可追踪关系。 |
| Spec-Validation | 检查结构完整性、引用、AC 可验证性和与 Plan 的一致性。 |
| Acceptance-Criteria | 定义 Given-When-Then 或等价的可验证行为边界。 |
| Requirement-Questioning | 通过 Step 0–4 追问、对抗验证和人工批准，将模糊请求收敛为 Draft Spec。 |

## 子模块

### Spec-Model — Spec 结构模型

新 Spec 从 `core/templates/spec.md` 创建，使用 `themis-spec/v1` 前置元数据。实例位于 `workspace/specs/<spec-id>/spec.md`，包含意图、范围、约束、证据、方案、需求、AC、假设、攻击结果、限制、回滚和批准记录。

**边界**：模板提供初始结构；Core 升级不会覆盖已创建的项目 Spec。P5 不迁移历史 Spec。

### Spec-Validation — Spec 校验

Spec-Validation 检查必填信息、引用完整性、AC 可验证性和 Plan 覆盖关系。P5 的模板检查器只校验 Core 模板结构；确定性项目 Spec lint 留待 P8。

**边界**：结构检查不替代对需求质量、根因或用户批准含义的判断。

### Acceptance-Criteria — 验收标准

每个 AC 应描述一个可验证行为，采用 Given-When-Then 或等价结构，并用稳定 `AC-xxx` 标识。每个 AC 最终必须由至少一个 Task 和 Gate 追踪。

**边界**：AC 定义验证什么，不定义如何实施或执行验证。

### Requirement-Questioning — 需求追问

P5 在 Draft 阶段按 `core/policies/specification.yaml` 执行五阶段流程：

```text
Step 0 — Intent Discovery
  Five Whys，区分表面方案与根因。
Step 1 — Scope Assessment
  多子系统拆分、Pre-mortem、假设与复杂度确认。
Step 2 — Context Gathering
  medium/high 收集目标、约束、量化标准、Option Zero 和证据。
Step 3 — Design Convergence
  方案取舍、分段 AC 确认、Draft 写入与自检。
Step 4 — Adversarial Validation
  攻击者视角扫描边界、并发、状态、安全、依赖和完整性风险。
```

low 使用精简 Step 0/3 和五项快速对抗检查；medium 聚焦核心 AC；high 覆盖全部 AC 并可多轮迭代。有效攻击以 `cover`、`accept` 或 `defer` 写入 `spec.md`；critical 安全、权限或数据完整性风险不能只以延期处置。

用户必须明确确认复杂度和最终 Draft。`core/policies/transitions.yaml` 声明 `draft_to_specified` 所需的七项证据，但 P5 只记录这些证据并保持 `status: draft`。未来 P8 的确定性执行器才可评估条件并写入机器状态迁移。

**边界**：需求追问负责帮助用户说清楚“做什么、为什么、如何验收”；它不写代码、不安排 Task、不伪造 Gate 或状态转换。

## 与 Workspace 的交互

```text
Specification 读取:
  workspace/context/                   # 已确认的项目事实和约束
  workspace/specs/<spec-id>/spec.md   # 已有或当前 Draft Spec

Specification 写入:
  workspace/specs/<spec-id>/spec.md   # Step 3 后创建/更新 Draft，Step 4 写入攻击和批准证据
```

P5 不写 `workspace/state/transitions/`，不保存每轮会话过程，也不直接写入正式 Context。

## 输入/输出协议

- **输入**：用户目标、已确认 Context、已有相关 Spec，以及仅为验证明确假设所需的最小代码事实。
- **输出**：具有稳定 AC、批准与攻击处置记录的 Draft Spec；尚无 P8 时，不输出机器状态迁移或通过声明。
