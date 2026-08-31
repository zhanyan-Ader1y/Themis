# verify/basic.md — 2026-08-29-product-judge / step1

> 本文件是 verify/basic 节点的实例工件。本节点的前置闸门、产出与三值取值条件见 `flow.md`「verify/basic」节；判据、判定者与断言范围见 `rules.md` §7。以上只指向位置，本文件不复述其文字。

## 执行身份

**主会话执行者。** 未派发独立子代理，理由记于「说明」。

## 断言与实际结果

**basic 段为空，§7 的三项判据无断言对象。** 逐项记明：

| §7 三项 | 断言对象 | 结果 |
| --- | --- | --- |
| 结构存在 | 无——basic 段无任务，无结构可落地 | 无对象 |
| 可构建 | 无——basic 段未产生任何代码改动 | 无对象 |
| 既有测试无回归 | 无——同上 | 无对象 |

## 命令证据

**本节点自行做出的空段代码层断言**（`flow.md` 要求，不得仅凭上游工件自述判空）：

- `task/basic.md`「任务」小节的条目数：`awk '/^## 任务/,/^## 判定依据/' .themis/workspace/spec/2026-08-29-product-judge/step1/task/basic.md | grep -c '^### '` → `0`
- 本 step 至此的代码改动：`git status --short -- '*.go'` → 空（零行）
- `impl/basic.md` 是否存在：`ls .themis/workspace/spec/2026-08-29-product-judge/step1/impl/basic.md` → 不存在。**按 `flow.md`「impl/basic」节正文"basic 段为空时本节点不产生调用"，这是正确状态。**

## 结论

**不适用。**

**该取值由 basic 段为空导致**——三项判据没有断言对象，`passed` 与 `failed` 两值皆为伪。

**取该值的后果，按 `flow.md` 该节**：不解锁 impl/detail（impl/detail 此时的前置闸门为 R3 approved），不触发失败去向，不构成 fail-closed 停靠。

## 说明

**未派发独立子代理，理由如实记明**：§7 的身份独立要求服务于"实现者不得自判其实现"，而本节点**没有任何实现可判**——三项判据无断言对象。派一个子代理去验"没有东西可验"不产生任何证据，只增加一次派发。

**这与 `2026-08-29-template-strip-prescriptions` 的处置一致**，非本实例新创的出路。

**本判断的可复核形态**：上面三条命令任何人可复跑，若 `task/basic.md` 条目数不为 `0`，本节点的取值即错。
