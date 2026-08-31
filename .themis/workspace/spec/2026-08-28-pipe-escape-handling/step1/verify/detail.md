# verify/detail.md — 2026-08-28-pipe-escape-handling / step1

> 本文件是 verify/detail 节点的实例工件。本节点的前置闸门、产出与取值条件见 `flow.md`「verify/detail」节；判据、判定者与断言范围见 `rules.md` §7，追溯链检出见 §12。以上只指向位置，本文件不复述其文字。
>
> **本文件的每个数字与存在性断言都记明了产出它的那条命令。判据命令含 `go` 与 `timeout`，两者不在只读白名单，故 `themis verify` 跑不了它们——人工实跑，与 `specify.md` 首注一致。**
>
> **探针纪律**：本节点自建的探针文件一律经 Write 工具落盘，期望值取自 bash 变量展开的直跑（`p='模式'; grep -c "$p" 文件`），发布前以 `cat -A` 核过反斜杠确实在文件里。

## 执行身份

**独立子代理。** 与 impl/detail 的执行者（主会话）不是同一身份。

**冷启动**：本节点未接收主会话的任何推理，只读仓库工件与自行实跑的命令。`impl/detail.md` 的自述被当作待核对象，其八条落地后实跑值本节点逐条重跑，未照抄。

**工作树**：仓库根 `C:\Coding\Themis`，分支 `main`，无 worktree。本节点未创建分支、未提交、未 push，除本文件外未改动仓库内任何文件。

## 断言与实际结果

### 六条判据

| 判据 | 命令（判据原文） | 判据要求 | 本节点实跑 | 结果 |
| --- | --- | --- | --- | --- |
| `SPEC-PESC-001` | `go run ./cmd/themis verify internal/themis/testdata/unsafe-args.md 2>&1 \| grep -c '无法可靠执行'` | `≥1` | `4` | 满足 |
| `SPEC-PESC-002` | `go run ./cmd/themis verify internal/themis/testdata/safe-args.md 2>&1 \| wc -l` | `0` | `0` | 满足 |
| `SPEC-PESC-003` | `go test ./internal/themis/ -run TestQuotedMetacharacterNotShellSyntax -v -count=1 2>&1 \| grep -c '^--- PASS'` | `≥1` | `1` | 满足 |
| `SPEC-PESC-004` | `go test ./internal/themis/ -run TestUnsafeArgRule -v -count=1 2>&1 \| grep -c 'PASS: TestUnsafeArgRule/'` | `≥16` | `16` | 满足 |
| `SPEC-PESC-005a` | `go run ./cmd/themis verify internal/themis/testdata/table-escape.md 2>&1 \| wc -l` | `0` | `0` | 满足 |
| `SPEC-PESC-005b` | `go test ./internal/themis/ -run TestTableEscape -v -count=1 2>&1 \| grep -c '^--- PASS'` | `≥1` | `1` | 满足 |
| `SPEC-PESC-005` 挂起复核 | `timeout 25 go run ./cmd/themis verify internal/themis/testdata/table-escape.md >/dev/null 2>&1; echo $?` | 不得为 `124` | `0` | 满足 |
| `SPEC-PESC-006a` | `go test ./... 2>&1 \| grep -c '^FAIL'` | `0` | `0` | 满足 |
| `SPEC-PESC-006b` | `git status --short -- .themis/workspace/spec \| grep -v 'pipe-escape-handling' \| wc -l` | `0` | `0` | 满足 |

**六条判据全部满足，无一未覆盖。**

### 两条判据的非恒真核验（本节点自加，判据未要求）

`SPEC-PESC-002` 与 `SPEC-PESC-005a` 的判据都是「输出行数为 `0`」。**该形态在"文件里一条断言都没被解析到"时同样为 `0`**，故本节点另做变异探针证伪其恒真：把两份 fixture 复制到仓库外并改掉记录值，工具逐条报出不符。

- `safe-args.md` 变异后报出 `5` 条不符，实跑值依次为 `3`、`3`、`6`、`3`、`3`
- `table-escape.md` 变异后报出 `2` 条不符（表格行与表格外的同一条），实跑值均为 `1`
- **这五个值与 bash 直跑值逐一相等**（bash：`SPEC`→`3`、`\<SPEC`→`3`、`S\|P`→`6`、`SPEC*`→`3`、`SPEC\>`→`3`），即 `SPEC-PESC-002`「不得误拒、也不得算错」两半都成立，不只是"没输出"

### 特别要求的六处独立核实

