# Plan 35 Markdown authority cutover 核验

## 核验边界

本分片记录任务 9 将 replacement Plan 35 的活动表示一次性切换为 Markdown-first contracts 的人工观察。2026-07-31 的接受仍是历史事实，只覆盖当时的 YAML 表示；本 cutover 不建立新的静态一致性、人工 replay、机器执行或用户重新接受证明。

本次“迁移”只表示一次性合同表示重构和 authority cutover，不形成安装升级、版本升级、runtime migration 或兼容转换产品能力。

## 切换前置条件

实施者在删除前观察到：

- 任务 1–8 的八个迁移 evidence 分片均存在，且各自的“未裁决 GAP”为“无”。
- `migration-parity.md` 已记录跨模块 authority、自然语言 Policy、Global Rule/公共入口、模板、Capability、Core、Workspace 与 Context 的候选迁移结果。
- Policy 分片已记录旧 YAML 中观察到的 98 个合法结果组合到自然语言控制规则的双向人工映射及 fresh reviewer 复核。
- 删除目标在本次 cutover 前没有额外未审阅内容变更；`git diff --name-only` 对 27 个 YAML、13 个 flat Markdown template 与 `.gitkeep` 无输出。
- 活动安装 guidance、公共 `themis` Skill、Plan 35 active implementation description、current authority entry 与 package README 已切换到 Markdown Policy、分层 templates、`workspace/project.md` 和拆分 references。

## 27 个 YAML 删除矩阵

| 旧路径 | 活动替代表示 | 实施者观察 |
|---|---|---|
| `core/policies/transitions.yaml` | `core/policies/README.md`、七个 shared-topic references、六个 phase-route references | 旧路径不存在；替代 Policy 包存在 |
| `core/core.yaml` | `core/README.md` | 旧路径不存在；Core package index 存在 |
| `workspace/manifest.yaml` | `workspace/project.md` 与 `workspace/references/` | 旧路径不存在；配置入口与五个 references 存在 |
| `workspace/context/catalog.yaml` | `workspace/context/catalog.md` | 旧路径不存在；Markdown Catalog 存在 |
| `core/protocols/context/common-schema.yaml` | `core/protocols/context/references/common-fields.md` | 旧路径不存在；descriptive contract 存在 |
| `core/protocols/context/context-item-schema.yaml` | `core/protocols/context/references/context-item.md` | 旧路径不存在；descriptive contract 存在 |
| `core/protocols/context/catalog-schema.yaml` | `core/protocols/context/references/catalog.md` | 旧路径不存在；descriptive contract 存在 |
| `core/protocols/context/bundle-schema.yaml` | `core/protocols/context/references/bundle.md` | 旧路径不存在；descriptive contract 存在 |
| `core/protocols/context/signal-schema.yaml` | `core/protocols/context/references/signal.md` | 旧路径不存在；descriptive contract 存在 |
| `core/templates/request-intake-source-event.yaml` | `core/templates/request-intake/source-event.md` | 旧路径不存在；structured Markdown record 存在 |
| `core/templates/request-intake-proposal.yaml` | `core/templates/request-intake/proposal.md` | 旧路径不存在；structured Markdown record 存在 |
| `core/templates/request-intake-decision.yaml` | `core/templates/request-intake/decision.md` | 旧路径不存在；structured Markdown record 存在 |
| `core/templates/current-request.yaml` | `core/templates/current-request/record.md` | 旧路径不存在；paired family control record 存在 |
| `core/templates/questioning-round.yaml` | `core/templates/questioning-round/record.md` | 旧路径不存在；paired family control record 存在 |
| `core/templates/grounding.yaml` | `core/templates/grounding/record.md` | 旧路径不存在；structured Markdown record 存在 |
| `core/templates/complexity-assessment.yaml` | `core/templates/complexity-assessment/record.md` | 旧路径不存在；structured Markdown record 存在 |
| `core/templates/plan.yaml` | `core/templates/plan/record.md` | 旧路径不存在；paired family control record 存在 |
| `core/templates/plan-check.yaml` | `core/templates/plan-check/record.md` | 旧路径不存在；structured Markdown record 存在 |
| `core/templates/review.yaml` | `core/templates/review-projection/record.md` | 旧路径不存在；paired family control record 存在 |
| `core/templates/review-check.yaml` | `core/templates/review-check/record.md` | 旧路径不存在；structured Markdown record 存在 |
| `core/templates/review-approval.yaml` | `core/templates/review-approval/record.md` | 旧路径不存在；paired family control record 存在 |
| `core/templates/review-feedback.yaml` | `core/templates/review-feedback/record.md` | 旧路径不存在；paired family control record 存在 |
| `core/templates/impl-result.yaml` | `core/templates/impl-result/record.md` | 旧路径不存在；paired family control record 存在 |
| `core/templates/verification.yaml` | `core/templates/verification/record.md` | 旧路径不存在；paired family control record 存在 |
| `core/templates/acceptance.yaml` | `core/templates/acceptance/record.md` | 旧路径不存在；paired family control record 存在 |
| `core/templates/summary.yaml` | `core/templates/summary/record.md` | 旧路径不存在；paired family control record 存在 |
| `core/templates/failure-learning.yaml` | `core/templates/failure-learning/record.md` | 旧路径不存在；paired family control record 存在 |

