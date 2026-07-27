# Knowledge — 知识治理

> 规范状态：正式设计。实现状态：已确认但未实现；当前只有领域 rules、Context/Knowledge 目录骨架和知识候选的设计合同，P5.5 执行器仍待实施设计确认。

## 职责边界

Knowledge 管理候选识别、事实核验、去重、冲突分析、审核、提升、拒绝、修订和废弃。它是治理过程，不是项目事实来源或第二套知识存储。

```text
正式项目知识: workspace/context/
治理过程数据: workspace/knowledge/
```

Core 不保存项目学习结果。Behavior Map 是 Context 管理的可重建代码派生数据，不经过 Knowledge Promotion。

## Candidate

候选可以来自 Implementation 经验、Verification 失败与 evidence、Review finding、Outcome/Attribution 分析或人工提交。

AI 可以提取和结构化 candidate，但必须保留来源、evidence、置信度和建议分类；候选、审核建议和人工批准都不能单独证明项目事实。

## 事实核验与冲突

候选进入 Promotion 前必须：

1. 通过 Context Catalog/Search 查找相关 L3 Item、authority、Scope 和开放 Signal；
2. 按声明类型读取当前代码、配置或 Schema；
3. 区分精确重复、潜在语义重复与事实冲突；
4. 无 Context 或代码支撑时返回 reject/revise 建议，不得 promote；
5. 与 Context 或代码冲突时保持 blocked，等待持久化人工裁决。

Knowledge 消费 Context 的 Catalog、Bundle、Signal 和 Freshness 结果，不实现第二套检索、索引、新鲜度或冲突算法。

## Governed Review

```text
candidate → fact validation → dedup/conflict analysis → governed review
                                                        ├─ promote
                                                        ├─ reject
                                                        └─ revise
```

- 去重只报告或记录关系，不得静默删除历史候选。
- 冲突检测只报告冲突，不静默选择事实。
- `promote`、`reject`、`revise` 必须来自持久化人工决定，或未来 policy 明确授权且可审计的决定。
- AI 只提供结构化分析和建议，不能绕过批准门禁。

## Promotion

经核验且批准的 Promotion 必须通过确定性处置：

1. 写入符合 Context Item Protocol 的 L3 文件；
2. 在同一受保护操作中更新 `workspace/context/catalog.yaml`；
3. 保留 candidate、review、decision、来源 artifact/evidence 和摘要引用；
4. read-back 校验 Context ID、path、digest 与引用；
5. 失败时回滚或报告不确定状态，不得静默覆盖既有 Context。

目标 Workspace 尚未完成 P5.4 Migration 时，不得由 Knowledge Runtime 隐式创建或转换结构。

## Deprecation

Context Freshness 或冲突 Signal 可以触发废弃候选，但不能自动删除正式知识。确认废弃后必须保存审核、来源和历史快照，并原子更新活动 L3 与 Catalog。废弃记录属于治理历史，不构成当前正式知识。

## Workspace 交互

```text
读取:
  workspace/knowledge/candidates/
  workspace/knowledge/reviews/
  workspace/context/catalog.yaml
  workspace/context/
  workspace/state/context-signals/
  当前代码、配置与 Schema
  workspace/outcomes/
  workspace/evidence/

写入:
  workspace/knowledge/reviews/
  workspace/knowledge/rejected/
  workspace/knowledge/archive/
  workspace/context/               # 仅经批准的 L3 写入
  workspace/context/catalog.yaml   # 与 L3 受保护更新
```

具体 artifact、action、脚本接口和处置枚举仍由 [P5.5 实施设计](../../../plan/55-knowledge-governance/impl.md) 确认；在该计划实施前不得声称自动候选提取、审核、Promotion 或 Deprecation 已可用。
