# 公共入口与控制

> 本文件属于 [Plan 35：Core Contract Replacement](../2026-07-31-plan-35-core-contract-replacement-design.md) 的功能 reference，拥有唯一公共 Skill、Global Rule 和单一自然语言 Policy 的跨模块合同。它不是第二份设计权威。稳定入口为 `.claude/skills/themis/SKILL.md`、唯一 Global Rule 和 `templates/.themis/core/policies/README.md` Policy package；核心不变量是 one public entry、one control owner、one Policy，且不得从自由文本猜测 route 或 persistence。

## 唯一公共 Skill

fresh template 恰好注册一个公共入口：

```text
.claude/skills/themis/SKILL.md
```

它只负责：

- 接收外部消息并确保 Source Event 被记录；
- 加载 Global Rule、current Policy reference、一个 Capability 及固定 Profile；
- 运输用户回答和 Capability result；
- 请求从 durable facts 恢复中断流程。

它不拥有 claims、lifecycle assignment、Capability 语义、route lookup、persistence/currentness、Approval、failure count、invalidation、Verification、Acceptance 或 Summary 判断。

## Global Rule

Global Rule 是唯一常驻控制说明，只执行通用控制：

1. 读取 current scope、identity、Policy、current refs 和 continuation；
2. 验证进入 Invocation 的前置 bindings；
3. 选择 Policy 指定的一个 Capability 和 fixed Profile；
4. 创建一次性 Invocation；
5. 验证 proposed result 的 identity、scope、Profile、status 和 bindings；
6. 在当前自然语言 Policy reference 中匹配且只匹配一个合法控制规则；
7. 请求规则声明的 control action；
8. 根据 observed recorder result 更新 current refs 或 gate；
9. 任一缺失、歧义、stale 或 unsupported 情况 fail closed。

Global Rule 不：

- 内嵌十六个 Capability 的推理方法；
- 维护第二份 legal status 或 route 规则；
- 解析 `recommended_route` 覆盖 Policy；
- 从自然语言猜测用户确认、lifecycle state 或恢复点；
- 声称未观察到的 persistence。

## 单一自然语言 Policy

`templates/.themis/core/policies/README.md` 是唯一 Policy entry，其 `references/` 只是同一个 Policy 的按主题分片，不形成多个 Policy。

Policy 合同必须共同声明：

- `request-intake` 与 `lifecycle` authority scopes；
- 十六个 Capability stable identities；
- 十六个 Capability 的 fixed Profile；
- 每个 Capability 的 legal scope 和 required identity bindings；
- closed vocabularies；
- 合法 control rules；
- materialization actions；
- invalidation；
- failure classes；
- guards 和 guard-failure actions；
- dynamic continuation invariants；
- recovery 与 assurance boundary。

不得建立第二份 Intake Policy，也不得由 Global Rule 硬编码 Intake 或 lifecycle 状态。

## 控制规则定位

自然语言控制规则继续通过以下四项定位：

```text
capability + selected_path + profile + status
```

`authority_scope` 不作为第五维度。每个 Capability 的 legal scope 由 Capability contract 和 Policy 唯一约束。

`themis-failure-learning` 可运行于两个 scope，但只使用统一 semantic rule；control action 必须读取 Invocation 中已验证的 `authority_scope` 和 scope-local continuation，不得跨 scope 修改动态状态。

98 是旧 YAML 表示中合法结果组合的迁移覆盖观察值，不是产品 identity、固定 Markdown 行数、可解析 DSL 或 runtime 常量。

## Current Request Dialogue 控制语义

当 `themis-current-request-dialogue` 返回 `needs-request-confirmation` 时，Policy 只允许持久化 Intake proposal 并进入 human request confirmation；不能创建或更新 lifecycle。

当它返回 `assignment-confirmed` 时，Policy 必须验证 confirmed decision 与逐 target operations，完整物化 assignment，再只使用 decision-bound continuations 创建或更新 lifecycle。

当它返回 `rejected` 时，Policy 必须持久化 rejection 并关闭 Intake，不能创建 lifecycle assignment。

`decision-bound-continuations` 只能来自 confirmed decision 中逐 target 绑定的 continuation，不能由 Agent prose 或 Global Rule 自行决定。

## 自然语言规则完整性

每个控制决定必须用完整中文句子明确：

1. 合法 Capability status；
2. current bindings、guard 和 durable facts；
3. 需要物化或记录的对象；
4. 成功后的 Capability、Human Dialogue 或 gate；
5. guard failure 的 action 和 next；
6. 失效的 authority、pointer 或 gate；
7. `none | non-counted | counted` failure class；
8. 必须停止且不得从自由文本猜测路由的情况。

Policy 不使用固定 Markdown route table、JSON/YAML 片段、可解析行格式、Markdown DSL 或 parser 指令。

## 表示与执行边界

当前自然语言 Policy 只是 Prompt-level 产品合同。Plan 35 不提供 Go parser、evaluator、validator、recorder 或 deterministic write runtime。缺少 observed Plan 36/37 support 时，不得声称规则已被机器执行。
