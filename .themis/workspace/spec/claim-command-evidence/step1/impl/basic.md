# impl/basic.md — claim-command-evidence / step1

> 本节点的前置闸门、产出与失败去向见 `flow.md`「impl/basic」节；四个小节的固定划分见 `template.md`。以上各处只指向位置，本文件不复述其文字。
>
> **本文件不含验证结论。**

## 执行身份

- **身份**：Claude Opus 5，本次 spec 流程执行者会话。工作树 `C:/Coding/Themis`，分支 `main`，动手前 HEAD `2dcfe44`。
- **授权来源**：R3 approved（`step1/task/review.md`「结论」）。
- **本节点不承担 verify/basic**：该节点的执行身份由其自身工件记录。

## 实际改动

**无。零落地调用。**

`task/basic.md` 为空段，本节点无可执行任务。`.themis/spec/template.md` 由 impl/detail 改动，本节点未触碰任何文件。

## 与批准范围的偏差

**无偏差。** 本节点未执行任何落地动作。

本节点为空段形态，下一节点结论取 `不适用`（`flow.md`「verify/basic」节）。**本 step 是该取值的第三个使用者**（前两个为 `workspace-cleanup`、`authorization-traceability`）。

## 命令记录

**命令 B1** — basic 段条目数（本节点自行数出，不采信上游自述）：

`grep -c '^### T-B' .themis/workspace/spec/claim-command-evidence/step1/task/basic.md` → `0`

条目数为 0，证实 basic 段确为空段。**本条已按新落地的断言形态记法书写。**
