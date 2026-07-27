# P5.5 实施索引

P5.5 将 Knowledge Governance 从文档模型落地为可安装的 Core 能力。它以 YAML 声明治理顺序和门禁，以 Prompt 完成候选提取、语义去重、冲突分析和审核建议，以 Shell 脚本执行候选持久化、契约校验和经批准的处置。正式项目知识仍只有一个权威位置：`workspace/context/`。

**状态**：实施设计待用户确认。确认前不得修改本计划列出的 Core、脚本、测试、Workspace 模板或发布文件。

## 审计结论

原草案只有 policy、两个 Prompt、rules 和 WIKI，且将所有确定性脚本推迟到 P8。这与仓库级三层执行模型冲突，也无法安全兑现候选落盘、批准校验、提升、拒绝、修订和废弃。

P5.5 必须自行提供最小确定性执行器；P8 未来只负责 Agent、Command、Skill 和跨阶段路由，不重新实现知识治理文件操作。

## 设计决策

| # | 决策 |
|---|---|
| D1 | P5.5 的明确依赖为 P1、P2、P5、P5.4；P5 提供人工批准模式，P5.4 提供 Context Item、Catalog、Signal、检索与 Freshness 契约。 |
| D2 | `workspace/context/` 是唯一正式知识库；`workspace/knowledge/` 只保存候选、审核、拒绝、处置和历史归档记录。 |
| D3 | 候选和治理记录采用追加式历史。拒绝、合并重复或修订均不删除原候选；修订创建带 `supersedes` 的新候选。 |
| D4 | v1 的所有最终处置都要求持久化人工批准。AI 只可提取候选、标记潜在重复/冲突并给出推荐。 |
| D5 | 精确内容/来源重复由脚本确定性识别；语义重复和事实冲突保持 Prompt 驱动，并由人工作最终裁决。不声明无实现基础的相似度数值阈值。 |
| D6 | 支持五类候选来源：`implementation_experience`、`verification_failure`、`review_finding`、`outcome`、`manual`。缺失的上游能力只能报告 unavailable，不得伪造来源工件。 |
| D7 | 可提升的 Context 类型与现有 Workspace 对齐：`architecture`、`domain`、`engineering`、`decisions`、`pitfalls`、`glossary`、`external`。Behavior Map 是 P6 派生数据，不属于知识提升目标。 |
| D8 | Runtime 执行器安装在 `templates/.themis/core/bin/`，随 Init/Upgrade 作为 Core 内容交付；仓库根 `bin/` 只保留安装与模板支持工具。 |
| D9 | P5.5 消费 P5.4 的 Workspace Schema 与显式 Migration；不得自行创建旧 `context-map.yaml`、并行索引或独立 Freshness 状态。治理子目录的按需创建必须与获批 P5.4 Migration 契约一致。 |
| D10 | 提升和废弃必须由脚本在锁内执行，校验候选/审核摘要和批准字段，使用临时文件与回滚恢复，且不得静默覆盖既有 Context。 |
| D11 | 敏感信息判断由 Prompt/人工负责；脚本要求显式敏感度审核字段，并拒绝已知私钥 PEM 标记等明显禁入内容，但不声称完成通用秘密扫描。 |
| D12 | Freshness、Context 冲突检测、Catalog 检索、Embedding、自动路由、Agent/Command/Skill 和策略授权的自动批准不属于 P5.5。Promote 前必须消费 Context/代码核验结果。 |

## 子模块段落

| 段落 | 文件 | 覆盖内容 |
|---|---|---|
| 策略与工件契约 | [impl-01-contracts.md](impl-01-contracts.md) | `knowledge-governance.yaml`、候选/审核/处置模板、稳定 ID、Workspace 路径和 Context 索引契约。 |
| 语义 Prompt | [impl-02-prompts.md](impl-02-prompts.md) | 候选提取、去重/冲突分析、审核、人工批准与脚本 fallback。 |
| 确定性执行器 | [impl-03-executors.md](impl-03-executors.md) | record/lint/apply 三个 Bash 3.2 脚本、JSON 接口、幂等、锁和回滚。 |
| 常驻规则与测试 | [impl-04-rules-tests.md](impl-04-rules-tests.md) | 50 行 Knowledge rules、模板检查、隔离回归和知识治理模块测试。 |
| 文档与发布 | [impl-05-docs-release.md](impl-05-docs-release.md) | WIKI、工作流、计划状态、AGENTS 契约、版本和发布记录。 |

