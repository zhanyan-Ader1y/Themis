# Spec 流程落地分段（basic / detail）实施计划

> **给执行者：** 必需子技能——用 `superpowers:subagent-driven-development`（推荐）或 `superpowers:executing-plans` 逐任务实施本计划。步骤使用 `- [ ]` 复选框语法跟踪。

**目标：** 把 spec 流程的"落地"从一次性改为有序两段（basic / detail），先合入契约并取得重新批准，再重排模板布局。

**架构：** 一次 R3 批准覆盖两段任务；basic 段落地后由独立角色做结构性验证，通过后才开始 detail 段；人工验收仍只在 step 末尾一次。两段恒定存在、允许为空，空段不产生落地调用，不构成路径分支。

**技术栈：** 纯 Markdown 合同与模板。无代码、无测试框架、无脚本。

**设计来源：** `docs/superpowers/specs/2026-08-10-spec-flow-basic-detail-split-design.md`（已确认）。本计划不引入该设计之外的语义。

---

## 全局约束

每个任务的要求都隐含包含本节。取值逐字来自 `AGENTS.md` 与设计文档。

- 所有 Markdown 内容使用中文（`AGENTS.md:53`）。
- 不新增 YAML 文件、YAML 模板或 YAML 语义合同；没有 Go CLI 消费者的 YAML 视为设计债务（`AGENTS.md:41-44`）。本计划**不修改** `spec.yaml`。
- 不新增 Python、Shell 或任何临时脚本；需要自动执行的能力必须由 Themis Go CLI 提供，当前不可用时明确标记 unavailable（`AGENTS.md:45-46`）。
- 不引入版本概念或版本形式的目录（`AGENTS.md:51`）。
- WIKI 类文件不记录任务状态（`AGENTS.md:50`）。
- 单一路径：不得出现 simple/full 分叉，不得为"是否分段"预留判断分支或开关。
- 不覆盖已有 `.themis`；本计划只动 `templates/.themis` 与 `docs/`。

## 验证方式说明

本仓库没有测试框架，且禁止新增脚本。因此每个任务的验证循环是：

1. **改动前观察** —— 运行只读检索，确认目标内容当前不存在（相当于"测试先失败"）。
2. **改动**。
3. **改动后观察** —— 重复同一检索，确认命中（相当于"测试转绿"）。

只读检索（`git`、`find`、`rg`）是一次性观察命令，不是项目脚本，不违反 `AGENTS.md:46`。**机器强制在当前阶段一律 unavailable**，本计划不得声称任何闸门已由机器强制执行。

## 执行前置

当前分支为 `main`。开始 Task 1 前先建分支：

```bash
git checkout -b spec-flow-basic-detail-split
```

以下两份文件目前未提交，属本次工作的既有产物，随 Task 1 一并纳入：

- `docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md`
- `docs/superpowers/specs/2026-08-10-spec-flow-basic-detail-split-design.md`

---

## 文件结构

| 文件 | 动作 | 职责 |
|---|---|---|
| `docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md` | 修改 | 承载行为契约；本次新增 4 条、补充 1 条 |
| `templates/.themis/workspace/spec/template/step1/task/{basic,detail,review}.md` | 新建 | 任务分解与一次性任务评审 |
| `templates/.themis/workspace/spec/template/step1/impl/{basic,detail}.md` | 新建 | 两段落地记录，实现者所有 |
| `templates/.themis/workspace/spec/template/step1/verify/{basic,detail}.md` | 新建 | 两段验证结论，验证角色所有 |
| `templates/.themis/workspace/spec/template/step1/{task,impl,task-review}.md` | 删除 | 被上述文件夹取代（现为空骨架） |
| `templates/.themis/workspace/spec/template/step1/acceptance.md` | 修改 | 增加孤儿阻断检查 |
| `templates/.themis/workspace/spec/template/step2/**` | 同上 | 与 step1 完全一致 |
| `templates/.themis/workspace/spec/template/README.md` | 修改 | 写入判定规则、执行顺序、`[basic]` 标识、verify/acceptance 分界 |

**不动的文件：** `spec.yaml`、`step.md`、`Intent.md`、`QA.md`、`specify.md`、`design.md`、`design-review.md`。执行者不得"顺手"修改它们。

---

## Task 1：把四条新增与一条补充合入 MVP specify

**文件：**

- 修改：`docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md`

**接口：**

