# Skill 与 reference 加载合同

## 1. 主题责任

本文定义公共 `themico` Skill 如何选择 operation reference 和 registry-selected type factory。具体 CLI 字段、类型 payload 与治理规则由对应主题 reference 负责，Skill 不复制或重新定义这些权威合同。

## 2. 单一公共 Skill

当前核心只有一个公共 Skill，名称固定为 `themico`。它负责：

- 查询和渐进读取 Themico 正式知识；
- 形成、修订和审阅知识 candidate；
- 组织类型确认、semantic assessment 和 Human Review；
- 调用 CLI prepare 与经授权的 lifecycle operation；
- 解释 CLI fact trace 和知识语义。

不得为三个知识类型创建三个公共 Skill，也不得让 operation reference 变成独立的宿主路由入口。`SKILL.md` 只保留 Claude Code 宿主发现所需的最小 frontmatter；流程和语义合同使用中文 Markdown。

## 3. 固定加载顺序

一次操作的加载顺序固定为：

```text
common/operation-contract
→ exactly one selected operation reference
→ CLI inspect/query 返回 persisted type，或读取新 candidate 的 proposed type
→ common/type-registry
→ exactly one registry-selected type factory
→ selected L2/L3/semantic-check reference
→ Agent proposal 或 assessment
→ CLI deterministic validate/prepare/apply
```

一次操作只选择一个 operation reference。只有当操作需要理解或生成特定类型内容时，才继续加载 type factory；不能默认加载三个 factory 后让 Agent自由选择正式记录类型。

## 4. operation reference

每个 operation reference 只负责一个操作，并明确：

- 输入与前置条件；
- Agent 职责；
- 对应 `themico` CLI command；
- Human gate；
- 权威输出；
- 合法 machine status；
- fail-closed 行为。

operation reference 不复制三种类型的完整 L2/L3 合同，也不定义新的 Zone、类型、状态或关系。若 operation 与 CLI command 不可用，reference 必须要求 draft-only 降级，不能指导 Agent 手工改写 `.themico`。

## 5. type registry

common type registry 是 Skill 的类型路由说明，必须与 CLI registry 闭集一致：

| `knowledge_type` | factory | Zone |
| --- | --- | --- |
| `design_decision` | `types/design-decision/factory.md` | `project_knowledge` |
| `development_standard` | `types/development-standard/factory.md` | `project_knowledge` |
| `development_experience` | `types/development-experience/factory.md` | `project_experience` |

registry 不支持目录自动发现、插件式类型扩展或标题关键词猜测。未知类型必须失败关闭。

## 6. factory 选择

### 6.1 已有正式记录

已有正式记录的 factory 只能这样选择：

1. 使用 CLI query 或 inspect 获得 record ID、revision 和已固化 `knowledge_type`；
2. 在 common registry 中查找唯一 factory；
3. 只加载该 factory 及其 L2、L3、semantic-check reference；
4. 若 type 未注册、缺失或与 Zone 不兼容，停止并报告机器合同问题。

禁止根据 title、summary、tags、L2 payload 或 L3 正文重新解释类型。即使标题写着“一次失败经验”，persisted type 为 `design_decision` 时也只能选择 design-decision factory，并由校验流程暴露内容错配。

### 6.2 新 candidate

新 candidate 尚无固化类型时，Agent 可以依据三个 factory 的分类摘要提出一个 `proposed_type` 和分类理由。Human 确认后，后续处理只能使用 CLI 返回的固化 `knowledge_type`。Human 拒绝或要求改变类型时，应在固化前修订 proposal；固化后改变类型必须创建派生 candidate。

## 7. type factory 内容

每个 type factory 必须固定说明：

- type identity；
- 唯一 Zone；
- 适用与不适用分类依据；
- L2 reference 路径；
- L3 reference 路径；
- semantic-check reference 路径。

L2 reference 指导生成与审阅类型化 payload；L3 reference 指导固定 Markdown 章节；semantic-check reference 指导 Agent 形成 assessment candidate。semantic check 不能授予 publication authority，也不能绕过 Human Approval。

## 8. CLI 与 Skill 权威关系

- Skill 负责语义工作流和解释；
- CLI 负责持久化类型、结构校验、身份、digest、source binding、currentness、预算、提交与 trace；
- Skill 输出的 proposal、assessment 和 explanation 都是非权威候选；
- CLI 输出的 succeeded 只证明对应机器操作成功，不证明自然语言内容正确；
- Human Approval 只对其精确绑定的 prepare 生效。

CLI unavailable、registry 不可读或 type binding 不明确时，Skill 只能生成不持久化 draft，并明确不能声称 current、published 或 valid。

## 9. 禁止的加载与写入方式

禁止：

- 同时加载全部 operation reference 并混合多个操作；
- 为已有记录加载多个 factory 后由 Agent投票选类型；
- 依据目录名自动注册新类型；
- 让 type factory 直接写 record 或 current pointer；
- 使用 Python、Shell、PowerShell、`jq`、`yq` 或手工 JSON 替代 CLI operation；
- 在 MCP adapter 或 Themis lifecycle 尚未另行设计时声称已经接线。
