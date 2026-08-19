# QA.md — core-removal

格式与收敛判据见 `rules.md` §2。

## 第 1 轮

### 问

1.（Why）本次删除 `templates/.themis/core/` 的直接触发条件，是否就是"本次 replay 走完并在 R3 获批"本身，还是您认为还需要其他前置确认（例如先核实没有本仓库之外的项目仍依赖 `core/` 的路径）？
2.（期望结果）"来源引用"列出的六处活跃引用中，`templates/.themis/CLAUDE.themis.md`、`templates/.themis/README.md` 断链后，您期望的处理方式是"重写为不含 `core/` 的版本"还是"整节删除对应条目"？两处是否要求一致的处理方式？
3.（期望结果）`templates/.themis/spec/README.md`（本次要改的安装包源）与只读控制面 `.themis/spec/README.md`（replay 正依据的副本）出现分歧后，是本次一并同步更新包源文件，还是保留分歧、等待下一次独立的安装动作统一？
4.（核心链路 / 范围）除"来源引用"列出的六处 `templates/.themis/` 活跃引用外，`docs/` 下另有约 36 个文件、396 行历史文档（`docs/plan/35-core-prompt-flow/`、`docs/superpowers/plans/`、`docs/superpowers/specs/` 等 Plan 35 证据记录）也引用 `core/` 路径。这些历史引用是否需要在本次一并处理（例如加注"已删除"），还是明确排除在本次范围之外，留作历史证据保持原样？

### 答

待所有者答复

### 来源

待定
