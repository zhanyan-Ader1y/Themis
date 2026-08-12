# Spec 流程落地分段设计 — basic / detail

> **状态:** 待审阅 — 2026-08-10 起草。
>
> **性质:** 本文件是**设计**,回答"落地为什么要分段、怎么分、分完后契约变成什么"。它是对已审批 `docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md` 的**增量**,不替代该文件。
>
> **依赖:** 本设计获批后,需按 `docs/plan/README.md` 的授权规则,把 §5 的契约增补合入 MVP specify 并**重新批准**,之后才能改模板。

---

## 1. 背景与问题

### 1.1 需要先纠正的前提

"落地是一次性的"只对新 spec 流程成立,对 Plan 35 core 合同不成立:

- `templates/.themis/core/kernel/planning/README.md:23` — Plan 内容本来就包含 dependency-ready Impl/Verification tasks。
- `templates/.themis/core/capabilities/planning.md:31` — Planning 职责含"分解依赖就绪的 Impl/Verification 任务"。
- `templates/.themis/core/capabilities/implementation.md:15,61` — `themis-impl` 一次 Invocation 只执行**一个**依赖就绪 task,`plan_task_identity` 为必填输入。

真正一次性的是新流程:`templates/.themis/workspace/spec/template/` 每个 step 只有一个 `impl.md`,已审批 MVP specify 也只有 SPEC-IMPL-001"在 R3 范围内实现",落地内部无任何结构。

因此本设计要解决的不是"要不要拆",而是**新流程的落地结构用什么形式表达**。

### 1.2 拆分要买的收益

大需求拆分已由 step(大步骤/小步骤,见 `templates/.themis/workspace/spec/template/README.md:15`)解决,**"缩小改动范围"不能再作为本设计的理由**,那是重复投资。真实收益是三条:

1. **失败归因。** 结构改动(加字段、改签名、迁移)与行为改动混在一个 diff 里,验证判 `failed` 时无法区分是基础错还是行为错,只能整体重做。
2. **证据类型不同。** 基础的验收是结构性、可机检的;行为的验收是 EARS 行为断言(SPEC-EARS-001)。混在一起会把本可机检的部分拖进人工判断。
3. **拦截点前移。** 字段类型选错、接口签名错、迁移方向错属于"下游全部返工"型错误,在写行为代码前先验一次最省。

### 1.3 拆分带来的新风险

| 风险 | 说明 | 本设计的处理 |
|---|---|---|
| 判定漂移 | "基础"若只是习惯叫法而无判定规则,Agent 每次分类都不一样 | §3 给出唯一判定规则,并要求把判定依据写入工件(SPEC-IMPL-003) |
| 空段与强行分类 | 纯行为修改没有基础;较大 step 可能有三层(schema → 接口 → 行为) | 两段恒定存在、允许为空;三层不加第三段,由 basic 段**内部依赖排序**承载 |
| 孤儿代码 | basic 已落地后 detail 被打回,已落地字段成为无消费者的死代码;而 SPEC-INVALIDATION-001 的失效级联只作用于工件,管不到已落地代码 | 规划期由 SPEC-IMPL-003/AC2 掐掉,验收期由 SPEC-ACCEPT-002 阻断;不自动回滚代码 |

---

## 2. 范围与非目标

**范围:** spec 流程中"R3 批准之后、人工验收之前"这一段的结构、判定规则、工件布局与契约增补。

**非目标:**

- 不改 R1/R2/R3 三个评审闸门的数量与职责;**人工评审与人工验收次数保持不变**。
- 不拆 design:basic 与 detail 共享同一套架构决策,拆开会让同一决策写两遍,本身即漂移来源。不拆不等于不覆盖——basic 的结构决策仍必须由 `design.md` 承载,见 §3.4。
- 不引入 simple/full 或任何形式的路径分叉。两段是**恒定存在的有序结构**,空段只是集合为空,不是分支。
- 不新增 YAML。`templates/.themis/workspace/spec/template/spec.yaml` 目前没有 Go CLI 消费者,按 `AGENTS.md` 属既有设计债务;本设计不向其新增字段,落地段的状态记录形式留给实施计划按 Markdown-first 决定。
- 不涉及 Themico。

---

## 3. 判定规则

### 3.1 basic 与 detail

- **basic(基础)** = 同时满足两条:被本 step 其他任务依赖;单独存在时不产生外部可观测行为。典型为字段、类型、接口签名、迁移、配置项。
- **detail(详细实现)** = 消费 basic,产生 specify 中可验证外部行为的改动。

切分依据只有"是否单独产生外部可观测行为"与"是否被依赖",**不看体量、不看习惯**。

### 3.2 basic 段内部的多层

若一个 step 的结构改动本身有层次(schema → 接口契约 → 行为),**不增设第三段**。schema 与接口契约同属 basic,在 `task/basic.md` 内按依赖排序执行,顺序由任务依赖声明承载,不产生额外闸门。