## 治理流程

```text
上游工件或人工观察
  → Prompt 提取候选语义
  → themis-knowledge-record.sh 规范化、生成摘要和稳定 ID
  → workspace/knowledge/candidates/<candidate-id>.md
  → 精确重复检查 + Prompt 语义重复/冲突分析
  → P5.4 Context Search/Signal + 当前代码核验候选事实
  → Prompt 生成审核记录和处置推荐
  → 用户确认最终处置并写入批准字段
  → themis-knowledge-lint.sh 校验候选、审核、批准和目标约束
  → themis-knowledge-apply.sh 在锁内执行
      ├─ promote → 原子写入 workspace/context/<category>/<context-id>.md + catalog.yaml
      ├─ reject → workspace/knowledge/rejected/<action-id>.md
      ├─ revise → 记录处置；新候选通过 supersedes 关联
      ├─ merge_duplicate → 记录 canonical 引用，不删除候选
      ├─ retain → 保留现有 Context 并记录废弃审核
      └─ archive → 保存历史快照、移除活动 Context、原子更新 catalog.yaml
```

## 目标文件

### Core 资产

| 文件 | 操作 |
|---|---|
| `templates/.themis/core/policies/knowledge-governance.yaml` | 新建 |
| `templates/.themis/core/templates/knowledge-candidate.md` | 新建 |
| `templates/.themis/core/templates/knowledge-review-record.md` | 新建 |
| `templates/.themis/core/templates/knowledge-action-record.md` | 新建 |
| `templates/.themis/core/templates/knowledge-candidate-extraction.md` | 新建 |
| `templates/.themis/core/templates/knowledge-review.md` | 新建 |
| `templates/.themis/core/bin/themis-knowledge-record.sh` | 新建 |
| `templates/.themis/core/bin/themis-knowledge-lint.sh` | 新建 |
| `templates/.themis/core/bin/themis-knowledge-apply.sh` | 新建 |
| `templates/.themis/core/kernel/knowledge/rules.md` | 更新 |

### 契约检查与测试

| 文件 | 操作 |
|---|---|
| `bin/themis-template-check.sh` | 扩展 P5.5 静态契约检查 |
| `tests/template-contract/test.sh` | 增加缺失/损坏 P5.5 资产夹具 |
| `tests/knowledge-governance/test.sh` | 新建脚本行为 TAP 测试 |
| `tests/init/test.sh` | 断言新 Core 资产安装 |
| `tests/upgrade/test.sh` | 断言 Core 更新且 Workspace 字节不变 |

### 设计契约、WIKI 与发布

| 文件 | 操作 |
|---|---|
| `docs/design/core/kernel/knowledge.md` | 更新实际治理流程和边界 |
| `docs/design/core/policies.md` | 更新真实 policy 结构，删除虚构的相似度阈值 |
| `docs/design/core/templates.md` | 记录三个持久工件模板和两个 Prompt |
| `docs/design/core/protocols.md` | 记录候选、审核、处置和 Context provenance 约束 |
| `docs/design/workspace/overview.md` | 澄清可选子目录、追加式记录和 Catalog 处置行为 |
| `docs/design/workflow.md` | 标记 P5.5 已交付流程及 P6/P7.5/P8 的缺失输入处理 |
| `docs/plan/55-knowledge-governance/README.md` | 修正依赖、脚本边界、目标资产与验收条件 |
| `docs/plan/README.md` | P5.5 完成后更新状态 |
| `CHANGES.md` | 记录新能力 |
| `templates/.themis/VERSION`、`templates/.themis/core/core.yaml` | 协调升级 Core/Bundle 版本 |

## Task 拆分与依赖

