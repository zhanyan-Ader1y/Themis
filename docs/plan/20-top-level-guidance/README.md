# P2 — Top-level Guidance

**优先级**：P2
**依赖**：[P1 Template Contract](../10-template-contract/README.md)
**状态**：已完成（Claude Code 运行时 import 探针待认证环境复核）

## 目标

将 `templates/.themis/CLAUDE.themis.md` 建设为安装项目中的精简 SDD 指引：明确工作边界与生命周期路由；Init 将其与 Core Orchestrator 的直接 import 追加到项目 `CLAUDE.md`，而不重复完整 WIKI。

## 范围

- 使用 P1 已验证存在的 `@import` 入口。
- 说明 Core 只读、Workspace 可读写、模板与实例分离、Upgrade 不覆盖 Workspace。
- 提供 Specification、Planning、Implementation、Verification、Review 的简明操作路由。
- 提供关键目录及模块规则文件的速查表。
- 定义 Init 的集成策略：Themis 管理指引位于 `.themis/CLAUDE.themis.md`；Init 总在项目 `CLAUDE.md` 末尾写入可逆标记区块，直接 import 该指引和 `.themis/core/kernel/orchestrator/rules.md`；检测到 `AGENTS.md` 时仅提示其优先级，不改写该文件。

## 非范围

- 不复制 `docs/` 的完整模块定义。
- 不实现模块具体控制逻辑。
- 不修改用户既有 `AGENTS.md`；Init 对 `CLAUDE.md` 的唯一受限修改是末尾的 Themis 标记区块。

## 目标文件

- `templates/.themis/CLAUDE.themis.md`
- P1 建立的规则入口文件
- 未来 Init 的指导文件安装/合并逻辑（由 P3 实现）

## 执行前置步骤

当用户主动发起本计划时，**第一步**必须在本计划目录创建或更新 `impl.md`（`docs/plan/20-top-level-guidance/impl.md`），至少记录：

1. 经实际验证的 Claude Code `@import` 解析约束；
2. 顶层入口到各规则文件的 import 图；
3. 指引正文大纲和允许的篇幅；
4. 独立文件、显式合并、已有 AGENTS 三种安装场景；
5. 入口有效性测试方法。

`impl.md` 经用户确认前，不得修改目标文件。

## 验收条件

- 每个 `@import` 都能解析到 P1 已存在的文件。
- 顶层文件不包含项目专有内容。
- 文件明确 Core/Workspace 写入边界及 SDD 阶段路由。
- 对已有 `CLAUDE.md` 的合并具备唯一标记、重复检测与可逆性设计。

## 风险与回滚

- **风险**：错误或过深的 import 导致 Claude Code 不能加载完整指引。
- **缓解**：P1 先提供 import 自检，并在本模块执行时进行加载验证。
- **回滚**：独立 `CLAUDE.themis.md` 可直接删除；合并块仅按唯一标记删除，不重写用户其余内容。
