# P0 实施设计 — Init Environment Validation

**关联计划**：[P0 — Init Environment Validation](README.md)
**状态**：实施完成并通过验证
**实施边界**：仅实现 Themis Init 阶段的 Bash、Git、mikefarah/yq 校验与说明；不实现 `themis-init.sh` 本体，不校验 Agent 或文件系统权限，也不让已安装 Themis 的 SDD 流程加载此检查。

## 1. 决策与约束

| 决策 | 结论 |
|---|---|
| 调用时机 | 仅 `themis-init.sh` 启动时调用；Upgrade、Agent、Core 运行时与 SDD 工作流均不得调用。 |
| 支持平台 | macOS、Linux、Windows Git Bash。 |
| Shell 语法基线 | Bash 3.2；不得使用 associative arrays、`mapfile`、`coproc`、`declare -A` 等 Bash 4+ 功能。 |
| Git 基线 | Git 2.0.0；只用 `git --version` 检查，不执行仓库操作。 |
| YAML 工具 | 仅接受 mikefarah/yq v4（建议最低 `v4.0.0`）；不接受 Python yq、kislyuk/yq 或其他同名命令。 |
| 失败策略 | 任一必需工具缺失、不兼容或无法解析版本时，输出单一明确诊断并以非零状态退出；不尝试静默安装。 |
| 可重复性 | 检查只读取命令版本输出，不写文件、环境变量、配置或 Workspace。 |

## 2. 文件与职责

| 文件 | 操作 | 职责 |
|---|---|---|
| `bin/_themis-init-env.sh` | 新建 | Bash 3.2 兼容的私有共享库；只由 `themis-init.sh` source。 |
| `docs/runtime-environment.md` | 新建 | 记录 Init 环境的版本要求、诊断含义、各平台获取方式与非范围。 |
| `bin/themis-init.sh` | 后续 P3 修改 | 只调用 `themis_init_require_environment`；本 P0 不创建或修改。 |
| `tests/init-environment/` 或等价测试夹具 | 新建，路径待实施确认 | 通过伪造 `PATH` 命令覆盖验证成功与失败路径。 |

`_themis-init-env.sh` 属于 Themis 源仓库的安装工具，不复制到目标项目的 `.themis/`。它不是 Core 运行时库。

## 3. 公共函数契约

共享库只定义下列以 `themis_init_` 开头的函数，避免与项目脚本或已安装 Themis 功能混淆：

```bash
themis_init_require_environment
themis_init_check_bash
themis_init_check_git
themis_init_check_yq
themis_init_version_at_least
themis_init_print_dependency_error
```

### `themis_init_require_environment`

```text
输入：无
顺序：Bash → Git → yq
成功：返回 0
失败：输出第一项失败工具的诊断，返回非零；不继续检查后续工具
副作用：无
```

### 单工具检查函数

```text
输入：无
成功：返回 0；默认静默
失败：调用 themis_init_print_dependency_error 并返回 1
副作用：无
```

### `themis_init_version_at_least <actual> <minimum>`

- 接受 `major.minor.patch`（patch 缺失时视为 0）。
- 逐段数值比较，不依赖 `sort -V`、Python、awk 版本扩展或 GNU-only 工具。
- 不接受无法归一化为三段数字的版本。

## 4. 版本读取与识别规则

### Bash

- 来源：内建变量 `BASH_VERSINFO`；若不可用则以 `$BASH_VERSION` 提取。
- 最低版本：`3.2.0`。
- 失败情况：脚本不是由 Bash 运行，或版本小于 `3.2.0`。
- 不通过 `bash --version` 启动子进程，因为实际解释脚本的 shell 才是需要验证的对象。

### Git

- 探测：`command -v git`。
- 版本来源：`git --version`，期望字符串包含 `git version <major>.<minor>[.<patch>]`。
- 最低版本：`2.0.0`。
- 解析失败也视为不兼容，防止同名包装器伪装成功。

### mikefarah/yq

- 探测：`command -v yq`。
- 版本来源：`yq --version`。
- 识别条件必须同时满足：
  1. 输出含有 `mikefarah/yq` 或官方 `yq ... version v4.*` 格式；
  2. 能从输出提取 `v4.<minor>.<patch>` 或等价的 v4 数字版本；
  3. 版本不低于 `v4.0.0`。