实施者通过文件树观察到 `templates/.themis` 下活动产品 YAML 数量为 0。公共 `templates/.claude/skills/themis/SKILL.md` 只保留宿主发现要求的 `name` 与 `description` frontmatter；该宿主元数据不是 Themis 产品语义合同。

## 13 个 flat Markdown template 与 `.gitkeep` 删除矩阵

| 旧路径 | 活动替代表示 | 实施者观察 |
|---|---|---|
| `core/templates/current-request.md` | `core/templates/current-request/content.md` | 旧路径不存在；paired content 存在 |
| `core/templates/questioning-round.md` | `core/templates/questioning-round/content.md` | 旧路径不存在；paired content 存在 |
| `core/templates/plan.md` | `core/templates/plan/content.md` | 旧路径不存在；paired content 存在 |
| `core/templates/review.md` | `core/templates/review-projection/content.md` | 旧路径不存在；paired content 存在 |
| `core/templates/review-approval.md` | `core/templates/review-approval/content.md` | 旧路径不存在；paired content 存在 |
| `core/templates/review-feedback.md` | `core/templates/review-feedback/content.md` | 旧路径不存在；paired content 存在 |
| `core/templates/impl-result.md` | `core/templates/impl-result/content.md` | 旧路径不存在；paired content 存在 |
| `core/templates/verification.md` | `core/templates/verification/content.md` | 旧路径不存在；paired content 存在 |
| `core/templates/acceptance.md` | `core/templates/acceptance/content.md` | 旧路径不存在；paired content 存在 |
| `core/templates/summary.md` | `core/templates/summary/content.md` | 旧路径不存在；paired content 存在 |
| `core/templates/failure-learning.md` | `core/templates/failure-learning/content.md` | 旧路径不存在；paired content 存在 |
| `core/templates/context-resolution.md` | `core/templates/context/resolution.md` | 旧路径不存在；Context aid 存在 |
| `core/templates/context-summary.md` | `core/templates/context/summary.md` | 旧路径不存在；Context aid 存在 |
| `core/templates/.gitkeep` | 分层 Markdown template tree | 旧占位路径不存在；实际模板目录非空 |

## 活动消费者扫描

实施者在删除后扫描了以下活动范围：

- `templates/.themis/**/*.md`
- `templates/.claude/skills/themis/SKILL.md`
- Plan 35 active implementation description 与 Plan index
- current Plan 35 authority entry

未观察到把 `transitions.yaml`、`manifest.yaml`、`core.yaml`、`catalog.yaml`、五个 Context schema YAML、machine record、YAML/Markdown pair 或被删除 flat template 当作 current authority 的活动引用。

唯一保留的活动命中位于 `core/policies/README.md`：它明确把旧 `transitions.yaml` 的 98 个合法结果组合描述为本次表示迁移的人工覆盖观察值，并明确否认其是产品 identity、永久常量、Go CLI 输入或可解析 DSL。该命中是历史迁移来源说明，不是 current authority dependency。

Plan 36、37、80 只在顶部 status/rebaseline notice 中声明其正文的旧 YAML 假设已经失效；历史正文继续作为历史或未来重设计输入保存，没有被伪装成当前可实施需求。

## 固定产品不变量追溯

