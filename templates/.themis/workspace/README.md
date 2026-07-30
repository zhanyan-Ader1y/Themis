# Workspace Package

## Responsibility

Workspace 是项目持有的语义工件、治理记录、执行证据和派生数据边界。Core 保持只读；Workspace 以 lifecycle identity 隔离实际记录，但不实现控制逻辑。

## Directory ownership

| Path | Ownership |
|---|---|
| `manifest.yaml` | 项目标识、显式 commands/Gates、paths、adapters 和受限 policy overrides |
| `context/` | 受治理 Context 输入；不能证明当前代码实现 |
| `changes/<lifecycle-id>/` | Current Request 引用、append-only questioning、统一 Plan、review 与 Approval 引用 |
| `state/<lifecycle-id>/` | current gate、Questioning Pointer、attempt/termination、invalidation、replacement、incomplete operation 与 last proven gate |
| `runs/<lifecycle-id>/` | Capability、Impl 与 Verification invocation metadata |
| `evidence/<lifecycle-id>/` | 实际命令输出、事实证据、coverage、Git observation 与写后核验结果 |
| `outcomes/<lifecycle-id>/` | Human Acceptance 与 Summary |
| `knowledge/` | Failure Learning、Summary 候选和独立治理 disposition |
| `cache/` | 可重建索引、bundle 和 projection；永非 authority |
| `policies/` | 受限制的 project override，不得绕过 global invariants |

## Lifecycle layout

```text
workspace/
├── changes/<lifecycle-id>/
│   ├── questioning.md
│   ├── plan.md
│   ├── review.md
│   └── review-approval.md
├── state/<lifecycle-id>/
├── runs/<lifecycle-id>/
├── evidence/<lifecycle-id>/
└── outcomes/<lifecycle-id>/
```

Current Request Revision 可以由控制面记录在 lifecycle state 中或由引用指向真实用户输入；不得把 Agent 总结写成用户原话。临时 Specification handoff 不持久化到 Workspace。

多个 lifecycle 可以绑定同一只读 Core policy identity/digest，但其 Current Request、continuation、sticky state、Task Execution Identity、worktree identity、attempt、artifact、evidence、Acceptance、Summary、incomplete operation 和 last proven gate 不得交叉。

## Authority and interaction

- Current Request Revision 定义本次交付目标语义。
- 代码、配置、Schema 与实际可执行行为是当前实现事实的唯一来源。
- Plan 是首个持久化执行合同，但始终从属于 Current Request Revision。
- `review.md` 是 checked Plan 的只读压缩投影，不能作为 Impl 输入。
- state/runs/evidence/outcomes 记录流程事实，不改写需求或 Plan 语义。
- record 或目录存在不证明写入完成；只有观察到的 recorder/result 和重读事实可支撑状态声明。

## Write isolation and interruption

- mutating invocation 绑定 lifecycle/task/invocation、exclusive worktree、allowed paths、pre-Impl baseline 与 expected state。
- 并发时一个写入任务独占一个 worktree；宿主不支持时只能串行唯一 writer，不能模拟隔离。
- 每次写入前核验 path containment、bindings、baseline 和 expected state。
- 适用时先完整写同目录临时文件，再原子替换单个目标。
- 关键多步记录使用 completion/incomplete marker；完成声明前重读实际文件、Git status/diff 和记录。
- 中断后从 `state/<lifecycle-id>/` 的实际记录与最后已证明 gate 重新判断；不从部分文件、聊天或 Agent summary 重建完成。
- Workspace 不提供或暗示跨 worktree locks、通用 transactions、rollback journals、automatic recovery、cross-worktree merge 或 conflict adjudication。

## Installation safety

- Fresh Init 前必须在任何写入前拒绝已有 `.themis/` 或冲突受管目标。
- 不支持 Core 原地更新、Workspace Migration、重复 Init 或复制模板覆盖。
- project commands 必须显式配置；`null` 不得被猜成默认命令。

## Current status

manifest、目录 scaffold 和 Prompt-level ownership/write-safety contracts 存在。没有 installer、Workspace validator、state recorder、atomic writer、Gate runner 或 executable contract suite；目录和文本合同不代表机器能力已经执行。
