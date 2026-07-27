# P5.4 实施索引

P5.4 将已确认的双轴可信模型和 L1/L2/L3 Context 设计落地为机器协议、唯一 Catalog、确定性检索/装配、新鲜度与 Signal。它必须在当前 `themis-workspace/v1` 可表达的目录内实施，不实现 Schema 转换、Knowledge Promotion、Behavior Map 或生命周期编排。

**状态**：实施设计待用户确认。确认前不得修改本计划列出的协议、脚本、Workspace 模板、测试或正式设计。

## 设计决策

| # | 决策 |
|---|---|
| D1 | 正式项目知识只有 `workspace/context/`；当前代码、配置和 Schema 负责当前实现事实。 |
| D2 | `workspace/context/catalog.yaml` 是唯一持久注册表；L1/L2、索引和 Bundle 都可重建。 |
| D3 | Context Item、Catalog、Bundle、Signal 分别使用版本化 Protocol，不把多个职责塞入一个 schema。 |
| D4 | Prompt 只在确定性 search 返回的候选 ID 内做语义筛选；脚本再次校验 ID/path/digest。 |
| D5 | `missing`、`stale`、`context_conflict`、`context_code_drift` 持久化到 `workspace/state/context-signals/`，不在 Cache 中保存唯一状态。 |
| D6 | Context executor 只处理一个显式 Workspace；所有输出绑定 project identity、Workspace root 和 source revision，禁止跨 Workspace 扫描。 |
| D7 | P5.4 只能使用当前 `themis-workspace/v1` 已允许的目录和 manifest paths；不得修改 schema、转换既有安装或隐式创建不兼容结构。 |
| D8 | 不创建或预留 Behavior Map、B1/B2/B3、Anchor 或 Behavior Extractor；Planning/Review 直接核验当前源码。 |
| D9 | Spec 和 Knowledge 消费 Context 能力，不各自实现 Catalog/Search/Freshness。 |
| D10 | 所有写入使用路径校验、锁、临时文件、原子替换、read-back 和失败恢复；机器输出使用 JSON。 |
| D11 | L1/L2 是可重建导航投影。L3/Catalog 变化时只标记受影响投影 stale；Search 始终可直接查询完整 Catalog/L3。 |
| D12 | Context/Knowledge 这类跨领域数据服务安装在 `core/bin/`；生命周期 runner 与领域 rules 共置于 `core/kernel/<domain>/`。 |

## 机器协议

目标目录：`templates/.themis/core/protocols/context/v1/`

### `context-item-schema.yaml`

至少定义：

- `context_item_schema: themis-context-item/v1`；
- 稳定 `CTX-*` ID、L3、category、knowledge kind、authority、status；
- scope、tags、source refs、project identity；
- source revision、verified time、dependencies、supersedes；
- content digest、freshness；
- frontmatter 与正文 digest 的一致性规则。

### `catalog-schema.yaml`

至少定义：

- `catalog_schema: themis-context-catalog/v1`；
- project identity、Workspace root digest、revision；
- Context ID → path/category/status/digest/freshness/source refs；
- ID/path 唯一性和路径逃逸禁止；
- L1/L2 派生投影引用。

### `bundle-schema.yaml`

至少定义：

- `bundle_schema: themis-context-bundle/v1`；
- query intent、Spec/Task、scope、token budget；
- selected/excluded Context ID、path、digest、freshness 和理由；
- 读取的 code/config/schema paths；
- unresolved Signal refs；
- `complete | partial | conflict | unavailable`。

### `signal-schema.yaml`

至少定义：

- `signal_schema: themis-context-signal/v1`；
- `missing | stale | context_conflict | context_code_drift`；
- project/workspace/revision、scope、sources、evidence refs；
- `open | resolved | accepted | superseded`；
- resolution/disposition 和审计时间。

## 确定性执行器

目标目录：`templates/.themis/core/bin/`

| 脚本 | 操作 | 写入边界 |
|---|---|---|
| `themis-context-lint.sh` | 校验 Item/Catalog/Bundle/Signal、引用和路径 | 默认只读；可输出 JSON 报告 |
| `themis-context-catalog.sh` | `build/check/register/remove/status` | Catalog；register/remove 仅供获批治理调用 |
| `themis-context-search.sh` | 按 ID/domain/entity/operation/state/path/term 检索 | 只读；输出稳定候选集合 |
| `themis-context-assemble.sh` | `prepare/select/finalize/status` 装配 Bundle | `workspace/cache/resolved-context/` |
| `themis-context-freshness.sh` | 重算 digest/revision/dependency 并记录 Signal | Catalog freshness + `state/context-signals/` |
| `themis-context-navigation.sh` | `lint/status/publish/rebuild-index` 校验并发布 L1/L2 candidate | `.abstract.md` / `.overview.md`；不修改 L3 |

共同合同：

- 必须显式传入 Workspace root，不从父目录搜索其他 Workspace；
- 验证 root 位于项目内，拒绝绝对输出路径、`..`、符号链接逃逸和 Core 写入；
- stdout 为单个稳定 JSON，诊断写 stderr；
- exit `0` 成功，`1` 无效/失败，`2` 表示需要人工裁决；
- 写操作可重复执行且不生成重复记录；
- 中断或 read-back 失败时恢复旧状态或报告保留的 recovery path；
- 复用 `themis-spec.sh` 的 staging、原子替换与 read-back 模式，不引用已退役脚本。

## Context Resolution

```text
Intent/Scope
  → explicit Context IDs
  → deterministic Catalog search
  → L1 filter → L2 navigation → selected L3
  → Prompt semantic selection within returned IDs
  → script validates selected IDs/path/digest/freshness
  → current code/config/schema lookup when needed
  → Bundle or persistent Signal
```

