# P5.3 需求追问 Skill 实施设计

P5.3 将 Requirement Questioning 从 Core Prompt 与 Spec 过程字段中拆出，落地为项目级 `Themis-Q` Skill。Skill 只维护提问方式与内容；Specification 拥有调用、事实核验、复杂度、收敛、确认、candidate 和发布流程。

## 设计决策

| # | 决策 |
|---|---|
| D1 | Requirement Questioning 实现为项目级 `Themis-Q` Skill，不实现专用 Agent。 |
| D2 | Skill 只定义一次一个聚焦问题、适应性深度、intent/scope/context/options/acceptance/risk 覆盖、假设挑战、对抗问题与收敛摘要。 |
| D3 | Skill 不定义 lifecycle、执行上下文、工具边界、持久化、确认 gate、handoff、稳定对象 ID、YAML schema、candidate 或 publisher。 |
| D4 | Specification 在当前请求需要澄清时主动通过 Skill 工具调用精确名称 `Themis-Q`；Skill 缺失或调用失败时停留 Specification，不读取旧 Prompt 或创建 candidate 代替。 |
| D5 | Specification 读取 policy、Context、既有 Specs 和必要的当前代码或配置，独立负责复杂度、事实依据、收敛、规范化摘要与最终 Draft 生成确认。 |
| D6 | 用户确认后，Specification 只创建 `workspace/cache/spec-candidates/<spec-id>.yaml` 的单一 candidate；后续批准与发布继续使用同一路径。 |
| D7 | 最终 Spec 只保存需求语义，不保存 `questioning` step status、自检勾选、逐轮问答或 handoff。 |
| D8 | Themis 尚未正式发布，不新增 Spec v3，也不保留 Spec v1/v2 概念；删除 `spec_schema`、`template_version` 与 `themis-spec/v*` 标识。Artifact、Workspace、Core 的独立版本合同保持不变。 |
| D9 | 保留八个稳定 readiness check ID；其计算基于最终 Spec 字段、稳定引用、批准和投影状态。 |
| D10 | 新增 `context_basis` 最终语义，区分 `grounded`、`not_required`、`limited`；Context 完整性由证据、理由和限制引用确定性判定。 |
| D11 | `spec_self_check_passed` 改为 validator 执行的 deterministic semantic consistency 聚合，不读取 Agent 自报布尔值。 |
| D12 | 保留 `themis-spec.sh validate/render/publish`、OID drift 与事务式 backup/restore/signal recovery。 |
| D13 | Init 将 Skill 安装到 `.claude/skills/Themis-Q/`；同名路径在写入前 fail closed，已有其他 `.claude` 内容不得被覆盖。 |
| D14 | 原 P5/P5.2 计划只追加 superseded 指针；长期规则同步到 owning `docs/design/**` 页面。 |

## 责任边界

```text
用户请求
  → Orchestrator 路由到 Specification
  → Specification 判断当前请求是否仍需澄清
  → 需要时调用 Skill("Themis-Q") 获取提问方法与覆盖指导
  → Specification 读取 policy、Context、既有 Spec 和必要代码/配置
  → Specification 组织追问、判断复杂度与收敛
  → Specification 展示规范化摘要并请求“生成 Draft Spec”确认
  → Specification 一次性创建唯一 candidate
  → validate → render/publish → canonical spec.yaml/spec.md
```

`Themis-Q` 可以要求总结 intent、scope、verified context、assumptions、selected option、requirements、AC、risks 与 rollback，但不规定这些内容如何传递或序列化。周边会话或调用能力决定返回格式。

## Spec 最终语义

```yaml
context_basis:
  disposition: grounded | not_required | limited
  evidence_refs: [EVD-*]
  limitation_refs: [ASM-* | RSK-*]
  rationale: ""
```

`spec_context_complete`：

- `grounded`：至少引用一个 `context | code | external` evidence；
- `not_required`：仅允许 confirmed low complexity，且 rationale 非空；Requirement 仍必须引用 evidence；
- `limited`：rationale、实际 evidence 和至少一个已处置 assumption/risk limitation 引用均非空。

`spec_self_check_passed` 由 validator 聚合：

