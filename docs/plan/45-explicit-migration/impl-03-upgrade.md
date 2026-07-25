# P4.5 子模块：P4 衔接

## 覆盖任务

- 任务 5：`bin/themis-upgrade.sh` 微调（诊断输出增加迁移提示）

## 设计依据

- D1：不修改 P4 事务逻辑，仅微调诊断文本
- D3：P4 拒绝升级时，如果候选 Core 有迁移描述符，提示用户可用 `themis-migrate.sh`

## 目标文件：`bin/themis-upgrade.sh`

**路径**：`bin/themis-upgrade.sh`

### 变更内容

**仅修改两处诊断文本**，不改变任何逻辑、退出码、事务流程或测试行为。

#### 变更 1：Workspace Schema 不兼容（约第 348 行）

当前：
```bash
themis_upgrade_error 'incompatible Workspace schema' \
  "Installed ${THEMIS_UPGRADE_WORKSPACE_SCHEMA}; candidate ${THEMIS_UPGRADE_CANDIDATE_CORE_VERSION} supports ${THEMIS_UPGRADE_WORKSPACE_SUPPORTED}. P4 does not run migrations."
```

改为：
```bash
themis_upgrade_error 'incompatible Workspace schema' \
  "Installed ${THEMIS_UPGRADE_WORKSPACE_SCHEMA}; candidate ${THEMIS_UPGRADE_CANDIDATE_CORE_VERSION} supports ${THEMIS_UPGRADE_WORKSPACE_SUPPORTED}. P4 does not run migrations. If a migration descriptor exists for this schema, run 'themis-migrate.sh <target> --check' to see available migration paths."
```

#### 变更 2：Artifact Schema 不兼容（约第 353 行）

当前：
```bash
themis_upgrade_error 'incompatible Artifact schema' \
  "Installed ${THEMIS_UPGRADE_ARTIFACT_SCHEMA}; candidate ${THEMIS_UPGRADE_CANDIDATE_CORE_VERSION} supports ${THEMIS_UPGRADE_ARTIFACT_SUPPORTED}. P4 does not run migrations."
```

改为：
```bash
themis_upgrade_error 'incompatible Artifact schema' \
  "Installed ${THEMIS_UPGRADE_ARTIFACT_SCHEMA}; candidate ${THEMIS_UPGRADE_CANDIDATE_CORE_VERSION} supports ${THEMIS_UPGRADE_ARTIFACT_SUPPORTED}. P4 does not run migrations. If a migration descriptor exists for this schema, run 'themis-migrate.sh <target> --check' to see available migration paths."
```

### 不变更内容

- 退出码（仍然为 1）
- 事务逻辑（仍然不执行迁移）
- 其他所有函数和诊断
- 拓扑结构、变量名和注释

### 验证关键

变更后必须确认 P4 的 33 项 TAP 测试全部通过。测试中对诊断文本的断言使用了 `assert_output_contains`（子串匹配），新增文本仅追加在原有诊断末尾，不影响已有匹配：

```bash
# tests/upgrade/test.sh:234 — 仍匹配原有诊断前缀
assert_output_contains 'incompatible Workspace schema' \
  'incompatible Workspace schema rejects upgrade'
```

需要验证原有断言仍通过，且新文本可以通过 `grep "themis-migrate"` 确认存在。
