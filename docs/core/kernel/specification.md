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

### Spec-Model — Spec 双视图结构模型

新 Spec 从 `core/templates/spec.yaml` 创建临时 candidate，使用 `themis-spec/v2`。活动实例位于 `workspace/specs/<spec-id>/`：`spec.yaml` 是唯一权威语义源，`spec.md` 是确定性生成、可丢弃并可重建的人类审阅投影。

结构化真源保存意图、范围、Context/Evidence、方案、需求、接口、契约、不变量、Given/When/Then AC、对抗发现、风险、回滚、图与批准记录。对象以 `REQ-*`、`DEC-*`、`IFC-*`、`CTR-*`、`INV-*`、`AC-*`、`ADV-*`、`RSK-*`、`DGM-*` 等稳定 ID 建模；关系使用 ID 引用，不使用数组位置或 Markdown 标题。

**边界**：Artifact v2 和 Spec v2 是 Themis 首次投入使用时的原生契约；Core Upgrade 不覆盖已创建的项目 Spec，也不提供预发布格式兼容层。

### Spec-Validation — 确定性校验与发布

`core/kernel/specification/themis-spec.sh` 提供 `validate`、`render` 和 `publish`：

- `validate` 区分 Draft validity 与 Specified readiness，检查结构、类型、枚举、ID、引用、追踪关系和 Human 投影 OID；
- `render` 从有效 `spec.yaml` 确定性生成固定顺序的 `spec.md`；
- `publish` 在 staging 中执行 candidate validate → render → pair validate，再事务性替换 canonical pair；备份完成但替换未开始的失败保持 canonical pair 原样，首个 rename 后的失败或 HUP/INT/TERM 自动恢复旧 pair，恢复失败则保留并报告完整 recovery path，新建失败不留下半套工件。

Readiness 使用 `spec_intent_complete`、`spec_scope_complexity_confirmed`、`spec_context_complete`、`spec_design_acceptance_complete`、`spec_adversarial_resolved`、`spec_self_check_passed`、`spec_user_approval_recorded` 和 `spec_projection_current` 八个稳定检查 ID。P5 可生成 `ready: true` 的校验报告，但只有 P8 才能持久化 `draft → specified` 状态迁移。

**边界**：结构检查不替代需求质量、根因或批准含义的语义判断；`spec.md` 永远不是机器证据，也不能反向恢复 YAML。

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

low 使用精简 Step 0/3 和五项快速对抗检查；medium 聚焦核心 AC；high 覆盖全部 AC 并可多轮迭代。有效攻击以 `ADV-*` 写入 `spec.yaml`，`cover` 引用实际解决对象，`accept`/`defer` 引用 `RSK-*`；critical 安全、权限或数据完整性风险不能只以延期处置。

用户必须明确确认复杂度和最终 Draft。`core/policies/transitions.yaml` 声明 `draft_to_specified` 所需的八个 validator check ID；P5 通过 publisher 保存双视图并保持 `status: draft`。未来 P8 的确定性状态执行器复用同一 validator JSON，评估条件并写入机器状态迁移，不重写 Spec 校验逻辑。

**边界**：需求追问负责帮助用户说清楚“做什么、为什么、如何验收”；它不写代码、不安排 Task、不伪造 Gate 或状态转换。

## 与 Workspace 的交互

```text
Specification 读取:
  workspace/context/                    # 已确认的项目事实和约束
  workspace/specs/<spec-id>/spec.yaml  # 唯一权威语义源
  workspace/specs/<spec-id>/spec.md    # 仅供人类审阅与漂移校验

Specification 写入:
  临时 spec.yaml candidate              # Prompt 只直接修改 candidate
  workspace/specs/<spec-id>/spec.yaml  # 仅由 themis-spec.sh publish 写入
  workspace/specs/<spec-id>/spec.md    # 同一 publish 事务生成
```

P5 不写 `workspace/state/transitions/`，不保存每轮会话过程，也不直接写入正式 Context。

## 输入/输出协议

- **输入**：用户目标、已确认 Context、已有相关 Spec，以及仅为验证明确假设所需的最小代码事实。
- **输出**：具有稳定 AC、批准与攻击处置记录的 Draft Spec；尚无 P8 时，不输出机器状态迁移或通过声明。
