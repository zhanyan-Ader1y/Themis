# .themis/spec/template.md

本文件只回答一个问题：**产物长什么样、放在哪**。只记录结构，不做任何定义——含义判定一律见 `rules.md`，流程走向（现在能不能走到下一步）一律见 `flow.md`。

实例面 `.themis/workspace/spec/<spec-id>/` 是运行时唯一可写处：`.themis/spec/` 下的定义面四份文件安装后只读，不被任何流程修改；每个 spec 实例在 `<spec-id>` 之下产出自己的一套工件，工件之间不共享、不跨实例引用。

## 实例目录树

```text
.themis/workspace/spec/<spec-id>/
  Intent.md
  intent-review.md
  QA.md
  state.md
  step<N>/
    specify.md
    design.md
    design-review.md
    task/
      basic.md  detail.md  review.md
    impl/
      basic.md  detail.md
    verify/
      basic.md  detail.md
    acceptance.md
    summary.md
```

`Intent.md`、`intent-review.md`、`QA.md`、`state.md` 每个 spec 一份，放在实例根目录：R1 意图评审只发生一次，因此 `intent-review.md` 不随 step 分目录，与 `Intent.md`、`QA.md`、`state.md` 一起留在根；其余工件按 step 分目录，每个 step 拥有独立的一套 `specify.md`、`design.md`、`design-review.md`、`task/`、`impl/`、`verify/`、`acceptance.md`、`summary.md`；`summary.md` 绑定的是该 step 的实际交付，因此与 `acceptance.md` 同层，不提到实例根目录。

step 编号规则：大步骤取整数，大步骤内的小步骤取小数。用户描述的多个无关联需求拆为不同大步骤；同一大步骤内部自顶向下、由抽象到具体拆为小步骤。

## 文件小节

| 文件 | 小节 |
| --- | --- |
| `Intent.md` | 问题 / 期望结果 / 核心链路 / 范围与非做 / 约束 / 来源引用 |
| `QA.md` | 第 N 轮 → 问 / 答 / 来源（追加写入） |
| `intent-review.md` | 投影 / 未解决反馈 / 结论 |
| `state.md` | 当前节点 / 各闸门 / 当前性 |
| `specify.md` | 行为条目（`### SPEC-<主题>-<序号>` + 验收判据）/ 来源覆盖 |
| `design.md` | 架构与边界 / 结构决策 / 取舍 / 事实依据 |
| `design-review.md` | 投影 / 未解决反馈 / 结论 |
| `task/basic.md` | 基础任务 → `### T-B<n>` |
| `task/detail.md` | 详细实现任务 → `### T-D<n>` |
| `task/review.md` | 评审范围 / 分类核查 / 未解决反馈 / 结论 |
| `impl/basic.md`、`impl/detail.md` | 执行身份 / 实际改动 / 与批准范围的偏差 / 命令记录 |
| `verify/basic.md`、`verify/detail.md` | 执行身份 / 断言与实际结果 / 命令证据 / 结论 / 说明 |
| `acceptance.md` | 交付视图 / 阻断核查 / 用户原话 / 结论 |
| `summary.md` | 交付摘要 / 绑定的验收结论 / 中性工件说明 |

上表每份工件的小节划分是 `rules.md` §9 的落点：§9 是贯穿全部产出工件节点的通用规则，不依附任何单一节点，因此不会被 `flow.md` 的某个节点专门引用——它正是通过本文件逐份工件的小节划分获得落点。

`impl/basic.md`、`impl/detail.md`、`verify/basic.md`、`verify/detail.md` 的**执行身份**小节是身份独立判定的落点，两处一比即得（判定见 `rules.md` §7）；`verify/basic.md`、`verify/detail.md` 的**说明**小节是人类语义的落点，其余四节（执行身份 / 断言与实际结果 / 命令证据 / 结论）均为控制事实（配比要求见 `rules.md` §9）。

`task/basic.md` 中每个 `### T-B<n>` 固定记四项：结构改动、判定依据、被哪些 detail 任务依赖、design.md 中的出处（判定见 `rules.md` §4、§6）。

`task/detail.md` 中每个 `### T-D<n>` 固定记三项：行为目标、对应 `specify.md` 条目、依赖的基础任务——后两项分别是 trace 链与 `rules.md` §8 消费者关系在本文件的落点。
