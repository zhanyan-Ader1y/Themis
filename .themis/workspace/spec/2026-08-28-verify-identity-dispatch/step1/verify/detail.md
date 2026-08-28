# verify/detail.md — 2026-08-28-verify-identity-dispatch / step1

> 本文件是 verify/detail 节点的实例工件。本节点的前置闸门、产出、失效波及与失败去向见 `flow.md`「verify/detail」节；断言范围、身份独立要求与拒绝条件见 `rules.md` §7，孤儿判定见 §8，追溯链环 2、3 见 §12；五个小节的固定划分见 `template.md`。以上各处只指向位置，本文件不复述其文字。
>
> **本文件里的每个数字与每条存在性断言，都由本节点当场跑命令得出。** `impl/detail.md`「命令记录」里的任何数字都**没有**被搬进本文件——该文件在此只是**被核验的对象**，其自述不作为证据。

## 执行身份

- **身份**：Claude Opus 5（模型标识 `claude-opus-5`），作为**由主会话派发的独立子代理**运行，承担本 step 的 verify/detail 节点。工作树为 `C:/Coding/Themis` 主工作树，分支 `main`；本次会话开始时 HEAD 为 `f0a8974`（命令 V1）。
- **与 `impl/detail.md`「执行身份」比对的结果：不相同——身份独立成立。** 对方那栏记的是"本次 spec 流程执行者会话"、动手前 HEAD `3034289`、授权来源 R3 approved；本栏是另一次会话，角色是被派发的验证者，起始 HEAD 已是 `f0a8974`。**派发关系、会话、起始 HEAD、承担节点四项都不同。** 对方那栏明写"本节点不承担 verify/detail"与"`verify/detail.md` 的内容不由本会话撰写"——本文件确由本次被派发的会话撰写，未被代写。
- **本栏能自证到哪一步**：本次会话在写下本文件之前，对 `.themis/spec/flow.md`、`.themis/spec/rules.md` 及本实例下任何其他工件**没有做过任何写操作**；本次会话对仓库的全部动作是读取、运行只读命令、以及构建 `/tmp/themis.exe`（构建产物在仓库外）。**核验不动的地方如实写在「说明」第 1 条**：两栏的模型标识相同，且当前没有任何机器签名把"两次会话"固定下来；本条独立性成立于控制面指定的比对方式（两处「执行身份」小节一比即得），不是密码学证明。
- **本文件的所有者**：验证角色。五条判据的结论、孤儿判定与环 2、3 结论只写在本文件，未写进任何实现者所有的工件。

## 断言与实际结果

A 组是 `specify.md` 五条判据的逐条断言，五条全在，未合并、未省略；B 组是孤儿判定；C 组是追溯链环 2、3。

### A 组 — `specify.md` 五条验收判据

#### 断言 1 — `SPEC-VDISP-001`

- **判据要求**：对 `flow.md` 数「独立子代理」的命中数，须 `≥2`。
- **实跑**：命令 V2 → `2`。
- **命中位置逐条核实**（不只看计数）：命令 V3a、V3b 显示两处命中分别位于第 `164` 行（verify/basic 节）与第 `190` 行（verify/detail 节）。**两处分属两个 verify 节点**，非同节点内重复计数。两处原文均含「验证角色由独立子代理承担」。
- **判定：满足。**

#### 断言 2 — `SPEC-VDISP-002`

