# Themis 活动实施计划

`docs/plan/**` 只保存尚待实施或验收的活动计划。本目录不建立第二套产品规范。

**当前主线是根目录 `.themis/spec/` 重新设计。** 已批准行为契约位于 `docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md`,控制面在 `.themis/spec/`(`README.md`/`flow.md`/`rules.md`/`template.md` 四份文件)。模块详细合同与模板状态位于 `templates/.themis/**/README.md`。

**编号 Plan 体系已于 2026-08-22 整体退役**,移入 [`retired/`](retired/)。退役理由、各 Plan 退役时的状态与重启条件见该目录 README。退役是停止推进,不是删除——其中的验收审计、静态核验输出与十六场景 replay 记录是历史证据,不得改写。

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
| 落地⑤ 端到端 replay | 2026-08-22,验收 accepted | [`spec-replay/drift-log.md`](spec-replay/drift-log.md)、[`spec-replay/hard-enforcement-list.md`](spec-replay/hard-enforcement-list.md);实例工件在 `.themis/workspace/spec/core-removal/`;载体产物为 `templates/.themis/core/` 删除(98 个文件) |

`mvp.md` §5 P4 的落地次序①–⑤至此全部完成,其 §2 行为契约在全程一行未动。

## 活动队列

**当前为空。** 下一步尚未确定,任一项启动前须单独展开实施计划并批准。

候选全部来自落地⑤ replay 的实际产出,不是推测:

| 候选 | 依据 | 备注 |
|---|---|---|
| hard 执行器强制项 | [`hard-enforcement-list.md`](spec-replay/hard-enforcement-list.md) 11 条,按实发次数排序 | 是否着手、按频次组还是闸门完整性组,两种排序的权衡已写在该文件末尾,未代为决定 |
| 控制面两处未修复缺口 | Ruling 18、Ruling 20 绕开的空段互斥读法 | 未修复。下一个空段实例会在同一处停下 |
| `workspace/README.md:5` 残留 | 所有者在 replay 验收中裁定「作为新 step 处理」 | 需自设计节点起完整走流程,另建 `step2/` |

另有 [`themico-core/`](themico-core/) 保存 Themico 的实施证据与人工 replay 记录;Themico 与 Themis 松耦合,不构成 Themis 运行前提。

## 通用限制

- 不引入功能版本、版本目录、compatibility、upgrade 或 migration。
- 不覆盖已有 `.themis`。
- 缺失 evaluator、validator、recorder、runtime、Agent host、worktree 或 command support 时 fail closed。
- 不得用 Prompt、README、template、policy 或 directory 的存在冒充 machine enforcement。
