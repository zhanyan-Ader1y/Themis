# P5.2 Spec 双视图实施设计

P5.2 将现有“YAML front matter + Markdown 正文”的单一 `spec.md` 升级为单一语义源、双视图工件：`spec.yaml` 是 Agent-readable 权威源，`spec.md` 是确定性生成的 Human-readable 审阅投影。

## 设计决策

| # | 决策 |
|---|---|
| D1 | 每个活动 Spec 固定为 `workspace/specs/<spec-id>/{spec.yaml,spec.md}`；`spec.yaml` 是唯一语义源，`spec.md` 不得反向同步。 |
| D2 | Artifact Contract 升为 `themis-artifact/v2`，Spec Protocol 升为 `themis-spec/v2`；Workspace 目录结构不变，继续使用 `themis-workspace/v1`。 |
| D3 | 新 Core 可读 Artifact v1/v2，但只写 v2；Upgrade 不修改 Workspace，旧项目经显式 `artifact-v1-to-v2` Migration 转换。 |
| D4 | `spec.yaml` 使用稳定对象 ID 与引用；Policy、Planning、Transition 和未来 P8 不得解析 Markdown 标题作为机器证据。 |
| D5 | Human 投影按“一屏摘要、关键图、关键决策、契约/不变量、全部 AC、风险/回滚、批准、附录”生成，正文不复制完整 YAML。 |
| D6 | 摘要文字及主决策、主风险、主图选择由 Agent 明确写入 `spec.yaml`；渲染器只排版，不进行语义总结。 |
| D7 | 单一 Bash 3.2 执行器 `themis-spec.sh` 提供 `validate`、`render`、`publish` 子命令，并输出机器可读 JSON。 |
| D8 | `publish` 通过 staging、配对校验、备份和恢复实现 fail-closed 发布；缺少协议/脚本或任一步失败时不得留下半套活动工件。 |
| D9 | `spec.md` 带源文件与正文 Git blob OID；源变化、正文手改或 marker 损坏均视为投影漂移，不从 Markdown 恢复 YAML。 |
| D10 | 结构有效与生命周期就绪分离：未完成 Draft 可以持久化，但只有完整 readiness、批准和当前 Human 投影才满足未来 `draft_to_specified` 条件。 |
| D11 | v1 迁移只确定性提取元数据并无损保存旧文件；自由文本不由 Shell 猜测，标记 `migration.status: review_required` 后回到 Specification 人工整理。 |
| D12 | 本次提供单 Spec 校验、渲染、发布、漂移检查和显式 Artifact Migration；P8 继续负责持久状态转换、项目级 lint、并发锁与跨工件追踪。 |

## Artifact 结构

```text
workspace/specs/<spec-id>/
├── spec.yaml                         # Agent-readable；唯一权威语义源
├── spec.md                           # Human-readable；确定性派生投影
├── plan.md                           # 后续 Planning 只从 spec.yaml 取机器输入
├── review.md
├── verify.md
└── artifacts/
    └── migration/
        └── spec-v1.md                # 迁移时保存的原始 v1 字节
```

### `spec.yaml` 顶层模型

- 元数据：`spec_schema`、`id`、`title`、`status`、`revision`、`template_version`、作者与时间；
- 审阅投影：摘要字段、主决策/风险/图引用、无图原因；
- 追问证据：复杂度、Step 0–4 状态、自检；
- 语义对象：`intent`、`scope`、`evidence`、`assumptions`、`options`、`decisions`、`requirements`；
- 执行契约：`interfaces`、`contracts`、`invariants`、`acceptance_criteria`；
- 风险治理：`adversarial_findings`、`risks`、`rollback`；
- 审批与迁移：`approval`、`migration`。

集合对象使用稳定前缀，例如 `SCP-`、`EVD-`、`OPT-`、`DEC-`、`REQ-`、`IFC-`、`CTR-`、`INV-`、`AC-`、`ASM-`、`RSK-`、`ADV-`、`DGM-`。对象身份来自 map key，引用只使用稳定 ID，不依赖数组位置或标题。

### `spec.md` 投影章节

1. `Review Summary`
2. `Architecture at a Glance`
3. `Key Decisions`
4. `Contracts and Invariants`
5. `Acceptance Criteria`
6. `Risks, Limitations, and Rollback`
7. `Approval`
8. `Appendix`

所有 AC 均展示；medium/high 最终 Spec 选择 1–2 张能暴露风险的 Mermaid 图，low 可不画图但必须说明原因。主区只保留最关键的决策、红线与风险，其余细节进入附录索引或留在 YAML。

## 实施段落

| 段落 | 主要任务 |
|---|---|
| A. 协议与版本 | 更新仓库契约；定义 Artifact v2、Spec v2、Human projection 协议和新安装版本。 |
| B. Spec 执行器 | 实现 `validate/render/publish`、OID 漂移检查、事务式双文件发布和 JSON 输出。 |
| C. P5/P8 接口 | 改造 Specification policy、transition check ID、questioning/adversarial Prompt、Specification/Planning rules。 |
| D. 显式迁移 | 统一 migration descriptor，新增 v1→v2 迁移并增强 migration verify/rollback。 |
| E. 契约与回归 | 扩展 template contract，新建 Spec artifact 测试，覆盖 Init/Upgrade/Migration。 |
| F. 文档与发布 | 同步 Protocols、Templates、Specification、Planning、Workspace、Workflow、加载链与变更记录。 |

## 目标文件

### 新增