- 搜索无命中不等于事实不存在；返回 `partial/unavailable` 并记录 `missing`。
- stale/conflict 时不得输出 `complete`。
- Context/代码职责互补可以同时进入 Bundle；冲突必须写 `context_code_drift`。
- Bundle 丢失后可从 Catalog、query 和 revision 重建。
- Catalog 是检索全集；L1/L2 只优化披露。缺失或 stale 时 search 直接使用 Catalog/L3，并返回 navigation warning。
- L3/Catalog 变更后标记受影响导航 stale；`context-summary.md` 只能基于 Catalog 返回的 L3 引用生成 candidate，executor 校验引用覆盖、digest 和无新增事实后再发布。

## Workspace 初始化边界

P5.4 只在 fresh Init 模板中声明当前 schema 已允许的目标目录、初始 Catalog 或 `.gitkeep`：

1. `workspace/context/catalog.yaml` 与 L1/L2 导航位置；
2. `workspace/state/context-signals/`；
3. `workspace/cache/context-index/` 与 `resolved-context/`；
4. `workspace/knowledge/` 的治理子目录可由对应获批计划在同一现行 schema 内定义。

对既有 `.themis`：

- P5.4 不运行 Init 覆盖、不转换 manifest、不补建目录；
- 缺失目标结构时返回 `unsupported_workspace_layout` 或 `unavailable`；
- 不建议删除 Workspace 或复制模板绕过；
- 任何需要 schema 变化或已有安装转换的工作延期到未来重新设计。

## Spec 与 Knowledge 集成边界

- Spec 的 `EVD-* kind: context` 使用稳定 `CTX-*` source；Spec validator 只校验结构和引用链，Catalog/digest/freshness 由本模块校验。
- Knowledge promotion 前必须调用 search/lint/freshness；Knowledge 不维护第二个索引或 Signal 算法。
- 缺少本模块或 Workspace layout 不受支持时，上游返回 unavailable/unsupported，不得临时创建 Catalog 或伪造 Context ID。

## 目标文件

### Core

- `templates/.themis/core/protocols/context/v1/{context-item,catalog,bundle,signal}-schema.yaml`
- `templates/.themis/core/bin/themis-context-{lint,catalog,search,assemble,freshness,navigation}.sh`
- `templates/.themis/core/templates/{context-resolution,context-summary}.md`
- `templates/.themis/core/kernel/context/rules.md`
- `templates/.themis/core/core.yaml`（仅登记受支持协议/能力，不改变 schema allow-list）

### Workspace

- 当前 `themis-workspace/v1` 内的目标目录模板与初始 Catalog
- `templates/.themis/workspace/manifest.yaml`（仅在现有字段/paths 内校准，不改变 schema）

### 检查与测试

- `bin/themis-template-check.sh`
- `tests/template-contract/test.sh`
- `tests/context-resolution/test.sh`
- `tests/init/test.sh`

### 正式设计与发布

- `docs/design/{governance,architecture,workflow}.md`
- `docs/design/core/kernel/{context,specification,knowledge}.md`
- `docs/design/core/{protocols,templates}.md`
- `docs/design/workspace/overview.md`
- `docs/plan/README.md`
- `CHANGES.md`
- `templates/.themis/VERSION`

## Task DAG

| Task | 内容 | 依赖 |
|---|---|---|
| CTX-01 | 四类 Protocol 与稳定身份/路径合同 | 无 |
| CTX-02 | lint + Catalog executor | CTX-01 |
| CTX-03 | search + resolution Prompt | CTX-02 |
| CTX-04 | assemble Bundle + semantic selection read-back | CTX-03 |
| CTX-05 | freshness + Signal | CTX-02 |
| CTX-06 | context-summary Prompt + L1/L2 navigation lint/publish | CTX-02、CTX-05 |
| CTX-07 | fresh Init 模板、rules、模板检查和模块测试 | CTX-03、CTX-04、CTX-05、CTX-06 |
| CTX-08 | Spec/Knowledge 接口验证与正式设计同步 | CTX-07 |
| CTX-09 | 全量回归和版本发布记录 | CTX-08 |

## 验证矩阵

| 验证项 | 预期 |
|---|---|
| Protocol YAML | 四个 schema 可解析，required/allowed/enums/ID/path 严格。 |
| Shell syntax/static | Bash 3.2 语法和 ShellCheck 通过。 |
| Catalog | ID/path 唯一；digest/revision 错误 fail closed；重复 register 幂等。 |
| Search | 只返回 Catalog 内候选；排序稳定；无命中不伪造事实。 |
| Bundle | selected/excluded/Signal/code refs 完整；Cache 删除后可重建。 |
| Freshness | source/dependency 改变产生 stale Signal，不自动改写 L3。 |
| L1/L2 navigation | L3 变化后投影 stale；Catalog search 仍命中；无来源 candidate 不能发布。 |
| Conflict | Context/Context 与 Context/code drift 分别持久化，阶段不继续。 |
| Isolation | 不能读写相邻 Workspace、Core 或路径逃逸目标。 |
| Existing install | 缺失布局稳定返回 unsupported/unavailable，Workspace 字节不变。 |
| Init | fresh 安装包含协议、脚本和当前 schema 允许的目标模板。 |
| Integration | Spec 与 Knowledge 只消费本模块接口，不存在第二套 resolver。 |

## 确认门禁

本实施索引确认后才能创建或修改上述实现资产。P5.5 和 Spec Context 引用必须等待本模块的实际 Protocol 与 executor 可用后再集成。
