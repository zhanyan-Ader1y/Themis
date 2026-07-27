# P6 实施索引

本文档是 P6（Behavior Map & Change Localization）的预实施索引。P6 尚未发起；下列分段是待创建的设计任务，不是已批准的实施方案，也不授权修改 Core 或 Workspace 模板。

## 已确认的仓库级边界

- Behavior Map 是 `workspace/context/architecture/behavior-map/` 下的派生 Context，不是第二套源码权威。
- Schema、策略、Prompt、Adapter 接口和确定性执行器属于 Core；Workspace 只保存项目特定生成实例。
- Context 拥有 Map 治理与新鲜度，Planning 只读消费定位结果，Verification 只能用锚点发现检查，Knowledge 不负责提升可重新生成的 Map。
- 每条事实声明必须具有源码/配置 Evidence Anchor；不支持或无法证明的内容标记为 `unknown`、`unsupported` 或 `hypothesis`。
- P6 首版只承诺手动重生成和过期标记，不承诺自动增量同步。

## 待创建的实施段落

用户主动发起 P6 后，必须先创建并完成以下文件，再等待用户确认：

| 段落 | 待创建文件 | 覆盖任务 |
|---|---|---|
| Protocol 与 B1/B2/B3 模型 | `impl-01-model.md` | B1/B2/B3、Anchor、Generation Metadata、Freshness、Localization Schema |
| 静态事实提取 | `impl-02-extractor.md` | Adapter 能力矩阵、parser、规范化 JSON、夹具和 unsupported 行为 |
| 变更定位 | `impl-03-localization.md` | AC → Behavior Unit → Candidate Location → Task → Gate、只读 Prompt 与回退 |
| 策略、Prompt 与执行器 | `impl-04-policies-executors.md` | behavior-map.yaml、两个 Prompt、Map lint/Freshness 脚本、MUST Read 规则 |
| 测试、文档与发布 | `impl-05-tests-docs.md` | 契约检查、模块回归、WIKI、版本和计划状态 |

## 预期目标文件

| 层 | 文件 | 操作 |
|---|---|---|
| Protocol | `templates/.themis/core/protocols/context/behavior-map/v1/schema.yaml` | 新建 |
| Policy | `templates/.themis/core/policies/behavior-map.yaml` | 新建；消费 P5.4 Context Policy，不重复其 Catalog/Signal 规则 |
| Prompt | `templates/.themis/core/templates/behavior-map-generation.md` | 新建 |
| Prompt | `templates/.themis/core/templates/change-localization.md` | 新建 |
| Adapter | `templates/.themis/core/adapters/schema/behavior-extractor/` | 扩展 |
| Executor | `templates/.themis/core/bin/themis-behavior-map-lint.sh` | 新建，具体运行时目录须在 impl 中与现有安装链复核 |
| Executor | `templates/.themis/core/bin/themis-behavior-map-freshness.sh` | 新建，具体运行时目录须在 impl 中与现有安装链复核 |
| Rules | `templates/.themis/core/kernel/context/rules.md` | 更新 |
| Rules | `templates/.themis/core/kernel/planning/rules.md` | 更新 |
| Contract check | `bin/themis-template-check.sh` | 扩展 |
| Tests | `tests/template-contract/test.sh`、`tests/behavior-map/test.sh` | 扩展/新建 |
| Wiki | `docs/core/kernel/context.md`、`docs/core/kernel/planning.md`、`docs/core/adapters.md`、`docs/core/protocols.md`、`docs/workflow.md` | 更新 |
| Repository contract | `AGENTS.md`、`AGENTS.CN.md` | 按最终实现同步 |

不得把 Behavior Map Schema 预装到 `templates/.themis/workspace/context/`。Core Upgrade 不修改 Workspace，因此控制契约放入 Workspace 会导致版本漂移且无法安全更新。

## 实施依赖顺序

```text
Protocol Schema ─┬─→ Adapter 与事实夹具 ─┐
                 └─→ Policy/Prompt ─────┼─→ lint/Freshness 执行器
                                        ├─→ Context/Planning rules
                                        └─→ 契约与模块测试 → WIKI/发布 → 全量回归
```

## 待细化验证矩阵

| 验证项 | 要求 |
|---|---|
| Protocol | B1/B2/B3、Anchor、Metadata、Freshness、Localization 字段与稳定 ID 可确定性校验 |
| Adapter | 每个语言逐项声明 parse/symbol/reference/call-graph/lineage 能力，并以夹具证明 |
| Facts-First | 每条 fact 都有合法 Anchor；无锚点 statement 稳定失败 |
| Freshness | Anchor/依赖变化产生 `stale`；无法计算影响产生 `unknown` |
| Localization | 固定人工标注集报告 precision、recall、未决覆盖和错误案例 |
| Safe degradation | Map 缺失、stale、unknown、unsupported 均回退源码检查，不伪造事实 |
| Boundaries | 不修改代码、不扩展 Plan、不生成 Gate verdict、不写入 Knowledge 治理路径 |
| Performance | 固定硬件、语言组合、缓存状态、项目规模和重复次数后再声明目标 |
| Installation | Init 安装 Core 能力；Upgrade 更新 Core 且保持 Workspace 字节不变；Migration 回归通过 |

## 确认门禁

P6 被主动发起后，第一步是把上述五个分段写成完整实施设计，记录精确 Schema、Adapter 能力、脚本接口、目标文件、Task 和验证矩阵。全部分段经用户确认前，不得修改 P6 实现文件。
