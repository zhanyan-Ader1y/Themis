# FEATURE 候选意见与处置索引

> 文档状态：设计输入索引，不拥有长期规则。下方“原始输入”保留调研与实践记录；每条结论必须以“处置矩阵”链接的唯一 owning design page 为准。
>
> 实现状态：能力退役与正式设计收敛已采纳；P5.4 Context、P5.5 Knowledge、P6.5 Verification recovery 与 P6.8 Review runtime 仍未实现。

## 原始输入

阅读"C:\Users\lin10\Downloads\Blogs\爆肝长文：SDD 实战下篇，从渐进式 SDD 到 Lattice Harness：AI Coding 的团队级闭环.html"中的四、五章

补充阅读（先summary，后续有相应知识涉及再从文章查找）："C:\Users\lin10\Downloads\Blogs\爆肝长文：SDD 实战上篇，从 Vibe Coding 到渐进式 Spec驱动开发.html"
## 冗余功能移除

- 移除behavior-map
- 移除migration、upgrade，在正式上线后再添加（原始设想；当前裁决为退役，未来恢复必须重新设计）
- 禁止过于复杂的脚本
- 分析policies模块是否有必要存在

## 明确设计

- 明确哪一类功能通过自然语言描述、哪一类通过yaml+脚本实现（需要考虑维护成本，agent执行不可靠或复杂流程脚本才是第一选择）
- Themis的终极目的是将项目中的“坑”沉淀到知识中，在不断使用Themis的过程中让Themis对项目的理解越来越深
- Themis的重点应该在以下几点：帮助用户阐明需求、通过时序图等简洁明了的方式降低review阶段的复杂度、能自主学习（知识spec过程中的学习或human主动学习）
- 将明确下来的设计记录到AGENTS中

## 知识库优化：Themis中的知识应该是怎样的


### 实践经验

- 如果把反复 Prompt 最终收敛出来的约束提前写下来、结构化、固定住，比如“要幂等”“余额不能为负”“失败不重试”，Vibe 里的临时判断就变成了团队可复用的约束资产。

- Spec Coding 的核心价值不是约束 AI，而是把团队认可的路径提前固定下来。

- 最高 ROI 的 spec 形式往往不是文件。 而是 CLAUDE.md、验收测试、brainstorm 对话和关键决策表，知识的来源不仅仅是spec文件中的内容。

- Context 不是代码真相源，而是帮助 Agent 少看错、少漏看，并把采用依据写进 Spec。代码、测试和 schema 仍是真相源。

- 代码能告诉模型“现在怎么写”，但不一定能告诉它“为什么必须这么写”。适合进入知识库的内容，是高稳定、高复用、跨需求会反复影响判断的规则：业务不变量、历史事故、架构决策、团队约定、接口契约。临时讨论、大段源码、泛 prompt 技巧都不适合直接进长期知识。关键标准很简单：这条信息如果不提前告诉 AI，它会不会做出“能跑但不对”的实现？会，就值得沉淀。不会，就别污染知识库。

- 让Themis的失败进入循环：很多 AI Coding 的失败不是“模型不会写”，而是失败信息没有被结构化利用。编译失败、测试失败、漂移失败都只是终端里的一段输出，下一轮 Agent 又重新猜。pipline中引入失败经验loop：
  - 任一步失败立即停止
  - 失败后 Agent 可以修复并重跑
  - 默认最多 3 次重试
  - 重试耗尽后 exit 2，触发 escalation
- 失败要分类，不然没法复盘
- Escalation 后不要直接污染知识库：Escalation 后不要直接污染知识库很多团队的知识库会越来越脏，是因为每次失败都直接写成“经验”。更好的方式是先生成 learn draft


Themis失败 draft模板：
```
#Draft：创建商品API的路由漂移

**失败分类**：drift
**失败步骤**：drift-check
**关联Spec**：lattice/specs/create-item-api/spec.md
**证据**：Spec声明了`POST/items`，但代码里没有注册对应路由。
**建议沉淀**：新增GinAPI时，需要同时更新`internal/handler/router.go`的路由注册，并补充对应的验收编号测试覆盖。
**状态**：draft
```



## spec优化

- 追问应该在spec.md生成前通过对话或澄清进行确定，且不应该生成文件（追问应该是独立的agent或skill）
- 移除投影章节，提供review.md模板，降低human review过程的复杂性。
- spec的实际产物除了知识外应该只有：spec.md、plan.md、review.md、verify.md、summary.md
- 检查spec.md中是否有声明对知识库中的Context Basic来源引用

## 处置矩阵

状态含义：

- `already_owned`：正式设计已覆盖，不在本文重复规则正文；
- `adopted`：采纳并写入链接的 owning page；
- `rejected`：与已确认合同冲突，不进入正式设计；
- `deferred`：方向保留，但由既有后续计划实施。