- API 基线：后续 Init 只允许使用 v4 语法，如 `yq eval '<expression>' <file>` 和 `yq eval -i '<expression>' <file>`。
- 不匹配的 `yq` 命令（如 Python wrapper）必须被拒绝，并在诊断中提示安装 mikefarah/yq v4。

## 5. 统一诊断格式

所有失败都使用稳定、可读、可用于测试的格式：

```text
Themis Init prerequisite failed: <tool>
  Required: <requirement>
  Detected: <detected-version-or-not-found>
  Reason: <missing | unsupported implementation | version too old | version unreadable>
  Install: <platform-neutral-or-platform-specific guidance>
```

安装指引：

| 工具 | macOS | Linux | Windows Git Bash |
|---|---|---|---|
| Bash | 系统 Bash；版本不足则安装较新 Bash | 系统包管理器 | Git for Windows 自带 Git Bash；升级 Git for Windows |
| Git | `brew install git` | 系统包管理器 | Git for Windows |
| yq | `brew install yq` | 官方 release 二进制或发行版包（须确认 mikefarah v4） | 下载 [mikefarah/yq release](https://github.com/mikefarah/yq/releases) 并加入 `PATH` |

文档应明确：运行时只校验、不安装；用户可自行按说明安装后重新运行 Init。

## 6. 实施任务拆分

1. 创建 `bin/_themis-init-env.sh`，添加 Bash 3.2 guard、版本比较与统一诊断函数。
2. 实现 Bash、Git、mikefarah/yq 三个独立检查函数，再组合为 `themis_init_require_environment`。
3. 编写 `docs/runtime-environment.md`：限定为 Init 前置环境，明确正常 Themis SDD 运行不会执行该校验。
4. 创建测试夹具：用临时目录和伪造 `git`/`yq` 可执行文件覆盖 `PATH`，覆盖以下矩阵。
5. 在 Bash 语法检查、真实当前环境与伪造环境上验证库；不创建 Init 主脚本。

## 7. 验证矩阵

| 场景 | Bash | Git | yq | 预期 |
|---|---|---|---|---|
| 全部满足 | 3.2+ | 2.0+ | mikefarah v4.0+ | 返回 0，无 stderr |
| Bash 过低 | 3.1 | 任意 | 任意 | 首项失败，显示 Bash 版本诊断 |
| Git 未找到 | 合格 | 不在 PATH | 任意 | 非零，`Detected: not found` |
| Git 过低 | 合格 | 1.9.9 | 任意 | 非零，显示最低版本与检测值 |
| yq 未找到 | 合格 | 合格 | 不在 PATH | 非零，提供官方 release 链接 |
| Python yq | 合格 | 合格 | 非 mikefarah 输出 | 非零，说明实现不受支持 |
| yq v3 | 合格 | 合格 | mikefarah v3 | 非零，要求 v4 |
| yq v4 | 合格 | 合格 | mikefarah v4.0+ | 返回 0 |
| Bash 兼容性 | n/a | n/a | n/a | `bash -n bin/_themis-init-env.sh` 通过，且不含 Bash 4+ 语法 |
| 运行时隔离 | n/a | n/a | n/a | 确认 `.themis/core/`、Workspace 和 Upgrade 脚本未 source 此库 |

## 8. 风险与回滚

- **yq 标识歧义**：不同系统的包名可能都叫 `yq`。用输出特征 + v4 版本双重判断；无法确认时宁可拒绝。
- **macOS 系统 Bash 过旧**：3.2 正好是支持下限，脚本必须避免 Bash 4 特性，并通过 macOS 兼容语法检查。
- **回滚**：移除 `bin/_themis-init-env.sh` 和 `docs/runtime-environment.md` 即可；该模块不写入模板和用户项目，无数据迁移需求。

## 9. 实施结果

已落地：

- `bin/_themis-init-env.sh`
- `docs/runtime-environment.md`
- `tests/init-environment/test.sh`

验证结果：

- Bash 语法检查通过。
- ShellCheck 0.11.0 通过 winget 安装，并使用其安装后的可执行文件完成静态检查；Bash 原生语法检查也已通过。
- 31 项版本解析、Git/yq 识别、失败诊断、检查顺序与静默成功测试全部通过。
- 当前开发环境的 Bash 和 Git 检查通过。
- 模板目录未引用 `_themis-init-env.sh` 或 `themis_init_require_environment`；P0 未创建或修改 Init、Upgrade、Core 或 Workspace 执行路径。