- 消费：设计文档 §5 的契约文本。
- 产出：`SPEC-IMPL-002`、`SPEC-IMPL-003`、`SPEC-VERIFY-003`、`SPEC-ACCEPT-002` 四个新标识符，供 Task 3–6 引用；`SPEC-INVALIDATION-001` 增补一句。

- [ ] **步骤 1：观察改动前状态**

```bash
rg -n "SPEC-IMPL-002|SPEC-IMPL-003|SPEC-VERIFY-003|SPEC-ACCEPT-002" docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md
```

预期：无输出（退出码 1）。四个标识符当前都不存在。

- [ ] **步骤 2：在 §2 F 段插入 SPEC-IMPL-002 与 SPEC-IMPL-003**

定位到 `### F. 实现与独立验证` 下的这一行：

```markdown
**SPEC-IMPL-001** — 实现必须在 R3 批准范围内进行:不得修改 current-request、plan 或验收要求,不得做无关重构。
```

在其**后**插入：

```markdown
**SPEC-IMPL-002** — R3 批准后,系统必须把已批准任务分为有序两段 basic（基础)与 detail（详细实现);basic 段通过结构性验证前,detail 段不得开始。
- AC1:basic 未通过结构性验证时开始 detail → 拒绝。
- AC2:basic 段为空时不产生落地调用,且流程不因此分叉;两段恒定存在,空段不是路径分支。

**SPEC-IMPL-003** — basic 任务必须同时满足"被本 step 其他任务依赖"与"单独不产生外部可观测行为",判定依据必须写入 basic 任务工件。
- AC1:某 basic 任务单独产生外部可观测行为 → 分类无效,必须移入 detail。
- AC2:无任何消费者的 basic 任务 → 拒绝进入 R3。
- AC3:basic 任务工件引入详细设计未定的结构(字段、类型、签名、迁移方向、配置项) → 拒绝。
```

- [ ] **步骤 3：在 §2 F 段插入 SPEC-VERIFY-003**

定位到这一行：

```markdown
**SPEC-VERIFY-002** — 验证必须依据实际实现与证据判定 `passed`/`failed`,不得依据文档、Agent 自述或文件存在判定通过。
```

在其**后**插入：

```markdown
**SPEC-VERIFY-003** — basic 段必须由独立于实现者的角色以结构性证据判定:结构存在、可构建、既有测试(若有)无回归。结论必须写入验证角色所有的工件,不得写入实现者所有的工件。
- AC1:以文档、Agent 自述或文件存在判定 basic 段通过 → 拒绝。
- AC2:basic 段验证不得声称交付任何外部行为。
- AC3:basic 段验证结论出现在实现者所有的落地工件中 → 拒绝。
```

- [ ] **步骤 4：在 §2 G 段插入 SPEC-ACCEPT-002**

定位到这一行：

```markdown
**SPEC-ACCEPT-001** — 仅当验证为 `passed` 时系统才可进入验收;仅当 Human `accepted`（接受)后才可进入摘要。
```

在其**后**插入：

```markdown
**SPEC-ACCEPT-002** — 存在已落地但无消费者的 basic 改动时,系统不得进入人工验收;必须由重规划显式处理(复用或删除)后才解除。
- AC1:detail 段被打回后直接进入验收 → 拒绝。
- AC2:fail-closed 停在 basic 段已证闸门,不自动回滚代码。
```

- [ ] **步骤 5：为 SPEC-INVALIDATION-001 增补一句**

把 §2 D 段的这一条：

```markdown
**SPEC-INVALIDATION-001** — 当任一工件变为新 revision（修订),系统必须使其全部下游工件失效(stale),且失效工件不得被当作 current（最新)继续使用。
- AC1:修改 current-request 后,已有 plan 与三个评审标记 stale,实现不得基于 stale 工件继续。
```

替换为：

```markdown
**SPEC-INVALIDATION-001** — 当任一工件变为新 revision（修订),系统必须使其全部下游工件失效(stale),且失效工件不得被当作 current（最新)继续使用。失效级联作用于工件;已落地的 basic 代码不被自动失效,改由 SPEC-ACCEPT-002 阻断处理。
- AC1:修改 current-request 后,已有 plan 与三个评审标记 stale,实现不得基于 stale 工件继续。
- AC2:已落地 basic 代码不得因下游失效被自动回滚或自动删除。
```

- [ ] **步骤 6：把文件状态改为待重新批准**

把文件头第 1–9 行的标题与状态行：

```markdown
# Themis Spec 流程 MVP — Specify（已审批）

> **状态:** **已审批** — 2026-08-08 由项目所有者(zhanyan)批准。
```

