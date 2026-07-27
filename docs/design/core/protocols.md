# Protocols — 协议层

> 规范状态：正式设计。实现状态：部分实现；版本字段和部分 Markdown/YAML 合同已存在，`core/protocols/` 中尚无独立机器可读协议实现。

## 职责边界

Protocol 定义 Core 与 Workspace、Core 与外部工具之间的数据格式和稳定语义。Protocol 是接口合同，不是处理实现。

- 协议必须版本化；新 Core 遇到不支持的数据版本时给出明确诊断，不静默解释。
- 兼容性由 `core.yaml` 中的 supported allow-list 与 migration descriptor 决定，不由版本字符串相等决定。
- 协议演进需要保持可解释性；无法直接兼容时通过显式 [Migration](migrations.md) 转换。
- Core policy 与 Workspace override 不得改变协议语义或把失败重新解释为成功。

## 协议命名空间

| 协议 | 目标合同 | 当前状态 |
|---|---|---|
| Artifact | Spec、Plan、Review、Verify 的字段、版本、引用和状态 | 部分实现：Spec 模板已落地，其余主要为设计合同 |
| Gate | Gate 输入、执行状态、证据和失败原因 | 已确认但未实现 |
| Evidence | 证据类型、来源、时间、关联 Gate/Spec 与存储引用 | 已确认但未实现 |
| Context | Context item、来源、版本、新鲜度和索引 | 已确认但未实现 |
| Outcome | success、rework、defect、incident、rollback 及其关联 | 已确认但未实现 |
| Adapter | 命令、参数、环境、退出码、stdout/stderr 和结构化结果 | 已确认但未实现 |

## 状态词汇

不同命名空间使用独立词汇，不得混用：

| 命名空间 | 规范值 |
|---|---|
| Lifecycle | `draft`, `specified`, `planned`, `implemented`, `verified`, `reviewed`, `archived` |
| Gate execution | `pending`, `running`, `passed`, `failed`, `skipped`, `error` |
| Verification verdict | `pass`, `fail`, `inconclusive` |
| Review result | `approved`, `changes_requested`, `blocked` |
| Migration execution | `success`, `failure`, `skipped` |
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

当前 `templates/.themis/core/protocols/` 只有目录骨架；在机器可读 Schema 落地前，Markdown、模板和 YAML policy 提供的是部分合同，不得声称存在完整协议运行时。
