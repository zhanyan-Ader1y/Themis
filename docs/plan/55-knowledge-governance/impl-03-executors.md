# P5.5 / impl-03 — 确定性执行器

## 目标

提供可安装、Bash 3.2 兼容的 Knowledge Governance Runtime 脚本。脚本只处理结构、摘要、路径、锁、持久化、批准校验、索引和回滚；不判断知识是否正确、有价值或语义等价。

## 安装位置

```text
core/bin/themis-knowledge-record.sh
core/bin/themis-knowledge-lint.sh
core/bin/themis-knowledge-apply.sh
```

源模板位置为 `templates/.themis/core/bin/`。fresh Init 安装完整 Core；当前不存在原地 Core 更新入口，也无需另建根级安装入口。

所有脚本必须：

- 使用中文注释说明用途、边界和非显然控制流；
- 保持 Bash 3.2 兼容；
- 使用 mikefarah/yq v4 解析 JSON/YAML；
- 对 Agent 消费的正常结果输出单个 JSON 对象；
- 将人类诊断写入 stderr；
- 不 source 或调用 P0 Init 环境校验；
- 拒绝 `..`、外部绝对路径、符号链接穿越和任何解析后落在 `--workspace` 根之外的输入或输出路径；apply/lint 必须覆盖 action 的 `inputs`、`outputs`、evidence refs 和所有目标路径。

## `themis-knowledge-record.sh`

### CLI

```text
themis-knowledge-record.sh candidate --workspace <root> --input <json-file>
themis-knowledge-record.sh review --workspace <root> --input <json-file>
themis-knowledge-record.sh --help
```

### Candidate 行为

1. 验证输入字段和枚举。
2. 拒绝缺失或为空的 `project`、`workspace_root`、`source_revision`、`source.evidence`，并校验 Workspace 绑定。
3. 规范化不含 `created_at` 的语义 payload。
4. 使用 `git hash-object --stdin` 计算完整摘要。
5. 生成 `KNC-<digest>` 和目标路径。
6. 若同 ID 文件存在且摘要一致，返回 `unchanged`。
7. 若同 ID 文件存在但内容不一致，报告 collision/conflict 并拒绝覆盖。
8. 通过临时文件写入 candidate 模板实例并原子 rename。
9. 返回真实 ID、摘要和路径。

### Review 行为

1. 验证 candidate/context 存在，并校验 `project`、`workspace_root`、`source_revision`、`evidence_refs` 与被绑定对象及当前调用一致。
2. 重算被审核对象摘要，写入或核对绑定字段。
3. 验证 recommendation/decision 属于 operation 的允许枚举。
4. final decision 存在时校验人工批准字段；pending review 可不批准但不能 apply。
5. 生成 `KRV-<digest>` 并追加写入 reviews。
6. 重复输入返回 `unchanged`。

### JSON 输出

```json
{
  "schema": "themis-knowledge-record-result/v1",
  "status": "created",
  "kind": "candidate",
  "id": "KNC-...",
  "digest": "...",
  "path": "workspace/knowledge/candidates/KNC-....md",
  "errors": []
}
```

`status` 允许 `created`、`unchanged`、`rejected`、`unavailable`。当 Verification exhaustion/escalation 调用 recorder 但 capability 自检失败时，脚本返回 `unavailable`，`errors` 包含 `candidate_pending`，不得创建 candidate 文件或声称 `created`。

## `themis-knowledge-lint.sh`

### CLI

```text
themis-knowledge-lint.sh policy --file <path>
themis-knowledge-lint.sh candidate --workspace <root> --file <path>
themis-knowledge-lint.sh review --workspace <root> --file <path>
themis-knowledge-lint.sh catalog --workspace <root> --file <path>
themis-knowledge-lint.sh --help
```

### 确定性检查

- Schema 标识、字段类型、必填值和稳定枚举；
- `project`、`workspace_root`、`source_revision`、`evidence_refs` 均非空，`workspace_root` 与 lint 调用参数一致，evidence refs 解析后均位于当前 Workspace；
- ID 与重算摘要一致；
- source artifact/evidence 路径存在且不逃逸 Workspace；
- `supersedes` 指向既有 candidate；
- review 绑定的 candidate/context digest 未过期；
- decision 与 operation 匹配；
- approved decision 具有完整人工批准字段；
- promote 目标分类合法；
- merge_duplicate 具有 canonical 引用；
- P5.4 Context/代码核验结果存在且未过期；
- `catalog.yaml` 无重复 ID/path、引用文件存在且 digest 一致；
- sensitivity 字段已审核；
- 内容不包含已知私钥 PEM 起始标记。

