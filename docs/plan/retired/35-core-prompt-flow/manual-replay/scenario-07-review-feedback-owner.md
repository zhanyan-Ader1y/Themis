# 场景 07：Review Feedback owner 与 durable resolution

## 初始 durable facts

- Lifecycle 已有 current checked Plan `plan-revision-p1`、绑定该 Plan 的 current Review Projection、`pass` Review Check，以及绑定 `plan-revision-p1` 的 prior current Review Approval `approval-revision-a1`；用户反馈已先经 Intake 形成 immutable Source Event。
- Review Dialogue continuation、selected path/profile、Policy binding 和 unresolved feedback set 均 current。
- 七个合法 owner 为 `current-request-dialogue`、`questioning`、`specification`、`simple-planning`、`planning`、`plan-check`、`review-projection`。
- 本场景以 full-path `planning` owner 作为“产生新 Plan、旧 Approval stale”的代表性 replay；其余六个 owner 复核各自不同的 invalidation 边界。

## 选择的 Capability / Profile / scope

- 分类使用 `themis-review-dialogue` / `human-dialogue` / `lifecycle`。
- Owner re-entry 分别使用既有 owner Capability/Profile；`current-request-dialogue` 保持 `request-intake` scope，其余保持 `lifecycle` scope，两个 scope 只交换 Feedback revision 与 continuation 的 immutable references。
- 需要事实时临时使用 `themis-grounding` / `semantic-readonly` / `lifecycle`，但保存原 owner continuation。

## proposed status

- 七个 owner-specific status 必须唯一对应：`needs-current-request`、`needs-questioning`、`needs-specification`、`needs-simple-planning`、`needs-planning`、`needs-plan-check`、`needs-review-projection`。
- `needs-grounding` 不改变已分类 owner；owner 成功终态分别为 `assignment-confirmed`、`converged`、`ready`、`ready`、`ready`、`pass`、`ready`。

## 适用的自然语言控制规则及其标题

- [Review 阶段路由 · Review Dialogue](../../../../templates/.themis/core/policies/references/routes/review.md#themis-review-dialogue--fullfull--human-dialogue)：代表分支使用 full/full；七个 owner 跨 simple/full 合法域分别要求 status 与 `affected_owner` 唯一一致，并先物化 Feedback。
- [物化与当前性 · Review Feedback resolution observation](../../../../templates/.themis/core/policies/references/materialization-and-currentness.md#review-feedback-resolution-observation)：owner result、resolution observation 与 set update 按序完成。
- [Review Feedback 模板 · Resolution observation](../../../../templates/.themis/core/templates/review-feedback/record.md#resolution-observation)：Feedback pair immutable，closure 由 lifecycle state observations 证明。

## control action

1. 先物化并重读 Review Feedback `record.md + content.md`，保存 exact owner continuation；代表分支的 status 为 `needs-planning`、`affected_owner` 为 `planning`，二者唯一一致。该 Feedback 路由的 invalidation 立即使 prior `approval-revision-a1` 与 unfinished downstream stale。
2. `themis-planning` Invocation/result 原样绑定 `review_feedback_revision` 与 `review_feedback_owner_continuation_reference`。
3. `themis-planning/ready` 成功结果完整物化并重读为新 unified Plan `plan-revision-p2`；`plan-revision-p2` 成为 current Plan 后，绑定旧 `plan-revision-p1` 的 Plan Check、Review Projection 和 Review Check 失效，已 stale 的 `approval-revision-a1` 又因 Plan binding 指向旧 revision 而不能复活。等待、blocked、needs-*、grounding 或 escalation 不产生新 Plan，也不关闭 Feedback。
4. 控制层先记录并重读引用 `plan-revision-p2` 的 resolution observation，再记录并重读引用它的 unresolved-set update observation。
5. 只有第二个 observation 完成后，新 state view 才排除 exact Feedback revision；随后必须针对 `plan-revision-p2` 重新完成 Plan Check、Review Projection、Review Check 与新的 Review decision，不能复活 `approval-revision-a1`。
6. 其余 owner 使用同一 exact binding 与两步 closure：`current-request-dialogue`、`questioning`、`specification`、`simple-planning` 可能经各自语义链形成替代 Plan；`plan-check` 与 `review-projection` owner 保持 Current Plan，不伪造新 Plan revision。

## materialized record/revision

- Immutable Review Feedback pair，绑定代表分支的 `planning` owner 与 exact continuation。
- 原 current `plan-revision-p1` 和 prior `approval-revision-a1` 保持 immutable；成功 owner re-entry 另行物化并重读新 unified Plan pair `plan-revision-p2`，不原地改写旧 Plan。
- 其他 owner 的适用 Current Request decision、Questioning pair、Specification result evidence、Plan pair、Plan Check record 或 Review Projection pair；`plan-check` / `review-projection` 分支不创建虚假的新 Plan。
- Lifecycle-local resolution observation 与后续 unresolved-set update observation；不新增 Capability、status 或 semantic artifact family。

## current pointer/gate

- 两步 observation 完成前，Feedback 始终 unresolved，Review Approval gate 关闭。
- 代表分支中，Feedback 路由命中后 `approval-revision-a1` 已因 invalidation stale；Current Plan pointer 随后从 `plan-revision-p1` 更新并重读为 `plan-revision-p2`，使该 Approval 的 Plan/Check/Projection bindings 继续指向旧 revision，因此旧 Approval 文件存在也不能恢复 current。
- `plan-check` owner 保留 Current Plan；`review-projection` owner 保留 Current Plan 和 current passed Plan Check，但两者都使 prior Approval stale，并要求重建其下游 Review 链。
- Closure 后仍须按 invalidation 重建 Review 链；只有绑定 `plan-revision-p2` 及其新 checks/projection、空 unresolved set 和新用户决定的 Approval 才可能 current。

## invalidation

- Current Request、Questioning、Specification 或 Planning owner 按其语义失效相应上游及 Review/downstream；代表 `planning` 分支在 Feedback 路由时先使 `approval-revision-a1` stale，新 `plan-revision-p2` 再明确使旧 Plan Check、Review Projection 与 Review Check 失效，并阻止旧 Approval 复活。
- `plan-check` 只失效 Plan Check、Projection、Review Check、Approval 和 unfinished downstream，不创建新 Plan。
- `review-projection` 只失效 Projection、Review Check、Approval 和 unfinished downstream，不创建新 Plan。

## failure class

合法 feedback return、grounding 与 owner reroute 为 `non-counted`；合法 owner 成功为 `none`。Owner/status 不一致、缺失 exact Feedback binding、提前移除 unresolved entry 或 materialization failure 属于 Invocation 后 counted invalid-result。

## 缺失 machine guarantees

Owner classification、recorder、digest、Policy evaluator、resolution observation、set update 和 currentness runtime 均为 `unavailable`。

## replay result

**PASS（人工合同重放）**：七个 owner 均有唯一 status 与可达 continuation；代表 `planning` 分支从 `plan-revision-p1` 产生并切换到新 `plan-revision-p2`，使绑定旧 Plan 的 `approval-revision-a1` 明确 stale；`plan-check` 与 `review-projection` 分支保持 Plan 不变且不伪造新 Plan。Grounding 不成为 owner；Feedback 只有经过 owner 成功和两步 durable state observation 才能离开 unresolved set，新的 Approval 不能提前形成。
