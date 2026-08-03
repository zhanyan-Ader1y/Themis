# 场景 05：Questioning 回答改变 claim

## 初始 durable facts

- Lifecycle 正等待 `human-questioning` continuation。
- 用户答案先形成新的 Source Event；它改变一个已确认 claim，而非仅补充 no-change answer。
- 原 Questioning proposal 尚不是 completed round。

## 选择的 Capability / Profile / scope

1. `themis-current-request-dialogue` / `human-dialogue` / `request-intake` / `null/null`。
2. 用户确认 changed-only diff 后，恢复 `themis-q` / `human-dialogue` / `lifecycle` / `null/null`。

## proposed status

- Intake 第一次：`needs-request-confirmation`。
- Intake 第二次：`assignment-confirmed`，target operation 为 `update-current-request`。
- Questioning：根据新 Current Request 返回 `needs-questioning` 或 `converged`。

## 适用的自然语言控制规则及其标题

- [Intake 入口控制 · Current Request 确认](../../../../templates/.themis/core/kernel/orchestrator/references/intake-entry.md#current-request-确认)：只确认 changed diff，并保留原 lifecycle-bearing Source Event。
- [Intake 路由 · `assignment-confirmed`](../../../../templates/.themis/core/policies/references/routes/intake.md#assignment-confirmed)：更新 Current Request 后恢复 decision-bound continuation。
- [理解阶段路由 · `needs-questioning`](../../../../templates/.themis/core/policies/references/routes/understanding.md#needs-questioning) 与 [`converged`](../../../../templates/.themis/core/policies/references/routes/understanding.md#converged)：未回答 proposal 不形成 round；收敛后才物化 pair 并更新 pointer。

## control action

- 持久化 changed-only proposal，等待逐项 explicit disposition。
- 完整物化 Decision 和新 Current Request pair，更新 pointer 后再恢复 `themis-q`。
- 若仍需追问，只保存 Questioning proposal/continuation；若收敛，物化 immutable Questioning Round pair 并更新 Current Questioning Pointer。

## materialized record/revision

- Answer 与 confirmation Source Events。
- Intake Proposal/Decision。
- 新 Current Request `record.md + content.md` pair及 pointer。
- 可选的 completed Questioning Round pair及 separate pointer。

## current pointer/gate

- 新 Current Request pointer 成为 current 前不得恢复 Questioning。
- 未回答 question 停在 `human-questioning`；`converged` round 完整 current 后才进入 Complexity Assessment。

## invalidation

Current Request revision 改变使受影响的 Questioning、Complexity Assessment、Plan 和 unfinished downstream 失效。

## failure class

等待 confirmation/question answer 与合法 `needs-questioning`：`non-counted`；合法 materialization：`none`。

## 缺失 machine guarantees

Semantic diff、fragment validation、dependency invalidation、pair digest 和 pointer update 的机器保证均为 `unavailable`。

## replay result

**PASS（人工合同重放）**：新 Markdown contracts 保持 Intake-first、changed-only confirmation、per-round immutable Questioning 和 Current Request-before-resume 顺序。
