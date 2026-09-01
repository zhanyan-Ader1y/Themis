# product-judge 全仓扫描 — 2026-08-31

> **本文件不是 `rules.md` §13 规定的报告落点。** §13 只定义了两处落点：spec 级闸门（R1 前）写实例目录下的 `judge.md`，step 级闸门（R2、R3、验收前）写 `step<N>/judge.md`，两者均为追加写入。**本次是全仓一次性扫描，不发生在任何单个闸门前，也不属任何单个实例**——§13 对这种形态没有规定落点。落点由本次派发指定，即本文件；这一点作为 §13 的一处判据空白记在末节。

## 1. 判定范围与依据

- **判定者**：`product-judge` 子代理（`rules.md` §13）。本次为 §13 上线后的首次实跑。
- **范围**：`C:/Coding/Themis/.themis/workspace/spec/` 下**全部 14 个实例**（该目录下无 `template/` 子目录，实测不存在，故无可跳过项），逐实例、逐已走完节点。
- **小节名的唯一事实源**：`C:/Coding/Themis/.themis/spec/flow.md` 十四个节点小节的「产出」项。**未援引 `template.md` 的任何内容**（`docs/adr/2026-08-29-template-is-skeleton-not-fact-source.md`）。
- **只判在不在、齐不齐**，不判任何断言真伪、不判内容对错。

## 2. 方法与实际执行的命令

1. `ls -la` 与 `find <实例> -type f | sort` 取全部实例的实际文件清单——**存在性全部由文件系统读出，未采信任何工件自述或主会话记忆**。
2. 对每份工件跑 `grep -nE '^#{1,6} <小节名>( .*)?$'` 判固定小节是否存在（标题行匹配，允许标题后带括注后缀）。
3. **对全部宽松匹配复跑一次严格匹配比对**，剔除子串误判——实测抓到 `1` 处：`2026-08-28-citation-overlap-check/step2/verify/detail.md` 中 `### 判据 004 的覆盖范围，如实说明其不足` 含"说明"二字但**不是**「说明」小节，宽松匹配曾误判为齐，严格匹配纠正为缺。
4. 逐实例读 `state.md`「当前节点」「各闸门」与工件实际存在情况交叉验证。
5. 对每个 `impl/basic.md` 不存在的场合，**回读 `flow.md`「impl/basic」节正文**确认"basic 段为空时本节点不产生调用"这一产出条件是否成立。

## 3. 结论摘要

| 项 | 数 |
| --- | --- |
| 实例总数 | `14` |
| 走完全部十四节点的 step | `16` |
| **缺失工件（判为缺失）** | **`7`** |
| **小节不齐的工件** | **`12`** |
| 按条件不产生、不计入缺失（`impl/basic.md`） | `11` |
| 未走到该节点、不判（`2026-08-29-template-judge`） | `11` |

## 4. 缺失工件清单

**全部 7 处同型：`verify/basic.md` 不存在。** §13 明写 `verify/basic` **不适用**"按条件不产生"——它在 basic 段为空时仍须产出工件并写入 `不适用` 结论（`flow.md`「verify/basic」节）。**文件缺失就是缺失。**