| 原始意见 | 处置 | 唯一归属与结论 |
|---|---|---|
| 移除 Behavior Map | `adopted` | [Context](core/kernel/context.md) 不拥有第二套源码表示；Planning 与 Review 直接核验当前代码并记录 revision/digest。当前模板、适配器占位和运行路径均退役。 |
| 移除 Migration、Upgrade | `adopted` | [Architecture](architecture.md#core-与-workspace) 与 [Workflow](workflow.md#init-与当前更新边界) 规定当前仅支持 fresh Init、固定 schema allow-list 和 unsupported fail closed；未来恢复时重新设计。 |
| 禁止过于复杂的脚本 | `adopted` | [Architecture](architecture.md#执行器职责与位置) 按协议操作和事务边界拆分，不按任意行数拆分。 |
| 分析 Policies 是否必要 | `already_owned` | [Policies](core/policies.md) 继续拥有稳定步骤、阈值、路由、枚举和处置。 |
| 明确自然语言、YAML 与脚本边界 | `already_owned` | [Architecture](architecture.md#三层执行模型) 的 Policy → Prompt → Shell 模型。 |
| 将项目“坑”沉淀为知识 | `already_owned` | [Knowledge](core/kernel/knowledge.md) 的 candidate → governed review → promotion。 |
| 需求澄清、图示降低 Review 复杂度、自主学习 | `adopted` | 澄清与图示归 [Specification](core/kernel/specification.md)；学习必须遵守 [Knowledge](core/kernel/knowledge.md)；前置评审归 [Review](core/kernel/review.md)。 |
| 将明确设计记录到 AGENTS | `rejected` | [Governance](governance.md#设计权威) 规定 AGENTS 只保存协作方式和设计链接。 |
| Prompt 收敛约束应结构化复用 | `adopted` | [Governance](governance.md#知识候选来源与准入) 规定候选来源和准入标准。 |
| Spec Coding 固定团队认可路径 | `already_owned` | [Specification](core/kernel/specification.md#职责边界) 已定义批准范围、需求和验收证据。 |
| CLAUDE/AGENTS、测试、对话、决策表可提供高 ROI 知识 | `adopted` | 只作为 candidate/evidence 来源；是否成为事实仍按 [Governance](governance.md#知识候选来源与准入) 核验。 |
| Context 不是当前实现真相源 | `already_owned` | [Governance](governance.md#项目事实可信模型) 的 Context/当前代码双轴可信模型。 |
| 长期知识应稳定、复用并防止“能跑但不对” | `adopted` | [Governance](governance.md#知识候选来源与准入) 与 [Knowledge](core/kernel/knowledge.md#candidate) 的准入合同。 |
| 任一步失败即停、修复重跑、默认 3 次、耗尽 exit 2 | `adopted` | [Workflow](workflow.md#verification-失败修复循环)、[Orchestrator](core/kernel/orchestrator.md#routing-与-recovery) 和 [Verification](core/kernel/verification.md#失败修复与-escalation) 的目标合同。 |
| 失败必须分类 | `already_owned` | [Verification](core/kernel/verification.md#evidence-与失败分类)。 |
| Escalation 先生成 learn draft，不直接污染知识 | `adopted` | [Knowledge](core/kernel/knowledge.md#verification-escalation)；仅 exhaustion/escalation 可产生 candidate。 |
| 追问不应生成文件 | `rejected` | [Specification](core/kernel/specification.md#spec-双视图) 保留持久 candidate，以支持恢复、验证和事务发布。 |
| 移除 Spec 投影章节 | `rejected` | [Specification](core/kernel/specification.md#spec-双视图) 保留 `spec.yaml` 权威源与 `spec.md` 单向 Human projection。 |
| 提供 `review.md` | `deferred` | [Review](core/kernel/review.md#human-review-投影) 已确认前置 Review 投影合同，等待 P6.8 实施。 |
| 新增 `summary.md` | `adopted` | [Workflow](workflow.md#verified--human-acceptance--summary--archived) 规定仅在 Human Acceptance `accepted` 后确定性生成最终交付投影。 |
| Spec 声明 Context 来源 | `adopted` | [Specification](core/kernel/specification.md#requirement-questioning) 要求记录稳定 Context ID 或证据限制；P5.4 执行器落地后校验 Catalog、digest 与 freshness。 |

## 实施顺序

1. P5.4 Context：在当前 `themis-workspace/v1` 内实现 Catalog、L1/L2/L3、Search、Bundle 与 Signal，不引入 Behavior Map 或 schema 转换。
2. 在 P5.4 之上实现 Spec Context 引用校验和 P5.5 Knowledge Governance。
3. 实现 Planning，并由 P6.8 Review 对 Spec、Plan、设计、风险、scope lock 与验收方案作前置批准。
4. Implementation 只执行 approved Review 绑定的范围。
5. P6.5 Verification 在实现后记录 Gate、失败分类、repair/resume、持久 attempt 和 escalation；`pass` 后进入 Human Acceptance。
6. Acceptance `accepted` 后确定性生成 `summary.md`，再完成 Outcome、Attribution、知识处置和归档。
7. 集成 Verification exhaustion → Knowledge candidate；能力缺失时保留 `candidate_pending`。

协调实施设计见 [P5.7 FEATURE 收敛计划](../plan/57-feature-convergence/impl.md)。
