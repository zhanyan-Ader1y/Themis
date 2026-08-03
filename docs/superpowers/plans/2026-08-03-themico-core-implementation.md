# Themico 核心实现计划

> **供 Agent 执行时使用：** 必须使用 `superpowers:subagent-driven-development`（推荐）或 `superpowers:executing-plans`，按任务逐项实施本计划。所有步骤使用复选框（`- [ ]`）跟踪。

**目标：** 实现一个独立、本地优先、无内置模型的 Themico 核心：通过单一公共 Skill 和按需 references 完成语义提案，通过 `themico` Go CLI 确定性执行原子 Knowledge Record 的校验、身份、修订、来源绑定、治理发布、渐进查询、失效和可重建投影。

**架构：** L1、L2、L3 是同一原子 Knowledge Record 的读取深度；正式语义由类型化 L3 和治理记录共同承载，L1/L2、索引与项目/领域/架构/feature 聚合视图均为可重建投影。Agent 负责理解、分类、摘要、相关性和忠实度分析，Human 负责类型确认与高影响授权，Go CLI 负责所有闭合集合、稳定身份、revision、digest、source binding、currentness、预算、引用完整性、可见提交、状态变化和 query trace。

**技术栈：** Go 1.26 标准库、JSON 机器合同、Markdown L3 与 Skill references、本地文件系统、Go 单元/集成/故障注入测试。首个计划不实现 Claude API、MCP adapter、Embedding、向量数据库、SQLite、Web UI、自动知识摄取或 Themis lifecycle 集成。

## 全局约束

- 当前顶层权威入口是 `docs/superpowers/specs/2026-07-29-themico-design.md`；本计划第一个任务必须把本轮已确认的设计增量写入该 authority，再开始代码实现。
- L1/L2/L3 只表示读取深度，不表示项目、领域、架构、组件或 feature 层级。
- Knowledge Record 是独立治理、修订、引用、失效和替代的最小原子单位；聚合内容不能成为第二份语义权威。
- 首批知识类型闭集固定为 `design_decision`、`development_standard`、`development_experience`。
- Zone 闭集固定为 `project_knowledge`、`project_experience`；前两种知识类型只能进入 `project_knowledge`，`development_experience` 只能进入 `project_experience`。
- 三种类型共享治理外壳和 L1；L2 共享公共头部并使用类型化 payload；L3 使用各类型固定 Markdown 章节。
- 已有正式记录必须根据已固化 `knowledge_type` 查询 registry 并选择唯一 factory；Agent 不得根据标题、摘要或正文重新解释类型。
- 新候选由 Agent 提出类型和分类依据，经 Human 明确确认后由 CLI 固化；类型固化后不得原地改型。
- 跨类型提炼必须创建新 candidate/record，并通过 `derived_from` 关系连接原记录。
- Agent 只能产生 proposal、candidate content、semantic assessment、explanation 和 relevance decision，不能产生 published/current/valid authority。
- Human 负责类型确认、publication、supersede、deprecate 和 archive 的授权；CLI 只校验授权工件的结构和绑定，不声称验证人的真实身份。
- CLI 是唯一 machine authority：负责结构、枚举、ID、revision、canonical digest、本地 source binding、registry、Catalog、currentness、确定性过滤、byte budget、关系完整性、可见提交、失效和重建。
- 正式 source 首批只支持 repository/root-relative 本地文件；CLI 必须直接读取 bytes 并计算 `sha256`。URL 抓取和未物化外部来源留给后续计划。
- 所有 machine JSON 使用 UTF-8、拒绝未知字段、拒绝重复键、拒绝浮点数，digest 使用项目定义的 canonical JSON 加 `sha256:` 前缀。
- 单个 machine JSON 输入上限为 1 MiB，单个 L3 Markdown 上限为 4 MiB，单个 source file 上限为 16 MiB；超过上限返回 `validation_failed`，不能截断。
- 查询只实现 byte budget，不实现 token budget；`content_budget_bytes` 必填，范围为 1 到 16 MiB。没有真实 tokenizer 时不得用估算值声称 token enforcement。
- 所有 CLI 生成时间使用 UTC `RFC3339Nano`；ID 由 `crypto/rand` 生成 16 bytes 并使用固定前缀加 32 位小写十六进制编码。
- L3 和所有产品/Skill 合同使用中文 Markdown；JSON 只用于实际由 Go CLI 读取或写出的 machine data。
- `SKILL.md` 只保留 Claude Code 宿主发现所需的最小 frontmatter；其余流程与合同写在 Markdown 正文和 references 中。
- Go module path 固定为 `github.com/zhanyan-Ader1y/Themis`，`go.mod` 使用 `go 1.26`，首个实现不得增加第三方 Go dependency。
- CLI 二进制名固定为 `themico`，避免与后续 Themis lifecycle runtime 的 `themis` CLI 混淆。
- CLI stdout 只输出一个 JSON result envelope；诊断不得以自由文本改变 status，stderr 仅用于不可编码的进程级故障。
- 查询轨迹中的 Agent 语义说明不是 CLI machine authority；首个 CLI trace 只保存可重放的过滤、选择、读取、关系扩展和预算事实，Skill 将 Agent explanation 作为独立非权威输出返回。
- 首个存储实现使用 `.themico/`、不可变 payload 和 generation-directory commit；不实现通用数据库、通用 transaction framework、rollback、自动修复、upgrade 或 migration。
- `.themico` 已存在时 `themico init` 必须在任何写入前失败；首个实现不接管或转换未知现有目录。
- 可见提交只能通过把完整 staging generation rename 到新的、不存在的 `generations/gen-%020d` 完成；查询只读取最高的完整合法 generation。
- 并发 writer 基于相同 generation 时只能有一个成功提交；失败方返回 `conflict`，不能覆盖获胜 generation。
- 当前计划只实现独立 Themico 核心 CLI 与单一 Skill/references；MCP adapter 和 Themis Global Rule/Capability/Workspace 的正式接线必须另立计划。
- 当前 Plan 35 Context 窄边界保持不变；不得把 Themico 的项目架构、正式设计或开发规范直接写入 `workspace/context/` 并声称 Context authority。
- 项目不使用 Python；不得新增 Python 源码、脚本、测试或一次性验证器。
- 不使用 Shell、PowerShell、`jq`、`yq` 或临时脚本代替 Go CLI 的产品能力；实现期只允许直接运行 Go 工具、Git 只读/提交命令和专用文件工具。
- 不增加功能版本、版本目录、compatibility、upgrade 或 migration。
- 执行前保存 `git status --short`；不得 reset、restore、clean、stash 或覆盖用户既有修改。

---

## 目标文件结构

