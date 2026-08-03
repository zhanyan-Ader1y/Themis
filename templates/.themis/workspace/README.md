# Workspace 包

## 职责

Workspace 是项目拥有的持久边界，保存 Request Intake records、lifecycle artifacts、control facts、execution evidence、outcomes 与 governed knowledge candidates。Core 对 Workspace 只读；Workspace 只记录 observation 与 reference，不自行裁决 route、semantic judgment、currentness 或 completion。

## 不可绕过的边界

- `request-intake` 与 `lifecycle` 可以引用同一 immutable source，但不得共享 dynamic state、Execution Identity、failure budget、continuation authority、current pointer 或 completion state。
- Capability result、文件或路径始终不直接建立 authority；适用 authority 需要唯一 Policy control、完整 materialization、completion observation、reread 与 separate current pointer update。
- 当前实现事实只来自 code、configuration、Schema 与 observed executable behavior；Context、Plan、Review、Summary 与 Agent prose 只能提供约束或线索。
- Cache 永远可重建且 non-authoritative；restricted Policy override 不得绕过 global invariants。
- Fresh installation 必须在写入前拒绝既有 `.themis/` 或冲突 managed target；不存在 upgrade、runtime migration 或 compatibility path。

## 配置入口

[project.md](project.md) 保存项目 identity、commands、Context 来源、Gates、adapters、restricted Policy overrides 与 Workspace paths。

## 参考合同

| 参考 | 职责 |
|---|---|
| [目录归属](references/directory-ownership.md) | Family roots、路径 ownership 与 fresh scaffold 边界 |
| [Intake 与 lifecycle 隔离](references/intake-and-lifecycle-isolation.md) | 双 authority scope、assignment gate 与 partial materialization |
| [工件与状态模型](references/artifact-and-state-model.md) | Paired revisions、structured/operational records、最小 state 与 currentness |
| [完成与 Intake 保留](references/completion-retention.md) | Lifecycle completion observation、target freezing 与 `dormant-read-only` |
| [恢复与缓存](references/recovery-and-cache.md) | Direct evidence、last proven gate、恢复 reread 与 cache 非权威边界 |

## 当前保证

Plan 35 只提供 scaffold 与 Prompt-level ownership contracts。Installer、validator、Policy evaluator、state recorder、digest service、deterministic writer、command runner、transaction、lock manager 与 automatic recovery runtime 当前均为 `unavailable`。
