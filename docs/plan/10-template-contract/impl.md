# P1 实施设计 — Template Contract

**关联计划**：[P1 — Template Contract](README.md)
**状态**：设计已批准，实施中
**实施边界**：仅将源仓库中未安装的 `.themis` 模板固化为最小、可版本化、可自检的 Core/Workspace 契约；不实现 Init、Upgrade、命令、业务规则、执行期 Shell 操作或已安装项目迁移。

## 1. 决策与约束

| 决策 | 结论 |
|---|---|
| 模板版本 | `.themis/VERSION` 是模板包发布版本，当前为 `0.1.0`，必须与 `core.core_version` 相同。 |
| Schema 独立性 | Workspace Schema 和 Artifact Schema 与 Core 版本独立；它们不要求等于 `0.1.0` 或彼此相等。 |
| 兼容性判定 | Core 对 Workspace、Artifact 两个维度分别使用 allow-list；命中 `supported` 为兼容，命中迁移描述为可迁移，其他为不兼容。 |
| 迁移 | P1 只声明 `migrations/workspace`、`migrations/artifacts` 根目录与空迁移列表；P4 才决定已安装项目的探测、备份、执行及回滚。 |
| Workspace 默认值 | 不假定目标项目的技术栈：命令为 `null`，Gate 为空列表，Adapter 与策略覆盖为空映射。 |
| 规则入口 | 为 8 个 Kernel 模块建立范围受限的 `rules.md`；不写入工作流、Agent 提示、Shell 调用或项目专有内容。 |
| 顶层导入 | P1 仅将 `CLAUDE.themis.md` 的路径机械修正为真实 Core 入口；P2 负责完整顶层指引和 Claude Code 实际加载验证。 |
| 自检 | 新增 Bash 3.2 兼容的源仓库检查器；其直接使用 mikefarah/yq v4，不得 source P0 的 Init 私有库。 |

## 2. 文件与职责

| 文件或目录 | 操作 | 职责 |
|---|---|---|
| `templates/.themis/core/core.yaml` | 填充 | 声明 Core 版本、两个 Schema 维度的兼容矩阵和迁移根目录。 |
| `templates/.themis/workspace/manifest.yaml` | 填充 | 提供项目中立的 Workspace v1 默认契约。 |
| `templates/.themis/VERSION` | 保持 | 模板包版本；检查器确认它与 `core_version` 相等。 |
| `templates/.themis/core/migrations/{workspace,artifacts}/` | 改名/新建 | 更正 `migations`，并创建与 Core 元数据一致的迁移根目录。 |
| `templates/.themis/core/kernel/knowledge/` | 改名 | 更正 `konwledge`。 |
| `templates/.themis/core/kernel/*/rules.md` | 新建 | 为 8 个 Kernel 模块提供最小、可导入的边界入口。 |
| `templates/CLAUDE.themis.md` | 单行修正 | 指向 `.themis/core/kernel/orchestrator/rules.md`。 |
| `bin/themis-template-check.sh` | 新建 | 验证未安装模板的结构、YAML、版本矩阵和 import 图。 |
| `tests/template-contract/test.sh` | 新建 | 使用临时模板副本和 yq v4 夹具覆盖成功与失败分支。 |
| `docs/README.md` | 修正 | 移除“三个版本必须相同”的错误说明，记录独立版本与兼容矩阵关系。 |
| `CHANGES.md` | 完成后更新 | 只在实现及验证完成后记录 P1 交付。 |

除上表文件外，不修改 Init、Upgrade、`.claude/commands/`、具体 Core 协议/策略/工件模板，或任何已安装项目的 Workspace。

## 3. YAML 契约

### `core/core.yaml`

```yaml
core_schema: themis-core/v1
core_version: 0.1.0
compatibility:
  workspace:
    supported: [themis-workspace/v1]
    migrations: []
  artifact:
    supported: [themis-artifact/v1]
    migrations: []
migration_roots:
  workspace: migrations/workspace
  artifacts: migrations/artifacts
```

字段语义：

- `core_schema` 是 Core 元数据本身的 Schema 标识，P1 只接受 `themis-core/v1`。
- `core_version` 是 Core 发布版本；必须与模板根 `VERSION` 的单行值相同。
- `compatibility.workspace` 和 `compatibility.artifact` 必须分别存在，且分别保存字符串 `supported` 列表与 `migrations` 列表。
- 后续迁移描述符属于 P4，最小形状为 `from_schema`、`to_schema`、`script`；`script` 必须是匹配维度迁移根目录下的相对路径。首次模板不包含历史 Schema，因此两份列表为空。
- `migration_roots` 固定为相对于 `core/` 的 `migrations/workspace` 与 `migrations/artifacts`，且目录必须存在。

### `workspace/manifest.yaml`

