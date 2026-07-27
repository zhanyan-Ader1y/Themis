# Knowledge — 知识治理

> 规范状态：正式设计。实现状态：已确认但未实现；当前只有领域 rules、Context/Knowledge 目录骨架和知识候选的设计合同。

## 职责边界

Knowledge 管理候选识别、去重、冲突检查、审核、提升、拒绝、修订和废弃。它是治理过程，不是第二套知识存储。

正式项目知识只有：

```text
workspace/context/
```

治理过程数据位于：

```text
workspace/knowledge/
```

Core 不保存项目学习结果。

## Candidate

候选可以来自：

- Implementation 经验；
- Verification 失败与 evidence；
- Review finding；
- Outcome 与 Attribution 分析；
- 人工提交的项目事实。

AI 可以提取和结构化 candidate，但必须保留来源、evidence、置信度和建议分类，不得直接提升为正式 Context。

## Governed Review

```text
candidate → deduplication → conflict check → review
                                    ├─ promote
                                    ├─ reject
                                    └─ revise
```

- 去重只标记相似性，不自动删除。
- 冲突检测只报告冲突，不静默选择事实。
- `promote`、`reject`、`revise` 必须来自人工或 policy 明确授权的治理决定。
- Promotion 把内容写入 `workspace/context/` 的所属分类并更新索引。

## Deprecation

Context Freshness 可以提出过期 candidate，但不能自动删除正式知识。确认废弃后：

1. 保存审核与来源证据；
2. 将原内容移动到 `workspace/knowledge/archive/`；
3. 更新 Context index；
4. 保留可追溯历史。

## Workspace 交互

目标合同：

```text
读取:
  workspace/knowledge/candidates/
  workspace/context/
  workspace/outcomes/
  workspace/evidence/

写入:
  workspace/knowledge/reviews/
  workspace/knowledge/rejected/
  workspace/knowledge/archive/
  workspace/context/               # 仅在 governed promotion 后
```

自动候选提取、语义去重、审核、Promotion、Deprecation 和 index updater 当前尚未实现。
