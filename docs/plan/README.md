# Themis 活动实施计划

`docs/plan/**` 只保存尚待实施或验收的活动计划。跨模块权威设计位于 `docs/superpowers/specs/**`，模块详细合同与当前模板状态位于 `templates/.themis/**/README.md`；本目录不建立第二套产品规范。

## 授权规则

- 每个计划必须单独批准后才能实施。
- 一个计划的批准不自动批准其依赖或后续计划。
- 实施发现权威设计需要变化时，先更新对应设计并重新批准。
- 未观察到真实验证输出前，不得宣称计划完成。

## 活动队列

| 顺序 | 计划 | 依赖 | 定位 | 状态 |
|---|---|---|---|---|
| 35 | [Core Prompt Flow](35-core-prompt-flow/impl.md) | 无 | 一个公共 Skill、内部 Capability/Profile、唯一 route policy 与 Prompt-level 双路径生命周期 | 已批准实施，最终核验中 |
| 36 | [Deterministic Assurance](36-deterministic-assurance/impl.md) | 用户已接受 Plan 35 | 严格 Schema、validator、canonical rules 与 accepted/rejected fixtures；无副作用 | 待单独确认 |
| 37 | [Native Runtime](37-native-runtime/impl.md) | 用户已接受 Plan 36 | policy evaluator、temporary invocation、per-lifecycle recorder 与最小写入安全 | 待单独确认 |
| 80 | [Multi-Agent Execution](80-multi-agent-execution/impl.md) | 可选；核心生命周期不依赖 | worktree-isolated optional worker topology | 待单独确认，非阻塞 |
| 90 | [Attribution Analytics](90-attribution-analytics/impl.md) | 可选；交付后使用 | Attribution 与 Outcome 分析 | 待单独确认，非阻塞 |

## 依赖

```text
Plan 35 Prompt-level lifecycle
  └── Plan 36 strict contracts and fixtures
        └── Plan 37 minimal native runtime

Plan 80 Multi-Agent Execution   optional / non-blocking
Plan 90 Attribution Analytics   optional / post-delivery / non-blocking
```

## Plan 35 生命周期

```text
Current Request
→ Questioning
→ Complexity Assessment
   ├─ simple → Simple Plan → Lightweight Plan Check
   └─ full   → temporary Specification → Planning → Full Plan Check
→ Review Projection → Review Check → Human Review → Review Approval
→ Verify [Impl → independent Verification]
→ Human Acceptance → Summary
→ optional governed knowledge candidates
```

- 两条路径生成同一个 Plan，并共享 Review、Approval、Verify、Acceptance 与 Summary。
- Review 位于 Impl 前；Verification 在 Impl 后独立执行。
- Summary 需要 current Verification `passed` 和 Human Acceptance `accepted`。
- Specification 是 full-path 临时 handoff，不持久化。
- 当前代码、配置、Schema 和 observed executable behavior 是当前实现事实的唯一来源。

## 统一控制模型

```text
public themis Skill
→ Global Control Rule
→ transitions.yaml
→ one internal Capability + fixed Agent Profile
→ one temporary Agent invocation
→ Capability Invocation Result
→ exactly one legal route
```

- `transitions.yaml` 是 route 的唯一声明源。
- Capability 拥有语义判断；Profile 只拥有权限与隔离合同。
- Global Rule 只协调 identity、bindings、generic actions、invalidation、recorded-state resume 与 failure budget。
- Workspace 按 lifecycle identity 保存实际记录。

## 计划边界

### Plan 36

只定义和测试严格合同：schemas、canonicalization、validation issues、currentness、Capability/Profile/Invocation/policy/artifact/lifecycle/write-safety shapes 与 fixtures。不得执行 transition、调用 Agent、写状态、运行命令或修改文件。

### Plan 37

只实现：

1. policy evaluator；
2. one-Capability temporary invocation；
3. per-lifecycle state recorder；
4. worktree-bound minimal fail-closed write safety。

Plan 37 不实现跨 worktree locks、通用 transactions、rollback journals、automatic recovery、cross-worktree merge 或 conflict adjudication。

### Plans 80/90

Plan 80 和 Plan 90 都是可选能力，不能成为 Verification、Acceptance、Summary 或 lifecycle completion 的门禁。

## 通用限制

- 不引入功能版本、版本目录、upgrade 或 migration。
- 不创建持久 Specification、第二种 Plan、独立 Delivery 或 Shell fallback。
- 不覆盖已存在 `.themis`。
- 缺失 evaluator、validator、recorder、runtime、Agent host、worktree 或 command support 时必须 fail closed。
- 不得用 Prompt、README、template 或 directory 的存在冒充 machine enforcement。
