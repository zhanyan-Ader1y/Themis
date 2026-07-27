# P5.9 — Implementation Enhancement（实施增强）

**优先级**：P5.9
**依赖**：[P1 Template Contract](../10-template-contract/README.md)、[P5 Requirement Questioning](../50-requirement-questioning/README.md)、[P5.8 Planning Enhancement](../58-planning-enhancement/README.md)
**状态**：设计中

## 背景

当前 Implementation 没有独立的 kernel 模块。Orchestrator 中只有三条规则：

> "Implementation is allowed only for work represented by an approved Spec and the current Plan. Implement one bounded planned task at a time. Do not mix unrelated refactors or silently expand scope."

这导致以下问题：

| 问题 | 后果 |
|---|---|
| 无任务选择策略 | Agent 可能跳过依赖、先做容易的、或同时改多个任务 |
| 无范围锁定机制 | 实施中发现的"顺便修"会悄然扩大范围 |
| 无证据要求 | 完成后无法判断 Task 是否真的满足完成标准 |
| 无进度评估 | 不知道何时进入下一个 Task、何时返回 Planning |
| 无回滚策略 | 任务中途发现方向错误时无明确的停止和清理协议 |

P5.9 将 Implementation 从 Orchestrator 的三句话扩展为独立的 kernel 模块，遵循与 P5 相同的三层模型：YAML 声明策略，Prompt 定义执行协议，Shell 脚本处理确定性操作。

## 目标

为 Implementation 阶段建立结构化执行协议：

```text
Planned
  → I1 选择下一个依赖已满足的 Task
  → I2 加载当前 Task 的 AC、约束与代码
  → I3 在限定范围内实施变更
  → I4 范围检查：变更是否超出 Plan？
  → I5 记录 Task evidence
  → I6 进度评估：下一个 Task？返回 Planning？返回 Specification？
  → Implemented（全部 Task 完成 + 证据齐全）
```

## 三层执行模型

| 层 | P5.9 职责 |
|---|---|
| YAML 策略 | 声明任务选择模式、范围锁定规则、证据最低要求、重试上限、范围扩张与 Plan 不足的处置策略 |
| Prompt 模板 | 定义 I1–I6 执行协议、范围自检清单、证据记录格式、Red Flags 防绕过规则 |
| Shell 脚本 | 确定性操作：从 Plan 解析当前任务状态、对比变更文件与 Plan 声明的范围、生成 Task evidence 骨架 |

## 设计决策

### D1：Implementation 不拥有 Spec 或 Plan 的修改权

Implementation 是**执行者**，不是设计者。发现范围不足时，它必须停止并路由回 Specification 或 Planning，而不是自行修改 Spec 或 Plan。

这与 Orchestrator 的现有规则一致：

> "Return to Specification or Planning when requested work exceeds approved scope."

P5.9 将此从 Orchestrator 的一句话扩展为可操作的检测和上报协议。

### D2：Task 是最小执行单元

一个 Task = 一次Implementation会话的边界。不允许跨 Task 实施，不允许"顺便"修不相关的文件。

Task 的定义由 P5.8 Planning Enhancement 提供。P5.9 依赖 P5.8 的 Task 模型（ID、AC 覆盖、依赖、完成标准、预期变更文件），但若 P5.8 尚未实施，P5.9 的回退模式是从当前 `plan.md` 的 Markdown 结构解析 Task。

### D3：范围检查是连续门禁

范围检查不是在 Task 结束后一次性执行——它是在实施过程中持续生效的。每修改一个文件前，agent 必须确认该文件在 Plan 声明的变更范围内。

```yaml
# implementation.yaml 中的声明
scope_enforcement:
  mode: continuous         # 每次文件修改前检查
  allowlist_source: plan   # 从 plan.md 的 Task 声明中提取
  on_violation: stop       # 发现范围外文件时立即停止并报告
```

### D4：证据必须可追溯

每个 Task 完成后必须记录：