| Task | 内容 | 依赖 | 完成条件 |
|---|---|---|---|
| KG-01 | 策略与持久工件契约 | 无 | Policy、三个工件模板的稳定 Schema、字段、枚举和路径明确。 |
| KG-02 | 候选提取与审核 Prompt | KG-01 | 两个 Prompt 读取 policy/模板，包含 Available Scripts 和缺失 fallback。 |
| KG-03 | record/lint/apply 执行器 | KG-01 | JSON 接口、幂等、锁、批准门禁、回滚和安全路径检查完成。 |
| KG-04 | Knowledge rules 与 Orchestrator 可达性复核 | KG-02、KG-03 | rules 不超过 50 行并显式 MUST Read；现有 import 图保持浅层。 |
| KG-05 | 模板检查与隔离回归 | KG-01、KG-02、KG-03、KG-04 | 新资产、稳定 ID/计数、Prompt 标题和 rules 预算均有失败夹具。 |
| KG-06 | 模块行为测试 | KG-03 | 候选、审核、六类处置、无批准拒绝、重复执行和失败回滚覆盖。 |
| KG-07 | 正式设计、计划与发布同步 | KG-04、KG-05、KG-06 | `docs/design/**` 与实现一致，版本和 Upgrade 期望同步。 |
| KG-08 | 全量验证 | KG-07 | 所有适用命令输出已观察且通过，最终工作树已检查。 |

```text
KG-01 ─┬─→ KG-02 ─┐
       └─→ KG-03 ─┼─→ KG-04 → KG-05 ─┐
                  └────────→ KG-06 ─┼→ KG-07 → KG-08
```

## 验证矩阵

| 验证项 | 方法 | 预期 |
|---|---|---|
| Policy YAML | `yq eval '.'` + 精确查询 | Schema、5 个来源、7 个分类、审核维度和允许处置完整。 |
| Shell 语法 | `bash -n` | 三个 Runtime 脚本和修改后的测试脚本均合法。 |
| Shell 静态检查 | `shellcheck` | 修改/新增 Shell 文件无 finding。 |
| 模板契约 | `bash bin/themis-template-check.sh` | 源模板成功且静默。 |
| 隔离模板回归 | `bash tests/template-contract/test.sh` | 缺文件、坏 YAML、错 Schema/ID/标题、缺脚本和超长 rules 均稳定失败。 |
| 知识治理行为 | `bash tests/knowledge-governance/test.sh` | record/lint/apply 的成功、拒绝、幂等与回滚路径通过。 |
| 无批准提升 | 测试 Workspace 指纹 | 非零退出，Context 和索引零变更。 |
| 已批准提升 | 检查 Context、索引和 action record | 三者一致写入，provenance 完整。 |
| 重复 apply | 连续执行两次 | 第二次返回 `unchanged`，无重复项。 |
| 失败回滚 | 注入索引写入失败 | 被触及的 Workspace 内容恢复原状。 |
| Init/Upgrade/Migration | 运行相应 suite | 新 Core 可安装/升级；既有 Workspace 不被 Upgrade 修改；Migration 回归不退化。 |
| 最终一致性 | `git diff --check` + `git status --short` | 无空白错误，变更仅限已确认范围。 |

## 关键行为样例

实施完成后至少人工审阅以下场景：

1. 从一次 Verification 失败提取可复用陷阱，生成 candidate 但不提升。
2. 精确重复候选被 record 脚本识别为 `unchanged`。
3. 语义相近但证据不同的候选只标记 potential duplicate，等待人工裁决。
4. 未提供 `approved_by`/`approved_at` 的 promote 被 apply 拒绝。
5. 已批准 promote 生成正式 Context、索引项和 action record。
6. revise 保留原候选并要求新候选声明 `supersedes`。
7. archive 在保存历史快照后移除活动 Context 索引；中途失败完整回滚。
8. 输入包含私钥 PEM 标记时 lint 拒绝持久化或提升。

## 非范围与后续集成

- Embedding、向量库或数值语义相似度阈值。
- P6 Context Freshness 和 Behavior Map 自动信号。
- P5.9 的结构化 Task evidence、P6.5 Verification、P6.8 Review、P7.5 Outcome 的完整生产者；P5.5 只消费实际存在且可验证的工件。
- P8 的 `Themis-Knowledge` Agent、Command、Skill、自动路由和调度。
- 无人工批准的策略授权提升。
- 自动修改或迁移既有知识工件 Schema。

## 确认门禁

本 `impl.md` 及其五个实施段落是 P5.5 的执行设计。用户确认前，只允许继续审阅和修订这些计划文档；不得创建或修改上述 Core、脚本、测试、Workspace 或发布文件。
