# Themis 安装包合同

本目录定义 future fresh Init 安装到项目 `.themis/` 的 Core 与 Workspace 基线。当前 checkout 提供一个公共 Skill、Prompt-level Global Rule、十五个内部 Capability、四个固定 Agent Profile、声明式路由、工件模板与目录 scaffold；不提供生产 installer、严格 validator 或确定性运行时。

## 产品主链

安装包共同强化：详细细化前的需求追问、低负担 Plan Review、可沉淀的 Agent Plan，以及受治理、持续进化的项目知识库。

```text
Current Request
→ Questioning
→ Complexity Assessment
   ├─ simple → Simple Plan → Lightweight Plan Check
   └─ full   → temporary Specification → Planning → Full Plan Check
→ Review Projection → Review Check → Human Review → Review Approval
→ Verify [Impl → independent Verification]
→ Human Acceptance
→ Summary
→ optional governed knowledge candidates
```

快速与完整路径只在统一 Plan 形成前不同。Review 始终位于项目实现前；Summary 只在 current Verification `passed` 且 Human Acceptance `accepted` 后生成。

## 控制架构

```text
public themis Skill
→ Global Control Rule
→ transitions.yaml selects one internal Capability
→ fixed Agent Profile
→ one temporary Agent invocation
→ validate Capability Invocation Result
→ match exactly one route
→ execute declared generic action/invalidation/next
```

- [`../.claude/skills/themis/SKILL.md`](../.claude/skills/themis/SKILL.md) 是 Claude Code 环境中唯一公共 Themis 入口，不拥有领域语义或全局路由。
- [`core/kernel/orchestrator/rules.md`](core/kernel/orchestrator/rules.md) 是唯一常驻生命周期 Rule，只作为通用 policy interpreter 和 coordinator。
- [`core/policies/transitions.yaml`](core/policies/transitions.yaml) 是合法状态路由、固定 Profile 映射、guards 与 invalid-result 行为的唯一声明源。
- [`core/capabilities`](core/capabilities/README.md) 中十五个不可直接发现的内部 Capability 分别拥有语义判断。
- [`core/agent-profiles`](core/agent-profiles/README.md) 中四个 Profile 只约束权限与隔离；一次临时 Agent invocation 只执行一个 Capability。
- Capability 和 Agent 不得互相调度；不存在持久 Agent、共享记忆、投票或共识。

## 权威模型

- Current Request Revision 是当前交付目标语义源。
- 受治理设计约束只限制可接受方案，不重写 Current Request，也不证明当前实现事实。
- 代码、配置、Schema 和实际观察到的可执行行为是当前实现事实的唯一来源。
- Specification 只是在完整路径中的临时非权威 handoff，不生成持久 `spec.yaml` 或 `spec.md`。
- 通过对应 profile 检查并经人工整体批准的统一 Plan 是执行合同。
- `review.md` 是 checked Plan 的只读压缩投影，不是实现输入。
- Context、Themico、经验、设计文档、Plan、Summary、Agent 分析和对话记忆不能替代当前实现证据。

## 包结构

| Package | 合同 |
|---|---|
| [`core/kernel/orchestrator`](core/kernel/orchestrator/README.md) | 唯一 Global Control Rule、调用边界与通用控制动作 |
| [`core/capabilities`](core/capabilities/README.md) | 十五个内部语义判断合同 |
| [`core/agent-profiles`](core/agent-profiles/README.md) | 四个固定权限与隔离合同 |
| [`core/kernel/context`](core/kernel/context/README.md) | 当前实现事实 Grounding 与 Context 权威边界 |
| [`core/kernel/specification`](core/kernel/specification/README.md) | 完整路径临时需求细化 handoff |
| [`core/kernel/planning`](core/kernel/planning/README.md) | Simple Plan、完整 Planning 与 profile-specific Plan Check |
| [`core/kernel/review`](core/kernel/review/README.md) | Projection、Projection Check、Dialogue 与独立 Approval |
| [`core/kernel/implementation`](core/kernel/implementation/README.md) | 批准范围内的 bounded Impl 与实际 delta |
| [`core/kernel/verification`](core/kernel/verification/README.md) | 独立只读验证、直接 evidence 与 verdict |
| [`core/kernel/knowledge`](core/kernel/knowledge/README.md) | Failure Learning、Summary candidate 与独立治理 |
| [`core/kernel/attribution`](core/kernel/attribution/README.md) | 可选 post-delivery observer；Plan 90 边界 |
| [`core/policies`](core/policies/README.md) | 唯一 Prompt-level 路由政策 |
| [`core/protocols`](core/protocols/README.md) | 当前结构边界与 Plan 36 严格协议责任 |
| [`core/templates`](core/templates/README.md) | 语义工件、投影、治理记录和证据记录模板 |
| [`workspace`](workspace/README.md) | 项目持有的 lifecycle-scoped 记录、Context、证据、结果和候选 |

