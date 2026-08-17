# Themico 首个可用交付：实现证据

## 0. 本证据的范围声明

本文档只覆盖 [`docs/superpowers/specs/2026-07-29-themico-design/first-usable-delivery.md`](../../superpowers/specs/2026-07-29-themico-design/first-usable-delivery.md) 第 8 节定义的 21 条独立验收集合，用于判定"首个可用交付"这一实施切片是否完成。

**本证据不构成** [`docs/superpowers/specs/2026-07-29-themico-design/acceptance.md`](../../superpowers/specs/2026-07-29-themico-design/acceptance.md) 完整 38 条目标的完成判定——那是 Themico 顶层设计的全部验收集合，包含首个交付明确延期的生命周期、关系遍历、聚合 view、外部集成等能力。首个可用交付完成不表示这些目标已经达成，也不等于用户接受或获得 push 授权。

提交 SHA：`c168d5a47d9164bea7d33afc37b3b814ef93c2e1`（任务 12 执行前的 HEAD；本任务只新增文档，不改动该 SHA 下的任何 Go 代码）。

**2026-08-17 补记**：终审修复波（提交 `e54cfed`、`c558594`）之后，一次定向再评审发现两项残留缺陷，已作为第 3 节缺陷 3、缺陷 4 补入本文档，并在第 2 节条目 7 补充如实说明；两项均已裁定延期到后续独立计划，不改变第 2 节 21 条独立验收集合的判定，也不改变第 1 节记录的 fresh verification 结果。

---

## 1. Fresh Verification（步骤 2）

以下命令均在 `C:/Coding/Themis/.claude/worktrees/themico-core` 下执行，平台 `go1.26.5 windows/amd64`，执行时间 2026-08-17（UTC 上午）。

### 1.1 `go build ./...`

```
$ go build ./...
```

exit code：`0`，无输出（构建成功）。

### 1.2 `go vet ./...`

```
$ go vet ./...
```

exit code：`0`，无输出（无问题）。

### 1.3 `git diff --check`

```
$ git diff --check
```

exit code：`0`，无输出（执行时工作树对已跟踪文件无未提交改动，因此无冲突标记/尾随空白可检查）。

### 1.4 `go test ./... -count=1`

```
$ go test ./... -count=1
?   	github.com/zhanyan-Ader1y/Themis/cmd/themico	[no test files]
ok  	github.com/zhanyan-Ader1y/Themis/internal/themico/candidate	10.830s
ok  	github.com/zhanyan-Ader1y/Themis/internal/themico/canonical	0.422s
ok  	github.com/zhanyan-Ader1y/Themis/internal/themico/cli	0.484s
ok  	github.com/zhanyan-Ader1y/Themis/internal/themico/governance	6.406s
ok  	github.com/zhanyan-Ader1y/Themis/internal/themico/integration	18.935s
ok  	github.com/zhanyan-Ader1y/Themis/internal/themico/model	0.496s
ok  	github.com/zhanyan-Ader1y/Themis/internal/themico/query	15.052s
ok  	github.com/zhanyan-Ader1y/Themis/internal/themico/result	0.581s
ok  	github.com/zhanyan-Ader1y/Themis/internal/themico/store	13.030s
ok  	github.com/zhanyan-Ader1y/Themis/internal/themico/validate	10.354s
```

exit code：`0`。10 个有测试的包全部 `ok`，`cmd/themico` 无测试文件（只是 `main` 的极薄入口，逻辑全部委托给 `internal/themico/cli`，由 `internal/themico/cli`、`internal/themico/integration` 两个包间接覆盖）。

**用 `-v` 复跑一次，统计精确的测试数量与 skip 数量**（同一 commit、同一命令，独立执行一次）：

```
$ go test ./... -count=1 -v
```

统计结果（对 `-v` 输出做行级计数，非估算）：

| 统计项 | 数量 |
|---|---|
| 顶层 `Test*` 函数（`=== RUN Test...`，不含子测试） | 139 |
| 子测试（`=== RUN Test.../...`） | 153 |
| 测试节点总数（顶层 + 子测试） | 292 |
| `PASS`（含子测试） | 285 |
| `FAIL`（含子测试） | 0 |
| `SKIP`（含子测试） | 7 |

