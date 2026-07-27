# Planning — 计划

## 职责边界

Planning 负责 Plan 和 Task 的结构、依赖、范围和可追踪性。它使用已批准 Spec 定义目标和 AC，使用 P5.4 Context Bundle 与当前代码确定项目事实，并可在 P6 可用时只读消费 Behavior Map 进行候选定位。

**Planning 关心“任务如何组织和证明完成”，不执行任务、不修改代码，也不拥有生命周期迁移。Spec/Plan 不能自证当前实现，Context Bundle 不完整或冲突时不得假装定位完成。**

## 核心能力

| 能力 | 说明 |
|---|---|
| Plan 结构定义 | 定义 Plan 文档的组成、Task 结构和依赖关系 |
| Task 模型 | 定义 Task 的粒度、类型、依赖和完成标准 |
| 可追踪性 | 确保 AC → Task → 实现 的双向追踪 |
| Plan 校验 | 校验 Plan 的完整性、一致性和可行性 |

## 子模块

### Plan-Model — Plan 结构模型

定义 Plan 的完整结构：

- **Plan 元数据**：关联 Spec ID、版本、创建时间
- **Task 列表**：分解后的可执行任务
- **依赖图**：Task 之间的依赖关系（DAG）
- **里程碑**：关键检查点
- **资源估算**：预计工作量和所需能力

**边界**：Plan-Model 是结构定义，实际创建 Plan 时使用 `core/templates/plan.md`。

### Task-Model — Task 模型

定义 Task 的结构和类型：

- **Task 类型**：实现、测试、重构、文档、部署
- **Task 粒度**：一个 Task 应在一次会话中可完成
- **Task 依赖**：前置 Task、后置 Task、并行 Task
- **完成标准**：每个 Task 有明确的 Definition of Done
- **关联 AC**：每个 Task 标注其覆盖的 AC

**边界**：Task-Model 定义 Task 的抽象结构，不定义具体 Task 的执行步骤。

### Change Localization — 变更定位（P6 规划中）

Planning 可只读消费 `current` Behavior Map，将已批准 AC 映射为建议性的变更范围：

```text
AC → Behavior Unit → Candidate File/Symbol → Task → Gate
```

每个候选位置必须记录角色（primary/supporting/test/config/schema）、理由、Anchor ID、source revision、置信度和未决区域。低置信度结果触发更广的只读源码调查，而不是更广的实施权限。

**边界**：定位结果是导航和 Plan 设计输入，不是独立项目事实或实现授权；它不能修改代码、自动创建或完成 Task、静默扩展 Plan 范围，也不能把 Behavior Map Anchor 当作 Verification verdict。只有 current B3 Anchor 可支持候选定位，关键当前实现仍需读取代码核验；Map 缺失、过期、未知或不支持时必须回退源码检查并记录该降级。P6 尚未实施。

### Traceability — 可追踪性

确保需求到实现的双向追踪：

```
AC → Task → 代码变更 → 验证结果
```

- 每个 AC 必须被至少一个 Task 覆盖
- 每个 Task 必须关联到至少一个 AC（或标记为工程任务）
- 代码变更通过 Git Adapter 关联到 Task
- 验证结果通过 Gate 关联回 AC

**边界**：Traceability 定义追踪规则和数据结构，实际追踪数据存储在 Workspace 中。

### Plan-Validation — Plan 校验

校验 Plan 的完整性和一致性：

- AC 覆盖率检查：所有 AC 是否被 Task 覆盖
- 依赖完整性检查：Task 依赖图是否无环、无缺失引用
- 粒度检查：Task 是否过大或过小
- 资源可行性检查：Task 是否超出当前能力范围

**边界**：Plan-Validation 只检查结构完整性，不评估 Plan 质量（那是 Review 的职责）。

## 与 Workspace 的交互

```
Planning 读取:
  workspace/specs/<spec-id>/spec.yaml # 已验证的权威目标、稳定 AC/Requirement/Contract/Invariant ID
  Specification validator JSON        # readiness 与 projection currency；不得重写校验逻辑
  workspace/specs/<spec-id>/plan.md   # 当前 Plan
  workspace/cache/resolved-context/   # P5.4 Context Bundle manifest
  workspace/context/                   # 被 Bundle 引用的正式知识
  当前代码、配置与 Schema              # 当前实现与目标位置
  workspace/context/architecture/behavior-map/ # P6 可选导航

Planning 展示:
  workspace/specs/<spec-id>/spec.md   # 仅供人类审阅，不得解析为机器输入

Planning 写入:
  （校验结果通过 Verification 的 Gate 机制记录）
```

## 输入/输出协议

- **输入**：通过 Spec Artifact Protocol 读取 Spec，通过 Plan Artifact Protocol 读取和解析 Plan
- **输出**：校验结果通过 Gate Result Protocol 传递