替换为：

```markdown
# Themis Spec 流程 MVP — Specify（待重新批准）

> **状态:** **待重新批准** — 原版本于 2026-08-08 由项目所有者(zhanyan)批准;2026-08-10 依 `docs/superpowers/specs/2026-08-10-spec-flow-basic-detail-split-design.md` §5 新增 SPEC-IMPL-002、SPEC-IMPL-003、SPEC-VERIFY-003、SPEC-ACCEPT-002 并增补 SPEC-INVALIDATION-001,按 `docs/plan/README.md` 授权规则需重新批准。
```

其余头部行（性质、审批结论、落地状态）保持不变。

- [ ] **步骤 7：观察改动后状态**

```bash
rg -c "SPEC-IMPL-002|SPEC-IMPL-003|SPEC-VERIFY-003|SPEC-ACCEPT-002" docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md
rg -n "待重新批准" docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md
```

预期：第一条命中计数为 6（`rg -c` 按行计数：四条新增条目的定义行各命中 1 行,共 4 行;文件头状态行一次性提到全部四个标识符,算 1 行;SPEC-INVALIDATION-001 的增补句提到 SPEC-ACCEPT-002,再算 1 行;合计 6 行)；第二条命中标题行与状态行共 2 处。

- [ ] **步骤 8：提交**

```bash
git add docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md docs/superpowers/specs/2026-08-10-spec-flow-basic-detail-split-design.md docs/superpowers/plans/2026-08-10-spec-flow-basic-detail-split.md
git commit -m "docs: 为 spec 流程落地分段增补行为契约

新增 SPEC-IMPL-002/003、SPEC-VERIFY-003、SPEC-ACCEPT-002，
增补 SPEC-INVALIDATION-001；MVP specify 转入待重新批准。

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 2：人工重新批准闸门

**这是人类闸门，不是 Agent 任务。** Task 3 及之后的全部任务在本任务关闭前不得开始——这正是本设计要建立的 gate 语义，执行者若跳过即自我否定。

**文件：**

- 修改：`docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md`（仅状态行）

**接口：**

- 消费：Task 1 产出的四个新标识符与状态标记。
- 产出：`已审批` 状态，是 Task 3 的前置条件。

- [ ] **步骤 1：向用户呈现变更**

呈现 Task 1 的实际 diff，并明确说明：本次只增不改，SPEC-IMPL-001、SPEC-VERIFY-001/002 原文未动。

```bash
git show --stat HEAD
git diff HEAD~1 -- docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md
```

- [ ] **步骤 2：等待用户明确批准**

不得从沉默、模糊肯定或"看起来没问题"推断批准。用户明确说明批准前，本步骤保持未完成。

- [ ] **步骤 3：批准后把状态改回已审批**

把文件头状态行替换为：

```markdown
# Themis Spec 流程 MVP — Specify（已审批）

> **状态:** **已审批** — 2026-08-08 首次批准;2026-08-10 因新增 SPEC-IMPL-002、SPEC-IMPL-003、SPEC-VERIFY-003、SPEC-ACCEPT-002 与 SPEC-INVALIDATION-001 增补,由项目所有者(zhanyan)重新批准。
```

- [ ] **步骤 4：观察并提交**

```bash
rg -n "已审批" docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md
git add docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md
git commit -m "docs: MVP specify 重新批准

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

预期：命中标题行与状态行共 2 处，且不再出现"待重新批准"。

---

## Task 3：重排 step1 布局

**前置：** Task 2 已关闭。

**文件：**

- 删除：`templates/.themis/workspace/spec/template/step1/task.md`、`impl.md`、`task-review.md`（三个均为空文件）
- 新建：`step1/task/basic.md`、`step1/task/detail.md`、`step1/task/review.md`
- 新建：`step1/impl/basic.md`、`step1/impl/detail.md`
- 新建：`step1/verify/basic.md`、`step1/verify/detail.md`
- 修改：`step1/acceptance.md`

**接口：**

- 消费：Task 2 批准的 SPEC-IMPL-002/003、SPEC-VERIFY-003、SPEC-ACCEPT-002。
- 产出：七个新模板文件的骨架结构，Task 4 逐字复制到 step2，Task 5 在 README 中引用其路径。

- [ ] **步骤 1：观察改动前状态**

```bash
find templates/.themis/workspace/spec/template/step1 -type f | sort
```