### 3.3 specify 中的 basic 标识

specify 只写外部可观测行为,而 basic 按定义不产生行为,两者的交集需要明确:

- **对外契约性基础**(字段进入 API 响应或对外数据契约):可观测但不构成行为,属于**契约存在性条目**。这类条目出现在 `specify.md` 中并标 `[basic]`,验收方式是结构性断言。
- **纯内部基础**(数据库列、内部类型、私有签名):按模板 README 的定位(`是否包含数据库表:通常不包含`)**不进 specify**,只出现在 `design.md` 与 `task/basic.md`。

因此 `[basic]` 的含义是"该条目为契约存在性、由基础落地承担",不是"这是一条基础行为"。specify 的定位不被破坏,且与基础段采用结构性验证相互对齐。

### 3.4 basic 的结构决策归属

design 不拆(§2),但**不拆不等于不覆盖**:字段名、类型、接口签名、迁移方向、配置项这些 basic 的结构决策,必须在 `design.md` 中定稿并经 R2 评审。`task/basic.md` 只做分解与依赖声明,**不得引入 `design.md` 未定的结构**。

理由:字段类型选错、签名定错正是 §1.2 列出的"下游全部返工"型错误,也正是本设计立闸门要拦的东西。若结构决策的源头留在任务分解阶段由 Agent 现场发明,闸门立在了下游,决策却在上游失控,分段的拦截作用被架空。

---

## 4. 工件布局与执行顺序

### 4.1 布局

```text
step1/
  specify.md          单文件;契约存在性条目标 [basic]
  design.md
  design-review.md
  task/
    basic.md          基础任务;每条写明判定依据与被谁依赖
    detail.md         详细实现任务;每条声明依赖哪些 basic 任务
    review.md         一次 R3 同时评审 basic 与 detail
  impl/
    basic.md          基础落地记录(实现者所有)
    detail.md         详细实现落地记录(实现者所有)
  verify/
    basic.md          结构性验证(验证角色所有)
    detail.md         行为验证(验证角色所有)
  acceptance.md       末尾一次人工验收,含孤儿阻断项
```

`task` 与 `impl` 各自成文件夹,basic 与 detail 不共处一文件。`task/review.md` 随文件夹走;`design` 未拆,故 `design-review.md` 仍在 step 层。step2 及后续 step 采用同一布局。

`verify/` 是自查时补上的:验证记录**不能**放进 `impl/`。`templates/.themis/core/capabilities/implementation.md:100` 规定 implementation-writer 不得给 Verification verdict,MVP specify 的 SPEC-VERIFY-001 要求验证由独立于实现者的角色进行;把结论写进实现者拥有的工件等于让实现者给自己发结论。

其中 `verify/detail.md` 不是本设计新增的语义——现模板完全没有验证工件,SPEC-VERIFY-001/002 在模板里无处落脚,这是既有缺口。本设计顺带给它一个位置以保持两段对称。若要把范围压到最小,可只保留 `verify/basic.md`,代价是行为验证继续无处存放。

### 4.2 执行顺序

```text
R3 批准(一次,覆盖 task/basic.md 与 task/detail.md)
→ impl/basic
→ 结构性验证(独立角色)
→ impl/detail
→ 行为验证
→ 人工验收(一次)
```

硬序:basic 段通过结构性验证前,detail 段不得开始。basic 段为空时不产生落地调用,顺序不变。

### 4.3 闸门强度

| 位置 | 谁判定 | 判定依据 | 是否需要人 |
|---|---|---|---|
| R3 | Human | 详细设计与两个 task 文件 | 是,一次 |
| basic 段验证 | 独立于实现者的角色 | 结构存在、可构建、既有测试(若有)无回归 | 否 |
| detail 段验证 | 独立于实现者的角色 | EARS 行为断言;并断言每个 `task/basic.md` 声明的被依赖关系,其消费者在实际代码中存在 | 否 |
| 验收 | Human | 行为验证 `passed`（孤儿判定含于其中,验收只引用结论,不自行判定） | 是,一次 |

人工介入次数与分段前一致;新增的只有一次机器可判的结构性验证。

### 4.4 verify 与 acceptance 的职责分界

两者都是"检查",但问的不是同一个问题,实施时极易被混成一件事,故在此写死:

> **verify 问"做出来的东西对不对得上已经批准的东西";acceptance 问"批准的东西是不是你真正要的"。**

