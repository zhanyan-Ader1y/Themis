# P3 — Init

**优先级**：P3
**依赖**：[P0 Init Environment Validation](../00-runtime-environment/README.md)、[P1 Template Contract](../10-template-contract/README.md)、[P2 Top-level Guidance](../20-top-level-guidance/README.md)
**状态**：已完成

## 目标

实现 `bin/themis-init.sh`，以交互优先且可自动化的方式将经过验证的 Themis 模板初始化到目标项目，并保留用户项目的所有既有内容。

## 范围

- 参数：目标路径、`--yes`、`--project-name` 与项目命令配置选项；不提供会替换既有 Workspace 的 `--force`。
- 调用 P0 的 Init 专用 Bash、Git、yq 校验。
- 校验目标路径和写入能力；已有 `.themis/` 时安全退出并建议使用 Upgrade。
- 从 P1 模板复制完整 `.themis/` 基线（包含 Themis 管理的 `CLAUDE.themis.md`）。
- 使用 yq 写入 Manifest 的项目名、lint/build/test 命令等项目特有字段。
- 创建完整 Workspace 目录以及必要的初始索引/状态文件。
- 幂等地向 `.gitignore` 加入仅派生数据：cache、锁和临时运行数据；不默认忽略 Spec、证据、Run 或正式 Context。
- 必须在项目 `CLAUDE.md` 末尾写入可逆的唯一标记块，直接 import `.themis/CLAUDE.themis.md` 与 `.themis/core/kernel/orchestrator/rules.md`；不创建根目录 Themis 指引文件，也不修改 `AGENTS.md`。
- 执行结构、YAML、版本、import 自检；失败时清理本次新建文件或恢复本次备份。

## 非范围

- 不运行项目 lint、build 或 test 命令。
- 不创建具体 Spec 或 Plan。
- 不升级已有安装；已有 `.themis/` 的演进属于 P4。
- 不对 Agent 或文件系统权限做运行时配置。

## 目标文件

- `bin/themis-init.sh`
- P0 的共享库
- Init 集成测试夹具/脚本（精确路径由 `impl.md` 确定）

## 执行前置步骤

当用户主动发起本计划时，**第一步**必须在本计划目录创建或更新 `impl.md`（`docs/plan/30-init/impl.md`），至少记录：

1. 函数边界与错误处理、清理/回滚策略；
2. 参数、交互提示与非交互默认值矩阵；
3. Manifest 字段到输入源的映射；
4. 精确 `.gitignore` 规则及其理由；
5. `CLAUDE.md` 末尾唯一标记块、两个直接 import 与已有 `AGENTS.md` 的不修改策略；
6. 临时项目端到端测试矩阵。

`impl.md` 经用户确认前，不得修改目标文件。

## 验收条件

- `--yes` 在空临时项目中可成功初始化，`.themis/` 内的指引有效，且项目根目录没有 `CLAUDE.themis.md`。
- Init 在项目 `CLAUDE.md` 末尾写入唯一、可逆的标记块，块内直接 import `.themis/CLAUDE.themis.md` 与 `.themis/core/kernel/orchestrator/rules.md`。
- 交互模式仅请求项目特有信息，并可安全接受默认值。
- 已有 `.themis/` 时不写入文件并建议 Upgrade。
- 已有完整标记块不会重复写入；破损、重复或被修改的标记块在写入前被拒绝。
- 初始化失败不遗留半完成安装。

## 风险与回滚

- **风险**：对已有项目的 `CLAUDE.md` 或 `.gitignore` 造成不可逆改动。
- **缓解**：标记化、幂等追加；写前备份目标文件并限定只修改 Themis 标记区块。
- **回滚**：删除本次新建 `.themis/`；恢复本次写入前的 CLAUDE/.gitignore 备份。
