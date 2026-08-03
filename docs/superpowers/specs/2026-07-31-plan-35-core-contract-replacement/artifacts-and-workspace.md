# 工件与工作区

> 本文件属于 [Plan 35：Core Contract Replacement](../2026-07-31-plan-35-core-contract-replacement-design.md) 的功能 reference，拥有 immutable artifact、revision、attempt 分离和 Workspace scoping 合同。它不是第二份设计权威。paired semantic artifact 的稳定形状固定为同一 revision 下的 `record.md + content.md`，任一组件无效则整个 revision invalid。

## Paired semantic artifacts

以下对象由 `record.md` 与 `content.md` 共同组成不可分割的逻辑 revision：

- Current Request；
- completed Questioning round；
- Plan；
- Review Projection；
- Review Approval；
- Review feedback；
- Impl Result；
- Verification；
- Human Acceptance；
- Summary；
- governed knowledge candidate，包括 Failure Learning candidate。

`record.md` 以自然语言 Markdown 标题、字段表和闭合枚举保存：

- identity；
- revision；
- typed fields；
- source/current bindings；
- content path；
- content digest；
- disposition/currentness；
- materialization observation。

`content.md` 保存经治理的人类语义和人类可读内容。

任一组件缺失、content digest mismatch 或 binding mismatch 时，整个逻辑 revision invalid。`record.md` 不能把 `content.md` 降格为无权威 projection，`content.md` 也不能脱离 `record.md` 单独成为执行 authority。

Review Projection 与 Summary 虽然是 paired artifacts，但其语义权限仍受来源限制：

- Review Projection 是 checked Plan 的绑定投影，不拥有 Plan 或 execution semantics；
- Summary 是 Verification、Acceptance 与 actual delta 的绑定交付投影，不创建 completion 事实，不替换 Verification 或 Acceptance。

## Structured semantic records

以下对象默认只要求自然语言 Markdown structured record，不机械生成 `content.md`：

- Grounding；
- Complexity Assessment；
- Plan Check；
- Review Check；
- route-affecting checker results；
- confirmed Intake assignment decision。

这些记录仍必须声明 stable identity、required bindings、闭合状态、来源引用和 materialization observation。Markdown 表示不意味着可由当前 Go runtime 自动解析；Plan 35 只拥有 Prompt-level 合同。

## Operational and evidence records

以下对象不是 semantic artifact revision：

- lifecycle/Intake state；
- Task/Intake Execution Identity；
- Invocation；
- attempt；
- raw Capability result evidence；
- control action/recorder result；
- current pointer；
- completion/incomplete marker；
- command/stdout/stderr evidence；
- Git baseline/status/diff observation；
- last proven gate。

## Immutable revisions

所有 paired semantic artifacts 使用不可变 revision：

```text
<artifact-family>/<opaque-revision-id>/
  record.md
  content.md
```

只需 structured record 的对象仍使用独立不可变 revision，但不创建无语义的 `content.md`。

规则：

- 内容或结构变化创建新 revision；
- current pointer 单独保存；
- 不原地覆盖；
- 不使用 symlink 作为 authority；
- 旧 revision 保留 observed disposition，例如 `stale | superseded | failed | rejected | invalidated`；
- 不从 revision 编号、时间或缺号推断 attempt 或 failure count；
- pointer 更新失败时 revision 可以存在，但不成为 current。

## Questioning round

不再维护一个不断追加的大 `questioning.md`。一次已完成问答交换形成一个独立 immutable round revision：

```text
questioning/<round-revision>/
  record.md
  content.md
```

每轮至少绑定：

- previous round revision；
- question proposal/continuation；
- answer Source Event refs；
- post-answer Current Request revision；
- Why/abstract What result；
- materialization observation。

尚待回答的问题只存在于 durable dialogue continuation/proposal，不伪装成 completed round。

## Attempt 与 artifact 分离

- attempt 属于 Execution Identity；
- attempt 开始和失败必须记录；
- artifact revision 只在完整持久化和重读后产生；
- 一个 attempt 可以没有 artifact；
- 一个 attempt 可以引用合同允许的多个 artifacts；
- incomplete marker 属于 operation record，不属于 artifact revision。

## Workspace scoping

fresh Workspace 使用：

```text
workspace/
  intakes/<intake-id>/
    source-events/
    proposals/
    decisions/
    state/

  changes/<lifecycle-id>/
    current-request/
    questioning/
    plan/
    review/
    approval/
    feedback/

  state/<lifecycle-id>/
    lifecycle-state
    current-pointers/
    invalidations/
    markers/

  runs/<lifecycle-id>/
    task-executions/
    invocations/
    attempts/
    impl-results/
    verification-results/

  evidence/<lifecycle-id>/
    commands/
    git-observations/
    external-evidence/

  outcomes/<lifecycle-id>/
    acceptance/
    summary/

  knowledge/
    intakes/<intake-id>/
    lifecycles/<lifecycle-id>/
```

路径只表达归属，不因目录或文件存在而证明 authority。所有 currentness 仍依赖 identity、bindings、完整物化和 observed reread。

`workspace/intakes/<intake-id>/state/` 保存 Intake 控制事实和 post-completion retention facts。休眠记录必须引用 immutable assignment decision、对应 target identity 和 observed lifecycle completion records；它不能写回或替换 assignment decision。

Workspace 只保存 Policy 已观察并记录的 lifecycle completion、target freeze 与 Intake retention facts，不重新定义何时允许这些 transition。完整 gate、逐 target 后置控制和 `dormant-read-only` 禁止行为由 [Request Intake：Lifecycle completion 与 retention](request-intake.md#lifecycle-completion-与-retention) 唯一定义。

Intake 与 lifecycle 可以引用同一个 Source Event，但不能共享动态 state、Execution Identity、attempt budget 或 continuation authority。

Lifecycle state 是最小引用状态，只保存：

- current gate；
- current artifact revision refs；
- policy identity/digest；
- sticky flag；
- Task Execution identities；
- attempt refs；
- currentness；
- markers；
- invalidation；
- incomplete operation；
- last proven gate。

Lifecycle state 不复制 Current Request claims、scope、Plan、design、acceptance semantics 或 artifact prose。
