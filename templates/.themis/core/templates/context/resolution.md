# Context Resolution 模板

> 本文件是只读 Context aid 的 Prompt-level Markdown 结构。它选择当前能力真正需要的受治理 Context，但不形成 lifecycle artifact、current pointer 或当前实现事实。

## 必需输入

- Current Request 或当前 Capability input bindings：
- Manifest 声明的 Context 入口：
- 实际存在的 Context references：
- 当前代码、配置、Schema 或可执行行为的直接 evidence entry points：

## 已选择的 Context

| Existing reference | Selection reason | Provided constraint/background/history/lead | Freshness or drift observation |
|---|---|---|---|

## 已排除的 Context

| Existing reference | Exclusion reason |
|---|---|

## 限制

- Missing：
- Stale：
- Conflict：
- Context-code drift：
- Search/assembly/validation assurance：`available | unavailable`

## 必需流程

1. 读取 manifest 声明的 Context 入口和实际存在的 Context 文件。
2. 仅选择与当前 Current Request 或能力输入直接相关的条目。
3. 对每个条目记录 selected/excluded 与理由，不增加来源中不存在的 identity、digest 或事实。
4. 标出 missing、stale、conflict、context-code drift 和 unavailable。
5. 将选择结果作为输入引用返回调用能力；不得把它转换为当前实现证据。

## Fail-closed 边界

不存在搜索、装配或验证能力时，使用有界人工读取并明确 assurance `unavailable`；不得引用已删除命令。空候选集表示没有可用 Context，不授权推断事实。Governed Context 可以约束可接受方案，但不能静默改写 Current Request；Context、Specification、Plan、Summary、知识库和 Agent inference 都不能证明当前实现行为。本 aid 不编辑 Catalog、Context、lifecycle state、Plan 或项目实现。