| # | 实例 / step | 缺失文件 | `state.md` 该行记的是什么 |
| --- | --- | --- | --- |
| 1 | `2026-08-27-claim-command-evidence` / step2 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/step2/verify/basic.md` | `verify/basic：不适用 — 同上（该取值第四个使用者）`——**无证据路径** |
| 2 | `2026-08-27-question-eligibility` / step1 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-question-eligibility/step1/verify/basic.md` | `verify/basic：不适用 — 同上（该取值第六个使用者）`——**无证据路径** |
| 3 | `2026-08-27-trace-number-scan` / step1 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-trace-number-scan/step1/verify/basic.md` | `verify/basic：不适用 — 同上（该取值第五个使用者）`——**无证据路径** |
| 4 | `2026-08-28-citation-overlap-check` / step1 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step1/verify/basic.md` | `verify/basic：不适用 — 同上`——**无证据路径** |
| 5 | `2026-08-28-citation-overlap-check` / step2 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step2/verify/basic.md` | `impl/basic、verify/basic：不适用 — basic 段为空`——**两节点并成一行，无证据路径** |
| 6 | `2026-08-28-gate-value-integrity` / step1 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-gate-value-integrity/step1/verify/basic.md` | `impl/basic、verify/basic：不适用 — basic 段为空`——**两节点并成一行，无证据路径** |
| 7 | `2026-08-28-spec-id-date-prefix` / step1 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-spec-id-date-prefix/step1/verify/basic.md` | `impl/basic、verify/basic：不适用 — basic 段为空`——**两节点并成一行，无证据路径** |

**交叉验证的一处规律，如实报出**：**凡 `state.md` 把 `verify/basic` 写成"同上"或与 `impl/basic` 并成一行、且不带证据路径的，工件一律不存在**（7/7）；凡带 `— step<N>/verify/basic.md` 证据路径的，工件一律存在（9/9）。**`state.md` 与文件系统在这 16 处没有互相矛盾**——它没有谎报存在，只是用"同上"把 `impl/basic` 的"不产生调用"顺带套到了 `verify/basic` 上。

## 5. 小节不齐清单

| # | 实例 / step | 文件 | 缺的固定小节 | 现场情况 |
| --- | --- | --- | --- | --- |
| 1 | `2026-08-27-claim-command-evidence` / step1 | `.../step1/task/review.md` | 「未解决反馈」 | 有 `### 我知道但还没解决的`（在「给评审者的呈现」下），**名称不是「未解决反馈」** |
| 2 | `2026-08-27-claim-command-evidence` / step2 | `.../step2/task/review.md` | 「未解决反馈」 | 同上，同一写法 |
| 3 | `2026-08-27-claim-command-evidence` / step2 | `.../step2/verify/detail.md` | 「说明」 | 末节为 `## 结论`，其后无「说明」 |
| 4 | `2026-08-27-question-eligibility` / step1 | `.../step1/verify/detail.md` | 「说明」 | 末节为 `## 结论` |
| 5 | `2026-08-27-trace-number-scan` / step1 | `.../step1/verify/detail.md` | 「说明」 | 末节为 `## 结论` |
| 6 | `2026-08-28-citation-overlap-check` / step1 | `.../step1/verify/detail.md` | 「说明」 | 末节为 `## 本节点自身的两条断言不受本工具校验，如实记明` |
| 7 | `2026-08-28-citation-overlap-check` / step2 | `.../step2/verify/detail.md` | 「说明」 | **宽松匹配曾误判为齐**，见第 2 节第 3 步 |
| 8 | `2026-08-28-gate-value-integrity` / step1 | `.../step1/verify/detail.md` | 「说明」 | 末节为 `## 本节点发现 themis verify 的一处新缺陷，如实报出` |
| 9 | `2026-08-28-spec-id-date-prefix` / step1 | `.../step1/verify/detail.md` | 「说明」 | 末节为 `## 结论` |
| 10 | `2026-08-27-trace-number-scan` / step1 | `.../step1/scope.md` | 「承担的上层分解项」「本 step 边界」「与其他 step 的关系」——**三节全缺** | 实有 `## 本 step 的范围`、`## 核实到的、影响做法的四处事实`、`## 本节点新暴露、不在 R1 已批准内容里的一处`、`## 命令证据` 等；**全仓唯一一份三节全不合名的 `scope.md`** |
| 11 | `2026-08-28-verify-identity-dispatch` / step1 | `.../step1/impl/detail.md` | 「与批准范围的偏差」 | 实有 `## T-D3 的执行方式与已知风险`、`## 尚未关闭、留给 verify/detail 与人工的` |
| 12 | `2026-08-29-template-strip-prescriptions` / step1 | `.../step1/summary.md` | 「中性工件说明」 | 有 `## 交付摘要`、`## 绑定的验收结论`，第三节缺 |

**7 处「说明」缺失集中在 `verify/detail.md`，且全部落在 `2026-08-27` 至 `2026-08-28` 之间的六个实例**；此前（`core-removal`、`authorization-traceability`、`workspace-cleanup`）与此后（`pipe-escape-handling`、`verify-identity-dispatch`、`product-judge`、`template-strip-prescriptions`）的 `verify/detail.md` 一律有 `## 说明`。**这不是个人风格差异，是一段连续时期的系统性漂移。**

## 6. 按条件不产生、不计入缺失的清单

**依据**：`flow.md`「impl/basic」节正文——"basic 段为空时本节点不产生调用，直接进入 impl/detail"。以下 11 处 `impl/basic.md` 不存在，**均由 `state.md` 该行明记 basic 段为空**，判为正确状态。

| # | 实例 / step | `state.md`「各闸门」原文 |
| --- | --- | --- |
| 1 | `2026-08-27-claim-command-evidence` / step2 | `impl/basic：不适用 — basic 段为空，无落地对象` |
| 2 | `2026-08-27-question-eligibility` / step1 | `impl/basic：不适用 — basic 段为空，无落地对象` |
| 3 | `2026-08-27-trace-number-scan` / step1 | `impl/basic：不适用 — basic 段为空，无落地对象` |
| 4 | `2026-08-28-citation-overlap-check` / step1 | `impl/basic：不适用 — basic 段为空` |
| 5 | `2026-08-28-citation-overlap-check` / step2 | `impl/basic、verify/basic：不适用 — basic 段为空` |
| 6 | `2026-08-28-gate-value-integrity` / step1 | `impl/basic、verify/basic：不适用 — basic 段为空` |
| 7 | `2026-08-28-pipe-escape-handling` / step1 | `impl/basic：不适用 — basic 段为空` |
| 8 | `2026-08-28-spec-id-date-prefix` / step1 | `impl/basic、verify/basic：不适用 — basic 段为空` |
| 9 | `2026-08-28-verify-identity-dispatch` / step1 | `impl/basic：不适用 — basic 段为空` |
| 10 | `2026-08-29-product-judge` / step1 | `impl/basic：不适用 — basic 段为空，按 flow.md 该节正文不产生调用，无 impl/basic.md，这是正确状态` |
| 11 | `2026-08-29-template-strip-prescriptions` / step1 | `impl/basic：不适用 — basic 段为空` |

