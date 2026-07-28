# Plan 36：Deterministic Assurance

> 状态：实施设计，待用户单独确认。只有 Plan 35 的实施结果已被用户另行接受后，Plan 36 才可进入实施确认；依赖满足也不构成自动授权。

## 1. 目标

为 Themis 定义语言无关、严格、可被未来运行时实现和测试的确定性合同，使 Prompt-first 语义流程可以依赖明确的机器输入、输出、currentness、transition、事务和投影语义，而不绑定 shell、Go 或任何特定实现语言。

本计划覆盖：

- Schemas；
- General protocols；
- Canonical projections；
- Artifact currentness；
- Stale-artifact handling；
- Lifecycle transitions；
- Plan Task DAGs；
- Review binding；
- Implementation scope；
- Verification Gate attempts；
- Human Acceptance；
- Summary；
- Knowledge transactions；
- Fresh-only Init。

Plan 36 只定义 strict contracts 和非 shell 合同夹具，不实现 production runtime。正式领域语义仍由 `docs/design/**` 定义，本文只设计如何把已确认语义转成可验证合同。

## 2. 确认、依赖与边界

- 硬依赖：Plan 35 已实施并被用户单独接受。
- 实施前置：用户必须针对 Plan 36 明确授权。
- Plan 36 接受后只使 Plan 37 具备单独评审条件，不自动授权 Plan 37。
- 不引入功能性模块版本、`v1`/`v2` 目录或协议版本树；每个合同只有一个 current definition。
- 兼容性只在 Core、Workspace、Artifact 顶层边界按正式设计处理，不把功能演进编码为模块版本。
- Plan 36 不改变 Prompt/Agent 的语义所有权，也不让 Schema 或 validator 判断需求是否合理、Review 是否应批准或知识是否有价值。

## 3. 设计原则

### 3.1 语言中立

合同必须以实现无关方式说明：

- 输入和输出字段、类型、枚举、必需性和约束；
- canonical serialization 与 digest 边界；
- stable identifier、reference 和 revision binding；
- 状态前置、原子副作用、失败分类和 exit/result 语义；
- invalid、stale、conflict、unsupported 与 unavailable 的 fail-closed 行为；
- 幂等性、锁、事务、rollback 和 recovery 要求。

不得使用“某段 shell 的当前行为”作为唯一合同，也不得把某种 Go API 形状提前写成规范。

### 3.2 严格拒绝

- 未知字段、未知枚举、非法路径、重复 ID、悬空引用、循环依赖、digest 不匹配和 unsupported schema 必须有明确拒绝语义。
- 缺失或不确定的信息不能通过默认值伪装为成功。
- Validator 必须区分结构无效、currentness 失败、policy conflict、evidence insufficient 和 runtime unavailable。
- validator 输出优先为稳定机器可读结果；人类消息是派生说明。

### 3.3 currentness 优先

每个跨工件 Gate 必须绑定 current artifact identity，而不是只检查路径存在：

- artifact ID 和类型；
- source/current revision 或 Git object ID；
- canonical digest；
- 上游引用及其 digest；
- policy/manifest binding；
- 生成或批准 actor/time；
- invalidation reason 和 replacement reference。

## 4. 合同范围

### 4.1 Schema 基础

定义可复用的 strict primitives：

- ID、relative path、timestamp、actor、digest、Git object ID；
- artifact reference、source reference、command reference、evidence reference；
- scope selector、AC reference、Task reference、Gate reference；
- validation issue、result envelope、error category；
- transaction ID、lock owner、attempt ID 和 recovery marker。

明确 canonical encoding、排序、空值、Unicode、换行和禁止歧义的规则。任何 schema composition 都不得形成版本目录。

### 4.2 General protocols

为确定性操作建立通用 envelope：

- request identity、operation、workspace root 和 expected state；
- resolved inputs 与 source digests；
- dry-run/validate/apply 等允许模式；
- machine result、issues、observed state、written paths 和 recovery info；
- stable exit semantics；
- 幂等 retry 与重复 request 的处置。

协议需区分 semantic decision input 与 deterministic assertion；执行器只能消费已明确给出的语义决定，不自行发明决定。

