# P4.5 实施索引

本文档是 P4.5（Explicit Migration）的实施总索引。

## 设计决策

| # | 决策 | 结论 |
|---|---|---|
| D1 | 独立脚本 vs 修改 P4 | 新建 `themis-migrate.sh`，P4 仅增加一行诊断提示 |
| D2 | 脚本/Prompt 拆分 | 备份、迁移调用、验证、回滚 → 脚本；用户确认、报告解读 → Prompt |
| D3 | 迁移入口 | P4 诊断 + 独立迁移命令 |
| D4 | 幂等性 | 每步迁移检查目标状态，已完成则跳过 |

## 子模块段落

| 段落 | 文件 | 覆盖任务 | 说明 |
|---|---|---|---|
| 迁移策略 | [impl-01-policies.md](impl-01-policies.md) | migration.yaml + migrations 规则 | 安全约束、备份路径、验证步骤 |
| 迁移执行 | [impl-02-execution.md](impl-02-execution.md) | migration-execution.md + themis-migrate.sh | Prompt 模板 + 脚本设计 |
| P4 衔接 | [impl-03-upgrade.md](impl-03-upgrade.md) | themis-upgrade.sh 微调 | 诊断输出增加迁移可用提示 |
| 测试与文档 | [impl-04-tests.md](impl-04-tests.md) | test.sh + docs 更新 | 集成测试 + WIKI 同步 |

## 目标文件清单

| # | 文件 | 操作 | 所属段落 |
|---|---|---|---|
| 1 | `templates/.themis/core/policies/migration.yaml` | 新建 | impl-01 |
| 2 | `templates/.themis/core/templates/migration-execution.md` | 新建 | impl-02 |
| 3 | `templates/.themis/core/kernel/migrations.md` | 新建 | impl-01 |
| 4 | `bin/themis-migrate.sh` | 新建 | impl-02 |
| 5 | `bin/themis-upgrade.sh` | 微调 | impl-03 |
| 6 | `docs/core/migrations.md` | 更新 | impl-04 |
| 7 | `tests/migrate/test.sh` | 新建 | impl-04 |

## 执行顺序

1. **impl-01**（migration.yaml + kernel/migrations.md）— 策略和规则基础
2. **impl-02**（migration-execution.md + themis-migrate.sh）— 依赖 impl-01
3. **impl-03**（themis-upgrade.sh 微调）— 独立，可并行
4. **impl-04**（test.sh + docs）— 依赖 impl-02、impl-03

## 验证矩阵

| # | 验证项 | 验证方式 | 预期结果 |
|---|---|---|---|
| V1 | migration.yaml 语法合法 | `yq eval '.'` | 通过 |
| V2 | migration.yaml 定义 5 项安全约束 | yq 检查 | 备份/原子/幂等/显式确认/可追溯 |
| V3 | themis-migrate.sh 语法合法 | `bash -n` | 通过 |
| V4 | migration-execution.md 含脚本声明块 | 手动检查 | 4 个脚本行 + Fallback 列 |
| V5 | P4 的 33 项测试保持通过 | `bash tests/upgrade/test.sh` | 33/33 通过 |
| V6 | 迁移 no-op（无匹配迁移描述符）退出 0 | TAP 测试 | 无文件写入 |
| V7 | 迁移备份在验证失败时回滚 | TAP 测试 | Workspace 指纹不变 |
| V8 | `--dry-run` 不写入任何文件 | TAP 测试 | 零文件系统变更 |
| V9 | P4 诊断输出含迁移可用提示 | `grep "themis-migrate"` 扫描 upgrade.sh 输出 | 存在 |
| V10 | ShellCheck 无 findings | `shellcheck bin/themis-migrate.sh` | 通过 |
| V11 | docs 与 migration.yaml 描述一致 | 手动对比 | 无矛盾 |
