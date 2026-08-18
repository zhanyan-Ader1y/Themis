# .themis/spec/flow.md

本文件只回答一个问题：**现在能不能走到下一步**。判定规则（这一步怎么判过不过）一律不在此处给出，指向 `rules.md` 的对应小节。

本文件永久单文件。流程契约本质是一张图，闸门的前置是上游节点的产出，失效级联跨节点波及，价值在于能被一次读完。拆成 `nodes/*.md` 后，读某一节点的人看不到"它的失效会波及谁"，而漏读上下游关系正是失效级联最易出错处。**这条与体量无关**：长到五百行也不拆，只在内部分节。

## 节点序列

```text
Intake（不可变来源 + 来源绑定 claims）
→ 追问（多轮，未答不得判收敛）
→ R1 意图评审 ────────────── 人工
→ 抽象设计（specify）
→ R2 抽象设计评审 ────────── 人工
→ 详细设计 + 任务（分 basic / detail 两组）
→ R3 详细方案评审 ────────── 人工
→ impl/basic
→ verify/basic ───────────── 机器判，无人工节点
→ impl/detail
→ verify/detail ──────────── 机器判，无人工节点
→ 人工验收 ───────────────── 人工
→ 摘要
```

人工节点固定四处——R1、R2、R3、验收；两次验证均无人工节点。

## 通用失败去向

任一节点失败（工具错误、验证不过、依赖缺失）时 **fail-closed**，停在 last proven gate（最近已证闸门），等待人类或 Agent 决定。系统**不得**进行失败次数预算，也**不得**把失败转为经验学习（`SPEC-FAIL-001`，判定见 `rules.md` §10）。

## Intake

- **前置闸门**：收到新用户请求。
- **产出**：不可变来源记录；`Intent.md` 的来源引用小节获得初始条目。
- **失效波及**：本节点是链首，无上游可失效；其自身变更使全部下游工件 stale。
- **失败去向**：无 last proven gate，停在链首等待重新提交请求。

用户确认 source-bound claims 之前，不得进入任何设计或实现节点（`SPEC-INTAKE-001`）。claims 的来源引用格式与分层事实源规则见 `rules.md` §1。

## 追问

- **前置闸门**：Intake 已产出不可变来源。
- **产出**：`QA.md` 追加第 N 轮问答（追加写入，不覆盖）；`Intent.md` 的问题/期望结果/核心链路小节被更新。
- **失效波及**：`Intent.md` 变更使 R1 结论及其下游全部 stale。
- **失败去向**：停在 Intake 已证闸门。

多轮进行，每轮问答形成不可变记录。收敛判据见 `rules.md` §2——未回答的问题不得判定为"已收敛"。

## R1 意图评审（人工）

- **前置闸门**：意图已判定收敛（`rules.md` §2）。
- **产出**：`intent-review.md` 的投影 / 未解决反馈 / 结论三节。
- **失效波及**：结论为 approved 才解锁抽象设计；`Intent.md` 任何后续变更使本结论 stale，需重新评审。
- **失败去向**：未批准则停在追问节点，继续追问或修订 `Intent.md`。

投影必须由抽象到具体渐进呈现，只含该抽象层增量（`rules.md` §3）。未批准前抽象设计节点不得开始。

## 抽象设计（specify）

- **前置闸门**：R1 结论为 approved 且未 stale。
- **产出**：`step<N>/specify.md` 的行为条目与来源覆盖两节。
- **失效波及**：本文件变更使 R2 结论、design.md、任务、验证、验收全部 stale。
- **失败去向**：停在 R1 已证闸门。

specify 即抽象设计——同一节点的两个叫法，不存在独立于抽象设计之外的第二份 specify 工件。行为条目用 EARS 句式表达使每条可判定通过/失败（`SPEC-EARS-001`）。`[basic]` 标识的含义见 `rules.md` §5。

## R2 抽象设计评审（人工）

- **前置闸门**：`specify.md` 成形。
- **产出**：`step<N>/design-review.md` 的投影 / 未解决反馈 / 结论三节。
- **失效波及**：结论 approved 才解锁详细设计；`specify.md` 变更使本结论 stale。
- **失败去向**：未批准则停在抽象设计节点。

投影须含架构或时序 Overview（`SPEC-REVIEW-R2`），低负担要求见 `rules.md` §3。

## 详细设计 + 任务

- **前置闸门**：R2 结论为 approved 且未 stale。
- **产出**：`step<N>/design.md`；`step<N>/task/basic.md` 与 `task/detail.md`（有序两组）。
- **失效波及**：design.md 变更使两份任务、两次实现、两次验证、验收全部 stale；单份任务变更只使其对应实现与验证 stale。
- **失败去向**：停在 R2 已证闸门。