### 4.3 Canonical projections

定义 machine semantic source 到 Human projection 的纯函数合同，包括至少：

- Spec；
- Plan；
- Review；
- Verification；
- Human Acceptance；
- Summary；
- 必要的 Context/Knowledge review projection。

每个 projection 合同必须规定：

- 唯一 source artifact；
- source digest 嵌入或可验证绑定；
- 稳定章节和排序；
- escaping、缺失字段和多值呈现；
- 手工编辑后的 stale/invalid 处置；
- 相同输入产生字节稳定输出。

Projection 不成为独立事实源，也不记录 machine transition。

### 4.4 Artifact currentness 与 stale handling

定义统一 currentness algorithm：

1. 解析 artifact 与引用；
2. 验证 schema 和 canonical digest；
3. 验证上游 artifact/revision/digest；
4. 验证当前代码或 manifest binding；
5. 验证替换、废弃和 invalidation marker；
6. 输出 `current`、`stale`、`invalid`、`conflict` 或 `unavailable` 及稳定原因。

Stale artifact 必须保留审计记录，不得通过重写历史 digest 变“新”。需要重新生成、重新批准或重新运行的动作应显式返回，不能自动跨越人工 Gate。

### 4.5 Lifecycle transitions

为以下机器状态迁移定义 strict preconditions、validator 集合、原子写入和失败不变式：

```text
Draft → Specified → Planned → Reviewed → Implemented → Verified → Archived
```

并把 Human Acceptance 与 Summary 定义为 `verified → archived` 间的强制 Gate，而非新 lifecycle status。

合同必须保证：

- Review 在 Implementation 前且 current；
- Verification 只针对 reviewed implementation revision；
- Human Acceptance 只能引用 current Verification `pass`；
- Summary 只能引用 durable `accepted` Acceptance；
- transition 失败不改变 machine state；
- Prompt 文本、Markdown 存在或用户聊天本身不是 transition。

### 4.6 Plan Task DAG

定义 Plan machine source 或可验证结构的合同：

- stable Task ID；
- dependency references；
- acyclic graph；
- deterministic ready set；
- Task scope、owned paths、constraints 与 completion requirements；
- AC → Task → location → Gate → acceptance traceability；
- skipped/removed/changed Task 的再批准规则。

Validator 必须检测 duplicate ID、missing dependency、cycle、uncovered AC、unreachable Task 和不一致 scope lock。

### 4.7 Review binding

定义 Review decision 与以下 current inputs 的不可歧义绑定：

- Spec ID/revision/digest；
- Plan ID/revision/digest；
- Context bundle/reference；
- source/code revision；
- policy/manifest digest；
- findings、disposition 与 unresolved severity；
- actor/time。

只有 `approved` 可授权 Implementation。任何绑定输入变化使授权 stale；`changes_requested` 和 `blocked` 不得被执行器解释为批准。

### 4.8 Implementation scope

定义 Task execution request、authorization 和 observed result：

- current approved Review；
- 当前依赖 ready set；
- allowed Task 和 path/scope constraints；
- pre-state revision/digest；
- actual changed paths、post-state revision、deviation 与 completion evidence；
- partial failure、rollback 和 dirty workspace 语义。

确定性合同校验授权和范围事实，不判断代码实现是否在语义上正确。

### 4.9 Verification Gate attempts

定义 Run、Gate 和 attempt：

- Gate ID、blocking、command source 和 coverage；
- exact argv、working directory、environment allow-list 和 timeout；
- started/completed time、exit code、stdout/stderr refs；
- status：`pending | running | passed | failed | skipped | error`；
- failure classification、repair handoff、rerun lineage；
- implementation revision 和所有批准工件绑定；
- evidence invalidation 与 current attempt selection。

Verdict contract 只允许 `pass | fail | inconclusive`。任何必需 Gate 缺失、unavailable、skipped without authorization、evidence stale 或 coverage 不足都不得产生 `pass`。

### 4.10 Human Acceptance

定义 durable Acceptance record：

- decision：`accepted | rejected`；
- actor/time；
- current Spec/Plan/Review/Verification refs 和 digests；
- performed manual steps 与结果；
- accepted residual risks；
- rejection reason 与 rework target。

