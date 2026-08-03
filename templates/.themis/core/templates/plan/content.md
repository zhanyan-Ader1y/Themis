# Unified Plan Content 模板

> 本文件是 simple 与 full path 共用的单一 immutable execution contract 的人类语义部分。它必须与同一 revision 的 `record.md` 完整物化并重读；本文件单独不构成 authority。

## 执行绑定

- Lifecycle identity：
- Plan revision identity：
- Confirmed Intake assignment decision：
- Current Request revision and active claim revisions：
- Questioning round revision：
- Governed design constraint references：
- Grounding result reference：
- Complexity Assessment reference：
- Selected path：`simple` 或 `full`
- Profile：`lightweight` 或 `full`
- Full path required：`false` 或 `true`
- Temporary Specification handoff reference：`full path only` 或 `none`
- Implementation fact baseline and evidence：

## Current request、scope 与 core flow

### 目标与预期结果

### 核心链路

### 纳入范围

### 明确排除项

## Behavior、contracts 与 acceptance requirements

### 可观察行为

### 合同与不变量

### 验收要求

## Current implementation facts、assumptions 与 invariants

### 直接实现事实

| Assertion | Code/configuration/Schema/observed behavior evidence | Baseline | Applicability | Unknowns |
|---|---|---|---|---|

### 假设

### 不适用的深度设计领域

> Simple path only：每个压缩领域都必须提供为何不适用的直接证据；unknown 不能作为不适用证据。

## Technical approach、trade-offs 与 implementation design

### 方案

### 组件、边界与依赖

### 数据流与状态变化

### 接口与失败行为

### 关键取舍

## Impact、failure handling 与 interruption boundaries

### 预期实现 delta

### 回归面

### 失败处理

### 恢复或回滚

## Impl 与 Verification task breakdown

### Impl 任务

| Plan Task identity | Dependencies | Approved scope | Completion condition | Expected delta |
|---|---|---|---|---|

### Verification 任务

| Plan Task identity | Assertions | Method or command | Expected evidence | Completion condition |
|---|---|---|---|---|

Verify 固定包含 `themis-impl → independent themis-verification`。同一 Plan Task 的 Impl 与 Verification 使用 separate Invocations，但共享 current Approval、baseline、expected delta、Plan Task Execution Identity 与 failure budget。

## Authority 输入覆盖

| Source class | Source reference | Covered Plan sections | Treatment |
|---|---|---|---|
| User-confirmed Current Request claims |  |  | objective authority |
| Governed design constraints |  |  | constrains solution only |
| Implementation fact evidence |  |  | current implementation fact |
| Temporary Specification refinement |  |  | full-path non-authoritative refinement |

## Revision 边界

任何内容或 binding 变化都创建新的 immutable Plan pair。只有 complete materialization 与 reread 后才能更新 separate current pointer；Review、Approval 或 dialogue 永远不原地 patch 本文件。