| 维度 | verify | acceptance |
|---|---|---|
| 谁判定 | 独立 Agent 角色 `independent-checker`,实现者不得验证自身产出(`capabilities/verification.md:7`、SPEC-VERIFY-001) | 人。不得从沉默或模糊肯定推断结论(`capabilities/acceptance-dialogue.md:96`) |
| 判定对象 | actual result 是否满足 Current Request 与 approved Plan(`capabilities/verification.md:29,35`) | 用户是否接受 actual result(`capabilities/acceptance-dialogue.md:31`) |
| 判定依据 | 直接读实际实现并运行允许的命令,记录 command/cwd/environment/exit/stdout/stderr(`capabilities/verification.md:29,79`) | 精简 acceptance view 与用户原话 Source Event(`capabilities/acceptance-dialogue.md:70-72`) |
| 出口 | `passed`/`failed`/`needs-planning`/`needs-specification`;`failed` 必须是有证据的 implementation-defect | `accepted`/`implementation-defect`/`needs-planning`/`needs-specification` |
| 顺序 | Impl 之后 | 只有 current verify `passed` 后才可进入(`capabilities/acceptance-dialogue.md:11`、SPEC-ACCEPT-001) |
| 性质 | 提供证据,不能授权 | 唯一授权点,只有 `accepted` 才能进 Summary(SPEC-SUMMARY-001) |

`capabilities/acceptance-dialogue.md:15` 已写死边界:acceptance **不是重复技术 Verification**。

**两者不可互相替代**,因为各自抓的是对方抓不到的错:

- verify 抓不到"做错了东西"。Plan 本身把目标写偏时,所有断言都能通过——交付完全符合 Plan,却不是用户要的。这只有人能发现,所以 acceptance 的出口里有 `needs-specification` 与 `needs-planning`,而不只是接受与否。
- acceptance 抓不到"做坏了东西"。用户看不见回归、边界与隐藏缺陷,也不会去读 stdout 比对 delta。砍掉 verify 等于让用户充当第一道防线,负担极重且不可靠,与低负担原则直接冲突。

还有一层是治理性的:verify 的独立性用于防止 Agent 自证,acceptance 的人工性是**授权**而非检查;前者是证据,后者是权力。

**落到本设计:** `verify/basic.md` 与 `verify/detail.md` 都不惊动用户,`acceptance.md` 始终只做一次。分段后 verify 从一次变两次、acceptance 仍为一次,人工负担不变,新增的全是机器可判的证据——这是"低负担 ≠ 少评审"在验证侧的对应形态。

---

## 5. 契约增补

以下条目在本设计获批后合入 MVP specify §2,并触发该文件重新批准。

### 5.1 新增

**SPEC-IMPL-002(落地分段)** — R3 批准后,系统必须把已批准任务分为有序两段 basic 与 detail;basic 段通过结构性验证前,detail 段不得开始。

- AC1:basic 未通过结构性验证时开始 detail → 拒绝。
- AC2:basic 段为空时不产生落地调用,且流程不因此分叉;两段恒定存在,空段不是路径分支。

**SPEC-IMPL-003(basic 判定)** — basic 任务必须同时满足"被本 step 其他任务依赖"与"单独不产生外部可观测行为",判定依据必须写入 `task/basic.md`。

- AC1:某 basic 任务单独产生外部可观测行为 → 分类无效,必须移入 detail。
- AC2:无任何消费者的 basic 任务 → 拒绝进入 R3。
- AC3:`task/basic.md` 引入 `design.md` 未定的结构(字段、类型、签名、迁移方向、配置项) → 拒绝。

**SPEC-VERIFY-003(结构性验证)** — basic 段必须由独立于实现者的角色以结构性证据判定:结构存在、可构建、既有测试(若有)无回归。结论必须写入验证角色所有的工件,不得写入实现者所有的工件。

- AC1:以文档、Agent 自述或文件存在判定 basic 段通过 → 拒绝。
- AC2:basic 段验证不得声称交付任何外部行为。
- AC3:basic 段验证结论出现在 `impl/` 下 → 拒绝。

**SPEC-ACCEPT-002(孤儿阻断)** — 存在已落地但无消费者的 basic 改动时,系统不得进入人工验收;必须由重规划显式处理(复用或删除)后才解除。

- AC1:detail 段被打回后直接进入验收 → 拒绝。
- AC2:fail-closed 停在 basic 段已证闸门,不自动回滚代码。

**判定者(2026-08-12 确定):** 该判定由 detail 段验证承担,不由人承担。理由是三条已批准约束同时指向它——闸门要成立必须有判定者;判定者必须独立于实现者(`SPEC-VERIFY-001`);实现层判据必须以代码为事实源(`SPEC-SOURCE-001`)。验收只引用其结论,不自行判定,因此不与"acceptance 不重复技术验证"(§4.4)冲突。条文本身不变——它只规定"不得进入人工验收",从未规定谁判。

该判定要挡住的具体场景是 AC1 挡不住的那条:detail 段重规划后**消费者被删除**。此时剩余 detail 任务可以全部通过,而 basic 改动已成孤儿,且并不存在"被打回"这一事实。