**如实记录：本次运行观察到 7 个 SKIP，而非任务 11 报告单独运行 `internal/themico/integration` 时记录的 1 个**。这不是矛盾——任务 11 的报告只统计了它当时新增/运行的 `internal/themico/integration` 单个包（该包本身确实只有 1 个 SKIP：`TestCandidateCreateRejectsSymlinkSourceEscape`）；本任务按 brief 步骤 2 的要求对整个 `go test ./...` 做了一次完整、独立的 `-v` 复跑，观察到全仓库范围内还有另外 6 个 SKIP 分布在 `candidate`、`store` 两个包里。全部 7 个 SKIP 均如实记录如下，**一律不计为 PASS**：

| 测试 | 所在包 | 原因（真实错误信息） |
|---|---|---|
| `TestCandidateCreateRejectsSymlinkSourceEscape` | `internal/themico/integration` | `os.Symlink` 失败：`A required privilege is not held by the client.` |
| `TestCreateRejectsRootExternalSymlinkWhenFixtureAvailable` | `internal/themico/candidate` | 同上（symlink fixture 不可用） |
| `TestCreateRejectsSourceThroughSymlinkedDirectoryWhenFixtureAvailable` | `internal/themico/candidate` | 同上（目录 symlink fixture 不可用） |
| `TestInitPublicationStaysAnchoredWhenParentPathIsReplaced` | `internal/themico/store` | 同上（parent alias 需要 symlink） |
| `TestCommitPublicationStaysAnchoredWhenStorePathIsReplaced` | `internal/themico/store` | `rename ...workspace ...workspace-relocated`：`The process cannot access the file because it is being used by another process.`（Windows 平台在途 rename 限制） |
| `TestCommitRejectsSymlinkEscapeWhenSupported` | `internal/themico/store` | 同上（symlink 权限） |
| `TestCommitRejectsSymlinkSwapBeforeImmutableCreateWhenSupported` | `internal/themico/store` | 同上（symlink 权限） |

7 个 SKIP 中 6 个的根因相同：本次执行使用的 Windows 账号未持有 `SeCreateSymbolicLinkPrivilege`（未开启开发者模式、非管理员），`os.Symlink` 直接失败，测试诚实 `t.Skip` 并记录了确切系统错误；第 7 个（`TestCommitPublicationStaysAnchoredWhenStorePathIsReplaced`）是 Windows 平台对"目录正被进程占用时不能重命名"的限制，同样诚实跳过。所有 6 个 symlink 相关 SKIP 在同一测试文件里都有一个使用 Windows 目录 junction（`mklink /J`，本环境已验证可创建、无需管理员权限）实现的姊妹用例真实执行并通过，实质性覆盖了"通过文件系统重定向逃逸沙箱根"这一安全属性（例如 `internal/themico/integration/security_test.go:100` 的 `TestCandidateCreateRejectsJunctionSourceEscape`）。这些 SKIP 标记为 **unavailable**，不计入通过数，也不作为已验证结论的依据。

---

## 2. 独立验收集合逐条映射（`first-usable-delivery.md` 第 8 节，21 条）

每条给出唯一的一手证据（代码文件:行号、测试函数、或 `manual-replay.md` 场景编号）。凡找不到 fresh evidence 的条目标记 **GAP**，不使用计划文本或设计文档替代证据。

### 1. 三种知识类型、两个 Zone 和唯一 compatibility 映射可运行且拒绝未知值

- 闭集与拒绝未知值：`internal/themico/model/registry_test.go:318` `TestEnumClosedSets`（对 `KnowledgeType`/`Zone`/`CandidateStatus`/`RecordStatus`/`RelationType` 分别断言合法值 `Valid()==true`、未知值 `Valid()==false`）。
- 唯一 compatibility 映射的强制执行：`internal/themico/candidate/service.go:404-413`（`validateTypeZone` 通过 `model.LookupFactory` 路由并比对 `factory.Zone`），由 `internal/themico/candidate/service_test.go:132` `TestCreateRejectsRegistryAndZoneErrorsWithoutMutation` 覆盖拒绝路径。
- 三个类型均可运行发布：`manual-replay.md` 场景 1（design_decision/project_knowledge）、场景 2（development_standard/project_knowledge）、场景 3（development_experience/project_experience）——三次真实 `publish` 均 `succeeded`，Zone 与设计声明的映射完全一致。

**判定**：满足，有 fresh evidence。

### 2. 三种类型的 L1、typed L2 和固定中文 L3 合同均被严格校验