| 证据字段 | 含义 |
|---|---|
| `task_id` | 对应 Plan 中的 Task 标识 |
| `acs_covered` | 覆盖的 Acceptance Criteria |
| `files_changed` | 修改的文件列表 |
| `change_summary` | 变更摘要 |
| `scope_deviations` | 范围偏差（如有，必须解释并链接到 Spec 修订） |
| `completion_evidence` | 满足完成标准的证据（测试输出、lint 结果等） |

证据在 P8 之前由 agent 写入 `workspace/evidence/`；P8 之后由 `themis-task-evidence` 脚本生成。

### D5：Implementation 不执行 Verification

Implementation 只记录它做了什么。Gate 执行（lint、build、test）属于 Verification。Implementation 可以**建议**运行哪些 Gate，但不能声称 Gate 已通过。

### D6：范围扩张的处置是结构化的，不是"先斩后奏"

```
检测到范围扩张
  → 立即停止当前 Task
  → 分类：
      A. Plan 不足但在 Spec 内 → 返回 Planning 补充 Task
      B. 超出 Spec → 返回 Specification 修订 Spec
      C. 纯粹是代码质量改进（无行为变更，零风险）→ 记录但允许
  → 不得在未路由的情况下"先改了再说"
```

## 新增 Core 资产

| 文件 | 类型 | 说明 |
|---|---|---|
| `core/kernel/implementation/rules.md` | 规则 | 职责、输入、输出、边界、MUST Read 指令 |
| `core/policies/implementation.yaml` | 策略 | 任务选择模式、范围锁定、证据要求、重试、扩张处置 |
| `core/templates/implementation-protocol.md` | Prompt | I1–I6 执行协议、范围自检、证据模板、Red Flags |
| `bin/themis-task-evidence.sh` | 脚本 | 确定性操作：验证 Plan 结构、解析 Task 状态、生成 evidence 骨架 |

## Orchestrator 变更

Orchestrator 的 Domain Boundaries 段追加 `@import ../implementation/rules.md`，使 Implementation 成为独立可路由模块。

当前 Orchestrator 的 Implementation 段（"Implementation is allowed only for..."）保留为简短摘要，详细协议由 `implementation/rules.md` 承载。

## 复杂性模型

P5.9 不分 low/medium/high——Implementation 的门禁是统一的。复杂度自适应属于 Specification（P5）和 Planning（P5.8）的职责，Implementation 只执行已规划好的 Task。

## 防绕过机制（Red Flags）

| Agent 的想法 | P5.9 约束 |
|---|---|
| "这个改动很小，不需要记录证据。" | 每个 Task 必须记录至少 `task_id`、`acs_covered`、`files_changed` |
| "顺便修一下这里的格式问题。" | 范围外文件触发连续检查→停止→分类 |
| "这个 Task 做完大半了，差一点就行。" | Task 完成标准由 Plan 定义，不是 agent 的主观判断 |
| "先实现再补 Plan。" | 无 Plan 不实施；Plan 不足先返回 Planning |
| "我知道 Spec 没写这个，但显然需要。" | 超出 Spec → 停止 → 返回 Specification |
| "同时改这两个 Task 效率更高。" | 每次只实施一个 Task；跨 Task 混合会导致证据链断裂 |

## 与 P5.8 的协调

P5.8 (Planning Enhancement) 定义了 Task 的正式模型（ID、DAG、依赖、完成标准、预期变更文件）。P5.9 消费该模型。

若 P5.9 在 P5.8 之前实施：
- Task 解析回退到当前 `plan.md` 的 Markdown 结构
- 依赖 DAG 回退到 Plan 中的顺序列表
- 完成标准回退到 AC 覆盖检查

若 P5.8 在 P5.9 之前实施：
- Task 模型直接读取 YAML/结构化格式
- 依赖 DAG 可被脚本确定性解析
- 完成标准可与 Verification Gate 联动

## 边界

- 不修改 Spec 或 Plan。
- 不执行 lint、build、test 命令或声称 Gate 已通过。
- 不跳过 Verification——Implementation 完成 != 质量已验证。
- 不混合无关重构——C 类偏差必须零风险且被记录。
- 不在 Plan 缺失或不完整时开始实施。
- Implementation 的"完成"只意味着所有 Task 有证据——`Implemented` 状态迁移仍需 P8。