- **判据要求**：对 `flow.md` 数「未由独立子代理承担」的命中数，须 `≥1`。
- **实跑**：命令 V4 → `2`。
- **命中位置**：命令 V5a、V5b 显示两处命中位于第 `164`、`190` 行，同样分属两个 verify 节点。
- **语义部分（R2 已定由本节点如实记录实际文本）**：两处的完整拦截句式为——「**未由独立子代理承担时，本节点不得给出结论**——`state.md` 该行取 `进行中`，流程停在 impl（/impl/detail）节点。**不设"记明理由即可放行"的出路。**」。三要素齐备：(a) 禁止的是**给出结论**这一动作本身，不是事后判结论无效；(b) 指定了替代取值 `进行中` 与停靠位置，未留"取什么值"的空白；(c) 明文否定了"记明理由即可放行"。命令 V6、V7 显示该短语在 `flow.md` 命中 `2` 处、在 `rules.md` 命中 `0` 处，且 `flow.md` 两处**均为否定形式**——全控制面不存在肯定形态的该出路。verify/basic 节另有一句写明拦截点位置的理由（「拦截点在动作发生前，不在结论写出后」）。
- **判定：满足。**

#### 断言 3 — `SPEC-VDISP-003`

- **判据要求**：在 `rules.md` §7 区间内数「交接」的命中数，须 `≥1`。
- **实跑**：命令 V8 → `2`。
- **四项最小集逐项核实**（判据要求的是"规定了最小集"，计数不足以证明四项都在，故另行读取）：§7 内「**交接的最小集，四项缺一不可**」（命令 V9 → `1`）下的编号列表为 1. 验哪些判据 2. 工件在哪 3. 在哪个工作树或分支上操作 4. 结论写进哪个文件——**与判据点名的四项逐项对应，无缺项**。§7 另写明四项的事故来源（子代理把提交打到 `main`，缺的正是第三项）与"四项不是穷举"。
- **本次派发的交接实测**：本次会话收到的交接**确实含全部四项**——验哪些判据（`SPEC-VDISP-001` 至 `005` 五条，并指明是 verify/detail 节点）、工件在哪（实例目录与 step1 路径）、在哪操作（`C:/Coding/Themis` 主工作树 `main` 分支，且明确不切分支、不提交）、结论写进哪个文件（`step1/verify/detail.md`）。**这是四项作为最小集的一次实际消费，非仅文本存在。**
- **判定：满足。**

#### 断言 4 — `SPEC-VDISP-004`

- **判据要求**：`step1/verify/detail.md` 的「执行身份」小节记明其为独立子代理，且与 `impl/detail.md` 不同。
- **实跑与实际结果**：本文件即 `step1/verify/detail.md`，其「执行身份」小节已记明：撰写者为主会话派发的独立子代理，起始 HEAD `f0a8974`，与 `impl/detail.md` 所记的执行者会话（HEAD `3034289`、承担 impl/detail）在派发关系、会话、起始 HEAD、承担节点四项上均不同。**判据所要求的存在性与差异性两项均成立。**
- **本条的循环如实标出（R2 已裁定接受，要求如实记明）**：本条由**验证节点自己**给出，而验证节点正是被约束的对象——该循环无法在本 step 内消除。**本节点能如实说明的强度到此为止**：写下"我是独立子代理"这句话的这次会话，确实不是写 `impl/detail.md` 的那次会话；本次会话在写本文件前对本实例的任何工件均无写操作（见「执行身份」第三条）。**本节点不主张该证据强于此**，也不主张它构成对未来违例的拦截。
- **判定：满足**（在上述如实标明的循环之下）。

#### 断言 5 — `SPEC-VDISP-005` `[横切]`