**§13 所载"实测十一个已走到实现的实例中 7 个没有这份文件"与本次实测不一致**：本次实测**十六个已走到实现的 step 中 11 个**没有 `impl/basic.md`（`2026-08-29-template-judge` 未走到实现，不计）。§13 的 `7` 是写作当日（`2026-08-29`）的计数，其后 `pipe-escape-handling`、`product-judge`、`template-strip-prescriptions` 三个实例又各增一处；差额可解释，不构成矛盾，**但 §13 正文里的这个数字现已过期**。

## 7. 未走到、不判的节点

`2026-08-29-template-judge` 已作废、停在抽象设计（`state.md`「当前节点」：**本需求已作废，停在抽象设计节点**；「各闸门」step 级明写 `其余节点：未开始，且不再开始`）。其 `step1/design-review.md` 及以下 **11 份工件不存在，判为"未走到该节点"，不计入缺失**。已走完的五个节点（Intake、追问、R1、step 定界、抽象设计）**全部齐备**。

## 8. 超出 §13 判定范围、但在扫描中看到的三处（只报不判）

**§13 的分界是"验证看内容对不对、`product-judge` 看产物齐不齐"，以下三处属内容层，本报告不作判定，只如实报出供人类评审者取舍。**

1. **`impl/basic` 节点的闸门取值不合 `flow.md` 取值表。** 11 处 `state.md` 把 `impl/basic` 记为 `不适用`，而 `flow.md`「闸门结论取值」表给该类节点的合法取值只有 `已走完` / `进行中` / `未开始`；`不适用` 是 `verify/basic` 独有的取值。较早的三个实例（`core-removal`、`authorization-traceability`、`workspace-cleanup`）记的是 `impl/basic：已走完`，与取值表一致。
2. **`state.md` 本身不在十四条「产出」项内。** 逐节点核对 `flow.md` 十四个节点小节的「产出」项，**没有任何一个节点把 `state.md` 列为产出**；对它的要求出自「通用失败去向」一节（"每个节点完成后，执行者必须更新实例 `state.md`"）。因此 **§13 的判据文本严格读来够不到 `state.md`**。本次仍核了它的存在性（14/14 全部存在），但这一项是本报告自行扩的，不是 §13 授予的。
3. **全仓零份 `judge.md`。** `find` 全仓 `.themis/workspace/spec/` 下无任何 `judge.md` 或 `step<N>/judge.md`。这与 §13 是新规、此前从未派发一致，不判为缺失。

## 9. 逐实例逐节点核查表（全部所查路径）

### 2026-08-19-core-removal

