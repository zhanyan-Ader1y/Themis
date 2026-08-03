# Agent、Human 与 CLI 权威边界

## 1. 主题责任

本文定义 Agent、Human 和 `themico` CLI 在知识形成、查询与治理中的不可绕过分权。任何参与方都不能把自己的判断扩张为另一参与方的权威。

## 2. 三方职责

### 2.1 Agent proposal

`Agent proposal` 是非权威语义输入。Agent 可以产生：

- proposal；
- candidate content；
- proposed type 与分类依据；
- relevance decision；
- semantic assessment candidate；
- 对查询结果、风险和取舍的 explanation。

Agent 负责理解自然语言、检索项目来源、区分事实与推断、形成 L1/L2/L3 候选，并解释为什么某项知识可能相关。Agent 不能：

- 直接写入 published record；
- 声称 candidate 已成为 current 或 valid authority；
- 代替 Human 确认类型或授权高影响生命周期操作；
- 代替 CLI 分配正式身份、revision、digest、current pointer 或 generation；
- 根据正文重新解释已有正式记录的 `knowledge_type`。

### 2.2 Human authorization

`Human authorization` 负责语义与治理决定，包括：

- 明确确认新 candidate 的知识类型；
- 授权 publication；
- 授权 supersede；
- 授权 deprecate；
- 授权 archive。

Human 还负责审阅内容是否准确、证据是否充分、替代关系是否符合真实语义，以及风险是否可接受。Human 的自然语言同意必须被物化为 CLI 可校验的确认或 Approval 工件，才能参与机器提交。

CLI 不验证 `approved_by` 或 `confirmed_by` 背后人的真实身份。身份鉴别、会话信任和授权来源由宿主控制面负责；CLI 只校验字段存在、闭集值、时间格式和精确 binding。因此，不得把 CLI 的结构校验描述为人的真实身份验证。

### 2.3 Go CLI

二进制名固定为 `themico`。`themico` Go CLI 是唯一 machine authority，负责：

- validate：结构、枚举、Zone compatibility、Markdown、source 和关系完整性；
- bind：candidate、source、assessment、prepare、Approval 和 record revision 的精确绑定；
- identify：使用 `crypto/rand` 生成 16 bytes，并按固定前缀加 32 位小写十六进制编码分配稳定 ID；
- revise：创建不可变 candidate 或 record revision；
- digest：计算 canonical JSON 和原始内容 digest；
- query：执行确定性 L1 filter 和受预算约束的读取；
- commit：通过 generation-directory 完成可见提交；
- invalidate：识别 revision 变化后的旧投影；
- rebuild：从 current authority 重建索引和 view；
- trace：记录可重放的机器事实。

CLI 不判断自然语言内容是否正确、是否有价值、是否忠实概括来源或是否应被 Human 接受。它只证明机器可判定的结构、绑定、currentness、一致性和提交事实。

## 3. 治理链路

标准发布链路固定为：

```text
Agent 形成 proposal 与 candidate content
→ CLI 创建 candidate revision 并绑定本地 source
→ Human 确认 proposed type
→ CLI 固化 knowledge_type
→ CLI 执行机器校验
→ 独立 Agent 形成 semantic assessment candidate
→ CLI 固化 assessment digest
→ CLI prepare，冻结 expected generation 与完整 write set
→ Human 审阅 prepare 并出具精确 Approval
→ CLI 复核 binding、currentness 与 authorization
→ CLI 提交新 generation
```

semantic checker 不能与 candidate proposer 使用同一 identity。CLI 只能比较 identity 字段是否不同，不能声称两者在现实中确为不同的人或进程。

## 4. prepare 与 Approval 绑定

prepare 是一次待授权机器操作的不可变身份。它至少绑定：

- operation；
- candidate 或 target record 的精确 ID 与 revision；
- candidate、L1、L2、L3 和 assessment digest；
- source bindings；
- expected generation；
- 分配的 record ID 与 revision；
- 完整 write set 与 invalidation set；
- prepare identity、created time 和 prepare digest。

Approval 必须精确绑定 `operation`、`prepare_id` 和 `prepare_digest`，并包含非空的 `approved_by`、`approved_at` 与 `authority_ref`。以下任一情况都必须失败关闭，且不能产生部分可见变更：

- Approval 缺失；
- operation 不匹配；
- prepare identity 或 digest 不匹配；
- source、candidate、target record 或 generation 已变化；
- prepare 已过时；
- 生命周期操作不在闭集；
- 结构或关系完整性校验失败。

Publish 阶段不重新解释 Agent proposal，也不重新生成内容；它只复核 prepare 中冻结的输入、授权和 currentness。

## 5. 类型确认

类型确认是独立 Human gate，不与 publication Approval 合并。确认工件固定包含：

| 字段 | 约束 |
| --- | --- |
| `schema` | 必须为 `themico-type-confirmation` |
| `candidate_id` | 绑定目标 candidate |
| `candidate_revision` | 绑定待确认的确切 revision |
| `knowledge_type` | 必须在 registry 闭集内并与 Zone 兼容 |
| `confirmed_by` | 非空 Human identity 声明 |
| `confirmed_at` | 必须为 RFC3339 时间 |
| `authority_ref` | 非空授权来源引用 |

CLI 只校验字段、格式、registry、Zone compatibility 和精确 binding，不验证 `confirmed_by` 背后的真实身份。

确认流程为：

1. Agent 提出 `proposed_type` 和分类依据；
2. Human 对确切 candidate revision 出具上述确认工件；
3. CLI 校验后创建固化 `knowledge_type` 的新 candidate revision；
4. 后续 revise、validate、prepare 和 publish 只能使用该持久化类型选择 factory。

类型确认不会自动授权 publication。类型固化后，任何跨类型改写都必须创建新的派生 candidate。

## 6. 查询分权

查询时：

- CLI 负责确定性过滤、稳定排序、预算、读取和 fact trace；
- Agent 负责从 L1 候选中判断语义相关性、决定是否升级读取，并给出 semantic explanation；
- Human 可以审阅 record、trace 和 explanation，但 explanation 不回写为 current authority。

CLI trace 不能包含伪装成机器事实的“语义上最相关”“已经证明正确”等判断。

## 7. 失败关闭与不可用降级

当 `themico` CLI 不可用、registry 无法读取、current generation 非法、投影绑定失败或授权不完整时：

- Agent 只能形成 draft；
- 不得持久化正式 record；
- 不得声称 draft 已发布、current、valid 或已获机器校验；
- 不得用 Python、Shell、PowerShell、`jq`、`yq` 或手工文件写入模拟产品能力；
- 必须把不可执行的治理操作报告为 unavailable 或对应的闭集失败状态。
