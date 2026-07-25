# P5 实施索引

本文档是 P5（Requirement Questioning）的实施总索引，列出所有子模块段落、任务、执行顺序和验证矩阵。每个子模块的详细设计与实施规范见独立文件。

## 子模块段落

| 段落 | 文件 | 覆盖的任务 | 说明 |
|---|---|---|---|
| 策略配置 | [impl-01-policies.md](impl-01-policies.md) | 任务 1、任务 5 | `specification.yaml` 和 `transitions.yaml` 的字段定义与默认值 |
| 追问模板 | [impl-02-templates.md](impl-02-templates.md) | 任务 2、任务 3 | `spec-questioning.md`（四步 Prompt）和 `spec-adversarial-checklist.md`（攻击场景库） |
| 规则引擎 | [impl-03-rules.md](impl-03-rules.md) | 任务 4 | `specification/rules.md` 重写：四步流程、Red Flags、自检清单 |
| 文档同步 | [impl-04-docs.md](impl-04-docs.md) | 任务 6 | `docs/core/kernel/specification.md` 更新 |

## 设计决策索引

| # | 决策 | 适用段落 |
|---|---|---|
| D1 | 追问在 Spec-Validation 之前 | 策略配置、规则引擎 |
| D2 | 复杂度自适应判定由 YAML 策略 + 用户确认 | 策略配置 |
| D3 | 对抗验证以 Prompt 驱动，不做确定性脚本 | 追问模板 |
| D4 | 中间状态不持久化 | 规则引擎 |
| D5 | Red Flags 嵌入 Prompt，不依赖外部脚本 | 规则引擎 |
| D6 | transitions.yaml 为声明式规则列表 | 策略配置 |

## 目标文件清单

| # | 文件 | 操作 | 所属段落 |
|---|---|---|---|
| 1 | `templates/.themis/core/policies/specification.yaml` | 新建 | impl-01 |
| 2 | `templates/.themis/core/templates/spec-questioning.md` | 新建 | impl-02 |
| 3 | `templates/.themis/core/templates/spec-adversarial-checklist.md` | 新建 | impl-02 |
| 4 | `templates/.themis/core/kernel/specification/rules.md` | 更新 | impl-03 |
| 5 | `templates/.themis/core/policies/transitions.yaml` | 新建 | impl-01 |
| 6 | `docs/core/kernel/specification.md` | 更新 | impl-04 |

## 文件间依赖

```text
specification.yaml (impl-01) ── 策略基础
       │
       ├── specification/rules.md (impl-03) ── 引用策略，定义行为
       │         │
       │         └── docs/.../specification.md (impl-04)
       │
       ├── spec-questioning.md (impl-02) ── 引用策略，Prompt 模板
       │
       └── spec-adversarial-checklist.md (impl-02) ── 引用策略，攻击场景

transitions.yaml (impl-01) ── 引用策略中的门禁条件
```

## 执行顺序

1. **impl-01**（specification.yaml + transitions.yaml）— 策略基础，其他文件引用
2. **impl-02**（spec-questioning.md + spec-adversarial-checklist.md）— 并行
3. **impl-03**（specification/rules.md）— 依赖 impl-01、impl-02
4. **impl-04**（specification.md 文档）— 依赖 impl-03

## 验证矩阵

| # | 验证项 | 验证方式 | 预期结果 |
|---|---|---|---|
| V1 | specification.yaml 语法合法 | `yq eval '.'` | 无错误退出 |
| V2 | transitions.yaml 语法合法 | `yq eval '.'` | 无错误退出 |
| V3 | transitions.yaml 含 7 个门禁条件 | `yq eval '.transitions["Draft→Specified"].conditions \| length'` | 返回 7 |
| V4 | specification/rules.md 不再含占位声明 | `grep "later Requirement Questioning"` | 无匹配 |
| V5 | rules.md 中的引用路径与模板文件一致 | 逐一手动核对 | 全部匹配 |
| V6 | spec-questioning.md 含 Step 0/1/2/3/4 五个段 | 手动检查标题 | 5 段全部存在 |
| V7 | spec-adversarial-checklist.md 含 6 个攻击维度 | 手动检查标题 | 6 维度全部存在 |
| V8 | spec-adversarial-checklist.md 含快速检查表（5 项） | 手动检查 | 5 项存在 |
| V9 | specification.md 文档新增 Requirement-Questioning 子模块 | 手动检查 | 存在 |
| V10 | docs 与 rules.md 描述一致 | 手动对比 | 无矛盾 |
| V11 | 所有文件在 templates/.themis/ 前缀下 | 手动检查路径 | 正确 |

## 相关文档

- [模块概述](README.md)
- [方法论对比分析](analysis.md)
- [Themis 完整工作流程](../../workflow.md)
- [人机混合知识治理计划](../../55-knowledge-governance/README.md)
- [验证增强计划](../../65-verification-enhancement/README.md)
- [行为地图计划](../../60-behavior-map/README.md)
