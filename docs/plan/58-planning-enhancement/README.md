# P5.8 — Planning Enhancement（计划增强）

**优先级**：P5.8
**依赖**：[P1 Template Contract](../10-template-contract/README.md)、[P5 Requirement Questioning](../50-requirement-questioning/README.md)、[P5.4 Context Restructure](../54-context-restructure/README.md)
**状态**：待用户主动发起

## 背景

Planning 是 SDD 生命周期中 Specified → Planned 的关键阶段，负责将已批准 Spec 分解为可执行 Task、建立依赖 DAG、锁定实施范围，并确保 AC、代码位置、Gate 与人工验收可追踪。当前基线只有简要 `planning/rules.md`，尚无 Plan policy、Prompt、机器协议或确定性校验器。

Planning 读取受治理 Context，并直接检查当前源码、配置与 Schema；它不依赖 Behavior Map 或第二套源码表示。

## 目标

1. 定义 Plan/Task 策略配置：Task 类型、粒度、依赖、scope lock、DoD 与证据模板。
2. 生成 `plan.md`，记录 current Spec、Context 和源码 revision/digest。
3. 建立 `AC → Task → code location → Gate → human acceptance` 追踪链。
4. 校验 AC 覆盖、DAG、代码依据、实施边界、回滚与验收方案。
5. 为前置 Review 提供完整输入，但不自行授权 Implementation。

## 核心设计

### Task 类型

| 类型 | 说明 | 默认 DoD |
|---|---|---|
| implementation | 功能实现 | 代码变更、Task evidence 与指定 Gate |
| testing | 测试编写 | 测试代码、覆盖目标与指定 Gate |
| refactoring | 受范围约束的重构 | 等价性要求、变更边界与指定 Gate |
| documentation | 文档 | 文档变更、链接/契约校验 |
| deployment | 部署 | 部署步骤、回滚与人工验收 |
| engineering | CI、依赖或工程配置 | 配置变更、风险与指定 Gate |
| exploration | 只读调查 | 问题、证据、结论和下一步；不授权项目变更 |

### Traceability 模型

```text
AC → Task → current code/config/schema location → Gate → evidence → human acceptance
```

代码位置必须通过直接读取当前实现核验，并至少记录 path、role、source revision/digest、定位理由和未决区域。定位不能自动扩大 Spec 或成为实施授权。

### Plan 校验维度

| 维度 | 检查内容 |
|---|---|
| AC 覆盖 | 每个 AC 是否被至少一个 Task、Gate 和人工验收步骤覆盖 |
| 依赖完整性 | Task DAG 无环、无缺失引用，执行顺序可确定 |
| 粒度 | Task 是否能在单次受控实施中完成 |
| 代码依据 | path/revision/digest 是否来自当前源码、配置或 Schema |
| Scope lock | 允许修改的文件/领域、禁止范围和偏差路由是否明确 |
| 证据 | 每个 Task 的完成证据与 Verification Gate 是否明确 |
| 风险与回滚 | 数据、安全、接口、状态与恢复方案是否充分 |
| 验收 | Human Acceptance 步骤、预期结果和残余限制是否明确 |

## 目标文件

| # | 文件 | 操作 | 说明 |
|---|---|---|---|
| 1 | `templates/.themis/core/policies/planning.yaml` | 新建 | Task、粒度、DAG、scope lock、证据与校验规则 |
| 2 | `templates/.themis/core/protocols/artifact/<current>/plan-schema.yaml` | 新建 | Plan/Task/traceability 的稳定机器合同 |
| 3 | `templates/.themis/core/templates/plan-generation.md` | 新建 | Spec + Context + current source → Plan |
| 4 | `templates/.themis/core/templates/plan-validation.md` | 新建 | 覆盖、依赖、依据、范围、风险与验收校验 |
| 5 | `templates/.themis/core/kernel/planning/rules.md` | 更新 | 完整 Planning 边界和路由 |
| 6 | `templates/.themis/core/kernel/planning/themis-plan.sh` | 新建 | validate/render/publish 等确定性操作 |
| 7 | `docs/design/core/kernel/planning.md` | 更新 | 实现状态与证据同步 |

所有新资产必须适配当前 Workspace/Artifact schema allow-list；若需要 Schema 转换或改变既有安装结构，该部分延期。

## 生命周期与 Review

- Planning 只完成 `specified → planned` 所需工件，不写 lifecycle transition。
- `plan.md` 完成不等于 Implementation 获准。
- P6.8 Review 必须读取 current Spec/Plan、设计、风险、scope lock、回滚与验收方案。
- Review 返回 `changes_requested` 时回到 Planning/Specification；返回 `blocked` 时补充事实或证据；只有 current `approved` Review 授权 Implementation。
- Spec 或 Plan 变化会使 Review approval 失效。

## 验收条件

- policy 定义 Task、DAG、scope lock、证据、风险与验收规则。
- Plan Protocol 拒绝未知引用、DAG 环、无 current source revision/digest 的代码定位和未覆盖 AC。
- Prompt 不依赖 Behavior Map，不凭猜测声明代码位置。
- Traceability 从 AC 覆盖到 Task、代码位置、Gate 和人工验收。
- `plan.md` 是 Human projection 或受控工件，不替代 current Spec、源码或 Review evidence。
- 模块测试覆盖项目隔离、投影漂移、路径越界、unsupported schema 和中断恢复。

## 非范围

- 不实现 Behavior Map 或静态分析替代层。
- 不修改项目源码、执行 Task 或 Verification Gate。
- 不批准 Implementation。
- 不改变 Workspace/Artifact schema，也不转换既有安装。

## 风险与回滚

- **风险**：代码定位不完整导致 Plan 漏项。**缓解**：记录未决区域、source revision/digest，并由前置 Review 检查 traceability 与证据缺口。
- **风险**：Plan 粒度过于死板。**缓解**：允许只读 `exploration` Task，但探索结论必须返回 Planning 后重新 Review，不能直接实施。
- **回滚**：移除未发布的新 Core 资产并恢复 rules；不得修改 Workspace 中已存在的项目工件。
