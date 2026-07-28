# Protocols — 协议层

> 规范状态：正式设计。实现状态：部分实现；Artifact v2 的当前唯一 Spec Schema/Human projection protocol 与 P5.4 Context 的五项无版本机器协议已落地，其余主要协议尚未落地。

## 职责边界

Protocol 定义 Core 与 Workspace、Core 与外部工具之间的数据格式和稳定语义。Protocol 是接口合同，不是处理实现。

- Spec、Context、Planning、Review、Verification、Knowledge 等业务模块只维护唯一当前合同；其 policy、protocol、result、projection、executor 标识和协议目录不得携带 `v1`、`v2` 等模块版本语义。
- 只有 `themis-core/v1`、`themis-workspace/v1`、`themis-artifact/v2` 这类顶层安装与工件兼容边界可以版本化；不支持的兼容 Schema 必须明确诊断并 fail closed。
- 业务模块合同在预发布阶段直接收敛和替换，不保留旧模块兼容、并存 Schema、转换路径或版本目录。
- 兼容性只由 `core.yaml` 中的 fixed supported/writable allow-list 决定，不由版本字符串相等、目录猜测或 Prompt 决定。
- 当前版本没有 Workspace/Artifact Schema 转换能力；不兼容演进必须延期到未来重新设计并确认的更新机制。
- Core policy 与 Workspace override 不得改变协议语义或把失败重新解释为成功。

## 协议命名空间

| 协议 | 目标合同 | 当前状态 |
|---|---|---|
| Artifact | Spec、Plan、Review、Verify、Summary 的字段、版本、引用和状态 | Artifact v2 下当前唯一 Spec 合同已实现；其他 Artifact 仍为设计合同 |
| Gate | Gate 输入、执行状态、证据和失败原因 | 已确认但未实现 |
| Review | 前置 finding、result、设计/evidence gap 与 Human projection 绑定 | 已确认但未实现 |
| Verification | Run、Gate attempt、repair state/handoff、escalation 与 verdict 引用 | 已确认但未实现 |
| Acceptance | 人工 decision、actor、time、accepted revisions、evidence refs、返工原因与 Summary gate | 已确认但未实现 |
| Knowledge | candidate、review、action 与 promoted Context 的摘要和 provenance 绑定 | 已确认但未实现 |
| Evidence | 证据类型、来源、时间、关联 Gate/Spec 与存储引用 | 已确认但未实现 |
| Context | Item、Catalog、Bundle、Signal 与共享 result/revision/digest 合同 | 已实现（五项无版本机器可读 Schema） |
| Outcome | success、rework、defect、incident、rollback 及其关联 | 已确认但未实现 |
| Adapter | 命令、参数、环境、退出码、stdout/stderr 和结构化结果 | 已确认但未实现 |

## Spec Artifact v2

新安装使用 `themis-artifact/v2`。Themis 尚未正式发布，因此该 Artifact 下只维护当前唯一 Spec 合同，不在 `spec.yaml` 中保存独立 `spec_schema` 或 `template_version`：

- `core/protocols/artifact/v2/spec-schema.yaml`：严格字段、最终 `context_basis`、对象类型、稳定 ID、引用完整性与八项 readiness check；
- `core/protocols/artifact/v2/spec-projection.yaml`：从 `spec.yaml` 到 `spec.md` 的固定章节、LF/终止换行与 OID 漂移合同。

`workspace/specs/<spec-id>/spec.yaml` 是唯一语义源；`spec.md` 是确定性 Human projection。机器消费者只解析 YAML 和 validator JSON。当前合同直接替换预发布旧结构，不提供 Spec schema 转换描述符；Artifact/Workspace/Core 自身仍按各自版本与 allow-list fail closed。

validator 稳定输出：

```text
spec_intent_complete
spec_scope_complexity_confirmed
spec_context_complete
spec_design_acceptance_complete
spec_adversarial_resolved
spec_self_check_passed
spec_user_approval_recorded
spec_projection_current
```

未来 lifecycle executor 必须复用这些输出，不重建第二个 Spec parser。

## Context Protocol

- **Context Item**：L3 正式知识，记录稳定 ID、category、knowledge kind、authority、status、scope、tags、provenance、source revision、digest、freshness、dependencies 和 supersession。
- **Context Catalog**：`workspace/context/catalog.yaml` 的唯一持久注册表。
- **Context Bundle**：按 Spec/Task 查询装配的可重建快照，记录选中/排除项、代码路径、revision/digest、token budget、选择理由、未决 Signal 和完整性状态。
- **Context Signal**：持久记录 `missing`、`stale`、`context_conflict`、`context_code_drift` 等问题及处置状态。

L1 `.abstract.md` 和 L2 `.overview.md` 是只引用 L3 的 `derived_navigation`。Cache 索引和 Bundle 可删除重建；Signal 属于 State。Context Protocol 不批准 Knowledge Promotion。

## 状态词汇

| 命名空间 | 规范值 |
|---|---|
| Lifecycle | `draft`, `specified`, `planned`, `reviewed`, `implemented`, `verified`, `archived` |
| Gate execution | `pending`, `running`, `passed`, `failed`, `skipped`, `error` |
| Review result | `approved`, `changes_requested`, `blocked` |
| Verification verdict | `pass`, `fail`, `inconclusive` |
| Human acceptance | `accepted`, `rejected` |
| Context resolution | `complete`, `partial`, `conflict`, `unavailable` |
| Context freshness | `current`, `stale`, `unknown`, `unsupported` |
| Spec approval | Spec 中独立的 approval decision，不等同于 lifecycle status |

Human Acceptance 与 Summary 是 `verified → archived` 的强制门禁，不新增 lifecycle status。Task 状态目前没有已实现的统一确定性合同。

## Gate Protocol

Gate 输入至少包含 Spec/Plan/Review 引用、实现 revision、代码变更范围和有效策略；输出包含 execution status、evidence refs、失败或不可用原因、Gate 类型、超时和执行元数据。Gate 状态不是 Verification verdict。

## Review、Verification、Acceptance 与 Knowledge Protocol

- Review evidence 保存绑定的 Spec/Plan revision、result、findings、severity、failure scenario、Context/code refs、设计与验收 evidence gaps；`review.md` 只绑定 evidence digest 并作 Human projection。
- Verification Run 保存 approved Review、effective policy、implementation revision、Gate 顺序、verdict 和 evidence refs；每个 attempt 保存精确命令、exit code、stdout/stderr refs、分类和受影响摘要。
- Repair state/handoff 保存持久 attempt、最多 3 个 repair/rerun cycle、失效 evidence 和恢复入口；Escalation 与 `candidate_pending` 或 Knowledge candidate 请求关联。
- Acceptance evidence 保存 actor、time、decision、accepted Spec/Plan/Review/Verification revisions、人工步骤结果、残余问题与拒绝返工目标。
- Summary projection 必须引用 accepted Acceptance evidence 和来源 digest；其 Markdown 不可反向覆盖 Acceptance、Run、Outcome 或 lifecycle state。
- Knowledge candidate、review、action 和 promoted Context 通过 digest 串联，并绑定 target project、Workspace root、source revision 与 evidence refs。

这些协议不执行 Gate、不修复代码、不做语义 Review、不替代人工验收或 Knowledge Promotion。除当前 Spec 合同外，机器可读 Schema 尚未落地。

## 与 Core 和 Workspace 的关系

```text
Protocols 定义稳定格式和语义
        ↓
Core Kernel / Adapter 按合同读取与输出
        ↓
Workspace 保存符合合同的项目数据和证据
```