| 节点 | 所查文件 | 文件 | 小节 |
| --- | --- | --- | --- |
| Intake | `C:/Coding/Themis/.themis/workspace/spec/2026-08-19-core-removal/Intent.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 追问 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-19-core-removal/QA.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R1 意图评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-19-core-removal/intent-review.md` | 存在 | 齐 |
| **step1** | | | |
| step 定界 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-19-core-removal/step1/scope.md` | 存在 | 齐 |
| 抽象设计 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-19-core-removal/step1/specify.md` | 存在 | 齐 |
| R2 抽象设计评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-19-core-removal/step1/design-review.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-19-core-removal/step1/design.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-19-core-removal/step1/task/basic.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-19-core-removal/step1/task/detail.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R3 详细方案评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-19-core-removal/step1/task/review.md` | 存在 | 齐 |
| impl/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-19-core-removal/step1/impl/basic.md` | 存在 | 齐 |
| verify/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-19-core-removal/step1/verify/basic.md` | 存在 | 齐 |
| impl/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-19-core-removal/step1/impl/detail.md` | 存在 | 齐 |
| verify/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-19-core-removal/step1/verify/detail.md` | 存在 | 齐 |
| 人工验收 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-19-core-removal/step1/acceptance.md` | 存在 | 齐 |
| 摘要 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-19-core-removal/step1/summary.md` | 存在 | 齐 |

### 2026-08-26-authorization-traceability

| 节点 | 所查文件 | 文件 | 小节 |
| --- | --- | --- | --- |
| Intake | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-authorization-traceability/Intent.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 追问 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-authorization-traceability/QA.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R1 意图评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-authorization-traceability/intent-review.md` | 存在 | 齐 |
| **step1** | | | |
| step 定界 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-authorization-traceability/step1/scope.md` | 存在 | 齐 |
| 抽象设计 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-authorization-traceability/step1/specify.md` | 存在 | 齐 |
| R2 抽象设计评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-authorization-traceability/step1/design-review.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-authorization-traceability/step1/design.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-authorization-traceability/step1/task/basic.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-authorization-traceability/step1/task/detail.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R3 详细方案评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-authorization-traceability/step1/task/review.md` | 存在 | 齐 |
| impl/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-authorization-traceability/step1/impl/basic.md` | 存在 | 齐 |
| verify/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-authorization-traceability/step1/verify/basic.md` | 存在 | 齐 |
| impl/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-authorization-traceability/step1/impl/detail.md` | 存在 | 齐 |
| verify/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-authorization-traceability/step1/verify/detail.md` | 存在 | 齐 |
| 人工验收 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-authorization-traceability/step1/acceptance.md` | 存在 | 齐 |
| 摘要 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-authorization-traceability/step1/summary.md` | 存在 | 齐 |

### 2026-08-26-workspace-cleanup

| 节点 | 所查文件 | 文件 | 小节 |
| --- | --- | --- | --- |
| Intake | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-workspace-cleanup/Intent.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 追问 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-workspace-cleanup/QA.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R1 意图评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-workspace-cleanup/intent-review.md` | 存在 | 齐 |
| **step1** | | | |
| step 定界 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-workspace-cleanup/step1/scope.md` | 存在 | 齐 |
| 抽象设计 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-workspace-cleanup/step1/specify.md` | 存在 | 齐 |
| R2 抽象设计评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-workspace-cleanup/step1/design-review.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-workspace-cleanup/step1/design.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-workspace-cleanup/step1/task/basic.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-workspace-cleanup/step1/task/detail.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R3 详细方案评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-workspace-cleanup/step1/task/review.md` | 存在 | 齐 |
| impl/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-workspace-cleanup/step1/impl/basic.md` | 存在 | 齐 |
| verify/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-workspace-cleanup/step1/verify/basic.md` | 存在 | 齐 |
| impl/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-workspace-cleanup/step1/impl/detail.md` | 存在 | 齐 |
| verify/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-workspace-cleanup/step1/verify/detail.md` | 存在 | 齐 |
| 人工验收 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-workspace-cleanup/step1/acceptance.md` | 存在 | 齐 |
| 摘要 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-26-workspace-cleanup/step1/summary.md` | 存在 | 齐 |

### 2026-08-27-claim-command-evidence

| 节点 | 所查文件 | 文件 | 小节 |
| --- | --- | --- | --- |
| Intake | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/Intent.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 追问 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/QA.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R1 意图评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/intent-review.md` | 存在 | 齐 |
| **step1** | | | |
| step 定界 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/step1/scope.md` | 存在 | 齐 |
| 抽象设计 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/step1/specify.md` | 存在 | 齐 |
| R2 抽象设计评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/step1/design-review.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/step1/design.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/step1/task/basic.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/step1/task/detail.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R3 详细方案评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/step1/task/review.md` | 存在 | **缺小节：「未解决反馈」** |
| impl/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/step1/impl/basic.md` | 存在 | 齐 |
| verify/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/step1/verify/basic.md` | 存在 | 齐 |
| impl/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/step1/impl/detail.md` | 存在 | 齐 |
| verify/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/step1/verify/detail.md` | 存在 | 齐 |
| 人工验收 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/step1/acceptance.md` | 存在 | 齐 |
| 摘要 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/step1/summary.md` | 存在 | 齐 |
| **step2** | | | |
| step 定界 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/step2/scope.md` | 存在 | 齐 |
| 抽象设计 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/step2/specify.md` | 存在 | 齐 |
| R2 抽象设计评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/step2/design-review.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/step2/design.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/step2/task/basic.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/step2/task/detail.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R3 详细方案评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/step2/task/review.md` | 存在 | **缺小节：「未解决反馈」** |
| impl/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/step2/impl/basic.md` | 不存在 | **按条件不产生**（`flow.md`「impl/basic」正文：basic 段为空时本节点不产生调用） |
| verify/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/step2/verify/basic.md` | **不存在** | **缺失** |
| impl/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/step2/impl/detail.md` | 存在 | 齐 |
| verify/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/step2/verify/detail.md` | 存在 | **缺小节：「说明」** |
| 人工验收 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/step2/acceptance.md` | 存在 | 齐 |
| 摘要 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-claim-command-evidence/step2/summary.md` | 存在 | 齐 |

### 2026-08-27-question-eligibility

| 节点 | 所查文件 | 文件 | 小节 |
| --- | --- | --- | --- |
| Intake | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-question-eligibility/Intent.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 追问 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-question-eligibility/QA.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R1 意图评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-question-eligibility/intent-review.md` | 存在 | 齐 |
| **step1** | | | |
| step 定界 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-question-eligibility/step1/scope.md` | 存在 | 齐 |
| 抽象设计 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-question-eligibility/step1/specify.md` | 存在 | 齐 |
| R2 抽象设计评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-question-eligibility/step1/design-review.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-question-eligibility/step1/design.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-question-eligibility/step1/task/basic.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-question-eligibility/step1/task/detail.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R3 详细方案评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-question-eligibility/step1/task/review.md` | 存在 | 齐 |
| impl/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-question-eligibility/step1/impl/basic.md` | 不存在 | **按条件不产生**（`flow.md`「impl/basic」正文：basic 段为空时本节点不产生调用） |
| verify/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-question-eligibility/step1/verify/basic.md` | **不存在** | **缺失** |
| impl/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-question-eligibility/step1/impl/detail.md` | 存在 | 齐 |
| verify/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-question-eligibility/step1/verify/detail.md` | 存在 | **缺小节：「说明」** |
| 人工验收 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-question-eligibility/step1/acceptance.md` | 存在 | 齐 |
| 摘要 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-question-eligibility/step1/summary.md` | 存在 | 齐 |