```text
go.mod
cmd/themico/
└── main.go
internal/themico/
├── result/
│   ├── result.go
│   └── result_test.go
├── model/
│   ├── model.go
│   ├── registry.go
│   └── registry_test.go
├── canonical/
│   ├── canonical.go
│   └── canonical_test.go
├── store/
│   ├── store.go
│   ├── generation.go
│   ├── path.go
│   └── store_test.go
├── candidate/
│   ├── service.go
│   └── service_test.go
├── validate/
│   ├── candidate.go
│   ├── markdown.go
│   ├── relation.go
│   └── validate_test.go
├── governance/
│   ├── prepare.go
│   ├── approval.go
│   ├── publish.go
│   ├── lifecycle.go
│   └── governance_test.go
├── query/
│   ├── query.go
│   ├── inspect.go
│   └── query_test.go
├── projection/
│   ├── projection.go
│   ├── views.go
│   └── projection_test.go
├── cli/
│   ├── cli.go
│   ├── commands.go
│   └── cli_test.go
└── integration/
    ├── lifecycle_test.go
    ├── query_test.go
    ├── interruption_test.go
    ├── security_test.go
    └── skill_contract_test.go

templates/.claude/skills/themico/
├── SKILL.md
└── references/
    ├── common/
    │   ├── operation-contract.md
    │   ├── result-contract.md
    │   ├── governance.md
    │   ├── knowledge-record.md
    │   ├── l1-discovery.md
    │   └── type-registry.md
    ├── operations/
    │   ├── query.md
    │   ├── inspect.md
    │   ├── create-candidate.md
    │   ├── revise-candidate.md
    │   ├── confirm-type.md
    │   ├── validate.md
    │   ├── prepare.md
    │   ├── publish.md
    │   ├── supersede.md
    │   ├── deprecate.md
    │   ├── archive.md
    │   ├── verify-projection.md
    │   └── rebuild.md
    └── types/
        ├── design-decision/
        │   ├── factory.md
        │   ├── l2.md
        │   ├── l3.md
        │   └── semantic-check.md
        ├── development-standard/
        │   ├── factory.md
        │   ├── l2.md
        │   ├── l3.md
        │   └── semantic-check.md
        └── development-experience/
            ├── factory.md
            ├── l2.md
            ├── l3.md
            └── semantic-check.md

docs/superpowers/specs/2026-07-29-themico-design/
├── knowledge-model.md
├── types-and-layers.md
├── agent-cli-authority.md
├── storage-and-lifecycle.md
├── query-and-projection.md
├── skill-and-references.md
└── acceptance.md

docs/plan/themico-core/
├── implementation-evidence.md
└── manual-replay.md
```

运行时数据布局固定为：

```text
<root>/.themico/
├── store.json
├── candidates/<candidate-id>/revisions/<candidate-revision>/
│   ├── candidate.json
│   └── content.md
├── records/<record-id>/revisions/<record-revision>/
│   ├── record.json
│   └── content.md
├── projections/<record-id>/<record-revision>/
│   ├── l1.json
│   └── l2.json
├── preparations/<prepare-id>/prepare.json
├── assessments/<assessment-digest>.json
├── approvals/<approval-digest>.json
└── generations/
    ├── gen-00000000000000000000/
    │   ├── manifest.json
    │   └── views.json
    └── gen-00000000000000000001/
        ├── manifest.json
        └── views.json
```

`records`、`candidates`、`projections`、`preparations`、`assessments` 和 `approvals` 中的对象均不可变。只有一个完整 generation directory 的出现才能改变可见 current state；未被任何合法 generation 引用的中断残留不构成 current authority。

---

### 任务 1：把已确认的 Themico 设计增量固化为 current Spec

**文件：**
- 修改：`docs/superpowers/specs/2026-07-29-themico-design.md`
- 新建：`docs/superpowers/specs/2026-07-29-themico-design/knowledge-model.md`
- 新建：`docs/superpowers/specs/2026-07-29-themico-design/types-and-layers.md`
- 新建：`docs/superpowers/specs/2026-07-29-themico-design/agent-cli-authority.md`
- 新建：`docs/superpowers/specs/2026-07-29-themico-design/storage-and-lifecycle.md`
- 新建：`docs/superpowers/specs/2026-07-29-themico-design/query-and-projection.md`
- 新建：`docs/superpowers/specs/2026-07-29-themico-design/skill-and-references.md`
- 新建：`docs/superpowers/specs/2026-07-29-themico-design/acceptance.md`

**接口：**
- 输入：现有 Themico 顶层设计和本计划“全局约束”中的已确认设计决定。
- 产出：一个短顶层入口和七个主题 reference；入口继续是唯一跨模块 authority，references 不成为第二份 Spec。

- [ ] **步骤 1：记录实施前工作树和 authority 基线**

运行：

```bash
git status --short
```

使用文件读取工具确认顶层 Spec 当前仍包含 Zone、L1/L2/L3、写入治理、MCP 边界和 15 条验收条件。将观察写入本任务实施报告，不在 Spec 中写任务状态。

- [ ] **步骤 2：先写 knowledge model 和 type/layer references**

`knowledge-model.md` 必须明确：

```text
原子 Knowledge Record = 稳定身份 + lifecycle + sources/authorization + typed relations + L1 + L2 + L3
聚合 view = 从 current record revisions 重建的 record-ID/L1 索引，不拥有独立语义
scope = project + domains + architecture_units + features
```

`types-and-layers.md` 必须写出三个封闭类型、Zone compatibility、通用 L1 字段、L2 公共头部和三种类型 payload、三种 L3 固定章节，以及“类型固化后不能原地改型”。

- [ ] **步骤 3：写 Agent/CLI/Human 分权 reference**

`agent-cli-authority.md` 使用下列不可绕过模型：

```text
Agent: proposal / candidate content / relevance / semantic assessment / explanation
Human: type confirmation / publication and lifecycle authorization
CLI: validate / bind / identify / revise / digest / query / commit / invalidate / rebuild / trace
```

明确 CLI 不判断自然语言内容是否正确，Agent 不写 current authority，Human authorization 必须绑定确切 prepare identity 和 digest。

- [ ] **步骤 4：写 storage、query、Skill references**

`storage-and-lifecycle.md` 固定 `.themico` 布局、不可变 payload、generation-directory commit、current/history、source binding 和 publish/supersede/deprecate/archive 语义。

`query-and-projection.md` 固定：

```text
CLI 确定性 L1 filter
→ Agent relevance selection
→ CLI 受预算约束读取 L2
→ Agent 决定是否升级
→ CLI 受预算约束读取 L3/有限关系
→ CLI fact trace + Agent semantic explanation
```

`skill-and-references.md` 固定一个公共 `themico` Skill、一个 operation reference、一个 registry-selected type factory，禁止 Skill/Agent 重新解释正式 type。

- [ ] **步骤 5：重写顶层 Spec 为 authority entry**

入口保留产品定位、核心不变量、非目标、Themis/MCP 延后边界和 reference 索引。把旧的“L1/L2 使用结构化格式”收紧为“由 CLI 实际消费的 JSON”；把“待审阅的顶层决策”改为已确认决定，不保留未决措辞。

- [ ] **步骤 6：扩充验收标准并做人工覆盖核对**

`acceptance.md` 至少逐项覆盖：原子记录、三个类型、Zone compatibility、L1/L2/L3、类型确认、跨类型派生、来源 digest、Human Approval、generation commit、并发 conflict、渐进查询、byte budget、关系完整性、投影失效、view rebuild、历史保留、Skill references、安全降级、无 MCP/Themis integration 越界。

使用内容搜索工具确认以下词各有唯一权威位置：

```text
atomic Knowledge Record
design_decision
development_standard
development_experience
derived_from
generation-directory
Agent proposal
Human authorization
Go CLI
```

- [ ] **步骤 7：审查文档 diff 并提交**

运行：

```bash
git diff -- docs/superpowers/specs/2026-07-29-themico-design.md docs/superpowers/specs/2026-07-29-themico-design
```

确认没有实现状态、YAML 产品合同、Claude API、MCP 实现或 Themis lifecycle 改动，然后提交：

```bash
git add docs/superpowers/specs/2026-07-29-themico-design.md docs/superpowers/specs/2026-07-29-themico-design
```

```bash
git commit -m "docs: refine Themico core authority"
```

---

