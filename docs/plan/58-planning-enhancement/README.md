# P5.8 — Planning Enhancement（计划增强）

**优先级**：P5.8（在 P5 需求追问之后、P6 Behavior Map 之前）
**依赖**：[P1 Template Contract](../10-template-contract/README.md)、[P5 Requirement Questioning](../50-requirement-questioning/README.md)
**状态**：待用户主动发起

## 背景

Planning 是 SDD 生命周期中 Specified → Planned 的关键阶段，负责将已批准 Spec 分解为可执行的 Task、建立依赖 DAG、确保 AC 全覆盖和可追踪性。当前基线：

- `planning/rules.md` 定义了模块边界，但内容为基线占位
- 无 Plan 策略配置文件（Task 类型定义、粒度规则、DoD 模板）
- 无 Plan 校验 Prompt 模板
- 无 Traceability 的标准化模板（AC → Task → Code → Gate）
- Behavior Map 定位完成后需要一个结构化的 Plan 生成流程

P5 需求追问确保"需求说清楚了"，Planning 应确保"任务拆得对、拆得完"。两者串行衔接。

## 目标

将 Planning 从文档化的理论模型落地为可执行的能力层：

1. 定义 Plan/Task 策略配置（Task 类型、粒度、依赖约束、DoD 模板）
2. 编写 Plan 生成 Prompt 模板（从 Spec + Context 生成 Plan）
3. 编写 Plan 校验 Prompt 模板（AC 覆盖、依赖完整性、粒度、可行性）
4. 更新 `planning/rules.md` 使其不再为占位状态
5. 同步更新 WIKI 文档

## 核心设计

### Task 类型

| 类型 | 说明 | 默认 DoD |
|---|---|---|
| implementation | 功能实现 | 代码变更 + 单元测试 + Gate 通过证据 |
| testing | 测试编写 | 测试代码 + 测试通过输出 |
| refactoring | 重构 | 等价性证据 + 已有测试仍通过 |
| documentation | 文档 | 文档文件变更 + 链接有效 |
| deployment | 部署 | 部署日志 + 冒烟测试通过 |
| engineering | 工程任务（CI、依赖更新等） | 管道通过证据 |

### Traceability 模型

```
AC → Task → 代码位置 (Behavior Map) → 代码变更
  → Verification Gate → 证据 → 通过/失败
```

### Plan 校验维度

| 维度 | 检查内容 |
|---|---|
| AC 覆盖 | 每个 AC 是否被至少一个 Task 覆盖 |
| 依赖完整性 | Task DAG 无环、无缺失引用 |
| 粒度检查 | Task 是否可在单次会话中完成 |
| 证据要求 | 每个 Task 的 DoD 和证据要求是否明确 |
| 可行性 | Task 是否超出当前能力范围 |

## 目标文件

| # | 文件 | 操作 | 说明 |
|---|---|---|---|
| 1 | `templates/.themis/core/policies/planning.yaml` | 新建 | Task 类型、粒度规则、DoD 模板、校验规则 |
| 2 | `templates/.themis/core/templates/plan-generation.md` | 新建 | Plan 生成 Prompt（Spec → Task 拆分 → 依赖 DAG） |
| 3 | `templates/.themis/core/templates/plan-validation.md` | 新建 | Plan 校验 Prompt（AC 覆盖、依赖、粒度、可行性） |
| 4 | `templates/.themis/core/kernel/planning/rules.md` | 更新 | 从占位内容更新为完整计划规则 |
| 5 | `docs/design/core/kernel/planning.md` | 更新 | 同步 WIKI |

## 验收条件

- `planning.yaml` 定义 ≥4 种 Task 类型，每种有 DoD 模板
- `plan-generation.md` 含完整的 Spec → Task 拆分逻辑和依赖构建规则
- `plan-validation.md` 含 5 维度的校验检查表
- `planning/rules.md` 不再包含占位内容
- Traceability 模型可追踪从 AC 到 Gate 的完整链路

## 非范围

- 不实现确定性 Shell 脚本（`themis-plan-lint.sh` 等留待 P8）
- 不修改 Workspace 目录结构（已由 P1 定义）
- 不实现 Behavior Map 定位（属于 P6）

## 风险与回滚

- **风险**：Plan 粒度过于死板，不适合探索性开发 → **缓解**：允许 `exploration` 类型的轻量 Task
- **回滚**：移除新增文件，恢复 rules.md 到基线
