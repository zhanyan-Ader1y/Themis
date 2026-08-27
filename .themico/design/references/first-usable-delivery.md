# Themico 首个可用交付范围

## 1. 文档角色

本文是 [Themico 顶层设计 Spec](../2026-07-29-themico-design.md) 的实施切片 reference，用于定义首个可用交付必须完成的端到端能力、延期边界和验收门槛。

本文不建立第二套产品设计，也不覆盖其他主题 reference。顶层 Spec 及其知识模型、类型、权威、存储、查询和 Skill 合同仍然定义完整 Themico 目标；本文只回答哪些已确认能力必须先形成可运行闭环。本文没有引入功能版本、版本目录、compatibility、upgrade 或 migration。

## 2. 交付目标

首个可用交付必须让 Human 与 Agent 能在本地仓库中完成一次真实、受治理且可验证的知识发布与读取：

```text
init
→ create 或 revise candidate
→ Human confirm-type
→ deterministic validate
→ independent semantic assessment
→ prepare publish
→ Human Approval
→ publish
→ query L1
→ exact-ID inspect L2 或 L3
```

该链路必须使用真实 `themico` Go CLI、不可变 payload、canonical digest、source binding 和 generation-directory commit。计划文本、直接写文件、测试替身或 Agent 声明都不能代替实际机器操作。

## 3. 必须保留的核心不变量

范围收敛不能削弱以下设计不变量：

1. Knowledge Record 仍是身份、revision、lifecycle、sources、authorization、typed relations、L1、L2 和 L3 的原子治理单位。
2. L1、L2、L3 仍只表示同一记录的读取深度，scope 维度不能变成新的知识层级。
3. `design_decision`、`development_standard`、`development_experience` 和两个 Zone 的闭集及唯一 compatibility 映射保持不变。
4. Agent 只拥有语义提案、内容生成、semantic assessment、相关性判断和 explanation；Human 拥有类型确认与 publication 授权；CLI 是唯一 machine authority。
5. 类型确认前只保存 `proposed_type`；确认后固化 `knowledge_type`，后续 revise 不得原地改型。
6. 正式 source 只接受 repository/root-relative 本地文件，并绑定 CLI 实际读取 bytes 的 digest。
7. candidate、record、projection、assessment、prepare、Approval 和 generation payload 都是不可变对象。
8. 只有完整合法的新 generation directory 发布成功后，current state 才能改变；orphan payload 和 staging 残留不是 current authority。
9. L1、L2、record revision、L3 digest 和 manifest pointer 必须精确绑定；绑定失效时读取失败关闭。
10. 所有机器 JSON、digest、ID、状态和 result envelope 继续遵守已确认的确定性合同。

## 4. 首个交付组件边界

### 4.1 Registry 与类型 factory

首个交付必须支持三个已确认知识类型及其 Zone compatibility。每个 factory 必须提供严格的 typed L2 payload 合同、固定中文 L3 Markdown 章节和 semantic-check reference。

新 candidate 可由 Agent 使用 lightweight classification registry 提出唯一 `proposed_type`。Human 确认后，CLI 固化类型；已有正式记录只能根据持久化 `knowledge_type` 路由到一个 factory，不能根据标题、摘要或正文重新猜测类型。

### 4.2 Candidate service

Candidate service 必须提供 create、revise、confirm-type 和 inspect：

- create 与 revise 读取并绑定实际 source bytes；
- revise 使用 expected candidate revision，stale writer 返回 conflict；
- confirm-type 创建新的不可变 candidate revision；
- confirm-type 后 revise 不能改变类型；
- inspect 根据 current manifest pointer 校验 canonical payload、digest、revision、status、record binding 和 L3 digest；
- mutation 成功后返回本次调用实际提交的 exact revision，不跟随之后发生变化的 current pointer。

`abandoned` 保留在 candidate 状态闭集中，但首个交付不要求提供独立 abandon 工作流。

### 4.3 Deterministic validate

validate 只证明机器可判定事实，必须覆盖：

- `knowledge_type` 与 Zone compatibility；
- 类型化 L2 payload；
- 对应类型的固定 L3 中文 Markdown 章节；
- L1、L2、L3 digest；
- candidate exact current revision；
- source currentness；
- 已提供 relation 的类型、目标 identity、目标存在性和跨 Zone 显式声明。

validate 不判断自然语言内容是否正确，不执行关系遍历、多跳展开或复杂 cycle analysis。关系的深层图约束进入后续独立计划。

### 4.4 Assessment、prepare、Approval 与 publish