### 任务 2：建立 Go module、CLI 进程合同和封闭结果状态

**文件：**
- 新建：`go.mod`
- 新建：`cmd/themico/main.go`
- 新建：`internal/themico/result/result.go`
- 新建：`internal/themico/result/result_test.go`
- 新建：`internal/themico/cli/cli.go`
- 新建：`internal/themico/cli/cli_test.go`

**接口：**
- 产出：`cli.Run(ctx, args, stdout, stderr) int`；所有后续命令使用统一 `result.Envelope`。
- 状态闭集：`succeeded | usage_error | validation_failed | not_found | precondition_failed | conflict | stale | unauthorized | approval_required | budget_exceeded | unavailable | internal_error`。

- [ ] **步骤 1：写失败的 result envelope 测试**

```go
func TestWriteProducesOneJSONEnvelope(t *testing.T) {
	var out bytes.Buffer
	envelope := result.Envelope{
		Schema:    "themico-command-result",
		Command:   "init",
		Status:    result.StatusSucceeded,
		Operation: "op_00000000000000000000000000000001",
		Output:    json.RawMessage(`{"root":"C:/repo/.themico"}`),
	}
	if err := result.Write(&out, envelope); err != nil {
		t.Fatal(err)
	}
	var decoded result.Envelope
	if err := json.Unmarshal(out.Bytes(), &decoded); err != nil {
		t.Fatal(err)
	}
	if decoded.Status != result.StatusSucceeded || bytes.Count(out.Bytes(), []byte("\n")) != 1 {
		t.Fatalf("unexpected output: %q", out.String())
	}
}
```

- [ ] **步骤 2：运行测试并观察缺失 package 失败**

运行：

```bash
go test ./internal/themico/result
```

预期：编译失败，因为 `result.Envelope` 和 `result.Write` 尚不存在。

- [ ] **步骤 3：创建 module 和 result 合同**

`go.mod` 固定为：

```go
module github.com/zhanyan-Ader1y/Themis

go 1.26
```

`result.Envelope` 使用以下字段：

```go
type Envelope struct {
	Schema      string          `json:"schema"`
	Command     string          `json:"command"`
	Status      Status          `json:"status"`
	Operation   string          `json:"operation_id"`
	Output      json.RawMessage `json:"output,omitempty"`
	Issues      []Issue         `json:"issues"`
	Trace       json.RawMessage `json:"trace,omitempty"`
}

type Issue struct {
	Code    string `json:"code"`
	Path    string `json:"path"`
	Message string `json:"message"`
}

const (
	ExitSuccess          = 0
	ExitInternal         = 1
	ExitUsage            = 2
	ExitValidation       = 3
	ExitNotFound         = 4
	ExitPrecondition     = 5
	ExitConflict         = 6
	ExitStale            = 7
	ExitUnauthorized     = 8
	ExitApprovalRequired = 9
	ExitBudgetExceeded   = 10
	ExitUnavailable      = 11
)
```

`Write` 必须拒绝未知 status、始终输出一个 JSON object 和一个结尾换行。固定 status 到 exit code 映射为：`succeeded=ExitSuccess`、`internal_error=ExitInternal`、`usage_error=ExitUsage`、`validation_failed=ExitValidation`、`not_found=ExitNotFound`、`precondition_failed=ExitPrecondition`、`conflict=ExitConflict`、`stale=ExitStale`、`unauthorized=ExitUnauthorized`、`approval_required=ExitApprovalRequired`、`budget_exceeded=ExitBudgetExceeded`、`unavailable=ExitUnavailable`。

- [ ] **步骤 4：写 CLI 空参数和未知命令测试**

```go
func TestRunRejectsUnknownCommand(t *testing.T) {
	var out, errOut bytes.Buffer
	exit := cli.Run(context.Background(), []string{"unknown"}, &out, &errOut)
	if exit != result.ExitUsage {
		t.Fatalf("exit=%d output=%s", exit, out.String())
	}
	var envelope result.Envelope
	if err := json.Unmarshal(out.Bytes(), &envelope); err != nil {
		t.Fatal(err)
	}
	if envelope.Status != result.StatusUsageError || errOut.Len() != 0 {
		t.Fatalf("status=%s stderr=%q", envelope.Status, errOut.String())
	}
}
```

- [ ] **步骤 5：实现最小 dispatcher 和 main**

`cmd/themico/main.go` 只调用：

```go
os.Exit(cli.Run(context.Background(), os.Args[1:], os.Stdout, os.Stderr))
```

`cli.Run` 此时只识别 `help`；其他命令返回 `usage_error`。后续任务逐步注册真实 handler，不使用第三方 CLI framework。

- [ ] **步骤 6：验证、格式化并提交**

运行：

```bash
gofmt -w cmd/themico internal/themico/result internal/themico/cli
```

```bash
go test ./internal/themico/result ./internal/themico/cli
```

```bash
go build ./...
```

提交：

```bash
git add go.mod cmd/themico internal/themico/result internal/themico/cli
```

```bash
git commit -m "feat: establish Themico CLI contract"
```

---

### 任务 3：实现统一 Record model 和显式 type registry/factory

**文件：**
- 新建：`internal/themico/model/model.go`
- 新建：`internal/themico/model/registry.go`
- 新建：`internal/themico/model/registry_test.go`

**接口：**
- 产出：`model.LookupFactory(KnowledgeType) (Factory, bool)` 和强类型 Record/Candidate/Projection 结构。
- Factory 闭集：三个 type，每个 type 唯一 Zone、L2 decoder 和 L3 headings。

- [ ] **步骤 1：写 registry 闭集和 Zone compatibility 失败测试**

```go
func TestRegistryHasExactlyThreeFactories(t *testing.T) {
	factories := model.Factories()
	if len(factories) != 3 {
		t.Fatalf("got %d factories", len(factories))
	}
	cases := map[model.KnowledgeType]model.Zone{
		model.TypeDesignDecision:       model.ZoneProjectKnowledge,
		model.TypeDevelopmentStandard:  model.ZoneProjectKnowledge,
		model.TypeDevelopmentExperience: model.ZoneProjectExperience,
	}
	for typ, wantZone := range cases {
		factory, ok := model.LookupFactory(typ)
		if !ok || factory.Zone != wantZone {
			t.Fatalf("type=%s factory=%+v", typ, factory)
		}
	}
	if _, ok := model.LookupFactory("architecture"); ok {
		t.Fatal("unregistered type accepted")
	}
}
```

- [ ] **步骤 2：定义治理和分层结构**

`model.go` 必须定义：

```go
type Scope struct {
	Project           string   `json:"project"`
	Domains           []string `json:"domains"`
	ArchitectureUnits []string `json:"architecture_units"`
	Features          []string `json:"features"`
}

type L1 struct {
	Title    string   `json:"title"`
	Summary  string   `json:"summary"`
	Triggers []string `json:"triggers"`
	Tags     []string `json:"tags"`
}

type L2 struct {
	CoreConclusion  string          `json:"core_conclusion"`
	ApplicableWhen  []string        `json:"applicable_when"`
	NotApplicableWhen []string      `json:"not_applicable_when"`
	Impact          []string        `json:"impact"`
	EvidenceSummary []string        `json:"evidence_summary"`
	UpgradeWhen     []string        `json:"upgrade_when"`
	Payload         json.RawMessage `json:"payload"`
}
```

定义 `SourceRef`、`Relation`、`CandidateRevision`、`RecordRevision`、`CandidatePointer`、`RecordPointer` 和 `Manifest`。所有 sequence 在写入前排序并去重；unknown JSON fields 由 strict decoder 拒绝。

