---
name: themico
description: 查询与渐进读取 Themico 正式项目知识，形成和审阅知识候选，并通过 themico CLI 准备与执行经授权的治理发布。
---

# themico

## 职责

本 Skill 是 Themico 的唯一公共入口，只负责路由与解释。语义合同位于 `.themico/core/references/`，机器权威由 `themico` Go CLI 承担。

## 加载路径

本 Skill 一次 Invocation 只加载一个 operation reference 和 registry 选中的一个 type factory；正文固定两条加载路径。

已有正式记录或已有 candidate：

```text
common/operation-contract
→ 唯一选中的 operation reference
→ CLI inspect/query 返回的 persisted knowledge_type
→ common/type-registry 的 identity routing table
→ 唯一选中的 type factory
→ 该 factory 的 L2/L3/semantic-check reference
```

尚无 proposed_type 的 create-candidate：

```text
common/operation-contract
→ create-candidate reference
→ common/type-registry 的 lightweight classification registry
→ Agent 提出唯一 proposed_type 与分类依据
→ common/type-registry 的 identity routing table
→ 唯一选中的 type factory
→ 该 factory 的 L2/L3 reference
```

## 边界

- 已有正式记录的 `knowledge_type` 只能来自 CLI（`candidate inspect`、`query`、`inspect` 的输出），不得根据标题、摘要或正文重新猜测类型。
- CLI 或本次流程所需 reference 不可用时，Agent 只能产出 draft 并报告 `unavailable`；不得手工修改 `.themico/workspace/`，也不得声称结果已 published、current 或 valid。