预期输出恰好七行：`acceptance.md`、`design-review.md`、`design.md`、`impl.md`、`specify.md`、`task-review.md`、`task.md`。确认 `task.md`、`impl.md`、`task-review.md` 大小为 0（可用 `find ... -size 0` 复核），删除不会丢内容。

- [ ] **步骤 2：删除被取代的三个空文件**

```bash
git rm templates/.themis/workspace/spec/template/step1/task.md templates/.themis/workspace/spec/template/step1/impl.md templates/.themis/workspace/spec/template/step1/task-review.md
```

- [ ] **步骤 3：创建 `step1/task/basic.md`**

```markdown
## 基础任务

> 判定：不单独产生外部可观测行为，且被本 step 其他任务依赖。两条同时满足才是 basic。
> 结构决策以 design.md 为准，本文件只做分解与依赖声明，不得引入 design.md 未定的字段、类型、签名、迁移方向或配置项。
> 本段为空是合法的，空段不产生落地调用，也不改变流程走向。

### T-B1

- 结构改动：
- 判定依据（为何不单独产生外部可观测行为）：
- 被哪些 detail 任务依赖：
- design.md 中的出处：
```

- [ ] **步骤 4：创建 `step1/task/detail.md`**

```markdown
## 详细实现任务

> 判定：消费基础任务，产生 specify.md 中可验证的外部行为。

### T-D1

- 行为目标：
- 对应 specify.md 条目：
- 依赖的基础任务：
```

- [ ] **步骤 5：创建 `step1/task/review.md`**

```markdown
## 评审范围

一次评审同时覆盖 task/basic.md 与 task/detail.md。不拆成两次人工评审。

## 分类核查

- [ ] 每个 basic 任务都写明了判定依据与被谁依赖
- [ ] 没有 basic 任务单独产生外部可观测行为
- [ ] 没有无消费者的 basic 任务
- [ ] basic 任务未引入 design.md 未定的结构

## 未解决反馈

## 结论
```

- [ ] **步骤 6：创建 `step1/impl/basic.md`**

```markdown
## 基础落地记录

> 本文件由实现者所有。**不得**写入验证结论——结构性验证结论属于 verify/basic.md。

## 实际改动

## 与批准范围的偏差

## 命令记录
```

- [ ] **步骤 7：创建 `step1/impl/detail.md`**

```markdown
## 详细实现落地记录

> 本文件由实现者所有。**不得**写入验证结论——行为验证结论属于 verify/detail.md。
> 开始条件：verify/basic.md 结论为通过。

## 实际改动

## 与批准范围的偏差

## 命令记录
```

- [ ] **步骤 8：创建 `step1/verify/basic.md`**

```markdown
## 结构性验证

> 本文件由独立于实现者的验证角色所有。
> 只判三项：结构存在、可构建、既有测试（若有）无回归。
> 不得声称交付任何外部行为——此刻行为尚未实现，任何行为结论都是假的。

## 断言与实际结果

## 命令证据

## 结论
```

- [ ] **步骤 9：创建 `step1/verify/detail.md`**

```markdown
## 行为验证

> 本文件由独立于实现者的验证角色所有。
> 逐条对 specify.md 的验收判据断言，不得依据文档、自述或文件存在判定通过。

## 断言与实际结果

## 命令证据

## 结论
```

- [ ] **步骤 10：修改 `step1/acceptance.md`**

现有内容：

```markdown
## summary


## user acceptance
```

替换为：

```markdown
## summary


## 验收阻断检查

> 任一项未通过则不得进入人工验收。

- [ ] 不存在已落地但无消费者的 basic 改动
- [ ] verify/detail.md 结论为通过


## user acceptance
```

- [ ] **步骤 11：观察改动后状态**

```bash
find templates/.themis/workspace/spec/template/step1 -type f | sort
```

预期输出恰好十一行：`acceptance.md`、`design-review.md`、`design.md`、`impl/basic.md`、`impl/detail.md`、`specify.md`、`task/basic.md`、`task/detail.md`、`task/review.md`、`verify/basic.md`、`verify/detail.md`。

- [ ] **步骤 12：提交**

