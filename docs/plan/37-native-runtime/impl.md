# Plan 37：Native Runtime

> 状态：实施设计，待用户单独确认。只有 Plan 36 的实施结果已被用户另行接受后，Plan 37 才可进入实施确认；本计划不会因依赖满足而自动获批。

## 1. 目标

实现 Themis 的首个新生产确定性运行时：一个无功能版本的 Go module、一个 `themis` CLI，以及支撑八个领域的跨平台确定性操作。

运行时负责严格解析、校验、投影、状态、事务、路径、锁、Git identity、命令执行和恢复；Prompt 与 Agent 继续负责意图理解、方案取舍、风险判断、Review 决策、Verification 语义解读、Human Acceptance 决定和知识价值判断。

实现必须遵循 Plan 36 已接受的语言中立合同，不通过 Go 代码重新定义合同。

## 2. 确认与依赖

- 硬依赖：Plan 36 已实施并被用户单独接受。
- 间接依赖：Plan 35 已接受，因为 Plan 36 依赖它。
- 实施前置：用户必须针对 Plan 37 明确授权。
- 合同歧义必须返回 Plan 36 处理；语义流程歧义必须返回 Plan 35 或所属正式设计处理。
- Plan 80 与 Plan 90 不是 Plan 37 的依赖，也不得阻塞核心运行时。

## 3. 核心技术约束

- 一个无版本 Go module；不得建立功能性 `v1`、`v2` module path 或版本目录。
- 一个用户入口：`themis` CLI。
- 使用 native Go facilities 或明确审查后的 Go libraries 处理 YAML、hash、Git object IDs、path safety、locks、transactions 和 recovery。
- 生产路径不得有 `.sh` fallback。
- 生产运行时不得依赖 `yq`。
- 允许执行 manifest/Plan/policy 明确引用的项目命令，作为受约束 child process；不得把 Themis 自身确定性逻辑委托给 shell 脚本。
- 跨平台支持至少覆盖 Windows、Linux 和 macOS 的构建、路径、锁、进程、原子写入和测试。
- Go 不拥有语义判断，不自行生成或批准 Spec、Plan、Review、Acceptance 或 Knowledge decision。

## 4. CLI 范围

CLI 命令名称和参数在实施时应从 Plan 36 protocol operation 派生，保持稳定、无功能版本。至少提供以下能力组：

```text
themis init ...
themis spec ...
themis context ...
themis lifecycle ...
themis plan ...
themis review ...
themis implementation ...
themis verification ...
themis delivery ...
themis knowledge ...
```

这些 capability group 不意味着 Go 进行语义创作。典型职责：

- `validate`：strict schema/protocol validation；
- `inspect/currentness`：解析 identity、digest 和 stale reason；
- `project`：从 machine source 生成 canonical Human projection；
- `record/apply`：在满足已给定决定和前置条件时执行原子写入；
- `transition`：运行 validator-backed lifecycle transition；
- `run`：执行被明确声明的项目 Gate；
- `recover`：恢复中断事务并报告稳定结果。

所有 Agent 消费接口应输出机器可读 JSON；人类文本输出不得成为唯一结果来源。

## 5. 包架构

最终包名可在实施时调整，但职责必须清楚且不按版本目录拆分。建议：

```text
cmd/themis/             CLI entrypoint
internal/contract/      Plan 36 schemas/protocols and validation
internal/canonical/     canonical encoding, projection, digest
internal/workspace/     workspace discovery, manifest, compatibility
internal/safepath/      root confinement, traversal/symlink controls
internal/gitid/         Git object ID and revision observation
internal/lock/          cross-platform locks
internal/txn/           staging, commit, rollback, recovery
internal/process/       explicit project child commands
internal/init/          fresh-only Init
internal/spec/          Spec validation/currentness/projection/publish
internal/context/       Catalog/search/bundle/freshness/signal/navigation
internal/lifecycle/     transitions and state records
internal/plan/          DAG and traceability validation
internal/review/        binding and authorization checks
internal/implementation/ scope/ready-set/evidence recording
internal/verification/  Gate attempts, Run/Evidence, verdict inputs
internal/delivery/      Acceptance recording and Summary projection gates
internal/knowledge/     approved transaction application and reread verify
```

