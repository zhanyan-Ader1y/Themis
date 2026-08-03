# Current Request 与 Dialogue

> 本文件属于 [Plan 35：Core Contract Replacement](../2026-07-31-plan-35-core-contract-replacement-design.md) 的功能 reference，拥有 Current Request claims 和 `themis-current-request-dialogue` 合同。它不是第二份设计权威。稳定 identity 包括 claim、claim revision、Current Request revision、diff item、proposal 和 assignment decision；核心不变量是用户语义必须 source-bound，且语义变化只能经新的 confirmation Source Event 明确确认。

## Claim model

Current Request 是可追溯 requirement claims 的不可变集合，不是对用户原文的无来源摘要。

每条 claim：

- 具有 stable claim identity；
- 内容或结构变化时产生不可变 claim revision；
- 引用一个或多个 Source Event 精确片段；
- disposition 为 `active | ambiguous | superseded`；
- 可显式绑定 `supersedes`、`split-from` 或 `merged-from`；
- 不得把 Agent 分析、Plan、Specification、历史需求或其他推理伪装成用户语义。

## Current Request revision

一个 Current Request revision 是某个 lifecycle 下已确认 claim revisions 的不可变集合，至少绑定：

- lifecycle identity；
- confirmed Intake assignment decision；
- active、ambiguous 和 superseded claim refs；
- Source Event refs；
- previous Current Request revision；
- materialization observation。

current pointer 与 revision 分离。内容或 claim set 改变时创建新 revision，不原地覆盖。

## 需要确认的变化

以下变化必须向用户展示 semantic diff 并获得明确 disposition：

- 新增 claim；
- 改写 claim；
- 废止 claim；
- 标记或解除 ambiguity；
- lifecycle assignment 或 Source Event 片段归属变化。

以下情况不要求额外确认：

- 新消息与现有 confirmed claim 完全匹配；
- 用户回答只补足当前对话，不改变 claim 或 assignment；
- 只记录新的 Source Event 和原 continuation 输入。

用户看到的 diff 只呈现变化项。每项包含：

- stable diff item identity；
- 短原文引用；
- `add | rewrite | supersede | ambiguity | assignment-change`；
- 旧语义与建议新语义；
- 受影响 lifecycle；
- `confirm | correct | keep-ambiguous` disposition。

整体确认绑定当前完整 diff digest。未提及或缺少 disposition 的必需项不能推断为已确认。

## Capability identity

新增并固定第十六个 Capability：

```text
themis-current-request-dialogue
```

它负责：

- 处理每条外部消息的 Intake；
- 比较 Source Event 与已确认 claims；
- 提议 claim diff；
- 提议 lifecycle assignment、split 或 no-change；
- 生成低负担用户 semantic diff；
- 处理新的用户 confirmation Source Event；
- 返回 assignment decision proposal；
- 保留 original dialogue continuation。

它不直接创建 lifecycle、写 Current Request revision、修改 Intake/lifecycle state、执行 route、修改项目实现，或从模糊确认、沉默和聊天历史推断用户决定。

## 固定 Profile 与 scope

```text
agent_profile: human-dialogue
authority_scope: request-intake
selected_path: null
profile: null
```

`human-dialogue` 保持只读。Capability 可返回 proposal 或 confirmed decision result，但只有 Policy control action 和 observed recorder result 可以物化治理记录。

## Invocation input bundle

至少绑定：

- authority scope；
- Intake identity；
- Intake Execution Identity；
- Invocation identity 与 attempt；
- 新 Source Event；
- pending proposal、proposal digest 与 prior confirmation refs；
- 相关 lifecycle 的 current Current Request refs；
- current claim revisions；
- original dialogue continuation；
- Policy identity/digest；
- remaining failure budget；
- allowed reads 和禁止写入声明。

## Legal status：`needs-request-confirmation`

必需输出：

- immutable proposal identity；
- proposal digest；
- stable diff item identities；
- 每项 Source Event fragment refs；
- proposed claim revisions；
- proposed target lifecycle operations；
- 每项允许 disposition；
- 用户可见精简 diff；
- confirmation continuation。

控制操作只持久化 proposal 并等待新的用户 Source Event，不创建或更新 lifecycle。

## Legal status：`assignment-confirmed`

当 diff 非空时，必需绑定：

- pending proposal identity/digest；
- 新 confirmation Source Event；
- 每个必需 diff item 的明确 disposition；
- 完整 diff digest；
- immutable assignment decision proposal；
- 逐 target operations；
- original dialogue continuation。

当 diff 为空时，必需绑定：

- 新 Source Event；
- current confirmed assignment 和 Current Request refs；
- claims/assignment unchanged 的结构化结论；
- `no-change` operation；
- original dialogue continuation。

无变化时不要求用户重复确认。

## Legal status：`rejected`

必需绑定：

- 用户明确拒绝的 Source Event；
- immutable rejection decision proposal；
- 空 lifecycle operations；
- Intake identity。

控制操作持久化 rejection 后将 Intake disposition 标记为 `rejected`。

## 两次 Invocation 确认协议

存在语义变化时必须使用：

```text
Source Event
→ first Current Request Dialogue Invocation
→ needs-request-confirmation
→ persist proposal
→ user confirmation becomes a new Source Event
→ second Current Request Dialogue Invocation
→ assignment-confirmed
→ policy-controlled materialization
```

一个 Invocation 不得跨多轮保留临时 context authority，Global Rule 也不得直接把自然语言“确认”映射为 confirmed。
