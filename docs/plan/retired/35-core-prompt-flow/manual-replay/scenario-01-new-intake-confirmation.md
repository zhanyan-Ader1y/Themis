# 场景 01：新 Intake、确认与 lifecycle 创建

## 初始 durable facts

- 收到一条尚未绑定任何 active Intake-local continuation 的外部消息。
- 尚无 Intake identity、Source Event、confirmed assignment decision 或 provisional lifecycle。
- `request-intake` 与任何既有 `lifecycle` scope 没有共享动态状态。

## 选择的 Capability / Profile / scope

1. Global Rule 先记录 immutable Source Event，并按 attachment 规则创建新的 Intake identity。
2. 第一次 Invocation：`themis-current-request-dialogue` / `human-dialogue` / `request-intake` / `null/null`。
3. 用户通过新的 confirmation Source Event 明确处置完整 diff 后，第二次 Invocation 使用相同 Capability/Profile/scope 和同一 Intake Execution Identity，但使用新的 Invocation/attempt identity。

## proposed status

- 第一次：`needs-request-confirmation`。
- 第二次：`assignment-confirmed`，target operation 为 `create-lifecycle`。

## 适用的自然语言控制规则及其标题

- [Intake 入口控制 · Source Event 与 attachment](../../../../templates/.themis/core/kernel/orchestrator/references/intake-entry.md#source-event-与-attachment)：无匹配 active continuation 时创建新 Intake。
- [Intake 路由 · `needs-request-confirmation`](../../../../templates/.themis/core/policies/references/routes/intake.md#needs-request-confirmation)：持久化 source-bound proposal 并等待 confirmation。
- [Intake 路由 · `assignment-confirmed`](../../../../templates/.themis/core/policies/references/routes/intake.md#assignment-confirmed)：验证 decision、逐 target operation 和 decision-bound continuation 后物化 assignment。

## control action

- 保留原消息 exact bytes 与 fragment references，物化 Intake Proposal 和 confirmation continuation。
- Confirmation 只确认 governance diff，不替代原 lifecycle-bearing Source Event。
- Decision 完整物化并重读后，才执行 `create-lifecycle`，建立 Current Request revision，并沿 decision-bound continuation 进入 `themis-q`。

## materialized record/revision

- 两个 immutable Source Event records：原消息与 confirmation 消息。
- Intake Proposal structured record。
- Intake Decision structured record及 target materialization observation。
- Current Request `record.md + content.md` pair。
- Separate Current Request pointer observation。

## current pointer/gate

- Intake 在全部 target 完成前保持 `open`；完成后 disposition 为 `assigned`、retention 为 `active`。
- Lifecycle 只有在 Current Request pair 完整重读并由 separate pointer 指向后，才能进入 Questioning gate。

## invalidation

- 新 proposal 使同一 Intake 中依赖旧 proposal 的 pending decision binding stale。
- 不创建 provisional lifecycle，也不改写其他 Intake/lifecycle authority。

## failure class

- 等待 confirmation：`non-counted`。
- 合法 assignment 成功：`none`。
- Confirmation/binding/target operation 无效时：counted invalid-result，停在 last proven gate。

## 缺失 machine guarantees

Strict Schema、canonical digest、Policy evaluator、state recorder、Invocation host、deterministic writer、pointer currentness 和 lifecycle creation runtime 均为 `unavailable`；本场景不声称机器执行。

## replay result

**PASS（人工合同重放）**：当前 Markdown Rule、Policy 与 templates 能唯一表达 Intake-first、changed-only confirmation、无 provisional lifecycle 和 decision-bound lifecycle creation；没有使用旧 YAML route 或自由文本猜测控制动作。