| 核实点 | 本节点结论 |
| --- | --- |
| 一、`SPEC-PESC-004` 判据命令的订正是否正当 | **正当**，见下「一」 |
| 二、`TestUnsafeArgRuleMessage` 是否在批准范围内 | **在范围内**，见下「二」 |
| 三、安全边界是否被放宽 | **未放宽**，见下「三」 |
| 四、`scope.md` 十六点是否被逐点覆盖 | **逐点覆盖，无遗漏**，见下「四」 |
| 五、挂起是否真的没了 | **落地后不挂（`0`）；但"改动前确实会挂"本节点未能独立复现**，见下「五」 |
| 六、取舍一的风险是否发生 | **发生**，报出三处值不符，未改工件，见下「六」 |

#### 一、`SPEC-PESC-004` 的订正改的是计数方式，不是断言内容

三种命令对同一次 `go test` 输出的实跑值：`^--- PASS` → `2`；不锚定的 `--- PASS` → `18`；`PASS: TestUnsafeArgRule/` → `16`。**与 `impl/detail.md` 所记三值一致，本节点重跑得同值。**

**本节点做了实现方未做的消融实验**，以判「实现若少写一个数据点，订正后的命令会不会立刻发现」：把包整份复制到仓库外的临时目录建成独立 module，在副本上——

- **删掉名为 backslash question 的那个数据点行**，订正后的命令得 `15`
- **把名为 plain 的数据点的期望值由 false 改为 true**（该子用例转为 FAIL），订正后的命令同样得 `15`

**两种破坏都被立刻发现。** 且 `PASS: TestUnsafeArgRule/` 不匹配 `TestUnsafeArgRuleMessage`（其后接的是 `Message` 而非 `/`），故第四个测试不虚增该计数。**订正正当。**

#### 二、`TestUnsafeArgRuleMessage` 在 R3 批准范围内

**本节点独立判定，未采信实现方的说法后再复核，而是自行对照三份上游工件：**

- `design.md` 决策三已定「拒绝信息须含 `无法可靠执行`、哪个 argv 元素、哪个字符、处置是手工实跑」；`task/detail.md` T-D2 复述了该要求但未指名测试
- 该测试断言的三项（`无法可靠执行`、`\(SPEC\)`、`手工实跑`）**全部落在决策三字面之内**，未引入 `design.md` 未定的任何结构，故不触 `rules.md` §6
- 它不改变任何判据的取值：`SPEC-PESC-004` 的订正后命令与它无关；它只让 `^--- PASS` 从 `1` 变 `2`，**而那条命令已因订正被弃用**

**判定：在范围内。** 一处如实记明的代价：`^--- PASS` 得 `2` 这个现象，一半由它造成——但这正是订正要解决的计数问题，不是它引入的缺陷。

#### 三、安全边界未被放宽

**本节点不看 `escape_test.go`，另写了一份独立探针**（落在仓库外的包副本里，`independent_probe_test.go`），**二十条引号外的元字符用例逐条要求被拒**，含 `> out.txt`、`>out.txt`、`; ls`、`& ls`、反引号、`$(ls)`、`grep -c 'a'>'b' f.md`（两段引号之间的 `>`）、`| rm -rf y`、`rm -rf y`、`wc -l < f.md > out.txt` 等；另两条为引号未闭合藏元字符（`grep -c 'SPEC f.md > out.txt`）。**全部通过，无一放行。**

**另经真实 CLI 端到端复核**：自建探针 `boundary-probe.md`（Write 落盘）经 `themis verify` 跑，引号外的 `>`、`;`、`&`、`$(` 四条逐条被拒，`out.txt` 未被创建；同文件中引号内含 `>`、`;` 的三条正常放行并跑出真值。

**结论：放宽只发生在引号内，一步也不多**，与 `task/review.md` 裁定一写进 T-D1 的边界约束一致。

#### 四、`scope.md` 十六点被逐点覆盖，无遗漏

本节点以机器对照，不靠肉眼：从 `scope.md` 矩阵逐行抽出第一个反引号片段共 `16` 个模式，逐个到 `escape_test.go` 找 `'模式'` 字面，**`16` 个全部 FOUND，MISSING `0`**。

**预期方向亦逐条对得上**（人工对照矩阵末列与测试 `refuse` 字段）：前六条 `SPEC`、`\<SPEC`、`S\|P`、`\|`、`SPEC*`、`节.*SPEC` 为 `false`（矩阵「好」）；中间九条为 `true`（矩阵「坏」）；第十六条 `SPEC\>` 为 `false`（矩阵「好（另属类二）」）。**无一处对不上。**