| 不变量 | 当前 authority owner / 活动入口 | 实施者观察 |
|---|---|---|
| Intake-first、immutable Source Event | 公共 `themis` Skill、Global Rule Intake reference、Policy Intake routes | 外部消息必须先形成 Source Event 并进入 `request-intake` |
| 双 authority scope | Policy `authority-scopes.md`、Capability bindings、Workspace isolation reference | `request-intake` 与 `lifecycle` 只交换稳定不可变引用，不共享动态 state、budget、continuation、pointer 或 completion |
| 十六 Capability | `core/capabilities/` 与 Policy `capability-bindings.md` | 十六个 individual Capability contract 存在；README 不计为 Capability |
| 四个 Agent Profile | `core/agent-profiles/` 与 Policy `capability-bindings.md` | 四个 Profile contract 存在；只有 `themis-impl` 绑定 `implementation-writer` |
| Review-before-Impl | 公共 `themis` Skill、Review route、Delivery route | current explicit Approval 是 Impl 前置门禁 |
| Verify 包含 Impl 与独立 Verification | 公共 `themis` Skill、`routes/delivery.md`、Templates README | 固定顺序为 `themis-impl → independent themis-verification`，writer 不自验 |
| Human Acceptance | Delivery route、Acceptance pair | 只有 current Verification `passed` 后才能进入 Acceptance |
| Summary 与 completion 分离 | Delivery route、Summary pair、retention reference | Summary 还要求 Human Acceptance `accepted`；Summary pair current 后才单独观察 lifecycle completion |
| 三次失败预算 | Policy failure-control、安装 guidance | Intake 与 lifecycle scope-local identity 分离；第三次 counted failure 终止并禁止第四次 Invocation |
| Failure Learning | Capability contract、Learning route、failure-control | scope-bound、non-blocking、non-recursive、candidate-only |
| `dormant-read-only` | Intake retention reference、安装 guidance、Workspace retention reference | 只作为完成后的 retention fact，不是 disposition、Capability status 或 route dimension |
| 物化、重读与 current pointer | Policy materialization/currentness reference、Templates README | revision 完整写入并重读后才可观察；current pointer 单独更新和重读；pair 任一 half 缺失使整个 revision invalid |

## 实施者结论

- 27 个旧 YAML、13 个被目录结构替代的 flat Markdown template 和 `.gitkeep` 已作为一个 cutover 批次删除。
- 对应 Markdown Policy、templates、Workspace 与 Context 替代路径均存在。
- 活动消费者已切换；未观察到仍依赖已删除表示的 current-authority 引用。
- 固定 Plan 35 产品不变量仍有明确活动 authority owner。
- 本结论只证明人工观察到的表示 cutover，不证明自然语言 Policy 语义已完成新的全量静态核验或 replay。

## 自动 Go CLI 检查状态

`automated-go-check: unavailable`

当前没有已批准并已实现的 Themis Go CLI 命令可自动执行 cutover、合同一致性或 currentness 检查。未使用 Python、Shell parser、一次性 validator 或虚构 CLI 子命令替代。

## Fresh reviewer 复核

Fresh read-only reviewer 独立核对了任务 9 计划、当前未提交工作树、删除集、替代路径、活动消费者、产品不变量、后续计划 status notice 与本 evidence。Reviewer 未修改文件、未创建 worktree、未提交，也未写 migration evidence。

首轮结论为 `CHANGES REQUIRED`，但 reviewer 明确确认 Markdown authority 产品树本身通过核心核查：

- 27 个 YAML、13 个 flat Markdown template 与 `.gitkeep` 删除准确；
- 映射替代路径全部存在，`templates/.themis` 活动 YAML 数量为 0；
- 未发现活动消费者把旧表示当作 current authority；
- 固定产品不变量均可追溯到活动 owner；
- Plan 36、37、80 仅修改顶部暂停/重基线 notice；
- `automated-go-check: unavailable` 陈述受事实支持。

Reviewer 提出三项闭环 finding：

1. `migration-parity.md` 仍把任务 9 写成尚未执行；
2. 本分片仍把 reviewer 与 GAP 写成待复核；
3. 历史 `2026-07-31-plan-35-core-contract-replacement.md` 的新增 supersession notice 使用英文。

协调会话已同步索引的实际 cutover 状态、记录本次 reviewer 结论，并把该历史 notice 改为中文。以上修正等待同一 reviewer 的 scoped re-review；其结论将在下方追加。

## Scoped re-review

同一 read-only reviewer 只复核上述三项修正，返回 `No findings and APPROVED`。Reviewer 未修改文件、未创建 worktree、未提交，也未写 migration evidence。

## 未裁决 GAP

无。