- **判据要求（第一条）**：在 `rules.md` §7 区间内数「结构存在、可构建」的命中数，须为 `1`。
- **实跑**：命令 V10 → `1`。
- **另行核实 §7 既有内容未被改动**（判据要求的是"不得改变 §7 现有的三项 basic 判据与 detail 断言范围"，计数只能证该句仍在，故另读 diff）：命令 V13 显示 `rules.md` 的改动为**新增 13 行、删除 0 行**——全部为新增，无删除行、无修改行；新增块位于「两次验证均无人工节点」之后、「verify/basic 在 basic 段为空时结论取 `不适用`」之前。**§7 的「判据」「拒绝条件」「判定者」三段一字未动**，三项 basic 判据与 detail 断言范围原样保留。
- **判据要求（第二条）**：全仓 `go test ./...` 输出中 `^FAIL` 的行数，须为 `0`。
- **实跑**：命令 V11 → `0`。命令 V12 显示 `^ok` 计 `12` 行，命令 V12b 显示另有 `2` 个包为 `[no test files]`，无 `FAIL`、无 `build failed`。
- **既有工件未失效的旁证**：命令 V15、V16 显示本次改动共涉 `2` 份文件、其中 `.go` 文件 `0` 份，即仅 `.themis/spec/flow.md` 与 `.themis/spec/rules.md` 两份控制面文件，**未触及任何既有实例工件**；四份控制面文件的 `themis verify` 报告数各为 `0`（命令 V24–V27），`themis overlap .themis/spec/` 未发现需人工复核的重合片段（命令 V28）。
- **判定：满足。**

### B 组 — 孤儿阻断判定（`rules.md` §8）

- **上游自述**：`task/basic.md`「基础任务」段原文为「**无。本段为空。**」，指向 `design.md`「basic/detail 分段」为判定依据。
- **本节点自行做出的代码层断言**（§8 拒绝条件明令不得以上游自述判空）：命令 V13、V14、V15、V16 显示本 step 的全部落地改动为 `.themis/spec/flow.md`（新增 6 行）与 `.themis/spec/rules.md`（新增 13 行），共 `2` 份文件，**其中 `.go` 文件 `0` 份**——均为 Markdown 控制面文本，无任何代码模块新增。既然本 step 未落地任何 basic 改动，**不存在"已落地但无消费者"的 basic 改动**。
- **判定：无孤儿。不阻断人工验收。**

### C 组 — 追溯链环 2、3（`rules.md` §12）

#### 环 2 — `specify.md` → `task/detail.md`

- **上游集合**（`### SPEC-` 条目，**按 §12 排除 `[横切]`**）：命令 V17 → `5` 条；命令 V18 → 其中 `1` 条带 `[横切]` 标识（`SPEC-VDISP-005`），**不计入上游集合**；命令 V19 → 上游为 `SPEC-VDISP-001`、`002`、`003`、`004`，基数 `4`。
- **下游集合**（`task/detail.md` 中出现的编号，按三种写法展开）：原样命中为 `SPEC-VDISP-001、002`（**逗号并列**，裸数字继承前缀，展开为 `001` 与 `002`）、`SPEC-VDISP-003`、`SPEC-VDISP-004`、`SPEC-VDISP-005`（**完整**写法）；展开去重后为 `001`、`002`、`003`、`004`、`005`，共 `5` 条。本文件未采用**区间**写法，故无区间需展开。
- **差集**（上游减下游，两侧先排序去重）：命令 V20a、V20b、V20c 共同显示上游四条 `001`、`002`、`003`、`004` 全部落在下游集合内（`001`、`003`、`004` 为完整写法，`002` 经逗号并列展开），故差集为空、行数 `0`。
- **下游多出的 `SPEC-VDISP-005` 不判失败**：§12 明写下游出现上游没有的编号本身不判失败；此处它出现在「判据 005 无任务承担，理由」一节，属合法的"记录某项无判据覆盖"写法，**且未被用来凑数**——本判定取的是差集为空，不是数量比较。
- **判定：环 2 完好。**

#### 环 3 — `task/detail.md` → `verify/detail.md`

- **上游集合**（`task/detail.md` 的 `T-D` 条目标题）：命令 V21 → `3` 条，即 `T-D1`、`T-D2`、`T-D3`。
- **下游集合**（本文件中出现的 `T-D` 编号，按三种写法展开）：`T-D1`、`T-D2`、`T-D3` 均以完整写法被引用（见「说明」第 3 条对三条任务的逐条核实），共 `3` 条。
- **差集**（上游减下游）：空，行数 `0`。
- **判定：环 3 完好。**

## 命令证据

