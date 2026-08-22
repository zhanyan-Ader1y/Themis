# 场景 13：Failure Learning 非阻塞且不递归

## 初始 durable facts

- 一个 scope-local Execution Identity 已观察到 counted failure，并保存 failed attempt/evidence 与 exact main continuation。
- Variant A 可形成可复用候选；Variant B 的 Learning 自身被阻塞；Variant C 在同一 identity 后续成功。

## 选择的 Capability / Profile / scope

`themis-failure-learning` / `semantic-readonly`，authority scope 与触发失败相同：Intake 使用 `request-intake` 的 `null/null`，lifecycle 使用当前 `simple/lightweight` 或 `full/full`。

## proposed status

- Variant A：`candidate-ready` 或 `not-reusable`。
- Variant B：`blocked`。
- Variant C：后续成功再次创建显式关联的 Learning request；结果可为任一合法 Learning status。

## 适用的自然语言控制规则及其标题

- [失败控制 · Failure Learning](../../../../templates/.themis/core/policies/references/failure-control.md#failure-learning)：每次 counted failure及明确关联成功都请求 Learning。
- [Learning 阶段路由](../../../../templates/.themis/core/policies/references/routes/learning.md)：三个 path/profile domain 都恢复 exact scope-local main route。
- [Failure、失效与恢复控制 · Scope-local 失败预算](../../../../templates/.themis/core/kernel/orchestrator/references/failure-invalidation-recovery.md#scope-local-失败预算)：Learning 不改变 route、budget或 delivery result。

## control action

- Variant A 物化 `failure-learning-pair` candidate/disposition后恢复 exact main continuation。
- Variant B 记录 Learning unavailable并立即恢复 main continuation，不再次调用 Learning。
- Variant C 只用明确 execution linkage关联 success evidence；prose similarity不建立关系。

## materialized record/revision

Scope-bound Failure Learning pair、proposal或 unavailable observation，均绑定 execution identity、attempt/success evidence与 main continuation；不会自动发布到知识 authority。

## current pointer/gate

主流程 gate在 Learning期间保持冻结，Learning完成或 unavailable 后恢复原 continuation。Learning不能改变 Verification、Acceptance、assignment、completion或 failure count。

## invalidation

无主流程 authority invalidation。跨 scope证据只能作为 immutable reference，不能修改另一 scope的动态 state。

## failure class

`candidate-ready`/`not-reusable` 为 `none`；`needs-more-evidence`/`blocked` 为 `non-counted`。Learning自身失败不计入递归 Learning循环。

## 缺失 machine guarantees

Learning scheduler、execution linkage validator、candidate recorder、knowledge governance和 continuation resume runtime 均为 `unavailable`。

## replay result

**PASS（人工合同重放）**：Learning 始终 scope-bound、candidate-only、non-blocking、non-recursive；blocked 不阻塞主流程，后续成功只有显式 linkage 才触发关联分析。