```bash
git add templates/.themis/workspace/spec/template/step1
git commit -m "feat: step1 模板改为 task/impl/verify 三文件夹布局

basic 与 detail 分文件；验证结论与落地记录分属不同角色的工件。

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 4：同步 step2 布局

**前置：** Task 3 已完成。

**文件：** 与 Task 3 相同，路径中的 `step1` 全部换成 `step2`。

**接口：**

- 消费：Task 3 创建的七个文件的**逐字内容**。
- 产出：step1 与 step2 结构完全一致。

- [ ] **步骤 1：观察改动前状态**

```bash
find templates/.themis/workspace/spec/template/step2 -type f | sort
```

预期七行，与 Task 3 步骤 1 的 step1 初始状态相同。

- [ ] **步骤 2：删除被取代的三个空文件**

```bash
git rm templates/.themis/workspace/spec/template/step2/task.md templates/.themis/workspace/spec/template/step2/impl.md templates/.themis/workspace/spec/template/step2/task-review.md
```

- [ ] **步骤 3：复制 step1 的新结构到 step2**

```bash
cp -r templates/.themis/workspace/spec/template/step1/task templates/.themis/workspace/spec/template/step1/impl templates/.themis/workspace/spec/template/step1/verify templates/.themis/workspace/spec/template/step2/
cp templates/.themis/workspace/spec/template/step1/acceptance.md templates/.themis/workspace/spec/template/step2/acceptance.md
```

模板骨架内容与 step 序号无关，逐字复制即可，不需要改写任何一行。

- [ ] **步骤 4：观察两个 step 是否完全一致**

```bash
diff -r templates/.themis/workspace/spec/template/step1 templates/.themis/workspace/spec/template/step2
```

预期：无输出，退出码 0。两个 step 的模板骨架应逐字相同（`specify.md`、`design.md`、`design-review.md` 三个空文件也相同）。若有输出，说明复制不完整，修正后重跑。

- [ ] **步骤 5：提交**

```bash
git add templates/.themis/workspace/spec/template/step2
git commit -m "feat: step2 模板同步 task/impl/verify 布局

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 5：在模板 README 写入规则

**前置：** Task 4 已完成。

**文件：**

- 修改：`templates/.themis/workspace/spec/template/README.md`

**接口：**

- 消费：Task 2 批准的四条契约；Task 3/4 建立的文件路径。
- 产出：模块级规则文本，是模块合同的常驻位置（模块核心设计随包以 README 保存）。

- [ ] **步骤 1：观察改动前状态**

```bash
rg -n "basic|detail|落地分段" templates/.themis/workspace/spec/template/README.md
```

预期：无输出。README 当前完全没有分段概念。

- [ ] **步骤 2：在 `## 关键定义` 之前插入新章节**

定位到这一行：

```markdown
## 关键定义
```

在其**前**插入：

```markdown
## 落地分段：basic 与 detail

### 判定

- **basic（基础）** = 同时满足两条：被本 step 其他任务依赖；单独存在时不产生外部可观测行为。典型为字段、类型、接口签名、迁移、配置项。
- **detail（详细实现）** = 消费 basic，产生 specify.md 中可验证外部行为的改动。

切分只看这两条硬判据，不看体量、不看习惯。判定依据必须逐条写入 `task/basic.md`，并在任务评审时受检。

结构改动本身有层次时（schema → 接口契约 → 行为）**不增设第三段**：它们同属 basic，在 `task/basic.md` 内按依赖排序执行，不产生额外闸门。

### 结构决策的归属

design 不拆，但不拆不等于不覆盖。字段名、类型、接口签名、迁移方向、配置项这些结构决策必须在 `design.md` 中定稿并经设计评审；`task/basic.md` 只做分解与依赖声明，不得引入 `design.md` 未定的结构。

### specify.md 中的 `[basic]` 标识

- **对外契约性基础**（字段进入 API 响应或对外数据契约）：可观测但不构成行为，属契约存在性条目，写入 `specify.md` 并标 `[basic]`。
- **纯内部基础**（数据库列、内部类型、私有签名）：不进 specify.md，只出现在 `design.md` 与 `task/basic.md`。

`[basic]` 的含义是"该条目为契约存在性、由基础落地承担"，不是"这是一条基础行为"。

### 执行顺序

```text
任务评审（一次，同时覆盖 task/basic.md 与 task/detail.md）
→ impl/basic
→ verify/basic（结构性验证，独立角色，无人工节点）
→ impl/detail
→ verify/detail（行为验证，独立角色，无人工节点）
→ acceptance（人工，一次）
```

硬序：`verify/basic` 通过前，`impl/detail` 不得开始。

两段恒定存在。basic 段为空时不产生落地调用，顺序不变——空段是集合为空，不是路径分支，不得为"是否分段"设置任何判断分支或开关。

### verify 与 acceptance 的分界

> verify 问"做出来的东西对不对得上已经批准的东西"；acceptance 问"批准的东西是不是你真正要的"。

| 维度 | verify | acceptance |
|---|---|---|
| 谁判定 | 独立于实现者的角色 | 人 |
| 判定对象 | 实际结果是否满足需求与已批准方案 | 用户是否接受实际结果 |
| 判定依据 | 直接读实际实现并运行允许的命令，记录命令与输出 | 精简验收视图与用户原话 |
| 性质 | 提供证据，不能授权 | 唯一授权点 |

acceptance 不重复技术验证。分段后 verify 从一次变两次、acceptance 始终一次，人工负担不变。

### 孤儿阻断

存在已落地但无消费者的 basic 改动时，不得进入人工验收，必须由重规划显式处理（复用或删除）后才解除。同时不自动回滚代码：fail-closed 停在 basic 段已证闸门，等人决定。

### 当前强制水平

以上全部规则目前**没有机器强制**：仓库尚无 Themis Go CLI 的对应能力，规则依赖 Agent 遵守与人工评审。不得声称任何闸门已由机器执行。

```