- [ ] **步骤 3：定义三个 L2 payload 和 L3 headings**

```go
type DesignDecisionL2 struct {
	AffectedUnits  []string `json:"affected_units"`
	Constraints    []string `json:"constraints"`
	Alternatives   []string `json:"alternatives"`
	Consequences   []string `json:"consequences"`
	ReevaluateWhen []string `json:"reevaluate_when"`
}

type DevelopmentStandardL2 struct {
	LifecycleStages  []string `json:"lifecycle_stages"`
	Trigger          []string `json:"trigger"`
	RequiredActions  []string `json:"required_actions"`
	ProhibitedActions []string `json:"prohibited_actions"`
	Verification     []string `json:"verification"`
	ExceptionPolicy  []string `json:"exception_policy"`
}

type DevelopmentExperienceL2 struct {
	Symptoms          []string `json:"symptoms"`
	Preconditions     []string `json:"preconditions"`
	ObservedFacts     []string `json:"observed_facts"`
	RecommendedAction []string `json:"recommended_action"`
	EvidenceStrength  string   `json:"evidence_strength"`
	Risks             []string `json:"risks"`
	StopConditions    []string `json:"stop_conditions"`
}
```

Factory 的 L3 headings 必须与 current Spec 完全一致；不得把 type 名称当作可扩展插件目录自动发现。

- [ ] **步骤 4：写 strict payload 和类型不可重解释测试**

测试 `design_decision` payload 出现 `symptoms` 时失败；测试从 persisted `knowledge_type` lookup factory，而不是从 title `"一次失败经验"` 猜测类型。

- [ ] **步骤 5：运行测试并提交**

```bash
gofmt -w internal/themico/model
```

```bash
go test ./internal/themico/model
```

```bash
git add internal/themico/model
```

```bash
git commit -m "feat: define Themico knowledge model"
```

---

### 任务 4：实现 canonical JSON、稳定 identity 和 generation store

**文件：**
- 新建：`internal/themico/canonical/canonical.go`
- 新建：`internal/themico/canonical/canonical_test.go`
- 新建：`internal/themico/store/path.go`
- 新建：`internal/themico/store/store.go`
- 新建：`internal/themico/store/generation.go`
- 新建：`internal/themico/store/store_test.go`

**接口：**
- 产出：`canonical.Encode`、`canonical.Digest`、`store.Init`、`store.Open`、`Store.Current`、`Store.Commit`。
- ID 前缀：`op_`、`cand_`、`crev_`、`kr_`、`rev_`、`prep_`、`assess_`；后接 32 个小写十六进制字符。

- [ ] **步骤 1：写 canonical digest 失败测试**

```go
func TestDigestIgnoresObjectKeyOrderButPreservesArrayOrder(t *testing.T) {
	a := json.RawMessage(`{"b":2,"a":1,"items":["x","y"]}`)
	b := json.RawMessage(`{"items":["x","y"],"a":1,"b":2}`)
	c := json.RawMessage(`{"items":["y","x"],"a":1,"b":2}`)
	da, _ := canonical.Digest(a)
	db, _ := canonical.Digest(b)
	dc, _ := canonical.Digest(c)
	if da != db || da == dc {
		t.Fatalf("digests: %s %s %s", da, db, dc)
	}
}
```

同时测试 duplicate key、float、trailing JSON 和 invalid UTF-8 被拒绝。

- [ ] **步骤 2：实现 canonical encoder 和 digest**

规则固定为：object key 按 Unicode code point 排序；array 保持顺序；整数使用十进制最短形式；字符串使用 Go JSON escaping；不输出空白；digest 为 `sha256:<64 lowercase hex>`。

- [ ] **步骤 3：写 init、safe path 和 generation visibility 失败测试**

测试：

```text
init on absent .themico -> generation 0 visible
init on existing .themico -> precondition_failed and bytes unchanged
../ escape -> validation_failed
staging generation not renamed -> Current still returns prior generation
rename complete generation -> Current returns new generation
```

- [ ] **步骤 4：实现 store layout**

`store.Init(root, opts)` 必须先检查 `<root>/.themico` 不存在，在同一父目录创建 `.themico.init-<operation-id>` 完整 staging store，fsync 后通过单次 rename 发布为 `.themico`；rename 前失败必须删除本次 staging，rename 冲突必须返回 `precondition_failed`，不得接管既有目录。`store.Open(root, opts)` 必须验证 `store.json` identity、generation 0 manifest digest，以及从 generation 0 到 current generation 的连续 parent chain。

Store 的构造和可测试依赖固定为：

```go
type Options struct {
	Clock                  func() time.Time
	NewID                  func(prefix string) (string, error)
	BeforeGenerationRename func() error
}

func Init(root string, opts Options) (*Store, error)
func Open(root string, opts Options) (*Store, error)
func (s *Store) Root() string
```

每个 generation manifest 必须包含 `generation`、`parent_generation`、`parent_manifest_digest` 和自身 canonical digest；`Current` 只接受从 generation 0 连续连接且目录/manifest 完整合法的最高 generation，不把编号更高但断链的目录视为 current。

`Store.Commit` 接口固定为：

```go
type CommitPlan struct {
	ExpectedGeneration uint64
	Writes             []ImmutableWrite
	Manifest           model.Manifest
	Views               json.RawMessage
}

func (s *Store) Commit(ctx context.Context, plan CommitPlan) (model.Manifest, error)
```

实现顺序：校验 expected generation；写不可变 payload；写同父目录 staging generation；fsync 文件和目录；rename 到 `gen-%020d`；若目标 generation 已存在则返回 conflict；绝不覆盖既有 payload 或 generation。

- [ ] **步骤 5：增加可注入 clock、ID source 和 pre-rename fault**

生产默认使用 `time.Now().UTC()` 和 `crypto/rand`。测试使用固定 clock/ID source。`BeforeGenerationRename func() error` 仅作为 `store.Options` 注入点；注入错误时 current generation 必须不变。

- [ ] **步骤 6：运行测试并提交**

```bash
gofmt -w internal/themico/canonical internal/themico/store
```

```bash
go test ./internal/themico/canonical ./internal/themico/store
```

```bash
git add internal/themico/canonical internal/themico/store
```

```bash
git commit -m "feat: add Themico generation store"
```

---

### 任务 5：实现 candidate create、revise、type confirmation 和 inspect

**文件：**
- 新建：`internal/themico/candidate/service.go`
- 新建：`internal/themico/candidate/service_test.go`

**接口：**
- 产出：`candidate.New(st *store.Store) *Service`、`Service.Create(ctx, req)`、`Service.Revise(ctx, req)`、`Service.ConfirmType(ctx, confirmation)`、`Service.Inspect(ctx, candidateID)`。
- Candidate status 闭集固定为 `proposed | type_confirmed | published | abandoned`；type confirmation 前只拥有 `proposed_type`，confirmation 后同时保留原提案并拥有不可变 `knowledge_type`。

- [ ] **步骤 1：写 candidate lifecycle 失败测试**

覆盖：