包只能共享通用 primitives，不得因方便将不同批准、锁、事务或恢复边界合并为一个万能 executor。

## 6. 基础设施设计

### 6.1 YAML 与 strict validation

- 使用 Go YAML parser 读取 source，并在应用层执行 Plan 36 的 unknown-field、type、enum 和 invariant 检查。
- 禁止 silent coercion、duplicate key ambiguity 和未声明默认成功。
- 输出 stable issue IDs、paths 和 machine result。
- Contract files 保持单一 current 定义；代码生成或嵌入策略不得制造第二份规范。

### 6.2 Canonicalization、hash 与 Git identity

- 按 Plan 36 定义生成 canonical bytes 与 digest。
- hash algorithm、prefix 和编码从合同读取或集中实现，禁止领域各自拼装。
- Git revision 必须使用 Git object ID 语义；可调用 `git` executable 查询 repository facts，但不得解析易变的人类展示文本。
- dirty working tree、untracked inputs、unborn branch 和非 Git workspace 必须有明确结果。

### 6.3 Path safety

所有写入前执行：

- 目标 root canonicalization；
- relative path validation；
- traversal 与 absolute path 拒绝；
- Windows drive/UNC 和 separator 处理；
- symlink/junction/reparse-point escape 防护；
- case sensitivity/collision 检查；
- reserved names、unsafe replace 和 cross-device rename 处理。

不得以字符串前缀比较替代真实路径约束。

### 6.4 Locks、transactions 与 recovery

- 锁粒度按 Workspace、artifact 或 protocol operation 的不可分割边界确定。
- 每个事务持久记录 ID、operation、preconditions、staged writes、backup/rollback data 和 phase。
- 写入采用同目录 staging、fsync/close、atomic replace 能力；平台不支持时必须 fail closed 或使用合同允许的安全策略。
- 中断后 `recover` 可决定 resume、rollback 或 require-human，不得猜测成功。
- retry 必须幂等；已经提交的 request 返回已观察结果，不重复副作用。

### 6.5 Child process

允许的项目命令必须来自受治理的 manifest/Plan/policy reference，并执行：

- argv array，不通过 shell 字符串解释；
- 明确 working directory；
- environment allow-list/overrides；
- timeout 与 cancellation；
- stdout/stderr 独立捕获和大小策略；
- exit code、signal/termination 与 start failure 分类；
- 不记录 secret values；
- 精确 command identity 写入 attempt/evidence。

不允许 fallback 到仓库中的 `.sh` 来实现 Spec、Context、lifecycle、projection 或 transaction。

## 7. 能力实现

### 7.1 Fresh Init

- 实现 Plan 36 fresh-only Init preflight、source inventory、staging、publish、rollback 和 post-verify。
- 已存在 `.themis/` 时在任何写入前失败并保留 Workspace。
- 安装 Core、Workspace、Project Skill 和可逆 guidance import 时保持事务一致性。
- 不提供 Core 原地更新、Workspace migration 或 Artifact schema conversion。
- 不依赖 Bash 或 `yq`；CLI binary 是生产入口。

### 7.2 Spec operations

- strict validate Spec machine source；
- 创建/发布 candidate 的文件与事务操作；
- canonical `spec.md` projection；
- current pair/digest 检查；
- validator-backed transition input；
- 不执行 requirement questioning 或语义 readiness 判断，除非 Prompt 已提供合同规定的显式决定/字段。

旧 shell publisher 只能作为迁移期间的实现事实被测试对照，不能成为新生产 fallback。

### 7.3 Context operations

- Catalog validate/update；
- exact ID resolution、search、bundle assembly；
- source digest 与 code revision binding；
- freshness checks、Signal record、navigation projection；
- Context write transaction 和 reread verification support。

Search ranking 或摘要不能建立事实；执行器返回来源和限制，由 Agent 作语义选择。

### 7.4 Lifecycle operations

- 按 Plan 36 validators 执行 transition；
- 原子记录 current state、history 和 artifact refs；
- 前置失败时零 mutation；
- Human Acceptance 与 Summary 作为 Verified 后的强制 Gate，不新增 lifecycle status；
- Archived 仍需满足正式设计规定的 Acceptance、Summary、Outcome/知识处置条件。

### 7.5 Planning、Review、Implementation

