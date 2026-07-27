# Knowledge — 知识治理

## 职责边界

Knowledge Governance 管理观察性知识从候选、事实核验、去重、冲突评估、审核、批准到提升或废弃的完整生命周期。

**Knowledge 是治理过程，不是项目事实来源或第二套知识存储。候选、审核和批准都不能独立证明事实；正式知识只存在于受治理 `workspace/context/`。**

## 核心能力

| 能力 | 说明 |
|---|---|
| 候选识别 | 从执行过程中识别可能的知识候选 |
| 事实核验 | 通过 P5.4 Context 结果或当前代码确认候选可支撑性 |
| 去重 | 确定性检查精确重复，Prompt 标记潜在语义重复 |
| 冲突评估 | 消费 Context Signal 并提出处置建议，不自行裁决 |
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

### Validation — 事实核验与冲突评估

候选进入审核前必须区分“观察”与“可支撑项目事实”：

- 使用 P5.4 Context Search 查找相关 L3 Item、authority、Scope 和开放 Signal；
- 按声明类型读取当前代码、配置或 Schema；
- 无 Context/代码支撑时推荐 reject/revise，不得 promote；
- 与 Context 或代码冲突时保持 blocked，等待持久化人工裁决。

**边界**：人工批准授权处置，但不替代事实核验。Knowledge 不自行实现 Catalog 检索、Freshness 或冲突检测算法。

### Deduplication — 去重

检查候选是否与已有知识重复：

- 脚本确定性比较稳定 ID、内容摘要和来源摘要；
- Prompt 在 Context 返回的候选集合内标记潜在语义重复；
- 与其他待审候选比较，保留 canonical 引用；
- 重复处置记录为追加式 action，不删除原候选。

**边界**：Deduplication 不删除候选，也不依赖未实现的 Embedding 相似度阈值。

### Review — 知识审核

对候选进行结构化审核：

- 检查候选的准确性和完整性
- 检查候选是否与已有知识冲突
- 审核结果决定：`promote`（提升）、`reject`（拒绝）、`revise`（修改后重新提交）
- 审核过程记录在 `workspace/knowledge/reviews/`

**边界**：Review 是审核流程，审核标准定义在 `core/policies/knowledge-governance.yaml`。

### Promotion — 知识提升

将通过核验和批准的候选提升为正式知识：

- 确定性 Apply 脚本在锁内写入符合 Context Item Protocol 的 L3 文件；
- 在同一原子处置中更新 `workspace/context/catalog.yaml`；
- 保留 candidate、review、action、来源 artifact/evidence 和摘要引用；
- read-back 校验 Context ID、path、digest 和引用后才记录成功；
- 支持 architecture、domain、engineering、decisions、pitfalls、glossary 和 external，Behavior Map 不经过该提升流程。

**边界**：Promotion 执行已批准动作，不判断语义，也不得在目标 Workspace 未完成 P5.4 Migration 时隐式创建或转换结构。

### Deprecation — 知识废弃

将过时知识标记为废弃：

- 接收来自 `workspace/state/context-signals/` 的 stale 或 conflict Signal；
- 执行废弃审核并持久化人工决定；
- 保存被废弃 Context 的历史快照与 action；
- 原子移除活动 L3 Item 和 Catalog 项，不改写历史候选。

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
  workspace/knowledge/candidates/      # 追加式候选
  workspace/knowledge/reviews/         # 审核与批准
  workspace/context/catalog.yaml       # 正式 Context 注册表
  workspace/context/                   # 已有 L3 知识
  workspace/state/context-signals/     # Context 发现的冲突与过期
  当前代码、配置与 Schema              # 候选事实核验

Knowledge 写入:
  workspace/knowledge/reviews/         # 审核记录
  workspace/knowledge/actions/         # 经批准处置记录
  workspace/knowledge/rejected/        # 拒绝记录
  workspace/knowledge/archive/         # 废弃快照与记录
  workspace/context/                   # 仅经批准的 L3 写入
  workspace/context/catalog.yaml       # 与 L3 原子更新
```

## 输入/输出协议

- **输入**：Knowledge Candidate/Review/Action 工件、Context Bundle/Signal 与当前代码核验结果
- **输出**：追加式治理记录；经批准处置通过 Context Protocol 原子写入 L3 Item 和 Catalog