- `internal/themico/validate/validate_test.go:51` `TestCandidateAcceptsValidRevisionForEachType`（三种类型各自的合法样例通过）。
- `internal/themico/validate/validate_test.go:71` `TestCandidateRejectsMalformedL3`、`:112` `TestCandidateFlagsMissingH1`、`:125` `TestCandidateFlagsInvalidTypedPayload`（结构性拒绝）。
- `internal/themico/model/registry_test.go:49` `TestFactoriesExposeExactL3Headings`（三种类型的固定中文章节清单本身受测）。
- `manual-replay.md` 场景 1/2/3：三次真实 `inspect depth=3` 返回的 L3 markdown 与各自 `content.md` 输入逐字一致，标题顺序与 registry 声明的章节完全匹配。

**判定**：满足，有 fresh evidence。

### 3. candidate create、revise、confirm-type、inspect 形成不可变、可追溯且并发安全的链路

- `internal/themico/candidate/service_test.go:25` `TestCreateBindsCandidatePayloadContentSourcesAndCurrentPointer`、`:82` `TestReviseCreatesImmutableRevisionAndPreservesCandidateAuthority`、`:309` `TestConfirmTypeCreatesBoundRevisionWithoutSemanticDrift`、`:391` `TestInspectUsesOnlyCurrentPointerAndValidatesDigests`。
- 并发安全：`internal/themico/candidate/persist_concurrency_test.go:19` `TestReviseReturnsItsCommittedRevisionWhenCurrentAdvancesBeforeReturn`；stale revision 冲突：`service_test.go:118` `TestReviseRejectsStaleExpectedRevisionWithoutVisibleMutation`。
- 真实链路 replay：`manual-replay.md` 场景 4（confirm-type 后 revise 改型被拒绝，候选类型与 revision 均未变）。

**判定**：满足，有 fresh evidence。

### 4. 类型确认与 publication Approval 是两个独立 Human gate，且 CLI 只校验声明与精确 binding

- 类型确认 gate：`internal/themico/candidate/service.go:168-205`（`ConfirmType`），`manual-replay.md` 场景 4。
- publication Approval gate：`internal/themico/governance/publish.go:40`（`checkApproval`）与 `internal/themico/governance/governance_test.go:21` `TestPublishGatesFailClosed`（子测试覆盖缺失 Approval、错误 operation、错误 digest、空 approver 四种绑定失败）。
- 两个 gate 相互独立的真实证据：`manual-replay.md` 场景 6（Approval 层面的四个子场景）与场景 4（类型确认层面）分别验证，互不依赖。

**判定**：满足，有 fresh evidence。

### 5. source 使用实际本地 bytes digest，路径 escape、source drift 和超限输入失败关闭

- 实际 bytes digest 绑定：`internal/themico/candidate/service.go:334-364`（`bindSources`，`sha256` 直接对读取到的字节计算）。
- 路径 escape：`internal/themico/integration/security_test.go:30` `TestCandidateCreateRejectsAbsolutePathSource`、`:48` `TestCandidateCreateRejectsDotDotSourceEscape`、`:100` `TestCandidateCreateRejectsJunctionSourceEscape`（真实可执行的 junction 逃逸场景）。
- source drift：`internal/themico/validate/validate_test.go:188` `TestCandidateChecksProvidedRelationsAndSources`（`source.stale` 子用例）；`manual-replay.md` 场景 5A/5B/5C（validate/prepare/publish 三个阶段各自独立拦截）。
- 超限输入：`internal/themico/integration/security_test.go:127` `TestCandidateCreateRejectsOversizedInputFile`。

**判定**：满足，有 fresh evidence。

### 6. validate 覆盖本范围定义的类型、内容、digest、currentness、source 和直接 relation 完整性

- `internal/themico/validate/validate_test.go:188` `TestCandidateChecksProvidedRelationsAndSources` 的四个子用例：`relation.type_forbidden`（禁止类型，例如 `supersedes` 不能由首个交付的 validate 承认为可直接声明）、`relation.target_missing`（目标不存在）、`relation.cross_zone_not_explicit`（跨 Zone 未显式声明）、`source.stale`。
- 类型/Zone/内容/digest/currentness：`internal/themico/validate/candidate.go` 全文；`validate_test.go:141` `TestCandidateFlagsUnconfirmedAndUnregisteredType`、`:247` `TestCandidateRejectsStaleRevision`。
- 确定性：`validate_test.go:259` `TestCandidateProducesIdenticalReportsForIdenticalInput`。

