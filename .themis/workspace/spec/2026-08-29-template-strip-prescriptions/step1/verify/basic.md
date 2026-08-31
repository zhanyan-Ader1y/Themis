# verify/basic.md — 2026-08-29-template-strip-prescriptions / step1

> 本节点的判据、判定者与断言范围见 `rules.md` §7，结论取值见 `flow.md`「verify/basic」节。以上只指向位置，本文件不复述其文字。

## 执行身份

- **身份**：Claude Opus 5，本次 spec 流程执行者会话，分支 `main`。
- **与 `impl/basic.md` 比对**：basic 段为空，**无 impl/basic 工件**，无从比对。
- **本节点未派发子代理，理由如实记明**：`rules.md` §7 的派发要求自 `2026-08-28` 生效，**但 basic 段为空——三项判据没有断言对象**。派一个子代理去验证"没有东西可验"不产生任何证据。**这是空段的固有形态，不是绕过**；与 `2026-08-28-verify-identity-dispatch/step1` 同处置。

## 断言与实际结果

**三项判据均无断言对象**：

| 判据 | 断言对象 | 结果 |
| --- | --- | --- |
| 结构存在 | 无——basic 段为空，未落地任何结构 | **无对象** |
| 可构建 | 无——本 step 不改代码 | **无对象** |
| 既有测试无回归 | 无——同上 | **无对象** |

## 命令证据

本节点自行做出的空段代码层断言（**不凭上游工件自述判空**）：

- basic 任务数：`grep -c '^### T-B' .themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/task/basic.md` → `0`
- 本 step 改动的 `.go` 文件数：`0`（`git diff 84c4b97..HEAD --name-only -- '*.go'` 无输出；**该命令含历史点位，不按可重跑断言书写**）

## 结论

**不适用。**

**由空段导致**——三项判据无断言对象，`passed` 与 `failed` 两值皆为伪。依 `flow.md` 该取值的规定：本节点不解锁 impl/detail（其前置闸门另有取值），不触发失败去向、不构成 fail-closed 停靠。

## 说明

**本文件是补写的**，产出时机晚于 verify/detail——**由独立验证子代理在核验时报出缺失**，本会话据此补齐。

**这是同型遗漏的第三次**（前两次：`2026-08-27-trace-number-scan` 的 `state.md`、`2026-08-28-verify-identity-dispatch` 的两份工件）。**三次都不是判据抓到的**——判据只验条目内容，不验工件是否齐备。

**该缺口的归属已定**：`docs/adr/2026-08-29-template-is-skeleton-not-fact-source.md`「已知代价」第 4 项记明——**工件齐备性的真正规定在 `flow.md` 各节点「产出」项，而那些产出项无判定者**。**修复属所有者排定的第 2 件事**，不在本 step 范围内。
