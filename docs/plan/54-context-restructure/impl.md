# P5.4 Context Restructure 实施设计

P5.4 在现有 `themis-workspace` 内实现受治理 Context 与当前代码事实的双轴可信模型。正式知识仅位于 `workspace/context/`；Catalog 是唯一持久注册表；L1/L2、索引和 Bundle 可重建；Signal 持久记录 missing、stale、Context 冲突和 Context/code drift。P5.4 不改变 Workspace/Artifact schema，不转换既有安装，不实现 Knowledge Promotion、生命周期编排、Behavior Map、Upgrade 或 Migration。

**状态**：已实施（2026-07-28）。

## 设计决策

1. Context Item、Catalog、Bundle、Signal 分别使用稳定且无模块版本的 `themis-context-*` Protocol；共享枚举和结果 envelope 位于 `common-schema.yaml`。
2. Item ID 为 `CTX-[0-9]{3,}`；Bundle 和 Signal ID 分别为 `CBL-`/`CSG-` 加 canonical SHA-256。
3. 所有 digest 为 `sha256:<64 lowercase hex>`。YAML 使用递归 key-sort 的紧凑 JSON；Item 正文统一 LF 和单个末尾换行；普通文件按原始字节计算。
4. Workspace identity 只覆盖 manifest 的 schema、project identity、逻辑 root 和 paths，不持久化机器绝对路径。
5. Revision 支持 Git commit + clean/dirty；非 Git 合法记录 unavailable。具体代码事实始终另带文件 digest。
6. Fresh Init 安装 unbound 空 Catalog；首个治理写操作显式 `catalog bind`。Init 不依赖 Git，不制造 revision。
7. Catalog 只保存受治理 registry；Freshness 不改写 L3、Item status 或 Catalog registry，动态状态由 digest/revision/dependency 和 open Signal 合成。
8. Prompt 只能在 deterministic Search/Prepare 返回的 ID 内语义选择；Shell 重验 ID、path、digest、budget 和 Signal。
9. 所有执行器显式接收 `--workspace`，不向父目录发现 Workspace；代码检查另显式接收 `--project-root`。
10. stdout 恰好一个 `themis-context-result` JSON；stderr 为人类诊断；exit 0 成功、1 invalid、2 adjudication/unavailable。
11. 写操作使用 `workspace/state/locks/context.lock/` 原子目录锁和 `workspace/state/transactions/context/` 可恢复事务；未知锁或 residue 不自动删除。
12. L1/L2 只复制获批 Catalog/L3 metadata，不生成新事实；未注册文件不会自动进入 Catalog。
13. 不在 `core.yaml` 增加 capability registry；实现完成时协调提升 Core/VERSION 到 `0.4.0`，Workspace/Artifact allow-list 不变。

## Protocol 合同

目标：`templates/.themis/core/protocols/context/`。

- `context-item-schema.yaml`：Markdown frontmatter 的 required/allowed keys、category、authority、status、scope/tags、source refs、dependencies、supersedes、abstract/overview 和 digest。
- `catalog-schema.yaml`：binding、project、workspace identity、revision、Catalog digest、ID→path/category/status/digest/source refs、唯一性和无环引用。
- `bundle-schema.yaml`：request、candidate/selected/excluded refs、code refs、Signal refs、预算、revision 和 `complete|partial|conflict|unavailable`。
- `signal-schema.yaml`：`missing|stale|context_conflict|context_code_drift`、`open|resolved|accepted|superseded`、scope/sources/evidence、首次/末次观测和 disposition。
- `common-schema.yaml`：共享 ID patterns、enums、digest/revision/path/timestamp 结构和 JSON result envelope。

审计时间为 UTC RFC3339 秒精度，不参与 Bundle/Signal ID。Catalog digest 排除机器观察时间、Signal 和 Cache。相同 Signal 身份幂等更新，不重复创建。

## 共享运行时

`templates/.themis/core/bin/_themis-context-common.sh` 统一提供：

- Bash 3.2 CLI、JSON escape/result、mikefarah/yq v4 和 `sha256sum` 检查；
- manifest/Protocol 定位、Workspace identity、Git/unavailable revision；
- YAML/frontmatter canonical digest；
- 相对路径、Core/相邻 Workspace/symlink containment；
- Context 专属 owner-token lock；
- Workspace-local staging、read-back、backup、rollback 和 explicit recovery。

read-only 命令不创建目录。写命令只在已安装且协议可识别的 layout 工作。锁不按年龄自动清理；事务恢复只处理 owner、operation、target 和 digest 都可验证的记录。

## 执行器合同

### Lint

```text
themis-context-lint.sh lint --workspace <root>
  [--kind all|item|catalog|bundle|signal] [--path <workspace-relative-path>]
```

只读批量校验 schema、allowed keys、ID/path、digest、唯一性、引用和 containment。

### Catalog

```text
themis-context-catalog.sh bind --workspace <root> --project-root <root>
themis-context-catalog.sh check --workspace <root> [--project-root <root>]
themis-context-catalog.sh register --workspace <root> --item <context-relative-path>
  --expected-catalog-digest <digest>
themis-context-catalog.sh remove --workspace <root> --id <CTX-id>
  --expected-catalog-digest <digest>
themis-context-catalog.sh status --workspace <root>
themis-context-catalog.sh recover --workspace <root> --transaction <id>
```

Bind 只允许 unbound→bound；identity 不同返回 adjudication。Register 相同内容幂等，验证 ID/path 唯一、依赖存在和无环。Remove 只移除 registry，不删除 L3；被引用或 active Item 需要裁决。

### Search

```text
themis-context-search.sh query --workspace <root> [filters...] [--term <text> ...] [--limit <n>]
```