## Workspace 归属

```text
workspace/changes/<lifecycle-id>/   Request、Questioning、Plan、Review、Approval
workspace/state/<lifecycle-id>/     current gate、pointer、attempt、invalidation、incomplete operation
workspace/runs/<lifecycle-id>/      Capability/Impl/Verification invocation metadata
workspace/evidence/<lifecycle-id>/  direct facts、commands、outputs、coverage
workspace/outcomes/<lifecycle-id>/  Human Acceptance、Summary
workspace/knowledge/                candidates、review、decision、disposition
```

临时 Specification 不持久化。多个 lifecycle 可以绑定同一只读 policy identity/digest，但动态状态、worktree identity、continuation、attempt、artifact、evidence 和 outcome 不得跨 lifecycle。

## 写入与中断边界

- mutating invocation 绑定 lifecycle、Task Execution、Invocation、worktree、allowed paths、pre-Impl baseline 与 expected state。
- 并发写入必须使用独占 worktree；不具备该能力时只允许串行唯一 writer，否则 fail closed。
- 写前核验路径、bindings、baseline 和 expected state；适用时完整写同目录临时文件后原子替换单个目标。
- 关键多步写入使用 completion/incomplete marker；完成前重读实际文件、Git status/diff 和记录。
- 中断后只从最后已证明 gate 继续，不根据部分文件猜测成功。
- 不声明跨 worktree 锁、通用事务、rollback journal、自动恢复、跨 worktree 合并或冲突自动裁决。

## 关键门禁

- 未获得 `simple-qualified` 且 `full_path_required = false`，不得选择快速路径。
- 快速路径发现隐藏复杂度时执行单向粘性升级，完整重走 Specification、Planning 与 Review。
- 未通过当前 Plan Check 和 Review Approval，不得执行 Impl。
- Impl 不拥有 Verification verdict；Verification 缺少直接证据不得 `passed`。
- Impl 与 Verification 共享一个 Plan task identity 和累计三次失败预算。
- 未 `passed` 不得 Acceptance；未 `accepted` 不得 Summary。
- Failure Learning 与 Summary 只能提出候选，不能自动发布为正式知识。
- Attribution 与 Multi-Agent 不能成为 Plan 35 核心门禁。

## 不变量

- Core 管理控制合同，不保存项目当前实现事实；Workspace 保存项目拥有的记录与引用，不实现控制逻辑。
- 每个模块只有唯一当前合同，不使用功能性版本目录或 `v1`、`v2`、`v3` 标识。
- Upgrade、Migration、Behavior Map 与 Shell runtime 不得通过 Adapter、fallback 或重命名资产隐式恢复。
- 不得覆盖现有 `.themis`；fresh template 不构成升级机制。
- 未观察到实际 evaluator、validator、recorder、runtime 或写入结果时，不得声称机器 transition、digest、currentness、persistence、atomic replacement、completion 或 recorded-state resume 已执行。

## 当前实现状态

Plan 35 当前提供一个公共 `themis` Skill、Global Control Rule、十五个内部 Capability、四个 Agent Profile、91 条唯一合法 route、Prompt-level worktree/write-safety 边界、模块合同和人工 replay 语义。严格 Schema、validator、canonicalization、digest/currentness 与 fixtures 属于 Plan 36；policy evaluation、临时 invocation、per-lifecycle recorder 与最小 fail-closed 写入安全属于 Plan 37；多 Agent 协作属于 Plan 80；Attribution automation 属于 Plan 90。
