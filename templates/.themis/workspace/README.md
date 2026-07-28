# Workspace Package

## Responsibility

Workspace 是项目持有的事实、语义工件、流程记录和派生数据边界。它让 Spec、Plan、evidence、Acceptance 和 Knowledge 在会话之间可恢复，同时把 Core 控制逻辑保持为只读。

## Directory ownership

| Path | Ownership |
|---|---|
| `manifest.yaml` | 项目标识、显式 commands/Gates、paths、adapters 和允许的 policy overrides |
| `context/` | 唯一正式项目知识和 Catalog |
| `specs/` | Spec、Plan、Review、Implementation/Delivery 关联工件 |
| `state/` | lifecycle、cursor、locks、transactions、Signals 等 machine/process records |
| `runs/` | Verification attempts 和 run metadata |
| `evidence/` | command outputs、references 和 coverage evidence |
| `outcomes/` | delivery outcomes 和可选 analysis |
| `knowledge/` | candidate、review、human decision 和 disposition records |
| `cache/` | 可重建 candidate/index/bundle/projection 数据；永非 authority |
| `policies/` | 受限制的 project override，不得绕过 global invariants |

## Authority and interaction

- `context/` 表达项目应当表达的事实；当前代码、配置和 Schema 表达现在实现的事实。
- `specs/` 表达批准的期望变化和工作组织，不证明代码已实现。
- `state/runs/evidence/outcomes` 记录流程事实，不替代 Context 或 Spec semantics。
- Core 正常运行时只读，Workspace 不实现控制逻辑。

## Safety boundaries

- Fresh Init 前必须在任何写入前拒绝已有 `.themis/` 或冲突受管目标。
- 不支持 Core 原地更新、Workspace/Artifact Migration 或重复 Init workaround。
- project commands 必须结构化配置；`null` 不得被猜成默认命令。
- path containment、locks、transactions、rollback 和 recovery 在 runtime 完成前不可声称存在。

## Current status

manifest 与目录 scaffold 存在，部分 Context Catalog/overview templates 存在。没有 installer、Workspace validator、state recorder、transaction manager、Gate runner 或 executable tests；目录存在不代表 lifecycle 能力可用。
