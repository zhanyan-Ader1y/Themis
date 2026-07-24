# P1 — Template Contract

**优先级**：P1
**依赖**：[P0 Init Environment Validation](../00-runtime-environment/README.md)
**状态**：已完成

## 目标

将当前目录骨架转化为 Init 与 Upgrade 都能稳定消费的版本化模板契约，使 Core、Workspace 和顶层导入路径具有明确且可验证的结构。

## 范围

- 修正模板目录拼写：`konwledge` → `knowledge`、`migations` → `migrations`。
- 定义并填充 `templates/.themis/core/core.yaml`：Core 版本、支持的 Workspace Schema、支持的 Artifact Schema、迁移入口元数据。
- 定义并填充 `templates/.themis/workspace/manifest.yaml`：Schema、项目身份、命令、Gate、Adapter、策略覆盖与路径的默认结构。
- 形成最小 `rules.md` 入口集合，使顶层或模块 `@import` 指向真实存在的文件。
- 定义模板目录自检：目录存在性、YAML 有效性、版本兼容矩阵及 import 目标存在性。

## 非范围

- 不实现 Kernel 业务规则本身；rules 文件只提供路由/边界入口。
- 不实现 Init 或 Upgrade 脚本。
- 不为具体项目填充真实 build、lint、test 命令。

## 关键设计约束

- Core Version、Workspace Schema、Artifact Schema 是独立版本维度，不应要求字面相同。
- 兼容性由 `core.yaml` 的支持矩阵判断，而不是简单文本版本比较。
- 模板必须在源仓库中即保持正确；Init 不应通过安装后的临时重命名掩盖模板错误。

## 目标文件

- `templates/.themis/core/core.yaml`
- `templates/.themis/workspace/manifest.yaml`
- `templates/.themis/core/kernel/*/rules.md`（最小入口集）
- `templates/.themis/core/migrations/` 与 `templates/.themis/core/kernel/knowledge/`（修正后目录）
- 模板自检脚本或共享校验函数（精确位置由 `impl.md` 确定）

## 执行前置步骤

当用户主动发起本计划时，**第一步**必须在本计划目录创建或更新 `impl.md`（`docs/plan/10-template-contract/impl.md`），至少记录：

1. `core.yaml` 与 `manifest.yaml` 的完整字段 Schema 和默认值；
2. 版本矩阵、兼容/可迁移/不兼容的判定规则；
3. 规则文件最小集和完整 import 图；
4. 模板自检命令与失败诊断；
5. 改名对已有安装的兼容策略。

`impl.md` 经用户确认前，不得修改目标文件。

## 验收条件

- 模板不存在 `konwledge` 或 `migations` 路径。
- Core 与 Workspace YAML 可由 P0 定义的 yq 解析和验证。
- 所有模板 `@import` 目标存在，且路径位于 `.themis/core/`。
- `core.yaml` 明确支持当前 Manifest 所声明的 Schema。
- 自检在空白新模板上成功，在损坏的 YAML 或缺失 import 上失败。

## 风险与回滚

- **风险**：过早固定 YAML Schema，限制后续模块演进。
- **缓解**：只定义启动、安装和升级所需的最小稳定字段；Schema 用显式版本扩展。
- **回滚**：在进行结构性重命名或 YAML 写入前创建模板快照；不触碰已安装项目的 Workspace。