- Plan strict validation、Task DAG、ready set 和 traceability coverage；
- Review binding/currentness 与 `approved` authorization 检查；
- Implementation Task authorization、scope/path checks、pre/post revision 和 evidence skeleton；
- Go 不拆 Task、不判断设计风险、不批准 Review、不编写代码。

### 7.6 Verification

- 从受治理来源解析 Gate；`null` 或缺失 command 不得被替代。
- 创建 Run/Gate attempt，执行显式项目命令，保存 output refs 和 status。
- 校验 coverage、currentness 和 blocking semantics，为 Prompt/规则计算 verdict 提供确定性输入；若 Plan 36 已将 verdict 聚合完全定义为确定性规则，则按合同计算。
- 任一必需 evidence 缺失或 stale 时不得输出 `pass`；稳定返回 `inconclusive` 输入或 verdict。
- 代码/配置/批准工件变化使受影响 evidence 失效。

### 7.7 Delivery

- Acceptance recorder 只接受引用 current Verification `pass` 的显式人类决定。
- `accepted`/`rejected` 决定必须由人提供，Go 只验证和持久化。
- Summary projector 只有在 durable `accepted` record current 时运行。
- Summary 是 deterministic Human projection，不是 state、Outcome 或新 decision。

### 7.8 Knowledge

- 接收 Prompt/人已完成的 candidate disposition 和 exact approved content/patch。
- 重做 deterministic precondition、conflict、digest 和 path checks。
- 在锁和事务中应用 governed source 与 Catalog 变更。
- reread 并验证 post-write content/digest 后才记录 `applied`。
- Go 不判断候选是否值得提升，也不替人批准。

## 8. 旧生产路径处置

实施必须先盘点现有 `bin/*.sh` 与 `templates/.themis/core/**/*.sh` 的入口和调用者，并制定可审阅切换：

- 新安装和新 Core 使用 `themis` CLI 作为生产确定性入口。
- 不保留生产 `.sh` fallback。
- 不允许 Go 在失败后偷偷调用旧 shell。
- 旧脚本可在同一实施中删除、退役或仅保留为非生产迁移期对照，具体处置必须在 Task scope 中逐文件批准。
- 现有 shell 测试应迁移为 Go tests 或改为调用 compiled CLI 的端到端测试；最终生产可用性不得依赖 Bash/`yq`。

由于当前产品不提供原地 update/migration，本计划不承诺自动升级已安装 Workspace。

## 9. 测试策略

### 9.1 Unit tests

每个基础包覆盖：

- strict parse/validation；
- canonical bytes/digest；
- safe path 与平台边界；
- Git identity cases；
- lock contention；
- transaction phases、rollback、crash recovery；
- child process timeout/cancel/output；
- domain validators 和 projection determinism。

### 9.2 Contract conformance

- 读取 Plan 36 的 `tests/contracts` corpus。
- 对每个 case 验证 status、issue IDs、output bytes/digest 和 side-effect boundaries。
- 同一 corpus 在支持的平台上产生相同合同结果。

### 9.3 Integration tests

- fresh Init success、existing install fail-before-write、partial failure rollback；
- Spec publish/currentness/project；
- Context catalog/search/bundle/freshness/signal；
- lifecycle precondition failure 与 atomic success；
- Task DAG、Review stale binding、Implementation scope violation；
- Gate run pass/fail/error/timeout/unavailable；
- insufficient evidence → `inconclusive`；
- non-pass Acceptance rejection；
- `pass` without durable `accepted` → no Summary；
- Knowledge conflict/apply/reread/rollback/recovery。

### 9.4 Cross-platform

CI 或等效可重复环境至少覆盖：

- Windows；
- Linux；
- macOS；
- path separator/case/drive/symlink variants；
- process termination、file replace 和 lock behavior；
- `go test ./...` 与 production build。

如果某平台未实际运行，不能声称跨平台完成。

### 9.5 Security and resilience

- traversal、symlink/junction escape、archive/source path injection；
- malicious YAML、duplicate keys、resource limits；
- command argv/env injection；
- secret redaction；
- concurrent writers、stale lock、disk-full/permission/interruption；
- transaction recovery 不重复副作用或丢失原文件。

## 10. 任务拆分

### T37-01 Runtime skeleton