**判定**：满足，有 fresh evidence。

### 7. independent assessment 绑定 exact candidate revision，checker identity 字段与 proposer 不同

- 结构校验实现：`internal/themico/governance/assessment.go:14-37`（`checkAssessment`：schema、`status==pass`、candidate ID/revision 精确绑定、checker identity 非空且与 `proposed_by` 不同、`checked_at` 合法 RFC3339）。
- **自动化测试缺口的如实说明**：现有自动化测试（`governance_test.go`、`integration/lifecycle_test.go` 等）里所有会成功走到 `prepare publish` 的 fixture 全部固定使用"checker 与 proposer 不同、status=pass、绑定正确"的 assessment，没有一处显式测试 `checkAssessment` 四条拒绝分支中的任意一条。
- 本任务用 `manual-replay.md` **补充复现材料 C** 补齐了这个空缺：四个真实 CLI 子场景（checker 与 proposer 相同 → `precondition_failed`；绑定错误 revision → `precondition_failed`；`status=fail` → `precondition_failed`；正确绑定 → `succeeded`）逐一对应 `assessment.go` 的判定分支。

**判定**：满足，fresh evidence 来自代码 + 本任务新增的 replay（原有自动化测试对负向分支覆盖不足，已在 replay 中补齐并如实说明）。

**如实补记（终审后定向再评审新增，2026-08-17）**：本条验收要求的字面文本只是"checker identity 字段与 proposer 不同"，这一点持续成立，判定不变。但该独立性检查在 `create → revise → confirm-type → assess` 顺序下会被 `candidate.Service.ConfirmType` 用 `ConfirmedBy` 覆写 `RevisedBy` 的既有行为削弱——原 reviser 的身份从 `RevisedBy` 字段被抹除后，仍可为自己撰写的当前内容出具通过的 semantic assessment。这不影响本条验收的判定，但会削弱顶层设计核心不变量 4 期望的"独立语义评估"；详见本文档第 3 节缺陷 4，以及 README「已知缺陷」第 3 条。publication 仍需要精确绑定 prepare 的独立 Human Approval，第二道 gate 未被削弱。

### 8. prepare 冻结 expected generation、全部 digest、record identity 和完整 write set

- 实现：`internal/themico/governance/prepare.go`（`PreparePublish` 冻结 `ExpectedGeneration`、`CandidateDigest`、`AssessmentDigest`、`L1Digest`/`L2Digest`/`L3Digest`、`RecordID`/`RecordRevision`、四项 `Writes`）。
- `internal/themico/governance/governance_test.go:54` `TestPreparedGenerationMatchesTheStateItsCommitProduces`（`prepare.ExpectedGeneration` 精确等于 prepare 提交后的当前 generation）。
- `internal/themico/governance/governance_test.go:132` `TestPublishRejectsFrozenWriteDrift`（`Writes` 中任一项被篡改后 publish 拒绝）。
- 真实证据：`manual-replay.md` 全部场景的 `prepare publish` 输出均展示完整的 `expected_generation`/五类 digest/四项 `writes`。

**判定**：满足，有 fresh evidence。

### 9. Approval 精确绑定 `operation=publish`、prepare identity 和 prepare digest

- 实现：`internal/themico/governance/publish.go` 中的 `checkApproval`（第 40 行调用点）。
- `internal/themico/governance/governance_test.go:21` `TestPublishGatesFailClosed` 子用例 `"wrong operation"`、`"wrong prepare digest"`、`"missing approval"`、`"empty approver"`。
- `manual-replay.md` 场景 6a/6b：真实 CLI 分别用错误 `prepare_digest`、错误 `operation` 触发 `precondition_failed`，消息分别为 `"approval is not bound to this prepare"`、`"approval operation does not match publish"`。

**判定**：满足，有 fresh evidence。

### 10. publish 以一个 generation commit 原子创建 active record、L1/L2、治理工件、record pointer 和 candidate published binding

