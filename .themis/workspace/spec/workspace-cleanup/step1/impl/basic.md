# impl/basic.md — workspace-cleanup / step1

> 本文件是 impl/basic 节点的实例工件。本节点的前置闸门、产出、失效波及与失败去向见 `flow.md`「impl/basic」节；四个小节的固定划分与「执行身份」作为身份独立判定落点这一用途见 `template.md`。以上各处只指向位置，本文件不复述其文字。
>
> **本文件不含验证结论。** 本节点只落地并如实记录，判据是否满足属 verify/basic。

## 执行身份

- **身份**：Claude Opus 5（模型标识 `claude-opus-5`），以本次 spec 流程执行者身份运行；工作树 `C:/Coding/Themis`，分支 `main`，动手前 HEAD 为 `7a068dc`、工作区除本 spec 实例工件外干净。当前强制水平下没有独立的实现者角色账户，身份即这一次 agent 会话本身。
- **授权来源**：R3 approved（`state.md`「各闸门」R3 行，原话见 `step1/task/review.md`「结论」）。本节点未在 R3 授权之外取得任何新授权。
- **本节点不承担 verify/basic**：该节点的执行身份由其自身工件记录，本文件不预写、不猜测。

## 实际改动

**无。零落地调用。**

`task/basic.md` 为空段（`### T-B` 条目数 0，命令 B2），本节点因此没有可执行的任务。`flow.md`「impl/basic」节列出的第二项产出（实际代码改动）在空段下为空集。

`templates/`、`.gitignore`、仓库根 `AGENTS.md`、`README.md`、`templates/.themico/` 均未被本节点触碰——命令 B1 显示落地前基线 `098fcd9` 到本节点执行时的区间内，`templates/` 与 `.gitignore` 零改动（该区间内唯一的提交 `7a068dc` 只改本 spec 的实例工件）。

## 与批准范围的偏差

**无偏差。** 本节点未执行任何落地动作，不存在越出 R3 批准范围的可能。

一处如实标出：本节点为空段形态，`flow.md`「verify/basic」节规定该情形下下一节点结论取 `不适用`。这一取值是控制面在 2026-08-24 新增的（此前该情形无合法取值，需控制器逐案裁定）——**本 step 是该新增取值的第一个使用者**。本节点不预判 verify/basic 的结论，仅指出其适用条款所在。

## 命令记录

**命令 B1** — 落地前基线到本节点执行时，`templates/` 与 `.gitignore` 的改动：

```
$ git diff --stat 098fcd9..HEAD -- templates/ .gitignore
（无输出）
```

无输出即证该区间内两处均零改动。

**命令 B2** — `task/basic.md` 的 basic 任务条目数：

```
$ grep -c '^### T-B' .themis/workspace/spec/workspace-cleanup/step1/task/basic.md
0
```

条目数为 0，证实 basic 段确为空段。**此为本节点自行运行得出，不采信 `task/basic.md` 正文的自述。**
