# 渐进查询、预算与投影

## 1. 主题责任

本文定义查询阶段、byte budget、关系扩展、fact trace、投影失效和 view 重建。查询不授予 publication authority，也不改变 Knowledge Record。

## 2. 固定渐进查询链路

查询链路固定为：

```text
CLI 确定性 L1 filter
→ Agent relevance selection
→ CLI 受预算约束读取 L2
→ Agent 决定是否升级
→ CLI 受预算约束读取 L3 与有限关系
→ CLI fact trace + Agent semantic explanation
```

各阶段必须保持职责分离。CLI 不执行自然语言语义排序；Agent 不绕过 CLI 直接遍历 `.themico` 并声称获得正式 current state。

## 3. CLI 确定性 L1 filter

查询必须显式指定至少一个 Zone。CLI 可以根据以下机器字段过滤：

- Zone；
- `knowledge_type`；
- lifecycle status；
- tags；
- project；
- domains；
- architecture units；
- features；
- current 或显式 history；
- 是否允许跨 Zone 关系扩展；
- 最大关系深度。

默认行为只返回 current active L1。空 type filter 表示所有 registry 类型；空 status filter 表示 active。结果按 record ID、revision 稳定排序。CLI 只返回与合法 current manifest 和有效投影绑定的候选。

## 4. Agent relevance selection

Agent 阅读 L1 候选后形成 relevance decision，明确：

- 选中了哪些 record IDs；
- 排除了哪些候选；
- 需要读取哪些精确 record IDs 的 L2；
- 语义判断所依据的用户任务和候选信息。

该 decision 是非权威语义选择。CLI 可以把 selected IDs 作为后续确定性读取输入，但不能把 Agent 的解释写入 machine fact trace 或 current record。

## 5. L2、L3 与关系升级

L2 和 L3 只能通过精确 record ID 请求：

- depth 1 返回治理摘要与 L1；
- depth 2 在 depth 1 基础上返回完整 L2；
- depth 3 在 depth 2 基础上返回完整 L3 Markdown。

Agent 根据 L2 的 `upgrade_when`、任务需要、风险和不确定性决定是否升级到 L3。CLI 不自动从摘要判断“需要完整语义”。

关系扩展要求：

- 默认不跨 Zone；
- 跨 Zone 必须由查询请求显式允许，且关系本身显式标记；
- 首批最大关系深度为 2；
- 只遍历 registry 中允许的 typed relation；
- 每个扩展目标仍按 current/history、预算和投影完整性校验；
- 关系相关不等于内容正确，也不等于可作为 current 项目事实。

## 6. byte budget

首批查询只实现 byte budget，不实现 token budget。`content_budget_bytes` 必填，范围为 1 byte 到 16 MiB。

预算规则为：

- CLI 对实际返回内容 bytes 计数；
- L2、L3 和关系扩展共用请求预算；
- 单个完整 item 超出剩余预算时，整个读取请求返回 `budget_exceeded`；
- 不能静默截断 L3、删除章节或只返回半个 JSON object；
- trace 记录已消费 bytes 和剩余预算；
- 在没有真实 tokenizer 时，不得用估算值声称 token enforcement。

Agent 可以在预算失败后提出更窄的 exact-ID 或更浅 depth 请求，但不能把部分缓存误报为完整读取结果。

## 7. CLI fact trace 与 Agent explanation

CLI fact trace 只记录可重放的机器事实：

- observed generation；
- searched zones；
- 实际 filters；
- candidate IDs；
- selected IDs；
- excluded IDs 及确定性原因；
- 读取的 record IDs 与 depth；
- relation expansions；
- content bytes 与剩余预算；
- projection、history 和 cross-Zone 开关。

Agent semantic explanation 独立说明：

- 为什么某条知识与当前任务相关；
- 为什么需要或不需要升级读取；
- 多条记录之间的语义关系；
- 哪些结论仍是推断或需要 Human 判断。

explanation 不能写入 CLI trace，也不能成为 record authority。CLI trace 也不能出现“最相关”“内容正确”“已证明因果”等语义判断。

## 8. 投影绑定与失效

L1 和 L2 是绑定具体 record revision 与 L3 digest 的投影。投影有效必须满足：

- record ID、record revision 与 manifest pointer 一致；
- L1 与 L2 指向同一 revision；
- L1/L2 声明的 source revision 与 L3 digest 匹配；
- projection digest 与磁盘 bytes 匹配；
- current manifest 没有引用旧 revision 投影。

record revision 变化后，旧 L1/L2 作为历史不可变 payload 保留，但不得继续作为 current 投影。投影缺失、digest 不匹配或绑定旧 revision 时，CLI 必须拒绝把它用于 current 查询。

投影失效不改变 record 的历史 payload，但在有效投影恢复前，相应 current 查询必须失败关闭，不能退回读取未绑定摘要。

## 9. 聚合 view 重建

聚合 view 只保存 current record IDs 按 project、domain、architecture unit 和 feature 的稳定索引，`views.json` 不嵌入 L1 bytes。重建流程为：

1. 打开合法 current generation；
2. 验证所有 current record 与 L1/L2 投影绑定；
3. 从 current record scope 生成稳定排序、去重的 view entries；
4. 创建新的 views 与 manifest；
5. 通过新的 generation-directory commit 使重建结果可见。

重建：

- 不调用 Agent 或模型；
- 不从 L3 自动生成新 L1/L2；
- L1/L2 缺失时不声称能够仅靠 record 与 L3 恢复，必须先由 Skill 或 Agent 形成新的投影候选并经过对应治理；
- 不创建 narrative、规则或经验摘要；
- 不修改 record bytes；
- 任一 record 或 projection 校验失败时整体失败，不提交部分 view。

因此，view 删除或损坏是可恢复的投影故障，不是知识丢失；record authority 无法验证则不能用重建掩盖。