- `internal/themico/governance/publish.go:156-172`（单次 `store.Commit` 内写入 record.json/content.md/l1.json/l2.json/candidate.json/candidate content.md/approval，并更新 `CurrentRecords`/`Projections`/`CurrentCandidates` 三个指针）。
- `internal/themico/governance/governance_test.go:68` `TestPublishCommitsRecordProjectionAndCandidateBindingAtomically`。
- `internal/themico/store/store_test.go:884` `TestCommitPublishesProjectionBoundToRecordRevision`。
- `manual-replay.md` 场景 1：`publish` 后单次 generation（3→4）内 `candidate inspect` 立即显示 `status=published` 且 `published_record_id` 精确指向新记录。

**判定**：满足，有 fresh evidence。

### 11. 初始化、generation chain、不可变写入、中断和并发 conflict 均有自动证据

- 初始化：`internal/themico/store/store_test.go:43` `TestInitMakesGenerationZeroVisibleAndOpenPreservesIdentity`。
- generation chain：`store_test.go:1093` `TestOpenAndCurrentRejectInvalidGenerationChain`。
- 不可变写入：`store_test.go:987` `TestCommitRefusesImmutableOverwriteWithoutChangingBytes`。
- 中断：`store_test.go:955` `TestCommitPreRenameFaultLeavesPriorCurrentAndOrphanPayload`；`internal/themico/integration/interruption_test.go:54` `TestPublishInterruptedDuringPayloadWriteLeavesOrphanInvisible`、`:111` `TestPublishInterruptedBeforeRenameLeavesCurrentStateUnchanged`。
- 并发 conflict：`store_test.go:1008` `TestConcurrentCommitHasOneWinnerAndOneConflict`；`internal/themico/integration/lifecycle_test.go:480` `TestConcurrentPublishLetsExactlyOneWinWithoutOverwriting`；`manual-replay.md` 场景 7（两个真实并发 OS 进程）。

**判定**：满足，有 fresh evidence。

### 12. query 默认只返回 current active L1，并支持本范围定义的确定性过滤和稳定排序

- `internal/themico/query/query_test.go:24` `TestSearchReturnsOnlyCurrentActiveL1InStableOrder`。
- `internal/themico/query/query_test.go:50` `TestSearchAppliesDeterministicFilters`（tags/triggers/types 子用例）。
- `manual-replay.md` 场景 1/2/3/7/8：`query` 输出的 `candidates` 数组只含 L1 字段（不含 `l2`/`l3`），`types`/`zones` 过滤按预期收窄。

**判定**：满足，有 fresh evidence。

### 13. exact-ID inspect 能返回 L1/L2/L3，并实施实际 byte budget；预算不足不截断完整 item

- `internal/themico/query/query_test.go:127` `TestInspectReturnsRequestedDepth`。
- `internal/themico/query/query_test.go:157` `TestInspectRejectsInvalidDepthAndEnforcesExactBudget`。
- `manual-replay.md` 场景 9：真实边界（1057 字节精确成功、1056 字节 `budget_exceeded` 且 `items` 为空数组，未被截断到 1056 字节）。

**判定**：满足，有 fresh evidence。

### 14. 每次读取校验 record、projection、content、digest 和 manifest pointer binding，篡改时失败关闭

- `internal/themico/query/query_test.go:213` `TestReadsFailClosedWhenBindingsAreTampered`。
- `manual-replay.md` 场景 8：真实篡改 `content.md`/`l1.json`/`l2.json` 三类文件，`inspect`/`query` 均整请求 `validation_failed`，还原字节后立即恢复正常。

**判定**：满足，有 fresh evidence。

### 15. `views.json` 保持 canonical 空对象，未被声明为聚合索引或 query authority

- `internal/themico/store/store.go:167`（`Init` 写入 `views := json.RawMessage(`{}`)`）。
- `internal/themico/governance/publish.go:171`（`Views: views`，`publish` 从不改写 views，透传 `CurrentState` 读到的原始字节）。
- `internal/themico/store/store_test.go:1303` `TestStoreReadAndAllocationExtensionsReuseConfiguredAuthority`（第 1319-1332 行直接断言 `string(views) != "{}"` 会失败，即断言 genesis views 恒为 `{}` 且返回值不可被调用方篡改）。
- `internal/themico/query` 包全文未出现任何读取 `views.json` 参与过滤/排序的逻辑——`query`/`inspect` 完全基于 `manifest.CurrentRecords`/`Projections`，与 `views.json` 无关，符合"不是 query authority"的声明。

**判定**：满足，有 fresh evidence。

### 16. 核心 CLI command surface 可构建、可运行，stdout 只有一个严格 result envelope

