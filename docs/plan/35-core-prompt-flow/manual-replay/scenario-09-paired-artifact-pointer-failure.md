# 场景 09：Paired artifact 与 pointer failure

## 初始 durable facts

- Lifecycle 准备把一个合法 `ready` proposal 物化为 paired semantic revision。
- Last proven gate、current pointer、Operation identity、Invocation/attempt 和 Policy binding 均已记录。
- Variant A 只写出 `record.md`，缺少匹配的 `content.md`。
- Variant B 写出两个 component，但重读观察为 `record.md.content_digest = digest-a`、对应 `content.md` 的 observed digest binding 为 `digest-b`，且 `digest-a != digest-b`；这是人工 replay 的显式不一致输入，不声称 digest service 已计算这些值。
- Variant C 完整形成 identity、digest、scope/source/artifact bindings 一致的 pair，但 separate current pointer update 失败。

## 选择的 Capability / Profile / scope

以 `themis-review-projection` / `semantic-readonly` / `lifecycle` 为代表；同一规则适用于十一类 paired artifact family。

## proposed status

`ready`，且 proposed result 本身的 Capability/Profile/path/status 与 Invocation 匹配。

## 适用的自然语言控制规则及其标题

- [物化与当前性 · 成对语义工件](../../../../templates/.themis/core/policies/references/materialization-and-currentness.md#成对语义工件)：`record.md + content.md` 不可分割。
- [物化与当前性 · Incomplete 与 pointer failure](../../../../templates/.themis/core/policies/references/materialization-and-currentness.md#incomplete-与-pointer-failure)：partial pair 不形成 revision；pointer failure 不建立 currentness。
- [Invocation 与物化控制 · 完整物化顺序](../../../../templates/.themis/core/kernel/orchestrator/references/invocation-and-materialization.md#完整物化顺序)：pointer 更新和重读位于 pair 重读之后。

## control action

- Variant A：记录 incomplete operation；由于缺少 `content.md`，拒绝 whole revision，保留 last proven gate，不更新 pointer。
- Variant B：重读两个 component 后观察到 `record.md.content_digest` 与该 revision 的 `content.md` observed digest binding 不一致；将 whole pair 判为 invalid，记录 materialization failure，保留 last proven gate，不更新 pointer。不得因为两个文件都存在而降级为 valid revision。
- Variant C：保留已完整物化并重读的 immutable revision，但记录 pointer update failure；该 revision 不是 current。
- 恢复时重读 pair、operation、pointer 与 current bindings，再决定是否按明确 Policy action 重试；不得重写 immutable pair，或从目录/文件存在推断成功。

## materialized record/revision

- Variant A：只有单一 `record.md` component 与 incomplete operation/evidence，没有 valid paired revision。
- Variant B：存在两个 component 和 digest mismatch observation，但 digest binding 不一致使整个 logical revision invalid；没有 valid/non-current paired revision 可供 pointer 指向。
- Variant C：valid non-current paired revision、pointer failure observation 与原 current pointer。

## current pointer/gate

三个 variant 都保持原 current pointer 和 last proven gate。Variant C 的候选 revision 只有在 separate pointer 成功更新并重读后才可能 current；Variant A/B 必须先按明确的新 operation 形成完整且 bindings 一致的新 immutable pair，不能只补写、修补或指向失败 revision。

## invalidation

- Variant A 的缺失 half 与 Variant B 的 digest mismatch 都使 whole revision invalid；Variant C 只形成 valid non-current revision。
- 依赖新 revision 的 downstream 不得建立；原 current authority 是否保留只由现有 bindings 与具体 Policy invalidation 决定，不能由失败写入自行推断。

## failure class

Half-write recorder/materialization failure、digest mismatch materialization failure 与 pointer update failure 均属于 Invocation/result 后 `counted` failure，并进入当前 lifecycle Execution Identity 的 failure control。

## 缺失 machine guarantees

Atomic writer、digest、pair validator、recorder、pointer update、reread/currentness evaluator 和 recovery runtime 均为 `unavailable`。

## replay result

**PASS（人工合同重放）**：Variant A 的单 half 不形成 revision；Variant B 明确观察 `record.md.content_digest != content.md observed digest`，因此两个 component 一起作为 whole revision invalid；Variant C 的完整 pair 加失败 pointer 只形成 non-current revision。三者都不能推进 gate 或由文件存在推断 current，且该人工观察不声称 unavailable digest/runtime 已执行。
