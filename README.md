<h1 align="center">Themis</h1>

<p align="center">
  <strong>面向团队的 repo-local 规范驱动 AI Coding Harness</strong>
</p>

<p align="center">
  <a href="#quick-start">快速开始</a> ·
  <a href="#usage">使用指南</a> ·
  <a href="docs/design/">设计规范</a> ·
  <a href="docs/">文档</a> ·
  <a href="CHANGES.md">更新日志</a>
</p>

<p align="center">
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
  <a href="docs/design/runtime-environment.md"><img alt="Bash 3.2 or newer" src="https://img.shields.io/badge/Bash-3.2%2B-4EAA25?logo=gnu-bash&logoColor=white"></a>
  <a href="docs/design/runtime-environment.md"><img alt="Git 2.0 or newer" src="https://img.shields.io/badge/Git-2.0%2B-F05032?logo=git&logoColor=white"></a>
  <a href="docs/design/runtime-environment.md"><img alt="mikefarah yq version 4" src="https://img.shields.io/badge/mikefarah%2Fyq-v4-5A2D81"></a>
</p>

---

Themis 是一个面向团队的 repo-local 规范驱动开发（SDD）Harness。它将受管的 AI Coding 能力安装到工程仓库中，同时将项目特定的 Context、Spec、运行记录和证据保留在项目持有的 Workspace 中。

## Themis 四大特点

- **Spec 前追问**：在发布 Spec 前系统澄清意图、范围、假设、约束和验收条件，减少带着歧义进入实施。
- **更轻松的 Spec Review**：以 `spec.yaml` 保存机器语义，以确定性 `spec.md` 提供聚焦关键决策、AC、风险和批准信息的人类投影。
- **Agent 自主 Plan 的结果可沉淀**：Agent 生成的计划、任务拆分、决策和证据要求可以成为受治理、可追溯的项目工件，而不是随会话消失。
- **不断进化的项目知识库**：将经过事实核验和人工批准的经验持续沉淀为项目持有的 Context，使后续 Spec、Plan、Review 和 Verification 能复用已有知识。

四项特点描述 Themis 的产品方向；各能力是否已经可执行，以 [设计规范中的实现状态](docs/design/) 和下方当前版本说明为准。

当前版本提供 **fresh Init** 与 Spec v2 双视图。它不提供 Core 原地更新、Workspace/Artifact Schema 转换或 Behavior Map；完整设计、模块边界与实现状态以 [Themis 设计规范](docs/design/) 为准，未实现的生命周期执行器不会被描述为现有能力。

<a id="quick-start"></a>

## 快速开始

### 前置环境

从 Themis 源仓库运行 Init 前，请准备以下环境：

| 依赖 | 最低版本 | 用途 |
|---|---:|---|
| Bash | 3.2+ | 运行 Themis Shell 入口 |
| Git | 2.0+ | Init 环境检查与项目元数据读取 |
| [mikefarah/yq](https://github.com/mikefarah/yq) | v4 | YAML 的读取、校验与更新 |

只支持 Go 实现的 `mikefarah/yq` v4；Python 版本或其他同名 `yq` 命令不兼容。macOS、Linux 与 Windows Git Bash 的安装说明见 [Init 运行环境](docs/design/runtime-environment.md)。

### 初始化项目

在 **Themis 源仓库**中运行：

```bash
bash bin/themis-init.sh /path/to/project
```

Init 仅适用于尚未存在 `.themis/` 的项目。它会校验环境与模板、安装 `.themis/`、写入 Workspace manifest，并向项目 `CLAUDE.md` 追加受管 Guidance import；同时将派生缓存和会话状态加入项目 `.gitignore`。它不会执行项目命令，也不会修改项目 `AGENTS.md`。

使用默认项目配置的非交互示例：

```bash
bash bin/themis-init.sh /path/to/project --yes --project-name my-project
```

完整语法：

```text
bash bin/themis-init.sh [target] [--yes] [--project-name <name>] [--lint <command>] [--build <command>] [--test <command>]
```

未显式提供的 `lint`、`build` 与 `test` 命令保持为空；Themis 不会猜测项目工具链。初始化后，使用能够读取项目 `CLAUDE.md` 的 Agent 环境在目标仓库中工作；Init 本身不验证该 Agent 是否可用。

<a id="usage"></a>

## 使用指南

### 已有安装

如果目标项目已存在 `.themis/`，Init 会在任何写入前失败，并保留现有 Workspace。当前版本没有原地更新或 Schema 转换入口；请不要用重复 Init、覆盖复制或删除 `.themis/` 的方式绕过该边界。

未来恢复更新能力时，将作为新的正式设计和实施计划重新确认，不复用已退役的 Upgrade/Migration 合同。

### 当前 Spec 产物

Requirement Questioning 在 cache 中维护 Draft candidate，并由确定性 Spec executor 发布双视图：

```text
workspace/cache/spec-candidates/<spec-id>.yaml
workspace/specs/<spec-id>/spec.yaml
workspace/specs/<spec-id>/spec.md
```

`spec.yaml` 是唯一机器语义源，`spec.md` 是可重建的 Human projection。Planning、前置 Review、Implementation、Verification、Human Acceptance、Summary 和 Archived 的完整执行器仍待实施；目标生命周期见 [完整工作流程](docs/design/workflow.md)。

## 文档

- [设计规范](docs/design/) — 已确认的 Themis 设计、模块合同与实现状态。
- [文档门户](docs/) — 设计、计划、分析与参考资料入口。
- [Init 运行环境](docs/design/runtime-environment.md) — Bash、Git 与 yq 的版本要求及跨平台安装指引。
- [完整工作流程](docs/design/workflow.md) — 生命周期、阶段门禁、fresh Init 与当前能力边界。
- [更新日志](CHANGES.md) — 版本变更记录。

## 许可证

本项目采用 [MIT License](LICENSE)。
