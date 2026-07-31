# Themis 活动实施计划

`docs/plan/**` 只保存尚待实施或验收的活动计划。当前跨模块权威设计位于 `docs/superpowers/specs/2026-07-31-plan-35-core-contract-replacement-design.md`；模块详细合同与模板状态位于 `templates/.themis/**/README.md`。本目录不建立第二套产品规范。

## 授权规则

- 每个计划必须单独批准后才能实施。
- 一个计划的批准不自动批准依赖或后续计划。
- 实施发现 current authority 需要变化时，先更新设计并重新批准。
- 未观察真实验证输出前不得宣称完成。
- Plan 35 已于 2026-07-31 完成实现、静态核验、人工 replay 和用户明确重新接受，现为 current authority。

## 活动队列

| 顺序 | 计划 | 依赖 | 定位 | 状态 |
|---|---|---|---|---|
| 35 | [Core Contract Replacement](35-core-prompt-flow/impl.md) | 无 | Intake-first 双作用域控制、十六个 Capability、不可变工件与 Prompt-level replay | 已实施、核验并重新接受；current authority |
| 36 | [Deterministic Assurance](36-deterministic-assurance/impl.md) | replacement Plan 35 已重新接受 | strict contracts、validator、canonicalization 与 fixtures；无副作用 | 暂停，待完整重基线和单独批准 |
| 37 | [Native Runtime](37-native-runtime/impl.md) | 重基线后的 Plan 36 已实施并接受 | policy evaluator、temporary invocation、recorder 与 minimal write safety | 暂停，待 Plan 36 |
| 80 | [Multi-Agent Execution](80-multi-agent-execution/impl.md) | 可选；启动时重基线 | optional worker topology | 待单独确认，非阻塞 |
| 90 | [Attribution Analytics](90-attribution-analytics/impl.md) | 可选；启动时重基线 | post-delivery attribution/outcome analysis | 待单独确认，非阻塞 |

## 依赖

```text
replacement Plan 35 implementation, evidence, and explicit re-acceptance complete
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

## 统一控制模型

```text
one public themis Skill
→ one Global Control Rule
→ one transitions.yaml across request-intake and lifecycle scopes
→ one internal Capability + fixed Agent Profile
→ one temporary Invocation
→ proposed Capability Invocation Result
→ exactly one legal route
→ complete materialization + observed reread
→ immutable revision and separate current pointer
```

- Capability 拥有一个语义判断；Profile 拥有权限与隔离合同。
- Global Rule 只解释 policy、协调 bindings、materialization、invalidation、failure control 和 recorded-state recovery。
- 文件存在、Markdown、Agent summary 或 proposed result 不构成 authority。
- Workspace 按 Intake 或 lifecycle identity 保存实际记录。

## 计划边界

### Plan 36

基于已重新接受的 replacement Plan 35 完整重基线，再定义 strict Schema、canonicalization、validation issue、semantic oracle 和 accepted/rejected fixtures。Plan 36 不执行 transition、调用 Agent、写状态、运行项目命令或修改实现。

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