以下全部在 `C:/Coding/Themis` 主工作树、分支 `main` 上跑出，输出原样记录。

**命令形态说明**：本节的命令一律写成 `themis verify` 可重跑的形态——不含 `2>&1`、`&&`、`;`、进程替换与 `cut`（该 CLI 的只读白名单不含它们，写了会被判"拒绝执行"而非比对）。**V3、V5 因此由"取行号列表"改写为"逐行号各计一次"，V13、V14 由 `--numstat` 改写为 `--stat` 尾行，V20 的差集由两条包含性断言承担**——值与前文引用的完全一致，只是形态可重跑。

- V1 — `git log --oneline -1` → `f0a8974 design(2026-08-28-verify-identity-dispatch): R2 approved，详细设计与三条任务` → `起始 HEAD f0a8974`
- V2 — `grep -c '独立子代理' .themis/spec/flow.md` → `2`
- V3a — `grep -n '独立子代理' .themis/spec/flow.md | grep -c '^164:'` → `1` → `verify/basic 节命中 1 处`
- V3b — `grep -n '独立子代理' .themis/spec/flow.md | grep -c '^190:'` → `1` → `verify/detail 节命中 1 处`
- V4 — `grep -c '未由独立子代理承担' .themis/spec/flow.md` → `2`
- V5a — `grep -n '未由独立子代理承担' .themis/spec/flow.md | grep -c '^164:'` → `1`
- V5b — `grep -n '未由独立子代理承担' .themis/spec/flow.md | grep -c '^190:'` → `1`
- V6 — `grep -c '记明理由' .themis/spec/flow.md` → `2`
- V7 — `grep -c '记明理由' .themis/spec/rules.md` → `0`
- V8 — `awk '/^## §7/,/^## §8/' .themis/spec/rules.md | grep -c '交接'` → `2`
- V9 — `awk '/^## §7/,/^## §8/' .themis/spec/rules.md | grep -c '四项缺一不可'` → `1`
- V10 — `awk '/^## §7/,/^## §8/' .themis/spec/rules.md | grep -c '结构存在、可构建'` → `1`
**以下三条（V11、V12、V12b）本节点实跑过，但 `themis verify` 无法重跑**——`go` 不在该 CLI 的只读白名单内（`internal/themis/verify.go` 的 `allowed` 表刻意不含它，因为 `go test` 不是只读命令）。**本节点如实标出这一点，不为迁就 CLI 而改写判据 005 指定的命令**；三条的值由本节点当场跑出，输出摘要附于其后。