### 2026-08-27-trace-number-scan

| 节点 | 所查文件 | 文件 | 小节 |
| --- | --- | --- | --- |
| Intake | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-trace-number-scan/Intent.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 追问 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-trace-number-scan/QA.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R1 意图评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-trace-number-scan/intent-review.md` | 存在 | 齐 |
| **step1** | | | |
| step 定界 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-trace-number-scan/step1/scope.md` | 存在 | **缺小节：「承担的上层分解项」「本 step 边界」「与其他 step 的关系」** |
| 抽象设计 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-trace-number-scan/step1/specify.md` | 存在 | 齐 |
| R2 抽象设计评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-trace-number-scan/step1/design-review.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-trace-number-scan/step1/design.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-trace-number-scan/step1/task/basic.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-trace-number-scan/step1/task/detail.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R3 详细方案评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-trace-number-scan/step1/task/review.md` | 存在 | 齐 |
| impl/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-trace-number-scan/step1/impl/basic.md` | 不存在 | **按条件不产生**（`flow.md`「impl/basic」正文：basic 段为空时本节点不产生调用） |
| verify/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-trace-number-scan/step1/verify/basic.md` | **不存在** | **缺失** |
| impl/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-trace-number-scan/step1/impl/detail.md` | 存在 | 齐 |
| verify/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-trace-number-scan/step1/verify/detail.md` | 存在 | **缺小节：「说明」** |
| 人工验收 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-trace-number-scan/step1/acceptance.md` | 存在 | 齐 |
| 摘要 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-27-trace-number-scan/step1/summary.md` | 存在 | 齐 |

### 2026-08-28-citation-overlap-check