独立 semantic assessment 必须精确绑定 candidate ID 与 revision，并使用与 proposer 不同的 checker identity 字段。CLI 只校验 assessment 的结构、状态和绑定，不判断 notes 是否正确。

`prepare publish` 必须冻结：

- operation；
- candidate ID、revision 和 digest；
- source bindings；
- assessment digest；
- expected generation；
- 分配的 record ID 与 revision；
- L1、L2、L3 digest；
- 完整 immutable write set；
- 空或非空的完整 invalidation set；
- prepare identity、created time 与 digest。

Human Approval 必须精确绑定：

```text
operation=publish
+ prepare_id
+ prepare_digest
```

publish 只能复核已经冻结的输入、currentness 和 Approval，不能重新解释 proposal 或重新生成内容。成功时必须在同一个 generation commit 中：

- 写入 active record revision 与 L3；
- 写入绑定该 record revision 的 L1、L2；
- 保存 assessment、prepare 和 Approval；
- 创建 current active record pointer；
- 把 candidate 标记为 `published`；
- 让 candidate pointer 精确绑定 record ID。

任一校验、绑定、授权、source currentness 或 expected generation 失败时，不得产生部分可见发布，不得自动 retry，也不得自动改变基线。

### 4.5 Record inspect 与基础 query

首个交付查询只以合法 current manifest pointers 及绑定有效的 L1/L2 为机器权威。

基础 query 必须支持以下确定性过滤：

- Zone；
- `knowledge_type`；
- lifecycle status；
- scope 中的 project、domains、architecture units、features；
- tags；
- triggers。

默认 query 只返回 current active L1，并按稳定规则排序。L2 和 L3 只能通过 exact record ID 请求；`depth` 只接受 `1`、`2`、`3`。

读取必须对实际返回 bytes 应用 byte budget。单个完整 item 超出剩余预算时返回 `budget_exceeded`；不能静默截断 L3、删除章节或声称 token enforcement。每次读取必须验证 record revision、L1/L2 和 L3 digest binding，投影缺失或失效时失败关闭，不能从 L3 临时生成摘要。

首个交付不要求 Agent relevance ranking、semantic explanation 的产品化接线、history query、关系扩展、多跳查询或跨 Zone 查询扩展。

### 4.6 Generation store 与 `views.json`

首个交付继续使用顶层 Spec 定义的 generation-directory store，store root 为 `.themico/workspace/`。`init` 只拥有 `workspace/`：它按需创建包目录与空 `core/`，在 workspace 已存在时失败，并允许控制面与工作区按任意顺序安装。`core/` 由 Skill reference 交付填充，不被 generation commit 写入。`manifest.json` 中的 current pointers 是 candidate 与 record currentness 的唯一机器来源。

repository-relative source 相对仓库根解析，不相对包目录或 workspace。

`views.json` 在首个交付中只承担 generation 格式所要求的合法最小对象角色，固定为 canonical 空对象 `{}`。它不表示完整聚合索引，不是基础 query 的权威来源，也不能被产品说明或证据声称为已经实现 project、domain、architecture unit 或 feature view。

聚合 view、显式 `rebuild` 命令、增量索引和损坏 view 恢复进入后续独立计划。该延期不允许 query 绕过 manifest pointer 或投影绑定校验。

### 4.7 CLI command surface

首个交付只要求以下核心 command 可构建、可运行并返回单一 JSON result envelope：

```text
themico init --root <root>
themico candidate create --root <root> --input <candidate.json> --content <content.md>
themico candidate revise --root <root> --input <revision.json> --content <content.md>
themico candidate confirm-type --root <root> --confirmation <confirmation.json>
themico candidate inspect --root <root> --id <candidate-id>
themico validate --root <root> --candidate <candidate-id> --revision <candidate-revision>
themico prepare publish --root <root> --candidate <candidate-id> --assessment <assessment.json>
themico publish --root <root> --prepare <prepare-id> --approval <approval.json>
themico query --root <root> --request <query.json>
themico inspect --root <root> --request <inspect.json>
```

CLI 层只负责参数解析、strict decode、service 调用、domain error 映射和 envelope 输出，不能复制 model、validation、governance 或 store 逻辑。缺参、未知 command、非法 JSON、不存在对象和 domain failure 必须返回闭集状态；stdout 不能混入额外文本。

### 4.8 单一公共 `themico` Skill

首个交付必须提供一个公共 `themico` Skill。一次 Invocation 只加载一个必要 operation reference，并按 registry 只加载一个 type factory。

