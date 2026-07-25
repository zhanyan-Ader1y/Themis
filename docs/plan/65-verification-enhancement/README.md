# P6.5 — 验证增强（Verification Enhancement）

**优先级**：P6.5（可在 P6 Behavior Map 之后、P8 Agent 之前实施）
**依赖**：[P1 Template Contract](../10-template-contract/README.md)、[P5 Requirement Questioning](../50-requirement-questioning/README.md)
**状态**：待用户主动发起

## 背景

Themis 在 `docs/core/kernel/verification.md` 和 `docs/workflow.md` 中已定义了 Verification 的完整理论模型——Gate 调度、证据采集、失败分类、Verdict 计算。但当前基线：

- `verification/rules.md` 定义了模块边界，但内容为基线占位
- 无 Gate 策略配置文件
- 无失败分类脚本或 Prompt
- 无 Verdict 计算的标准化模板
- P5 需求追问中第四步的"对抗验证"为 Spec 级别，不覆盖代码级 Gate 验证

P5 方法论分析揭示的设计原则——**对抗式验证、假设探测、边界条件扫描**——同样适用于代码级验证。Spec 对抗验证检查"需求是否完整"，代码级 Gate 验证应检查"实现是否满足需求且无遗漏"。

## 目标

1. 将 Gate Pipeline 从概念落地为策略配置
2. 编写失败分类 Prompt 模板（瞬态/代码/配置/策略四分类）
3. 增强 `verification/rules.md`，引入 P5 方法论中的对抗式检查
4. 同步更新 WIKI 文档

## 核心设计

### Gate 策略配置

`verification.yaml` 定义三类 Gate 的行为：

| Gate 类型 | 语义 | 默认行为 |
|---|---|---|
| blocking | 失败阻止推进 | lint、build、test 默认为 blocking |
| warning | 失败允许继续，标记待处理 | code-coverage、complexity 默认为 warning |
| info | 仅收集信息 | dependency-audit、bundle-size 默认为 info |

### 失败分类（来自 P5 方法论增强）

| 类别 | 判定标准 | 处理策略 |
|---|---|---|
| transient | 环境问题、网络超时、资源竞争 | 自动重试，最多 N 次 |
| code | 编译错误、测试失败、lint 违规 | 返回 Implementation，需修复代码 |
| configuration | 环境变量缺失、权限不足 | 请求人工/运维介入 |
| policy_conflict | Gate 规则矛盾 | 停止，需人工裁决 |
| **evidence_insufficient**（新增） | 证据不足以判断 | 标记为 inconclusive，不 pass |
| **assumption_violated**（新增） | 验证过程发现关键假设不成立 | 返回 Specification，需重新评估 |

> 新增两类源自 P5 方法论：`evidence_insufficient` 反映苏格拉底式"证据探测"——证据不足不是通过；`assumption_violated` 反映 grill-me"假设攻击"——发现假设不成立时应回溯而非继续。

### 对抗式证据检查

从 P5 Step 4 的攻击维度中提取适用于代码级验证的检查项：

| 攻击维度 | 代码级 Gate 对应 |
|---|---|
| 边界条件 | 边界值测试覆盖 |
| 并发与竞态 | 并发测试、race condition 检测 |
| 状态转换 | 状态机测试、非法状态断言 |
| 权限与安全 | 安全扫描、权限测试 |
| 依赖失败 | 集成测试的 mock 失败场景 |
| 数据完整性 | Schema 迁移测试、数据一致性检查 |

## 目标文件

| # | 文件 | 操作 | 说明 |
|---|---|---|---|
| 1 | `templates/.themis/core/policies/verification.yaml` | 新建 | Gate 类型、默认策略、失败分类规则、对抗检查维度 |
| 2 | `templates/.themis/core/templates/failure-classification.md` | 新建 | 失败分类 Prompt 模板 |
| 3 | `templates/.themis/core/kernel/verification/rules.md` | 更新 | 从占位内容更新为完整验证规则 |
| 4 | `docs/core/kernel/verification.md` | 更新 | 同步 WIKI |

## 验收条件

- `verification.yaml` 定义 3 种 Gate 类型和 6 种失败分类
- `failure-classification.md` 包含每类失败的判定 Prompt 和推荐处理
- `verification/rules.md` 不再包含占位内容
- 新增的对抗式证据检查维度在 rules 中有明确描述
- 与 P5 的对抗验证方法论保持概念一致

## 非范围

- 不实现 `themis-pipeline.sh` 确定性脚本（留待 P8）
- 不修改 Workspace 的 runs/evidence 目录结构（已由 P1 定义）
- 不实现 Gate 并行调度（P8 范围）
- 不修改 `workspace/manifest.yaml` 的 Gate 配置段（已由 P1 定义）

## 风险与回滚

- **风险**：失败分类 Prompt 判断不准确 → **缓解**：分类提示保守（不确定时归为待人工判断）
- **回滚**：移除新增文件，恢复 rules.md 到基线
