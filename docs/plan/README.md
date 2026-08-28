# Themis 活动实施计划

`docs/plan/**` 只保存尚待实施或验收的活动计划。本目录不建立第二套产品规范。

**当前主线是根目录 `.themis/spec/` 重新设计。** 已批准行为契约位于 `docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md`,控制面在 `.themis/spec/`(`README.md`/`flow.md`/`rules.md`/`template.md` 四份文件)，**单份入库，无包源副本**——两层包源模型对 `.themis` 已于 2026-08-26 取消。控制面写作约束见 `.themis/AGENTS.md`。

**编号 Plan 体系（35/36/37/80/90）已退役并于 2026-08-27 删除。** 它们是 Plan 35 旧 core 体系的产物，实现载体（该体系的合同与模板）已先于 2026-08-22 删除，计划本身随之失去对象。内容在 git 历史中可回溯，但**不作为任何现行依据**——重启须依届时 current contracts 整体重基线并重新审批。

## 授权规则

- 每个计划必须单独批准后才能实施。
- 一个计划的批准不自动批准依赖或后续计划。
- 实施发现 current authority 需要变化时,先更新设计并重新批准。
- 未观察真实验证输出前不得宣称完成。
- 已退役计划不得直接取用重启,必须依届时 current contracts 整体重基线并重新审批。

## 已完成

| 活动 | 完成 | 产物 |
|---|---|---|
| 落地①–④ 控制面 | 2026-08-18 | `.themis/spec/` 四份文件,按 [`2026-08-18-themis-spec-control-plane.md`](../superpowers/plans/2026-08-18-themis-spec-control-plane.md) |
| 落地⑤ 端到端 replay | 2026-08-22,验收 accepted | [`spec-replay/drift-log.md`](spec-replay/drift-log.md)、[`spec-replay/hard-enforcement-list.md`](spec-replay/hard-enforcement-list.md);实例工件在 `.themis/workspace/spec/2026-08-19-core-removal/`;载体产物为 `templates/.themis/core/` 删除(98 个文件) |
| 控制面两处缺口修复 | 2026-08-24 | `flow.md`「impl/detail」加空段限定；`verify/basic` 新增 `不适用` 取值；另修根因——`state.md` 闸门取值此前控制面从未定义，致 replay 自建约定并重载"已证" |
| 意图分两层 | 2026-08-24 | spec 级 `Intent.md`（新增「step 分解」）+ step 级 `scope.md`；`flow.md` 新增「step 定界」节点与失效级联的唯一例外条款 |
| `templates/.themis/` 清空 | 2026-08-26，验收 accepted | 控制面改为 `.themis/` 单份入库，两层包源模型对 `.themis` 取消；实例工件在 `.themis/workspace/spec/2026-08-26-workspace-cleanup/` |

`mvp.md` §5 P4 的落地次序①–⑤至此全部完成,其 §2 行为契约在全程一行未动。

## 活动队列

**当前为空。** 下一步尚未确定,任一项启动前须单独展开实施计划并批准。

**唯一剩余候选：hard 执行器强制项**——[`hard-enforcement-list.md`](spec-replay/hard-enforcement-list.md) 11 条，按实发次数排序。

此前并列的另两个候选**均已解决，不再是候选**：控制面两处缺口于 2026-08-24 修复（`2026-08-26-workspace-cleanup` 实例是新增 `不适用` 取值的首个使用者，两处此前需裁定的地方均由条款直接给出答案，一次裁定未动用）；`templates/.themis/workspace/README.md:5` 的残留随该目录整体删除而消失。

### 2026-08-26 后新增的实发证据

`2026-08-26-workspace-cleanup` 实例走完一遍流程，三条强制项各自又实发一次，**改变了原有排序依据**：

| 强制项 | replay 时实发 | 本次新增 | 形态 |
|---|---|---|---|
| 第 3 项 授权可追溯到逐字原话 | 2 次 | **+3** | R2、R3、人工验收各一次——评审者给了结论未给并列裁定，或给了裁定未给结论 |
| 第 1 项 数值/存在性 claim 由命令产生 | 8+ 次 | +1 | 活引用清点漏检：范围限定 `*.md`，且模式对 `filepath.Join` 分段拼接的路径无效，两者叠加 |
| 第 6 项 验证身份取自派发元数据 | 2 次 | +1 | impl 与 verify 两段均由同一会话承担，身份独立不成立 |

**第 3 项由实发 2 次升至 5 次。** 该文件末尾原记着一处权衡——按频次它排第 3，按"闸门完整性"该排第 1；**新证据使其按频次也进入前三，该权衡自行消解**。它与其余各项的性质差别仍然成立：其余防的是记录不准，它防的是闸门失效。

另需记：第 3 项四次实发均由执行体自觉按住，未产生实际越权。**但自觉不可持续，且失效后不可检出**——推断补足的授权与真授权在工件文本上无法区分。

Themico 的实施证据与人工 replay 记录已随其全部内容归并到 `.themico/evidence/`；Themico 与 Themis 松耦合，不构成 Themis 运行前提。

## 通用限制

> 本节原有四条写于 2026-07-31（提交 `d606967`，Plan 35 语境），至今未改。2026-08-27 逐条核实后，**三条移除、一条保留**——移除的不是"不再重要"，而是它们的约束对象已消失、或已由更近的活条款承载，留着会造成两处写同一事实的漂移。

- 不引入功能版本、版本目录、compatibility、upgrade 或 migration。**（保留，但注意仓库根 `AGENTS.md` 第 69 行已有等价条款"项目中不允许添加版本概念，不允许出现版本形式的目录"——本条是跨模块约定在本目录的重复，将来若要消除重复，删本条、留 `AGENTS.md` 那条。）**

**已移除的三条与理由（如实记录，不是静默删除）：**

- ~~不覆盖已有 `.themis`~~——该约束针对"安装动作会覆盖目标项目已有内容"这一风险，而两层包源模型已于 2026-08-26 对 `.themis` 取消（`templates/` 下现只余 `.themico`）。**约束对象不存在了。**
- ~~缺失 evaluator、validator、recorder、runtime、Agent host、worktree 或 command support 时 fail closed~~——这些是 Plan 35 的组件名，当前控制面零引用。**fail-closed 本身仍然成立**，但它现在由 `.themis/spec/flow.md`「通用失败去向」与 `rules.md` §10 承载，条件也不再按这些组件名表述。
- ~~不得用 Prompt、README、template、policy 或 directory 的存在冒充 machine enforcement~~——**判断仍然成立，但已由更近、更权威的条款承载**：`.themis/spec/README.md`「当前强制水平」写明"机器强制 unavailable……任何文本不得声称闸门已由机器执行"。那是本次重构的控制面自己写的，不受 Plan 35 退役影响。**引用这条约束时应指向 `.themis/spec/README.md`，不再指向本文件。**

**四处已闭合实例的工件仍指向本文件的这一条**（`2026-08-26-authorization-traceability` 的 `Intent.md` 两处、`step1/specify.md` 两处）。**它们不改写**——那是已 accepted 的历史记录，记的是当时依据什么。读者按本节的说明换算即可。改写历史记录会把证据改成结论。