| 节点 | 所查文件 | 文件 | 小节 |
| --- | --- | --- | --- |
| Intake | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/Intent.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 追问 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/QA.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R1 意图评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/intent-review.md` | 存在 | 齐 |
| **step1** | | | |
| step 定界 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step1/scope.md` | 存在 | 齐 |
| 抽象设计 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step1/specify.md` | 存在 | 齐 |
| R2 抽象设计评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step1/design-review.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step1/design.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step1/task/basic.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step1/task/detail.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R3 详细方案评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step1/task/review.md` | 存在 | 齐 |
| impl/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step1/impl/basic.md` | 不存在 | **按条件不产生**（`flow.md`「impl/basic」正文：basic 段为空时本节点不产生调用） |
| verify/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step1/verify/basic.md` | **不存在** | **缺失** |
| impl/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step1/impl/detail.md` | 存在 | 齐 |
| verify/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step1/verify/detail.md` | 存在 | **缺小节：「说明」** |
| 人工验收 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step1/acceptance.md` | 存在 | 齐 |
| 摘要 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step1/summary.md` | 存在 | 齐 |
| **step2** | | | |
| step 定界 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step2/scope.md` | 存在 | 齐 |
| 抽象设计 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step2/specify.md` | 存在 | 齐 |
| R2 抽象设计评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step2/design-review.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step2/design.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step2/task/basic.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step2/task/detail.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R3 详细方案评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step2/task/review.md` | 存在 | 齐 |
| impl/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step2/impl/basic.md` | 不存在 | **按条件不产生**（`flow.md`「impl/basic」正文：basic 段为空时本节点不产生调用） |
| verify/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step2/verify/basic.md` | **不存在** | **缺失** |
| impl/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step2/impl/detail.md` | 存在 | 齐 |
| verify/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step2/verify/detail.md` | 存在 | **缺小节：「说明」** |
| 人工验收 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step2/acceptance.md` | 存在 | 齐 |
| 摘要 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-citation-overlap-check/step2/summary.md` | 存在 | 齐 |

### 2026-08-28-gate-value-integrity

| 节点 | 所查文件 | 文件 | 小节 |
| --- | --- | --- | --- |
| Intake | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-gate-value-integrity/Intent.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 追问 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-gate-value-integrity/QA.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R1 意图评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-gate-value-integrity/intent-review.md` | 存在 | 齐 |
| **step1** | | | |
| step 定界 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-gate-value-integrity/step1/scope.md` | 存在 | 齐 |
| 抽象设计 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-gate-value-integrity/step1/specify.md` | 存在 | 齐 |
| R2 抽象设计评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-gate-value-integrity/step1/design-review.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-gate-value-integrity/step1/design.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-gate-value-integrity/step1/task/basic.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-gate-value-integrity/step1/task/detail.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R3 详细方案评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-gate-value-integrity/step1/task/review.md` | 存在 | 齐 |
| impl/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-gate-value-integrity/step1/impl/basic.md` | 不存在 | **按条件不产生**（`flow.md`「impl/basic」正文：basic 段为空时本节点不产生调用） |
| verify/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-gate-value-integrity/step1/verify/basic.md` | **不存在** | **缺失** |
| impl/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-gate-value-integrity/step1/impl/detail.md` | 存在 | 齐 |
| verify/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-gate-value-integrity/step1/verify/detail.md` | 存在 | **缺小节：「说明」** |
| 人工验收 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-gate-value-integrity/step1/acceptance.md` | 存在 | 齐 |
| 摘要 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-gate-value-integrity/step1/summary.md` | 存在 | 齐 |

### 2026-08-28-pipe-escape-handling

| 节点 | 所查文件 | 文件 | 小节 |
| --- | --- | --- | --- |
| Intake | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-pipe-escape-handling/Intent.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 追问 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-pipe-escape-handling/QA.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R1 意图评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-pipe-escape-handling/intent-review.md` | 存在 | 齐 |
| **step1** | | | |
| step 定界 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-pipe-escape-handling/step1/scope.md` | 存在 | 齐 |
| 抽象设计 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-pipe-escape-handling/step1/specify.md` | 存在 | 齐 |
| R2 抽象设计评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-pipe-escape-handling/step1/design-review.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-pipe-escape-handling/step1/design.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-pipe-escape-handling/step1/task/basic.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-pipe-escape-handling/step1/task/detail.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R3 详细方案评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-pipe-escape-handling/step1/task/review.md` | 存在 | 齐 |
| impl/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-pipe-escape-handling/step1/impl/basic.md` | 不存在 | **按条件不产生**（`flow.md`「impl/basic」正文：basic 段为空时本节点不产生调用） |
| verify/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-pipe-escape-handling/step1/verify/basic.md` | 存在 | 齐 |
| impl/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-pipe-escape-handling/step1/impl/detail.md` | 存在 | 齐 |
| verify/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-pipe-escape-handling/step1/verify/detail.md` | 存在 | 齐 |
| 人工验收 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-pipe-escape-handling/step1/acceptance.md` | 存在 | 齐 |
| 摘要 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-pipe-escape-handling/step1/summary.md` | 存在 | 齐 |

### 2026-08-28-spec-id-date-prefix

| 节点 | 所查文件 | 文件 | 小节 |
| --- | --- | --- | --- |
| Intake | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-spec-id-date-prefix/Intent.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 追问 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-spec-id-date-prefix/QA.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R1 意图评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-spec-id-date-prefix/intent-review.md` | 存在 | 齐 |
| **step1** | | | |
| step 定界 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-spec-id-date-prefix/step1/scope.md` | 存在 | 齐 |
| 抽象设计 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-spec-id-date-prefix/step1/specify.md` | 存在 | 齐 |
| R2 抽象设计评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-spec-id-date-prefix/step1/design-review.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-spec-id-date-prefix/step1/design.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-spec-id-date-prefix/step1/task/basic.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-spec-id-date-prefix/step1/task/detail.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R3 详细方案评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-spec-id-date-prefix/step1/task/review.md` | 存在 | 齐 |
| impl/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-spec-id-date-prefix/step1/impl/basic.md` | 不存在 | **按条件不产生**（`flow.md`「impl/basic」正文：basic 段为空时本节点不产生调用） |
| verify/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-spec-id-date-prefix/step1/verify/basic.md` | **不存在** | **缺失** |
| impl/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-spec-id-date-prefix/step1/impl/detail.md` | 存在 | 齐 |
| verify/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-spec-id-date-prefix/step1/verify/detail.md` | 存在 | **缺小节：「说明」** |
| 人工验收 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-spec-id-date-prefix/step1/acceptance.md` | 存在 | 齐 |
| 摘要 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-spec-id-date-prefix/step1/summary.md` | 存在 | 齐 |

### 2026-08-28-verify-identity-dispatch

| 节点 | 所查文件 | 文件 | 小节 |
| --- | --- | --- | --- |
| Intake | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-verify-identity-dispatch/Intent.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 追问 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-verify-identity-dispatch/QA.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R1 意图评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-verify-identity-dispatch/intent-review.md` | 存在 | 齐 |
| **step1** | | | |
| step 定界 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-verify-identity-dispatch/step1/scope.md` | 存在 | 齐 |
| 抽象设计 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-verify-identity-dispatch/step1/specify.md` | 存在 | 齐 |
| R2 抽象设计评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-verify-identity-dispatch/step1/design-review.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-verify-identity-dispatch/step1/design.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-verify-identity-dispatch/step1/task/basic.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-verify-identity-dispatch/step1/task/detail.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R3 详细方案评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-verify-identity-dispatch/step1/task/review.md` | 存在 | 齐 |
| impl/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-verify-identity-dispatch/step1/impl/basic.md` | 不存在 | **按条件不产生**（`flow.md`「impl/basic」正文：basic 段为空时本节点不产生调用） |
| verify/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-verify-identity-dispatch/step1/verify/basic.md` | 存在 | 齐 |
| impl/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-verify-identity-dispatch/step1/impl/detail.md` | 存在 | **缺小节：「与批准范围的偏差」** |
| verify/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-verify-identity-dispatch/step1/verify/detail.md` | 存在 | 齐 |
| 人工验收 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-verify-identity-dispatch/step1/acceptance.md` | 存在 | 齐 |
| 摘要 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-28-verify-identity-dispatch/step1/summary.md` | 存在 | 齐 |

### 2026-08-29-product-judge

| 节点 | 所查文件 | 文件 | 小节 |
| --- | --- | --- | --- |
| Intake | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-product-judge/Intent.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 追问 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-product-judge/QA.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R1 意图评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-product-judge/intent-review.md` | 存在 | 齐 |
| **step1** | | | |
| step 定界 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-product-judge/step1/scope.md` | 存在 | 齐 |
| 抽象设计 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-product-judge/step1/specify.md` | 存在 | 齐 |
| R2 抽象设计评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-product-judge/step1/design-review.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-product-judge/step1/design.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-product-judge/step1/task/basic.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-product-judge/step1/task/detail.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R3 详细方案评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-product-judge/step1/task/review.md` | 存在 | 齐 |
| impl/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-product-judge/step1/impl/basic.md` | 不存在 | **按条件不产生**（`flow.md`「impl/basic」正文：basic 段为空时本节点不产生调用） |
| verify/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-product-judge/step1/verify/basic.md` | 存在 | 齐 |
| impl/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-product-judge/step1/impl/detail.md` | 存在 | 齐 |
| verify/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-product-judge/step1/verify/detail.md` | 存在 | 齐 |
| 人工验收 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-product-judge/step1/acceptance.md` | 存在 | 齐 |
| 摘要 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-product-judge/step1/summary.md` | 存在 | 齐 |

### 2026-08-29-template-judge

| 节点 | 所查文件 | 文件 | 小节 |
| --- | --- | --- | --- |
| Intake | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-judge/Intent.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 追问 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-judge/QA.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R1 意图评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-judge/intent-review.md` | 存在 | 齐 |
| **step1** | | | |
| step 定界 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-judge/step1/scope.md` | 存在 | 齐 |
| 抽象设计 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-judge/step1/specify.md` | 存在 | 齐 |
| R2 抽象设计评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-judge/step1/design-review.md` | 不存在 | **不判**——本需求已作废、停在抽象设计，该节点未走到 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-judge/step1/design.md` | 不存在 | **不判**——本需求已作废、停在抽象设计，该节点未走到 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-judge/step1/task/basic.md` | 不存在 | **不判**——本需求已作废、停在抽象设计，该节点未走到 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-judge/step1/task/detail.md` | 不存在 | **不判**——本需求已作废、停在抽象设计，该节点未走到 |
| R3 详细方案评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-judge/step1/task/review.md` | 不存在 | **不判**——本需求已作废、停在抽象设计，该节点未走到 |
| impl/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-judge/step1/impl/basic.md` | 不存在 | **不判**——本需求已作废、停在抽象设计，该节点未走到 |
| verify/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-judge/step1/verify/basic.md` | 不存在 | **不判**——本需求已作废、停在抽象设计，该节点未走到 |
| impl/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-judge/step1/impl/detail.md` | 不存在 | **不判**——本需求已作废、停在抽象设计，该节点未走到 |
| verify/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-judge/step1/verify/detail.md` | 不存在 | **不判**——本需求已作废、停在抽象设计，该节点未走到 |
| 人工验收 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-judge/step1/acceptance.md` | 不存在 | **不判**——本需求已作废、停在抽象设计，该节点未走到 |
| 摘要 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-judge/step1/summary.md` | 不存在 | **不判**——本需求已作废、停在抽象设计，该节点未走到 |

### 2026-08-29-template-strip-prescriptions

| 节点 | 所查文件 | 文件 | 小节 |
| --- | --- | --- | --- |
| Intake | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-strip-prescriptions/Intent.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 追问 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-strip-prescriptions/QA.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R1 意图评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-strip-prescriptions/intent-review.md` | 存在 | 齐 |
| **step1** | | | |
| step 定界 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/scope.md` | 存在 | 齐 |
| 抽象设计 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/specify.md` | 存在 | 齐 |
| R2 抽象设计评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/design-review.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/design.md` | 存在 | 齐 |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/task/basic.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| 详细设计+任务 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/task/detail.md` | 存在 | 齐（「产出」项未列小节名，只判存在性） |
| R3 详细方案评审 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/task/review.md` | 存在 | 齐 |
| impl/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/impl/basic.md` | 不存在 | **按条件不产生**（`flow.md`「impl/basic」正文：basic 段为空时本节点不产生调用） |
| verify/basic | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/verify/basic.md` | 存在 | 齐 |
| impl/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/impl/detail.md` | 存在 | 齐 |
| verify/detail | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/verify/detail.md` | 存在 | 齐 |
| 人工验收 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/acceptance.md` | 存在 | 齐 |
| 摘要 | `C:/Coding/Themis/.themis/workspace/spec/2026-08-29-template-strip-prescriptions/step1/summary.md` | 存在 | **缺小节：「中性工件说明」** |

