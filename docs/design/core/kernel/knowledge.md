# Knowledge — 知识治理

> 规范状态：正式设计。实现状态：已确认但未实现；当前只有领域 rules、Context/Knowledge 目录骨架和知识候选的设计合同，P5.5 执行器仍待实施设计确认。

## 职责边界

Knowledge 管理候选识别、事实核验、去重、冲突分析、审核、提升、拒绝、修订和废弃。它是治理过程，不是项目事实来源或第二套知识存储。

```text
正式项目知识: workspace/context/
治理过程数据: workspace/knowledge/
```

Core 不保存项目学习结果。每个 candidate、review、action 和被提升的 Context 都必须绑定 target project、Workspace root、source revision 与可解析 evidence refs；Knowledge 不得跨 Workspace 搜索、核验、提升或归档。

## Candidate

候选可以来自 Implementation 经验、Verification 失败与 evidence、Review finding、Outcome/Attribution 分析或人工提交。

Verification failure 只有在 repair/retry 预算耗尽或已持久化 escalation 后才具备候选资格；retry window 内的单次 transient failure 不得进入知识治理。

AI 可以提取和结构化 candidate，但必须保留来源、evidence、置信度和建议分类；候选、审核建议和人工批准都不能单独证明项目事实。Candidate 还必须满足 [设计治理](../../governance.md#知识候选来源与准入) 的稳定性、复用性、归因、冲突和敏感信息准入合同。

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

当前 Workspace 尚未具备目标治理结构时，不得由 Knowledge Runtime 隐式创建不兼容目录、改写 Schema 或转换既有数据。

## Verification Escalation

Verification exhaustion/escalation 可以请求记录 `verification_failure` candidate，但不能直接写入 Context。候选必须引用达到耗尽状态的 Run、失败 Gate、attempt、分类和 evidence，并继续经过事实核验、治理审核与人工批准。

当 P5.5 recorder 尚未安装或能力自检失败时，Verification 必须在 Run 中持久化 `candidate_pending` payload 并报告 `unavailable`；不得丢失草稿、手工伪造 candidate 文件或声称已经创建。

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
  workspace/knowledge/candidates/
  workspace/knowledge/reviews/
  workspace/knowledge/actions/
  workspace/knowledge/rejected/
  workspace/knowledge/archive/
  workspace/context/               # 仅经批准的 L3 写入
  workspace/context/catalog.yaml   # 与 L3 受保护更新
```

具体 artifact、action、脚本接口和处置枚举仍由 [P5.5 实施设计](../../../plan/55-knowledge-governance/impl.md) 确认；在该计划实施前不得声称自动候选提取、审核、Promotion 或 Deprecation 已可用。
