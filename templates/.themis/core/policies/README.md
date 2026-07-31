# Policies Package

## Responsibility

`transitions.yaml` 是 Themis 唯一 route/control policy，声明 `request-intake` 与 `lifecycle` 两个隔离 authority scope、十六个固定 Capability/Profile 绑定、legal statuses、control actions、materialization/currentness、失效、恢复和失败预算。

Global Rule 只通用解释这份 policy；Capability 只产生 proposed semantic result；Workspace 保存 observed state、records、evidence 和 current pointers。任何一方都不得复制或覆盖另一方的 authority。

## Sole owned policy

- `transitions.yaml`：唯一 policy；route key 固定为 `capability + selected_path + profile + status`。
- Authority scope 不是第五个 route 维度，因为每个 Capability 的 legal scope 在 policy 和 Capability contract 中唯一绑定。
- 当前 route 数量只是该文件的可观察属性，不是产品身份或永久合同。

## Authority scopes

- `request-intake`：Source Event、claim/assignment proposal、用户确认 decision、Intake Execution Identity、scope-local continuation、pointer、disposition 和 post-completion retention facts。
- `lifecycle`：Current Request、Questioning、path/Plan、Review/Approval、Plan Task Execution、Verification、Acceptance、Summary 和 scope-local continuation/pointers。
- 两个 scope 只能用稳定不可变引用互相指向；不得共享动态 state、Execution Identity、failure budget、continuation authority、current pointer 或 completion state。
- `dormant-read-only` 是 assigned Intake 的派生 retention mode，不是 disposition、Capability status 或 route key 维度。

## Control boundaries

- 所有外部消息先成为 immutable Source Event，并经 `themis-current-request-dialogue`；不能先创建或继续 lifecycle。
- Capability Invocation Result 永远只是 proposal。
- Authority 需要：校验结果与 bindings、精确匹配一条 route、执行 control action、完整持久化、记录 completion/incomplete observation、重读 identity/content/digest/bindings，再更新独立 pointer。
- 零条或多条 route match、unknown status、wrong-profile、wrong-scope、stale/duplicate/late result 或 recorder/materialization failure 均 fail closed。
- `recommended_route` 只供 diagnostics，不具控制权。
- `profile` 表示 Plan profile `lightweight | full | null`；执行权限由独立 `agent_profile` 定义。

## Lifecycle invariants

- `full_path_required` 在同一 lifecycle 内只允许 `false → true`；Questioning、reassessment、restart、resume 或 retry 都不能清除。
- Simple/full paths 在 Plan Check 后汇合，共用 Review、Approval、Verify、Acceptance 和 Summary。
- Review Approval 在 Impl 前；Verify 固定为 `themis-impl → independent themis-verification`。
- Current Verification 必须 `passed` 才能 Acceptance；current Acceptance 必须 `accepted` 才能 Summary。
- Summary pair 完整物化并观察 lifecycle completion 后，policy 冻结对应 Intake target；全部关联 lifecycle target 完成后，Intake 保持 `assigned` 并进入 `dormant-read-only`，失活 continuation，禁止 attachment、Invocation、mutation、reactivation 和 recovery。

## Failure and recovery

- Intake Execution Identity 和 lifecycle Plan Task Execution Identity 各自最多三次 counted failure；第三次终止对应 identity，禁止第四次 Invocation。
- Impl、Verification 和 acceptance 的 implementation-defect repair 共享一个 Plan Task budget。
- 每次 counted failure 和显式关联 later success 都触发 scope-bound、non-blocking、non-recursive Failure Learning。
- Recovery 只从 active durable state、pointers、markers、artifact components、Invocation/attempt records 和 applicable Git facts重建 `last-proven-gate`；不得从 chat、summary 或 temporary reasoning 恢复。
- Dormant Intake records 只用于历史来源/决定核验，不参与 recovery；后续外部消息创建新 Intake。

## Safe degradation

当前 YAML 是 Prompt-level control input，不是 strict machine contract。Plan 35 只能进行静态检查和人工 replay；没有对应后续能力时不得声称机器执行了 transition、persistence、currentness、digest、attempt、invalidation、termination 或 recovery。

- Plan 36：strict Schema、canonical serialization、validator、issue taxonomy、semantic oracle 和 fixtures。
- Plan 37：policy evaluator、Invocation host、recorder、deterministic writes 和 command execution。

本包不包含功能版本、upgrade、migration、Shell fallback、多 Agent orchestration、Attribution gate、通用锁、事务、rollback journal 或 automatic repair。
