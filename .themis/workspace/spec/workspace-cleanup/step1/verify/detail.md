# verify/detail.md — workspace-cleanup / step1

> 本文件是 verify/detail 节点的实例工件。本节点的前置闸门、产出、失效波及与失败去向见 `flow.md`「verify/detail」节；断言范围、身份独立与拒绝条件见 `rules.md` §7，孤儿判定见 §8。以上各处只指向位置，本文件不复述其文字。
>
> **本文件里的每个数字与每条存在性断言，都由本节点当场跑命令得出。** `impl/detail.md` 的自述在本文件中只是**被核验的对象**，不作为证据使用。

## 执行身份

- **身份**：Claude Opus 5（模型标识 `claude-opus-5`），本次 spec 流程会话。工作树 `C:/Coding/Themis`，分支 `main`，起始 HEAD `0a552ad`（命令 V1）。
- **与 `impl/detail.md`「执行身份」比对的结果：相同——`rules.md` §7 的身份独立在本段不成立。** 两份工件由同一次 agent 会话产出。`impl/detail.md`「执行身份」末段已预先指出这一点并把判定留给本节点，本节点如实确认：**不成立**。
- **这一失守的性质**：与 basic 段同源，且与 `core-removal` 实例 basic 段同型。该实例的 detail 段曾因派发把两个节点拆给两次会话而成立——**两相对照证明这道闸门的开合完全取决于派发层，节点自身无法创造第二个身份**（`hard-enforcement-list.md` 第 6 项已据此记明修复对象是派发层而非控制面条款）。本次 soft 执行器下无派发层可依。
- **本节点能自证到哪一步**：本次会话在写下本文件前，对被验证的对象（`templates/`、`.gitignore`、`AGENTS.md`、`README.md`、`CLAUDE.md`、Go 源码）零写入；落地改动已在本次会话之前的提交 `0a552ad` 中。但**这不能替代身份独立**——同一会话既落地又验证，本节点对自己的落地判断存在结构性偏袒，如实标出。

## 断言与实际结果

`specify.md` 五条行为条目逐条断言，不挑拣。

| 条目 | 断言 | 实际结果 | 判定 |
| --- | --- | --- | --- |
| SPEC-WSCLEAN-001 | `templates/.themis/` 不存在 | `GONE`；文件数 `0`（命令 V2） | **满足** |
| SPEC-WSCLEAN-002 | `.gitignore` 无控制面忽略规则 | 精确正则计数 `0`（命令 V3） | **满足** |
| SPEC-WSCLEAN-003 | 控制面在 git 中可得且内容与落地前逐字相同 | 四份全部 `TRACKED`（V4）；内容一致（V5 方式B、V6、V7 三法互证） | **满足**（判据写法有缺陷，见下） |
| SPEC-WSCLEAN-004 | 无指向已删内容的活引用 | 命中 `0`（命令 V8）；加严扫描的 3 处命中全在 `.idea/`（V9） | **满足** |
| SPEC-WSCLEAN-005 | Go 构建与测试不劣于基线 | `BUILD_OK`、`ok` 计数 `10`、`FAIL` 计数 `0`（命令 V10），与基线持平 | **满足** |

### SPEC-WSCLEAN-003 的判据写法缺陷（本节点的独立裁定）

`specify.md` 该条判据写的比对命令是 `git show <基线>:… | diff -q - ".themis/spec/$f.md"`。**本节点实跑该命令，四份全部报 DIFF**（命令 V5 方式A）。

若照字面判，本条应判 `failed`。本节点不这样判，理由是**用三种独立方法互证内容实际逐字相同**：

1. **忽略行尾比对**（命令 V6）：`diff --strip-trailing-cr` 四份全部一致。
2. **字节计数**（命令 V7）：去掉 CR 后，四份的字节数与基线分别为 1940/1940、14041/14041、10846/10846、4709/4709，全部相等。
3. **blob 哈希**（命令 V5 方式B）：git 实际存储的规范化内容哈希，四份与基线包源完全相同。

