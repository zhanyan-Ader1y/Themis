# .themis/spec/template.md

本文件只回答一个问题：**产物长什么样、放在哪**。只记录结构，不做任何定义——含义判定一律见 `rules.md`，流程走向（现在能不能走到下一步）一律见 `flow.md`。

实例面 `.themis/workspace/spec/<spec-id>/` 是运行时唯一可写处：`.themis/spec/` 下的定义面四份文件安装后只读，不被任何流程修改；每个 spec 实例在 `<spec-id>` 之下产出自己的一套工件，工件之间不共享、不跨实例引用。

**spec-id 的形态**：`yyyy-MM-dd-<主题>`，日期取**实例创建日**（Intake 产出之日）。该日期可从 git 取得（`git log --diff-filter=A` 的最早一条），**不需任何人记忆或另行约定**。

**不用序号**：序号要有人维护"下一个用几"这个状态，而日期前缀天然有序、可从内容自证。**同一天可有多个实例**，按主题区分即可。（本项目 `docs/adr/` 的文件命名同源，其论证见该目录的 `AGENTS.md`。）

## 实例目录树

```text
.themis/workspace/spec/<spec-id>/
  Intent.md
  intent-review.md
  QA.md
  state.md
  step<N>/
    scope.md
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
    summary.md
```

**意图分两层。** 上层是**用户的完整需求**，写在实例根的 `Intent.md`，由 R1 一次确认——需求本身与它的 step 分解一并确认。下层是**该需求的一个分解单元**，写在 `step<N>/scope.md`，只说明本 step 承担上层哪一块、边界在哪；它的合法性由上层 R1 已批准的 step 分解背书，**不单独评审**，评审仍是 R1/R2/R3 三道。

一个 spec 实例承载**一个完整用户需求**；其下多个 step 是该需求的分解，彼此可以互不重叠，但合起来构成该需求，全部完成才算需求达成。**step 不是无关需求的容器**——真正无关的需求另起 spec 实例。

`Intent.md`、`intent-review.md`、`QA.md`、`state.md` 每个 spec 一份，放在实例根目录：R1 确认的是上层需求与分解方式，只发生一次，因此 `intent-review.md` 不随 step 分目录，与 `Intent.md`、`QA.md`、`state.md` 一起留在根。其余工件按 step 分目录，每个 step 拥有独立的一套 `scope.md`、`specify.md`、`design.md`、`design-review.md`、`task/`、`impl/`、`verify/`、`acceptance.md`、`summary.md`；`summary.md` 绑定的是该 step 的实际交付，因此与 `acceptance.md` 同层，不提到实例根目录。

step 编号规则：大步骤取整数，大步骤内的小步骤取小数。同一需求自顶向下、由抽象到具体拆为多个大步骤；大步骤内部再拆小步骤。

## 文件小节

| 文件 | 小节 |
| --- | --- |
| `Intent.md` | 问题 / 期望结果 / 核心链路 / 范围与非做 / 约束 / **step 分解** / 来源引用 |
| `QA.md` | 第 N 轮 → 问 / 答 / 来源（追加写入） |
| `intent-review.md` | 投影 / 未解决反馈 / 用户原话 / 结论 |
| `state.md` | 当前节点 / 各闸门 / 当前性（统管全部 step：spec 级节点各一行，step 级节点按 step 分组） |
| `scope.md` | 承担的上层分解项 / 本 step 边界 / 与其他 step 的关系 |
| `specify.md` | 行为条目（`### SPEC-<主题>-<序号>` + 可选标识 `[basic]`／`[横切]` + 验收判据 + 来自 `Intent.md` 哪一节）/ 来源覆盖 |
| `design.md` | 架构与边界 / 结构决策 / 取舍 / 事实依据 |
| `design-review.md` | 投影 / 未解决反馈 / 用户原话 / 结论 |
| `task/basic.md` | 基础任务 → `### T-B<n>` |
| `task/detail.md` | 详细实现任务 → `### T-D<n>` |
| `task/review.md` | 评审范围 / 分类核查 / 未解决反馈 / 用户原话 / 结论 |
| `impl/basic.md`、`impl/detail.md` | 执行身份 / 实际改动 / 与批准范围的偏差 / 命令记录 |
| `verify/basic.md` | 执行身份 / 断言与实际结果 / 命令证据 / 结论 / 说明 |
| `verify/detail.md` | 执行身份 / 断言与实际结果（每条断言注明对应任务）/ 命令证据 / 结论 / 说明 |
| `acceptance.md` | 交付视图 / 阻断核查（引用验证断言的结论）/ 用户原话 / 结论 |
| `summary.md` | 交付摘要 / 绑定的验收结论 / 中性工件说明 |

