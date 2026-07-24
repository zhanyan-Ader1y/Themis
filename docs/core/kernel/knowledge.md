# Knowledge — 知识治理

## 职责边界

Knowledge 管理从项目执行过程中沉淀的结构化知识的完整生命周期：候选识别、去重、冲突检查、审核、提升、废弃。

**Knowledge 是治理过程，不是知识存储——知识内容始终存储在 Workspace 中。Core 内不得保存项目学习结果。**

## 核心能力

| 能力 | 说明 |
|---|---|
| 候选识别 | 从执行过程中识别可能的知识候选 |
| 去重 | 检查新候选是否与已有知识重复 |
| 冲突检查 | 检查新候选是否与已有知识冲突 |
| 审核 | 对候选进行结构化审核 |
| 提升 | 将通过审核的候选提升为正式知识 |
| 废弃 | 将过时知识标记为废弃 |

## 子模块

### Candidate — 候选识别

从执行过程中识别知识候选：

- 从 Spec 执行中提取经验教训
- 从 Review 结果中提取模式
- 从 Verification 失败中提取陷阱
- 从 Outcome 分析中提取改进点
- 候选以结构化格式写入 `workspace/knowledge/candidates/`

**边界**：Candidate 只识别候选，不做质量判断。

### Deduplication — 去重

检查候选是否与已有知识重复：

- 语义相似度比较（标题、关键词、内容）
- 与 `workspace/context/` 中已有知识比较
- 与 `workspace/knowledge/candidates/` 中其他候选比较
- 重复候选标记为 `duplicate`，不再进入审核

**边界**：Deduplication 只做相似度判断，不删除重复内容（决策由审核流程做出）。

### Review — 知识审核

对候选进行结构化审核：

- 检查候选的准确性和完整性
- 检查候选是否与已有知识冲突
- 审核结果决定：`promote`（提升）、`reject`（拒绝）、`revise`（修改后重新提交）
- 审核过程记录在 `workspace/knowledge/reviews/`

**边界**：Review 是审核流程，审核标准定义在 `core/policies/knowledge-governance.yaml`。

### Promotion — 知识提升

将通过审核的候选提升为正式知识：

- 将候选内容移动到 `workspace/context/` 对应子目录
- 更新 `workspace/context/context-map.yaml` 索引
- 记录提升历史
- 架构知识 → `workspace/context/architecture/`
- 领域知识 → `workspace/context/domain/`
- 陷阱 → `workspace/context/pitfalls/`
- 决策 → `workspace/context/decisions/`

**边界**：Promotion 是执行提升动作，不判断是否应该提升（那是 Review 的职责）。

### Deprecation — 知识废弃

将过时知识标记为废弃：

- 接收来自 Context Freshness 的过期标记
- 执行废弃审核（确认该知识确实不再适用）
- 将废弃知识移动到 `workspace/knowledge/archive/`
- 更新索引，标记废弃时间

**边界**：Deprecation 是废弃执行器，废弃判断来自 Context Freshness 和人工审核。

## 知识流转全景

```
执行过程 → Candidate → Deduplication → Review → Promotion → workspace/context/
                                    ↓           ↓
                                duplicate    rejected → workspace/knowledge/rejected/
                                                         ↓
              workspace/context/ ← Deprecation ← Freshness 检测
                    ↓
        workspace/knowledge/archive/
```

## 与 Workspace 的交互

```
Knowledge 读取:
  workspace/knowledge/candidates/      # 候选知识
  workspace/context/                   # 已有知识
  workspace/outcomes/                  # 产出的经验教训

Knowledge 写入:
  workspace/knowledge/reviews/         # 审核记录
  workspace/knowledge/rejected/        # 被拒绝的候选
  workspace/knowledge/archive/         # 废弃的知识
  workspace/context/                   # 提升后的正式知识
```

## 输入/输出协议

- **输入**：通过 Context Item Protocol 读取候选和已有知识
- **输出**：治理结果通过 Outcome Protocol 记录，提升的知识通过 Context Protocol 写入 Workspace