# P4.5 — Explicit Migration（显式迁移）

**优先级**：P4.5（P4 Upgrade 的补充能力）
**依赖**：[P1 Template Contract](../10-template-contract/README.md)、[P4 Upgrade](../40-upgrade/README.md)
**状态**：已完成；当前实现边界见 [Migrations 正式规范](../../design/core/migrations.md)

## 背景

P4 Upgrade 的当前行为：

- Workspace / Artifact Schema 在候选 Core 的 `supported[]` allow-list 中 → 直接升级
- Schema 不在 allow-list 中 → **拒绝，输出诊断，提示"P4 does not run migrations"**

`docs/core/migrations.md` 已定义了迁移的完整理论模型（备份→迁移→验证→回滚），但 Upgrade 脚本中缺少执行路径。用户在收到拒绝诊断后，只能手动处理 Schema 和工件格式变更。

P4.5 的目标是：当 P4 拒绝升级时，如果候选 Core 声明了迁移描述符，提供一个**独立于 P4 的显式迁移执行器**，由用户显式触发。

## 核心设计决策

### 决策 1：独立脚本 vs 修改 P4

**选择**：新增独立脚本 `bin/themis-migrate.sh`，不修改 `bin/themis-upgrade.sh`。

**理由**：
- P4 的"拒绝且不执行迁移"是已实施且已验证的安全边界，不应被破坏
- 迁移是独立的用户决策，不应与升级事务耦合
- Upgrade 的 33 项测试保持通过，迁移有独立的测试套件
- P4 的诊断输出可以增加一行提示："A migration is available. Run `themis-migrate.sh` to execute it."

### 决策 2：脚本/Prompt 拆分（按 Themis 执行模型）

| 步骤 | 实现方式 | 理由 |
|---|---|---|
| 兼容性检查（migration descriptor 查询） | **脚本** | 从 core.yaml 读取迁移描述符，确定性 YAML 解析 |
| Workspace 备份 | **脚本** | 纯文件复制操作（`cp -R`），确定性 |
| 执行迁移脚本（v1-to-v2.sh 等） | **脚本** | 迁移脚本本身就是 Shell，在 core.yaml 的 `path` 中已声明 |
| 迁移后验证（目录结构、工件格式、索引） | **脚本** | 结构完整性检查可逐项用 `find`/`yq`/`diff` 验证 |
| Workspace 恢复（回滚） | **脚本** | 从备份恢复，确定性 |
| 用户确认门禁（迁移前、每步后） | **Prompt** | 人类决策，不可自动化 |
| 迁移报告解读 | **Prompt** | AI 解释验证输出并给出建议 |
| 具体迁移脚本的编写（v1-to-v2.sh 等） | 非本次范围 | 属于 Core 版本发布的一部分 |

### 决策 3：迁移流程入口

```
P4 Upgrade 拒绝升级（Schema incompatible）
    │
    ├── 候选 Core 无迁移描述符 → 拒绝（行为不变）
    │
    └── 候选 Core 有迁移描述符 → 输出附加提示：
        "A migration is available: workspace/artifacts schema can be migrated
         from <current> to <target>. Run 'themis-migrate.sh <target>' to
         execute the explicit migration."
```

`themis-migrate.sh` 是独立入口，不与 `themis-upgrade.sh` 共享事务逻辑。两者仅共享 `themis-template-check.sh`（候选模板验证）。

## 迁移流程