```yaml
workspace_schema: themis-workspace/v1
artifact_schema: themis-artifact/v1
project:
  name: ""
  root: "."
commands:
  lint: null
  build: null
  test: null
context:
  entry_points: []
  external_sources: []
gates: []
adapters: {}
policy_overrides: {}
paths:
  policies: workspace/policies
  context: workspace/context
  specs: workspace/specs
  state: workspace/state
  runs: workspace/runs
  evidence: workspace/evidence
  outcomes: workspace/outcomes
  knowledge: workspace/knowledge
  cache: workspace/cache
```

- `project.name` 保留空字符串，禁止把 Themis 或示例项目误写为项目身份；`project.root` 固定为模板安装根 `.`。
- `commands` 中的 `null` 表示“尚未由项目配置”，而不是可执行的空命令。
- `gates: []` 不会触发任何默认 Gate；P3 或项目维护者填入实际能力后，后续 Verification 才可执行。
- `paths` 是完整 Workspace 目录契约，值不以尾部 `/` 区分语义。

## 4. 规则文件与 import 图

P1 建立以下八个真实入口：

```text
core/kernel/orchestrator/rules.md
core/kernel/specification/rules.md
core/kernel/planning/rules.md
core/kernel/context/rules.md
core/kernel/verification/rules.md
core/kernel/review/rules.md
core/kernel/attribution/rules.md
core/kernel/knowledge/rules.md
```

每个文件只描述其所属模块的职责、是否读取/写入 Workspace 以及具体流程尚属后续计划；它不能重复完整 WIKI 或改变状态。

```text
CLAUDE.themis.md
  └── .themis/core/kernel/orchestrator/rules.md
        ├── ../specification/rules.md
        ├── ../planning/rules.md
        ├── ../context/rules.md
        ├── ../verification/rules.md
        ├── ../review/rules.md
        └── ../knowledge/rules.md

attribution/rules.md 仅作为按需入口，不进入基线 orchestrator 导入链。
```

P1 只检查每个目标文件存在、Core 内部导入未越出 `core/`。P2 负责补充顶层正文与验证 Claude Code 对该图的实际解析行为。

## 5. 模板自检设计

### 命令契约

```bash
bash bin/themis-template-check.sh [template-root]
```

- 不带参数时，检查源仓库的 `templates/.themis`。
- 指定参数时，检查传入的临时模板根，供测试夹具安全地损坏副本。
- 成功时返回 `0` 且保持静默；失败时返回非零并向 stderr 输出一项稳定、可操作的 `Themis template contract failed: <subject>` 诊断。
- 它不写入文件、不安装工具、不运行项目命令、不读取或写入 Workspace 实例，也不加载 `_themis-init-env.sh`。

### 检查顺序

1. 解析模板根、Core 与 Workspace 路径，并确认目录、`VERSION`、两份 YAML、迁移根和八个 `rules.md` 均存在。
2. 拒绝仍存在的 `core/migations` 或 `core/kernel/konwledge` 旧路径。
3. 确认 `yq` 可用并以 `yq eval` 读取 YAML；读取或解析失败即停止。
4. 验证 `VERSION`/`core_version`、Core Schema、Manifest Schema、要求的对象/数组/映射字段和路径字面量。
5. 依据 `compatibility.workspace` 与 `compatibility.artifact` 分别判定 Manifest 的两个 Schema：支持为成功；符合迁移描述符为可迁移而非成功；其他为失败。
6. 解析所有模板 Markdown 中的 `@import`，确认顶层路径真实存在；对 Core 内部路径再确认规范化后的目标仍位于 `core/` 中。

脚本使用 Bash 3.2 语法和 yq v4 的 `yq eval`。所有函数、诊断、非显然的路径处理及失败短路均按 `AGENTS.md` 的注释标准说明目的与边界。

### 测试矩阵

测试脚本将复制 `templates/.themis` 与 `templates/CLAUDE.themis.md` 到临时目录，在复制品上逐项破坏：

| 场景 | 预期 |
|---|---|
| 原始模板 | 返回 0、无输出 |
| Core YAML 语法损坏 | 非零，报告 Core YAML 不可读取 |
| Manifest 缺必填 Schema | 非零，报告缺少字段 |
| `VERSION` 与 `core_version` 不同 | 非零，报告 Bundle/Core 版本不匹配 |
| Workspace Schema 不受支持 | 非零，报告不兼容 |
| 命中合法迁移描述符 | 非零，报告显式迁移需要（不自动迁移） |
| 迁移脚本位于错误根目录 | 非零，报告 migration 根目录不匹配 |
| 保留旧拼写目录 | 非零，报告 legacy 路径 |
| 删除导入目标 | 非零，报告缺少 import 目标 |
| Core 内部导入越出 `core/` | 非零，报告不安全 import |

## 6. 实施任务

