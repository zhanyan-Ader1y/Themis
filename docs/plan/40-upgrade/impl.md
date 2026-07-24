# P4 实施设计 — Upgrade

**关联计划**：[P4 — Upgrade](README.md)
**状态**：已实施
**实施边界**：实现安全替换已安装 Themis 的非 Workspace 内容；P4 不调用 P0，不运行项目命令，不迁移、写入、复制、删除或恢复 `.themis/workspace/`，也不修改项目 `CLAUDE.md` 或 `AGENTS.md`。

## 1. 目标与不可变边界

Upgrade 的候选版本始终来自源仓库中与脚本相邻推导出的 `templates/.themis/`。它只在已安装布局符合当前直接 import 契约、且候选 Core 明确兼容现有 Workspace/Artifact Schema 时执行替换。

受 Upgrade 管理、可替换的范围是 `.themis/` 中除顶层 `workspace/` 外的**所有**顶层条目；当前至少包含：

```text
.themis/VERSION
.themis/CLAUDE.themis.md
.themis/core/
```

`workspace/` 是绝对排除项。实现不得遍历其内容以执行复制、删除、移动、权限重设或恢复；其 `manifest.yaml`、Spec、Evidence、Context、状态与任何项目文件必须保持逐字不变。项目根的 `CLAUDE.md` 及 `AGENTS.md` 也不属于事务内容。

P4 仅产生两种兼容性结论：**compatible** 或 **incompatible**。即使候选 Core 声明了迁移描述符，P4 仍拒绝升级并要求后续显式迁移能力处理；不得将“可迁移”当作可替换。

## 2. 命令接口与输入约束

计划实现单一 Bash 3.2 兼容入口：

```text
Usage: themis-upgrade.sh [target] [--dry-run]
```

| 输入 | 默认值 | 行为 |
|---|---|---|
| `[target]` | `.` | 已安装 Themis 的项目根目录；解析为绝对路径。 |
| `--dry-run` | 否 | 完成所有只读布局、版本、Schema 与候选检查；输出将备份、移除和复制的顶层管理条目，但不创建暂存区、备份或修改任何文件。 |
| `--help` | 否 | 输出帮助并成功退出。 |

拒绝多余位置参数、未知选项、缺失/不可写目标、缺失或非目录的 `<target>/.themis/workspace`、缺失必要的 Core/Manifest 文件，以及不受支持的 YAML 工具。脚本自行确认 `yq` 是 mikefarah/yq v4，以读取 Schema 和兼容性；**不得 source 或执行** `_themis-init-env.sh`，也不得将 Bash/Git 的 Init 前置检查带入 Upgrade。

版本相同的已安装 Bundle/Core 与候选 Bundle/Core，在完成布局和候选兼容性验证后输出“already current”并以零状态退出；不创建备份或暂存内容。版本不同才进入升级事务。

## 3. 当前布局与遗留安装拒绝

Upgrade 仅支持由 P3 建立的当前入口布局。它在任何写入前局部复用 Init 中的严格标记语义（在 Upgrade 脚本中实现独立、只读的检查函数，不能 source Init）：

```md
<!-- themis:guidance:start -->
@import .themis/CLAUDE.themis.md
@import .themis/core/kernel/orchestrator/rules.md
<!-- themis:guidance:end -->
```

通过条件为项目 `CLAUDE.md` 中开始与结束标记各恰好一次，且标记块逐字等于上述内容；同时必须存在 `.themis/CLAUDE.themis.md`，且项目根不存在 `CLAUDE.themis.md`。

缺失、单边、重复或被修改的标记块，缺失 contained guidance，或发现根级 `CLAUDE.themis.md` 都视为 legacy/manual layout：输出“需要手动迁移项目指引”的诊断并在创建备份前退出。P4 不尝试修复或重写项目指引，避免将升级行为扩展到项目持有文件。

## 4. 只读预检与兼容性决策

实施时在写入前依次执行：