```
1. 迁移前检查（脚本: themis-migrate.sh）
   ├── 读取 core/core.yaml 的 compatibility.*.migrations[]
   ├── 匹配已安装的 Workspace/Artifact Schema → 找到迁移描述符
   ├── 匹配失败 → 拒绝，输出已安装版本和候选支持范围
   └── 匹配成功 → 输出将要执行的迁移步骤

2. 用户确认（Prompt 门禁）
   ├── 展示迁移描述符内容（from → to, 迁移脚本路径, reversible）
   ├── 用户必须明确输入确认
   └── 用户拒绝 → 退出，零写入

3. Workspace 备份（脚本: themis-migrate.sh）
   ├── 创建持久备份: <target>/.themis-migration-backup.XXXXXX/
   ├── 完整复制 workspace/ 到备份目录
   └── 记录备份路径、迁移前版本信息

4. 执行迁移（脚本: 调用 core/migrations/*.sh）
   ├── 按 dependency 顺序执行迁移脚本
   ├── 每个迁移脚本:
   │     ├── 接收 workspace/ 路径作为参数
   │     ├── 执行确定性文件操作（目录创建、字段更新、格式转换）
   │     └── 输出 JSON: {status, changed_files[], errors[]}
   ├── 更新 manifest.yaml 中的 workspace_schema / artifact_schema
   └── 生成迁移报告 (migration-report.json)

5. 迁移后验证（脚本: themis-migrate.sh --verify）
   ├── 目录结构完整性（与模板骨架对比）
   ├── 工件格式正确性（yq 语法检查）
   ├── 索引一致性（context-map 引用有效）
   └── 失败 → 从备份回滚

6. 完成（脚本）
   ├── 记录迁移日志到 workspace/state/migration_log/
   └── 保留备份直到用户确认迁移成功
```

## 迁移安全约束

| 约束 | 实现方式 |
|---|---|
| 备份优先 | 脚本: 迁移前 `cp -R workspace/ backup/`，备份路径写入日志 |
| 原子性 | 脚本: 全部成功或 `cp -R backup/workspace/ workspace/` 恢复 |
| 幂等性 | 脚本: 每步迁移检查目标状态，已完成则跳过 |
| 显式确认 | Prompt: 迁移前和每步迁移后要求用户输入 |
| 可追溯 | 脚本: migration-report.json + workspace/state/migration_log/ |

## 迁移描述符格式（已有，不修改）

```yaml
# core/core.yaml
compatibility:
  workspace:
    supported: [themis-workspace/v1]
    migrations:
      - from: themis-workspace/v1
        to: themis-workspace/v2
        path: migrations/workspace/v1-to-v2.sh
        reversible: true
```

迁移脚本 `migrations/workspace/v1-to-v2.sh` 在模板中提供，由 P4 的 Upgrade 复制到已安装项目中。P4.5 的迁移执行器按 `path` 调用这些脚本。

## 目标文件

| # | 文件 | 操作 | 说明 |
|---|---|---|---|
| 1 | `templates/.themis/core/policies/migration.yaml` | 新建 | 迁移安全约束、备份路径、验证步骤 |
| 2 | `templates/.themis/core/templates/migration-execution.md` | 新建 | Prompt 模板（用户确认引导 + 报告解读）；含脚本声明块 |
| 3 | `templates/.themis/core/kernel/migrations.md` | 新建 | 迁移模块规则（当前不存在，需新增） |
| 4 | `bin/themis-migrate.sh` | 新建 | 迁移执行器（兼容性检查 + 备份 + 调用迁移脚本 + 验证 + 回滚） |
| 5 | `bin/themis-upgrade.sh` | 微调 | 诊断输出增加一行："Migration available. Run themis-migrate.sh." |
| 6 | `docs/core/migrations.md` | 更新 | 同步 WIKI（增加脚本/Prompt 拆分说明） |
| 7 | `tests/migrate/test.sh` | 新建 | 隔离 TAP 集成测试 |

## 验收条件

- `themis-migrate.sh` 在 Schema 兼容时 no-op（迁移描述符不匹配）
- `themis-migrate.sh` 在有匹配迁移描述符时执行完整 5 步流程
- 迁移前创建完整 Workspace 备份
- 迁移验证失败时从备份回滚，Workspace 指纹不变
- P4 的 33 项测试保持全部通过（Upgrade 诊断输出微调后）
- `--dry-run` 不写入任何文件
- 每个迁移步骤在执行前要求用户确认（Prompt 门禁）

## 非范围

- 不编写具体的迁移脚本（如 v1-to-v2.sh）——这些是 Core 版本发布的一部分
- 不实现自动迁移——迁移必须由用户显式触发
- 不修改 P4 Upgrade 的事务逻辑
- 不修改 Workspace 目录结构（已由 P1 定义）

## 风险与回滚

- **风险**：迁移脚本错误导致 Workspace 损坏 → **缓解**：备份优先 + 原子回滚
- **风险**：用户在不兼容的迁移脚本间跳跃 → **缓解**：迁移执行器按 `from → to` 精确匹配，跳过不匹配的迁移
- **回滚**：从备份恢复 Workspace，删除迁移日志，移除新增文件