```go
func TestConfirmedCandidateCannotChangeType(t *testing.T) {
	ctx := context.Background()
	svc, created := createAndConfirmExperienceCandidate(t)
	current, err := svc.Inspect(ctx, created.CandidateID)
	if err != nil {
		t.Fatal(err)
	}
	request := ReviseRequest{
		CandidateID:       current.CandidateID,
		ExpectedRevision: current.Revision,
		ProposedType:      model.TypeDesignDecision,
		L1:                current.L1,
		L2:                current.L2,
		SourcePaths:       sourcePaths(current.Sources),
		Relations:         current.Relations,
		ContentMarkdown:   current.ContentMarkdown,
		RevisedBy:         "agent:revision-writer",
	}
	if _, err := svc.Revise(ctx, request); !errors.Is(err, ErrTypeImmutable) {
		t.Fatalf("err=%v", err)
	}
	after, err := svc.Inspect(ctx, created.CandidateID)
	if err != nil {
		t.Fatal(err)
	}
	if after.Revision != current.Revision || after.KnowledgeType != model.TypeDevelopmentExperience {
		t.Fatalf("candidate changed: %+v", after)
	}
}
```

再覆盖 stale expected revision、未知 type、错误 Zone、source path escape 和 missing content。

- [ ] **步骤 2：定义 create/revise 输入**

```go
type CreateRequest struct {
	Zone                    model.Zone          `json:"zone"`
	Scope                   model.Scope         `json:"scope"`
	ProposedType            model.KnowledgeType `json:"proposed_type"`
	ClassificationRationale string              `json:"classification_rationale"`
	SourcePaths             []string            `json:"source_paths"`
	Relations               []model.Relation    `json:"relations"`
	L1                      model.L1            `json:"l1"`
	L2                      model.L2            `json:"l2"`
	ProposedBy               string              `json:"proposed_by"`
	ContentMarkdown          []byte              `json:"-"`
}

type ReviseRequest struct {
	CandidateID       string
	ExpectedRevision string
	ProposedType      model.KnowledgeType
	L1                model.L1
	L2                model.L2
	SourcePaths       []string
	Relations         []model.Relation
	ContentMarkdown   []byte
	RevisedBy         string
}
```

CLI 从输入 JSON 读取结构字段，从 `--content` 读取 Markdown bytes；CLI 打开 `store.Store` 后构造 `candidate.Service`，service 不接受 root 或任意目标路径。

- [ ] **步骤 3：实现本地 source binding**

Create/Revise 直接从 store root 解析 source path，拒绝绝对路径、`..`、symlink/junction escape 和不存在文件，保存实际 bytes 的 sha256。Source bytes 后续变化不会重写旧 candidate revision，只会使其在 validate/prepare 时返回 stale。

- [ ] **步骤 4：实现 type confirmation**

Confirmation JSON 固定为：

```json
{
  "schema": "themico-type-confirmation",
  "candidate_id": "cand_00000000000000000000000000000001",
  "candidate_revision": "crev_00000000000000000000000000000001",
  "knowledge_type": "development_experience",
  "confirmed_by": "human:zhanyan",
  "confirmed_at": "2026-08-03T10:00:00Z",
  "authority_ref": "conversation:a17c3daa-c7ae-4775-9a32-30e5752f3e61"
}
```

CLI 只验证字段、binding、registry 和 Zone compatibility。确认后创建新 candidate revision；后续 Revise 只能保留已固化 type。

- [ ] **步骤 5：运行测试并提交**

```bash
gofmt -w internal/themico/candidate
```

```bash
go test ./internal/themico/candidate
```

```bash
git add internal/themico/candidate
```

```bash
git commit -m "feat: implement Themico candidates"
```

---

### 任务 6：实现结构、Markdown、source 和 typed relation 校验

**文件：**
- 新建：`internal/themico/validate/candidate.go`
- 新建：`internal/themico/validate/markdown.go`
- 新建：`internal/themico/validate/relation.go`
- 新建：`internal/themico/validate/validate_test.go`

**接口：**
- 产出：`validate.Candidate(store, candidateID, revision) Report`。
- Report 只表达机器可证明问题；内容真实性留给 semantic assessment 和 Human Review。

- [ ] **步骤 1：写三种 L3 heading 失败测试**

每种类型准备一个完整通过 fixture，再分别删除一个必填 heading，预期 issue code：

```text
markdown.missing_heading
markdown.frontmatter_forbidden
markdown.heading_order
l2.unknown_field
source.stale
relation.target_missing
relation.type_forbidden
relation.cycle
```

- [ ] **步骤 2：实现 Markdown validator**

校验第一个非空行是单一 H1；禁止文件以 `---` frontmatter 开头；每个 Factory 的 H2 必须且只出现一次，并按 Spec 顺序出现；额外 H2 返回 `markdown.unknown_heading`。H3 及更深标题允许存在。

- [ ] **步骤 3：实现 relation registry**

关系闭集固定为：

```text
depends_on
constrains
derived_from
applies_to
challenges
corrects
recovers_from
follows
related_to
supersedes
```

`supersedes` 只能由 governance operation 生成，candidate 自由输入时拒绝。`depends_on`、`derived_from`、`supersedes` 必须无环；`related_to` 允许双向，但 CLI 不自动生成反向边。

- [ ] **步骤 4：实现 source/current target 校验**

Validate 必须重新读取 source bytes 并比较 digest；target relation 默认允许引用 current 或 history record，但必须存在。跨 Zone relation 必须在 relation 中显式 `cross_zone: true`，否则返回 `relation.cross_zone_not_explicit`。

- [ ] **步骤 5：实现稳定 issue 排序**

所有 issue 按 `path`、`code`、`message` 排序；同一输入重复校验输出 byte-identical JSON。

- [ ] **步骤 6：运行测试并提交**

```bash
gofmt -w internal/themico/validate
```

```bash
go test ./internal/themico/validate
```

```bash
git add internal/themico/validate
```

```bash
git commit -m "feat: validate Themico knowledge contracts"
```

---

### 任务 7：实现 semantic assessment、prepare、Human Approval 和 publish

**文件：**
- 新建：`internal/themico/governance/prepare.go`
- 新建：`internal/themico/governance/approval.go`
- 新建：`internal/themico/governance/publish.go`
- 新建：`internal/themico/governance/governance_test.go`

**接口：**
- 产出：`PreparePublish` 和 `Publish`。
- Prepare 固化全部 expected inputs 和 writes；Publish 不重新解释 proposal，只重新检查 currentness 和 Approval binding。

- [ ] **步骤 1：写 publish gate 失败测试**

覆盖：未确认 type、机器校验失败、同一 proposer 充当 semantic checker、assessment fail、无 Approval、Approval 绑定错误、source stale、generation conflict。每个失败都必须证明 record/pointer 未变。

- [ ] **步骤 2：定义 semantic assessment**

```go
type SemanticAssessmentStatus string

const (
	SemanticAssessmentPass SemanticAssessmentStatus = "pass"
	SemanticAssessmentFail SemanticAssessmentStatus = "fail"
)

type SemanticAssessment struct {
	Schema            string                   `json:"schema"`
	CandidateID       string                   `json:"candidate_id"`
	CandidateRevision string                   `json:"candidate_revision"`
	Status            SemanticAssessmentStatus `json:"status"`
	CheckerIdentity   string                   `json:"checker_identity"`
	CheckedAt         string                   `json:"checked_at"`
	Notes             string                   `json:"notes"`
}
```

CLI 验证 assessment 与 candidate binding、`status`、timestamp 和 `checker_identity != proposed_by`，但不判断 notes 是否正确。Assessment JSON canonical digest 后保存为不可变对象。

- [ ] **步骤 3：定义 prepare artifact**

Prepare 包含：operation=`publish`、candidate ID/revision/digest、assessment digest、source bindings、expected generation、allocated record ID/revision、L1/L2/L3 digests、完整 write set、invalidation set、created_at。Prepare 保存后不可修改。