任务必须在 R3 之前完成 basic/detail 分类（`SPEC-IMPL-002`），判定见 `rules.md` §4。结构决策归属见 `rules.md` §6——任务文件只做分解与依赖声明，不得引入 design.md 未定的结构。两段恒定存在，**允许为空**；空段不产生落地调用，也不构成路径分支。

## R3 详细方案评审（人工）

- **前置闸门**：design.md 与两份任务成形，且 basic/detail 分类已完成。
- **产出**：`step<N>/task/review.md` 的评审范围 / 分类核查 / 未解决反馈 / 结论四节。
- **失效波及**：结论 approved 才解锁实现；design.md 或任务变更使本结论 stale。
- **失败去向**：未批准则停在详细设计+任务节点。

一次评审同时覆盖 `task/basic.md` 与 `task/detail.md`，不拆成两次人工评审。未解决反馈必须为空才可批准（`SPEC-REVIEW-R3`）。

## impl/basic

- **前置闸门**：R3 结论为 approved 且未 stale。
- **产出**：`step<N>/impl/basic.md` 的执行身份 / 实际改动 / 与批准范围的偏差 / 命令记录四节，以及实际代码改动。
- **失效波及**：本节点产出变更使 verify/basic 结论 stale。
- **失败去向**：停在 R3 已证闸门。

实现必须在 R3 批准范围内——不得修改 current-request、plan 或验收要求，不得做无关重构（`SPEC-IMPL-001`）。basic 段为空时本节点不产生调用，直接进入 impl/detail。

## verify/basic

- **前置闸门**：impl/basic 完成。
- **产出**：`step<N>/verify/basic.md` 的执行身份 / 断言与实际结果 / 命令证据 / 结论 / 说明五节。
- **失效波及**：结论通过才解锁 impl/detail；impl/basic 变更使本结论 stale。
- **失败去向**：结论不通过则停在 R3 已证闸门，由重规划处理。

**无人工节点**——机器判。只判三项：结构存在、可构建、既有测试（若有）无回归。判定者与断言范围见 `rules.md` §7。结论必须写入验证角色所有的工件，不得写入实现者所有的工件。

## impl/detail

- **前置闸门**：verify/basic 结论通过；basic 段为空时前置闸门为 R3 approved。
- **产出**：`step<N>/impl/detail.md` 的四节，以及实际代码改动。
- **失效波及**：本节点产出变更使 verify/detail 结论 stale。
- **失败去向**：停在 verify/basic 已证闸门；basic 段为空时停在 R3 已证闸门。

basic 段通过结构性验证前，detail 段不得开始（`SPEC-IMPL-002`）。

## verify/detail

- **前置闸门**：impl/detail 完成。
- **产出**：`step<N>/verify/detail.md` 的五节。
- **失效波及**：结论通过才解锁人工验收；impl/detail 变更使本结论 stale。
- **失败去向**：结论不通过则停在 verify/basic 已证闸门。

**无人工节点**——机器判。依据实际实现与证据判定 `passed`/`failed`，不得依据文档、Agent 自述或文件存在判定通过（`SPEC-VERIFY-002`）。验证者身份必须独立于实现者，判定见 `rules.md` §7。

孤儿阻断的判定同样在本节点完成，结论写入本节点工件 `verify/detail.md`；判据、拒绝条件与判定者见 `rules.md` §8。

## 人工验收（人工）

- **前置闸门**：verify/detail 结论为 `passed`，且孤儿阻断核查通过（`rules.md` §8）。
- **产出**：`step<N>/acceptance.md` 的交付视图 / 阻断核查 / 用户原话 / 结论四节。
- **失效波及**：结论 accepted 才解锁摘要；任一上游变更使本结论 stale。
- **失败去向**：未接受则停在 verify/detail 已证闸门。

存在已落地但无消费者的 basic 改动时不得进入本节点，必须由重规划显式处理（复用或删除）后才解除（`SPEC-ACCEPT-002`）。人工验收在 step 末尾**只有一次**，不因落地分两段而分两次。

## 摘要

- **前置闸门**：验收结论为 accepted。
- **产出**：摘要工件，绑定实际交付。
- **失效波及**：本节点是链尾。
- **失败去向**：停在验收已证闸门。

仅当验收 accepted 后 lifecycle 才可标记完成（`SPEC-SUMMARY-001`）。摘要产出中性工件；是否喂给 Themico 由可选 adapter 决定，不得成为流程运行前提（`SPEC-THEMICO-002`）。
