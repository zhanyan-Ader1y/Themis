# 实例结构

本文件只记录结构，**不做任何定义**。字段含义、判定规则与填写要求一律见 [rules.md](rules.md)，节点顺序见 [flow.md](flow.md)。

## 实例目录树

```text
.themis/workspace/spec/<spec-id>/
  Intent.md
  intent-review.md
  QA.md
  state.md
  summary.md
  step<N>/
    specify.md
    specify-review.md
    design.md
    task/
      basic.md  detail.md
    review.md
    impl/
      basic.md  detail.md
    verify/
      basic.md  detail.md
    acceptance.md
```

`<spec-id>` 为一次 spec 运行的标识。`<N>` 为实现步骤序号：大步骤为整数，小步骤为小数。

## 文件小节

| 文件 | 小节 |
|---|---|
| `Intent.md` | 问题 / 期望结果 / 核心链路 / 范围与非做 / 约束 / 来源引用 |
| `intent-review.md` | 投影 / 未解决反馈 / 结论 |
| `QA.md` | 第 N 轮 → 问 / 答 / 来源 |
| `state.md` | 当前节点 / 各闸门 / 当前性 |
| `summary.md` | 实际交付 / 绑定的验收结论 / 说明 |
| `specify.md` | 行为条目（`### SPEC-<主题>-<序号>` + 验收判据）/ 来源覆盖 |
| `specify-review.md` | 投影 / 未解决反馈 / 结论 |
| `design.md` | 架构与边界 / 结构决策 / 取舍 / 事实依据 |
| `task/basic.md` | 基础任务 → `### T-B<n>` |
| `task/detail.md` | 详细实现任务 → `### T-D<n>` |
| `review.md` | 评审范围 / 分类核查 / 未解决反馈 / 结论 |
| `impl/basic.md`、`impl/detail.md` | 执行身份 / 实际改动 / 与批准范围的偏差 / 命令记录 |
| `verify/basic.md`、`verify/detail.md` | 执行身份 / 断言与实际结果 / 命令证据 / 结论 / 说明 |
| `acceptance.md` | 交付视图 / 阻断核查 / 用户原话 / 结论 |

`QA.md` 追加写入，既有轮次不改写。三个评审工件与三个闸门一一对应：`intent-review.md` 对 R1，`specify-review.md` 对 R2，`review.md` 对 R3。