Acceptance recorder 必须拒绝非 `pass` 或 stale Verification。聊天回复或未持久 Markdown 不满足 durable record。

### 4.11 Summary

定义 Summary source set 与 deterministic projection：

- 只能消费 current Verification `pass` 和 durable `accepted` Acceptance；
- 引用 accepted Spec/Plan/Review/Verification/Acceptance；
- 包含最终范围、实际变更、AC/evidence、批准偏差、限制和后续事项；
- 不产生 Acceptance decision、Verification verdict、Outcome 或 lifecycle state；
- 任一 source 变化后 Summary stale，必须重新生成并再次验证绑定。

### 4.12 Knowledge transactions

定义从 approved disposition 到 governed Context 写入的事务合同：

- candidate、source evidence、target Context item/path；
- duplicate/conflict/freshness checks；
- human decision 与 exact approved patch/content；
- lock、precondition digest、atomic write、catalog/index update；
- reread 与 post-write digest verification；
- commit/rollback/recovery record；
- `applied`、`pending`、`rejected`、`conflict`、`failed` 等稳定处置。

只有人工批准、实际 apply 和 reread verification 都成功时才能报告正式知识已更新。

### 4.13 Fresh-only Init

定义全新安装的 deterministic contract：

- 目标根、允许创建路径和 path safety；
- preflight：目标 `.themis/` 不存在、必要项目根条件满足；
- Core/Workspace/Skill/guidance 的来源 manifest 与 digest；
- staging、锁、原子发布、失败 rollback；
- 已存在 `.themis/` 时写入前 fail closed；
- 不执行 Core 原地更新、Workspace migration 或 Artifact schema conversion；
- 成功后完整 inventory 和 digest verification。

此合同不等同于实现 installer；Plan 37 才实现首个新生产运行时。

## 5. `tests/contracts` 夹具语料库

新增非 shell 的 `tests/contracts` fixture corpus，用于任何未来实现的语言中立一致性验证。夹具本身以数据和 expected result 表达，不通过 `.sh` 作为合同入口。

建议布局按职责而不是版本组织：

```text
tests/contracts/
  schema/
  projection/
  currentness/
  lifecycle/
  plan-dag/
  review-binding/
  implementation-scope/
  verification/
  acceptance/
  summary/
  knowledge/
  init/
```

每组至少包含：

- valid minimal；
- valid complete；
- unknown field；
- missing required；
- invalid enum/ID/path/digest；
- stale binding；
- conflict；
- unsupported top-level compatibility；
- deterministic expected canonical output；
- failure expected result/issue IDs。

夹具格式必须能被多语言 runner 读取；如需夹具 manifest，应定义稳定 case ID、input refs、operation、expected status、expected issue IDs 和 expected output digest。

## 6. 明确非目标

- 不实现 `themis` CLI 或任何 production runtime。
- 不以 shell、Go 或其他语言编写生产 executor。
- 不替换现有 Init、Spec 或 Context 实现。
- 不增加生产 `.sh` fallback，也不决定 Plan 37 的内部 API。
- 不执行 lifecycle transition、Knowledge write 或 Summary generation。
- 不实现多 Agent 调度或 Attribution analytics。
- 不把 Prompt/Agent 语义判断搬入 schema、fixture 或 validator contract。

## 7. 拟议文件类别

实施开始时需根据当前 checkout 精确定位。预期范围：

- `templates/.themis/core/protocols/`：general、artifact、lifecycle 和领域 strict contracts。
- `templates/.themis/core/policies/`：稳定 transition、Gate、invalidation 和 transaction 控制声明。
- `templates/.themis/core/templates/`：machine source/human projection 对应模板，仅作为合同一部分时修改。
- `templates/.themis/workspace/`：为 current state、runs、evidence、Acceptance、transaction 等提供无实现的目录/manifest contract，如正式设计允许。
- `tests/contracts/`：语言中立 fixture corpus 和 expected outputs；不得创建 shell test runner。
- `docs/design/**`：只在合同细化需要确认长期设计时同步更新。

