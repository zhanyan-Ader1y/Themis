# Templates — 模板层

> 规范状态：正式设计。实现状态：部分实现；当前模板包含无版本 Spec authoritative candidate，Requirement Questioning 已迁移到 sibling Project Skill `Themis-Q`，其余工件模板尚未落地。

## 职责边界

Template 提供新工件的初始结构或按需 Prompt，不是运行中的项目事实。

- Core template 与 Workspace instance 分离。
- 当前版本不原地更新既有安装或转换既有工件。
- 结构化工件必须遵守所属 Artifact Schema；当前预发布 Spec 不再保存独立 schema 或 template version 字段。
- Prompt 处理语义判断和用户交互；脚本处理确定性、可验证操作。

## 当前模板资产

| 文件 | 用途 | 状态 |
|---|---|---|
| `core/templates/spec.yaml` | 当前唯一、无独立版本字段的 Draft Spec candidate 结构 | 已实现 |
| `.claude/skills/Themis-Q/SKILL.md` | 聚焦、渐进式需求追问的方法与覆盖范围 | 已实现 |
| `.claude/skills/Themis-Q/references/adversarial-checklist.md` | 按需加载的 low 快速检查与六类对抗场景 | 已实现 |

### Draft Spec

`spec.yaml` 使用稳定对象 ID 保存 intent、scope、evidence、方案、需求、AC、假设、攻击处置、风险、回滚和批准。P5 只更新 cache candidate，随后由 `themis-spec.sh publish` 校验、渲染并发布 canonical `spec.yaml` / `spec.md` pair。`spec.md` 没有独立模板：它是带 OID 的确定性 Human 审阅投影，手改或反向同步均被禁止。

P5 记录批准证据但保持 `status: draft`；批准不是机器 lifecycle transition。Artifact 继续使用 `themis-artifact/v2`，当前预发布 Spec 是该 Artifact 下唯一、无独立版本字段的原生合同，不提供旧 Spec 模板或转换路径。

### Skill 读取规则

- `Themis-Q` 通过项目标准 Skill 目录自动发现；其目录名决定 Skill 工具与 `/Themis-Q` 的调用名称。
- Skill 正文只维护追问方法：一次一个聚焦问题、适应性深度、intent/scope/context/options/acceptance/risk 覆盖、假设挑战、对抗问题与收敛摘要。
- 详细攻击库通过 sibling reference 按需读取，避免把长场景库塞入主 Skill 正文。
- Domain `rules.md` 必须明确要求 Specification 在需要澄清时通过 Skill 工具调用 `Themis-Q`，并在能力缺失时 fail closed；不得读取退役 Core Prompt 代替调用。
- YAML policy、Context 读取、复杂度分类、收敛判断、用户确认、candidate 创建和 publisher 调用均属于 Specification，不属于 Skill 模板合同。

## 已确认但未实现的模板

- `plan.md`；
- `review.md`：从前置 Review evidence 确定性生成的 Human projection；
- `verify.md`：从 Verification Run/Evidence 确定性生成的 Human projection；
- `summary.md`：只在 Human Acceptance 通过后，从 accepted Spec/Plan/Review/Verification/Outcome 引用生成的最终交付投影；
- `knowledge-candidate.md`、`knowledge-review-record.md` 与 `knowledge-action-record.md`；
- `failure-classification.md` 与 repair handoff Prompt；
- `knowledge-candidate-extraction.md` 与 `knowledge-review.md` Prompt。

Review、Verify 和 Summary Markdown 都不是机器 result/verdict/acceptance 来源。`summary.md` 只做验收后的交付收口，记录最终范围、实际变更、接受证据、偏差、残余风险和后续事项；它不替代各阶段自己的机器记录。

后续新增模板时，需要同步定义 Artifact/Domain Protocol、稳定字段、无版本模块标识、模板检查和隔离回归。设计示例不得被当作现有文件。

## 生命周期

```text
core/templates/<artifact>
        ↓ 创建 candidate 或实例
workspace/cache/spec-candidates/<spec-id>.yaml
        ↓ publisher 验证并生成 pair
workspace/specs/<spec-id>/{spec.yaml,spec.md}
        ↓ Plan → Review → Implementation → Verification → Acceptance → Summary
项目工件独立演进；当前版本不提供原地更新
```
