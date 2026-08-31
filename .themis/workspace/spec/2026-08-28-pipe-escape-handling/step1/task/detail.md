# task/detail.md — 2026-08-28-pipe-escape-handling / step1

> 本文件是详细设计 + 任务节点的实例工件。任务只做分解与依赖声明，**不得引入 `design.md` 未定的结构**（`rules.md` §6）。以上只指向位置，本文件不复述其文字。

## 有序任务

### T-D1 — 元字符判定改为引号感知

**依赖**：无。

**落点**：`internal/themis/verify.go` 的 `CheckAllowed`（现第 `152` 行以 `strings.Contains` 在整串上匹配）。

**改法**：只在**引号外**的位置匹配 `shellMetacharacters`。**复用 `run.go` `splitWords` 已有的引号跟踪逻辑，不新写第二套引号规则**（`design.md` 决策四）——所需的"某位置是否在引号内"辅助函数折进本任务，理由见 `task/basic.md` 末节。

**对应判据**：`SPEC-PESC-003`（`go test -run TestQuotedMetacharacterNotShellSyntax -v` 的 `--- PASS` 计数 `≥1`，落地前 `0`）。

**测试须至少覆盖**：`SPEC\>` 放行（当前被误拒）；`grep x f \| rm -rf y` 中引号外的 `>`／`;`／`&` 仍被拒（**安全边界不得放宽**）。

**不得做**：不得增删白名单命令；不得移除任何一个元字符；不得让引号外的元字符逃逸。

### T-D2 — 新增传输可靠性判定，命中即显式拒绝

**依赖**：无（与 T-D1 同文件但不同函数，互不影响）。

**落点**：`internal/themis/verify.go` 新增函数，**与 `CheckAllowed` 并列而非合并**（`design.md` 决策一）。

**判定对象**：**分词后的 argv 元素**，不是原始命令串（决策一）。

**规则**：某 argv 元素同时含反斜杠与 `*` `?` `[` `]` `{` `}` `(` `)` 之一时判为不可靠（决策二）。**两个字符集写死，不做可配置。**

**拒绝信息**：须含 `无法可靠执行`，并指出**哪个 argv 元素**、**触发的是哪个字符**、**处置是手工实跑**（决策三）。

**对应判据**：`SPEC-PESC-001`（fixture 经工具跑出 `无法可靠执行` 计数 `≥1`，落地前 `0`）、`SPEC-PESC-004`（`TestUnsafeArgRule` 的 `--- PASS` 计数 `≥16`，落地前 `0`）、`SPEC-PESC-002`（safe fixture 输出行数 `0`，落地前 `2`）。

**须新建两个 fixture**：`internal/themis/testdata/unsafe-args.md`（命中致坏条件的模式）与 `testdata/safe-args.md`（**至少含 `SPEC`、`\<SPEC`、`S\|P`、`SPEC*` 四条已证正常的，加 `SPEC\>`**）。

**`TestUnsafeArgRule` 须以表驱动覆盖 `scope.md` 事实（1）的全部 `16` 个数据点**，每点一个子用例。

**不得做**：不得把该判定合并进 `CheckAllowed`；不得按原始命令串判（会误拒）；不得把 `16` 点写成一个用例（判据要求 `≥16` 个 `--- PASS`）。

### T-D3 — 表格行内的 `\|` 还原为 `|`

**依赖**：无。

**落点**：`internal/themis/verify.go` 的 `ParseAssertion`，在取反引号片段之前。

**改法**：行首（去空白后）为 `|` 时判为表格行，该行内所有 `\|` 还原为 `|`，再走既有解析（`design.md` 决策五）。

**对应判据**：`SPEC-PESC-005` 前半（table-escape fixture 输出行数 `0`，落地前 `2`）。

**须新建 fixture**：`internal/themis/testdata/table-escape.md`，含**断言形态写在表格单元格内、管道按表格规则转义**的用例。

**测试**：`TestTableEscape`，`--- PASS` 计数 `≥1`。

**不得做**：**不得改动任何既有工件的那 `27` 条断言**——改的是工具读法（`design.md` 取舍一）；非表格行不得做任何还原。

### T-D4 — 提前返回时终止并回收已启动的子进程

**依赖**：无。

**落点**：`internal/themis/run.go` 的 `runPipeline`（现第 `144`–`156` 行先全部 `Start` 再按序 `Wait`）。

**改法**：任何提前返回的路径先终止并回收已启动的进程（`design.md` 决策六）。

**对应判据**：`SPEC-PESC-005` 的挂起复核——`timeout 25 go run ./cmd/themis verify …; echo $?` **不得为 `124`**。**该项取不到判据记法**（退出码不是 stdout），**验证节点须单独实跑并记录**。

**不得做**：**不得引入超时**（决策六——超时会把"命令本来就慢"与"卡死"混为一谈，且时长常量定不对）。

## 判据到任务的映射

| 判据 | 承担任务 |
| --- | --- |
| `SPEC-PESC-001` 命中即拒 | T-D2 |
| `SPEC-PESC-002` 不误拒不算错 | T-D1、T-D2 |
| `SPEC-PESC-003` 引号内元字符不判 shell 语法 | T-D1 |
| `SPEC-PESC-004` 规则被 `16` 点测试固定 | T-D2 |
| `SPEC-PESC-005` 表格转义不失败不挂起 | T-D3（不失败）、T-D4（不挂起） |
| `SPEC-PESC-006` [横切] 防回归 | 四条共同不得违反 |

**反向：无多余任务**——四条各有判据承担。**与 `2026-08-29-product-judge` 的 T-D2 无判据不同，本 step 不存在无判据的交付物。**
