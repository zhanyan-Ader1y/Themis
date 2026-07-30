# Context Resolution

## Purpose

选择当前能力真正需要的受治理 Context，并明确它只提供设计约束、背景、历史或核验线索。当前实现事实必须回到代码、配置、Schema 或实际可执行行为。

## Required Flow

1. 读取 manifest 声明的 Context 入口和实际存在的 Context 文件。
2. 仅选择与当前 Current Request 或能力输入直接相关的条目。
3. 对每个条目记录 selected/excluded 与理由，不增加来源中不存在的 ID、digest 或事实。
4. 标出 missing、stale、conflict、context-code drift 和 unavailable。
5. 将选择结果作为输入引用返回调用能力；不得把它转换为当前实现证据。

## Output

```yaml
selected:
  - reference: <existing path or governed id>
    reason: <why this constraint or context is required>
excluded:
  - reference: <existing path or governed id>
    reason: <why it is not required>
limitations: []
```

## Fail-Closed Rules

- 不存在搜索、装配或验证能力时，使用有界人工读取并明确 assurance unavailable；不得引用已删除命令。
- 空候选集表示没有可用 Context，不授权推断事实。
- Governed Context 可以约束可接受方案，但不能静默改写 Current Request。
- Context、Specification、Plan、Summary、知识库和 Agent 推断都不能证明当前实现行为。
- 不从本模板编辑 Catalog、Context、lifecycle state、Plan 或项目实现。