所有模块和协议目录保持无功能版本。

## 8. 任务拆分

### T36-01 合同盘点与术语表

- 将 Plan 35 的语义输入/输出映射到当前 schemas、policies、templates 和缺口。
- 建立 stable IDs、result categories、currentness 和 digest 术语。
- 标出设计问题并在写合同前取得裁决。

### T36-02 Strict primitives 与 general protocol

- 定义共用 types、references、canonicalization、result envelope、issues 和 idempotency。
- 为 unknown/invalid/unsupported 输入建立 fail-closed 规则。

### T36-03 Artifact 与 projection

- 定义 artifact identity、currentness、stale handling 和 canonical projection。
- 为 Spec/Plan/Review/Verification/Acceptance/Summary 建立 expected canonical fixtures。

### T36-04 Lifecycle 与 Task/Review/Implementation

- 定义 transition validators 和原子 state change。
- 定义 Task DAG、Review binding、ready set、scope authorization 与 invalidation。

### T36-05 Verification、Acceptance 与 Summary

- 定义 Run/Gate/attempt/evidence/verdict。
- 锁定 `pass → durable accepted → Summary` 顺序并建立负例夹具。

### T36-06 Knowledge transaction 与 fresh Init

- 定义 approved write、锁、事务、reread verification、rollback/recovery。
- 定义 fresh-only Init、安全路径、staging 和 existing-install fail-closed。

### T36-07 Fixture corpus

- 为所有合同编写 valid、invalid、stale、conflict 和 deterministic-output cases。
- 校验 fixture manifest 引用完整、case ID 唯一、expected digest 可复算。

### T36-08 跨合同一致性审查

- 检查同一字段、状态、digest 和引用在各合同中语义一致。
- 检查每个 Plan 35 handoff 都有对应合同或明确保留为 semantic-only。
- 检查合同没有泄漏特定语言实现或语义判断。

## 9. 验证矩阵

| 领域 | 必需验证 |
|---|---|
| Schema | valid 接受；unknown/missing/invalid 稳定拒绝 |
| Canonicalization | 相同语义输入产生相同字节与 digest |
| Currentness | revision/digest/reference 任一变化均产生明确 stale reason |
| Lifecycle | 前置不满足时零 state mutation；成功写入原子且可审计 |
| Plan DAG | cycle、duplicate、missing dependency、uncovered AC 均被发现 |
| Review | 只有 current `approved` 可授权；输入变化使其 stale |
| Implementation | 非 ready Task、越界 path 和 stale authorization 被拒绝 |
| Verification | 缺失/跳过/stale evidence 不得产生 `pass` |
| Acceptance | 非 current `pass` 无法写 `accepted` |
| Summary | 缺少 durable `accepted` 无法投影；相同 sources 输出稳定 |
| Knowledge | 无批准、precondition drift、apply/reread 失败均不报告 applied |
| Init | existing `.themis/` 写前失败；partial failure 可 rollback/recover |
| Fixtures | 所有 case 引用有效、expected issue IDs 稳定、无 shell runner |

还必须运行与修改文件相关的现有 schema/template 检查和 `git diff --check`。若当前仓库没有可执行合同 validator，本计划只能验证合同自洽、fixture 可解析和 expected digests 的独立复算，不得宣称 production conformance。

## 10. 完成与接受条件

- 所列十四类合同均有唯一 current、语言中立定义。
- `tests/contracts` 覆盖正例、负例、stale、conflict 和 canonical output，且不依赖 shell runner。
- Review-before-Implementation 和 Verification-after-Implementation 可由合同结构强制检查。
- Verification 不足证据无法得到 `pass`。
- Summary 无法绕过 current `pass` 与 durable `accepted`。
- Knowledge 无法绕过人工批准、实际应用和 reread verification。
- Fresh Init 对已有安装 fail closed，不隐式提供 upgrade/migration。
- 没有 production runtime、executor 或 CLI 被实现或宣称可用。
- 没有功能性模块版本或版本目录。
- 实际验证结果已交给用户，用户另行明确接受 Plan 36。

Plan 36 的接受只确认合同阶段完成；Plan 37 仍需单独实施确认。
