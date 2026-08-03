# 恢复与 Cache

## 当前实现事实

当前实现事实只来自 code、configuration、Schema 与 observed executable behavior。Plan、Review、Context、Specification、Summary、knowledge candidate 和 Agent prose 只能提供约束或线索，不能替代 direct evidence。

## 恢复 reread

Recovery 必须重新读取：

- scope-local state 与 current pointers；
- completion/incomplete markers；
- 每个 required artifact component；
- Invocation/attempt records；
- applicable Git facts；
- last proven gate 与 durable continuation。

Recovery 不得从文件存在、自由文本或相似内容推断 completion，不自动 repair、rollback、merge 或继续 partial write。缺少、冲突或 ambiguous binding 时停在 last proven gate。

## Cache

`workspace/cache/` 只保存可重建 indexes、resolved Context bundles 与 projections。Cache：

- 不拥有 lifecycle、Intake、artifact、Context 或 currentness authority；
- 不得成为唯一 evidence；
- 可在不改变 authoritative records 的前提下清理和重建；
- stale、missing 或 conflict 时必须回到 source records 重新观察。

## Runtime 边界

Plan 35 不提供 installer、validator、Policy evaluator、state recorder、digest service、deterministic writer、command runner、transaction、lock manager 或 automatic recovery runtime。对应能力没有 observed implementation 时一律标记 `unavailable`，不得用 Python、Shell 临时 parser 或手工 machine-owned state 替代。
