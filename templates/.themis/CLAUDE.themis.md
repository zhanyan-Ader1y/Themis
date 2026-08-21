# Themis 项目指南

本托管指南定义安装后项目的控制边界。`.claude/skills/themis/SKILL.md` 是唯一公共项目 Skill。

## 安装边界

- `.themis/workspace/` 归项目所有，用于保存 Intake/lifecycle 记录、Context、evidence、outcomes 与 knowledge governance。
- 已存在的 `.themis/` 必须逐字节保留。fresh template 不是 upgrade、migration 或 compatibility 机制。
- 只有 installer 或 runtime operation 确实存在且结果可观察时才能使用。不得通过编辑 guidance 隐藏冲突。

## Intake-first 入口

每条外部用户消息必须先成为 `request-intake` 下的 immutable Source Event，并保留 original bytes 与精确 fragment references。这包括新请求、Questioning 回答、Review feedback/approval、Acceptance 以及 restart/unblock 消息。

只有匹配 active durable Intake-local confirmation 或 restart/unblock continuation 时，才能把 Source Event 附加到已有 Intake。`dormant-read-only` Intake 永远不可附加。措辞、相邻消息、聊天历史、open Intake 或 Agent 推断都不能选择 attachment；不满足条件时必须创建新 Intake。

```text
Source Event
→ themis-current-request-dialogue
   ├─ needs-request-confirmation → persist proposal and await a new Source Event
   ├─ rejected → persist explicit rejection
   └─ assignment-confirmed → materialize decision and declared targets
→ create/update source-bound Current Request revisions
→ resume the exact decision-bound lifecycle continuation
```

confirmed assignment 完整物化并重读前，不得创建、定位、更新、拆分、合并或继续任何 lifecycle。

## 权威模型

- Source Event original bytes 拥有外部输入权威。
- user-confirmed source-bound claim revisions 拥有 lifecycle target 语义权威。
- governed design constraints 约束解决方案，但不能改写 claims 或证明 implementation。
- code、configuration、Schema 与 observed executable behavior 是 current implementation facts 的唯一来源。
- temporary Specification 是 full-path handoff，不具有 persistent artifact/current pointer。
- current checked 且 explicitly approved 的 unified Plan 是执行合同。
- Review Projection 是 checked Plan 的绑定只读视图，不是 execution input。
- Context、Themico、experience、documentation、Plans、summaries、Agent inference、conversation memory 和文件存在都不能替代直接 implementation evidence 或 observed materialization。

来源冲突时，保留冲突并返回 semantic owner。缺失 evidence 永远不等于成功。

## Scope 与 Artifact 隔离

`request-intake` 与 `lifecycle` 只能交换 immutable stable references。二者不能共享 dynamic state、Execution Identity、failure budget、continuation authority、current pointer 或 completion state。

logical artifact 使用 immutable revision 与独立 current pointer。paired semantic artifact 要求匹配的 Markdown 控制 `record.md` 与 governed `content.md`；任一组件缺失或不匹配都会使整个 revision invalid。completed Questioning exchange 使用 per-round immutable pair，未回答问题保留在 proposal/continuation state 中。

lifecycle state 只保存最小控制事实与 references，不复制 claim、Plan、Review、Acceptance 或 Summary prose。

## Review、Verify、Acceptance 与 Summary

- Review Projection 按从抽象到具体的顺序呈现高影响内容，只在降低理解负担时使用图形。
- Review Dialogue 提出 immutable Feedback 或 Approval，不直接修改 Plan/Projection。
- Approval 绑定 checked Plan、实际展示的 projection、user decision Source Event、由已重读 resolution 与 unresolved-set update observations 证明为空的 unresolved-feedback set，以及 pre-Impl baseline。
- Impl 记录实际 approved delta，不能给出 Verification verdict。
- independent Verification 绑定 exact implementation result 以及直接 commands/observations/evidence。
- Impl 与 Verification 使用不同 Invocation。
- Human Acceptance 在 Verification passed 后记录 source-bound user observation。Summary 是 Acceptance accepted 后的绑定 delivery projection。

## 安全降级

Plan 35 提供 Prompt/template/policy contracts、static checks 与 manual replay semantics。Plan 36 拥有 strict Schema、canonical serialization、validation、issue taxonomy、semantic oracle 与 fixtures。Plan 37 拥有 native policy evaluation、Invocation hosting、recording、digest/write services 与 command execution。

如果 evaluator、recorder、validator、digest service、command runner、installer 或 deterministic writer 不可用，则停留在 current proven gate 并明确缺失的 assurance。不得虚构 Source Events、artifacts、evidence、digests、currentness、transitions、attempts、invalidations、termination、recovery、atomicity 或 completion。

## 关键路径

| 用途 | 安装路径 |
|---|---|
| 公共入口 | `.claude/skills/themis/SKILL.md` |
| 项目配置 | `.themis/workspace/project.md` |
| Request Intake records | `.themis/workspace/intakes/<intake-id>/` |
| lifecycle semantic revisions | `.themis/workspace/changes/<lifecycle-id>/` |
| lifecycle state 与 pointers | `.themis/workspace/state/<lifecycle-id>/` |
| Invocations 与 evidence | `.themis/workspace/runs/<lifecycle-id>/`、`.themis/workspace/evidence/<lifecycle-id>/` |
| Acceptance 与 Summary | `.themis/workspace/outcomes/<lifecycle-id>/` |
| scope-separated knowledge candidates | `.themis/workspace/knowledge/intakes/`、`.themis/workspace/knowledge/lifecycles/` |

Multi-Agent execution 与 Attribution analytics 保持 optional future concerns，永远不是 Plan 35 gate。