过滤 ID/category/kind/scope/status/path，按 exact-ID、category、path、ID 稳定排序。Term 使用 deterministic ASCII case-fold substring；非 ASCII 按原字节。无命中返回空 candidates 和 missing 建议，不隐式写 Signal。导航 stale 不阻断 Catalog Search。

### Assemble

```text
themis-context-assemble.sh prepare --workspace <root> --request <relative-yaml>
themis-context-assemble.sh select --workspace <root> --bundle <CBL-id> --selection <relative-yaml>
themis-context-assemble.sh finalize --workspace <root> --bundle <CBL-id> [--project-root <root>]
themis-context-assemble.sh status --workspace <root> --bundle <CBL-id>
themis-context-assemble.sh recover --workspace <root> --transaction <id>
```

Prepare 固定 request、Catalog digest、revision 和候选。Select 只接受该候选集合。Finalize 重验来源并写 `cache/resolved-context/<id>/{manifest.yaml,context.md}`；Markdown 仅稳定连接 L3 正文，不总结。`token_budget` 是元数据，`content_budget_bytes` 是 Shell 强制上限。

### Freshness

```text
themis-context-freshness.sh check --workspace <root> (--id <CTX-id>|--all) [--project-root <root>]
themis-context-freshness.sh record --workspace <root> --report <relative-yaml>
themis-context-freshness.sh resolve --workspace <root> --signal <CSG-id>
  --status resolved|accepted|superseded --actor <value> --note <relative-file>
themis-context-freshness.sh status --workspace <root> [--signal <CSG-id>]
themis-context-freshness.sh recover --workspace <root> --transaction <id>
```

Check 只读；Record 才持久 Signal；Resolve 记录人工 actor/note/evidence。任何操作都不自动改 L3/Catalog 或裁决双轴冲突。

### Navigation

```text
themis-context-navigation.sh render --workspace <root> --candidate <cache-relative-dir>
themis-context-navigation.sh publish --workspace <root> --candidate <cache-relative-dir>
  --expected-catalog-digest <digest>
themis-context-navigation.sh status --workspace <root>
themis-context-navigation.sh rebuild-index --workspace <root>
themis-context-navigation.sh recover --workspace <root> --transaction <id>
```

Root `.abstract.md` 按固定 category 显示 active count；root `.overview.md` 列 title/abstract/status/scope/path/digest；category `.overview.md` 额外复制受治理 overview 和依赖。Projection frontmatter 绑定 Catalog/source digests；generated time 不参与 currency。Render 只写 Cache candidate，Publish 重验后事务发布。

## Prompt、模板与集成

- `context-resolution.md` 强制先 Search/Prepare，模型只能返回候选 ID 内的 selection；缺失/stale/conflict/drift 时停止事实性结论。
- `context-summary.md` 只生成待治理 Item metadata candidate，禁止直接写 Catalog/L3/L1/L2。
- `context/rules.md` 保持 50 行内，以按需 `MUST Read` 路由 Protocol、Prompt 和 executors；不增加 Orchestrator 常驻 import。
- 顶层 Guidance 与 Orchestrator 明确 governed Context 和 current code 是双轴来源，不写成全局覆盖关系。
- Fresh template 安装空 Catalog、root 空投影、七类目录、Signal/transaction/lock/cache skeleton；不制造项目事实或 Git revision。
- Manifest 沿用现有 fields/paths；Init 只配置既有 project name，不承担 Catalog bind。
- Template checker 要求全部协议、执行器、Prompt、bootstrap 和权限，并继续拒绝退役资产。

## Task DAG

| Task | 内容 | 依赖 |
|---|---|---|
| CTX-01 | Protocol、共同 runtime、digest/path/result 合同 | 无 |
| CTX-02 | Lint、Catalog、bootstrap bind、锁/事务 | CTX-01 |
| CTX-03 | Search、Prepare/Select/Finalize 和 resolution Prompt | CTX-02 |
| CTX-04 | Freshness、Signal 和人工 disposition | CTX-02 |
| CTX-05 | L1/L2 Navigation、Index 和 summary candidate 边界 | CTX-02、CTX-04 |
| CTX-06 | fresh template、rules、Guidance、Template Contract、Init | CTX-03、CTX-04、CTX-05 |
| CTX-07 | 正式设计、状态、版本和发布记录 | CTX-06 |
| CTX-08 | 全量回归、扫描、diff/status | CTX-07 |

## 验证矩阵

- Protocol：YAML 可解析；unknown key/type/enum/ID/digest/ref/cycle fail closed。
- Shell：`bash -n`、`shellcheck -x`、Bash 3.2。
- Bootstrap：非 Git bind 合法；不同 identity 不自动重绑；existing install 不变。
- Catalog：ID/path 唯一、expected digest、register 幂等、remove 引用保护。
- Search：Catalog-only、稳定排序、empty hit、navigation fallback。
- Bundle：越界 selection、预算、stale/conflict/unavailable、Cache 删除后重建。
- Freshness：Check 只读、Signal 幂等、人工 disposition、Catalog/L3 字节不变。
- Navigation：root/category currency、coverage/digest、无来源 candidate 拒绝。
- Isolation：拒绝 absolute、`..`、symlink、Core、相邻 Workspace。
- Recovery：锁竞争、未知锁、写入中断、rollback、restore failure 和 explicit recover。
- 性能：20 Item 正常主流程不超过 `2N + 30` 次 yq；禁止 per-field process pattern。
- Integration：Spec/Knowledge 只消费本模块接口；不存在第二 Catalog/resolver。
- Regression：Template Check、Context、Init、Template Contract、Spec Artifact 和现有套件实际输出通过。

实现不得修改独立未跟踪的 `docs/plan/53-requirement-questioning-skill/`，不得创建 commit 或 push，除非用户另行明确要求。
