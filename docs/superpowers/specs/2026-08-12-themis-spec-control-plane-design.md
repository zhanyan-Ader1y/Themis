# `.themis/spec/` 控制面与骨架设计

> **状态:** 待审阅 — 2026-08-12 起草。
>
> **性质:** 本文件是**设计**,回答"重写后的 spec 流程,其定义面由哪些文件构成、各自管什么、实例长什么样"。行为契约本身在已审批的 `docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md`,本设计不改动它。
>
> **依赖:** 本设计落地即 `mvp.md` §5 P4 的落地①②③④。按 `mvp.md:181`,这几项须先用 writing-plans 展开为实施计划才可开始。

---

## 1. 背景

`core/` 是 simple/full 双路径模型(`capabilities/complexity-assessment.md`、`capabilities/simple-planning.md`、`planning.md` 的 `selected_path` 绑定),与已审批 `mvp.md:20` 的"不设简易/完整之分,不为任何未来的双路径做预留"直接冲突。二者不可能是同一条流程。

**处置(已定):** spec 完全独立于 core,不引用它的任何合同;core 在 spec 落地后删除。因此本设计不得借用 core 的任何东西,哪怕它暂时还在。

在此之前,落地分段(basic/detail)的规则被写进了实例骨架 `workspace/spec/template/**`。那是错的位置:template 会被复制成每个实例,定义写在里面会随实例扩散并各自漂移。本设计给这些定义一个唯一的家。

---

## 2. 包边界

- **`.themis/spec/`** —— 定义面,**运行时只读**。安装进项目后不被任何流程修改。
- **`.themis/workspace/spec/<spec-id>/`** —— 实例面,运行时**唯一可写处**。
- **与 `core/` 零引用。**

### 2.1 从 core 接手的最小必需集

只接新流程真正引用到的五项,其余随 core 一起废弃:

| 项 | 为何必须 |
|---|---|
| 执行身份 | `SPEC-VERIFY-001/AC1` 要判"同一执行身份既 impl 又 verify" |
| Intake 与来源引用 | `SPEC-INTAKE-001/002` 要求不可变来源与 `<类型>#<定位>` 引用 |
| 工件阐述方式 | `SPEC-ARTIFACT-001` |
| 状态文件 | `SPEC-ENFORCE-001` 要求 soft 执行器记录当前节点与各闸门 |
| fail-closed | `SPEC-FAIL-001` |

**明确废弃(不迁移):** core 的四个 Agent Profile、Policy 失效级联机制、Workspace 目录归属表、完整 Source Event 模型、失败预算与恢复换档。新流程需要什么就在 spec/ 里重新写一份最小的,不搬旧合同。

**废弃不等于禁止参考。** 写 spec/ 的对应内容时可以查阅 core 的原设计取经,但产出必须是重新写的、只覆盖新流程所需的最小合同——不得整段复制,也不得在 spec/ 中引用 core 的路径(core 会被删除,引用即断链)。

---

## 3. 控制面构成

```text
templates/.themis/spec/
  README.md     包身份、四份文件的索引、当前强制水平、rules.md 的拆分退出条件
  flow.md       流程契约 —— 永久单文件,按节点分 ## 小节
  rules.md      判定规则与禁令 —— 按主题分 ## 小节,每节自足
  template.md   实例结构:目录树 + 文件小节,不做定义

templates/.themis/skills/themis/SKILL.md    公共入口,唯一副本
```

`SKILL.md` 随包放在 `.themis/skills/themis/`,**安装到实际项目时移动到 `.claude/skills/`**。因此包内不再保留 `templates/.claude/skills/themis/SKILL.md`——同时存在源与安装产物即是漂移源。

该移动动作目前**没有执行者**:Themis Go CLI 的安装能力尚未实现,标记为 unavailable。在其可用前,移动由人工完成;不得用脚本替代,也不得声称安装已自动化。

### 3.1 加载链

```text
SKILL.md
→ README.md（索引,确认当前强制水平）
→ flow.md（定位当前节点、前置闸门是否满足）
→ rules.md 中该节点对应的小节（这一步怎么判）
→ template.md（要产出或更新哪些文件、哪些小节）
```

### 3.2 职责分界

| 文件 | 只回答一个问题 |
|---|---|
| `flow.md` | 现在能不能走到下一步 |
| `rules.md` | 这一步怎么判过不过 |
| `template.md` | 产物长什么样、放在哪 |
| `README.md` | 去哪找上面三个（不含任何流程或判定内容） |

这条分界写进 README 并在评审时受检。**理由是现成的教训:正是因为没有这条分界,判定规则才被写进了实例骨架。** 没有明文分界,四份文件会重新互相渗透。

---

## 4. flow.md

### 4.1 节点序列

