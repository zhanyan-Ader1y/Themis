# governance

## 两个独立的 Human gate

Themico 的治理链上有且只有两个 Human gate，二者互相独立，任何一个的通过都不代表另一个已经通过：

1. **类型确认（type confirmation）**：Human 对 Agent 提出的 `proposed_type` 与 `classification_rationale` 做出明确确认，CLI 通过 `themico candidate confirm-type` 把 `knowledge_type` 固化到该候选。固化后不得原地改型；候选状态从 `proposed` 变为 `type_confirmed`。这一步只授权“这份材料属于这个知识类型”，不授权发布。
2. **发布授权（publication approval）**：Human 对一次已冻结的 `prepare` 产物给出 `Approval`，CLI 通过 `themico publish` 把候选提交为正式 Knowledge Record。这一步只授权“把这份已冻结内容提交为 current 记录”，不重新审视或改变类型确认结论。

两个 gate 的授权工件（`confirmation.json`、`approval.json`）都要求 `authority_ref` 等字段，但 CLI 只校验这些工件的结构和绑定关系，不声称已验证签署人的真实身份——真实身份核验属于 Human 与外部治理流程的职责，不是本 Skill 或 CLI 的职责。

## Agent 与 Human 的权限边界

- Agent 只能产生 proposal、candidate content、semantic assessment、explanation 和 relevance decision，不能产生 published、current 或 valid 的权威结论。
- 即便 `themico validate` 返回 `succeeded` 且 `Report.OK == true`，也只表示候选通过了确定性的结构与绑定校验，不代表已经发布；发布仍必须经过 `prepare publish` 与 `publish` 两步，且 `publish` 仍需要独立的 Human `Approval`。
- Semantic assessment（`assessment.json`，`status: pass|fail`）是 Agent 产出的独立语义判断，用于 `prepare publish` 的前置条件，但它本身不是 publication authority，也不能替代 Human Approval。
- CLI 是唯一 machine authority：负责结构、枚举、ID、revision、canonical digest、本地 source binding、registry、currentness、确定性过滤、byte budget、关系完整性和可见提交；Agent 侧的任何解释或推荐都不能改变这些机器事实。
