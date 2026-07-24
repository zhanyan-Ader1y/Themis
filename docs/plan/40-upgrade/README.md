# P4 — Upgrade

**优先级**：P4
**依赖**：[P1 Template Contract](../10-template-contract/README.md)、[P3 Init](../30-init/README.md)
**状态**：已完成

## 目标

实现 `bin/themis-upgrade.sh`，以可诊断、可回滚的方式将已初始化项目中的 Themis 管理内容替换为最新模板，同时逐字保护项目 Workspace。

## 范围

- 参数：目标路径和 `--dry-run`；不默认提供绕过兼容性检查的高风险选项。
- 使用 Upgrade 自身所需的最小工具能力处理文件、版本和 YAML；不得加载或执行 P0 的 Init 环境校验。
- 读取已安装与候选模板的框架版本、Core Version、Workspace Schema、Artifact Schema 和支持矩阵。
- 仅识别两种结果：兼容或不兼容；P4 不执行 Workspace 或 Artifact 迁移。
- 兼容升级时，以可回滚的替换操作删除 `.themis/` 下除 `workspace/` 外的 Themis 管理内容，再从最新模板复制对应内容；`workspace/` 及其所有文件保持原样。
- `.themis/CLAUDE.themis.md` 随同除 `workspace/` 外的 Themis 管理内容替换；不创建或替换项目根 `CLAUDE.themis.md`，也不重写项目 `CLAUDE.md`，因为其直接 import 路径保持稳定。
- 不兼容时不写文件，并输出已安装版本、候选支持范围和建议操作。
- 任一失败后恢复被替换的 Themis 管理内容；Workspace 不参与删除、复制或恢复操作。
- 验证新 Core、保留的 Workspace、YAML 版本/兼容关系和顶层指引 import。

## 非范围

- 不删除、复制、迁移或修改 `workspace/`，包括其中的 Manifest、Spec、Evidence、Context、状态和旧记录。
- 不静默迁移 Workspace 或 Artifact Schema。
- 不自动删除升级备份。
- 不实现未在模板中显式提供的迁移逻辑。

## 目标文件

- `bin/themis-upgrade.sh`
- Upgrade 自身的工具函数或库（精确路径由 `impl.md` 决定）
- Upgrade 集成测试夹具/脚本（精确路径由 `impl.md` 确定）

## 执行前置步骤

当用户主动发起本计划时，**第一步**必须在本计划目录创建或更新 `impl.md`（`docs/plan/40-upgrade/impl.md`），至少记录：

1. 升级事务边界、更新顺序及失败状态；
2. Themis 管理内容的备份位置、命名规则、保留与恢复流程；
3. `workspace/` 不变性验证方法（升级前后内容哈希与目录清单）；
4. 除 `workspace/` 外的 `.themis/` 内容（包含 `.themis/CLAUDE.themis.md`）的原子替换策略；
5. 兼容与不兼容的决策表；
6. `--dry-run` 输出契约和回滚测试矩阵。

`impl.md` 经用户确认前，不得修改目标文件。

## 验收条件

- 版本相同的安装无写入退出。
- 兼容升级仅替换 `.themis/` 中除 `workspace/` 外的内容（包含 `.themis/CLAUDE.themis.md`）；Workspace 内容哈希与目录清单不变，项目 `CLAUDE.md` 不变。
- 升级前后 `workspace/manifest.yaml` 字节内容不变；若新 Core 不支持其声明的 Schema，升级拒绝且无写入。
- 不兼容升级无写入、返回非零并给出可操作诊断。
- 任一模拟失败后，被替换的 Themis 管理内容恢复至升级前状态，Workspace 内容哈希与目录清单仍不变。
- `--dry-run` 不写入任何文件。

## 风险与回滚

- **风险**：替换中断造成 Themis 管理内容不完整，或新 Core 与既有 Workspace Schema 不兼容。
- **缓解**：升级前验证兼容性，备份待替换内容，阶段性自检并在失败时恢复；`workspace/` 不进入任何删除、复制或写入操作。
- **回滚**：用升级前的 Themis 管理内容快照恢复；保留日志和备份，不自动清理。