差异来源是本仓库在 Windows 下 autocrlf 生效——工作区为 CRLF、git 存储为 LF。`diff` 逐字节比较，因此把行尾差异报为全文差异。**判据要测的是"内容未在迁移中被改动"，三法互证该语义成立。**

**这是判据写法的缺陷，不是落地的缺陷，也不是本节点放宽读法。** 本节点未修改 `specify.md`（那是已批准工件），如实记录于此，处置交人工验收。**须明确**：本条判定为满足，依据是上述三法，不是"照抄 impl 的说法"——`impl/detail.md` 命令 D4 也提出了同一问题，但本节点是独立重跑后得出同一结论，未采信其结论。

### 三份迁移文件：不在断言范围内

R2 裁定 B 不补 SPEC-WSCLEAN-006，五条判据无一覆盖 `skills/themis/SKILL.md`、`skills/themico/SKILL.md`、`AGENTS.md` 三份的迁移结果。

**本节点不把它们判为"通过"——无判据即无结论**（`design-review.md`「裁定 B」明写此约束）。

仅如实记录观察到的事实，供人工验收判断：三份全部 `TRACKED`，blob 哈希与落地前基线一致；`AGENTS.md` 的三节写作约束（`### 引用只指向，不复述`、`### 判据必须有判定者`、`### 失败去向必须镜像前置闸门的分支`）完整保留（命令 V11、V12）。**这些是记录，不是判定。**

### 孤儿判定（§8）：不存在孤儿

本节点自行数出 `task/basic.md` 的 `### T-B` 条目数为 **0**（命令 V13），并逐条读了六条 detail 任务的依赖项——依赖分别为「无」「T-D1」「T-D1」「T-D2 与 T-D3」「T-D4」「T-D4」，**无一指向任何 basic 任务**。

basic 段为空，没有已落地的 basic 改动，因而没有可判的孤儿。**此结论由本节点自行数出，未采信 `task/basic.md` 或 `task/review.md` 的自述**（§8 拒绝条件）。

**须为下游写明前提**：此处的"不存在孤儿"是**没有可判对象**，不是"逐个 basic 任务都找到了消费者"。空段下本结论信息量极低，`acceptance.md` 引用时应带此前提。

## 命令证据

**V1** 起始状态：`git rev-parse --short HEAD` → `0a552ad`

**V2** 判据 001：`test -e templates/.themis` → `GONE`；`find templates/.themis -type f | wc -l` → `0`

**V3** 判据 002：`grep -cE '^/?\.themis/(spec|skills)/?$|^/?\.themis/(README|CLAUDE\.themis)\.md$' .gitignore` → `0`

**V4** 判据 003 入库：四份全部 `TRACKED`

**V5** 判据 003 内容，两法：

```
方式A（specify.md 原写法，diff）：README DIFF / flow DIFF / rules DIFF / template DIFF
方式B（blob 哈希）：              README SAME / flow SAME / rules SAME / template SAME
```

**V6** 忽略行尾：四份全部「内容一致(仅行尾差)」

**V7** 去 CR 后字节数：

```
README   基线=1940   当前=1940   OK
flow     基线=14041  当前=14041  OK
rules    基线=10846  当前=10846  OK
template 基线=4709   当前=4709   OK
```

**V8** 判据 004：`0`

**V9** 加严扫描（去掉 `--include='*.md'`）：`3`，逐条读原文全在 `.idea/workspace.xml`（IDE 状态文件，被 `.gitignore` 忽略，非仓库内容）：

```
./.idea/workspace.xml:8   change afterPath …/templates/.themis/core/capabilities/template/SKILL.md
./.idea/workspace.xml:9   change afterPath …/templates/.themis/core/capabilities/template/rule.md
./.idea/workspace.xml:76  last_opened_file_path …/templates/.themis/workspace/spec/template/step2
```