```text
Intake（不可变来源 + 来源绑定 claims）
→ 追问（多轮,未答不得判收敛）
→ R1 意图评审 ────────────── 人工
→ 抽象设计（specify）
→ R2 抽象设计评审 ────────── 人工
→ 详细设计 + 任务（分 basic / detail 两组）
→ R3 详细方案评审 ────────── 人工
→ impl/basic
→ verify/basic ───────────── 机器判,无人工节点
→ impl/detail
→ verify/detail ──────────── 机器判,无人工节点
→ 人工验收 ───────────────── 人工
→ 摘要
```

人工节点固定四处:R1、R2、R3、验收。两次验证均无人工节点。

### 4.2 每个节点写四件事

**前置闸门**(什么满足了才能进)、**产出**(哪些实例文件被创建或更新)、**失效波及**(本节点变了,下游哪些作废)、**失败去向**(fail-closed 停在哪个已证闸门)。

判定规则一律不写在这里,指向 `rules.md` 的对应小节。

### 4.3 flow.md 永久单文件

流程契约本质是一张图:闸门的前置是上游节点的产出,失效级联跨节点波及。价值在于**能被一次读完**。拆成 `nodes/*.md` 后,读某一节点的人看不到"它的失效会波及谁",而漏读上下游关系正是失效级联最易出错处。

**这条与体量无关**:flow.md 长到五百行也不拆,只在内部分节。

---

## 5. rules.md

### 5.1 十个主题小节

| # | 主题 | 来源条文 |
|---|---|---|
| 1 | 来源与分层事实源 | `SPEC-INTAKE-002`、`SPEC-SOURCE-001` |
| 2 | 意图收敛判据 | `SPEC-QUESTION-001/002` |
| 3 | 评审投影的低负担要求 | `SPEC-REVIEW-LOWBURDEN` |
| 4 | basic/detail 判定 | `SPEC-IMPL-003` 及三条 AC |
| 5 | `[basic]` 标识 | 落地分段设计 §3.3 |
| 6 | 结构决策归属 | `SPEC-IMPL-003/AC3` |
| 7 | 验证:身份独立、basic 三项、detail 断言范围 | `SPEC-VERIFY-001/002/003` |
| 8 | 孤儿阻断 | `SPEC-ACCEPT-002` |
| 9 | 工件阐述方式 | `SPEC-ARTIFACT-001` |
| 10 | 失败:fail-closed,不预算不学习 | `SPEC-FAIL-001` |

### 5.2 每节固定四项

**适用节点 / 判据 / 拒绝条件 / 判定者。**

第四项是教训换来的:孤儿阻断当初没写判定者,三份文档各指了一个互斥的角色,闸门退化成没人能合法勾上的框。**任何判据没有判定者就不是闸门。**

### 5.3 暂不按节点拆分,但留缝

判定规则彼此独立,天然可拆。现在不拆的理由不是体量(全部约八十至一百二十行),而是**拆分边界应由"什么内容一起变化"决定,而现在这些规则一条都还没经过真实使用**,没有证据支持任何边界。边界画错比不拆更贵。

每节写成自足形态(读一节不需读另一节),将来抽出时整节搬走、原处留一行索引即可。

**拆分的触发条件(写入 README,可判定,不用"感觉长了"):**

- **单节失衡**:某一节超过全文三分之一——它已经不是"一节"了;
- **独立演进**:连续三次修改都只动同一节——该节有自己的变更节奏,直接对应"一起变化的内容住在一起"这条拆分原则;
- **总量阈值**:`rules.md` 全文超过 300 行——现预计八十至一百二十行,300 行意味着规则量翻近三倍,此时单文件内定位成本明显上升,按需加载的收益开始超过维护多文件加索引的成本。

满足任一条即把该节抽为独立文件。三条都可数,不留解释空间——避免"要不要拆"每次重新变成主观争论。

---

## 6. template.md

只记录结构,**不做任何定义**;含义一律归 `rules.md`。

### 6.1 实例目录树

```text
.themis/workspace/spec/<spec-id>/
  Intent.md
  intent-review.md
  QA.md
  state.md
  step<N>/
    specify.md
    design.md
    design-review.md
    task/
      basic.md  detail.md  review.md
    impl/
      basic.md  detail.md
    verify/
      basic.md  detail.md
    acceptance.md
```

**两个新增文件:**

- `intent-review.md` —— 原骨架中 R2 有 `design-review.md`、R3 有 `task/review.md`,**R1 没有任何落点**,而 `SPEC-REVIEW-R1/AC1` 要能判定 R1 是否 approved。放在 spec 根而非 step 下:Intent 每个 spec 一份,R1 也只一次。
- `state.md` —— `SPEC-ENFORCE-001` 要求的人类可读状态文件。原 `spec.yaml` 已因无 Go 消费者且节点集不含 impl、verify 仅单一 flag 而移除。

### 6.2 文件小节