宿主发现入口为 `.claude/skills/themico/SKILL.md`，只保留宿主所需的最小 frontmatter 与转发说明；common references、operation references 和三个 type factory 全部位于 `.themico/core/references/` 下，与受治理 workspace 分离。

首个交付所需 operation references 为：

- `query`；
- `inspect`；
- `create-candidate`；
- `revise-candidate`；
- `confirm-type`；
- `validate`；
- `prepare`；
- `publish`。

common references 必须提供 operation、result、governance、Knowledge Record、L1 discovery 和 type registry 合同；三个 type factory 各自提供 factory、L2、L3 和 semantic-check reference。

CLI 或所需 reference unavailable 时，Skill 只能形成 draft 并报告 unavailable，不能手工修改 `.themico/workspace/`，也不能声称结果已 published、current 或 valid。

## 5. 端到端数据流与失败关闭

首个交付的 authority 变化如下：

1. `init` 按需创建 `.themico/` 与空 `.themico/core/`，并发布含 generation 0 的 `.themico/workspace/`；workspace 已存在时在任何写入前失败。
2. candidate mutation 写入不可变 revision，并通过 expected generation 更新 current candidate pointer。
3. Human 类型确认只对确切 candidate revision 生效，并创建固化类型的新 revision。
4. validate 和 independent assessment 不改变 published record current state。
5. prepare 冻结发布输入、写集合和 expected generation，但不发布 record。
6. Approval 只授权其精确绑定的 prepare。
7. publish 使用一次 generation commit 同时改变 record 与 candidate 的可见 current state。
8. query 和 inspect 只读取合法 current generation 及其精确绑定 payload。

以下任一情况都必须停在 last valid current state：

- current generation chain 非法；
- candidate、record、projection 或 content digest 不匹配；
- expected generation 或 expected revision stale；
- source bytes 已变化；
- type、Zone、L2 或 L3 合同不合法；
- relation target 不存在或跨 Zone 声明缺失；
- assessment 与 candidate binding 不匹配；
- checker identity 字段与 proposer 相同；
- prepare、Approval、operation 或 digest 不匹配；
- byte budget 不足；
- 文件路径 escape、symlink/junction escape 或输入超限；
- 所需 CLI、registry、factory 或 operation reference unavailable。

失败不能通过自动 retry、自动修复、部分返回、手工文件写入或其他脚本模拟成功。

## 6. 后续独立计划

以下已确认设计仍属于完整 Themico 目标，但不阻塞首个可用交付：

### 6.1 生命周期与派生

- supersede；
- deprecate；
- archive；
- history query；
- 跨类型派生工作流和 `create-derived-candidate`。

### 6.2 关系与查询增强

- relation traversal；
- 多跳查询；
- 跨 Zone 查询扩展；
- 复杂 cycle analysis；
- Agent relevance ranking；
- enriched semantic explanation。

### 6.3 投影和性能增强

- project、domain、architecture unit、feature 聚合 view；
- `rebuild` 命令；
- 增量 view 维护；
- cache；
- 并行 query；
- 其他经过真实测量后单独批准的性能优化。

### 6.4 外部来源与集成

- URL source；
- MCP adapter；
- Claude API 或内置模型；
- Embedding、向量数据库或 SQLite；
- Web UI；
- Themis lifecycle 正式接线；
- token budget。

延期能力不能以空 command、占位 handler、未接线 reference 或“计划支持”的说明进入首个交付并被声称为可用。

## 7. 自动测试与人工 replay

### 7.1 自动测试

首个交付至少必须提供以下 fresh 自动证据：

- 三种知识类型各自的 typed L2 与固定 L3 校验；
- create、revise、confirm-type、inspect 的成功与失败路径；
- 类型确认后改型被拒绝；
- source path、source drift、大小限制和当前平台可执行的 symlink/junction 安全；
- candidate 与 publish stale revision/generation conflict；
- 两个 writer 基于同一 generation 时只有一个成功；
- payload 写入、generation staging 和 rename 前中断不改变 current state；
- assessment、prepare 和 Approval 精确绑定；
- validate 对直接 relation 的类型、目标存在性与跨 Zone 显式声明进行校验；
- publish 原子写入 record、projection 与 candidate published binding；
- generation chain 连续性、parent digest 与 current payload 完整性校验；
- `init` 产生的 `core/`/`workspace/` 分离，store payload 不逃逸到包根或 `core/`，已安装 control plane 时仍能初始化并保持其 bytes 不变，且失败初始化只回收本次创建的空目录；
- L1 基础过滤、exact-ID L2/L3、byte budget exact boundary；
- record、projection、content 或 manifest binding 篡改后读取失败关闭；
- CLI help、缺参、unknown command、strict JSON 和单一 envelope；
- Skill tree、operation reference 与唯一 factory 加载合同。

