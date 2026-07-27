# Protocols — 协议层

> 规范状态：正式设计。实现状态：部分实现；Artifact v2 Spec Schema 与 Human projection protocol 已以机器可读 YAML 落地；其余主要协议及 P5.4/P6 协议尚未落地。

## 职责边界

Protocol 定义 Core 与 Workspace、Core 与外部工具之间的数据格式和稳定语义。Protocol 是接口合同，不是处理实现。

- 协议必须版本化；新 Core 遇到不支持的数据版本时给出明确诊断，不静默解释。
- 兼容性由 `core.yaml` 中的 supported allow-list 与 migration descriptor 决定，不由版本字符串相等决定。
- 协议演进需要保持可解释性；无法直接兼容时通过显式 [Migration](migrations.md) 转换。
- Core policy 与 Workspace override 不得改变协议语义或把失败重新解释为成功。

## 协议命名空间

| 协议 | 目标合同 | 当前状态 |
|---|---|---|
| Artifact | Spec、Plan、Review、Verify 的字段、版本、引用和状态 | Spec v2 已实现；其他 Artifact 仍为设计合同 |
| Gate | Gate 输入、执行状态、证据和失败原因 | 已确认但未实现 |
| Evidence | 证据类型、来源、时间、关联 Gate/Spec 与存储引用 | 已确认但未实现 |
| Context | Item、Catalog、Bundle、Signal 与 Behavior Map | 已确认但未实现 |
| Outcome | success、rework、defect、incident、rollback 及其关联 | 已确认但未实现 |
| Adapter | 命令、参数、环境、退出码、stdout/stderr 和结构化结果 | 已确认但未实现 |

## Spec Artifact v2

新安装使用 `themis-artifact/v2`，其中 `themis-spec/v2` 是唯一可读写的 Spec 协议。机器可读的权威合同位于：

- `core/protocols/artifact/v2/spec-schema.yaml`：严格顶层字段、对象类型、稳定 ID、引用完整性与八项 readiness check；
- `core/protocols/artifact/v2/spec-projection.yaml`：从 `spec.yaml` 到 `spec.md` 的固定章节、主视图限制、LF/终止换行与 OID 漂移合同。

`workspace/specs/<spec-id>/spec.yaml` 是唯一语义源；`spec.md` 是确定性生成的审阅投影。任何机器消费者只解析 YAML 和 validator JSON，绝不将 Markdown 标题或正文当作证据。当前 v2 是首次发布的原生合同：不支持 Artifact v1、Spec v1 或其迁移描述符。

validator 将结构有效性与 lifecycle readiness 分离，并稳定输出：

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

未来 P8 必须消费这些输出，而非重建另一个 Spec parser。

## Context Protocol

Context 使用职责独立、相互引用的协议：

- **Context Item**：L3 正式知识，记录稳定 ID、category、knowledge kind、authority、status、scope、tags、provenance、source revision、content digest、freshness、dependencies 和 supersession。
- **Context Catalog**：`workspace/context/catalog.yaml` 的唯一持久注册表，保存 Item 身份、路径和完整性元数据。
- **Context Bundle**：按 Spec/Task 查询装配的可重建快照，记录选中与排除项、代码路径、revision/digest、token budget、选择理由、未决 Signal 和完整性状态。
- **Context Signal**：持久记录 `missing`、`stale`、`context_conflict`、`context_code_drift` 等问题及其来源和处置状态。
- **Behavior Map**：定义 B1/B2/B3、Anchor、Generation Metadata、Freshness 与 Change Localization 的结构；B1/B2 只能引用 B3，只有 `current` 且受支持的 B3 才能支撑代码事实。

L1 `.abstract.md` 和 L2 `.overview.md` 是引用 L3/B3 的 `derived_navigation` 投影，不是独立事实协议。Cache 索引和 Bundle 可以删除重建；Signal 属于 State，不能只存在 Cache。

Context Protocol 定义数据结构、引用与完整性约束，不决定知识内容是否正确，也不批准 Knowledge Promotion。完整语义见 [Context](kernel/context.md)。

## 状态词汇

不同命名空间使用独立词汇，不得混用：

| 命名空间 | 规范值 |
|---|---|
| Lifecycle | `draft`, `specified`, `planned`, `implemented`, `verified`, `reviewed`, `archived` |
| Gate execution | `pending`, `running`, `passed`, `failed`, `skipped`, `error` |
| Verification verdict | `pass`, `fail`, `inconclusive` |
| Review result | `approved`, `changes_requested`, `blocked` |
| Migration execution | `success`, `failure`, `skipped` |
| Context resolution | `complete`, `partial`, `conflict`, `unavailable` |
| Context/Map freshness | `current`, `stale`, `unknown`, `unsupported` |
| Spec approval | 使用 Spec 中独立的 approval decision，不等同于 lifecycle status |

Task 状态目前尚无已实现的统一确定性合同。计划文档、Markdown checklist 或 Agent 任务工具中的状态不能自动成为 Themis Task Protocol。

## Gate Protocol

Gate 输入至少包含 Spec/Plan 引用、代码变更范围和有效策略；输出包含：

- 一个 Gate execution 状态；
- 证据引用；
- 失败或不可用原因；
- Gate 类型（blocking、warning 或 informational）；
- 超时和执行元数据。

Gate 状态不是 Verification verdict。多个 Gate 结果由 Verification 聚合为 `pass`、`fail` 或 `inconclusive`。

## 与 Core 和 Workspace 的关系

```text
Protocols 定义稳定格式和语义
        ↓
Core Kernel / Adapter 按合同读取与输出
        ↓
Workspace 保存符合合同的项目数据和证据
```

当前 `templates/.themis/core/protocols/` 已包含 Spec v2 与 projection YAML；其他机器可读协议尚未落地，相关设计不得被表述为完整运行时。
