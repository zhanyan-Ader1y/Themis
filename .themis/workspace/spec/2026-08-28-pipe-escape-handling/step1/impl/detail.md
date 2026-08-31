# impl/detail.md — 2026-08-28-pipe-escape-handling / step1

> 本文件是 impl/detail 节点的实例工件。本节点的前置闸门与产出见 `flow.md`「impl/detail」节；实现须在 R3 批准范围内，结构决策归属见 `rules.md` §6。以上只指向位置，本文件不复述其文字。

## 执行身份

**主会话执行者。** 验证由独立子代理另行承担。

**前置闸门**：R3 approved（`step1/task/review.md`「结论」）；basic 段为空，故本节点前置按 `flow.md`「impl/detail」节取 R3 approved。

## 实际改动

**两个源文件、一个测试文件、四个 fixture。四条任务全部落地。**

### T-D1 — 元字符判定改为引号感知

`verify.go`：`CheckAllowed` 的 `strings.Contains` 改为新增的 `containsUnquoted`。该函数逐字符跟踪引号状态，**只在引号外的位置匹配**，引号跟踪形态与 `splitPipeline`、`splitWords` 一致，未新写第二套引号规则。

### T-D2 — 新增 `CheckTransportable`，命中致坏条件即拒绝

`verify.go`：新增常量 `untransportable = "*?[]{}()"` 与函数 `CheckTransportable`，**与 `CheckAllowed` 并列、未合并**。按 `splitStage` 分词后的 **argv 元素**判定，元素同时含反斜杠与该集合任一字符时拒绝。

`run.go`：`VerifyLine` 在 `CheckAllowed` 之后调用它。

**拒绝信息含三要素**：`无法可靠执行`、触发的 argv 元素与字符、处置为手工实跑。

### T-D3 — 表格行内的 `\|` 还原

`verify.go`：新增 `unescapeTableRow`，`ParseAssertion` 入口处调用。行首（去空白后）为 `|` 时判为表格行，该行内 `\|` 全部还原为 `|`；**非表格行一字不动**。

### T-D4 — 提前返回时回收已启动的子进程

`run.go`：`runPipeline` 的启动循环记录已启动数，任一 `Start` 失败即调用新增的 `killStarted` 终止并回收。**未引入超时**（`design.md` 决策六）。

### 新增的测试与 fixture

| 文件 | 内容 |
| --- | --- |
| `internal/themis/escape_test.go` | `TestQuotedMetacharacterNotShellSyntax`、`TestUnsafeArgRule`（`16` 个子用例）、`TestUnsafeArgRuleMessage`、`TestTableEscape` |
| `testdata/patterns.txt` | 固定样本，`5` 行有效内容；**不依赖会变动的控制面文件** |
| `testdata/safe-args.md` | `5` 条须放行的断言，含此前被误拒的 `SPEC\>` |
| `testdata/unsafe-args.md` | `4` 条须被拒的断言 |
| `testdata/table-escape.md` | 表格单元格内的断言 + 表格外的同一条 |

## 与批准范围的偏差

### 偏差一：`SPEC-PESC-004` 的判据命令经落地订正（已回填 `specify.md`）

**初稿的 `grep -c '^--- PASS'` 数不到子用例**——`go test -v` 把子用例输出为缩进行，`^` 锚定只匹配顶层测试。落地后该命令实跑得 `2`，而 `16` 个数据点全部通过。

**三种命令的实跑值**：`^--- PASS` → `2`；不锚定 `--- PASS` → `18`；`PASS: TestUnsafeArgRule/` → **`16`**。**取第三种**，恰为数据点数。

**订正的是计数方式，不是断言内容**——仍断言"`16` 个数据点各成子用例且全部通过"。**不是改判据迎合实现**：实现若少写一个数据点，订正后的命令立刻得 `15`。**已回填 `specify.md` 并记为第 `37` 次同型实发。**

### 偏差二：`TestUnsafeArgRuleMessage` 是任务文件未列出的第四个测试

T-D2 的任务文本要求拒绝信息含三要素，**但未指名一个测试去验它**。本节点新增该测试。

**判为在批准范围内**：它验的正是 `design.md` 决策三已定的内容，未引入任何 `design.md` 未定的结构。**如实记明，供 R3 已批准范围的复核。**

