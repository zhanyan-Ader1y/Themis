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

当前版本提供 **Init**、**Upgrade** 和显式 **Migration** 的分步入口。完整设计、模块边界与实现状态以 [Themis 设计规范](docs/design/) 为准；未实现的生命周期执行器不会被 README 描述为现有能力。

<a id="quick-start"></a>

## 快速开始

### 前置环境

从 Themis 源仓库运行命令前，请准备以下环境：

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

### 升级已有安装

已有 `.themis/` 的项目应使用 Upgrade，而不是再次执行 Init。建议先预演：

```bash
bash bin/themis-upgrade.sh /path/to/project --dry-run
```

确认后执行升级：

```bash
bash bin/themis-upgrade.sh /path/to/project
```

Upgrade 仅替换 `.themis/` 中 **Workspace 以外**的 Themis 受管内容；它保持 Workspace 不变，也不会重写项目的 `CLAUDE.md` 或 `AGENTS.md`。若兼容性检查发现 Workspace 或 Artifact Schema 不兼容，Upgrade 会拒绝继续并要求显式 Migration。

完整语法：

```text
bash bin/themis-upgrade.sh [target] [--dry-run]
```

### 显式 Schema Migration

Migration 是 Upgrade 因 Schema 不兼容而拒绝时使用的高级恢复路径。按以下顺序显式执行：

```bash
bash bin/themis-migrate.sh /path/to/project --check
bash bin/themis-migrate.sh /path/to/project --backup
bash bin/themis-migrate.sh /path/to/project --run --migration-id '<from→to>'
bash bin/themis-migrate.sh /path/to/project --verify
bash bin/themis-migrate.sh /path/to/project --rollback --backup-path <path>
```

> **当前限制：** 只有 `--check` 返回实际 descriptor 后才能执行对应的 `--run`。当前模板没有具体 migration descriptor 或 Schema 转换脚本，因此当前版本没有内置、可执行的版本转换路径。调用方需要显式确认迁移、保存 `--backup` 返回的路径；`--verify` 失败后也需要显式调用 `--rollback`，脚本尚未端到端强制这些安全前置条件。

完整语法：

```text
bash bin/themis-migrate.sh <target> <action> [options]
```

可用 action 为 `--check`、`--backup`、`--run`、`--verify`、`--rollback`、`--dry-run` 和 `--help`。`--run` 必须提供 `--migration-id`，`--rollback` 必须提供 `--backup-path`；详见 [Migration 当前边界](docs/design/core/migrations.md)。

## 文档

- [设计规范](docs/design/) — 已确认的 Themis 设计、模块合同与实现状态。
- [文档门户](docs/) — 设计、计划、分析与参考资料入口。
- [Init 运行环境](docs/design/runtime-environment.md) — Bash、Git 与 yq 的版本要求及跨平台安装指引。
- [完整工作流程](docs/design/workflow.md) — 生命周期、能力边界与 Init / Upgrade / Migration 的关系。
- [更新日志](CHANGES.md) — 版本变更记录。

## 许可证

本项目采用 [MIT License](LICENSE)。
