# P7.5 — Attribution & Outcome（归因与交付结果）

**优先级**：P7.5（在 P6.5/P6.8 评审增强之后、P8 Agent 架构之前）
**依赖**：[P1 Template Contract](../10-template-contract/README.md)、[P6.5 Verification Enhancement](../65-verification-enhancement/README.md)、[P6.8 Review Enhancement](../68-review-enhancement/README.md)
**状态**：待用户主动发起

## 背景

Attribution 是 SDD 流程的"观察者"——它不参与执行，而是在事后关联 Spec、Task、代码变更、验证结果、部署和最终 Outcome，用于长期质量分析和改进。当前基线：

- `attribution/rules.md` 定义了模块边界，但**不在 Orchestrator import 图中**
- 无 Outcome 分类策略
- 无 Attribution 分析 Prompt
- Workflow 文档已定义完整的 Outcome 模型（success/rework/defect/incident/rollback），但无落地方案

Themis 区分"单次验证通过"和"实际交付结果成功"——这是 Verification 和 Outcome 的本质区别。缺乏 Outcome 追踪意味着无法从历史中学习。

## 目标

1. 定义 Outcome 分类策略和记录模板
2. 定义 Attribution 关联模型（Spec → Task → Commit → Run → Deploy → Outcome）
3. 编写 Attribution 分析 Prompt（返工率、缺陷逃逸率、验证薄弱点）
4. 更新 `attribution/rules.md` 使其不再为占位状态，并纳入 import 图
5. 同步更新 WIKI 文档

## 核心设计

### Outcome 分类

| 类型 | 含义 | 记录时机 |
|---|---|---|
| success | 成功交付，无重大问题 | 部署后观察期结束 |
| rework | 需要返工 | Review 后或部署后发现关键缺陷 |
| defect | 逃逸缺陷 | 生产环境发现问题 |
| incident | 事故 | 导致服务中断或数据损坏 |
| rollback | 回滚 | 部署后被撤销 |

### Attribution 关联链

```
Spec (`spec.yaml` 权威语义；`spec.md` Human 投影)
  → Plan (plan.md)
    → Task (plan.md tasks[])
      → Commit (git history)
        → Run (verification runs)
          → Deploy (deployment evidence)
            → Outcome (outcomes/*)
```

### 分析维度

| 维度 | 计算方式 | 用途 |
|---|---|---|
| 返工率 | rework / (success + rework) | 识别需求质量或实现质量问题 |
| 缺陷逃逸率 | defect / total deployed | 识别验证薄弱环节 |
| 平均修复时间 | incident → resolved 时长 | 识别响应瓶颈 |
| Gate 有效性 | Gate pass 但 Outcome fail 的比例 | 识别需要增强的 Gate |

## 目标文件

| # | 文件 | 操作 | 说明 |
|---|---|---|---|
| 1 | `templates/.themis/core/policies/outcome.yaml` | 新建 | Outcome 分类、记录规则、观察期配置 |
| 2 | `templates/.themis/core/templates/attribution-analysis.md` | 新建 | Attribution 分析 Prompt（输入→关联→分析→建议） |
| 3 | `templates/.themis/core/kernel/attribution/rules.md` | 更新 | 从占位内容更新为完整归因规则 |
| 4 | `templates/.themis/core/kernel/orchestrator/rules.md` | 更新 | 将 Attribution 纳入 import 图 |
| 5 | `docs/core/kernel/attribution.md` | 更新 | 同步 WIKI |

## 验收条件

- `outcome.yaml` 定义 5 种 Outcome 类型及记录规则
- `attribution-analysis.md` 含完整的关联模型和分析维度 Prompt
- `attribution/rules.md` 不再包含占位内容
- `orchestrator/rules.md` 的 import 图中包含 `../attribution/rules.md`
- Outcome 与 Verification Verdict 的区别有明确文档

## 非范围

- 不实现自动化的指标计算脚本（留待 P8）
- 不实现部署集成（依赖外部 CI/CD）
- 不修改 Workspace 的 outcomes 目录结构（已由 P1 定义）

## 风险与回滚

- **风险**：Outcome 数据不足导致分析无意义 → **缓解**：初期仅做手动记录，不做自动分析
- **回滚**：移除新增文件，恢复 rules.md 到基线，从 import 图中移除 attribution