1. 从脚本路径定位源仓库、候选 `templates/.themis/` 和现有 `bin/themis-template-check.sh`；验证三者存在。
2. 调用现有检查器验证候选源模板：`bash bin/themis-template-check.sh <candidate>`。这复用 P1/P2 的结构、版本、Core import、YAML 与候选自身兼容性契约检查；失败即拒绝。
3. 验证安装布局（第 3 节）和已安装 `.themis/workspace/manifest.yaml` 的 YAML 可读性；读取其 `workspace_schema`、`artifact_schema`、Bundle Version 与已安装 Core Version。
4. 从候选 `core/core.yaml` 读取 `core_schema`、`core_version`、`compatibility.workspace.supported[]` 与 `compatibility.artifact.supported[]`。Schema 必须为非空、正确命名空间的标识符，支持列表必须为 YAML 序列。
5. 仅当候选的两个 `supported[]` 列表分别包含现有 manifest 的 Workspace 与 Artifact Schema 时判定 compatible；否则输出安装版本、候选版本、每个实际 Schema 与对应候选 allow-list，并以非零状态退出。
6. 当版本发生变化时，准备候选非 Workspace 顶层条目清单。候选 `workspace/` 只用于候选模板静态验证，绝不进入复制清单。

候选模板中出现面向既有 Schema 的 migration descriptor 不改变第 5 步结果：不在 `supported[]` 中即 incompatible，并指出 P4 不执行迁移。这样不会把项目持有数据的演进隐藏在 Core 替换内。

## 5. 事务、备份与恢复

### 5.1 持久备份

仅在所有预检通过且确有版本差异后，在项目根创建唯一持久目录：

```text
<target>/.themis-upgrade-backup.XXXXXX/
└── managed/       # 升级前 .themis/ 的每个非 workspace 顶层条目
```

名称使用 `mktemp -d` 生成，避免覆盖已有备份。备份仅容纳 Upgrade 即将移动的非 Workspace 条目；不得复制 `workspace/`，不得在其内部放置元数据。脚本输出备份绝对路径，成功、失败和恢复后均不自动删除，以便用户审计或手动回滚。P4 不修改 `.gitignore`。

### 5.2 暂存和替换顺序

为避免从未验证的候选直接覆盖安装，事务在目标根创建独立、唯一的暂存目录，并将候选 `.themis/` 的非 `workspace/` 顶层条目完整复制至该目录。复制保留文件和目录结构；暂存树必须通过 `--installed` 语义所需的结构检查，并结合保留 Workspace 进行最终安装检查。

在同一文件系统的项目根下执行下列阶段；每个阶段均由 `trap` 驱动的失败处理保护：

1. 记录开始状态，建立持久备份和候选暂存树；再次确认 `.themis/workspace` 存在且未被暂存逻辑引用。
2. 将当前 `.themis/` 中每一个非 `workspace/` 顶层条目移动至备份的 `managed/`。`workspace/` 名称由显式排除条件跳过，而非“复制后再还原”。
3. 将暂存树的所有候选非 `workspace/` 顶层条目移动到 `.themis/`。这会刷新 `VERSION`、`CLAUDE.themis.md`、`core/` 及以后版本新增的 Themis 管理条目。
4. 运行 `bash bin/themis-template-check.sh --installed <target>/.themis`；它验证新 Core 与未修改 manifest 的组合、contained guidance 和 Core import 图。
5. 以仅只读目录清单与内容指纹比较 Upgrade 前后 Workspace；并再次验证项目 `CLAUDE.md` 的精确标记块。成功后删除暂存目录，保留持久备份并输出完成信息与其路径。

测试和实现中的 Workspace 指纹必须覆盖相对路径、文件类型、空目录和普通文件内容；`manifest.yaml` 还必须进行独立的字节级比较。无需改变 Workspace 权限或时间戳来完成此检查。

### 5.3 失败与恢复

从第 1 步创建任何事务目录起，所有失败（候选复制、移动、检查器、Workspace 指纹或信号/中断）都进入恢复：

