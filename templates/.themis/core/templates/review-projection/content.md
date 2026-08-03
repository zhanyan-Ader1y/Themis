# Review Projection Content 模板

> 本文件是 checked Plan 的人类审阅投影。它降低理解成本但不拥有目标、设计或执行 authority，也不得原地 patch。

## Source bindings 记录

- Lifecycle identity：
- Review revision identity：
- Current Request revision：
- Selected path/profile：
- Full path required：
- Plan revision/content digest：
- Plan Check reference：
- Projection profile：

## Overview 概览

仅在确实降低审阅负担时加入 Mermaid flowchart 或 sequence diagram；图形必须忠实于 Plan 核心链路，不增加语义。

## 目标与总体方案

## 关键架构与模块边界

## 重要行为、合同与不变量

## 精简 Review 项

按抽象到具体、高影响到低影响、异常优先排序；除非用户要求，不展示低价值实现细节。

### 1. `<精简结论>`

- Agent recommendation：
- Main basis：
- Impact or trade-off：
- Plan trace location：

## 关键风险与取舍

## Acceptance 与 Verification 设计

Verify 固定为 `themis-impl → independent themis-verification`；本投影不替代 Plan task 或 Verification evidence。

## 按需展开位置

列出 Review Dialogue 可从 checked Plan 解释的位置，不复制或修改 Plan。

## Revision 边界

任何 Plan 或 Plan Check 变化都使本投影 stale，并要求新的 immutable Review Projection pair。单独 content 文件不能建立 authority 或 currentness。
