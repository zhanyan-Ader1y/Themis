# P5.5 / impl-02 — 语义 Prompt

## 目标

将候选内容提取、语义重复判断、冲突分析、审核建议和用户交互保留在 Prompt 层。Prompt 读取 YAML 权威策略和工件模板，不执行确定性文件操作，也不把 AI 推荐冒充为批准。

## Candidate Extraction Prompt

文件：`core/templates/knowledge-candidate-extraction.md`

### MUST Read

开始候选提取前必须读取：

1. `core/policies/knowledge-governance.yaml`
2. `core/templates/knowledge-candidate.md`
3. 实际来源工件和证据
4. 相关 `workspace/context/` 项与待审核候选

### 流程

1. 确认来源类型和实际引用可访问。
2. 区分一次性日志、瞬时状态与可复用知识。
3. 提炼一个候选只表达一个可独立审核的知识结论。
4. 选择建议分类，但不决定最终提升目录。
5. 记录支持证据、适用范围、反例和失效条件。
6. 检查敏感信息并执行必要脱敏；无法安全脱敏则停止。
7. 形成符合 candidate 模板的结构化输入。
8. 调用 record 脚本持久化，再调用 lint 脚本校验真实结果。

### Red Flags

- 将成功一次视为长期规律。
- 只引用对话记忆，没有 artifact/evidence。
- 复制长日志或源代码而不提炼结论。
- 把未验证推断写成事实。
- 将凭证、私钥、Token、个人数据或内部敏感内容写入候选。
- 在候选阶段直接修改 `workspace/context/`。

## Knowledge Review Prompt

文件：`core/templates/knowledge-review.md`

同一 Prompt 支持 `candidate_review` 和 `context_deprecation`，但必须明确当前操作，不能混合两个决策。

### MUST Read

1. `core/policies/knowledge-governance.yaml`
2. `core/templates/knowledge-review-record.md`
3. 当前 candidate 或 Context 全文及摘要
4. candidate 引用的真实 provenance/evidence
5. 相关 Context 和其他候选
6. 已有 reviews/actions，用于识别重复处置或 stale review

### 审核流程

1. 校验审核对象及来源是否可访问。
2. 读取 lint 输出；结构无效时停止，不进入语义审核。
3. 对六个 policy 维度逐项给出 finding 和证据。
4. 区分 exact duplicate、potential semantic duplicate 和 factual conflict。
5. 给出允许枚举内的 recommendation。
6. 清楚说明推荐的影响、目标分类、canonical 引用或修订要求。
7. 一次只询问一个需要人工决定的问题。
8. 用户作出最终决定后，将 decision、rationale、approved_by、approved_at 写入 review 输入。
9. 通过 record/lint 脚本持久化并校验 review。
10. 明确告知用户即将发生的 Workspace 变更；只有用户确认执行后才调用 apply。
11. 解析 apply 的 JSON 输出，不根据 Prompt 自行声称 promote/archive 已完成。

### 人工门禁

以下都需要人工批准，而不仅是 promote：

- reject：防止 AI 丢弃有效候选；
- revise：确认原候选不应原样提升；
- merge_duplicate：确认 canonical 项确实等价；
- retain/archive：确认现有正式知识仍有效或确已过时。

缺少批准字段时，Prompt 只能保持 review 为 pending，不能调用 apply。

## Available Scripts

两个 Prompt 都必须包含下表，并在调用前检查脚本真实存在：

| Script | Purpose | Missing fallback |
|---|---|---|
| `core/bin/themis-knowledge-record.sh` | 规范化并持久化 candidate/review，输出 JSON | 停止 Workspace 写入；只在对话中展示草案并报告 capability missing。 |
| `core/bin/themis-knowledge-lint.sh` | 校验 policy、candidate、review、Context 索引和批准字段 | 停止，不把人工阅读替代为机器校验结果。 |
| `core/bin/themis-knowledge-apply.sh` | 执行已批准的 promote/reject/revise/merge/retain/archive | 停止，不手工移动、删除、覆盖 Context 或更新索引。 |

Prompt 必须解析脚本实际 JSON 和退出状态。脚本失败、输出不可解析或状态不确定时，治理流程停留在当前阶段。

## 输出边界

Candidate Extraction Prompt 的输出是 candidate 草案或 record 脚本的真实结果。

Knowledge Review Prompt 的输出是：

- 审核维度 findings；
- recommendation；
- 用户最终 decision 的持久记录；
- apply 脚本的真实 action 引用，或明确的 pending/blocked 状态。

Prompt 不得：

- 自行生成 action record；
- 手写或绕过 `catalog.yaml` 的原子更新；
- 删除或移动 candidate；
- 将 recommendation 表述为用户批准；
- 在脚本缺失时用文件工具模拟处置。

## 行为样例

至少审阅以下 Prompt 场景：

1. Verification 工件存在且包含稳定失败模式 → 生成 pitfalls 候选。
2. 只提供“我记得之前失败过” → 要求证据或降为 manual 来源，不伪造 run。
3. 候选与 Context 主题相近但作用域不同 → 标记 potential duplicate，要求人工比较。
4. 候选与现有 Context 冲突 → 禁止 promote，直到人工裁决并记录理由。
5. 用户拒绝 recommendation → 以用户 decision 为准，并保留 AI 推荐差异。
6. Freshness 信号不存在 → 不主动推断 Context 已过时。
