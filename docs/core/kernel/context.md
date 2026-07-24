# Context — 上下文

## 职责边界

Context 管理项目长期事实与知识的发现、解析、冲突处理与新鲜度维护。它回答"我们知道的关于这个项目的一切是什么"，但不拥有这些知识的内容——内容始终在 Workspace 中。

**Context 是治理层，不是存储层。**

## 核心能力

| 能力 | 说明 |
|---|---|
| 上下文发现 | 从项目文件、文档、配置中自动发现上下文信息 |
| 上下文解析 | 解析引用、继承和覆盖关系，生成有效上下文 |
| 冲突处理 | 检测并报告多个上下文来源之间的冲突 |
| 新鲜度维护 | 标记过期上下文，触发刷新建议 |

## 子模块

### Discovery — 上下文发现

从项目中自动发现上下文信息：

- 扫描 `workspace/context/` 中的显式上下文文件
- 通过 Adapter 从项目文件中提取隐含上下文（架构、依赖、配置）
- 从外部来源（文档链接、API Schema）获取引用的上下文
- 发现结果以候选形式提交给 Knowledge 模块进行审核

**边界**：Discovery 只负责发现，不负责审核（审核是 Knowledge 的职责）。

### Resolution — 上下文解析

解析上下文之间的引用和继承关系：

- 解析上下文项之间的引用（如 ADR 引用架构决策）
- 合并多层上下文（Core 默认 + 项目覆盖）
- 生成当前有效的上下文快照
- 快照缓存到 `workspace/cache/resolved-context/`

**边界**：Resolution 是解析引擎，不修改原始上下文内容。

### Conflict — 冲突检测

检测多个上下文来源之间的冲突：

- 同一概念的不同定义
- 矛盾的架构决策
- 过时的引用
- 冲突以结构化报告形式输出，不自动解决

**边界**：Conflict 只检测和报告冲突，不自动解决冲突（解决由开发者或 Agent 决策）。

### Freshness — 新鲜度

维护上下文的新鲜度：

- 标记每个上下文项的来源和最后更新时间
- 检测可能过期的上下文（依赖的代码已变更、外部文档已更新）
- 生成过期上下文列表供开发者审核
- 与 Knowledge 模块协作，将过期上下文标记为废弃候选

**边界**：Freshness 只标记过期，不自动更新上下文（更新需要人工确认）。

## 与 Workspace 的交互

```
Context 读取:
  workspace/context/                   # 所有项目上下文
  workspace/manifest.yaml              # 上下文入口配置
  workspace/cache/context-index/       # 上下文索引缓存

Context 写入:
  workspace/cache/resolved-context/    # 解析后的有效上下文
  workspace/cache/context-index/       # 上下文索引
  workspace/knowledge/candidates/      # 发现的新上下文候选
```

## 输入/输出协议

- **输入**：通过 Context Item Protocol 读取和解析上下文项
- **输出**：解析结果通过 Context Protocol 对外暴露，冲突报告写入 `workspace/cache/`