## 10. §13 首次实跑评估

### 10.1 §13 的判据够不够用——遇到了三处只能自己发明的情况

1. **"固定小节"是按名匹配还是按语义匹配，§13 没说。** 本报告一律按**名**判——`task/review.md` 里的 `### 我知道但还没解决的` 语义上就是「未解决反馈」，`verify/detail.md` 里的 `## 本节点发现…如实报出` 语义上就是「说明」。按名判它们缺，按语义判它们齐。**两种读法给出的缺失数相差 `9` 处**（12 处小节不齐里有 9 处是"有对应内容、名字不同"）。§13 说"两项都不需要读懂内容"，这句支持按名判，本报告据此取按名；**但这是推出来的，不是写着的**。
2. **匹配的粒度没规定。** 子串命中算不算？实测这一条有真实后果：`### 判据 004 的覆盖范围，如实说明其不足` 含"说明"二字，宽松匹配会把一份**确实缺「说明」小节**的工件判为齐。**这正是 §12 反复警告的"把误报换成漏报"，而 §13 对此零规定。**
3. **全仓扫描没有落点。** §13 只定义了闸门前的两处落点，本次这种"不属任何闸门、不属任何实例"的形态无处可写。落点由派发临时指定。

**另有一处 §13 自身的数字已过期**：正文写"实测十一个已走到实现的实例中 `7` 个没有这份文件"，现为 16 个 step 中 11 个（第 6 节）。