- 无空 readiness 字段和已知 placeholder token；
- Review Summary 的 request/intent/root cause 与 authoritative intent 一致；
- Review included/excluded 与 scope 对齐；
- assumption、option 无 `pending`，decision 引用 selected option；
- Requirement 有 scope/evidence refs，AC 有 Requirement refs；
- rollback triggers、steps、impact 完整。

## 目标文件

### 新增

| 文件 | 作用 |
|---|---|
| `templates/.claude/skills/Themis-Q/SKILL.md` | 聚焦、适应性的需求追问方法与覆盖范围。 |
| `templates/.claude/skills/Themis-Q/references/adversarial-checklist.md` | 按需加载的快速检查与六维对抗问题库。 |

### 修改或退役

| 文件或范围 | 作用 |
|---|---|
| `bin/themis-init.sh` | 安全安装 sibling project Skill，跟踪父目录并纳入完整回滚。 |
| `bin/themis-template-check.sh` | 验证 Skill 名称、提问方式、覆盖范围、对抗 reference、收敛指导及 Specification 调用边界。 |
| `templates/.themis/core/protocols/artifact/v2/{spec-schema,spec-projection}.yaml` | 在 Artifact v2 内维护唯一无版本 Spec schema/projection。 |
| `templates/.themis/core/templates/spec.yaml` | 移除 Spec 版本与 questioning 过程字段，新增 `context_basis`。 |
| `templates/.themis/core/kernel/specification/{rules.md,themis-spec.sh}` | `rules.md` 分配 Skill/Specification 职责；executor 按最终语义计算 readiness。 |
| `templates/.themis/core/policies/{specification,transitions}.yaml` | Specification policy、semantic consistency 与稳定 transition evidence。 |
| `templates/.themis/core/templates/{spec-questioning,spec-adversarial-checklist}.md` | 退役，避免形成第二份追问内容。 |
| `tests/{template-contract,init,spec-artifact}/test.sh` | Skill 内容、Init 合并回滚、无版本 Spec/readiness 与 publisher 回归。 |
| `docs/design/**` owning pages | 同步 Skill 方法边界、Specification 流程和无版本 Spec 合同。 |

## 验证矩阵

| 验证项 | 方法 | 预期 |
|---|---|---|
| Skill bundle | Template Contract 正/负 fixture | Skill/reference 存在；一次一问、适应性覆盖、AC 分段、对抗问题和收敛摘要受保护；不要求工具、fork、确认或 handoff 合同。 |
| Specification invocation | Template Contract | `rules.md` 主动调用精确名称 `Themis-Q`，声明 Skill 只提供提问方法；缺失/失败时不创建 candidate。 |
| Init merge | Fresh 与已有 `.claude` fixture | Skill 安装到标准路径；其他内容字节不变；同名冲突在写前失败。 |
| Init rollback | Skill copy 后注入后续失败 | 只删除本次创建的 Skill/空父目录并恢复 CLAUDE、gitignore 和 `.themis`。 |
| Spec contract | low/medium/high 与三种 context disposition fixtures | 无版本 Spec 有效；任何版本字段、questioning/process-state、无效引用和不一致语义 fail closed。 |
| Stable readiness | Validator JSON | 八个 ID 保持不变且由最终语义正确 pass/fail。 |
| Publisher | render/drift/backup/rename/restore/interrupt fixtures | 确定性和事务行为无回归，新建失败不留半套 pair。 |
| Shell | `bash -n`、ShellCheck | 修改的 Bash 3.2 脚本零诊断。 |
| Final | `git diff --check`、`git status --short` | 无 whitespace 错误；不覆盖工作树中无关未提交变更。 |

## 非目标

- 不让 Skill 负责流程编排、Context 读取、复杂度决策、确认、持久化或 artifact 生成。
- 不实现专用 Requirement Questioning Agent、P8 状态执行器、持久会话恢复或跨会话 handoff。
- 不保存原始问答、过程 checklist 或 questioning 状态文件。
- 不转换或兼容旧 Spec schema，不恢复 Upgrade/Migration。
- 不移除 Artifact、Workspace、Core 自身的版本与 compatibility 合同。
- 不改变 Spec Human projection、publisher 事务模型或 P8 的稳定 readiness 消费边界。