### 5.2 补充

**SPEC-INVALIDATION-001** 增补一句:失效级联作用于工件;已落地的 basic 代码不被自动失效,改由 SPEC-ACCEPT-002 阻断处理。

不补这一句,孤儿场景在现有契约中无人认领。

### 5.3 不动

**SPEC-IMPL-001** 保持原样——两段都在同一次 R3 批准范围内,分段不扩大实现授权。

**SPEC-VERIFY-001/002** 保持原样,SPEC-VERIFY-003 继承其"实现者不得验证自身产出""不得依据文档或自述判定"的要求。

---

## 6. 被否方案

| 方案 | 否决理由 |
|---|---|
| 只拆执行顺序,不加闸门 | 拿不到失败归因与前置拦截,收益接近于零 |
| 拆为两个完整 step | 人工评审与验收次数翻倍;且 basic step 没有外部行为,无法为自己写出行为级验收标准 |
| basic 与 detail 同文件分段 | 违反"两者不共处一文件";证据混杂,追溯弱 |
| 增设第三段承载多层结构 | 层数因需求而异,固定段数必然错配;依赖排序已足够 |
| detail 被打回时自动回滚 basic | 破坏性动作,与 SPEC-FAIL-001"停下等人类决定"直接矛盾,且已做的功全废 |
| 只记录孤儿不阻断 | 孤儿代码会随下一轮静默通过验收 |

---

## 7. 落地范围

获批并完成 MVP specify 重新批准后,需要改动:

1. `docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md` — 合入 §5 的四条新增与一条补充,重新批准。
2. `templates/.themis/workspace/spec/template/step1/`、`step2/` — 按 §4.1 重排为 `task/`、`impl/`、`verify/` 三个文件夹布局;原 `task.md`、`impl.md`、`task-review.md` 三个空骨架文件被取代。
3. `templates/.themis/workspace/spec/template/README.md` — 写入 §3 判定规则、§4.2 执行顺序与 `[basic]` 标识约定。
4. `templates/.themis/workspace/spec/template/step1/acceptance.md`、`step2/acceptance.md` — 增加孤儿阻断项。

具体步骤、次序与提交点由后续实施计划给出,本设计不含实施计划。

---

## 8. 评审聚焦:最容易偏离的意图

> 与 MVP specify §3 同格式,按下游返工成本从高到低排。这些是本设计落地时最可能被理解偏的点。

| # | 易漂移点 | 为何易漂移 | 本设计取向 | 需你确认 |
|---|---|---|---|---|
| B1 | **basic 判定被体量化** | 日常语义里"基础"≈ 小的、前置的、基础设施类的;而规则是两条硬判据:不单独产生外部可观测行为 + 被本 step 其他任务依赖 | 按体量分会让 basic 段吸走本属 detail 的行为改动,而结构性验证**验不了行为**,缺陷被推迟到最后才暴露——分段收益归零,只剩开销。判定依据必须逐条写入 `task/basic.md` 并在 R3 受评审,不符判定的任务在 R3 打回 | 判据只认这两条 |
| B2 | **空 basic 段被实现成路径分支** | "没有 basic 就跳过分段"是最自然的写法 | 两段恒定存在,空段只是集合为空、不产生落地调用;**不得出现"是否分段"的判断分支或开关**。否则就是被明令禁止的 simple/full 分叉换皮复活 | 空段不是分支 |
| B3 | **两段被理解成两次人工** | 只要立了闸门,就本能地想找人确认一次 | basic 段之后只有机器判定的结构性验证,**零人工节点**;人工仍是一次 R3 + 一次验收 | 人工次数不增 |
| B4 | **结构性验证向两个方向漂** | 一是验证者忍不住跑行为断言;二是退化成"文件存在即通过" | 只判结构存在、可构建、既有测试无回归;不得声称交付任何外部行为;结论不得写进 `impl/`。此刻行为尚未实现,任何行为结论都是假的 | 验证边界只有这三项 |
| B5 | **孤儿阻断退化为提醒** | "记录一下请注意"比"拦住"好写得多 | 这是硬闸门:存在无消费者的已落地 basic 就不得进入人工验收,必须由重规划显式处理(复用或删除)后才解除;同时不自动回滚代码 | 阻断而非提醒 |
| B6 | **`[basic]` 标识污染 specify** | 把所有前置工作都写进 specify 更省事 | 只有**对外契约存在性**条目可标 `[basic]`;纯内部基础(数据库列、内部类型、私有签名)不进 specify,只出现在 `design.md` 与 `task/basic.md`。否则 specify 退化成设计文档 | 内部基础不进 specify |
| B7 | **verify 与 acceptance 混为一件事** | 两者都叫"检查" | verify 对已批准物给证据,acceptance 对真实意图给授权;acceptance 不重复技术验证(§4.4) | §4.4 的分界 |
