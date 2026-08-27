# Knowledge Record 与聚合模型

## 1. 主题责任

本文只定义 Knowledge Record 的原子边界、scope 和聚合 view。知识类型与分层字段由 [知识类型与 L1/L2/L3 合同](types-and-layers.md) 定义；状态提交由 [存储、来源绑定与生命周期](storage-and-lifecycle.md) 定义。

## 2. atomic Knowledge Record

`atomic Knowledge Record` 是 Themico 独立治理、修订、引用、失效和替代的最小单位。其完整组成固定为：

```text
原子 Knowledge Record
= 稳定身份
+ lifecycle
+ sources 与 authorization
+ typed relations
+ L1
+ L2
+ L3
```

这些部分共同绑定到同一 record revision。任何单独复制的摘要、正文片段、关系集合或聚合条目都不能代替该 revision，也不能独立成为 current authority。

### 2.1 稳定身份与 revision

- record ID 表示一条知识跨 revision 的稳定身份；
- record revision 表示该身份在一次受治理变更后的不可变状态；
- current pointer 只指向一个完整、合法 generation 中声明的 current revision；
- 历史 revision 保留其当时的内容、来源、授权、关系和投影绑定；
- 内容变化、状态变化和被替代都通过新 revision 或新 record 表达，不静默覆盖已有 payload。

### 2.2 治理外壳

每个 record revision 必须能够追溯：

- `record_id` 与 `record_revision`；
- 已固化的 `knowledge_type` 与兼容 `zone`；
- lifecycle status；
- scope；
- source bindings；
- publication 或 lifecycle authorization；
- typed relations；
- L1、L2、L3 的精确 digest 与 revision 绑定；
- 创建该可见状态的 generation。

治理外壳和 L3 共同支撑正式记录的完整语义与可追溯性。L1/L2 是绑定该 revision 的可重建投影，不能脱离记录独立修订。

## 3. scope 模型

scope 固定由以下维度组成：

| 字段 | 含义 | 约束 |
| --- | --- | --- |
| `project` | 记录所属项目 | 单值，不能为空 |
| `domains` | 记录涉及的领域 | 多值，稳定排序并去重 |
| `architecture_units` | 记录涉及的架构单元或组件 | 多值，稳定排序并去重 |
| `features` | 记录涉及的 feature | 多值，稳定排序并去重 |

scope 用于确定性过滤、相关性判断和聚合索引。它不表达知识读取深度，也不建立“项目 L1、领域 L2、feature L3”之类层级。项目、领域、架构单元和 feature 中的每条知识仍各自拥有完整 L1、L2 和 L3。

## 4. typed relations

关系属于源 record revision，而不是独立图数据库中的第二份事实。每条关系必须包含明确的关系类型和目标 record 身份；需要引用历史时还必须显式绑定目标 revision。

关系类型由 CLI registry 闭集校验。首批核心关系包括：

- `depends_on`；
- `constrains`；
- `derived_from`；
- `applies_to`；
- `challenges`；
- `corrects`；
- `recovers_from`；
- `follows`；
- `related_to`；
- `supersedes`。

跨 Zone 关系必须显式声明。`depends_on`、`derived_from` 和 `supersedes` 必须保持无环；`supersedes` 只能由治理操作生成，不能作为 Agent 任意写入的普通关系。

跨类型提炼使用 `derived_from`：新知识创建独立 candidate 和 record，原记录的类型、状态和内容不因提炼而改变。

## 5. 聚合 view

聚合 view 是从 current record revisions 重建的 record-ID 索引，固定支持：

- project；
- domain；
- architecture unit；
- feature。

每个 view entry 只保存聚合 key 与稳定排序后的 record IDs；展示所需的发现信息通过这些 record IDs 读取其 current L1，`views.json` 不复制 L1 bytes。view 不得保存独立 narrative、结论、规则、经验正文或生命周期判断。

因此：

- view 不能被单独发布、修订、批准或引用为语义来源；
- view 与 current manifest 不一致时必须视为失效；
- view 删除或损坏时，可以从 current record revisions 和其有效 L1 重建；
- 重建 view 不创建新知识，也不改变 record bytes；
- 查询结果必须保留 record ID，使 Human 与 Agent 能回到原子记录。

## 6. 禁止的替代模型

Themico 不允许：

- 以项目、领域、架构单元或 feature 页面作为第二份正式语义；
- 把一组记录合并成无法追溯成员身份的新权威正文；
- 只修订聚合摘要而不修订原子记录；
- 以标签、目录或文本相似度隐式建立关系；
- 因跨类型总结而原地改变已有记录的 `knowledge_type`。