- `go build ./...`（本文档第 1.1 节，成功）。
- `internal/themico/cli/cli_test.go:93` `TestRunEmitsExactlyOneEnvelopePerInvocation`、`:133` `TestHelpOutputIsByteIdenticalAcrossRuns`。
- `manual-replay.md` 全部场景：每次调用 stdout 均为单行 JSON envelope（`assertSingleJSONLine` 同款约束在 replay 里逐次人工确认）。

**判定**：满足，有 fresh evidence。

### 17. 单一公共 `themico` Skill 只加载一个 operation reference 和 registry 选择的一个 factory；references 位于 `.themico/core/`，发现入口位于 `.claude/skills/themico/SKILL.md`

- `internal/themico/integration/skill_contract_test.go:22` `TestSkillTreeMatchesFirstUsableDeliveryContract`（Skill 目录只含 `SKILL.md`；`operations`/`common`/三个 `types/*` 目录的文件清单与首个交付契约逐一比对；只有 `SKILL.md` 携带 YAML frontmatter；`supersede`/`deprecate`/`archive`/`rebuild`/`verify-projection`/`create-derived-candidate` 六个延期 operation reference 均确认不存在）。
- `internal/themico/integration/skill_contract_test.go:60` `TestFactoryL3ReferencesMatchRegistryHeadings`（三个 factory 的 `l3.md` 与 `model.Factories()` 声明的固定章节逐一核对）。

**判定**：满足，有 fresh evidence。

### 18. `init` 建立 `core/` 与 `workspace/` 分离，store payload 全部落在 `workspace/` 内，`core/` 不被 generation commit 写入；控制面与工作区可按任意顺序安装

- `internal/themico/store/store_test.go:82` `TestInitSeparatesControlPlaneFromGovernedWorkspace`、`:139` `TestInitInstallsWorkspaceBesideAnExistingControlPlane`、`:167` `TestFailedInitLeavesAnExistingControlPlaneUntouched`。
- `internal/themico/integration/lifecycle_test.go:568` `TestInitLayoutAndControlPlane`（预置 `core/` 内容 → `init` → 断言 `core/` 字节不变、`workspace/` 七个子目录齐全 → 一次 `candidate create` 提交 → 断言 `core/` 下没有出现任何新文件 → 重复 `init` 断言 `precondition_failed`）。

**判定**：满足，有 fresh evidence。

### 19. 自动测试、人工 replay、`go test ./... -count=1`、`go vet ./...`、`go build ./...` 和 `git diff --check` 均有 fresh 结果；无法证明的项目显式标记 GAP 或 unavailable

- 本文档第 1 节：四个命令的 fresh 输出、exit code、测试/skip 数量均已记录；7 个 SKIP 逐一标记为 unavailable（原因、错误信息见上）。
- `manual-replay.md`：九个场景 + 三段补充复现材料，全部为本任务真实执行产生。
- 本文档下方"已知缺陷披露"章节记录了两个不属于 unavailable/SKIP，但属于**已确认功能性缺陷**的问题（见第 3 节），如实披露而非掩盖。

**判定**：满足，有 fresh evidence；已知缺陷已披露而非隐藏。

### 20. 产品说明只陈述实际可用能力，并明确本文件第 6 节能力尚未交付

- `README.md` 新增的"Themico"章节（本任务改动）逐一列出可用的 11 条命令，并显式列出 `first-usable-delivery.md` 第 6 节全部延期能力（供 grep 交叉核对：`supersede`、`deprecate`、`archive`、`history query`、跨类型派生与 `create-derived-candidate`、`relation traversal`、多跳查询、跨 Zone 查询扩展、`cycle analysis`、`Agent relevance ranking`、`enriched semantic explanation`、聚合 view、`rebuild`、增量 view 维护、cache、并行 query、`URL source`、`MCP adapter`、`Claude API` 或内置模型、`Embedding`、向量数据库、`SQLite`、`Web UI`、`Themis lifecycle` 正式接线、`token budget`）。
- 同一章节如实披露本报告确认的四个已知缺陷（见下，其中两个为终审后定向再评审新增）。

**判定**：满足。

### 21. 没有新增 Python、产品 YAML、功能版本、版本目录或计划外外部集成

- 本任务提交范围审查（步骤 5，见本文档第 4 节）：只新增/修改 `README.md`、`docs/plan/themico-core/implementation-evidence.md`、`docs/plan/themico-core/manual-replay.md` 三个 Markdown 文件，未新增任何 `.py`、产品 YAML、版本目录或第三方依赖。
- `go.mod` 未被本任务改动，`go 1.26`、无新增 module 依赖。

