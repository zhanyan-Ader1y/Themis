# Core 包

## 包身份

- Package identity：`themis-core`。
- 本包只提供 Prompt-level Global Rule、自然语言 Policy、Capability、Agent Profile、模板与 Workspace 边界合同。
- 本包没有功能版本，也不声明 `schema`、`workspace_schema` 或 `artifact_schema` 机器身份。

## 合同入口

| 合同 | 入口 | 职责 |
|---|---|---|
| 公共入口 | [themis Skill](../../.claude/skills/themis/SKILL.md) | 接收公共请求，加载 Global Rule 与唯一 Policy |
| Global Rule | [Orchestrator Rule](kernel/orchestrator/rules.md) | 常驻控制入口、gate、Invocation 与恢复边界 |
| Policy entry | [themis-core-control](policies/README.md) | 唯一自然语言路由、状态、失效与失败控制 |
| Capability contracts | [Capabilities](capabilities/README.md) | 十六个固定内部能力及 proposed result 合同 |
| Agent Profile contracts | [Agent Profiles](agent-profiles/README.md) | 四个固定执行权限 Profile |
| Template contracts | [Templates](templates/README.md) | Intake、lifecycle、Review、Delivery、Outcome、Learning 与 Context 候选结构 |
| Workspace boundary | [Workspace](../workspace/README.md) | 项目拥有的持久记录、工件、证据、结果与候选边界 |

## 权威边界

- 外部输入、目标语义、当前实现事实、approved Plan 与持久工件分别由其 accepted contract 拥有；文件存在或 Capability prose 不自动建立 authority。
- Capability result 始终只是 proposal；只有唯一 Policy control、完整 materialization、completion observation、reread 与 separate current pointer update 才能建立适用 authority。
- Core 对 Workspace 只读；不得把 Core 模板、Policy 或示例当作项目状态。

## 当前保证

Plan 35 只提供自然语言 Prompt 合同和人工可核验结构。Strict validator、canonical digest、Policy evaluator、state recorder、Invocation host、deterministic writer 与 machine currentness 均为 `unavailable`；不得以临时脚本或手工写入冒充这些能力。