| 文件 | 作用 |
|---|---|
| `templates/.themis/core/protocols/artifact/v2/spec-schema.yaml` | Spec v2 字段、类型、稳定 ID、引用和 readiness check 协议。 |
| `templates/.themis/core/protocols/artifact/v2/spec-projection.yaml` | Human 章节顺序、主视图限制和渲染契约。 |
| `templates/.themis/core/templates/spec.yaml` | 新 Draft 的 Agent-readable 初始模板。 |
| `templates/.themis/core/kernel/specification/themis-spec.sh` | `validate/render/publish` 确定性执行器。 |
| `templates/.themis/core/migrations/artifacts/v1-to-v2.sh` | 显式 Artifact v1→v2 迁移。 |
| `tests/spec-artifact/test.sh` | Spec schema、引用、渲染、漂移与发布回归。 |

### 修改

| 文件或范围 | 作用 |
|---|---|
| `docs/design/core/{protocols,templates}.md`、`docs/design/core/kernel/{specification,planning}.md`、`docs/design/workspace/overview.md`、`docs/design/workflow.md` | 在实施获批后同步单一语义源、双视图、机器证据与显式迁移的正式设计。 |
| `templates/.themis/{VERSION,core/core.yaml,workspace/manifest.yaml}` | Artifact v2、可读/可写兼容矩阵、迁移描述符和版本。 |
| `templates/.themis/core/policies/{specification,transitions,migration}.yaml` | 投影规则、readiness check、稳定 transition evidence 与迁移验证。 |
| `templates/.themis/core/templates/{spec-questioning,spec-adversarial-checklist,migration-execution}.md` | 使用结构化 candidate、执行器与对象级攻击处置。 |
| `templates/.themis/core/kernel/{specification,planning}/rules.md` | `spec.yaml` 权威输入、publisher-only 写入与 Planning 读取边界。 |
| `templates/.themis/{CLAUDE.themis.md,core/kernel/orchestrator/rules.md}` | 双视图路径、v1 只读兼容和 fail-closed 路由。 |
| `bin/{themis-template-check,themis-migrate}.sh` | 新 Core 契约检查、ASCII migration ID、Artifact v2 配对验证。 |
| `tests/{template-contract,init,upgrade,migrate}/test.sh` | 新安装、无损升级、显式迁移和负向 fixture。 |
| `docs/design/core/`、`docs/design/workspace/overview.md`、`docs/design/workflow.md`、`docs/analysis/loading-chain.md` | 同步正式设计、实现边界与 P5/P8 集成。 |
| `docs/plan/README.md`、`CHANGES.md` | 登记 P5.2 与已交付能力。 |

原 `templates/.themis/core/templates/spec.md` 不再作为 v2 创建模板；迁移适配器是唯一允许解析旧标题的路径。

## 实施顺序

```text
Canonical design + Protocol/Version contract
  → spec.yaml template + validator
  → Human renderer + OID drift
  → transactional publisher
  → P5 policy/Prompt/rules + Planning input
  → Artifact v1→v2 migration + verify
  → template/spec/init/upgrade/migrate tests
  → Wiki、计划、版本与变更记录
```

## 验证矩阵

| 验证项 | 方法 | 预期 |
|---|---|---|
| Spec 协议 | `yq eval` + `themis-spec.sh validate` | 最小 Draft 有效；错误类型、枚举、未知键和 ID 前缀失败。 |
| 引用完整性 | Spec artifact fixtures | dangling ref、错误目标类型、无 Requirement 的 AC 失败。 |
| Readiness | low/medium/high fixtures | Draft validity 与 Specified readiness 分离；critical defer 和超限延期阻塞。 |
| 确定性渲染 | 同一源重复 `render` | `spec.md` 字节完全一致，章节和主视图限制稳定。 |
| 投影漂移 | 修改 YAML/Markdown/marker | source OID、body OID 或 marker 检查失败。 |
| 配对发布 | 注入 validate/render/rename 失败 | 旧 pair 保持不变或恢复；新建失败不留半套文件。 |
| 模板契约 | `bash tests/template-contract/test.sh` | v2 协议、脚本、transition checks 和 rules 边界均受保护。 |
| Init | `bash tests/init/test.sh` | 新项目安装 Artifact v2 资产，不创建项目 Spec。 |
| Upgrade | `bash tests/upgrade/test.sh` | v1 Workspace 字节不变；旧 `spec.md` 不被 Upgrade 转换。 |
| Migration | `bash tests/migrate/test.sh` | 原文保全、多 Spec、幂等、review_required、最后更新 manifest、失败回滚。 |
| 环境回归 | `bash tests/init-environment/test.sh` | 基础环境契约无回归。 |
| Shell | `bash -n`、ShellCheck | 所有修改脚本兼容 Bash 3.2 且无 ShellCheck 问题。 |
| 最终检查 | 端到端 fixture、`git diff --check`、工作树检查 | 双视图全链路工作，文档/版本/模板同步。 |

## P8 边界

P5.2 不执行或持久化 `draft → specified`，不写 `workspace/state/transitions/`，不实现项目级持续 lint、并发锁、CI Gate、全局状态查询或 AC→Task→Gate→Evidence 跨工件追踪。P8 必须复用 `themis-spec.sh validate` 的稳定 JSON check ID，不得重新实现第二套 Spec 解析器。

## 确认门禁

本文件确认前，不修改上述 Core、脚本、测试、版本或长期文档。用户确认后才按实施顺序开始编码。
