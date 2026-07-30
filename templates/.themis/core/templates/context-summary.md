# Context Summary Candidate

## Purpose

提出有来源支撑的治理候选。该模板可以把已核验材料压缩为可审阅内容，但不能批准、发布、注册、计算 digest 或赋予正式权威。

## Required Inputs

- 已核验的来源材料和真实引用；
- 候选所属知识或经验治理区域；
- 适用范围、复用条件和限制；
- 未解决的不确定、冲突、freshness 与 code drift。

## Output

```yaml
candidate:
  title: <concise title>
  area: <governed knowledge or experience area>
  kind: <candidate kind>
  scope: []
  tags: []
  abstract: <L1-safe abstract>
  overview: <L2-safe overview>
  source_refs: []
  dependencies: []
body: |
  <proposed L3 detail grounded only in cited sources>
uncertainties: []
```

## Boundaries

- 不发明 ID、status、digest、revision、approval 或 Catalog entry。
- 不直接写入正式知识、经验区、Catalog、L1/L2 projection 或 cache。
- 当前代码行为只有直接代码/配置/Schema/执行证据可以证明；候选中的转述不是实现事实源。
- 缺少来源、材料 stale、冲突未解决或仅有模型推断时，不得形成事实性正文。
- 只把候选交给实际存在的独立治理流程；不存在时返回调用方并标记未持久化。