| 文件 | 小节 |
|---|---|
| `Intent.md` | 问题 / 期望结果 / 核心链路 / 范围与非做 / 约束 / 来源引用 |
| `QA.md` | 第 N 轮 → 问 / 答 / 来源（追加写入） |
| `intent-review.md` | 投影 / 未解决反馈 / 结论 |
| `state.md` | 当前节点 / 各闸门 / 当前性 |
| `specify.md` | 行为条目（`### SPEC-<主题>-<序号>` + 验收判据）/ 来源覆盖 |
| `design.md` | 架构与边界 / 结构决策 / 取舍 / 事实依据 |
| `design-review.md` | 投影 / 未解决反馈 / 结论 |
| `task/basic.md` | 基础任务 → `### T-B<n>` |
| `task/detail.md` | 详细实现任务 → `### T-D<n>` |
| `task/review.md` | 评审范围 / 分类核查 / 未解决反馈 / 结论 |
| `impl/basic.md`、`impl/detail.md` | 执行身份 / 实际改动 / 与批准范围的偏差 / 命令记录 |
| `verify/basic.md`、`verify/detail.md` | 执行身份 / 断言与实际结果 / 命令证据 / 结论 / 说明 |
| `acceptance.md` | 交付视图 / 阻断核查 / 用户原话 / 结论 |

`impl` 与 `verify` 的**执行身份**小节是 `SPEC-VERIFY-001/AC1` 的落点——此前从工件上无从判定同一身份是否既 impl 又 verify,现在两处一比即得。`verify` 的**说明**小节是人类语义的落点,其余四节均为控制事实。

---

## 7. 与已审批 specify 的对应

### 7.1 `SPEC-ARTIFACT-001` 的读法

该条**不要求**把工件拆成两个物理文件,它约束的是**工件文件内的阐述方式**:每个工件文件必须同时承载可核验的控制事实(绑定了什么上游、执行身份、结论、证据)与人类语义(说明、理由),缺一不可。

§6.2 的小节即按此配比:控制事实与人类语义各有落点。

### 7.2 D1 无需修改

`mvp.md:145`(D1)写"不再有独立 specify 工件"。**specify 即抽象设计**——同一节点的两个叫法,不存在独立于抽象设计之外的第二份 specify 工件,条文成立,不必重新批准。

### 7.3 落地①②③④ 的对应

| 落地项 | 本设计对应物 |
|---|---|
| ① `flow.md` | §4 |
| ② 工件模板 | §6 的 `template.md`(单文件记录结构,取代实体骨架树) |

| ③ 语义 references + `SKILL.md` | §5 的 `rules.md` 与 §3 的 `SKILL.md` |
| ④ soft 执行器 + 状态文件约定 | §6.1 的 `state.md` 与 §4.2 的失败去向 |

落地⑤(端到端 replay)不在本设计范围。

### 7.4 ② 与 `mvp.md:174` 的两处偏离(需知悉)

`mvp.md:174` 把落地②写为"工件模板(`.themis/spec/templates/`,配对 record/content + trace + EARS)"。本设计有两处偏离:

- **形态**:不建 `templates/` 目录、不产出配对 record/content 文件,改为单份 `template.md` 只记录结构。依据是 §7.1——`SPEC-ARTIFACT-001` 约束的是文件内的阐述方式,不要求物理配对。
- **路径**:`.themis/spec/template.md`,而非 `.themis/spec/templates/`。

`mvp.md` §5 P4 作为"基准"批准保留,本偏离不改动 §2 的任何行为契约条目,但落地时应同步更新 `mvp.md:174` 的路径与形态描述,避免留下与 §5 的字面冲突。

---

## 8. 迁移

1. **建 `templates/.themis/spec/`**,写入 README、flow.md、rules.md、template.md 四份。
2. **把定义从实例骨架外移**:`workspace/spec/template/README.md` 的落地分段章节,以及 `task/*`、`impl/*`、`verify/*`、`acceptance.md` 中的全部引用块与说明文字,迁入 `rules.md` 与 `flow.md`。
3. **实体骨架树退场**:`workspace/spec/template/**` 由 `template.md` 取代。
4. **`SKILL.md`**:写入 `templates/.themis/skills/themis/SKILL.md`,删除 `templates/.claude/skills/themis/SKILL.md`。
5. **core 删除**:待 spec 落地并验证后单独执行,不在本设计范围。

外移不是纯搬家:现形态是"提示就在手边",抽走后闸门规则完全依赖 `.themis/spec/` **被读到**。而机器强制目前 unavailable,读不读全靠 Prompt。因此 `SKILL.md` 的加载链(§3.1)必须与 `flow.md`、`rules.md` 同批落地,不得延后。

---

## 9. 非目标

- 不改动已审批的 `mvp.md` 任何行为契约条目。
- 不实现机器强制:validator、evaluator、recorder、digest 均为 unavailable,任何文本不得声称闸门已由机器执行。
- 不新增 YAML(无 Go CLI 消费者)、不新增 Python/Shell 脚本、不引入版本概念或版本目录。
- 不设 simple/full 分叉,不为双路径预留开关。
- 不迁移 core 的非最小必需集合同(§2.1)。
- 不包含 core 的删除动作与端到端 replay。