### 10.2 交接四项够不够——冷启动下缺过两项

1. **缺"哪些节点算已走完"的判定依据。** §13 的判据是"截至该闸门为止**已走完的每个节点**"，而交接给的是"全仓所有实例的完整核查"，没给每个实例走到哪。交接虽提示"以 `state.md` 交叉验证、但不要只信它"，**却没给出两者不一致时该以谁为准**。本次没遇到真冲突（第 4 节末段），**遇到了我只能自己定**。
2. **交接第 2 项里有一条与实测不符的事实。** 交接写"实例目录：`.themis/workspace/spec/` 下每个子目录（**跳过 `template/`**）"——实测该目录下**没有** `template/`（`ls .themis/workspace` 只有 `spec`；`find .themis/workspace -name template -type d` 零命中）。这条不影响结论，**但它正是 §13 拒绝条件第一条所防的东西：一条来自上游的、未经文件系统核实的事实**。同批还有一条：交接称 `state.md`"就在十四条产出项里"，**实测不在**（第 8 节第 2 点）。**冷启动子代理若照单全收，会把 `state.md` 当作 §13 授权范围内的判定对象——本报告核了它，但已标明那是自行扩的。**

**四项之外真正缺的，是"判据的解释权归谁"**：上面 10.1 的三处空白，子代理只能自己发明，而发明结果直接改变缺失数（相差 9 处）。**§7 那四项防的是"验错对象、写错地方"，防不了"判据本身没定义"。**

### 10.3 有没有哪条拒绝条件在实际中是错的或够不到的

- **"报告'齐备'而未逐节点列出所查的文件路径"——成本极高但可执行。** 本次逐节点列出 `257` 行路径（第 9 节）。**这条在单闸门形态下是合理的**（一个 step 十四行）；**在全仓形态下它使报告的 90% 是机器可生成的清单**。不是错，是不适配本次形态。
- **"不得援引 `template.md` 作为任何小节名的事实来源"——本次完全够得到，但它暴露了一处已知缺口的现场后果。** `flow.md`「产出」项对 `Intent.md`、`QA.md`、`task/basic.md`、`task/detail.md` **四类工件未列小节名**，故这四类只判存在性；`2026-08-29-product-judge` 的 `scope.md` 自己记着"'小节齐不齐'只覆盖 `8/14`"。**本次实测印证了这个覆盖率**：16 个 step × 每 step 4 份只判存在性的工件 = `64` 份工件的内部结构本次一行也没判。
- **"只读「产出」项而不读该节点正文里的产出条件"——这条是对的，且本次真的拦下了误报。** 11 处 `impl/basic.md` 不存在，若只读「产出」项会全部报成缺失，**误报率会是真实缺失数（7）的 1.6 倍**。§13 特意把 `verify/basic` 从这条豁免里排除，也是对的——**本次 7 处真缺失，全部就是 `verify/basic.md`**。**若没有那句排除，这 7 处会被同一条豁免一并吸收，本次扫描将报出零缺失。**

### 10.4 一处能力边界的现场证据

§13 自陈"判不了报告本身是否敷衍"。**本次可佐证的是另一面**：第 5 节 12 处小节不齐里有 9 处属"内容在、名字不对"，**这类问题只有按名机械匹配才抓得到，而按名机械匹配恰恰是最容易被敷衍地做成"看起来都有"的那种检查**。判据的严格度与敷衍的可能性在这里是同向的，不是反向的。

## 11. 未做的事

- **未创建分支、未提交、未 push。**
- **未修改任何既有工件**——本次唯一写入的文件是本报告。
