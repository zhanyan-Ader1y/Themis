# impl/basic.md — authorization-traceability / step1

> 本文件是 impl/basic 节点的实例工件。本节点的前置闸门、产出与失败去向见 `flow.md`「impl/basic」节；四个小节的固定划分见 `template.md`。以上各处只指向位置，本文件不复述其文字。
>
> **本文件不含验证结论。** 本节点只落地并如实记录。

## 执行身份

- **身份**：Claude Opus 5（模型标识 `claude-opus-5`），本次 spec 流程执行者会话。工作树 `C:/Coding/Themis`，分支 `main`，动手前 HEAD `df98437`。当前强制水平下无独立实现者角色账户，身份即这一次 agent 会话本身。
- **授权来源**：R3 approved（原话与录入说明见 `step1/task/review.md`）。本节点未在 R3 授权之外取得任何新授权。
- **本节点不承担 verify/basic**：该节点的执行身份由其自身工件记录，本文件不预写、不猜测。

## 实际改动

**无。零落地调用。**

`task/basic.md` 为空段（`### T-B` 条目数 0，命令 B1），本节点无可执行任务。`flow.md`「impl/basic」节列出的第二项产出（实际代码改动）在空段下为空集。

`.themis/spec/`、`.themis/skills/` 均未被本节点触碰——落地全部由 impl/detail 承担。

## 与批准范围的偏差

**无偏差。** 本节点未执行任何落地动作，不存在越出 R3 批准范围的可能。

一处如实标出：本节点为空段形态，`flow.md`「verify/basic」节规定该情形下下一节点结论取 `不适用`。**本 step 是该取值的第二个使用者**（首个为 `workspace-cleanup`），本节点不预判其结论，仅指出适用条款所在。

## 命令记录

**命令 B1** — `task/basic.md` 的 basic 任务条目数：

```
$ grep -c '^### T-B' .themis/workspace/spec/authorization-traceability/step1/task/basic.md
0
```

条目数为 0，证实 basic 段确为空段。**此为本节点自行运行得出，不采信 `task/basic.md` 正文的自述。**