- [ ] **步骤 3：观察改动后状态**

```bash
rg -c "basic" templates/.themis/workspace/spec/template/README.md
rg -n "## 落地分段：basic 与 detail" templates/.themis/workspace/spec/template/README.md
```

预期：第一条命中计数大于 10；第二条命中 1 处，且位置在 `## 关键定义` 之前。

- [ ] **步骤 4：提交**

```bash
git add templates/.themis/workspace/spec/template/README.md
git commit -m "docs: spec 模板 README 写入落地分段规则

判定、结构决策归属、[basic] 标识、执行顺序、verify/acceptance 分界与孤儿阻断。

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 6：一致性核验

**前置：** Task 5 已完成。

**文件：** 不修改任何文件。本任务只产出观察结论；发现不符时回到对应任务修正，不在本任务内"顺手改"。

**接口：**

- 消费：Task 1–5 的全部产出。
- 产出：可交付的核验结论。

- [ ] **步骤 1：核验模板树与设计 §4.1 一致**

```bash
find templates/.themis/workspace/spec/template -type f | sort
```

逐项比对设计文档 §4.1 的布局块。预期 step1 与 step2 各十一个文件，加上顶层 `README.md`、`spec.yaml`、`step.md`、`Intent.md`、`QA.md`。

- [ ] **步骤 2：核验四条新契约都在 specify 中且状态为已审批**

```bash
rg -n "SPEC-IMPL-002|SPEC-IMPL-003|SPEC-VERIFY-003|SPEC-ACCEPT-002|待重新批准" docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md
```

预期：四个标识符各命中，`待重新批准` 无命中。

- [ ] **步骤 3：核验全局约束未被违反**

```bash
git diff --stat main...HEAD
find templates/ -name "*.py" -o -name "*.sh"
git diff --stat main...HEAD -- "*.yaml"
```

预期：第一条显示改动只落在 `docs/` 与 `templates/.themis/workspace/spec/template/`；第二条无输出（未新增脚本）；第三条无输出（`spec.yaml` 未被触碰）。

- [ ] **步骤 4：向用户报告**

报告实际观察输出，不得用"应该没问题"替代证据。明确声明：本次交付的是 Prompt 层合同与模板，**机器强制 unavailable**，闸门依赖 Agent 遵守与人工评审。

---

## 自查

**规格覆盖：** 设计 §5 的四条新增与一条补充 → Task 1；§7 的四项落地范围 → Task 1（第 1 项）、Task 3/4（第 2、4 项）、Task 5（第 3 项）；重新批准要求 → Task 2；§3.4 结构决策归属 → Task 1 步骤 2 的 AC3 与 Task 5 的 README 章节；§4.4 verify/acceptance 分界 → Task 5。§8 的 B1–B7 是评审视角，不需要独立任务，其取向已分别落到 Task 3 的模板提示语与 Task 5 的 README 文本中。

**占位符扫描：** 无 TBD/TODO；每个改动步骤都给出了完整的最终文本；模板骨架中的空白字段是模板本身的填写位，不是计划的占位符。

**命名一致性：** 四个新标识符在 Task 1 定义，在 Task 5、Task 6 中逐字复用；文件路径 `task/basic.md`、`task/detail.md`、`task/review.md`、`impl/basic.md`、`impl/detail.md`、`verify/basic.md`、`verify/detail.md` 在 Task 3、4、5、6 中保持一致。