上表每份工件的小节划分是 `rules.md` §9 的落点：§9 是贯穿全部产出工件节点的通用规则，不依附任何单一节点，因此不会被 `flow.md` 的某个节点专门引用——它正是通过本文件逐份工件的小节划分获得落点。

`impl/basic.md`、`impl/detail.md`、`verify/basic.md`、`verify/detail.md` 的**执行身份**小节是身份独立判定的落点，两处一比即得（判定见 `rules.md` §7）；`verify/basic.md`、`verify/detail.md` 的**说明**小节是人类语义的落点，其余四节（执行身份 / 断言与实际结果 / 命令证据 / 结论）均为控制事实（配比要求见 `rules.md` §9）。

`task/basic.md` 中每个 `### T-B<n>` 固定记四项：结构改动、判定依据、被哪些 detail 任务依赖、design.md 中的出处（判定见 `rules.md` §4、§6）。

`task/detail.md` 中每个 `### T-D<n>` 固定记三项：行为目标、对应 `specify.md` 条目、依赖的基础任务——后两项分别是 trace 链与 `rules.md` §8 消费者关系在本文件的落点。

`specify.md` 每个 `### SPEC-` 条目要指向 `Intent.md` 对应源节、`verify/detail.md` 每条断言注明其验证的任务编号、`acceptance.md` 的阻断核查小节按上表括注引用验证断言的结论——这三项与上一段的环 2 落点合起来，构成 `SPEC-TRACE-001` 所要求的追溯链在本文件的四处落点。链的检出判据与判定者见 `rules.md` §12。

## 编号引用写法

引用 `SPEC-` 与 `T-D` 编号时，**只用下列三种写法**。三种都来自已完成实例的实际书写，不是新发明的。

| 写法 | 例 | 用在什么时候 |
| --- | --- | --- |
| **完整** | `判据 SPEC-CLAIMCLI-003` | 只引一条 |
| **逗号并列** | `判据 SPEC-CLAIMCLI-002、004` | 引数条且不连续 |
| **区间** | `判据 SPEC-CLAIMFORM-001 至 005` | 引一段连续的 |

**裸数字必须紧跟在一个完整编号之后，中间不得插入其他文字。** 写成「判据 SPEC-X-002，以及 004」会使 `004` 取不到——中间隔了文字，它就只是个普通数字。

**为什么要规定**：`rules.md` §12 的追溯链检出按这三种写法展开编号。**写法没有规定时，扫描只能假定编号总以完整形式出现**——而实际书写里区间与逗号缩写都在自发使用，两种都曾使检出误报（该缺口两次实发，见 `rules.md` §12）。**判定与展开规则见 `rules.md` §12，本节只规定怎么写。**

## 断言形态

工件里每个数字与存在性断言，都必须记明它是哪条命令跑出来的。**适用于全部数字与存在性断言**——行数、计数、命中数、文件是否存在，不按"主张性/辅助性"或所在小节区分。

**两种记法，单个断言写在一行内**（下面两行是记法示例，路径写成占位名——若写真实路径，`themis verify` 会把示例当成断言去跑，而示例里的数字必然随文件增长而失真）：

```text
两段式（常态）：  `wc -l < 某文件.md` → `131`
三段式（有推导时）：`ls -1 某目录/` → `README.md flow.md rules.md template.md` → `4 份文件`
```

**两段式是常态**——绝大多数断言的命令输出就是断言值本身。**三段式只在"据原样输出推出另一个值"时用**，中段记原样输出，末段记据此写下的断言值。

**CLI 的比对规则**（`themis` CLI 尚不存在，本段写明供其实现时消费）：两段式比对命令的真实输出与断言值是否相等；三段式先比对真实输出与中段是否相等，**中段到断言值的推导由人判**——那是语义判断，CLI 判不了。

**判定者**：验证角色在验证时判形态是否合规，与它逐条对照判据同时进行（`rules.md` §7）。**本段不由机器校验**——当前强制水平见 `README.md`；CLI 可用后它接管的是"重跑比对"，形态是否合规仍由人判。
