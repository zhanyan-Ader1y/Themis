# SKILL.md 重写报告 —— 断开 core 路径，公共入口只剩 spec 一条

## 背景

`templates/.themis/skills/themis/SKILL.md` 原先同时给出两条互斥路径：第 25–43 行指向 `.themis/core/` 的
simple/full 双路径加载链（kernel/orchestrator、policies、capabilities、agent-profiles），第 102–114 行
指向新建成的 `.themis/spec/` 控制面。`core/` 路径明写 `selected_path`，与已批准契约
`docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md:20`（"Themis 不设简易/完整之分，流程是唯一
单一路径"）直接冲突。本次任务将 `SKILL.md` 重写为只保留 spec 路径的单一公共入口。

## 重写前后结构对照

| 位置 | 重写前（114 行） | 重写后（36 行） |
| --- | --- | --- |
| frontmatter | `name` + `description`，description 描述 Source Event / Global Rule / Policy / Capability / fixed Agent Profile 四层模型 | `name` + `description`，description 改为说明这是唯一公共 Themis 入口，按 `.themis/spec/` 的流程契约推进 spec 流程 |
| 公共治理入口职责 | 依赖 core 的 Source Event、Request Intake、Global Rule、Policy、Capability、Agent Profile、route/currentness/Approval/failure count 等语义 | 改写为：入口不做流程判定，只负责定位当前节点、加载对应契约与模板；Intake 语义指向 `flow.md` |
| 加载流程（core） | 七级链：`rules.md → policies/README.md → orchestrator reference → Policy shared-topic reference → Policy phase route reference → Capability contract + fixed Agent Profile → 一次 Invocation`，并列出 `.themis/core/...` 六个稳定入口路径 | **整节删除** |
| Intake-first 边界（core） | 六步链图（Source Event → request-intake → themis-current-request-dialogue → Policy-controlled confirmation → materialized assignment → decision-bound continuation），含 `dormant-read-only` Intake 等 core 专属概念 | 精简为一句话，指向 `flow.md` 的 Intake 节点，不复述节点四件事 |
| 启动、继续与恢复（core 九步） | 九步流程，依赖 `rules.md` + `policies/README.md` 的 core 加载、Global Rule 验证、`recommended_route` 等 | **整节删除**；恢复语义保留为独立小节"中断与恢复"，指向 `flow.md`"通用失败去向"与 `template.md` 的 `state.md` 字段结构 |
| Review 与交付门禁（core） | 含 `themis-impl` / `themis-verification` Capability 名、failure budget、separate Invocations 等 | 精简为"Review 与 Impl 的顺序"一句话，指向 `flow.md` 的节点顺序，不点名 core Capability |
| 安全降级（core） | Plan 35 措辞、Invocation/failure budget、strict validator/canonical digest/Policy evaluator/state recorder/Invocation host 六项 unavailable 列举 | **整节删除**（该语义已被"当前强制水平"soft 执行器声明取代） |
| spec 流程加载链 | 五级链 + 四份文件职责分界 + soft 执行器声明（第 102–114 行） | 原样保留，作为新版核心的"加载链"节 |

## 删除的 core 概念

- Global Rule / 自然语言 Policy / internal Capability / fixed Agent Profile 四层模型
- `selected_path`、Policy route identity（`capability + selected_path + profile + status`）、`authority_scope`、Invocation、failure budget
- Source Event / Request Intake / `dormant-read-only` Intake / attachment-interception 等 core Intake 模型
- 「启动、继续与恢复」九步（依赖 `rules.md` + `policies/README.md` 的 core 加载链）
- `themis-impl` / `themis-verification` 两个 core Capability 名
- 「安全降级」整节的 Plan 35 措辞与 Invocation/failure budget 概念
- `.themis/core/kernel/orchestrator/...`、`.themis/core/policies/...`、`.themis/core/capabilities/...`、`.themis/core/agent-profiles/...` 六条稳定入口路径

## 保留并重写为 spec 语义的内容

- **每条外部用户消息先成为不可变来源，进入 Intake** —— 保留，改用 spec 措辞，指向 `.themis/spec/flow.md` 而非 core 的 Source Event 模型，不复述 Intake 节点的"前置闸门/产出/失效波及/失败去向"四件事
- **中断后从 last proven gate 恢复，不从 chat/summary/report/file existence 恢复** —— 保留为独立"中断与恢复"小节，指向 `flow.md`"通用失败去向"一节与 `template.md` 的 `state.md` 字段结构（当前节点/各闸门/当前性）
- **Review 必须在 Impl 前** —— 保留为"Review 与 Impl 的顺序"小节，指向 `flow.md` 的节点顺序与各人工评审的前置闸门，不点名具体 Capability
- **五级加载链**（`SKILL.md → README.md → flow.md → rules.md（对应小节）→ template.md`）—— 原样保留，路径均为安装后运行时路径 `.themis/spec/*.md`，不带 `templates/` 前缀
- **四份文件职责分界说明** —— 原样保留（`flow.md` 只答能不能走下一步、`rules.md` 只答怎么判、`template.md` 只答产物长什么样、`README.md` 只答去哪找前三个）
- **soft 执行器声明** —— 原样保留（机器强制 unavailable，validator/evaluator/recorder/digest 均未实现，闸门靠 Agent 遵守，状态记录在实例 `state.md`，任何文本不得声称闸门已由机器执行）

## 核验输出（真实运行结果）

```
$ grep -n 'core/' templates/.themis/skills/themis/SKILL.md || echo "零 core 引用（预期）"
零 core 引用（预期）

$ grep -c '\.themis/spec/' templates/.themis/skills/themis/SKILL.md
10

$ grep -nE '^- \*\*(前置闸门|产出|失效波及|失败去向|判据|拒绝条件|判定者)\*\*' templates/.themis/skills/themis/SKILL.md || echo "无复述（预期）"
无复述（预期）

$ wc -l templates/.themis/skills/themis/SKILL.md
36 templates/.themis/skills/themis/SKILL.md
```

零 core 引用；`.themis/spec/` 引用 10 处（≥ 4，预期达标）；无节点四件事或判定四项复述；全文从 114 行精简到 36 行。

## 遗留 concern

- `templates/.themis/core/` 目录本体未动，仍在磁盘上，但已无任何入口引用它——按任务要求，整体删除是后续独立任务（需先做端到端 replay 验证）。
- `SKILL.md` 不再提及 `themis` Go CLI 就绪后按 `SPEC-ENFORCE-002` 切换 hard 执行器的路径；该细节已存在于 `.themis/spec/README.md`"当前强制水平"一节，`SKILL.md` 通过加载链指向 README.md 即可获得，未重复声明，避免复述。
- 未验证是否有其他文件（如宿主发现机制、CI、其他 Skill）仍引用 `SKILL.md` 中已删除的 core 加载路径或 Capability 名（`themis-impl`/`themis-verification` 等）；本次任务范围明确限定只改 `SKILL.md` 一个文件，未做全仓扫描确认无孤儿引用。
