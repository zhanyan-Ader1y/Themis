# P0 — Init Environment Validation

**优先级**：P0
**依赖**：无
**状态**：已完成

## 目标

定义并提供 **Init 安装阶段**的最小前置环境契约和校验能力。该校验只在 `themis-init.sh` 运行时调用；已安装 Themis 的正常 SDD 运行流程不调用它。

## 范围

- 校验 Bash 3.2+，并规定实现不得使用 Bash 4+ 专属语法。
- 校验 Git 2.0+，用于 Git Adapter 及安装项目版本信息读取。
- 校验 [mikefarah/yq](https://github.com/mikefarah/yq)，用于 YAML 的读取、写入与验证。
- 规定缺失或版本不兼容时的诊断格式，以及 macOS、Linux、Windows Git Bash 的获取指引。
- 抽取供 **Init** 使用的 Bash 环境检测函数；Upgrade 与已安装 Themis 的运行流程不得依赖或调用此校验。

## 非范围

- 不检查、不安装、不配置 Agent 环境。
- 不检查、不申请文件系统权限。
- 不实现测试、CI、容器或语言运行时的检测；它们属于项目 Adapter 配置。
- 不实现 Init、Upgrade 或任何 Kernel 能力。

## 目标文件

- `docs/runtime-environment.md`
- 共享 Bash 运行时库（精确路径由 `impl.md` 决定）
- Init 对共享库的调用点；该库不应被 Upgrade 或已安装 Themis 的正常 SDD 执行路径加载

## 执行前置步骤

当用户主动发起本计划时，**第一步**必须在本计划目录创建或更新 `impl.md`（`docs/plan/00-runtime-environment/impl.md`），至少记录：

1. 支持的 yq 主版本与精确 CLI 语法；
2. Bash、Git、yq 的版本解析策略；
3. 共享库位置与公开函数；
4. 各平台诊断与安装提示；
5. 自动化验证矩阵。

`impl.md` 经用户确认前，不得修改目标文件。

## 验收条件

- 在 Bash 3.2+、Git 2.0+、兼容 yq 存在时，校验返回成功。
- 任一依赖缺失或版本不足时，校验以非零状态退出，并指出工具、检测值、最低版本与获取链接/建议。
- 不含 Agent 或文件系统权限检测。
- Init 可在未来调用共享检测逻辑，而已安装 Themis 的正常运行流程与 Upgrade 不调用该逻辑。

## 风险与回滚

- **风险**：不同 yq 实现或 Windows 包装脚本名称相同但语义不同。
- **缓解**：以 `yq --version` 的 mikefarah 特征和主版本双重识别。
- **回滚**：此模块只增加文档与共享库，可整体移除，不影响模板或 Workspace 数据。