**判定**：满足。

---

**21 条中的 GAP 数量：0。** 全部 21 条均找到唯一的 fresh 一手证据；其中条目 7 的自动化测试覆盖存在缺口，已用本任务新增的真实 CLI replay（`manual-replay.md` 补充复现材料 C）弥补并如实说明，不作为 GAP 处理，因为最终确实存在可复现、可核对的 fresh evidence。

---

## 3. 已知缺陷披露（README 与本文档必须如实包含，不得省略或美化）

### 缺陷 1：`l1.json` 与 `l2.json` 是同一份完整 `model.Projection` 的字节副本

- **现象**：每次 `publish` 写入的 `projections/<record_id>/<revision>/l1.json` 与 `l2.json` 字节完全相同（`manual-replay.md` 场景 1 已用 `diff`/`sha256sum` 实测确认）。
- **根因**：`internal/themico/store/generation.go` 的 `validateProjectionReference`（约第 351-400 行）对两个文件都解码为完整 `model.Projection` 并各自校验 `record.L1` 与 `record.L2`，这是任务 4（store 层）遗留的既有约束；`internal/themico/governance/prepare.go`（约第 119-129 行）与 `internal/themico/governance/publish.go`（约第 82-89、113-118 行）的代码注释已记录该约束及升级需求。
- **影响边界**：`internal/themico/query/query.go` 的 API 层发现/升级边界仍然成立——`query` 命令只返回 L1 字段。但"L1、L2 是两个独立存储单元"这一物理层保证不成立，属已知缺陷，待后续独立计划修复。

### 缺陷 2：`canonical.Encode` 的 1 MiB 硬上限与 `query`/`inspect` 的 16 MiB `content_budget_bytes` 冲突

- **现象**：一个通过了 `content_budget_bytes` 预算门禁、语义上完全成功的多记录结果集，在 CLI 把整个 `Result`/`InspectResult` 编码为 envelope 时可能因超过 1 MiB 被兜底为 `internal_error`（`manual-replay.md` 补充复现材料 B 已用真实两条约 594 KB 的记录复现：单条 `succeeded`，合计约 1.19 MB 时整请求 `internal_error`，消息 `"machine JSON exceeds 1048576 bytes"`）。
- **根因**：`internal/themico/canonical/canonical.go` 第 16、35-37 行硬编码 `maxMachineJSONBytes = 1 << 20`；`internal/themico/query` 自身的预算核算（`inspect.go` 第 118-140 行）只按 `content_budget_bytes`（最高 16 MiB）逐项累加校验，与 CLI 层 `internal/themico/cli/commands.go` 的 `canonicalOutput`/`traceEnvelope`（第 409-415、505-529 行）对整个输出对象的 1 MiB 硬上限互不知晓。
- **影响边界**：**README 必须说明 CLI 实际可返回的结果上限受 1 MiB envelope 编码限制约束，不得把 16 MiB 预算宣传为完全可用的读取能力上限。**

以上两条缺陷均已在本任务新增的 README Themico 章节中如实披露。

### 缺陷 3（终审后定向再评审新增）：128 KiB content 上限只堵住了 L3 自身导致的读不回，L1/L2/Scope 仍无独立字节上限

- **背景**：终审修复波把 `internal/themico/candidate/service.go` 的 `maxContent` 从 4 MiB 收紧到 128 KiB，目的是让"能发布的记录都能被 `inspect --depth 3` 读回"。这个修复本身是正确的最小修复，但它只约束了 `content.md`（L3）一个字段。
- **现象**：`L1`、`L2`、`Scope` 都没有独立的字节上限；`candidate.Service` 唯一的组合约束是整份 `candidate.json`（不含走 `json:"-"` 的 `content.md`）在 canonical 编码后不超过 1 MiB（`maxMachineJSON = 1 << 20`）。因此可以构造一个 `L1.Tags`/`Summary` 或 `L2.Payload` 逼近 900 KB 的候选，配合任意合法的 128 KiB content——它能通过 create/revise/confirm-type/validate/prepare/publish 全链路成功发布，此后该记录的 `inspect --depth 3` 会因为整个 `query.Item`（`l1`+`l2`+`l3` 一起编码）超过 1 MiB canonical 硬上限，永久返回 `validation_failed`。
- **根因**：与缺陷 2 同源——`internal/themico/canonical/canonical.go` 的 `Encode` 对任意一次 machine JSON 编码都有硬编码的 1 MiB 上限，而 `maxContent` 的推导（见 `service.go` 常量块注释）明确承认"这不保证一个单独逼近 1 MiB 的病态 L1/L2"，把这一收窄留给了后续设计。
- **影响边界**：README 已把这一处措辞收窄为"128 KiB 上限只堵住 L3 自身导致的读不回，不构成整体保证"，不再声称"确保发布的内容一定能被 depth-3 读回"。彻底解决需要给 L1/L2/Scope 各自加上独立字节上限，属后续独立计划，与缺陷 2 的 envelope 预算模型重新设计一并处理。

