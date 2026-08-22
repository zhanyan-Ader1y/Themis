# Plan 35 Markdown 合同重构迁移核验索引

## 核验边界

本索引记录 replacement Plan 35 从既有 YAML 表示迁移到 Markdown-first 表示时的人工语义一致性证据。2026-07-31 的重新接受仍是历史事实，但它只覆盖当时的 YAML 表示；在本次表示重构完成、重新建立静态证据和人工重放并由用户明确重新接受前，不得用旧证据宣称当前 Markdown-first 合规或当前 `32/32 PASS`。

本次“迁移”只表示一次性合同表示重构与 authority cutover，不形成安装升级、版本升级或 runtime migration 产品能力。

## Evidence 分片

| 分片 | 唯一写入任务 | 当前观察 | 未裁决 GAP |
|---|---:|---|---|
| [基线](migration-parity/baseline.md) | 任务 1 | 已记录并由独立 reviewer 核对提交后 clean 工作树、27 个活动 YAML、四个大文件和旧证据适用边界 | 无 |
| [跨模块权威](migration-parity/authority.md) | 任务 2 | 已建立 107 行短入口与十个功能 references；22 章、32 条标准和关键不变量完整，两个 Medium finding 修复后 scoped re-review APPROVED | 无 |
| [自然语言 Policy](migration-parity/policy.md) | 任务 3 | 已建立唯一 Policy entry、七个共享主题 references 和六个阶段 route references；旧 YAML 的 98 个合法组合已由实施者逐项映射并经 fresh reviewer 独立确认，唯一 Medium finding 修复后 scoped re-review `APPROVED` | 无 |
| [Global Rule 与公共入口](migration-parity/control-entry.md) | 任务 4 | 已把旧 308 行 Rule 拆为 96 行常驻入口与六个 gate references，并把公共 `themis` Skill 改为加载唯一自然语言 Policy；首轮一个 Medium Source Event binding finding 修复后 scoped re-review `APPROVED` | 无 |
| [Intake 与 Planning 模板](migration-parity/intake-and-planning-templates.md) | 任务 5 | 已建立 12 个候选 Markdown templates；首次五个 Medium finding 与一个 Low 行数误差修复后，scoped re-review `APPROVED` | 无 |
| [Review 与 Delivery 模板](migration-parity/review-and-delivery-templates.md) | 任务 6 | 已建立 19 个候选 Markdown templates；首次独立 review 的四个 High finding 修复后，scoped re-review `APPROVED` | 无 |
| [Capability 合同](migration-parity/capabilities.md) | 任务 7 | README 与十六个 Capability 的 17 个 fenced YAML result envelope 已迁移为 Markdown 字段合同；首次两个 High finding 与协调会话发现的 target 表述漂移修复后，scoped re-review `APPROVED` | 无 |
| [Core、Workspace 与 Context](migration-parity/core-workspace-context.md) | 任务 8 | 已建立 17 个 Markdown candidates 并保留八个旧 YAML；Core/Workspace 切片直接 APPROVED，Context 与 evidence 首轮 finding 修复后 scoped re-review `APPROVED` | 无 |
| [全局切换](migration-parity/cutover.md) | 任务 9 | 已一次删除 27 个旧 YAML、13 个 flat Markdown template 与 `.gitkeep`；替代路径、活动消费者和固定不变量已由实施者核对，fresh reviewer 首轮三项 evidence/语言闭环 finding 修正后 scoped re-review `APPROVED` | 无 |

## 当前结论

- 当前 Plan 35 产品语义仍以 2026-07-31 已接受的 replacement 设计为重构输入。
- 新的 Markdown-first 规则使旧 YAML 表示与旧静态/replay 证据不再足以证明当前表示合规。
- 当前阶段已完成基线冻结、任务 2–8 的 Markdown candidate 构建与独立复核，以及任务 9 的全局 Markdown authority cutover。27 个旧 YAML、13 个 flat Markdown template 与 `.gitkeep` 已删除，活动消费者已切换；fresh reviewer 首轮三项 evidence/语言闭环 finding 修正后 scoped re-review `APPROVED`。
- Plan 36 与 Plan 37 在新的 Plan 35 证据完成并由用户明确重新接受前继续暂停。
- criterion 32 当前为 `PENDING USER RE-ACCEPTANCE`，用户沉默不构成接受。

## 自动 Go CLI 检查状态

`unavailable`。当前仓库没有已批准并已实现的 Themis Go CLI 文档/合同核验命令；未使用 Python、Shell 临时脚本或虚构子命令替代。
