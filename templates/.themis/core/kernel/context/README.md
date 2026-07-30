# Context Package

## Responsibility

Context 提供受治理设计约束、背景、历史和可复用经验入口，并保持这些内容与当前实现事实严格分离。当前代码、配置、Schema 和实际可执行行为必须由直接证据核验。

## Capability mapping

- `themis-grounding`：核验调用方提出的具体实现事实请求。
- `core/templates/context-resolution.md`：有界选择相关 Context。
- `core/templates/context-summary.md`：形成待独立治理的 Context candidate。

## Authority boundary

- Governed Context 可以约束可接受方案或提供搜索线索。
- Context、Themico、Specification、Plan、Review、Summary 和经验都不能证明当前实现事实。
- Context 与实现冲突时保留双方，标记 drift/conflict，不静默选择全局赢家。
- `themis-context` 只收录可复用经验，不收录项目架构、设计决定或当前实现事实。

## Workspace interaction

正式受治理内容位于 `workspace/context/`；候选和 disposition 位于 `workspace/knowledge/`；cache 永非 authority。Plan 35 不实现 Catalog mutation、index、freshness、Signal transition 或 governed apply runtime。

## Current status

Context 的历史结构声明、Catalog scaffold 和人工模板存在。旧 Shell executors 已移除；当前没有 deterministic search/assemble/lint/navigation 或事实 validator。
