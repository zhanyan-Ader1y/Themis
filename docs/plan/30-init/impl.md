# P3 实施设计 — Init

**关联计划**：[P3 — Init](README.md)
**状态**：已实施
**实施边界**：实现 `bin/themis-init.sh`，将已验证的源模板安装到目标项目；不升级已有安装（P4）、不创建 Spec/Plan、不运行项目命令。

## 1. 参数接口

| 参数 | 必需 | 说明 |
|---|---|---|
| `[target]` | 否 | 目标项目根目录，默认 `.` |
| `--yes` | 否 | 非交互模式，接受所有默认值 |
| `--project-name <name>` | 否 | 项目名；交互模式下提示输入，`--yes` 时默认使用目标目录名 |
| `--lint <cmd>` | 否 | 项目 lint 命令 |
| `--build <cmd>` | 否 | 项目 build 命令 |
| `--test <cmd>` | 否 | 项目 test 命令 |

Init 总是在项目 `CLAUDE.md` 末尾写入唯一的 Themis 标记块；不提供可选合并开关，也不会创建项目根 `CLAUDE.themis.md`。Themis 管理的紧凑指引随模板安装于 `<target>/.themis/CLAUDE.themis.md`。

P3 不提供 `--force`。只要目标已存在 `.themis/`，Init 就必须在任何写入前拒绝并建议使用 P4 Upgrade。现有安装同时包含 Themis 管理的 Core 与项目管理的 Workspace，Init 无法在不承担升级、兼容性判断和 Workspace 保护责任的情况下安全替换它。

## 2. 执行顺序

1. 解析参数，确定目标目录的绝对路径。
2. 定位模板源：从脚本自身路径推导源仓库的 `templates/` 目录。
3. 调用 P0 的 `_themis-init-env.sh`：`themis_init_require_environment`。
4. 检查目标目录存在且可写；已有 `.themis/` 时输出诊断、建议 Upgrade 并退出。
5. 交互收集项目信息（`--yes` 跳过）：
   - 项目名（默认使用目标目录名）；
   - lint、build、test 命令（默认 `null`）。
6. 在任何模板写入前验证 `CLAUDE.md` 与 `.gitignore` 的 Themis 标记状态，并备份将要修改的既有文件。
7. 复制完整 `templates/.themis/` → `<target>/.themis/`（其中包含 `CLAUDE.themis.md`）。
8. 用 yq 写入项目名与命令到 `<target>/.themis/workspace/manifest.yaml`。
9. 幂等更新 `.gitignore`。
10. 在项目 `CLAUDE.md` 末尾写入两个直接 import 的标记块；无该文件时创建最小文件。
11. 运行 `bin/themis-template-check.sh --installed <target>/.themis` 自检。
12. 自检失败时执行回滚，成功时清理备份。

## 3. 模板源定位

脚本使用与 P1 检查器相同的模式，从自身文件系统位置推导源仓库：

```bash
THEMIS_INIT_SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
THEMIS_INIT_REPO_ROOT=$(CDPATH='' cd -- "${THEMIS_INIT_SCRIPT_DIR}/.." && pwd)
THEMIS_INIT_TEMPLATE_SOURCE="${THEMIS_INIT_REPO_ROOT}/templates"
```

这要求从源仓库的 `bin/` 目录运行；P3 尚未支持从已安装的 Themis 实例初始化另一个项目。

## 4. Manifest 写入

使用 yq 写入项目字段，不重写整个文件：

```bash
yq eval -i ".project.name = \"${project_name}\"" "${manifest_path}"
yq eval -i ".commands.lint = \"${lint_cmd}\"" "${manifest_path}"
yq eval -i ".commands.build = \"${build_cmd}\"" "${manifest_path}"
yq eval -i ".commands.test = \"${test_cmd}\"" "${manifest_path}"
```

默认值 `null` 在 YAML 中保持为 `null`，而非空字符串。P3 不修改 `gates`、`adapters`、`policy_overrides` 和 `context` 字段。

## 5. `.gitignore` 规则

仅忽略派生数据，不忽略 Spec、证据、Run 或正式 Context：

```text
# Themis — derived data (managed by themis-init)
.themis/workspace/cache/
.themis/workspace/state/sessions/
```

规则以标记行包裹，已存在时幂等跳过：

```text
# Themis — derived data (managed by themis-init)
...
# Themis end
```

## 6. `CLAUDE.md` 集成

Init 将以下唯一标记块追加到项目 `CLAUDE.md` 的末尾：

```text
<!-- themis:guidance:start -->
@import .themis/CLAUDE.themis.md
@import .themis/core/kernel/orchestrator/rules.md
<!-- themis:guidance:end -->
```

第一个 import 加载 `.themis/` 内 Themis 管理的紧凑顶层指引；第二个 import 直接加载 Orchestrator 与其领域规则图。顶层指引自身不再 import Orchestrator，以避免重复加载。

实现逻辑：

- 搜索开始和结束标记；
- 两个标记都存在且各出现恰好一次，并且块内容精确匹配：已安装，跳过；
- 两个标记都不存在：仅在文件末尾追加块；
- 只有单边标记、多个块或块内容被修改：输出诊断，不修改文件，退出；
- 无 `CLAUDE.md`：创建仅含标记块的最小文件；
- 不修改 `AGENTS.md`；发现该文件只报告其存在和既有优先级。

