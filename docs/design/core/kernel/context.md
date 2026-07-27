# Context — 上下文

> 规范状态：正式设计。实现状态：目录与领域 rules 已落地；自动 Discovery、Resolution、Conflict、Freshness 和 Behavior Map 生成器尚未实现。

## 职责边界

Context 管理已验证项目事实的读取、来源、冲突和新鲜度。它不决定需求、实施方案或知识提升结论，内容始终存放在 Workspace。

正式项目知识只有 `workspace/context/` 一个权威位置。AI 发现的新信息先作为 candidate 进入 Knowledge governance，未经审核不得直接写入正式 Context。

## 目标能力

| 能力 | 合同 |
|---|---|
| Discovery | 从显式 Context、代码事实和允许的外部来源发现候选 |
| Resolution | 解析引用和覆盖关系，生成可重建的有效 Context snapshot |
| Conflict | 结构化报告相互矛盾的事实、决策或过时引用，不自动裁决 |
| Freshness | 根据代码与来源变化标记可能过期内容，不自动改写正式知识 |
| Behavior Map | 以静态分析和代码证据锚点描述行为与位置 |

以上执行器目前尚未实现。

## Behavior Map

Behavior Map 是 `workspace/context/architecture/behavior-map/` 下的派生 Context 数据：

- 每条声明必须有文件、符号或调用路径等代码证据锚点。
- AI 可以辅助分类，但不能把无锚点推断写成事实。
- 首版采用手动重生成与新鲜度标记，不承诺自动增量同步。
- Map 缺失或过期时，Planning 回退到源码检查。

## Workspace 交互

目标合同：

```text
读取:
  workspace/context/
  workspace/manifest.yaml
  workspace/cache/context-index/

写入:
  workspace/cache/resolved-context/
  workspace/cache/context-index/
  workspace/knowledge/candidates/
```

Cache 只是可重建派生数据，不构成事实来源。冲突必须报告给用户或治理流程，而不是静默选择一个来源。