### 缺陷 4（终审后定向再评审新增）：semantic assessment 独立性检查只在部分操作顺序下真正独立

- **现象**：`internal/themico/governance/assessment.go` 的 `checkAssessment` 要求 checker identity 不同于 proposer，也不同于当前 revision 的 reviser（读取 `candidate.RevisedBy`，这是终审修复波"Important 2"新增的检查）。但 `internal/themico/candidate/service.go` 的 `ConfirmType` 会用 `ConfirmedBy` 覆写 `RevisedBy`。在 `create → revise → confirm-type → assess` 这一合法顺序下（`confirm-type` 发生在 `revise` 之后，中间不再 `revise`），原 reviser 的身份已被 `ConfirmedBy` 从 `RevisedBy` 字段抹除，`checkAssessment` 只能看到覆写后的值，该 reviser 因而仍可为自己撰写的当前内容出具通过的 semantic assessment 而不被拦截。
- **验收范围**：第 2 节条目 7 的字面文本（"checker identity 字段与 proposer 不同"）持续成立，不构成该条目的 GAP。被削弱的是顶层设计核心不变量 4（`docs/superpowers/specs/2026-07-29-themico-design.md` 第 3.4 节）期望的独立语义评估。
- **影响边界**：**publication 仍需要一份精确绑定 prepare 的独立 Human Approval，这道 gate 没有被削弱**，因此这不构成"无人审查即可发布"。彻底修复需要引入一个能跨 `ConfirmType` 存续的"当前内容真实撰写者"身份，涉及 model 与生命周期变更，属后续独立计划。

以上四条缺陷均已在 README「已知缺陷」章节如实披露；缺陷 3、4 是终审修复波提交（`c558594`）后定向再评审确认的残留缺陷，已裁定延期到后续独立计划，不阻塞本分支合并。

---

## 4. 提交范围审查（步骤 5）

```
$ git status --short
```

（本任务提交前，工作树对已跟踪文件无改动；本任务只新增以下三个文件并修改 README.md。）

```
$ git diff --stat
```

（本任务提交后的 diff 范围：`README.md` 增量修改 + `docs/plan/themico-core/implementation-evidence.md`、`docs/plan/themico-core/manual-replay.md` 两个新文件。未包含任何 `.themico` 测试数据、编译产物、`.py` 文件、产品 YAML、MCP adapter 代码或 Themis lifecycle 改动。人工 replay 使用的临时仓库位于系统临时目录，不属于本仓库、不进入本次提交。）

---

## 5. 汇总结论

- Fresh verification：`go build`/`go vet`/`go test -count=1`/`git diff --check` 全部执行且全部通过；292 个测试节点中 285 PASS、0 FAIL、7 SKIP（均为 Windows 平台权限限制，如实标记 unavailable，不计入通过）。
- 21 条独立验收集合：21 条全部有唯一 fresh 一手证据，GAP 数量为 0。
- 四个已知缺陷（L1/L2 投影字节重复、1 MiB envelope 硬上限与 16 MiB 预算冲突、L1/L2/Scope 缺少独立字节上限、semantic assessment 独立性检查的顺序依赖）已如实披露在 README 与本文档，未被掩盖或美化；后两条是终审修复波提交（`c558594`）后定向再评审确认的残留缺陷，已裁定延期到后续独立计划，不阻塞本分支合并。
- 本证据只覆盖首个可用交付这一实施切片，不构成 `acceptance.md` 完整 38 条目标的完成判定，也不表示生命周期、关系遍历、聚合 view、外部集成等延期能力已经交付。