## 7. 交互模式

仅在未传 `--yes` 时进入交互。交互只询问项目特有信息：

1. 项目名（默认：目标目录的 basename）。
2. lint 命令（默认：跳过，保持 `null`）。
3. build 命令（默认：跳过）。
4. test 命令（默认：跳过）。

所有提示接受空输入使用默认值。

## 8. 错误处理与回滚

- 环境校验失败 → 退出，不创建任何文件。
- 目标不可写或已有 `.themis/` → 退出，不创建任何文件。
- 任何步骤失败后：
  1. 删除本次创建的 `<target>/.themis/`（其中包含 Themis 管理的 `CLAUDE.themis.md`）；
  2. 如果写入了 `CLAUDE.md` 标记块，回退到备份；
  3. 如果写入了 `.gitignore` 块，回退到备份；
  4. 如果创建了新的 `CLAUDE.md`，删除该文件。
- 成功时删除备份文件。

## 9. 实施任务

1. 编写 `bin/themis-init.sh`，包含上述全部逻辑。
2. 编写 `tests/init/test.sh`，覆盖成功安装、重复运行拒绝、`CLAUDE.md` 末尾直接 import、标记冲突、已有安装拒绝和失败清理。
3. 运行全部回归，记录结果并更新 `CHANGES.md`。

## 10. 验证矩阵

| 类别 | 检查 | 预期 |
|---|---|---|
| Bash 语法 | `bash -n bin/themis-init.sh` | 通过 |
| Shell 静态检查 | ShellCheck | 无 findings |
| 成功安装 | 空临时项目 + `--yes --project-name test` | `.themis/CLAUDE.themis.md` 就位，Manifest 写入正确；项目根无 `CLAUDE.themis.md` |
| `CLAUDE.md` 直接入口 | 新建或已有 `CLAUDE.md` | 末尾仅有一个标记块，块内直接 import `.themis/CLAUDE.themis.md` 和 Orchestrator |
| 重复运行 | 同一目标运行两次 | 第二次在任何写入前拒绝，首次安装内容保持不变 |
| 已有安装拒绝 | 目标已有 `.themis/` | 退出并建议 Upgrade；不修改 Core 或 Workspace |
| 标记冲突 | 单边、重复或被修改的 Themis 标记 | 退出并报告诊断，且不创建 `.themis/` |
| 失败清理 | 模拟写入失败 | 不留 `.themis/` 或部分 `CLAUDE.md`/`.gitignore` 写入 |
| 自检通过 | 安装后运行 checker 的 `--installed` 模式 | 成功且无输出 |
| 回归 | P0 31 项、P1/P2 32 项 | 全部通过 |
| 补丁卫生 | `git diff --check` | 通过 |

## 11. 实施结果

已落地：

- `bin/themis-init.sh`：Bash 3.2 兼容的 Init 实现，先运行 P0 环境校验和源模板检查，再配置新的 Workspace manifest；不运行项目命令，也不覆盖已有 `.themis/`。
- `templates/.themis/CLAUDE.themis.md`：将 Themis 顶层指引移入 Themis 命名空间；项目根不再安装 `CLAUDE.themis.md`。
- 项目 `CLAUDE.md`：Init 总在末尾写入一个可逆、严格校验的标记块，直接 import `.themis/CLAUDE.themis.md` 与 `.themis/core/kernel/orchestrator/rules.md`。破损、重复或被修改的块在任何安装写入前拒绝。
- `bin/themis-template-check.sh`：源模板与 `--installed` 校验模式均支持自包含的 `.themis/CLAUDE.themis.md`；源模板禁止遗留根目录指引，安装后的 project name 不再被误判为源模板默认值。
- `tests/init/test.sh`：新增 22 项隔离集成测试，覆盖新建/已有 `CLAUDE.md`、直接 import、根目录无指引文件、标记冲突、manifest 配置与已有 Workspace 拒绝。
- `tests/template-contract/test.sh`：扩展为 34 项，覆盖包含式指引的零 import 契约与过时根目录指引拒绝。

验证结果：

- `bash -n bin/themis-init.sh bin/themis-template-check.sh tests/init/test.sh tests/template-contract/test.sh` 通过。
- ShellCheck 0.11.0 对上述脚本无 findings。
- `bash tests/init-environment/test.sh`：P0 的 31 项测试全部通过。
- `bash tests/template-contract/test.sh`：P1/P2 契约的 34 项测试全部通过。
- `bash tests/init/test.sh`：P3 的 22 项 Init 集成测试全部通过。
- `bash bin/themis-template-check.sh`：源模板成功且无输出。
- `git diff --check` 通过；仅输出已有 Windows 工作区的 LF/CRLF 转换警告，无 whitespace error。

仍待认证环境验证：

- Claude Code 运行时 import 行为仍需在已认证环境中使用项目 `CLAUDE.md` 的双直接 import 块复核；静态路径、存在性、Core confinement 与安装布局已由检查器和隔离夹具覆盖。