测试只能对实际运行的平台声明通过。当前权限或平台无法执行的 junction、race detector 或其他保证必须明确标记 unavailable，不能推断为 PASS。

### 7.2 人工 replay

必须使用构建出的 `themico` CLI 在临时 repository replay 并记录：

1. `design_decision` 完整发布与 L1/L2/L3 读取；
2. `development_standard` 完整发布与 L1/L2/L3 读取；
3. `development_experience` 完整发布与 L1/L2/L3 读取；
4. 类型确认后 revise 改型被拒绝；
5. source drift 阻止 validate、prepare 或 publish；
6. 错误或 stale Approval 阻止 publish；
7. 并发 generation conflict 不覆盖获胜 generation；
8. 投影或 content 篡改导致 query/inspect 失败关闭；
9. byte budget 不足返回 `budget_exceeded` 且不截断 L3。

每个 replay 必须记录实际输入、command、result status、generation before/after 和 observed files。

## 8. 独立验收集合

只有以下条件全部具有 fresh evidence，且 acceptance mapping 没有未裁决 GAP，才能报告“首个可用交付完成”：

1. 三种知识类型、两个 Zone 和唯一 compatibility 映射可运行且拒绝未知值。
2. 三种类型的 L1、typed L2 和固定中文 L3 合同均被严格校验。
3. candidate create、revise、confirm-type、inspect 形成不可变、可追溯且并发安全的链路。
4. 类型确认与 publication Approval 是两个独立 Human gate，且 CLI 只校验声明与精确 binding。
5. source 使用实际本地 bytes digest，路径 escape、source drift 和超限输入失败关闭。
6. validate 覆盖本范围定义的类型、内容、digest、currentness、source 和直接 relation 完整性。
7. independent assessment 绑定 exact candidate revision，checker identity 字段与 proposer 不同。
8. prepare 冻结 expected generation、全部 digest、record identity 和完整 write set。
9. Approval 精确绑定 `operation=publish`、prepare identity 和 prepare digest。
10. publish 以一个 generation commit 原子创建 active record、L1/L2、治理工件、record pointer 和 candidate published binding。
11. 初始化、generation chain、不可变写入、中断和并发 conflict 均有自动证据。
12. query 默认只返回 current active L1，并支持本范围定义的确定性过滤和稳定排序。
13. exact-ID inspect 能返回 L1/L2/L3，并实施实际 byte budget；预算不足不截断完整 item。
14. 每次读取校验 record、projection、content、digest 和 manifest pointer binding，篡改时失败关闭。
15. `views.json` 保持 canonical 空对象，未被声明为聚合索引或 query authority。
16. 核心 CLI command surface 可构建、可运行，stdout 只有一个严格 result envelope。
17. 单一公共 `themico` Skill 只加载一个 operation reference 和 registry 选择的一个 factory；references 位于 `.themico/core/`，发现入口位于 `.claude/skills/themico/SKILL.md`。
18. `init` 建立 `core/` 与 `workspace/` 分离，store payload 全部落在 `workspace/` 内，`core/` 不被 generation commit 写入；控制面与工作区可按任意顺序安装。
19. 自动测试、人工 replay、`go test ./... -count=1`、`go vet ./...`、`go build ./...` 和 `git diff --check` 均有 fresh 结果；无法证明的项目显式标记 GAP 或 unavailable。
20. 产品说明只陈述实际可用能力，并明确本文件第 6 节能力尚未交付。
21. 没有新增 Python、产品 YAML、功能版本、版本目录或计划外外部集成。

该判定只证明本实施切片完成，不表示完整 Themico 设计的全部生命周期、关系、投影和集成目标已经实现，也不等于用户接受或 push 授权。

## 9. 剩余实施计划输入

实施计划必须保留已经完成的基础任务，并把剩余工作重组为以下可独立审查的任务：

1. 最小确定性校验；
2. assessment、prepare、Approval 与 publish；
3. record inspect 和基础 query；
4. 核心 CLI command surface；
5. 单一 `themico` Skill 与必要 references；
6. E2E、并发、中断和安全测试；
7. README、人工 replay 与验收证据。

计划不得把第 6 节延期能力重新放回首个交付门槛。每个任务仍需独立实现、测试、提交和 review，最终还需 whole-branch review 与 fresh 完成证据。
