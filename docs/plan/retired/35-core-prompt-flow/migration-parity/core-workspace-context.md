# Core、Workspace 与 Context 迁移核验

## 核验范围

本分片核验任务 8 将 Core package identity、Workspace project configuration/ownership/state/recovery 合同与五个 Context descriptive protocols 从旧 YAML 或大型入口迁移为候选中文 Markdown。候选文件尚未切换为 current authority；八个旧 YAML 继续保留到任务 9 全局 cutover。

本任务不修改 Policy route、Capability、artifact templates 或 lifecycle consumers，不删除旧 YAML，不实现 adapter runtime、validator、digest、Catalog mutation、search/assembly、Policy evaluator、state recorder、writer 或 Plan 36/37 能力。

## 旧来源与候选目标

| 旧来源或入口 | 候选目标 | 迁移观察 |
|---|---|---|
| `core/core.yaml` | `core/README.md` | 保留 package identity、公共入口、Global Rule、Policy、Capability、Agent Profile、template 与 Workspace 入口关系；不把 `schema`、`workspace_schema`、`artifact_schema` 继续描述为机器 Schema identity |
| `workspace/manifest.yaml` | `workspace/project.md` | 保留 project name/root、lint/build/test commands、Context entry points/external sources、Gates、adapters、restricted Policy overrides 与十个 Workspace path 配置槽；空值统一写为 `未配置` |
| 旧 `workspace/README.md` | 短 `workspace/README.md` + 五个 `workspace/references/*.md` | 入口只保留职责、不可绕过边界、配置入口与 reference 索引；directory ownership、scope isolation、artifact/state、completion/retention、recovery/cache 分别有唯一详细 owner |
| `workspace/context/catalog.yaml` | `workspace/context/catalog.md` | 保留 `unbound`、project root、revision observation、原 catalog digest placeholder 与空 item index；明确 placeholder 不证明 canonical digest 或 currentness |
| `context/common-schema.yaml` | `context/references/common-fields.md` | 保留 Context/Bundle/Signal/Transaction ID pattern、digest pattern、共享 enum、公共 result、revision、digest/timestamp/path conventions；全部只作为 descriptive vocabulary |
| `context/context-item-schema.yaml` | `context/references/context-item.md` | 保留 item identity、字段闭集、source refs、relationships 与固定正文结构；把旧 `markdown-with-yaml-frontmatter` 改为纯 Markdown 固定章节 |
| `context/catalog-schema.yaml` | `context/references/catalog.md` | 保留 Catalog 顶层、project/revision、item index/source ref 字段闭集及 unique ID/path、existing refs、acyclic dependencies 与 digest exclusion 约束 |
| `context/bundle-schema.yaml` | `context/references/bundle.md` | 保留 Bundle、request、Context refs、revision、budget 与 status 字段；`spec_ref` 保持 required，但未配置时写 `未配置`；保留 subset、disjoint 与 byte-budget 约束 |
| `context/signal-schema.yaml` | `context/references/signal.md` | 保留 Signal、revision、disposition 字段闭集，四种 kind、四种 status、open/adjudicated disposition 约束与 drift 语义 |
| 旧 Protocols/Adapters 入口 | `core/protocols/README.md`、`core/adapters/README.md` | Protocols 改为 descriptive Markdown 边界；Adapter 输入改为 `workspace/project.md`，未实现 runtime |

## 候选文件观察

任务计划要求的 17 个 Core、Workspace 与 Context package candidates 均已建立或更新：

- `templates/.themis/core/README.md`
- `templates/.themis/workspace/README.md`
- `templates/.themis/workspace/project.md`
- `templates/.themis/workspace/references/directory-ownership.md`
- `templates/.themis/workspace/references/intake-and-lifecycle-isolation.md`
- `templates/.themis/workspace/references/artifact-and-state-model.md`
- `templates/.themis/workspace/references/completion-retention.md`
- `templates/.themis/workspace/references/recovery-and-cache.md`
- `templates/.themis/workspace/context/catalog.md`
- `templates/.themis/core/protocols/README.md`
- `templates/.themis/core/protocols/context/README.md`
- `templates/.themis/core/protocols/context/references/common-fields.md`
- `templates/.themis/core/protocols/context/references/context-item.md`
- `templates/.themis/core/protocols/context/references/catalog.md`
- `templates/.themis/core/protocols/context/references/bundle.md`
- `templates/.themis/core/protocols/context/references/signal.md`
- `templates/.themis/core/adapters/README.md`

## Workspace 合同边界

- `request-intake` 与 `lifecycle` 可引用同一 immutable source，但不共享 dynamic state、Execution Identity、failure budget、continuation authority、current pointer 或 completion state。
- `workspace/project.md` 只保存 Prompt-level configuration；配置槽存在不证明 command、path、adapter 或 override 可执行。
- Paired artifact 使用同一 immutable revision 下的 `record.md + content.md`；缺少任一部分或 identity/digest/scope/binding mismatch 时 whole revision invalid。
- Current pointer 是 separate operational observation；revision 存在不证明 pointer 已更新。
- Summary pair complete/current 后，Policy 才能记录 separate lifecycle completion observation；completion 不写回 immutable Summary。
- Cache 永远可重建且 non-authoritative；恢复只能从 durable facts 重读 last proven gate，不自动 repair、merge 或 replay。
- Fresh scaffold 只创建 family roots；写入前必须拒绝既有 `.themis/` 或冲突 managed target，不提供 upgrade/runtime migration/compatibility path。

## Context authority 边界

