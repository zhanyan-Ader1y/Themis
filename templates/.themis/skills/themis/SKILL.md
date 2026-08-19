---
name: themis
description: 唯一公共 Themis 入口；接收任意新消息或续接消息，按 `.themis/spec/` 的流程契约推进 spec 流程——定位当前节点，加载对应的判据与产物模板，不做机器强制，不复述判定内容。
---

# themis

## 公共入口职责

本 Skill 是唯一公共 `themis` 入口。每条外部用户消息先成为不可变来源，进入 Intake，不得跳过 Intake 直接进入设计或实现节点；Intake 节点的产出与失效范围见 `.themis/spec/flow.md`。

本入口不做流程判定——某节点是否收敛、评审是否通过、验证是否通过，这些判据全部在 `.themis/spec/rules.md`，本入口无权代为下结论。本入口只负责：定位当前 spec 实例所处的节点，加载该节点对应的流程契约、判据与产物模板，把控制权交给 Agent 按契约执行。

## 加载链

```text
SKILL.md
  → .themis/spec/README.md（索引，确认当前强制水平）
  → .themis/spec/flow.md（定位当前节点，判它现在能不能走到下一步）
  → .themis/spec/rules.md 中该节点对应的小节（这一步怎么判过不过）
  → .themis/spec/template.md（要产出或更新哪些文件、哪些小节）
```

四份文件职责互不渗透：`flow.md` 只答现在能不能走到下一步，`rules.md` 只答这一步怎么判过不过，`template.md` 只答产物长什么样、放在哪，`README.md` 只答去哪找上面三个；任何一份都不得越界承担另一份的职责。

## 中断与恢复

中断后只从实例 `state.md` 记录的当前节点与各闸门结论恢复到 last proven gate；不从 chat、摘要、Agent 自述或文件存在推断已完成节点。恢复依据的通用规则见 `.themis/spec/flow.md`（"通用失败去向"一节），`state.md` 的字段结构见 `.themis/spec/template.md`。

## Review 与 Impl 的顺序

Review 必须在对应的 Impl 之前完成并取得批准结论，Impl 不得在未批准前开始。具体的节点顺序、每处人工评审的前置闸门与失败去向见 `.themis/spec/flow.md`。

## 当前强制水平

当前为 **soft 执行器**：机器强制 unavailable，validator、evaluator、recorder、digest 均未实现，闸门靠 Agent 遵守，状态记录在实例的 `state.md`。任何文本不得声称 `.themis/spec/` 流程的闸门已由机器执行。
