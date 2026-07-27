# Attribution — 归因

> 规范状态：正式设计。实现状态：已确认但未实现；当前只有领域 rules 和 Workspace Outcome 目录骨架。

## 职责边界

Attribution 建立 Spec、Plan、Task、代码变更、Verification、deployment 和最终 Outcome 之间的可追溯关联。它是观察者，不干预执行流程，不评估个人绩效，也不改写源 evidence。

## 关联模型

```text
Spec → Plan → Task → Commit/Change → Run → Deployment → Outcome
```

每个关联必须保留稳定 ID、来源和时间信息。身份可以来自 Git、Session 或 Agent metadata，但推断身份时必须标明证据来源。

## Outcome

Outcome 描述交付后的真实结果：

```text
success | rework | defect | incident | rollback
```

Verification `pass` 只说明某次 Run 的 blocking Gate 通过，不等同于 Outcome `success`。后续 defect 或 incident 不改写历史 Run，而是新增 Outcome 并建立关联。

## 分析边界

- 可以计算返工、缺陷逃逸、验证薄弱点和阶段趋势。
- 必须区分测量到的相关性与因果解释。
- 不得根据单次关联断言个人或 Agent 导致了结果。
- 改进建议进入 Knowledge candidate，而不是由 Attribution 直接修改 policy 或 Context。

## Workspace 交互

目标合同：

```text
读取:
  workspace/specs/
  workspace/runs/
  workspace/evidence/
  workspace/outcomes/
  Git / deployment evidence

写入:
  workspace/outcomes/ 中的关联与分析记录
```