- 确认 Go toolchain policy、module root、CLI layout 和构建产物。
- 建立 machine-readable result/exit contract 和测试基线。
- 不创建功能版本 module path。

### T37-02 Contract engine

- 实现 strict YAML、canonicalization、digest、references 和 issue reporting。
- 通过 Plan 36 基础与 projection fixtures。

### T37-03 Platform primitives

- 实现 safepath、Git identity、locks、transactions、recovery 和 process runner。
- 完成平台专项单元/集成测试。

### T37-04 Fresh Init

- 实现 fresh-only transaction。
- 切换新安装生产入口，验证 no Bash/no `yq` runtime dependency。

### T37-05 Spec 与 Context

- 实现全部确定性 Spec/Context operations。
- 与 Plan 35 Prompt handoff 和 Plan 36 fixtures 对齐。

### T37-06 Lifecycle、Planning、Review、Implementation

- 实现 transition、DAG、binding、ready set、scope 和 evidence skeleton。
- 验证 Review-before-Implementation invariant。

### T37-07 Verification 与 Delivery

- 实现 child Gate attempts、evidence、verdict contract、Acceptance record 和 Summary gate/projection。
- 验证 Verification-after-Implementation 及 `pass + accepted` 顺序。

### T37-08 Knowledge transactions

- 实现 approved apply、Catalog update、reread verification、rollback/recovery。
- 验证无人工批准不能写正式 Context。

### T37-09 Production cutover

- 枚举并处理旧 shell/yq 生产调用者。
- 删除所有生产 fallback，迁移测试和 guidance。
- 确认新安装只暴露 `themis` CLI 的确定性入口。

### T37-10 Full conformance

- 运行 unit、contract、integration、security 和三平台矩阵。
- 执行人工 Prompt-to-runtime 端到端验收。
- 汇总未支持项；任何缺口都不得包装为完成。

## 11. 验证矩阵

| 能力 | 成功证据 | 必需失败/边界证据 |
|---|---|---|
| Build | 单 module、单 CLI 在三平台构建 | 无功能版本路径 |
| YAML/contracts | 全部 valid fixtures 通过 | unknown/invalid/unsupported fail closed |
| Canonicalization | expected bytes/digests 一致 | 输入变化导致 digest/currentness 变化 |
| Paths | 合法 root 内操作 | traversal、absolute、symlink/junction escape 拒绝 |
| Locks/txn | atomic commit、idempotent retry | contention、crash、rollback/recovery |
| Init | fresh install 完整 post-verify | existing install 写前失败、partial rollback |
| Spec/Context | operations 与 fixtures 一致 | stale/conflict/unavailable 稳定结果 |
| Lifecycle | 合法 transition 原子记录 | 前置失败零 mutation |
| Plan/Review/Impl | DAG/ready/binding/scope 正确 | cycle、stale Review、越界 Task 拒绝 |
| Verification | exact child command 与 evidence | missing/stale evidence 不得 `pass` |
| Delivery | current `pass` + durable `accepted` 后 Summary | 其他组合全部拒绝 Summary |
| Knowledge | approved apply + reread 后 `applied` | 未批准、drift、reread mismatch 不成功 |
| Production deps | binary 运行不需要 Bash/`yq` | 无 `.sh` fallback 路径 |

最终还需执行 repository-required checks、`go test ./...`、production build、contract corpus、三平台 CI/等效证据和 `git diff --check`。

## 12. 完成与接受条件

- 一个无功能版本 Go module 和一个 `themis` CLI 已实现并可构建。
- Fresh Init、Spec、Context、lifecycle 以及支撑八领域的确定性 operations 已实现。
- 所有 Plan 36 contract fixtures 通过，失败结果和副作用边界稳定。
- 新生产运行时无 `.sh` fallback、无 `yq` runtime dependency。
- 显式项目命令只通过受约束 child process 执行。
- Windows、Linux、macOS 均有实际测试证据。
- Review-before-Implementation、Verification-after-Implementation、`pass + durable accepted → Summary` 由运行时强制。
- Knowledge 只有在批准、应用和 reread verification 后报告成功。
- Go 未吸收语义判断；Prompt/Agent ownership 保持可审计。
- 未支持或未验证能力被明确报告，没有虚构成功。
- 用户审阅实际验证 evidence 并另行明确接受 Plan 37。
