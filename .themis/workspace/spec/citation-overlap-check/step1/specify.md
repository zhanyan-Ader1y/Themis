# specify.md — citation-overlap-check / step1

> 本文件是抽象设计（specify）节点的实例工件。本节点的前置闸门与产出见 `flow.md`「抽象设计（specify）」节；`[basic]` 见 `rules.md` §5，`[横切]` 见 §12。以上只指向位置，本文件不复述其文字。
>
> **本文件的判据一律按 `template.md`「断言形态」记法书写，并由本节点当场实跑。**

## 行为条目

### SPEC-OVERLAP-001 [basic]

`themis` CLI 必须有一个检出引用重复的子命令。

**验收判据**：

`go test ./internal/themis/... -run TestOverlapCommand -v | grep -c '^--- PASS'` → `≥1`

**依据**：`scope.md` 事实（3）——shell 实现实测超时，Go 进程内比对是唯一可行做法。

**本条带 `[basic]` 标识**：它建立的是"该子命令存在"这一契约存在性，验收方式是结构性断言。**与 `SPEC-CLAIMCLI-001` 同形。**

### SPEC-OVERLAP-002

检出必须把每处匹配**延长到极大**后再去重，而非报告所有定长窗口。

**验收判据**：

`go test ./internal/themis/... -run TestMaximalExtension -v | grep -c '^--- PASS'` → `≥1`

**依据**：`scope.md` 事实（1）——`153` 处 vs `26` 处。**这一条决定工具可用与否**：定长窗口的输出里，同一句话会以几十个错位片段反复出现。

### SPEC-OVERLAP-003

检出必须能排除正当重合，且**排除规则本身可被调用者看见**。

**验收判据**：

`go test ./internal/themis/... -run TestLegitimateOverlap -v | grep -c '^--- PASS'` → `≥1`

**依据**：`scope.md` 事实（2）——三种稳定形态，粗过滤后余 `4` 处全是散文句。

**"可被看见"不可省**：排除规则若藏在代码里，被误排除的违规**无人能发现**——那正是本需求要治的失效（自动核验的盲区），不能用新的盲区去补旧的盲区。

### SPEC-OVERLAP-004

检出**只标出，不拦截**——退出码不因发现重合而非零。

**验收判据**：

`go test ./internal/themis/... -run TestOverlapExitCode -v | grep -c '^--- PASS'` → `≥1`

**依据**：`hard-enforcement-list.md` 第 2 项原文即定"标出供人工复核"；R1 已确认。**另一条依据**：正当重合无法零误报，自动拦截会把它变成硬阻塞，而 `trace-number-scan` 已确立教训——误报率高的检查会训练执行者忽略它。

### SPEC-OVERLAP-005 [横切]

改动不得使 `verify` 子命令的既有行为改变。

**验收判据**：

`go test ./internal/themis/... 2>&1 | grep -c '^FAIL'` → `0`

**依据**：防回归。`verify` 与新子命令共处同一包，**新增解析或工具函数可能误改既有路径**。

**本条带 `[横切]` 标识**：它验证的是 `verify` 既有行为不被扰动，那不是本 step 的产出。

## 来源覆盖

| 条目 | 覆盖的达成状态 | 事实来源 |
| --- | --- | --- |
| 001 | 子命令存在 | 代码#`scope.md` 事实（3）shell 实测超时 |
| 002 | 降噪（极大延长） | 代码#`scope.md` 事实（1）153→26 实测 |
| 003 | 排除正当重合且规则可见 | 代码#`scope.md` 事实（2）三形态与粗过滤实测 |
| 004 | 标出不拦截 | 代码#`hard-enforcement-list.md` 第 2 项；用户确认#R1 |
| 005 | 防回归（横切保护，非达成状态之一） | 代码#`internal/themis/` 现有测试 |

**`[basic]` 标识：001 一条带。** 依 §5，它建立契约存在性而非行为，验收用结构性断言。其余四条是行为条目。

## 本节点标出、须 R2 判定的一处

**判据 001–004 全部形如 `go test … | grep -c '^--- PASS'`，而 `go` 不在 CLI 白名单内。**

**这是已知处境，不是新问题**：`claim-command-evidence` step2 的四条判据同此，所有者已裁定"不放行 `go`，判据改由人工判"。

**本节点依 `flow.md` R2 节新增的交叉核查要求主动列出**（见 `scope.md`「会触及或放宽的既有裁定」）：**本 step 的判据与既有白名单裁定确实冲突，处置照旧——人工判，不重新提出裁定。**

**R2 须确认这一处置成立**。若 R2 认为应另作处置，本节点的判据须重写。

**须记明的是**：这是 `flow.md` 那条交叉核查**第一次真正生效**——它由上一个需求（`question-eligibility`）补入，本 step 是第一个受其约束的实例。**上次正是因为没有这条，`go` 冲突拖到落地才发现。**