- [ ] **步骤 4：定义 Human Approval**

```go
type Approval struct {
	Schema        string `json:"schema"`
	Operation     string `json:"operation"`
	PrepareID     string `json:"prepare_id"`
	PrepareDigest string `json:"prepare_digest"`
	ApprovedBy    string `json:"approved_by"`
	ApprovedAt    string `json:"approved_at"`
	AuthorityRef  string `json:"authority_ref"`
}
```

CLI 只接受 `operation=publish` 且所有 binding 完全匹配的 Approval。空 `approved_by` 或 `authority_ref` 返回 unauthorized。

- [ ] **步骤 5：实现 publish generation commit**

Publish 写入 immutable record revision、L1、L2、assessment、approval，然后提交新 generation manifest。Record status 为 `active`；candidate pointer 变为 `published` 并记录 record ID；generation views 在任务 10 前写空合法对象。

- [ ] **步骤 6：验证中断不产生可见发布**

使用 store pre-rename fault，断言所有 orphan payload 不被 `Current`、`Query` 或 `Inspect` 返回；重新执行必须先重新 prepare，因为 expected generation/currentness 需要重新读取。

- [ ] **步骤 7：运行测试并提交**

```bash
gofmt -w internal/themico/governance
```

```bash
go test ./internal/themico/governance
```

```bash
git add internal/themico/governance
```

```bash
git commit -m "feat: govern Themico publication"
```

---

### 任务 8：实现确定性 L1 查询、渐进 inspect、预算和 query trace

**文件：**
- 新建：`internal/themico/query/query.go`
- 新建：`internal/themico/query/inspect.go`
- 新建：`internal/themico/query/query_test.go`

**接口：**
- 产出：`query.Search`、`query.Inspect`。
- CLI 只做确定性候选选择和读取；Agent 语义排序及最终解释不进入 CLI authority。

- [ ] **步骤 1：写渐进读取失败测试**

准备两个 Zone、三个 type、current/history 和跨 Zone relation fixtures，验证：

```text
默认 query 只返回 current active L1
history 必须显式 include_history=true
L2/L3 必须由 exact record IDs 请求
cross_zone=false 时不扩展跨 Zone relation
relation_depth 最大为 2
预算不足返回 budget_exceeded 且不返回截断 L3
```

- [ ] **步骤 2：定义 QueryRequest**

```go
type Request struct {
	Zones              []model.Zone          `json:"zones"`
	Types              []model.KnowledgeType `json:"types"`
	Statuses           []model.RecordStatus  `json:"statuses"`
	TagsAny            []string              `json:"tags_any"`
	Project            string                `json:"project"`
	DomainsAny         []string              `json:"domains_any"`
	ArchitectureAny    []string              `json:"architecture_units_any"`
	FeaturesAny        []string              `json:"features_any"`
	IncludeHistory     bool                  `json:"include_history"`
	CrossZone          bool                  `json:"cross_zone"`
	RelationDepth      int                   `json:"relation_depth"`
	ContentBudgetBytes int64                 `json:"content_budget_bytes"`
}
```

Zones 必填；空 type/status filter 表示全部注册 type 和默认 active。结果按 record ID、revision 排序。

- [ ] **步骤 3：实现 L1 filter 和 trace**

Trace 必须记录：observed generation、searched zones、filters、candidate IDs、selected IDs、excluded IDs/reasons、relation expansions、content bytes 和剩余预算。CLI 不写“为什么语义相关”，只写机器过滤原因。

- [ ] **步骤 4：实现 Inspect depth**

`Inspect(recordIDs, depth, budget)` 的 depth 只接受 `1|2|3`。Depth 1 返回治理摘要和 L1；depth 2 增加 L2；depth 3 增加完整 L3 Markdown。任一完整 item 超出剩余预算时整个请求返回 budget_exceeded，不静默截断。

- [ ] **步骤 5：运行测试并提交**

```bash
gofmt -w internal/themico/query
```

```bash
go test ./internal/themico/query
```

```bash
git add internal/themico/query
```

```bash
git commit -m "feat: add progressive Themico query"
```

---

### 任务 9：实现 supersede、deprecate、archive 和跨类型派生

**文件：**
- 新建：`internal/themico/governance/lifecycle.go`
- 修改：`internal/themico/governance/governance_test.go`
- 修改：`internal/themico/candidate/service.go`
- 修改：`internal/themico/candidate/service_test.go`

**接口：**
- 产出：`PrepareSupersede`、`PrepareStatusChange`、`ApplyLifecycle`、`candidate.CreateDerived`。
- 不实现物理删除。

- [ ] **步骤 1：写 supersede 原子性失败测试**

测试一个新 candidate 替代 active record：同一 generation 中新 record 变 active，旧 record 产生 status=`superseded` 的新 revision，新 record 获得 system-managed `supersedes` relation；Approval 错误时两者都不变。

- [ ] **步骤 2：实现 supersede prepare/apply**

Prepare 绑定 old current revision、新 candidate revision、assessment、source、expected generation 和完整双 record write set。只允许同一知识语义身份的 Human-reviewed replacement；CLI 只验证结构/绑定，不判断“语义身份相同”。

- [ ] **步骤 3：实现 deprecate 和 archive**

两者都创建新的 record revision，复用相同 L1/L2/L3 bytes，改变 status 并保存 reason/Approval。`archive` 不删除历史或 content；默认 query 排除 deprecated、superseded、archived。

- [ ] **步骤 4：实现跨类型派生**

`CreateDerived` 必须创建新 candidate ID，要求 `derived_from` 指向现有 record，允许提出不同 type，但仍需独立 type confirmation、semantic assessment、prepare 和 publish。测试从 `development_experience` 派生 `development_standard` 后原经验保持 active 且 type 不变。

- [ ] **步骤 5：运行测试并提交**

```bash
gofmt -w internal/themico/candidate internal/themico/governance
```

```bash
go test ./internal/themico/candidate ./internal/themico/governance
```

```bash
git add internal/themico/candidate internal/themico/governance
```

```bash
git commit -m "feat: manage Themico knowledge lifecycle"
```

---

### 任务 10：实现投影校验、失效传播和聚合 view 重建

**文件：**
- 新建：`internal/themico/projection/projection.go`
- 新建：`internal/themico/projection/views.go`
- 新建：`internal/themico/projection/projection_test.go`

**接口：**
- 产出：`projection.Verify`、`projection.BuildViews`、`projection.Rebuild`。
- Rebuild 只重建已有 L1/L2 的索引和聚合视图，不调用 Agent，不从 L3 自动生成新语义摘要。

- [ ] **步骤 1：写 projection source-binding 失败测试**

覆盖：L1 与 L2 指向不同 record revision、L3 digest 不匹配、current pointer 指向旧 projection、view 包含不存在 record、删除 current views 后 rebuild 恢复。

- [ ] **步骤 2：实现 Verify**

Verify 检查 record revision、L1、L2、L3、manifest pointer 和 digest 全部一致；返回 `projection.stale`、`projection.missing`、`projection.digest_mismatch` 的稳定 issue。

- [ ] **步骤 3：实现四种 aggregate view**

`views.json` 只保存以下 rebuildable indexes：

```go
type Views struct {
	Projects          []ViewEntry `json:"projects"`
	Domains           []ViewEntry `json:"domains"`
	ArchitectureUnits []ViewEntry `json:"architecture_units"`
	Features          []ViewEntry `json:"features"`
}

type ViewEntry struct {
	Key       string   `json:"key"`
	RecordIDs []string `json:"record_ids"`
}
```