**一处须记明的边界**：`TestUnsafeArgRule` 钉的是 `CheckTransportable` 的**分类结论**，**不是矩阵实际测量的那件事**——矩阵测的是「bash 值与工具值是否相等」。**故"这 16 点不许回归"回归的是规则，不是那次测量。** 这不违反 `SPEC-PESC-004` 的字面（「规则必须被测试固定」），但保障范围比矩阵窄，如实记明。

#### 五、落地后不挂；"改动前会挂"本节点未能独立复现

**落地后**：`timeout 25 go run ./cmd/themis verify internal/themis/testdata/table-escape.md >/dev/null 2>&1; echo $?` → `0`，不为 `124`。**判据这一半满足。**

**改动前**：本节点未用 `git stash`，而是把 `HEAD` 的六份源文件经 `git show HEAD:<path>` 取出到仓库外的目录 `C:/Coding/_themis_old` 另建 module 并 `go build`，得到改动前的 `themis-old.exe`。用它跑——

- 同一份 `table-escape.md`：`timeout 25` 退出码 **`1`**（不是 `124`）。输出是一条值不符（`实跑得到 "2"，文件里写的是 "1"`），**没有挂起**
- 仓库内全部 `8` 份"表格行内带转义管道断言"的真实工件，逐份 `timeout 60`：退出码依次为 `1 0 1 0 1 1 1 1`，**无一为 `124`**

**本节点如实报告：做不到——我没能独立确证改动前会挂。** 不假装验过。

**代码层的旁证解释了为什么**：`killStarted` 只在 `cmd.Start()` 失败时被调用（`run.go` 第 `152`–`159` 行）。而 `CheckAllowed` 要求每一段都在白名单内，白名单全部 `15` 个命令在本机 `PATH` 上都存在（`command -v` 逐个查过），**故本机触发不到 Start 失败这条路径**。

**连带的一处如实记明**：`killStarted` **没有任何测试覆盖**——`grep -rn 'killStarted' --include=*.go .` 只有 `run.go` 内的定义与唯一调用点，`grep -rn 'runPipeline' --include=*_test.go .` 无任何命中。**T-D4 的改动是四条任务里唯一既无测试、又未被本节点独立复现前后差异的一条。**

#### 六、取舍一的风险发生了：报出三处值不符，未改工件

按取舍一「如实报出，不改工件」，本节点抽了含表格断言的真实工件跑。**报出的不符**：

- `2026-08-28-citation-overlap-check/step2/verify/detail.md:20` 与 `:51`：`awk '/^## verify\/basic/,/^## impl\/detail/' .themis/spec/flow.md | grep -c 'rules.md.*§7'` **实跑 `2`，文件记 `1`**
- `2026-08-27-trace-number-scan/step1/verify/detail.md:64`：`awk '/^## 编号引用写法/,0' .themis/spec/template.md | grep -cE 'SPEC-|T-D'` **实跑 `4`，文件记 `5`**——**该条与本 step 无关**：`template.md` 已被 `2026-08-29-template-strip-prescriptions` 改写，属工件漂移
- `2026-08-27-claim-command-evidence/step1/verify/detail.md:20`–`:23`（四条，实跑 `0`，文件记 `2`/`2`/`1`/`1`）：**这四条改动前后同值**（改动前的 `themis-old.exe` 报同样四条同样的值），**不是表格还原新暴露的**，成因是断言里写了省略号 `…` 当文件名

**未改动上述任何一份工件。**

## 命令证据

**每条都记明产出它的命令；数字全部为本节点当场实跑，非转录自 `impl/detail.md`。**

**六条判据**（在仓库根实跑，`grep` 模式一律经 bash 变量展开传入）：

- `p='无法可靠执行'; go run ./cmd/themis verify internal/themis/testdata/unsafe-args.md 2>&1 | grep -c "$p"` → `4`
- `go run ./cmd/themis verify internal/themis/testdata/safe-args.md 2>&1 | wc -l` → `0`
- `p='^--- PASS'; go test ./internal/themis/ -run TestQuotedMetacharacterNotShellSyntax -v -count=1 2>&1 | grep -c "$p"` → `1`
- `p='PASS: TestUnsafeArgRule/'; go test ./internal/themis/ -run TestUnsafeArgRule -v -count=1 2>&1 | grep -c "$p"` → `16`
- `go run ./cmd/themis verify internal/themis/testdata/table-escape.md 2>&1 | wc -l` → `0`
- `p='^--- PASS'; go test ./internal/themis/ -run TestTableEscape -v -count=1 2>&1 | grep -c "$p"` → `1`
- `timeout 25 go run ./cmd/themis verify internal/themis/testdata/table-escape.md >/dev/null 2>&1; echo $?` → `0`
- `p='^FAIL'; go test ./... 2>&1 | grep -c "$p"` → `0`
- `git status --short -- .themis/workspace/spec | grep -v 'pipe-escape-handling' | wc -l` → `0`

