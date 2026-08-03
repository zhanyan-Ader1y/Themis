# Plan 35：Core Contract Replacement

> 状态：2026-07-31 replacement Plan 35 的产品语义已获用户重新接受；2026-08-01 Markdown-first amendment 只重构表示和加载粒度。新的 Markdown 表示在静态证据、人工 replay 和用户明确重新接受前仍处于待核验状态，Plan 36/37 继续暂停。

本文是 replacement Plan 35 唯一 cross-module authority entry。详细合同按功能存放于同名目录的 references；这些文件共同构成本文，不单独形成第二份设计权威。

## 1. 适用范围

Plan 35 定义 Prompt-first 产品合同：

- stable identity、authority owner 与 authority scope；
- Request Intake、Source Event、Current Request claims 和 lifecycle assignment；
- 十六个 Capability、四个 Agent Profile 和 temporary Invocation；
- 唯一公共 `themis` Skill、一个 Global Rule 和一个自然语言 Policy package；
- immutable artifact revision、current pointer、materialization 与 Workspace scoping；
- Review、Approval、Impl、Verification、Acceptance、Summary；
- currentness、invalidation、failure budget、Failure Learning 和 interruption recovery；
- Prompt/template/Policy 层的静态观察、人工 replay 与重新接受边界。

Plan 35 不实现 Go parser、validator、recorder、runtime、installer、upgrade、transaction、multi-Agent execution 或 Attribution analytics。Plan 36 才拥有 strict assurance；Plan 37 才拥有 native runtime 和 write safety。

## 2. Markdown-first amendment

2026-07-31 接受的产品语义保持不变。2026-08-01 amendment 只改变表示：

- 不需要 Themis Go CLI 解析或执行的产品语义使用自然语言 Markdown；
- `templates/.themis/core/policies/README.md` 与其 references 共同构成唯一自然语言 Policy；
- paired semantic artifact 使用同一不可变 revision 下的 `record.md + content.md`；
- structured record 使用 Markdown 标题、字段表和闭合枚举；
- references 按功能拆分，公共入口只加载当前决定所需主题；
- 当前没有已批准且已实现的 Themis Go CLI 合同检查命令，自动检查状态必须写为 `unavailable`，不得以 Python、Shell 或临时脚本替代。

Markdown 表示不等于 machine enforcement。Capability result、文件存在、Agent summary 或自然语言陈述都不能替代 observed persistence 和 reread。

## 3. 不可绕过的产品摘要

1. 每条外部用户消息先成为 immutable Request Intake Source Event，再进入任何 lifecycle 语义处理。
2. `request-intake` 与 `lifecycle` 是两个隔离 authority scope，只通过 stable immutable references 关联。
3. Current Request 由 user-confirmed、source-bound claims 构成；claim 或 assignment 变化必须展示 changed-only semantic diff 并获得明确 disposition。
4. 一个 Intake 可显式创建或更新多个 lifecycle；partial target materialization 可恢复且不自动 rollback。
5. `dormant-read-only` 是 assigned Intake 的派生 retention mode，不是第五种 disposition；dormant Intake 不可附加、恢复、重激活或调度 Invocation。
6. 固定十六个 Capability 和四个 Agent Profile；只有 `themis-impl` 使用 `implementation-writer`。
7. Capability Invocation Result 永远只是 proposal；只有唯一 Policy control、完整物化、完成观察、重读和 separate current pointer update 才能形成 authority。
8. route identity 保持 `capability + selected_path + profile + status`；Global Rule 不维护第二份 route/status 表。
9. simple/full 只在 Plan 形成前分叉，`full_path_required` 在 lifecycle 内 sticky；两条路径共享 Review、Approval、Impl、Verification、Acceptance 和 Summary。
10. Review 必须发生在 Impl 前；Approval 批准 checked Plan，并绑定用户实际看到的 Review Projection。
11. Verify 固定为 `themis-impl → independent themis-verification`；两次 Invocation 共享同一 Plan Task Execution Identity 和 failure budget。
12. Summary 只允许在 current Verification `passed` 且 current Human Acceptance `accepted` 后生成。
13. Intake 与 lifecycle failure budget 隔离；每个 scope-local Execution Identity 的第三次 counted failure 终止该 identity，并禁止第四次 Invocation。
14. Failure Learning 只生成 scope-bound、non-blocking、non-recursive candidate，不修改主流程或 completion。
15. interruption 只从 durable facts 和 last proven gate 恢复；duplicate、late、stale、wrong-profile、wrong-scope 或 incomplete result 不得成为 current。

