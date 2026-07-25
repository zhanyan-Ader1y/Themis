# P5 子模块：追问与攻击 Prompt

## 覆盖内容

- 新建 `templates/.themis/core/templates/spec-questioning.md`
- 新建 `templates/.themis/core/templates/spec-adversarial-checklist.md`

## 设计边界

P5 的 Prompt 负责对话、解释、语义推理和人工门禁；它不伪造确定性工具输出。YAML 只提供模式和阈值，Prompt 读取并落实它们。

## `spec-questioning.md`

模板包含：

1. **Role 与全局约束**：一次一问、选择项优先、所有变更都需 Spec、先 Context 后最小代码检查、持久记录关键结论、不得把 Draft 说成已批准。
2. **Available Scripts**：明确 P5 没有需求质量或状态迁移脚本；缺少 P8 执行器时保持 Draft 并报告能力缺失。
3. **Complexity Routing**：定义 low、medium、high 的 Step 0–4 模式和用户覆盖流程。
4. **Step 0 Intent Discovery**：使用比例适当的 Why 追问根因，并记录替代方案。
5. **Step 1 Scope Assessment**：识别多子系统、Pre-mortem、假设、复杂度与用户确认。
6. **Step 2 Context Gathering**：medium/high 收集约束、量化标准、Option Zero、证据及验证方法。
7. **Step 3 Design Convergence**：方案取舍、最多三个 AC 的分段确认、Draft 写入和自检。
8. **Step 4 Adversarial Validation**：攻击者角色切换、有效发现处置、未决发现与迭代上限处理。
9. **Final Approval 与 Red Flags**：要求明确批准，记录证据但不声称已写状态迁移；阻止“简单所以跳过”“先改一行”等绕过模式。

## `spec-adversarial-checklist.md`

场景库独立于流程模板：

- low 的五项快速检查；
- medium 对核心 AC 使用的聚焦方式；
- high 覆盖全部 AC 的全面方式；
- 边界条件、并发与竞态、状态转换、权限与安全、依赖失败、数据完整性六个维度；
- `cover`、`accept`、`defer` 三种记录方式与 critical 风险限制。

每个有效发现都需要 `ADV-xxx`，关联 AC 和处置。攻击库帮助 Agent 提问，不自动判定风险是否真实、哪个方案更好或用户是否已批准。

## 验证

- `spec-questioning.md` 有独立 Step 0、1、2、3、4 标题。
- Step 4 明确角色切换、三种处置与未决攻击保持 Draft 的规则。
- `spec-adversarial-checklist.md` 有五项快速检查和六个攻击维度；每个维度有多个具体问题。
- 模板与 policy 的复杂度、攻击维度、处置词和 P8 边界一致。