**改动面**（`git status --short`）：`internal/themis/run.go` 与 `internal/themis/verify.go` 两份 ` M`；`internal/themis/escape_test.go` 与 `internal/themis/testdata/` 下 `patterns.txt`、`safe-args.md`、`table-escape.md`、`unsafe-args.md` 四份为 `??`。**`.themis/workspace/spec` 下的 ` M`／`??` 全部落在 `2026-08-28-pipe-escape-handling` 实例内**（`Intent.md`、`QA.md`、`intent-review.md` 的改动是 R1 第 2 轮的增量，`git diff` 逐段读过，非改证据）。

**订正正当性的消融实验**（在仓库外副本 `C:/Coding/_themis_verify_tmp` 上做，仓库内文件未动）：

- 建副本：`cp internal/themis/*.go <副本>/; cp -r internal/themis/testdata <副本>/`，副本内 `printf 'module themisablation\n\ngo 1.21\n' > go.mod`
- 删一个数据点：`sed -i '69d' <副本>/escape_test.go`，`p='backslash question'; grep -c "$p" <副本>/escape_test.go` → `0`；随后 `p='PASS: TestUnsafeArgRule/'; go test . -run TestUnsafeArgRule -v -count=1 2>&1 | grep -c "$p"` → `15`
- 改错一个期望值：`plain` 行 `false`→`true`，同一计数命令 → `15`

**安全边界探针**：`independent_probe_test.go` 经 Write 落盘于副本，`go test . -run TestProbeUnquotedMetacharactersStillRefused -v -count=1` → `--- PASS`，`22` 条须拒用例无一放行、`6` 条须放行用例无一误拒。真实 CLI 探针 `boundary-probe.md` 经 Write 落盘于仓库外，`themis verify` 报出 `>`、`;`、`&`、`$(` 四条拒绝，`ls out.txt` → `No such file or directory`。

**十六点覆盖对照**：`awk '/^\| \`/ {print}' <scope.md> | awk -F'\`' '{print $2}'` 抽出 `16` 个模式（`wc -l` → `16`），逐个 `grep -qF "'<模式>'" internal/themis/escape_test.go`，MISSING 计数 → `0`。

**改动前基线**：`for f in cmd/themis/main.go go.mod internal/themis/cli/cli.go internal/themis/overlap.go internal/themis/run.go internal/themis/verify.go; do git show "HEAD:$f" > <旧目录>/$f; done`，`go build ./...` 成功；`go build -o <旧目录>/themis-old.exe ./cmd/themis`。旧版对 `table-escape.md`：`timeout 25 ... ; echo $?` → `1`。旧版对 `8` 份真实工件：退出码 `1 0 1 0 1 1 1 1`。

**传输规则精度实测**（见「说明」第一条）：

- 致坏确有其事：`f=internal/themis/testdata/patterns.txt; for p in '\(SPEC\)' 'S\{1\}PEC' 'S\|P.*E'; do grep -c "$p" "$f"; done` → `3`、`3`、`6`；同三条经旧版工具（无传输判定）分别得 `1`、`1`、`0`
- 过拒确有其事：`2026-08-27-question-eligibility/step1/verify/detail.md:29` 的命令，bash 直跑（`eval` 自工件抽出的原文）→ `3`，工件记 `3`，旧版工具亦无不符；`2026-08-28-gate-value-integrity/step1/verify/detail.md:53` → bash `0`／记 `0`；`2026-08-27-trace-number-scan/step1/verify/detail.md:29`、`:63`、`:65` → bash `3`／`1`／`3`，记 `3`／`1`／`3`。**五条经新版一律被 `CheckTransportable` 拒绝**

**追溯链检出（`rules.md` §12）**：

- `p='SPEC-PESC-[0-9][0-9][0-9]'; grep -o "$p" specify.md | sort -u` → `001`–`006` 共 `6` 条
- 同一命令对 `task/detail.md` → `001`–`006` 共 `6` 条
- 两份编号清单经 comm -23 取差集（上游减任务），输出为空，其行数为 `0`
- `SPEC-PESC-006` 带 `[横切]` 标识（`q='SPEC-PESC-006 \[横切\]'; grep -c "$q" specify.md` → `1`），按 §12 本不计入上游集合；**即便计入，差集仍为 `0`**

## 结论

**passed。**