- V11 — `go test ./... 2>&1 | grep -c '^FAIL'` → `0`（**CLI 不可重跑，见上**）
- V12 — `go test ./... 2>&1 | grep -c '^ok'` → `12`（**CLI 不可重跑**）
- V12b — `go test ./... 2>&1 | grep -c 'no test files'` → `2`（**CLI 不可重跑**）
- V11–V12b 的原样输出摘要：`internal/themico/` 下 10 个包与 `internal/themis`、`internal/themis/cli` 共 12 个包报 `ok`，`cmd/themico`、`cmd/themis` 两个包报 `[no test files]`，无 `FAIL` 行、无 `build failed` 行。
- V13 — `git diff --stat .themis/spec/rules.md | tail -1` → ` 1 file changed, 13 insertions(+)` → `新增 13 行、删除 0 行`
- V14 — `git diff --stat .themis/spec/flow.md | tail -1` → ` 1 file changed, 6 insertions(+)` → `新增 6 行（4 行正文 + 2 行空行）、删除 0 行`
- V15 — `git diff --name-only | wc -l` → `2`
- V16 — `git diff --name-only -- '*.go' | wc -l` → `0`
- V17 — `grep -c '^### SPEC-' .themis/workspace/spec/2026-08-28-verify-identity-dispatch/step1/specify.md` → `5`
- V18 — `grep '^### SPEC-' .themis/workspace/spec/2026-08-28-verify-identity-dispatch/step1/specify.md | grep -c '\[横切\]'` → `1`
- V19 — `grep '^### SPEC-' .themis/workspace/spec/2026-08-28-verify-identity-dispatch/step1/specify.md | grep -v '\[横切\]' | wc -l` → `4` → `环 2 上游集合基数`
- V20a — `grep -o 'SPEC-VDISP-00[134]' .themis/workspace/spec/2026-08-28-verify-identity-dispatch/step1/task/detail.md | sort -u | wc -l` → `3` → `001、003、004 以完整写法出现`
- V20b — `grep -c 'SPEC-VDISP-001、002' .themis/workspace/spec/2026-08-28-verify-identity-dispatch/step1/task/detail.md` → `1` → `002 以逗号并列的裸数字出现，展开后归入下游集合`
- V20c — `grep -o 'SPEC-VDISP-002' .themis/workspace/spec/2026-08-28-verify-identity-dispatch/step1/task/detail.md | wc -l` → `0` → `002 确无完整写法，V20b 的展开是它进入下游集合的唯一途径`
- V21 — `grep -cE '^#+ T-D[0-9]+' .themis/workspace/spec/2026-08-28-verify-identity-dispatch/step1/task/detail.md` → `3` → `环 3 上游集合基数`
- V22 — `grep -c '本段为空' .themis/workspace/spec/2026-08-28-verify-identity-dispatch/step1/task/basic.md` → `1` → `basic 段自述为空`
- V23 — `ls -1 /tmp/themis.exe | wc -l` → `1` → `本节点自行构建的 CLI 存在（构建命令 go build -o /tmp/themis.exe ./cmd/themis 输出 BUILD_OK，含 && 故不写成可重跑断言）`
- V24 — `/tmp/themis.exe verify .themis/spec/flow.md | wc -l` → `0` → `报告数 0`
- V25 — `/tmp/themis.exe verify .themis/spec/rules.md | wc -l` → `0` → `报告数 0`
- V26 — `/tmp/themis.exe verify .themis/spec/template.md | wc -l` → `0` → `报告数 0`
- V27 — `/tmp/themis.exe verify .themis/spec/README.md | wc -l` → `0` → `报告数 0`
- V28 — `/tmp/themis.exe overlap .themis/spec/ | head -1` → `未发现需人工复核的重合片段。`
- V29 — `find .themis/workspace/spec -name 'state.md' | wc -l` → `9`
- V30 — `ls -1 .themis/workspace/spec/ | wc -l` → `11` → `实例目录 11 个，其中 9 个有 state.md`
- V31 — `find .themis/workspace/spec/2026-08-28-verify-identity-dispatch -name 'state.md' | wc -l` → `0` → `本实例无 state.md`
- V32 — `find .themis/workspace/spec/2026-08-28-verify-identity-dispatch/step1/verify -name 'basic.md' | wc -l` → `0` → `本 step 无 verify/basic.md`
- V33a — `grep -l '^## T-D' .themis/workspace/spec/*/step*/task/detail.md | wc -l` → `7`
- V33b — `grep -l '^### T-D' .themis/workspace/spec/*/step*/task/detail.md | wc -l` → `5` → `12 份中 7 份用 '## T-D'、5 份用 '### T-D'，两种并存`

**本文件在收尾时用 `/tmp/themis.exe verify` 重跑过一遍自身断言。** 结果为 `3` 条报告，**三条全部是 V11、V12、V12b 的"`go` 不在只读白名单内"**，即上文已标出的 CLI 能力边界；**没有任何一条是值不符**。此前实例的 `verify/detail.md` 亦有同类不可重跑条目（例如 `2026-08-28-citation-overlap-check/step2` 有 `themis` 命令不在白名单内的一条），**这是当前 CLI 的已知边界，不是本文件的断言错误**。

## 结论

**`passed`。**