每个 record ID 只来自 current manifest；排序稳定；view 不保存独立 narrative、结论或 authority。

- [ ] **步骤 4：实现 Rebuild generation**

Rebuild 从 current record revisions 重新读取 L1/L2，生成新 views 和 manifest projection references，再以新 generation 提交。权威 record bytes 不改变；如果任何 record/projection 校验失败，整个 rebuild 返回 validation_failed 且不提交。

- [ ] **步骤 5：实现失效传播**

Record revision 变化后旧 L1/L2 继续作为历史 payload 保留，但 current manifest 不得引用它们。Prepare 必须列出被替换 current projection；Apply 后 Verify 只能接受新 revision projections。

- [ ] **步骤 6：运行测试并提交**

```bash
gofmt -w internal/themico/projection
```

```bash
go test ./internal/themico/projection
```

```bash
git add internal/themico/projection
```

```bash
git commit -m "feat: rebuild Themico projections"
```

---

### 任务 11：接通完整 `themico` CLI command surface

**文件：**
- 修改：`internal/themico/cli/cli.go`
- 新建：`internal/themico/cli/commands.go`
- 修改：`internal/themico/cli/cli_test.go`
- 修改：`cmd/themico/main.go`

**接口：**
- 产出：可构建的 `themico` CLI；所有 mutation 通过 service/governance/store，不直接写文件。

- [ ] **步骤 1：写 command table 测试**

固定命令：

```text
themico init --root <root>
themico candidate create --root <root> --input <candidate.json> --content <content.md>
themico candidate revise --root <root> --input <revision.json> --content <content.md>
themico candidate create-derived --root <root> --source-record <record-id> --input <candidate.json> --content <content.md>
themico candidate confirm-type --root <root> --confirmation <confirmation.json>
themico candidate inspect --root <root> --id <candidate-id>
themico validate --root <root> --candidate <candidate-id> --revision <candidate-revision>
themico prepare publish --root <root> --candidate <candidate-id> --assessment <assessment.json>
themico prepare supersede --root <root> --candidate <candidate-id> --target <record-id> --assessment <assessment.json>
themico prepare deprecate --root <root> --record <record-id> --reason <reason.md>
themico prepare archive --root <root> --record <record-id> --reason <reason.md>
themico publish --root <root> --prepare <prepare-id> --approval <approval.json>
themico supersede --root <root> --prepare <prepare-id> --approval <approval.json>
themico deprecate --root <root> --prepare <prepare-id> --approval <approval.json>
themico archive --root <root> --prepare <prepare-id> --approval <approval.json>
themico query --root <root> --request <query.json>
themico inspect --root <root> --request <inspect.json>
themico verify-projection --root <root>
themico rebuild --root <root> --expected-generation <number>
```

测试每个 command 的缺参返回 usage_error；不存在 root 返回 not_found；stdout 始终只有一个 envelope。

- [ ] **步骤 2：实现 strict JSON file decoder**

使用 `json.Decoder.DisallowUnknownFields()`，再确认第二次 Decode 返回 `io.EOF`。所有 file path 参数先经过 root containment；CLI 不能接受 stdin 持续流，也不能读取多对象 JSON。

- [ ] **步骤 3：注册所有 handler**

`commands.go` 只做 flag parse、strict decode、service 调用、domain error 到 result status 映射和 envelope 输出。不得在 CLI layer 重复 model/validation/governance 逻辑。`candidate create-derived` 必须调用任务 9 的 `candidate.CreateDerived`，不能把 `derived_from` 降级为普通 create request 中可省略的自由文本关系。

- [ ] **步骤 4：验证可构建和 help 稳定**

```bash
gofmt -w cmd/themico internal/themico/cli
```

```bash
go test ./internal/themico/cli
```

```bash
go build ./...
```

执行两次 help，确认 stdout byte-identical：

```bash
go run ./cmd/themico help
```

- [ ] **步骤 5：提交**

```bash
git add cmd/themico internal/themico/cli
```

```bash
git commit -m "feat: expose Themico CLI operations"
```

---

### 任务 12：实现单一 Themico Skill 和按需 type factory references

**文件：**
- 新建：`templates/.claude/skills/themico/SKILL.md`
- 新建：`templates/.claude/skills/themico/references/common/operation-contract.md`
- 新建：`templates/.claude/skills/themico/references/common/result-contract.md`
- 新建：`templates/.claude/skills/themico/references/common/governance.md`
- 新建：`templates/.claude/skills/themico/references/common/knowledge-record.md`
- 新建：`templates/.claude/skills/themico/references/common/l1-discovery.md`
- 新建：`templates/.claude/skills/themico/references/common/type-registry.md`
- 新建：`templates/.claude/skills/themico/references/operations/query.md`
- 新建：`templates/.claude/skills/themico/references/operations/inspect.md`
- 新建：`templates/.claude/skills/themico/references/operations/create-candidate.md`
- 新建：`templates/.claude/skills/themico/references/operations/create-derived-candidate.md`
- 新建：`templates/.claude/skills/themico/references/operations/revise-candidate.md`
- 新建：`templates/.claude/skills/themico/references/operations/confirm-type.md`
- 新建：`templates/.claude/skills/themico/references/operations/validate.md`
- 新建：`templates/.claude/skills/themico/references/operations/prepare.md`
- 新建：`templates/.claude/skills/themico/references/operations/publish.md`
- 新建：`templates/.claude/skills/themico/references/operations/supersede.md`
- 新建：`templates/.claude/skills/themico/references/operations/deprecate.md`
- 新建：`templates/.claude/skills/themico/references/operations/archive.md`
- 新建：`templates/.claude/skills/themico/references/operations/verify-projection.md`
- 新建：`templates/.claude/skills/themico/references/operations/rebuild.md`
- 新建：`templates/.claude/skills/themico/references/types/design-decision/factory.md`
- 新建：`templates/.claude/skills/themico/references/types/design-decision/l2.md`
- 新建：`templates/.claude/skills/themico/references/types/design-decision/l3.md`
- 新建：`templates/.claude/skills/themico/references/types/design-decision/semantic-check.md`
- 新建：`templates/.claude/skills/themico/references/types/development-standard/factory.md`
- 新建：`templates/.claude/skills/themico/references/types/development-standard/l2.md`
- 新建：`templates/.claude/skills/themico/references/types/development-standard/l3.md`
- 新建：`templates/.claude/skills/themico/references/types/development-standard/semantic-check.md`
- 新建：`templates/.claude/skills/themico/references/types/development-experience/factory.md`
- 新建：`templates/.claude/skills/themico/references/types/development-experience/l2.md`
- 新建：`templates/.claude/skills/themico/references/types/development-experience/l3.md`
- 新建：`templates/.claude/skills/themico/references/types/development-experience/semantic-check.md`
- 新建：`internal/themico/integration/skill_contract_test.go`

**接口：**
- 产出：唯一公共 `themico` Skill；一次操作只加载一个 operation reference，正式 record 只加载 registry 指定的一个 type factory。

- [ ] **步骤 1：先写 Skill tree contract 测试**

测试必须读取上述固定路径，确认：

```text
只有 SKILL.md 有宿主 YAML frontmatter
SKILL name 恰为 themico
common references 6 个
operation references 14 个
type factories 恰为 3 个
每个 factory 都有 factory/l2/l3/semantic-check
所有正文包含中文标题
```

- [ ] **步骤 2：写公共 Skill 入口**

