# Templates — 模板层

> 规范状态：正式设计。实现状态：部分实现；当前模板包含 Spec v2 authoritative candidate、需求追问和对抗清单，其余工件模板尚未落地。

## 职责边界

Template 提供新工件的初始结构或按需 Prompt，不是运行中的项目事实。

- Core template 与 Workspace instance 分离。
- 当前版本不原地更新既有安装或转换既有工件。
- 结构化工件必须记录 Schema 或 template version。
- Prompt 处理语义判断和用户交互；脚本处理确定性、可验证操作。

## 当前模板资产

| 文件 | 用途 | 状态 |
|---|---|---|
| `spec.yaml` | `themis-spec/v2` Draft 的唯一权威、Agent-readable candidate 结构 | 已实现 |
| `spec-questioning.md` | P5 Step 0–4 自适应需求追问 | 已实现 |
| `spec-adversarial-checklist.md` | low 快速检查与六类对抗场景 | 已实现 |

### Draft Spec

`spec.yaml` 使用稳定对象 ID 保存 intent、scope、evidence、方案、需求、AC、假设、攻击处置、风险、回滚和批准。P5 只更新 cache candidate，随后由 `themis-spec.sh publish` 校验、渲染并发布 canonical `spec.yaml` / `spec.md` pair。`spec.md` 没有独立模板：它是带 OID 的确定性 Human 审阅投影，手改或反向同步均被禁止。

P5 记录批准证据但保持 `status: draft`；批准不是机器 lifecycle transition。当前 Artifact/Spec 原生版本为 v2，不提供 Spec v1 模板或转换路径。

### Prompt 读取规则

- Domain `rules.md` 必须显式要求读取当前阶段所需 Prompt、policy、template 或 checklist。
- Prompt 必须列出可用脚本和缺失时的 fallback。
- Prompt 不复制 YAML 中的步骤顺序、阈值或状态条件。

## 已确认但未实现的模板

- `plan.md`；
- `review.md`：从前置 Review evidence 确定性生成的 Human projection；
- `verify.md`：从 Verification Run/Evidence 确定性生成的 Human projection；
- `summary.md`：只在 Human Acceptance 通过后，从 accepted Spec/Plan/Review/Verification/Outcome 引用生成的最终交付投影；
- `knowledge-candidate.md`、`knowledge-review-record.md` 与 `knowledge-action-record.md`；
- `failure-classification.md` 与 repair handoff Prompt；
- `knowledge-candidate-extraction.md` 与 `knowledge-review.md` Prompt。

Review、Verify 和 Summary Markdown 都不是机器 result/verdict/acceptance 来源。`summary.md` 只做验收后的交付收口，记录最终范围、实际变更、接受证据、偏差、残余风险和后续事项；它不替代各阶段自己的机器记录。

后续新增模板时，需要同步定义 Artifact/Domain Protocol、稳定字段、版本标识、模板检查和隔离回归。设计示例不得被当作现有文件。

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