1. 记录本设计并经用户批准后，填充两份 YAML，更新 WIKI 的版本模型说明。
2. 以移动而非复制的方式修正两个模板目录；建立两个迁移子目录并添加必要目录标记。
3. 新建八个范围受限的 Kernel 规则入口，修正顶层单行 import。
4. 实现带完整注释的 `themis-template-check.sh`，不复用或违反 P0 的 Init 专用环境检查边界。
5. 新建可清理临时目录的测试夹具，覆盖上述矩阵。
6. 执行 Bash、ShellCheck、yq、测试、import 和 diff 验证；将实际结果回填到“实施结果”。

## 7. 验证矩阵

| 类别 | 命令或检查 | 预期 |
|---|---|---|
| Bash 语法 | `bash -n bin/themis-template-check.sh tests/template-contract/test.sh` | 通过 |
| Shell 静态检查 | ShellCheck 检查新增两个 Bash 文件 | 无 findings |
| 完整契约 | `bash tests/template-contract/test.sh` | 所有 TAP 断言通过 |
| YAML 读取 | yq v4 读取 `core.yaml`、`manifest.yaml` | 字段可解析，Core 支持两项 Manifest Schema |
| 目录/拼写 | 搜索模板树 | 不含 `konwledge` 或 `migations` |
| 导入 | 对所有模板 `@import` 解析目标 | 顶层入口与 6 条 Core 内部 import 均存在，内部路径不越界 |
| 边界 | 搜索新增脚本引用 | 不 source P0、未触及 Init/Upgrade/已安装 Workspace |
| 补丁卫生 | `git diff --check` | 通过 |

## 8. 风险与回滚

- **Schema 过早固化**：仅定义安装、加载兼容性和目录契约必需字段；后续变化通过显式 Schema 版本演进。
- **默认命令误执行**：所有项目工具链字段以 `null` 或空集合表达“尚未配置”。
- **版本概念混淆**：只要求 Bundle 与 Core release 对齐；两个 Schema 独立以兼容矩阵判断。
- **导入越界或断链**：自检将所有模板 import 的目标存在性与 Core 内部路径边界设为硬失败。
- **迁移伤及项目内容**：P1 不含迁移可执行文件，也不读取或写入任何已安装 Workspace；P4 保留备份、确认与回滚责任。
- **回滚**：模板仍未安装时，可回退本次源模板、检查器及测试变更；不涉及用户数据恢复。

## 9. 实施结果

已落地：

- `templates/.themis/core/core.yaml`：Core v1 元数据、Workspace/Artifact 独立兼容矩阵与迁移根目录。
- `templates/.themis/workspace/manifest.yaml`：不预设项目工具链的 Workspace v1 默认契约。
- `templates/.themis/core/migrations/{workspace,artifacts}/` 与 `templates/.themis/core/kernel/knowledge/`：已修正两处模板拼写，并保留空目录标记。
- 8 个 `templates/.themis/core/kernel/*/rules.md` 最小范围入口；orchestrator 导入 6 个活动领域入口，Attribution 保持按需入口。
- `templates/CLAUDE.themis.md`：已机械修正到真实的 Core orchestrator 入口；完整顶层指引仍由 P2 负责。
- `bin/themis-template-check.sh` 与 `tests/template-contract/test.sh`：Bash 3.2 兼容的只读自检和隔离夹具测试。
- `docs/README.md`：已澄清 Bundle/Core 版本一致、Workspace/Artifact Schema 独立并按 allow-list 兼容的模型。
- **P5/P6 模板目录**：`templates/.themis/workspace/context/architecture/behavior-map/`（P6 行为地图存储）、`templates/.themis/workspace/context/{domain,engineering,decisions,pitfalls,glossary,external}/`（Workspace 上下文子目录）、`templates/.themis/core/adapters/schema/behavior-extractor/`（P6 静态分析 Adapter）。均以 `.gitkeep` 标记，自检已包含这些路径。

验证结果：

- `bash -n bin/themis-template-check.sh tests/template-contract/test.sh` 通过。
- ShellCheck 0.11.0 对新增两个 Bash 文件无 findings。
- `bash bin/themis-template-check.sh` 对源模板成功且无输出。
- `bash tests/template-contract/test.sh` 的 22 项成功、损坏 YAML、缺失字段、版本不匹配、兼容/可迁移 Schema、错误迁移根目录、遗留拼写、导入缺失与 Core 越界导入测试全部通过。
- mikefarah/yq v4.53.3 已成功读取两份 YAML；`core.yaml` 分别声明支持 Manifest 的 Workspace 与 Artifact Schema。
- 搜索确认不保留 `konwledge` 或 `migations`，共有 8 个 Kernel 规则入口、6 条 orchestrator Core 内部导入和 1 条修正后的顶层导入。
- 新检查器未 source P0 的 `_themis-init-env.sh`，未修改 Init、Upgrade 或任何已安装 Workspace 行为。
- `git diff --check` 通过。