**这次加严扫描是本节点自加的**：`impl/detail.md`「偏差 1」记载六处活引用的清点因限定 `*.md` 而漏掉了 Go 源码里的第七处。本节点据此扩大扫描范围复核，确认除 `.idea/` 外无其他遗漏。

**V10** 判据 005：`BUILD_OK`；`ok` → `10`；`FAIL` → `0`

**V11** 三份迁移文件：全部 `TRACKED`，blob 全部一致

**V12** `AGENTS.md` 三节写作约束：`### ` 计数 `3`，标题为「引用只指向，不复述」「判据必须有判定者」「失败去向必须镜像前置闸门的分支」

**V13** 孤儿判定：`### T-B` 计数 `0`；六条 detail 任务依赖项逐条读出，无一指向 basic

**V14** 越界边界核验：`git diff 098fcd9..HEAD --stat -- templates/.themico/` → `1 file changed, 1 insertion(+), 1 deletion(-)`，证实该包只被改动一行，符合 R2 裁定 A 的效力边界

## 结论

**passed。**

- `specify.md` 五条行为条目逐条断言，**五条全部满足**。
- 孤儿判定：**不存在孤儿**（空段，无可判对象——前提已写明供 `acceptance.md` 引用）。
- 越界边界成立：`templates/.themico/` 只被改动一行（命令 V14），符合 R2 裁定 A。

**本结论不覆盖的三处，必须随结论一并读：**

1. **三份迁移文件不在断言范围内**（R2 裁定 B）。本节点只记录不判定，其正确性由人工验收承担。
2. **`impl/detail.md` 记载的偏差 1——改动 Go 测试文件——超出 R3 批准的任务对象清单。** 本节点核实该改动确实使判据 005 从 `ok:9/FAIL:3` 恢复到基线，且该测试语义合同未变；**但"是否接受这处越界"不是验证角色能判的，属人工验收裁量。**
3. **身份独立不成立**（见「执行身份」）。本结论由与实现者同一会话的角色作出，存在结构性偏袒，**其证据强度低于独立验证**。

本结论依据本节点自己运行的命令与真实输出，不依据 `impl/detail.md` 的自述、也不依据任何工件文件存在与否。

## 说明

**1. 判据写法缺陷与落地缺陷的分界，本节点判得动，靠的是判据写死了语义。** SPEC-WSCLEAN-003 除命令外还写明它要验证的是"控制面在 git 中存在且内容未在迁移中被改动"。正因语义写在那里，命令报 DIFF 时本节点才有依据去问"这个 DIFF 是否意味着内容被改动了"，而不是机械判 failed。**若该条只写了命令、没写语义，本节点只能判 failed 或越权放宽，两者都不对。**

**2. 本节点自加了一次加严扫描，起因是 impl 自曝的漏检。** 原判据 004 限定 `*.md`，而实际漏掉的第七处引用在 Go 源码里。本节点把扫描扩到全部文件类型，命中 3 处全在 `.idea/`——非仓库内容。**这次加严不改变判据、不改变判定标准，只是本节点为自己的结论多找一层证据。**

**3. "想让它通过"的冲动出现在一处，被三法互证挡住。** SPEC-WSCLEAN-003 报 DIFF 时，最省事的两条路都错：照字面判 failed（错，内容确实没变），或直接采信 `impl/detail.md` 已给出的"是行尾问题"的说法（错，那是采信被核验对象的自述）。本节点跑了三种独立方法，其中字节计数（V7）是最硬的一条——**若真有内容被改动，去掉 CR 后的字节数不会四份全部相等。**

**4. 本节点核验不动的两样，如实写出。** 其一，对方那栏的真伪——本节点只能读到 `impl/detail.md` 写下的执行身份，读不到那次会话本身；本次两栏相同，问题不在真伪而在独立性本身不成立。其二，`AGENTS.md`「安装包与项目工作区的边界」一节改写后的**措辞是否恰当**——本节点能核实它不再指向已删路径（判据 004 已覆盖），但"改写得对不对、有没有引入新的不准确"属产品判断，不在五条判据范围内，留给人工验收。