`specify.md` 五条判据 `SPEC-VDISP-001` 至 `005` **逐条满足**，无一条合并或省略：001 → `2`（≥2，分属两节点）；002 → `2`（≥1，拦截三要素齐备）；003 → `2`（≥1，四项最小集逐项在位并已被本次派发实际消费）；004 → 本文件「执行身份」记明独立子代理身份且与 `impl/detail.md` 不同，**其循环已如实标出**；005 → 第一条 `1`、第二条 `0`，且 §7 既有三段一字未动。

**孤儿判定：无孤儿**，本 step 无任何 basic 落地改动（代码层断言见 B 组）。**追溯链环 2 差集 `0`、环 3 差集 `0`，两环完好。**

**本结论不覆盖以下三项**，它们不属五条判据的验证范围，作为本节点发现的问题移交下游（见「说明」第 4、5、6 条）：本实例缺 `state.md` 与 `verify/basic.md`；`rules.md` §12 有两处历史断言已失真；`task/detail.md` 的 `T-D` 标题层级与 `template.md` 规定不一致。**三者均不改变上述 `passed` 判定**——第一项不在五条判据之内，第二项位于 §12 而非 §7 且经 `git diff` 核实为本 step 之前既已存在，第三项同为既存漂移且不影响环 3 判定。

## 说明

1. **身份独立性的证据强度，如实写明。** 本栏与 `impl/detail.md` 那栏的模型标识相同（均为 `claude-opus-5`），当前控制面下没有任何机器签名把"这是两次不同会话"固定下来。本条成立于 §7 指定的比对方式——两处「执行身份」小节一比即得，四项（派发关系、会话、起始 HEAD、承担节点）均不同。**这不是密码学证明**，一个不自觉的执行体仍可以伪造该小节；§7 与 `flow.md` 也都明写拦截点在动作发生前、当前强制水平下没有机器拦截点。

2. **判据 004 的循环，本节点不主张已消除。** R2 已裁定接受该循环并要求如实标出，本文件在 A 组断言 4 下照此执行。本节点能说明的全部是：写下这句话的会话确实是另一次，且它在写本文件前对本实例工件无写操作。**本节点不主张该证据能拦住未来的违例**，也不主张它比 `impl/detail.md` 里同一句话强到可以免于人工复核——人工验收节点仍须按 §7 复核身份独立性是否成立。

3. **三条任务的逐条核实**（环 3 的语义面，§12 明写集合包含发现不了"引错"，故另读）：**`T-D1`**（`flow.md` 两个 verify 节点写明派发要求与拦截）——已落地，命令 V14 显示 `flow.md` 新增 6 行（4 行正文 + 2 行空行），两节点各含派发要求句与拦截句，另有一句拦截点理由；其做法三项（各补一句、拦截写成"不得给出结论"并写明 `进行中` 与停靠位置、不留放行余地）**逐项在文本中可查**。**`T-D2`**（`rules.md` §7 补交接最小集与生效时点）——已落地，命令 V13 显示 `rules.md` 新增 13 行，含四项编号列表、事故来源、"四项不是穷举"、生效时点句（「本要求自 `2026-08-28` 修订起适用——在此之前的实例不因本条被判违反」）与"不是机器强制、soft 执行器下同样适用"一句；其做法第 4 项（不改 §7 现有三项 basic 判据与 detail 断言范围）经 V13 的零删除行核实。**`T-D3`**（本 step 的 verify 由独立子代理承担）——**本文件的存在即其执行结果**，且由本次被派发的会话撰写，未被代写。**三条任务均有对应产物，未发现引错。**

