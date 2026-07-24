# Attribution — 归因

## 职责边界

Attribution 定义 Spec、代码变更、验证结果、发布和最终产出之间的关联模型。它回答"谁做了什么、结果如何"，用于长期质量分析和改进。

**Attribution 是观察者，不是参与者——它记录关联关系，不干预执行流程。**

## 核心能力

| 能力 | 说明 |
|---|---|
| 身份关联 | 将开发者、Agent、评审者与工件关联 |
| 产出模型 | 定义产出物的结构和关联关系 |
| 归因分析 | 从历史数据中分析质量模式和趋势 |

## 子模块

### Identity-Linking — 身份关联

建立执行者与产出之间的关联：

- 将开发者身份与代码变更关联
- 将 Agent 标识与自动化任务关联
- 将评审者与评审结果关联
- 身份信息通过 Git 提交记录、Session 记录等获取

**边界**：Identity-Linking 只建立关联，不评估个人表现（那是归因分析的职责）。

### Outcome-Model — 产出模型

定义产出物的结构和关联：

```
Spec → Plan → Tasks → Code Changes → Verification → Deployment → Outcome
```

- 每个产出物有唯一标识和元数据
- 产出物之间的关联关系可追溯
- 产出物类型：Spec、Plan、Task、Commit、PR、Build、Test Run、Deploy、Incident

**边界**：Outcome-Model 是数据模型，不存储实际产出（产出在 Workspace 中）。

### Attribution-Analysis — 归因分析

从历史数据中分析质量模式：

- 哪些 Spec 的返工率最高
- 哪些类型的缺陷逃逸率最高
- 哪个阶段的验证效率最低
- 分析结果写入 `workspace/outcomes/` 对应子目录

**边界**：Attribution-Analysis 只分析趋势，不提出改进建议（改进建议是 Knowledge 的职责）。

## 与 Workspace 的交互

```
Attribution 读取:
  workspace/specs/                     # 工件历史
  workspace/runs/                      # 执行历史
  workspace/outcomes/                  # 产出历史
  Git 历史（通过 Git Adapter）

Attribution 写入:
  workspace/outcomes/                  # 归因分析结果
```

## 输入/输出协议

- **输入**：通过 Outcome Protocol 读取产出数据，通过 Git Adapter 读取代码变更历史
- **输出**：分析结果通过 Outcome Protocol 写入 Workspace