**依据**：`specify.md` 六条判据、九条判据命令（含 `005` 的挂起复核）**全部由本节点实跑并满足**，无一条未覆盖、无一条以放宽阈值或改写命令的方式满足。追溯链差集为 `0`。安全边界经两套独立探针（包内、CLI 端到端）确认未放宽。`scope.md` 十六点经机器对照逐点覆盖。

**说明小节报出的三类问题不构成 `failed`**，理由逐条记于下节。

## 说明

### 一、传输可靠性规则过拒了至少 `5` 条真实断言——本节点新发现，`scope.md` 事实（2）被实测部分反驳

**事实**：`CheckTransportable` 现在拒绝的下列五条真实断言，**改动前的工具跑它们得到的值与 bash 完全一致**，即这些参数其实传输正常：

`question-eligibility/step1/verify/detail.md:29`、`gate-value-integrity/step1/verify/detail.md:53`、`trace-number-scan/step1/verify/detail.md:29`、`:63`、`:65`。

**共同形态**：致坏字符是被反斜杠转义的 `\*`，而非矩阵里那些裸的 `(`、`)`、`{`、`}`、`[`。**矩阵的 `16` 个取样点里没有一个是 `\*` 形态**，规则因此把这一形态一并划进了致坏集合。

**这反驳了 `scope.md` 事实（2）的一句话**：「当前有 `48` 条既有断言，经 `themis verify` 复跑会得到错值」。**至少 `5` 条不会**——旧版工具算对了它们。该句是上游 step 定界节点的断言，本节点不改它，如实报出。

**为什么仍判 `passed`**：

- `SPEC-PESC-002` 的**判据**是 `safe-args.md` 输出 `0` 行，已满足且经变异证伪非恒真；其行为陈述里的「误拒」以「未命中致坏条件」为界，而这五条按 `design.md` 决策二的字面**确实命中**——**规则本身偏严，不是实现偏离了规则**
- `scope.md` 已明写「`16` 点拟合不等于规则正确」，`specify.md`「须 R2 判定的第二处」把这一点单列并由 R2 知情批准，`task/review.md`「本次批准未覆盖」第 `3` 条再次记明。**这是已被上游知情接受的强度边界，不是本节点新发现的越界**

**本节点仍要把它记在这里**，因为 (b) 相对 (a) 的全部价值是「少拒 `27` 条」，而实测显示这笔账比 `scope.md` 记的要小。**这是后续需求的输入，不是本 step 的失败。**

### 二、`killStarted` 无测试覆盖，且本节点未能确证它修好了什么

见「五」。**判据 `SPEC-PESC-005` 的挂起复核只要求"不得为 `124`"，落地后为 `0`，字面满足**；但该判据在改动前于本机也不为 `124`，**故它证不出 T-D4 做了什么**——正是 `specify.md` 首注要规避的那种形态（`SPEC-PJUDGE-003` 恒为 `14`），本条在本机上事实上落入了该形态。

**不判 `failed` 的理由**：`scope.md` 事实（4）记的复现是 step 定界节点当场跑出的，**本节点无法证伪一次别人在别的时刻跑出的复现**——它可能依赖当时的探针形态或当时的 `PATH`。**判据本身满足，改动本身无害**（`killStarted` 只在错误路径上执行，正常路径不经过它），**且 `go test ./...` 无回归**。

**如实记明供后续闸门取用**：若要让 T-D4 可证，须补一个直接调用 `runPipeline` 且第二段命令必然 Start 失败的测试——本节点未补，因为不改被测文件。

### 三、表格还原后跑出与记录不符的三处，未改工件

见「六」。**按 `design.md` 取舍一与 R1 两轮确认的「不改既有工件」，本节点只报出、不改。** 其中 `trace-number-scan:64` 的成因在另一个需求（`template.md` 已被改写），`claim-command-evidence:20`–`:23` 改动前后同值、非本次新暴露；**真正由表格还原新变得可跑并暴露不符的是 `citation-overlap-check/step2` 的两条（`2` vs `1`）**。

### 四、本节点未做、须记明的边界

- **未对 `.themis/workspace/spec` 全量工件复跑**，只跑了含表格转义断言的 `8` 份加 `1` 份抽验。**全量复跑是 `intent-review.md` 第 1 轮提出、取舍二明确不做的事**，本节点不擅自扩范围
- **未验证致坏规则在别的平台上成立**——本节点全部实跑在 Windows 的 Git Bash 上，与 `scope.md` 同一环境
- **本节点建立的仓库外临时目录**（`C:/Coding/_themis_verify_tmp`、`C:/Coding/_themis_old`、`C:/Coding/_themis_new.exe`）**已删除**，其重建步骤已完整记于「命令证据」，任何人可复跑
