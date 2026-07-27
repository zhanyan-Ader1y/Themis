# P5 实施索引

P5 将需求追问落地为可安装的 Core 能力。它以 YAML 声明门禁，以 Prompt 执行语义追问和对抗验证，以脚本验证确定性模板结构；不会在没有 P8 执行器时伪造生命周期状态迁移。

## 设计决策

| # | 决策 |
|---|---|
| D1 | 流程统一为五阶段：Step 0–4。 |
| D2 | 复杂度采用低→中→高的有序判定，用户必须确认或覆盖结论。 |
| D3 | 对抗验证、根因和批准是 Prompt/人工职责，不实现语义判断脚本。 |
| D4 | 不持久化每轮对话；只持久化 Draft Spec 的最终可复核结论。 |
| D5 | `draft_to_specified` 使用 ASCII 键的 YAML 映射，包含显式 `from`、`to` 和稳定条件 ID。 |
| D6 | P5 记录批准证据但保持 `status: draft`；P8 未来读取该证据并记录机器状态。 |
| D7 | 常驻 Specification rules 保持 50 行以内；详细流程、Red Flags 和攻击库置于 Prompt 模板。 |

## 子模块段落

| 段落 | 文件 | 覆盖内容 |
|---|---|---|
| 策略与工件契约 | [impl-01-policies.md](impl-01-policies.md) | `specification.yaml`、`transitions.yaml` 与 P5.2 `spec.yaml` 双视图稳定数据结构。 |
| 追问与攻击 Prompt | [impl-02-templates.md](impl-02-templates.md) | Step 0–4 流程、复杂度路由、Red Flags、快速检查与攻击场景库。 |
| 常驻规则与契约检查 | [impl-03-rules.md](impl-03-rules.md) | 50 行 Specification rules、Orchestrator 边界、模板检查器和 TAP 回归。 |
| 文档与发布同步 | [impl-04-docs.md](impl-04-docs.md) | WIKI、工作流、计划状态、变更记录及版本同步。 |

## 目标文件

| 文件 | 操作 | 所属段落 |
|---|---|---|
| `templates/.themis/core/policies/specification.yaml` | 新建 | impl-01 |
| `templates/.themis/core/policies/transitions.yaml` | 新建 | impl-01 |
| `templates/.themis/core/templates/spec.yaml` | 新建 | impl-01 / P5.2 |
| `templates/.themis/core/protocols/artifact/v2/` | 新建 | P5.2 |
| `templates/.themis/core/kernel/specification/themis-spec.sh` | 新建 | P5.2 |
| `templates/.themis/core/templates/spec-questioning.md` | 新建 | impl-02 |
| `templates/.themis/core/templates/spec-adversarial-checklist.md` | 新建 | impl-02 |
| `templates/.themis/core/kernel/specification/rules.md` | 更新 | impl-03 |
| `templates/.themis/core/kernel/orchestrator/rules.md` | 更新 | impl-03 |
| `bin/themis-template-check.sh` | 更新 | impl-03 |
| `tests/template-contract/test.sh` | 更新 | impl-03 |
| `docs/core/kernel/specification.md` | 更新 | impl-04 |
| `docs/core/policies.md` | 更新 | impl-04 |
| `docs/core/templates.md` | 更新 | impl-04 |
| `docs/workflow.md` | 更新 | impl-04 |
| `docs/plan/README.md`、`CHANGES.md` | 更新 | impl-04 |
| `templates/.themis/VERSION`、`core/core.yaml` | 更新 | impl-04 |

## 实施顺序

```text
策略与 Spec 契约
  → Prompt 模板
  → 规则与模板检查器
  → 隔离契约回归
  → WIKI、版本与发布记录
  → Init / Upgrade / Migration 全量回归
```

## 验证矩阵

| 验证项 | 方法 | 预期 |
|---|---|---|
| P5 policy YAML | `yq eval '.'` | 均可解析，具备稳定 map/list 结构。 |
| Policy 内容 | `yq` 查询 | 三档复杂度、六维攻击、五项快速检查、八项 readiness 条件完整。 |
| 模板契约 | `bash bin/themis-template-check.sh` | 成功且静默。 |
| 隔离失败场景 | `bash tests/template-contract/test.sh` | 缺失、损坏、错误 ID/数量/标题和超长 rules 均失败。 |
| 安装与升级 | Init/Upgrade/Migrate suites | 新 Core 资产可安装、升级且 Workspace 不变。 |
| Prompt 行为 | 受控样例审阅 | 不伪造状态迁移；各复杂度路径和未决攻击路径正确。 |

## 边界

P5 不实现机器状态迁移记录、会话持久化或命令/Skill/Agent。P5.2 已补充确定性 Spec lint/render/publish；P8 仍负责持久生命周期状态。Artifact v2 与 Spec v2 是首次发布契约，不存在历史 Spec 兼容或转换范围。
