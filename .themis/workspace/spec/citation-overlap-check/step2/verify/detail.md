# verify/detail.md — citation-overlap-check / step2

> 本文件的断言范围、身份独立与拒绝条件见 `rules.md` §7，孤儿判定见 §8，追溯链环 2/3 检出见 §12。以上只指向位置，本文件不复述其文字。
>
> **本文件里的每个数字与存在性断言均由本节点当场跑命令得出。**

## 执行身份

- **身份**：Claude Opus 5，本次 spec 流程会话，分支 `main`。
- **与 `impl/detail.md`「执行身份」比对：相同——身份独立不成立**（第八次）。
- **本 step 的证据强度是本项目至今最弱的**：R2、R3 均为授权代行，**方案、落地、验证三者全部只有执行者一人看过**。此前 `question-eligibility` 只有 R3 是代行，本 step 是两道。

## 断言与实际结果

| 条目 | 任务 | 判据与实跑 | 结论 |
| --- | --- | --- | --- |
| 001 | T-D1 | `grep -c '只判三项：结构存在' .themis/spec/flow.md` → `0`；`grep -c '依据实际实现与证据判定' .themis/spec/flow.md` → `0` | **满足** |
| 002 | T-D2 | `grep -c '必须由重规划显式处理' .themis/spec/flow.md` → `0`；`grep -c '（工具错误、验证不过、依赖缺失）' .themis/spec/flow.md` → `0` | **满足** |
| 003 | T-D3 | `grep -c '裸数字必须紧跟在一个完整编号之后' .themis/spec/rules.md .themis/spec/template.md \| awk -F: '{s+=$2} END {print s}'` → `1` | **满足** |
| 004 | T-D1、T-D2 | `awk '/^## verify\/basic/,/^## impl\/detail/' .themis/spec/flow.md \| grep -c 'rules.md.*§7'` → `1` | **满足** |
| 005 `[横切]` | 无 | `themis overlap .themis/spec` → `0` 处；`go test ./...` 的 `FAIL` 数 → `0` | **满足** |

**判据 005 的 `themis` 那条由人工实跑**——`themis` 不在只读白名单内，R2 已裁定照旧（step1 已记明这是白名单机制的必然边界）。

### 判据 004 的覆盖范围，如实说明其不足

判据 004 只查 `verify/basic` 一节的指向是否还在，**查不到另外三处删除后的可读性**。

本节点因此逐处通读四行原文核对：

- `flow.md:33` —— 保留 fail-closed 行为与 `SPEC-FAIL-001`，句尾指向 §10。**成句。**
- `flow.md:154` —— "判据、判定者与断言范围见 §7"，保留结论写入要求。**成句。**
- `flow.md:176` —— 保留 `SPEC-VERIFY-002` 与身份独立要求，指向 §7。**成句。**
- `flow.md:189` —— 保留 `SPEC-ACCEPT-002`、人工验收只有一次、唯一授权点。**成句。**

**四处指向全部保留，无断链。**

### 判据 005 的效果核查

`impl/detail.md` 称 `overlap` 报出 `0` 处。**本节点独立复跑确认**：输出为「未发现需人工复核的重合片段」，四条排除规则计数分别为 `4`、`4`、`5`、`2`。

**这是 step1 交付的直接效用**：修复第一次有了机器可判的完成条件，且**由 step1 的产物验证 step2 的完成**。

## 命令证据

- `grep -c '只判三项：结构存在' .themis/spec/flow.md` → `0`
- `grep -c '依据实际实现与证据判定' .themis/spec/flow.md` → `0`
- `grep -c '必须由重规划显式处理' .themis/spec/flow.md` → `0`
- `grep -c '（工具错误、验证不过、依赖缺失）' .themis/spec/flow.md` → `0`
- `grep -c '裸数字必须紧跟在一个完整编号之后' .themis/spec/rules.md .themis/spec/template.md | awk -F: '{s+=$2} END {print s}'` → `1`
- `awk '/^## verify\/basic/,/^## impl\/detail/' .themis/spec/flow.md | grep -c 'rules.md.*§7'` → `1`
- 控制面四份文件 `themis verify` 报告数：各 `0`（人工实跑）
- `themis overlap .themis/spec` → `0` 处（人工实跑）

## 追溯链检出（§12 环 2、环 3）

- **环 2**：上游排除 `[横切]` 后为 `001 002 003 004`，下游展开后含全部四条，**差集为空 → 通**。
- **环 3**：上游 `T-D1 T-D2 T-D3`，下游为本文件任务栏，三者均出现，**差集为空 → 通**。

## 结论

**passed。**

五条判据全部满足。追溯链两环均通。**`themis overlap` 报出 `0` 处，控制面五处复述全部清除。**

**五项如实带出，不掩饰**：

1. **本 step 是本项目至今独立性最弱的**——R2、R3 两道闸门均为授权代行，方案、落地、验证只有执行者一人看过。**若所有者事后审阅认为任一裁定有误，本 step 应退回相应节点。**
2. **R2 裁定二在无决定性依据下作出**——编号前提归 `template.md` 还是留在 `rules.md`，两个方向都讲得通。`impl/detail.md` 已按 R2 的补偿处置写明性质。
3. **落地中一处偏差**——第 33 行引入重复指向，判据抓不到，**靠通读读出**。这佐证了 `design.md` 结构决策二（逐处通读）的必要性。
4. **`overlap` 报 `0` 不等于确实无复述**——只等于"无未被四条经验规则排除的重合"。
5. **另三处删除的可读性无判据保护**——本节点逐处通读核对，但那是人判，非机器判。