明显秘密标记检查是最低拒绝规则，不替代 Prompt/人工敏感信息审核。

### JSON 输出

```json
{
  "schema": "themis-knowledge-lint-result/v1",
  "status": "pass",
  "kind": "review",
  "path": "...",
  "errors": [],
  "warnings": []
}
```

结构错误、stale digest 或门禁不满足返回非零。

## `themis-knowledge-apply.sh`

### CLI

```text
themis-knowledge-apply.sh --workspace <root> --review <path> [--dry-run]
themis-knowledge-apply.sh --help
```

不提供直接的 `--decision promote` 参数；decision 必须来自持久化 review，防止绕过审核和批准记录。

### 前置门禁

1. 调用或复用 lint 逻辑验证 policy、对象和 review。
2. 要求 review `approval.mode: human`、`status: approved`。
3. 重算 candidate/context/review 摘要。
4. 确认同 review 尚未应用，或已应用结果完全一致。
5. 获取 `workspace/state/locks/knowledge-governance.lock` 的原子目录锁。
6. 锁已存在时报告 blocked，不删除未知锁。

### 处置行为

- `promote`
  - 生成 `CTX-<candidate-digest>`；
  - 写入允许分类目录；
  - 保留 candidate/review/source/evidence provenance；
  - 原子更新既有且受支持的 `catalog.yaml`；目标 Workspace layout 不受支持时返回 `unsupported_workspace_layout`，不创建目录或转换数据；
  - 创建 canonical `workspace/knowledge/actions/<action-id>.md`。
- `reject`
  - 不删除 candidate；
  - 在 `actions/` 写 canonical action record，并在 `rejected/` 写拒绝投影或引用。
- `revise`
  - 不修改 candidate；
  - 在 `actions/` 写 canonical action record；后续 record 的新 candidate 必须通过 `supersedes` 关联。
- `merge_duplicate`
  - 校验 canonical 引用存在；
  - 不删除 candidate 或 canonical 项；
  - 在 `actions/` 写 canonical action record。
- `retain`
  - 保持 Context 和索引不变；
  - 在 `actions/` 写废弃审核的 canonical action record。
- `archive`
  - 先保存 Context 内容及 provenance 的历史快照；
  - 从活动 Catalog 移除对应项；
  - 再移除活动 Context 文件；
  - 在 `actions/` 写 canonical action record，并在 `archive/` 保存历史快照或引用。

### 原子性与回滚

多文件处置采用：

1. 在 Workspace 内创建本次 action 的临时目录；
2. 备份所有既有待触及文件；
3. 完成新文件和新索引的临时构建；
4. 逐项 rename；
5. 任一步失败或收到 HUP/INT/TERM 时恢复备份并删除本次新文件；
6. 只有全部提交成功后写最终 action record；
7. 清理临时目录并释放锁。

如果无法证明恢复完成，返回 `error` 并保留诊断材料，不宣称 Workspace 未变化。

### 幂等性

Action ID 由 review digest 生成：`KAC-<review-digest>`。重复执行：

- action record 存在且输出摘要一致 → `unchanged`；
- action record 存在但目标内容漂移 → `conflict`，不得重写；
- 上次无最终 action record但存在未知残留 → `blocked`，要求人工检查。

### JSON 输出

```json
{
  "schema": "themis-knowledge-apply-result/v1",
  "status": "applied",
  "decision": "promote",
  "action_id": "KAC-...",
  "review_id": "KRV-...",
  "changed_paths": [],
  "unchanged_paths": [],
  "rollback": "not_needed",
  "errors": []
}
```

`--dry-run` 输出将执行的路径和操作，但 Workspace 指纹必须保持不变。

## 脚本测试边界

Shell 测试不得评价知识语义质量，只验证：

- JSON/YAML 契约；
- 路径和摘要；
- 批准门禁；
- 文件操作；
- 索引一致性；
- 幂等和回滚；
- 明显秘密标记拒绝。
