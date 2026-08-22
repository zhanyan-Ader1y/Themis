# Themis 活动实施计划

`docs/plan/**` 只保存尚待实施或验收的活动计划。本目录不建立第二套产品规范。

**当前主线是根目录 `.themis/spec/` 重新设计**，不是编号 Plan 队列。其已批准行为契约位于 `docs/superpowers/specs/2026-08-07-themis-spec-flow-mvp.md`；落地①–④已于 2026-08-18 产出 `.themis/spec/` 控制面四份文件（`README.md`/`flow.md`/`rules.md`/`template.md`），落地⑤（端到端 replay）未开始。

**编号 Plan 35/36/37 属于 `templates/.themis/` 旧 core**，与主线不共用一套合同。Plan 35 的 2026-07-31 replacement 产品语义位于 `docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement-design.md`；Markdown authority cutover、新静态证据、十六场景人工 replay 与 criteria 1–31 重映射已完成，criterion 32 仍等待用户明确重新接受。`templates/.themis/core/` 的退场正是落地⑤ replay 所承载的需求，故这三个 Plan 在 replay 结论产生前不推进。模块详细合同与模板状态位于 `templates/.themis/**/README.md`。

## 授权规则

- 每个计划必须单独批准后才能实施。
- 一个计划的批准不自动批准依赖或后续计划。
- 实施发现 current authority 需要变化时，先更新设计并重新批准。
- 未观察真实验证输出前不得宣称完成。
- Plan 35 于 2026-07-31 完成当时 YAML 表示下的实现、核验和明确重新接受；该事实作为历史基线保留。当前 Markdown-first 表示迁移已完成新静态核验、人工 replay 与 criteria 1–31 重映射，但 criterion 32 仍等待用户明确重新接受，因此不得据此启动 Plan 36/37。

## 活动队列

| 顺序 | 计划 | 依赖 | 定位 | 状态 |
|---|---|---|---|---|
| 当前 | [spec 流程端到端 replay（落地⑤）](../superpowers/plans/2026-08-19-spec-flow-end-to-end-replay.md) | `.themis/spec/` 控制面四份文件已落地 | 以「删除 `templates/.themis/core/`」为载体走完 flow.md 十三个节点，产出漂移清单作为未来 hard 执行器强制清单 | 计划已展开，**等待单独批准**；未开始执行 |
| 35 | [Core Contract Replacement](35-core-prompt-flow/impl.md) | 无 | Intake-first 双作用域控制、十六个 Capability、不可变工件与 Prompt-level replay | Cutover、静态证据、replay 与 criteria 1–31 已完成；criterion 32 等待用户重新接受 |
| 36 | [Deterministic Assurance](36-deterministic-assurance/impl.md) | Markdown-first replacement Plan 35 已重新接受 | strict contracts、validator、canonicalization 与 fixtures；无副作用 | 暂停，待 Plan 35 criterion 32 通过后完整重基线和单独批准 |
| 37 | [Native Runtime](37-native-runtime/impl.md) | 重基线后的 Plan 36 已实施并接受 | policy evaluator、temporary invocation、recorder 与 minimal write safety | 暂停，待 Plan 36 |
| 80 | [Multi-Agent Execution](80-multi-agent-execution/impl.md) | 可选；启动时重基线 | optional worker topology | 待单独确认，非阻塞 |
| 90 | [Attribution Analytics](90-attribution-analytics/impl.md) | 可选；启动时重基线 | post-delivery attribution/outcome analysis | 待单独确认，非阻塞 |

## 依赖

```text
replacement Plan 35 historical product semantics retained
→ Markdown-first representation cutover, evidence rebuild, and explicit re-acceptance
→ full Plan 36 rebaseline and separate approval
→ Plan 36 implementation and acceptance
→ Plan 37 rebaseline and separate approval

Plan 80 Multi-Agent Execution   optional / launch-time rebaseline
Plan 90 Attribution Analytics   optional / post-delivery / launch-time rebaseline
```

## Plan 35 主流程

```text
external message
→ immutable Source Event under Request Intake
→ Current Request Dialogue
   ├─ semantic/assignment change → changed-only confirmation → second Invocation
   ├─ no change → resume durable continuation
   └─ rejection → persist rejection
→ policy-controlled assignment materialization
→ create or update lifecycle Current Request revision
→ Questioning and optional Grounding
→ Complexity Assessment
   ├─ simple → Simple Plan → Lightweight Plan Check
   └─ full   → temporary Specification → Planning → Full Plan Check
→ Review Projection → Review Check → Review Dialogue → Review Approval
→ Verify [Impl → independent Verification]
→ Human Acceptance → Summary
→ optional governed knowledge candidates
```

- 每条外部消息先进入 `request-intake` authority scope；assignment 前不创建 provisional lifecycle。
- Current Request 由 user-confirmed、source-bound claims 构成。
- `request-intake` 与 `lifecycle` 的 Execution identity、budget、continuation、pointer 和动态状态隔离。
- 两条 lifecycle 路径生成同一个 Plan，并共享 Review、Approval、Verify、Acceptance 与 Summary。
- Review 位于 Impl 前；Verification 在 Impl 后独立执行。
- Summary 需要 current Verification `passed` 和 Human Acceptance `accepted`。
- Specification 是 full-path temporary handoff，不持久化为 authority。
- 当前代码、配置、Schema 和 observed executable behavior 是当前实现事实的唯一来源。

## 当前控制模型

```text
one public themis Skill
→ one Global Control Rule with on-demand references
→ one Markdown Policy package across request-intake and lifecycle scopes
→ one internal Capability + fixed Agent Profile
→ one temporary Invocation
→ proposed Capability Invocation Result
→ exactly one applicable natural-language control rule
→ complete materialization + observed reread
→ immutable revision and separate current pointer
```

- Capability 拥有一个语义判断；Profile 拥有权限与隔离合同。
- Global Rule 只解释 Policy、协调 bindings、materialization、invalidation、failure control 和 recorded-state recovery。
- 文件存在、Markdown、Agent summary 或 proposed result 不构成 authority。
- Workspace 按 Intake 或 lifecycle identity 保存实际记录。

## 计划边界

### Plan 36

等待 replacement Plan 35 的当前 Markdown-first 证据获得用户明确重新接受后，再基于该 authority 完整重基线并单独审阅 Plan 36。Plan 36 只定义 strict Schema、canonicalization、validation issue、semantic oracle 和 accepted/rejected fixtures，不执行 transition、调用 Agent、写状态、运行项目命令或修改实现。

### Plan 37

等待重基线后的 Plan 36。未来只实现 policy evaluation、one-Capability temporary invocation、scope-bound recorder 和 minimal fail-closed write safety，不拥有 Capability 语义。

### Plans 80/90

Plan 80 和 Plan 90 保持可选，只在各自正式启动时依据届时 current contracts 一次性重基线，不能成为 Verification、Acceptance、Summary 或 core completion 门禁。

## 通用限制

- 不引入功能版本、版本目录、compatibility、upgrade 或 migration。
- 不创建持久 Specification、第二种 Plan、独立 Delivery 或 Shell fallback。
- 不覆盖已有 `.themis`。
- 缺失 evaluator、validator、recorder、runtime、Agent host、worktree 或 command support 时 fail closed。
- 不得用 Prompt、README、template、policy 或 directory 的存在冒充 machine enforcement。