## 4. Reference 选择表

| 需要理解或修改的主题 | 必读 reference |
|---|---|
| 背景、目标、设计边界、双 scope、authority owner 与 authority 成立条件 | [权威模型](2026-07-31-plan-35-core-contract-replacement/authority-model.md) |
| Intake identity、Source Event、assignment、多目标恢复和 completion retention | [Request Intake](2026-07-31-plan-35-core-contract-replacement/request-intake.md) |
| claim model、Current Request revision、semantic diff 和两次确认协议 | [Current Request 与 Dialogue](2026-07-31-plan-35-core-contract-replacement/current-request-and-dialogue.md) |
| 十六个 Capability、四个 Profile、Invocation 与 proposal/materialization 边界 | [Capability 与 Agent Profile](2026-07-31-plan-35-core-contract-replacement/capabilities-and-profiles.md) |
| 唯一公共 Skill、Global Rule、自然语言 Policy 和控制规则完整性 | [公共入口与控制](2026-07-31-plan-35-core-contract-replacement/public-entry-and-control.md) |
| 前台 lifecycle、Questioning、simple/full 和 sticky escalation | [Lifecycle Flow](2026-07-31-plan-35-core-contract-replacement/lifecycle-flow.md) |
| paired/structured records、immutable revision、attempt 分离和 Workspace | [Artifact 与 Workspace](2026-07-31-plan-35-core-contract-replacement/artifacts-and-workspace.md) |
| Review、Approval、Impl、Verification、Acceptance 和 Summary | [Review 与 Delivery](2026-07-31-plan-35-core-contract-replacement/review-and-delivery.md) |
| currentness、invalidation、三次失败预算、Failure Learning 和 recovery | [Currentness、Failure 与 Recovery](2026-07-31-plan-35-core-contract-replacement/currentness-failure-recovery.md) |
| 静态观察、十六类 replay、实施影响、重新接受和三十二条标准 | [核验与重新接受](2026-07-31-plan-35-core-contract-replacement/verification-and-acceptance.md) |

只读取与当前决定相关的 reference；涉及多个主题时按表组合加载。不得因为 references 分片而建立多个 Policy、多个 lifecycle owner 或多个 cross-module authority。

## 5. 合同优先级

发现来源冲突时按以下顺序判断，并把无法直接裁决的冲突记录为 GAP：

1. 本文及其十个 references 组成的 current Plan 35 cross-module authority；
2. 唯一自然语言 Policy package；
3. 对应 Capability contract；
4. artifact/record template；
5. guidance 与 evidence。

较低层来源不能改变较高层的 stable identity、legal status、gate、failure class、invalidation 或 authority boundary。

## 6. 修改规则

任何跨模块行为改变都必须同时检查并更新：

- 本入口及拥有该主题的 reference；
- 唯一自然语言 Policy 中对应规则；
- 受影响 Capability 与 fixed Profile contract；
- artifact/record template 和 Workspace ownership；
- static verification、manual replay 与 acceptance evidence。

单纯调整措辞、拆分文件或改变 Markdown 呈现不得悄然修改字段、状态、门禁、失败预算、恢复语义或 authority owner。若改动实际改变产品行为，应先形成新的设计与批准，不得伪装成表示重构。

## 7. 当前核验边界

2026-07-31 的重新接受仍证明当时的 replacement 产品语义曾被接受，但不能独立证明新的 Markdown 表示合规。当前必须完成：

```text
Markdown authority and contract cutover
→ static consistency evidence
→ sixteen manual replay scenarios
→ acceptance audit
→ user reviews actual evidence
→ user explicitly re-accepts current representation
```

在最后一步前，criterion 32 保持 `PENDING USER RE-ACCEPTANCE`；不得恢复 current representation authority，也不得启动 Plan 36/37 实现。