`SKILL.md` 的 description 优先说明：可查询 Themico、形成/审阅知识候选、通过 CLI 准备和执行经授权治理操作。正文固定加载顺序：

```text
common/operation-contract
→ selected operation reference
→ CLI inspect/query 得到 persisted type 或 candidate proposed type
→ common/type-registry
→ exactly one selected type factory
→ selected L2/L3/semantic-check reference
→ Agent proposal or assessment
→ CLI deterministic validation/prepare/apply
```

明确已有 record 的 type 只能来自 CLI；CLI unavailable 时只允许 draft-only、不持久化、不声称 current。

- [ ] **步骤 3：写 common 和 operation references**

每个 operation reference 必须写：输入、Agent 职责、CLI command、Human gate、权威输出、合法 machine statuses、fail-closed 行为。不得复制三个 type 的完整 L2/L3 合同。

- [ ] **步骤 4：写三个 type factory**

Factory 明确 Zone、L2/L3 reference 路径、分类依据和不适用条件。Semantic check 只产生 assessment candidate，不能授予 publication authority。

- [ ] **步骤 5：运行 contract test 并提交**

```bash
gofmt -w internal/themico/integration/skill_contract_test.go
```

```bash
go test ./internal/themico/integration -run TestSkillContract -count=1
```

```bash
git add templates/.claude/skills/themico internal/themico/integration/skill_contract_test.go
```

```bash
git commit -m "feat: add Themico knowledge Skill"
```

---

### 任务 13：补齐端到端、并发、中断和路径安全测试

**文件：**
- 新建：`internal/themico/integration/lifecycle_test.go`
- 新建：`internal/themico/integration/query_test.go`
- 新建：`internal/themico/integration/interruption_test.go`
- 新建：`internal/themico/integration/security_test.go`

**接口：**
- 产出：从 CLI request 到 generation commit/query 的可重复证据。

- [ ] **步骤 1：实现完整 happy path 测试**

使用 `cli.Run` 和 temp repository：init → create candidate → confirm type → validate → semantic assessment → prepare → Human Approval fixture → publish → query L1 → inspect L2 → inspect L3。断言每步 status、ID binding、generation 和 query trace。

- [ ] **步骤 2：实现三类型和跨类型派生测试**

每种 type 发布一条 record；从 development experience 派生 development standard；断言原 record 未改型、新 record 拥有 `derived_from`、对应 factory headings 和 Zone 均正确。

- [ ] **步骤 3：实现 lifecycle 测试**

覆盖 supersede、deprecate、archive、history query、默认 current query 和 Approval stale。确认正式知识不物理删除。

- [ ] **步骤 4：实现并发和中断测试**

两个 writer 从相同 generation prepare；并发 apply 只能一个 succeeded，另一个 conflict。分别在 payload 写入后、generation staging 写入后、rename 前注入故障，确认 current generation 和查询结果不变。

- [ ] **步骤 5：实现路径和输入安全测试**

覆盖：绝对路径、`..`、symlink/junction escape、case collision、oversized JSON、unknown field、duplicate JSON key、invalid UTF-8、Markdown frontmatter、relation cycle、source digest drift、budget exact boundary。

只对测试实际运行的平台声明通过；Windows junction 若当前权限无法创建，测试必须显式 `t.Skip` 并在最终 evidence 记录 unavailable，不能伪造 PASS。

- [ ] **步骤 6：运行全量测试并提交**

```bash
gofmt -w internal/themico/integration
```

```bash
go test ./... -count=1
```

```bash
go vet ./...
```

```bash
go build ./...
```

```bash
git add internal/themico/integration
```

```bash
git commit -m "test: verify Themico core workflows"
```

---

### 任务 14：对齐产品说明并生成实施验收证据

**文件：**
- 修改：`README.md`
- 新建：`docs/plan/themico-core/implementation-evidence.md`
- 新建：`docs/plan/themico-core/manual-replay.md`

**接口：**
- 产出：只陈述实际实现能力的产品说明、命令证据和人工 replay；不提前宣称 MCP/Themis integration。

- [ ] **步骤 1：更新 README 当前状态和入口**

新增 Themico 核心说明，链接 current Spec、`templates/.claude/skills/themico/SKILL.md` 和 CLI build/run 入口。明确：MCP adapter、Themis lifecycle 接线、外部 source fetch、embedding/vector search 当前 unavailable。

- [ ] **步骤 2：运行并记录 fresh verification**

运行：

```bash
go test ./... -count=1
```

```bash
go vet ./...
```

```bash
go build ./...
```

```bash
git diff --check
```

把完整命令、exit code、测试数量、skip 数量和平台写入 `implementation-evidence.md`。未运行或 skip 的保证标记 unavailable。

- [ ] **步骤 3：人工 replay 十个场景**

`manual-replay.md` 逐场景记录实际输入文件、CLI command、result status、generation before/after 和 observed files：

```text
1. design_decision happy path
2. development_standard happy path
3. development_experience happy path
4. type confirmation 后改型被拒绝
5. 跨类型 derived_from 新记录
6. stale source 阻止 prepare/publish
7. wrong Approval 阻止 apply
8. concurrent generation conflict
9. projection corruption detection and rebuild
10. progressive query budget and explicit cross-zone expansion
```

- [ ] **步骤 4：逐条映射 Spec 验收条件**

在 `implementation-evidence.md` 为 `acceptance.md` 每条标准给出唯一代码、测试或 replay 引用。找不到 fresh evidence 的标准保持 GAP，不得用计划文本代替证据。

- [ ] **步骤 5：审查范围和工作树**

运行：

```bash
git status --short
```

```bash
git diff --stat
```

确认没有 `.themico` 测试数据、编译产物、Python、YAML 产品合同、MCP adapter、Themis lifecycle 改动或依赖文件进入提交。

- [ ] **步骤 6：提交文档与最终证据**

```bash
git add README.md docs/plan/themico-core
```

```bash
git commit -m "docs: record Themico core evidence"
```

- [ ] **步骤 7：执行最终验收命令**

```bash
go test ./... -count=1
```

```bash
go vet ./...
```

```bash
go build ./...
```

```bash
git diff --check HEAD~14..HEAD
```

只有全部实际通过且 acceptance mapping 无未裁决 GAP 时，才能把核心实现报告为完成。提交和测试通过不自动构成用户接受，也不授权 push、PR、MCP 集成或 Themis lifecycle 接线。

---

## 计划自检清单

- Spec coverage：任务 1 固化本轮全部设计决定；任务 2–11 实现 CLI 核心；任务 12 实现单一 Skill/references；任务 13–14 提供运行证据和验收映射。
- Authority separation：Agent proposal、Human authorization、CLI machine authority 在 model、prepare、Approval、Skill 和测试中分别落实。
- Atomic record：candidate/record revision、L1/L2/L3、relations、source 和 generation commit 均以单条 Record 为治理单位。
- Progressive read：L1 query、exact-ID L2/L3 inspect、byte budget、cross-Zone 和 trace 都有独立实现与测试。
- Projection boundary：L1/L2 与 aggregate views 均绑定 record revision；rebuild 不生成新语义。
- Type consistency：三个 type identity、Zone compatibility、Factory 名称和 L2/L3 references 在 Spec、Go model、CLI、Skill 与测试中保持一致。
- Scope control：不实现 Claude API、MCP、Themis lifecycle integration、Embedding、SQLite、向量数据库、Web UI、migration 或自动知识摄取。
- Repository constraints：无 Python、无 Shell fallback、无产品 YAML、无功能版本或版本目录。
