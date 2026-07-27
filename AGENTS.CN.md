# 项目

Themis 是一个 SDD Harness 框架，将本地 AI 编码系统安装到工程项目中，并实现受治理的项目知识积累。

本文件定义 Agent 的仓库工作约定。Themis 设计规范的唯一权威来源是 [`docs/design/README.md`](docs/design/README.md)；不要在此重复详细产品设计。

## 设计入口

修改行为或契约前，读取与任务相关的设计页：

- [设计权威与文档状态](docs/design/README.md)
- [设计治理与证据](docs/design/governance.md)
- [总体架构与领域所有权](docs/design/architecture.md)
- [生命周期与路由](docs/design/workflow.md)
- [Core 与 Workspace 模块索引](docs/design/README.md#设计导航)

若实现、模板、测试或已观察输出与设计冲突，报告漂移，并更新所属设计页或计划。不得声称未观察到的能力已经存在。

## 计划执行

- 计划文档不是实现授权。用户必须明确发起计划。
- 计划实施的第一步是在 `docs/plan/<priority>-<slug>/impl.md` 中记录决策、任务、目标文件和验证矩阵。
- 在用户确认该计划的 `impl.md` 前，不得修改其实现文件。
- 每个计划拥有自己的目录和实施记录。大型工作应在该目录中拆分为聚焦段落。

## 文档维护

- `README.md` 是项目介绍和顶层导航。
- `docs/README.md` 是文档门户。
- 已确认的设计变更必须在同一次变更中更新 `docs/design/**` 下的所属文件。
- 计划、分析、模板、策略、Prompt 和变更日志可以链接设计规则，但不得形成第二个规范来源。
- 保持实现状态和证据链接准确。保留历史计划；规则被替代时添加 superseded 注记，不改写原始决策。
- 旧 `docs/core/`、`docs/workspace/`、`docs/workflow.md` 和 `docs/runtime-environment.md` 路径仅为兼容指针。
- `AGENTS.md` 与 `AGENTS.CN.md` 必须在同一次变更中保持语义同步。

## 脚本文档

- 每个 Shell 脚本必须包含中文注释，解释用途、操作边界和非显而易见的行为。
- 公共函数和主要验证或控制流段落必须记录其行为及必要的输入或输出。
- 实现变化时保持注释准确。
- 除非已批准计划修改运行时契约，否则保持 Bash 3.2 兼容。
- 对修改的 Shell 脚本运行 Bash 语法检查和 ShellCheck。

## 验证

- Core 契约新增必需文件、标识符、标题、策略形状、import 或行数预算时，同步扩展确定性模板检查和隔离回归夹具。
- Core 变更后运行受影响的模板、Init、Upgrade、Migration 和模块测试。
- 实现工作完成后执行 `git diff --check` 并检查最终工作树。
- 未实际观察到输出，不得声称检查通过。