### 偏差三：verify/detail 给出 `passed` **之后**，实现者又改了一处 fixture

**独立验证报出：`SPEC-PESC-005` 的挂起判据在改动前也不是 `124`，落入了"证不出该 step 做了什么"的形态。** 核实**属实**——初版 `table-escape.md` 用的是 `grep -c`，而挂起需要 `grep -r`（递归 grep 在下一阶段未启动时会转为读标准输入）。

**处置**：`table-escape.md` 增一条以 `grep -rl` 取文件数、再经表格转义的管道交给 `wc -l` 的断言（值 `4`），即挂起的复现形态。

**改后的前后对照，本节点实跑**：取 `HEAD` 的两份源文件另建旧版，对同一 fixture 跑 `timeout 25`——**旧版被超时杀掉（`exit status 143`），新版退出码 `0`**。**判据自此能证出改动做了什么。**

**该改动使 verify/detail 结论 stale**（`flow.md` impl/detail 节失效波及）。**六条判据已由实现者复跑，值与验证角色所得一致**；受影响的是 fixture 内容与验证工件中对它的引用。**是否需要重新验证，交人工验收裁定。**

### 无其他偏差

四条任务的落点、形态、内容均在 R3 批准范围内。**未改动任何既有工件**——`git status --short -- .themis/workspace/spec` 除本实例外为空。**未增删白名单命令，未移除任何元字符。**

## 命令记录

**改动面**：

- `git status --short` → `internal/themis/verify.go`、`internal/themis/run.go` 两份 ` M`；`escape_test.go` 与四个 testdata 文件为新增
- 既有工件改动：`git status --short -- .themis/workspace/spec | grep -v 'pipe-escape-handling' | wc -l` → `0`

**六条判据落地后实跑**（`004` 用订正后的命令）：

- `SPEC-PESC-001`：`go run ./cmd/themis verify internal/themis/testdata/unsafe-args.md 2>&1 | grep -c '无法可靠执行'` → `4`（判据 `≥1`，落地前 `0`）
- `SPEC-PESC-002`：`go run ./cmd/themis verify internal/themis/testdata/safe-args.md 2>&1 | wc -l` → `0`（判据 `0`，落地前 `2`）
- `SPEC-PESC-003`：`go test ./internal/themis/ -run TestQuotedMetacharacterNotShellSyntax -v -count=1 2>&1 | grep -c '^--- PASS'` → `1`（判据 `≥1`，落地前 `0`）
- `SPEC-PESC-004`：`go test ./internal/themis/ -run TestUnsafeArgRule -v -count=1 2>&1 | grep -c 'PASS: TestUnsafeArgRule/'` → `16`（判据 `≥16`，落地前 `0`）
- `SPEC-PESC-005a`：`go run ./cmd/themis verify internal/themis/testdata/table-escape.md 2>&1 | wc -l` → `0`（判据 `0`，落地前 `2`）
- `SPEC-PESC-005b`：`go test ./internal/themis/ -run TestTableEscape -v -count=1 2>&1 | grep -c '^--- PASS'` → `1`（判据 `≥1`，落地前 `0`）
- `SPEC-PESC-006a`：`go test ./... 2>&1 | grep -c '^FAIL'` → `0`
- `SPEC-PESC-006b`：`git status --short -- .themis/workspace/spec | grep -v 'pipe-escape-handling' | wc -l` → `0`

**挂起复核**（`SPEC-PESC-005` 取不到判据记法的那半）：

- `timeout 25 go run ./cmd/themis verify internal/themis/testdata/table-escape.md >/dev/null 2>&1; echo $?` → **`0`**（不得为 `124`；落地前该形态触发 `124`）

**真实工件抽验一份**（`2026-08-28-citation-overlap-check/step1/verify/detail.md`）：

- 该文件此前含表格断言，现可完整跑完，退出码 `0`（工具自身正常退出）
- 报出两条拒绝，**逐条核过均为正确拒绝**：`go test … 2>&1 | …` 的 `>` 在**引号外**，是本包不解释的真 shell 语法；`themis overlap …` 的 `themis` 本就不在只读白名单
