# P5.5 — 人机混合知识治理

**优先级**：P5.5
**依赖**：[P1 Template Contract](../10-template-contract/README.md)、[P2 Top-level Guidance](../20-top-level-guidance/README.md)、[P5 Requirement Questioning](../50-requirement-questioning/README.md)、[P5.4 Context Restructure](../54-context-restructure/README.md)
**状态**：实施设计待确认

## 目标

将 Knowledge Governance 落地为可安装、可审计的人机混合能力：

```text
Candidate Extraction
  → Review Recommendation
  → Human Decision
  → Deterministic Apply
```

完整协议、Prompt、脚本、原子性和测试设计见 [impl.md](impl.md) 及 `impl-01` 至 `impl-05`。

## 职责分离

| 环节 | 责任 |
|---|---|
| Candidate Extraction | AI 从受支持来源提取结构化候选，不建立正式知识 |
| Review Recommendation | AI 检查来源、事实支撑、重复、冲突、敏感性和处置建议 |
| Human Decision | 人工持久化最终批准或拒绝；当前合同不允许自动批准 |
| Deterministic Apply | Shell 校验摘要、路径、批准、锁和 Workspace 布局，原子执行处置 |

`workspace/context/` 是正式项目知识的唯一存储；`workspace/knowledge/` 保存追加式候选、审核、人工 decision、canonical action 和历史投影，不是第二知识库。

## 治理约束

- candidate、AI recommendation 和对话都不能直接写入 Context；
- candidate 不移动、不删除，修订通过新 candidate 的 `supersedes` 关联；
- promote 前必须由受治理 Context 或当前代码核验，并绑定 provenance、对象摘要和人工批准；
- stale review、越界路径、符号链接穿越、摘要漂移或不受支持 Workspace 布局必须 fail closed；
- apply 缺失时停止，禁止用通用文件工具手工提升、拒绝、归档或更新 Catalog；
- exact duplicate 可确定性校验；semantic similarity 只能由 Prompt/人工评估，当前合同不提供 Embedding 阈值。

## 处置

Candidate disposition：

```text
promote | reject | revise | merge_duplicate
```

Context deprecation disposition：

```text
retain | revise | archive
```

所有处置都在 `workspace/knowledge/actions/` 生成 canonical `KAC-*` 记录。reject 可在 `rejected/` 生成投影；archive 可在 `archive/` 保存历史快照，但这些目录不替代 candidate、action 或当前正式 Context。

## Workspace 与安装边界

fresh Init 安装 policy、工件模板、Prompt、Runtime 脚本和 current Workspace 骨架。已有 `.themis` 不由本能力覆盖、补建或转换。

Runtime 只接受当前受支持的 Catalog 与治理布局。缺失目录、Catalog 或 Schema 不受支持时返回 `unsupported_workspace_layout` 或 `unavailable`，不得创建不兼容结构、改写 manifest/schema 或转换旧数据。

## 验收条件

1. Policy 使用稳定根 Schema，并定义来源、分类、审核维度、处置和人工批准字段。
2. candidate/review/action 工件具有稳定 Schema、ID、摘要绑定和 provenance。
3. record/lint/apply 使用 Bash 3.2、mikefarah/yq v4 和单一 JSON 结果。
4. apply 具备锁、幂等、dry-run、事务提交、信号恢复与回滚。
5. candidate 始终追加保留，任何最终处置都具有 canonical action。
6. unsupported layout 与 unavailable capability 不修改 Workspace。
7. Template Contract、Knowledge Governance、fresh Init 与相关回归测试全部通过。

## 非范围

- Embedding、向量检索或自动语义去重；
- P6 Freshness、P7.5 Outcome 分析或 P8 Agent/Command/Skill 路由；
- Behavior Map、Anchor 或其他派生源码表示；
- 自动批准、自动 Context 更新或 Workspace Schema 转换。