- Context 只服务受治理经验、背景、约束与核验线索，不拥有 current implementation facts、Current Request、Plan、lifecycle state、current pointer 或 completion authority。
- `category`、`authority`、`binding` 与 `context_code_drift` 等历史字段只描述来源、治理或冲突 observation，不能扩大 Context authority。
- 当前实现事实必须直接读取 code、configuration、Schema 或 observed executable behavior；Bundle 的 `code_refs` 不能替代 direct evidence。
- Context item 即使使用 `architecture` 或 `decisions` category，也不得复制项目当前架构、批准设计或代码结构并宣称 Context authority。
- Strict validation、canonical digest、Catalog mutation、deterministic selection/assembly、signal transition 与 governed apply 当前均为 `unavailable`。

## 文件体积观察

使用 `wc -l` 人工观察；该命令只统计文本行数，不构成 Themis machine enforcement：

| 入口 | 实际行数 | 上限 | 观察 |
|---|---:|---:|---|
| `templates/.themis/core/README.md` | 31 | 120 | 范围内 |
| `templates/.themis/workspace/README.md` | 31 | 140 | 范围内 |
| `templates/.themis/core/protocols/context/README.md` | 25 | 120 | 范围内 |

17 个候选文件总计 746 行；详细语义已拆入聚焦 references，三个入口不承载字段全集。

## 旧 YAML 保留观察

以下八个旧 YAML 均仍存在：

```text
templates/.themis/core/core.yaml
templates/.themis/workspace/manifest.yaml
templates/.themis/workspace/context/catalog.yaml
templates/.themis/core/protocols/context/common-schema.yaml
templates/.themis/core/protocols/context/context-item-schema.yaml
templates/.themis/core/protocols/context/catalog-schema.yaml
templates/.themis/core/protocols/context/bundle-schema.yaml
templates/.themis/core/protocols/context/signal-schema.yaml
```

对这八个路径执行定向 `git diff --exit-code`，输出为空且 exit 0；任务 8 没有修改、删除或重命名旧来源。它们只在任务 9 全局 authority cutover、任务 1–8 所有分片无未裁决 GAP 且全部 consumers 已切换后才能统一删除。

## 实施者核对

- 17 个候选文件均存在，Workspace 五个 references 与 Context 五个 references 数量符合计划。
- Candidate scope 定向搜索未发现 fenced YAML、YAML frontmatter requirement、`null`、`markdown-with-yaml-frontmatter`、`TODO` 或 `TBD`；未发现 Python/pytest 实现、调用或 parser，只有禁止以 Python 替代正式 Go CLI 保证的边界文字。
- `workspace/project.md` 逐项保留 manifest 的 project、commands、Context、Gates、adapters、Policy overrides 与十个 path 配置槽。
- Context common/item/catalog/bundle/signal references 显式保存 required/allowed field 闭集、enum、relationships 与完整性约束；Bundle Request 表的五个字段均标记 required。
- 通用 Markdown 标题和展示表头使用中文；stable identities、字段名、status、enum、operation token 与 path 保持精确英文值。
- `git diff --check` 成功，仅报告 Windows LF→CRLF warning；未做 line-ending normalization。
- 本任务未执行 authority cutover，未启动 Plan 36/37，未 commit 或 push。

## Fresh reviewer 核对

Fresh independent read-only review 拆为三个互相独立的切片：

1. Core/Workspace 切片返回 `Verdict: APPROVED`、`Findings: None`，确认 package identity、七个入口、manifest 配置槽、十个 paths、五个 Workspace references、双 scope、artifact/currentness、completion/retention、recovery/cache、Catalog 与 Adapter 边界无语义或配置缺失。
2. Context 合同切片首轮返回 `CHANGES_REQUIRED`：`context-item.md` 的固定 Markdown 结构把三个必填 sequence 合并为自由文本占位符，无法分别人工核对 `source_refs`、`dependencies` 与 `supersedes`。候选已改为三个显式小节，source refs 使用固定 `path | digest` 表，两个关系各使用 Context item ID sequence，空 sequence 统一写 `未配置`。
3. Evidence/切换门禁切片首轮返回 `CHANGES_REQUIRED`：实施者证据把禁止性边界中的 `Python` 字样也误报为“未发现 Python”。证据已修正为“未发现 Python/pytest 实现、调用或 parser；存在禁止性边界文字”。Reviewer 同时确认其余文件数、行数、入口限额、旧 YAML 保留、Git observations、Go CLI unavailable 与 Task 9 gate 声明成立。

Reviewer 全程只读，未编辑文件、创建 worktree、commit 或 push。

Scoped independent re-review 结果：

- Context item candidate 的原 finding 返回 `Verdict: APPROVED`、`Findings: None`；reviewer 确认三个 required sequence 已分别表示，source ref 固定为 `path + digest`，两个关系限制为 Context item ID，空 sequence 明确写 `未配置`，且字段合同与固定 Markdown 示例一致。任务 8 强制保留不变的旧 YAML 只作为迁移来源，不是 candidate representation。
- Evidence 文案与刷新计数的原 finding 返回 `Verdict: APPROVED`、`Findings: None`；reviewer 确认禁止性 Python 文字已与实现/调用/parser 区分，17 个候选总计 746 行，三个入口仍为 31/31/25，且 Task 9 在复核完成前保持阻塞。

## 未裁决 GAP

无。Task 8 的 Core/Workspace 全量切片已通过，Context 与 evidence 首轮 finding 均已修复并通过 scoped independent re-review；候选仍只在任务 9 全局 authority cutover 后才能成为 current authority。

## 自动 Go CLI 检查状态

`unavailable`。当前仓库不存在已批准并已实现的 Themis Go CLI Core/Workspace/Context 合同核验命令；未使用 Python、Shell 临时 parser、一次性 validator 或虚构子命令替代。Git、Glob、Grep 与 `wc` 只用于人工文件/版本控制观察，不构成 machine enforcement。
