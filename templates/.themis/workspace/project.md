# 项目配置

## 使用边界

不保留旧 `workspace_schema` 与 `artifact_schema` 作为机器 Schema identity。空值统一写为 `未配置`。当前没有已批准并实现的 Themis Go CLI 解析此文件，因此它是 Prompt-level Markdown 配置模板，不证明命令、路径、adapter 或 override 可执行。

## 项目

| 配置项 | 值 | 说明 |
|---|---|---|
| `project.name` | 未配置 | 项目显示名称 |
| `project.root` | `.` | 相对于 `.themis` 安装所在项目的根目录 |

## 命令

| 配置项 | 值 |
|---|---|
| `commands.lint` | 未配置 |
| `commands.build` | 未配置 |
| `commands.test` | 未配置 |

命令只有在项目明确填写且实际执行入口存在时才可调用；不得猜测或用占位文本执行。

## Context 来源

| 配置项 | 值 | 边界 |
|---|---|---|
| `context.entry_points` | 未配置 | 显式 Context 入口列表 |
| `context.external_sources` | 未配置 | 显式外部来源列表 |

Context 只提供受治理的经验、背景、约束或核验线索，不能证明当前实现事实或拥有 lifecycle state。

## Gates、Adapters 与 Policy overrides

| 配置项 | 值 | 边界 |
|---|---|---|
| `gates` | 未配置 | 只允许项目显式声明的 Gate |
| `adapters` | 未配置 | 只允许项目显式声明的 adapter 与凭据边界 |
| `policy_overrides` | 未配置 | restricted override；不得绕过 Global Rule、authority scope、currentness、Approval 或失败预算不变量 |

## Workspace 路径

以下路径都相对于 `.themis` 安装根：

| 配置项 | 路径 |
|---|---|
| `paths.policies` | `workspace/policies` |
| `paths.context` | `workspace/context` |
| `paths.intakes` | `workspace/intakes` |
| `paths.changes` | `workspace/changes` |
| `paths.state` | `workspace/state` |
| `paths.runs` | `workspace/runs` |
| `paths.evidence` | `workspace/evidence` |
| `paths.outcomes` | `workspace/outcomes` |
| `paths.knowledge` | `workspace/knowledge` |
| `paths.cache` | `workspace/cache` |

路径声明不等于目录、内容、current pointer 或 runtime 已存在。Fresh scaffold、写入与恢复仍受 [Workspace 合同](README.md) 约束。