1. 仅删除本次已放入 `.themis/` 的候选非 Workspace 顶层条目；
2. 将备份 `managed/` 的所有条目移回 `.themis/`；
3. 保留持久备份，删除临时暂存目录；
4. 以读取方式确认 Workspace 指纹和项目 `CLAUDE.md` 未变化；
5. 若恢复自身失败，返回非零并输出备份路径、未完成阶段和明确的人工恢复命令/状态说明。

恢复不得尝试重建、覆盖或“修复” Workspace；由于事务从未移动它，恢复只处理管理条目。任何预检失败和 `--dry-run` 都发生在创建备份或暂存目录之前。

## 6. `--dry-run` 输出契约

`--dry-run` 成功输出应包含：绝对 target、已安装与候选 Bundle/Core 版本、保留的 Workspace/Artifact Schema、兼容结果、预期备份路径模式、将从 `.themis/` 移出的非 Workspace 顶层条目，以及将从候选复制的非 Workspace 顶层条目。输出明确说明以下路径不在动作清单：

```text
.themis/workspace/
CLAUDE.md
AGENTS.md
```

版本相同则输出 no-op 原因。任何布局或兼容性错误使用与真实升级相同的非零诊断，但不产生文件系统写入；测试通过前后项目目录树和内容指纹证明这一点。

## 7. 实施文件与复用边界

后续获批实现只新增以下 P4 文件：

- `bin/themis-upgrade.sh`：Bash 3.2 兼容的 Upgrade 入口；包含用途、运行边界、公共函数、关键控制流和非显然安全决策注释，符合 [AGENTS.md](../../../AGENTS.md) 的脚本文档规则。
- `tests/upgrade/test.sh`：隔离项目上的 TAP 集成测试；不得复用真实项目目录。

直接复用但不修改的现有能力：

- `bin/themis-template-check.sh` 的 source 与 `--installed` 契约验证；
- `templates/.themis/core/core.yaml` 的候选兼容 allow-list；
- `templates/.themis/workspace/manifest.yaml` 的 schema 字段布局；
- `bin/themis-init.sh` 中的脚本路径定位、严格 managed-block 语义及带注释的 Bash 3.2 风格（仅作为实现模式参考，Upgrade 不能 source Init 或其 P0 依赖）。

P4 不新增 P0 依赖、不修改 Init、模板、Core 或项目指引，也不实现 migration executor。若后续抽取共享函数，必须先单独设计其所有权，确保 Upgrade 不会间接加载 Init-only 环境检查。

## 8. 集成测试矩阵

`tests/upgrade/test.sh` 应在临时项目中使用 P3 Init 创建基线，然后使用经复制和受控变更的候选模板/源仓库夹具验证：

| 类别 | 场景 | 预期 |
|---|---|---|
| 当前版本 | 安装与候选 Bundle/Core 相同 | 零状态 no-op；无备份、无暂存、项目树和全部指纹不变。 |
| 兼容替换 | 候选版本升高且 allow-list 支持现有两种 Schema | 成功；`VERSION`、`core/`、`.themis/CLAUDE.themis.md` 等非 Workspace 内容刷新；持久备份保留。 |
| Workspace 不变性 | Workspace 含 manifest、Spec、Evidence、嵌套空目录和未知项目文件 | 前后相对树、文件类型、内容指纹及 manifest 字节完全一致。 |
| 项目指引不变 | P3 正确 `CLAUDE.md` 与 `AGENTS.md` | 两个文件升级前后逐字一致；CLAUDE marker 仍精确有效。 |
| Candidate 兼容性 | 候选不支持已安装 Workspace 或 Artifact Schema | 非零、诊断列出实际值和候选支持范围；无备份/暂存/目标写入。 |
| 可迁移但未支持 | 候选仅声明 migration descriptor | 仍拒绝且无写入；明确 P4 不迁移 Workspace。 |
| 遗留布局 | 根级 `CLAUDE.themis.md`、缺失/单边/重复/修改 marker、或缺 contained guidance | 非零，提示手动迁移；非 Workspace 内容和 Workspace 都不变。 |
| Candidate 失效 | source template 缺路径、YAML/导入/版本契约无效 | 在事务前拒绝；安装完全不变。 |
| `--dry-run` | 兼容升级和不兼容升级 | 输出动作/诊断；完整项目树、内容指纹、无备份/暂存目录均不变。 |
| 事务失败 | 在旧管理条目已备份后模拟候选移动或最终 checker 失败 | 非 Workspace 管理内容恢复到升级前；Workspace/CLAUDE/AGENTS 指纹不变；备份保留且诊断给出路径。 |
| 结构范围 | 候选新增一个非 Workspace 顶层管理条目 | 成功复制该条目；候选 `workspace/` 的任何变化均不进入目标。 |