4. **本节点发现的问题一：本实例缺 `state.md`，本 step 亦缺 `verify/basic.md`。** 命令 V29 显示 `.themis/workspace/spec` 下现存 `9` 份 `state.md`，V30 显示实例目录共 `11` 个，V31 显示**本实例下没有 `state.md`**。`flow.md`「通用失败去向」段明写「每个节点完成后，执行者必须更新实例 `state.md` 的当前节点、该节点闸门结论、当前性三项」，并写明 `state.md` 是 soft 执行器下判定"停在 last proven gate"的依据；「前置的可查形态」段进一步要求每个节点开始时须能从 `state.md`「各闸门」读出前置闸门结论。**本实例自 Intake 起未产出该文件**，因而本节点无法从 `state.md` 读出自身前置闸门（impl/detail 完成）的记录，只能依据 `impl/detail.md` 的存在与内容推断。**这正是「前置的可查形态」段所说的"跳过留下的可查缺口"。** 另据命令 V32，本 step 的 `verify/basic.md` 亦不存在——`flow.md`「verify/basic」节规定该节点在 basic 段为空时结论取 `不适用`，**并须在工件「结论」小节写明它由空段导致、附本节点自行做出的空段代码层断言**；即**取 `不适用` 仍要求产出工件**，此处工件缺失。两项**均不在五条判据的验证范围内，故不改变 `passed` 判定**，**移交人工验收节点处置**。

5. **本节点发现的问题二：`rules.md` §12 有两处历史断言已失真。** §12 内两条自证断言当前重跑的结果与其记录值不符——「三种写法不是新发明」一句的 `grep -rnE … | wc -l` 记录为 `4`、**本节点实跑得 `12`**；「本标识的边界经既有判据检验」一句的 `grep -h '^### SPEC-' … | wc -l` 记录为 `24`、**本节点实跑得 `54`**。**成因是实例数增长**，非本 step 所致：命令 V13 显示本 step 对 `rules.md` 的改动全部落在 §7、为纯新增，**§12 一字未动**。命令 V25 显示 `themis verify .themis/spec/rules.md` 报告数为 `0`，说明这两行未被 CLI 的形态识别命中（其命令含管道与 glob），**即当前 CLI 无法覆盖此类断言**——这与在办实例 `2026-08-28-pipe-escape-handling` 的主题相关。**判据 005 的保护范围限于 §7，不含 §12**，故本项不构成 005 不满足；**作为本节点发现的问题移交，由所有者决定是否单独立项。**

6. **本节点发现的问题三：`task/detail.md` 的 `T-D` 标题层级与 `template.md` 规定不一致。** `template.md` 规定 `task/detail.md` 中每个条目写作 `### T-D<n>`，但命令 V33a、V33b 显示 12 份 `task/detail.md` 中 `5` 份用 `### T-D`、`7` 份用 `## T-D`——**本 step 的 `task/detail.md` 属后者**。本节点的环 3 扫描因此用 `^#+ T-D` 而非 `^### T-D` 取上游集合（命令 V21）；若严格按 `^### T-D` 扫，本 step 上游集合会得 `0`，**从而把漏引变成漏报**，正是 §12 所警示的方向。这是**既存漂移**（另 6 份同形的实例均在本 step 之前），不由本 step 引入，也不影响环 3 的实际判定（差集为空成立于实际存在的三条任务）。**移交所有者决定是统一书写还是放宽 `template.md`。**

7. **本节点未做、也无权做的**：未修改任何文件（除写出本文件外），未切分支、未新建工作树、未提交——交接第 3 项明确要求在 `main` 主工作树上操作且提交由主会话完成，本次会话据此执行。`git status --short` 在本文件写出前显示的改动为 `.themis/spec/flow.md`、`.themis/spec/rules.md` 两份已修改文件与两处未跟踪路径（`step1/impl/`、`step1/task/review.md`），**全部为实现者会话留下**，本次会话未新增其他改动。

8. **§12 能力边界对本次判定的限制，本节点重申**：环 2、3 的集合包含只能发现漏引，发现不了引错。本节点为此另做了第 3 条的逐条语义核实，**但那是本节点自行加做的，不是 §12 要求的**；若第 3 条的语义判断有误，环 2、3 的差集为空并不能兜住它。
