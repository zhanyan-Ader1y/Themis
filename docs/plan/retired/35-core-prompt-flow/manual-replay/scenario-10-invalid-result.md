# 场景 10：Invalid result fail closed

## 初始 durable facts

- Invocation 已开始并唯一绑定 Capability、scope、Execution Identity、Profile、path/profile、Policy、attempt、continuation 和 materialization target。
- Variant 分别返回 duplicate terminal result、late result、wrong Profile、wrong scope、unknown status、stale binding、zero rule match 或 multiple rule matches。

## 选择的 Capability / Profile / scope

以 `themis-review-check` / `independent-checker` / `lifecycle` 为代表；invalid-result 规则适用于所有 Capability 和两个 authority scope。

## proposed status

Variant 可声称 `pass`，也可使用未知或错误 path-domain status；关键事实是 result identity/binding 或唯一规则匹配不合法。

## 适用的自然语言控制规则及其标题

- [失败控制 · 无效结果](../../../../templates/.themis/core/policies/references/failure-control.md#无效结果)：Invocation/result 后的非法结果一律 counted fail closed。
- [失败控制 · Result uniqueness 与第四次 Invocation 禁令](../../../../templates/.themis/core/policies/references/failure-control.md#result-uniqueness-与第四次-invocation-禁令)：一次 Invocation 只接受一个终态。
- [Invocation 与物化控制 · Proposed result 验证](../../../../templates/.themis/core/kernel/orchestrator/references/invocation-and-materialization.md#proposed-result-验证)：不得从 `recommended_route` 或近似 prose 补全。

## control action

拒绝 proposed result，不执行其 materialization target，不更新 current pointer；记录 attempt 与 observed invalid-result，触发 scope-bound Failure Learning request，并保留或终止 exact main continuation取决于累计失败次数。

## materialized record/revision

只记录 attempt、invalid-result evidence、failure observation，以及非阻塞 Failure Learning request/result；不形成被拒绝的 checker/artifact authority。

## current pointer/gate

保持 last proven gate 与原 current pointers。Duplicate/late result 不能覆盖已接受终态，wrong-scope result 不能跨 authority scope 改变 state。

## invalidation

被拒绝结果不创建新的 semantic invalidation；failure control 可在第三次失败时失活对应 Execution Identity 的 continuation和 unfinished downstream。

## failure class

所有列出的 Invocation/result 后 invalid result 均为 `counted`。对照 variant：若 required Policy package/reference 在 Invocation 前已观察为 unavailable/ambiguous，则不创建 attempt且不计数。

## 缺失 machine guarantees

Result validator、unique-terminal enforcement、Policy matcher、failure recorder、budget counter 和 rejection runtime 均为 `unavailable`。

## replay result

**PASS（人工合同重放）**：duplicate、late、wrong-profile、wrong-scope、unknown/stale 和 zero/multiple match 均被拒绝并停在 last proven gate；无任何自由文本 fallback。