## 9. 验证步骤

获批实现后按以下顺序验证：

```bash
bash -n bin/themis-upgrade.sh tests/upgrade/test.sh
```

```bash
shellcheck bin/themis-upgrade.sh tests/upgrade/test.sh
```

```bash
bash bin/themis-template-check.sh
```

```bash
bash tests/init-environment/test.sh
```

```bash
bash tests/template-contract/test.sh
```

```bash
bash tests/init/test.sh
```

```bash
bash tests/upgrade/test.sh
```

```bash
git diff --check
```

ShellCheck 的实际可执行路径遵循当前 Windows/Git Bash 环境配置；若其未在 `PATH`，使用已验证的安装路径。P0、P1/P2、P3 回归必须保持通过，且 Upgrade 测试需独立证明 P0 未被 source 或执行。Claude Code 的 authenticated runtime import 探针仍是 P2/P3 的独立待验证事项，不属于 P4 替换事务。

## 10. 实施结果

已落地：

- `bin/themis-upgrade.sh`：Bash 3.2 兼容的 Upgrade 入口。它独立检查 mikefarah/yq v4，且不 source Init/P0；在任何写入前校验 P3 的双直接 import 布局、候选模板（包括候选自身的 Schema 兼容性）、版本与候选 Core 对已安装 Workspace/Artifact Schema 的 allow-list 兼容性。
- 兼容升级只移动 `.themis/` 的非 `workspace/` 顶层条目到持久 `.themis-upgrade-backup.XXXXXX/managed/`，再从候选暂存区替换这些条目。`workspace/`、项目 `CLAUDE.md` 和 `AGENTS.md` 从不属于移动、复制、删除或恢复范围。
- `--dry-run` 只报告版本、Schema、兼容结论及替换/保护边界，不创建备份或暂存目录。
- 事务失败时仅删除已放入的候选管理条目，按备份恢复旧管理内容，并验证 Workspace 和 `CLAUDE.md` 指纹仍未改变；备份始终保留。一个仅测试使用的 `THEMIS_UPGRADE_TEST_FAIL_AFTER_REPLACEMENT=1` 注入点用于确定性验证这一路径。
- `tests/upgrade/test.sh`：新增 33 项隔离 TAP 集成测试，覆盖 no-op、兼容更新、新增受管 Core 内容、Workspace/Manifest/CLAUDE/AGENTS 不变性、dry-run、候选 Schema 不兼容、legacy 指引布局、修改标记块与替换后回滚。

验证结果：

- `bash -n bin/themis-upgrade.sh tests/upgrade/test.sh` 通过。
- ShellCheck 0.11.0 对 P1–P4 的脚本与测试无 findings。
- `bash bin/themis-template-check.sh` 通过且无输出。
- `bash tests/init-environment/test.sh`：P0 的 31 项测试全部通过。
- `bash tests/template-contract/test.sh`：P1/P2 的 34 项测试全部通过。
- `bash tests/init/test.sh`：P3 的 22 项测试全部通过。
- `bash tests/upgrade/test.sh`：P4 的 33 项测试全部通过。
- `git diff --check` 通过；仅输出已有 Windows 工作区的 LF/CRLF 转换警告，无 whitespace error。
