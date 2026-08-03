# 权威模型

> 本文件属于 [Plan 35：Core Contract Replacement](../2026-07-31-plan-35-core-contract-replacement-design.md) 的功能 reference，拥有背景、目标、设计边界和核心权威模型。它不是第二份设计权威。稳定 identity 包括 `request-intake`、`lifecycle`、Source Event、Current Request、Capability、Policy、Global Rule 和 recorder observation；核心不变量是两个 scope 动态隔离，且 proposed result 只有完整物化并重读后才可能成为 authority。

## 背景

原 Plan 35 建立了 Prompt-first 双路径生命周期、十五个内部 Capability、四个 Agent Profile、唯一公共 `themis` Skill、单一 Policy、Review-before-Impl、`Impl → independent Verification`、Human Acceptance、Summary 和三次失败预算。

设计 Plan 36 strict assurance 时发现，原模型没有完整定义：

- 外部用户消息在 lifecycle 归属前的来源权威；
- Current Request 如何从用户原文形成、确认、修正、分流和追溯；
- Capability result 与持久记录何时获得 authority；
- artifact revision、execution attempt、current pointer 和 incomplete operation 的关系；
- 对话确认如何跨一次性 Invocation 持久续接；
- Intake 失败预算如何与 lifecycle task budget 隔离。

这些是 Plan 35 产品语义，不由 Plan 36 validator 决定。replacement 设计直接替换旧合同，不提供 compatibility、upgrade 或 runtime migration。

## 目标

Plan 35 固定以下产品合同：

1. 每条外部消息先成为不可变 Request Intake Source Event；
2. 用户来源语义以可追溯 requirement claims 表达；
3. claim 变化和 lifecycle assignment 在进入 lifecycle 前获得用户明确确认；
4. 一个公共入口、一个 Global Rule 和一个自然语言 Policy package 同时治理 Intake 与 lifecycle，但不共享动态 authority；
5. 原十五个 Capability 保持职责边界，新增 `themis-current-request-dialogue`，总数固定为十六个；
6. 四个 Agent Profile 保持不变，任何 Profile 都不直接拥有 Workspace 治理记录的持久化权威；
7. paired semantic artifact 由同一不可变 revision 内的 `record.md` 与 `content.md` 共同构成；
8. Capability Invocation Result 永远只是 proposal，必须经 Policy control、完整持久化和重读后才能物化为 authority；
9. Intake 与 lifecycle 分别拥有失败预算、continuation 和恢复边界；
10. Review、Approval、Impl、Verification、Acceptance 与 Summary 不可互相替代。

## 设计边界

Plan 35 定义：

- stable contract identity；
- authority owner 与 authority scope；
- 输入、输出和必要 bindings；
- closed semantic status；
- Markdown representation requirement；
- lifecycle、currentness、invalidation、failure 和 materialization invariant；
- Prompt、template 和 Policy 层应表达的合同；
- 静态观察与人工 replay 的验收范围。

Plan 35 不选择或实现：

- Go module、runtime 或 CLI；
- strict Schema、canonical serialization 或 digest 算法；
- validator、semantic oracle 或 fixture runner；
- 文件系统原子替换的具体平台机制；
- lock、transaction、rollback 或 automatic recovery；
- multi-Agent execution；
- Attribution analytics；
- installer、upgrade、runtime migration 或兼容层。

Plan 36 才拥有 strict Schema、canonicalization、validator 和 accepted/rejected fixtures；Plan 37 才拥有 native runtime、recorder、write safety 和 command execution。

## 单 Policy、双 authority scope

```text
用户消息
→ immutable Request Intake Source Event
→ themis-current-request-dialogue
→ 自然语言 Policy 选择唯一合法 control action
→ recorder 完整持久化并重读
→ confirmed assignment 创建或更新 lifecycle
→ lifecycle Capability flow
```

固定 scope：

- `request-intake`：管理 Source Event、claim/assignment proposal、用户确认、assignment decision、Intake execution 和 scope-local continuation；
- `lifecycle`：管理 Current Request、Questioning、Assessment、Plan、Review、Approval、Impl、Verification、Acceptance、Summary、Task Execution 和 lifecycle continuation。

两个 scope 只能通过 stable immutable references 关联，不得共享 dynamic state、Execution Identity、attempt budget、continuation authority、current pointer 或 completion status。

## Authority owner

- **Source Event**：用户原始输入的永久来源权威；
- **Current Request claims**：经用户确认后，对目标语义的 lifecycle 权威；
- **Capability**：拥有本领域语义判断，只返回 proposed result；
- **Agent Profile**：拥有工具、读取、实现写入和隔离边界；
- **自然语言 Policy package**：唯一 route、control action、failure class、guard 和 invalidation policy；
- **Global Rule**：解释 Policy，并协调 Invocation、result validation、control action 和 observed result；
- **Recorder observed result**：证明 record 或 artifact 已完整持久化并被重读；
- **Lifecycle state**：只保存 current refs、gate 和控制事实，不复制业务或设计语义。

## Authority 成立条件

Capability Invocation Result 永远不是持久 authority。只有经过完整链路，record 或 artifact 才能成为 current：

```text
validate proposed result and bindings
→ match exactly one natural-language Policy rule
→ execute the declared control action
→ persist every required component
→ record completion or incomplete observation
→ reread record and content
→ verify identity, digest and bindings
→ create immutable revision observation
→ update separate current pointer
```

缺少任一步骤时：

- 不推进 gate；
- 不声称 persistence；
- 不从 prose、文件存在或 Agent summary 推断成功；
- 保持或返回 last proven gate。

## 表示修订

2026-07-31 已接受的是上述产品语义。2026-08-01 Markdown-first amendment 只改变表示：

- `templates/.themis/core/policies/README.md` 与其 references 共同构成唯一自然语言 Policy；
- 不需要 Go CLI 执行的语义合同不使用 YAML；
- paired artifact 使用 `record.md + content.md`；
- structured record 使用自然语言 Markdown 字段表和枚举；
- 当前没有 Go parser、validator、recorder 或 runtime，不得声称 machine enforcement。
