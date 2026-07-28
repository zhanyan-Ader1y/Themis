# P5.5 / impl-04 — 常驻规则、契约检查与测试

## Knowledge rules

更新 `core/kernel/knowledge/rules.md`，继续保持以下固定章节：

- `## Responsibility`
- `## Inputs`
- `## Outputs`
- `## Boundaries`

文件总行数不得超过 50 行。详细流程必须留在 Prompt，不进入 Orchestrator 常驻 import 图。

### MUST Read 契约

Knowledge rules 必须按操作显式要求：

- 任何 Knowledge 工作前 MUST Read `core/policies/knowledge-governance.yaml`；
- 提取 candidate 前 MUST Read `core/templates/knowledge-candidate-extraction.md` 和 `knowledge-candidate.md`；
- 审核或废弃前 MUST Read `core/templates/knowledge-review.md` 和 `knowledge-review-record.md`；
- 调用脚本前验证 `core/bin/` 中相应能力存在，并解析真实 JSON；
- apply 缺失时停止，禁止用通用文件工具手工提升、拒绝、归档或更新索引。

### 边界

- 不在 Core 存储项目知识。
- 不将候选或 AI 推荐视为正式知识。
- 不在无持久化人工批准时执行最终处置。
- 不静默覆盖已有 Context。
- 不伪造上游 Task、Verification、Review、Outcome 或 Freshness 工件。
- 不让 Knowledge 承担 P6 Freshness、P7.5 Outcome 分析或 P8 路由职责。

Orchestrator 已 import Knowledge rules，无需新增 import 或扩大 import 数量。

## 模板检查器扩展

`bin/themis-template-check.sh` 增加静态、只读检查：

1. 要求 policy、三个工件模板、两个 Prompt、三个 Runtime 脚本存在。
2. 校验 policy 根 map 和 `themis-knowledge-governance-policy`。
3. 校验 5 个来源、7 个分类、6 个审核维度、4 个 candidate dispositions、3 个 deprecation dispositions。
4. 校验 `approval.mode` 的当前默认值和 required fields 声明。
5. 校验 candidate/review/action 模板 Schema 行和固定标题。
6. 校验两个 Prompt 的核心阶段标题及 `## Available Scripts`。
7. 校验三个脚本通过 `bash -n`。
8. 继续对 Knowledge rules 应用 50 行预算和四个固定章节。
9. 校验 rules 包含 policy 和 Prompt 的精确 MUST Read 路径。

检查器不执行 Knowledge 脚本、不创建 Workspace 数据、不做语义审核。

## Template Contract 回归

扩展 `tests/template-contract/test.sh`，每个失败夹具在隔离模板副本中运行：

- 缺失 policy；
- policy YAML 损坏；
- 错误 policy Schema；
- 缺少来源/分类/维度/处置 ID；
- 缺失 candidate/review/action 模板；
- 缺失模板 Schema 或固定标题；
- 缺失 extraction/review Prompt；
- Prompt 缺 `Available Scripts`；
- 缺失 Runtime 脚本；
- Runtime 脚本 Bash 语法损坏；
- Knowledge rules 缺 MUST Read；
- Knowledge rules 超过 50 行。

更新 TAP plan count，避免只新增断言而忘记计划数。

## Knowledge Governance 模块测试

新建 `tests/knowledge-governance/test.sh`。测试只操作临时 Workspace，使用 TAP 输出并在 trap 中清理。

### Candidate/Review 测试

- 合法 candidate 创建；
- 相同输入重复记录返回 unchanged；
- 非法 source/category 拒绝；
- 缺 provenance 拒绝；
- `supersedes` 不存在时拒绝；
- 明显私钥标记拒绝；
- 合法 pending review 可记录但不可 apply；
- stale candidate digest 的 review lint 失败；
- candidate 缺少 `project`、`workspace_root` 或 `source_revision` 时拒绝；
- candidate/review 的 `workspace_root` 与 `--workspace` 不一致时拒绝；
- review 缺少或越界 `evidence_refs` 时拒绝；
- Verification exhaustion 调用 recorder 但 capability missing 时返回 `unavailable`，errors 含 `candidate_pending`，且不创建文件；
- decision 与 operation 不匹配时失败。

### Apply 测试

- 无批准 promote：非零、Workspace 指纹不变；
- 已批准 promote：L3 Context、Catalog、review、`actions/` canonical action 一致；
- 目标 Context 已存在且相同：幂等 unchanged；
- 目标 Context 已存在但不同：conflict，不覆盖；
- reject：candidate 保留，rejected action 创建；
- revise：candidate 保留，action 指出 supersedes 要求；
- merge_duplicate：canonical 不存在时失败，存在时记录引用；
- retain：Context 和索引不变，只新增 action；
- archive：历史快照、活动文件移除、索引更新一致；
- apply 重复执行：无重复 action/index；
- `--dry-run`：Workspace 指纹不变；
- 锁冲突：blocked，不删除未知锁；
- 注入 Context 写入失败：回滚；
- 注入 index rename 失败：回滚；
- HUP/INT/TERM trap：恢复并释放本次锁；
- action 的 evidence refs、inputs、outputs 或目标路径指向 Workspace 外时拒绝，当前 Workspace 指纹不变。

## 安装边界回归

### Init

`tests/init/test.sh` 增加已安装路径断言：

- policy；
- 三个工件模板；
- 两个 Prompt；
- 三个 Core Runtime 脚本；
- 更新后的 Knowledge rules。

### Existing Workspace

模块测试增加受支持 layout 与缺失 layout 夹具：

- fresh Init 的 current Workspace layout 可正常运行；
- 缺少 Catalog/治理目录或 schema 不受支持时返回 `unsupported_workspace_layout`/`unavailable`；
- Runtime 不补建不兼容目录、不改写 manifest/schema，Workspace 指纹保持不变。

## 必跑命令

```bash
bash -n templates/.themis/core/bin/themis-knowledge-record.sh
```

```bash
bash -n templates/.themis/core/bin/themis-knowledge-lint.sh
```

```bash
bash -n templates/.themis/core/bin/themis-knowledge-apply.sh
```

```bash
shellcheck templates/.themis/core/bin/themis-knowledge-record.sh templates/.themis/core/bin/themis-knowledge-lint.sh templates/.themis/core/bin/themis-knowledge-apply.sh bin/themis-template-check.sh tests/template-contract/test.sh tests/knowledge-governance/test.sh tests/init/test.sh
```

```bash
bash bin/themis-template-check.sh
```

```bash
bash tests/template-contract/test.sh
```

```bash
bash tests/knowledge-governance/test.sh
```

```bash
bash tests/init-environment/test.sh
```

```bash
bash tests/init/test.sh
```

```bash
git diff --check
```

只有观察到真实输出后才能记录通过。
