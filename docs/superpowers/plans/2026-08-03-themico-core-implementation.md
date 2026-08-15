# Themico 核心实现计划

> **供 Agent 执行时使用：** 必须使用 `superpowers:subagent-driven-development`（推荐）或 `superpowers:executing-plans`，按任务逐项实施本计划。所有步骤使用复选框（`- [ ]`）跟踪。

**目标：** 实现一个独立、本地优先、无内置模型的 Themico 核心：通过单一公共 Skill 和按需 references 完成语义提案，通过 `themico` Go CLI 确定性执行原子 Knowledge Record 的校验、身份、修订、来源绑定、治理发布、渐进查询、失效和可重建投影。

**架构：** L1、L2、L3 是同一原子 Knowledge Record 的读取深度；正式语义由类型化 L3 和治理记录共同承载，L1/L2、索引与项目/领域/架构/feature 聚合视图均为可重建投影。Agent 负责理解、分类、摘要、相关性和忠实度分析，Human 负责类型确认与高影响授权，Go CLI 负责所有闭合集合、稳定身份、revision、digest、source binding、currentness、预算、引用完整性、可见提交、状态变化和 query trace。

**技术栈：** Go 1.26 标准库、JSON 机器合同、Markdown L3 与 Skill references、本地文件系统、Go 单元/集成/故障注入测试。首个计划不实现 Claude API、MCP adapter、Embedding、向量数据库、SQLite、Web UI、自动知识摄取或 Themis lifecycle 集成。

**Spec：** `docs/superpowers/specs/2026-07-29-themico-design/first-usable-delivery.md`（首个可用交付范围，顶层 authority 为 `docs/superpowers/specs/2026-07-29-themico-design.md`）。执行者必须同时阅读计划与该 Spec。

**当前进度：** 任务 1–5 已完成并合入 `main`（`44207c2..8f80edc`），提供 Spec authority、Go module 与 result envelope、知识模型与 registry、canonical JSON 与 generation store、candidate 生命周期。任务 6–12 是按首个可用交付范围重组后的剩余工作，逐个独立实现、测试、提交与 review。

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
- CLI 是唯一 machine authority：负责结构、枚举、ID、revision、canonical digest、本地 source binding、registry、currentness、确定性过滤、byte budget、关系完整性和可见提交。当前核心不定义独立 Catalog artifact 或命令；currentness 由 generation `manifest.json` 的 current pointers/projection references 承担。
- 本计划范围是 `docs/superpowers/specs/2026-07-29-themico-design/first-usable-delivery.md` 定义的首个可用交付。`views.json` 固定为 canonical 空对象 `{}`，只满足 generation 格式要求；它不是聚合索引，也不是 query authority，任何任务都不得把它声称为完整 current 索引。
- 以下能力属于后续独立计划，任何任务都不得实现、预留空 command、占位 handler 或未接线 reference：supersede、deprecate、archive、history query、跨类型派生与 `create-derived-candidate`、relation traversal、多跳查询、跨 Zone 查询扩展、cycle analysis、Agent relevance ranking、聚合 view、`rebuild` 命令、URL source、MCP、Embedding、向量数据库、SQLite、Web UI、Themis lifecycle 接线、token budget。
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
- Themico 安装到仓库根目录的 `.themico/`，分为控制面 `core/` 与受治理工作区 `workspace/`；store root 为 `.themico/workspace/`，`core/` 保存 Skill references 且不被 generation commit 写入。
- 公共 `SKILL.md` 位于 `.claude/skills/themico/`，因为宿主只从该目录发现 Skill；common/operation/type references 位于 `.themico/core/references/`。
- 首个存储实现使用 `.themico/workspace/`、不可变 payload 和 generation-directory commit；不实现通用数据库、通用 transaction framework、rollback、自动修复、upgrade 或 migration。
- `themico init` 只拥有 workspace：`.themico/workspace/` 已存在时必须在任何写入前失败，不接管或转换未知现有 store；`.themico/` 或 `.themico/core/` 已存在不构成失败条件，init 按需创建缺失的包目录与空 `core/`，且不读取或改写既有 control-plane 内容。
- repository-relative source path 相对仓库根解析，不相对包目录或 workspace。
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
│   ├── assessment.go
│   ├── prepare.go
│   ├── approval.go
│   ├── publish.go
│   └── governance_test.go
├── query/
│   ├── query.go
│   ├── inspect.go
│   └── query_test.go
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
└── SKILL.md                               仅宿主发现入口与转发说明

templates/.themico/core/
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
    │   └── publish.md
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
├── acceptance.md
└── first-usable-delivery.md

docs/plan/themico-core/
├── implementation-evidence.md
└── manual-replay.md
```

运行时数据布局固定为：

```text
<repository-root>/.themico/
├── core/                                  控制面：Skill references 与 type factories
└── workspace/                             受治理 store
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

> **任务 1–5 已完成**，代码已合入 `main`（`44207c2..8f80edc`）。以下记录保留作为接口来源与设计依据，**执行者不得重新实施**。剩余工作从任务 6 开始。

### 任务 1：把已确认的 Themico 设计增量固化为 current Spec（已完成）

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

### 任务 2：建立 Go module、CLI 进程合同和封闭结果状态（已完成）

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

### 任务 3：实现统一 Record model 和显式 type registry/factory（已完成）

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

### 任务 4：实现 canonical JSON、稳定 identity 和 generation store（已完成）

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

`store.Init(root, opts)` 只拥有 workspace：按需创建 `<root>/.themico` 与空 `core/`，检查 `<root>/.themico/workspace` 不存在，在包目录内创建 `workspace.init-<operation-id>` 完整 staging store，fsync 后通过单次 rename 发布为 `workspace`；rename 前失败必须删除本次 staging，rename 冲突必须返回 `precondition_failed`，不得接管既有 store。已安装的 `core/` 内容不阻止初始化，也不被读取或改写。`store.Open(root, opts)` 以 `<root>/.themico/workspace` 为 store root，验证 `store.json` identity、generation 0 manifest digest，以及从 generation 0 到 current generation 的连续 parent chain。

Store 的构造和可测试依赖固定为：

```go
type Options struct {
	Clock                  func() time.Time
	NewID                  func(prefix string) (string, error)
	BeforeGenerationRename func() error
}

func WorkspaceRoot(root string) string
func CoreRoot(root string) string

func Init(root string, opts Options) (*Store, error)
func Open(root string, opts Options) (*Store, error)
func (s *Store) Root() string
func (s *Store) RepositoryRoot() string
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

### 任务 5：实现 candidate create、revise、type confirmation 和 inspect（已完成）

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

### 任务 6：实现最小确定性 validate

**文件：**
- 新建：`internal/themico/validate/candidate.go`
- 新建：`internal/themico/validate/markdown.go`
- 新建：`internal/themico/validate/relation.go`
- 新建：`internal/themico/validate/validate_test.go`

**接口：**
- 消费：`store.Open(root string, opts store.Options) (*store.Store, error)`；`candidate.New(st *store.Store) *candidate.Service`；`(*candidate.Service).Inspect(ctx context.Context, candidateID string) (model.CandidateRevision, error)`；`model.LookupFactory(knowledgeType model.KnowledgeType) (model.Factory, bool)`；`model.Factory.L3Headings []string`；`model.Factory.DecodePayload func([]byte) (any, error)`；`canonical.Digest(value any) (string, error)`。
- 产出：

```go
package validate

// Report is the deterministic machine verdict for one candidate revision.
type Report struct {
	CandidateID       string        `json:"candidate_id"`
	CandidateRevision string        `json:"candidate_revision"`
	OK                bool          `json:"ok"`
	Issues            []result.Issue `json:"issues"`
}

func Candidate(ctx context.Context, st *store.Store, candidateID, candidateRevision string) (Report, error)
```

`Report.Issues` 使用 `result.Issue{Code, Path, Message}`，按 `Path`、`Code`、`Message` 升序排序，`nil` 归一化为空切片。`Candidate` 只在无法读取 store 或 candidate 时返回 error；机器可判定的合同问题一律进入 `Issues` 并令 `OK=false`。

本任务只做首个交付范围内的校验：类型/Zone 兼容、typed L2 payload、固定 L3 章节、L1/L2/L3 digest、candidate 精确 current revision、source currentness，以及**已提供 relation** 的类型、目标 identity 格式、目标存在性与跨 Zone 显式声明。不做关系遍历、多跳展开、cycle analysis 或自然语言正确性判断。

- [ ] **步骤 1：写 issue code 表与 Markdown 失败测试**

在 `validate_test.go` 中固定 issue code 闭集：

```text
type.unregistered
type.zone_incompatible
type.not_confirmed
l2.payload_invalid
markdown.frontmatter_forbidden
markdown.missing_h1
markdown.missing_heading
markdown.unknown_heading
markdown.heading_order
digest.l1_mismatch
digest.l2_mismatch
digest.l3_mismatch
candidate.revision_stale
source.stale
source.unreadable
relation.type_forbidden
relation.target_invalid
relation.target_missing
relation.cross_zone_not_explicit
```

先写三种类型各一个完整通过 fixture，再分别构造缺失章节、章节乱序、多余 H2 和 frontmatter 四种失败：

```go
func TestCandidateRejectsMalformedL3(t *testing.T) {
	for _, test := range []struct {
		name    string
		content string
		code    string
	}{
		{
			name:    "frontmatter",
			content: "---\ntitle: x\n---\n\n# 标题\n\n## 背景与问题\n正文\n",
			code:    "markdown.frontmatter_forbidden",
		},
		{
			name:    "missing heading",
			content: designDecisionContentWithout(t, "约束"),
			code:    "markdown.missing_heading",
		},
		{
			name:    "unknown heading",
			content: designDecisionContent(t) + "\n## 额外章节\n正文\n",
			code:    "markdown.unknown_heading",
		},
		{
			name:    "heading order",
			content: designDecisionContentSwapped(t, "决策", "约束"),
			code:    "markdown.heading_order",
		},
	} {
		t.Run(test.name, func(t *testing.T) {
			fixture := newFixture(t)
			created := fixture.confirmedCandidate(t, model.TypeDesignDecision, []byte(test.content))
			report := mustValidate(t, fixture.store, created.CandidateID, created.Revision)
			if report.OK || !hasIssue(report, test.code) {
				t.Fatalf("report=%+v want issue %s", report, test.code)
			}
		})
	}
}
```

- [ ] **步骤 2：运行测试确认失败**

Run: `go test ./internal/themico/validate -run TestCandidateRejectsMalformedL3 -v`
Expected: FAIL，`undefined: validate.Candidate`。

- [ ] **步骤 3：实现 Markdown validator**

`markdown.go`：

```go
package validate

// checkMarkdown verifies the fixed Chinese section contract for one knowledge type.
func checkMarkdown(content []byte, headings []string) []result.Issue {
	issues := make([]result.Issue, 0)
	text := string(content)
	if strings.HasPrefix(strings.TrimLeft(text, "﻿"), "---") {
		issues = append(issues, issue("markdown.frontmatter_forbidden", "content.md", "L3 must not start with YAML frontmatter"))
		return issues
	}

	var h1 int
	seen := make(map[string]int, len(headings))
	order := make([]string, 0, len(headings))
	for index, line := range strings.Split(text, "\n") {
		trimmed := strings.TrimRight(line, "\r")
		switch {
		case strings.HasPrefix(trimmed, "# "):
			h1++
		case strings.HasPrefix(trimmed, "## "):
			title := strings.TrimSpace(strings.TrimPrefix(trimmed, "## "))
			seen[title] = index
			order = append(order, title)
		}
	}
	if h1 != 1 {
		issues = append(issues, issue("markdown.missing_h1", "content.md", "L3 must contain exactly one H1"))
	}

	expected := make(map[string]struct{}, len(headings))
	for _, heading := range headings {
		expected[heading] = struct{}{}
		if _, ok := seen[heading]; !ok {
			issues = append(issues, issue("markdown.missing_heading", "content.md#"+heading, "required H2 is missing"))
		}
	}
	for _, title := range order {
		if _, ok := expected[title]; !ok {
			issues = append(issues, issue("markdown.unknown_heading", "content.md#"+title, "H2 is not part of this knowledge type"))
		}
	}

	previous := -1
	for _, heading := range headings {
		line, ok := seen[heading]
		if !ok {
			continue
		}
		if line < previous {
			issues = append(issues, issue("markdown.heading_order", "content.md#"+heading, "required H2 appears out of order"))
		}
		previous = line
	}
	return issues
}
```

重复 H2 由 `seen` 记录最后一次出现位置，乱序时必然触发 `markdown.heading_order`；H3 及更深标题不参与校验。

- [ ] **步骤 4：运行 Markdown 测试确认通过**

Run: `go test ./internal/themico/validate -run TestCandidateRejectsMalformedL3 -v`
Expected: PASS。

- [ ] **步骤 5：写 relation 与 source 失败测试**

```go
func TestCandidateChecksProvidedRelationsAndSources(t *testing.T) {
	fixture := newFixture(t)
	published := fixture.publishedRecord(t)

	for _, test := range []struct {
		name     string
		mutate   func(*testing.T, *fixtureState) (string, string)
		code     string
	}{
		{
			name: "forbidden type",
			mutate: func(t *testing.T, state *fixtureState) (string, string) {
				return state.candidateWithRelation(t, model.Relation{
					Type:           model.RelationSupersedes,
					TargetRecordID: published.RecordID,
				})
			},
			code: "relation.type_forbidden",
		},
		{
			name: "missing target",
			mutate: func(t *testing.T, state *fixtureState) (string, string) {
				return state.candidateWithRelation(t, model.Relation{
					Type:           model.RelationRelatedTo,
					TargetRecordID: "kr_99999999999999999999999999999999",
				})
			},
			code: "relation.target_missing",
		},
		{
			name: "implicit cross zone",
			mutate: func(t *testing.T, state *fixtureState) (string, string) {
				return state.candidateWithRelation(t, model.Relation{
					Type:           model.RelationRelatedTo,
					TargetRecordID: published.RecordID,
				})
			},
			code: "relation.cross_zone_not_explicit",
		},
		{
			name: "source drift",
			mutate: func(t *testing.T, state *fixtureState) (string, string) {
				id, revision := state.candidateWithSource(t, "docs/source.txt", []byte("v1"))
				writeSource(t, state.root, "docs/source.txt", []byte("v2"))
				return id, revision
			},
			code: "source.stale",
		},
	} {
		t.Run(test.name, func(t *testing.T) {
			id, revision := test.mutate(t, fixture)
			report := mustValidate(t, fixture.store, id, revision)
			if report.OK || !hasIssue(report, test.code) {
				t.Fatalf("report=%+v want issue %s", report, test.code)
			}
		})
	}
}
```

"implicit cross zone" fixture 必须让 candidate 与目标 record 处于不同 Zone 且 `CrossZone` 为 `false`。

- [ ] **步骤 6：实现 relation 与 source 校验**

`relation.go`：

```go
package validate

// candidateRelationTypes is the closed set a candidate may declare itself.
// supersedes is generated by governance operations only.
var candidateRelationTypes = map[model.RelationType]struct{}{
	model.RelationDependsOn:    {},
	model.RelationConstrains:   {},
	model.RelationDerivedFrom:  {},
	model.RelationAppliesTo:    {},
	model.RelationChallenges:   {},
	model.RelationCorrects:     {},
	model.RelationRecoversFrom: {},
	model.RelationFollows:      {},
	model.RelationRelatedTo:    {},
}

// checkRelations validates only the relations this revision declares. Traversal,
// multi-hop expansion and cycle analysis are a later plan.
func checkRelations(relations []model.Relation, zone model.Zone, targets map[string]model.RecordPointer, zones map[string]model.Zone) []result.Issue {
	issues := make([]result.Issue, 0)
	for index, relation := range relations {
		path := fmt.Sprintf("relations[%d]", index)
		if _, ok := candidateRelationTypes[relation.Type]; !ok {
			issues = append(issues, issue("relation.type_forbidden", path, "relation type cannot be declared by a candidate"))
			continue
		}
		if !strings.HasPrefix(relation.TargetRecordID, "kr_") || len(relation.TargetRecordID) != len("kr_")+32 {
			issues = append(issues, issue("relation.target_invalid", path, "target record ID is malformed"))
			continue
		}
		pointer, found := targets[relation.TargetRecordID]
		if !found {
			issues = append(issues, issue("relation.target_missing", path, "target record does not exist"))
			continue
		}
		if relation.TargetRecordRevision != "" && relation.TargetRecordRevision != pointer.Revision {
			issues = append(issues, issue("relation.target_missing", path, "target record revision is not current"))
			continue
		}
		if zones[relation.TargetRecordID] != zone && !relation.CrossZone {
			issues = append(issues, issue("relation.cross_zone_not_explicit", path, "cross-zone relation must set cross_zone"))
		}
	}
	return issues
}
```

`candidate.go` 中 source 校验重新读取仓库根下的实际 bytes 并比较 digest：

```go
func checkSources(repositoryRoot string, sources []model.SourceRef) []result.Issue {
	issues := make([]result.Issue, 0)
	root, err := os.OpenRoot(repositoryRoot)
	if err != nil {
		return append(issues, issue("source.unreadable", "sources", "repository root is unreadable"))
	}
	defer root.Close()
	for index, source := range sources {
		path := fmt.Sprintf("sources[%d]", index)
		data, err := readLimited(root, filepath.FromSlash(source.Path), maxSourceBytes)
		if err != nil {
			issues = append(issues, issue("source.unreadable", path, "source cannot be read"))
			continue
		}
		if rawDigest(data) != source.Digest {
			issues = append(issues, issue("source.stale", path, "source bytes changed after binding"))
		}
	}
	return issues
}
```

`maxSourceBytes` 为 `16 << 20`；`rawDigest` 返回 `"sha256:" + hex`，与 candidate service 中的实现保持一致。

- [ ] **步骤 7：实现 Candidate 聚合与稳定排序**

`candidate.go` 的 `Candidate` 依次执行：读取 current manifest 与 candidate → 比较 `candidateRevision` 是否为精确 current revision（否则 `candidate.revision_stale` 并立即返回）→ 要求 `Status == model.CandidateStatusTypeConfirmed`（否则 `type.not_confirmed`）→ `model.LookupFactory(revision.KnowledgeType)`（否则 `type.unregistered`）→ 比较 `factory.Zone` 与 `revision.Zone`（否则 `type.zone_incompatible`）→ `factory.DecodePayload(revision.L2.Payload)`（否则 `l2.payload_invalid`）→ `checkMarkdown` → 用 `canonical.Digest` 重算 L1/L2 并与 `revision.L1Digest`/`L2Digest` 比较、用 `rawDigest(revision.ContentMarkdown)` 与 `revision.L3Digest` 比较 → `checkSources` → `checkRelations`。

最后统一排序并归一化：

```go
slices.SortFunc(issues, func(left, right result.Issue) int {
	if left.Path != right.Path {
		return strings.Compare(left.Path, right.Path)
	}
	if left.Code != right.Code {
		return strings.Compare(left.Code, right.Code)
	}
	return strings.Compare(left.Message, right.Message)
})
return Report{
	CandidateID:       revision.CandidateID,
	CandidateRevision: revision.Revision,
	OK:                len(issues) == 0,
	Issues:            issues,
}, nil
```

- [ ] **步骤 8：写确定性重复校验测试**

```go
func TestCandidateProducesIdenticalReportsForIdenticalInput(t *testing.T) {
	fixture := newFixture(t)
	created := fixture.confirmedCandidate(t, model.TypeDevelopmentExperience, experienceContent(t))

	first := mustValidate(t, fixture.store, created.CandidateID, created.Revision)
	second := mustValidate(t, fixture.store, created.CandidateID, created.Revision)

	firstBytes, err := canonical.Encode(first)
	if err != nil {
		t.Fatal(err)
	}
	secondBytes, err := canonical.Encode(second)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(firstBytes, secondBytes) {
		t.Fatalf("report is not deterministic:\n%s\n%s", firstBytes, secondBytes)
	}
	if !first.OK {
		t.Fatalf("valid candidate reported issues: %+v", first.Issues)
	}
}
```

- [ ] **步骤 9：运行全部 validate 测试**

Run: `go test ./internal/themico/validate -count=1`
Expected: PASS。

- [ ] **步骤 10：格式化、验证并提交**

```bash
gofmt -w internal/themico/validate
```

```bash
go test ./... -count=1
```

```bash
go vet ./...
```

```bash
git add internal/themico/validate
```

```bash
git commit -m "feat: validate Themico candidate contracts"
```

---

### 任务 7：实现 semantic assessment、prepare、Human Approval 与 publish

**文件：**
- 新建：`internal/themico/governance/assessment.go`
- 新建：`internal/themico/governance/prepare.go`
- 新建：`internal/themico/governance/approval.go`
- 新建：`internal/themico/governance/publish.go`
- 新建：`internal/themico/governance/governance_test.go`

**接口：**
- 消费：`validate.Candidate(ctx, st, candidateID, candidateRevision) (validate.Report, error)`；`(*store.Store).CurrentState() (model.Manifest, json.RawMessage, error)`；`(*store.Store).Commit(ctx, store.CommitPlan) (model.Manifest, error)`；`(*store.Store).AllocateID(prefix string) (string, error)`；`(*store.Store).Now() time.Time`；`store.ImmutableWrite{Path, Data}`；`store.CommitPlan{ExpectedGeneration, Writes, Manifest, Views}`；`store.ErrConflict`、`store.ErrValidation`、`store.ErrPrecondition`。
- 产出：

```go
package governance

type Service struct{ /* unexported */ }

func New(st *store.Store) *Service

func (s *Service) PreparePublish(ctx context.Context, request PrepareRequest) (model.Prepare, error)
func (s *Service) Publish(ctx context.Context, request PublishRequest) (model.RecordRevision, error)

type PrepareRequest struct {
	CandidateID string
	Assessment  model.SemanticAssessment
}

type PublishRequest struct {
	PrepareID string
	Approval  model.Approval
}
```

- [ ] **步骤 1：把治理工件加入 model**

在 `internal/themico/model/model.go` 追加（字段顺序即 JSON 契约，`canonical.Encode` 负责按 key 排序）：

```go
// SemanticAssessmentStatus is the closed assessment verdict set.
type SemanticAssessmentStatus string

const (
	AssessmentPass SemanticAssessmentStatus = "pass"
	AssessmentFail SemanticAssessmentStatus = "fail"
)

func (value SemanticAssessmentStatus) Valid() bool {
	return value == AssessmentPass || value == AssessmentFail
}

// SemanticAssessment is an independent Agent verdict bound to one candidate revision.
type SemanticAssessment struct {
	Schema            string                   `json:"schema"`
	CandidateID       string                   `json:"candidate_id"`
	CandidateRevision string                   `json:"candidate_revision"`
	Status            SemanticAssessmentStatus `json:"status"`
	CheckerIdentity   string                   `json:"checker_identity"`
	CheckedAt         string                   `json:"checked_at"`
	Notes             string                   `json:"notes"`
}

// Prepare freezes every input one authorized publish may commit.
type Prepare struct {
	Schema            string           `json:"schema"`
	PrepareID         string           `json:"prepare_id"`
	Operation         string           `json:"operation"`
	CandidateID       string           `json:"candidate_id"`
	CandidateRevision string           `json:"candidate_revision"`
	CandidateDigest   string           `json:"candidate_digest"`
	AssessmentDigest  string           `json:"assessment_digest"`
	Sources           []SourceRef      `json:"sources"`
	ExpectedGeneration uint64          `json:"expected_generation"`
	RecordID          string           `json:"record_id"`
	RecordRevision    string           `json:"record_revision"`
	L1Digest          string           `json:"l1_digest"`
	L2Digest          string           `json:"l2_digest"`
	L3Digest          string           `json:"l3_digest"`
	Writes            []PreparedWrite  `json:"writes"`
	Invalidations     []ProjectionRef  `json:"invalidations"`
	CreatedAt         string           `json:"created_at"`
	Digest            string           `json:"digest"`
}

// PreparedWrite is one frozen immutable target inside a prepare.
type PreparedWrite struct {
	Path   string `json:"path"`
	Digest string `json:"digest"`
}

// Approval is the Human authorization bound to one exact prepare.
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

`Prepare.Digest` 参与 canonical digest 计算前必须为空字符串，计算后再回填，与 `Manifest.Digest` 的既有做法一致。

- [ ] **步骤 2：写 publish gate 失败测试**

```go
func TestPublishGatesFailClosed(t *testing.T) {
	for _, test := range []struct {
		name    string
		arrange func(*testing.T, *fixtureState) PublishRequest
		wantErr error
	}{
		{name: "missing approval", arrange: withoutApproval, wantErr: store.ErrPrecondition},
		{name: "wrong operation", arrange: withApprovalOperation("supersede"), wantErr: store.ErrPrecondition},
		{name: "wrong prepare digest", arrange: withApprovalDigest("sha256:" + strings.Repeat("0", 64)), wantErr: store.ErrPrecondition},
		{name: "empty approver", arrange: withApprovalApprover(""), wantErr: store.ErrPrecondition},
		{name: "source drift", arrange: withSourceDrift, wantErr: store.ErrValidation},
		{name: "generation advanced", arrange: withAdvancedGeneration, wantErr: store.ErrConflict},
	} {
		t.Run(test.name, func(t *testing.T) {
			fixture := newFixture(t)
			request := test.arrange(t, fixture)
			before := mustCurrent(t, fixture.store)

			if _, err := fixture.governance.Publish(context.Background(), request); !errors.Is(err, test.wantErr) {
				t.Fatalf("error: %v want %v", err, test.wantErr)
			}

			after := mustCurrent(t, fixture.store)
			if len(after.CurrentRecords) != len(before.CurrentRecords) {
				t.Fatalf("failed publish changed current records: %+v", after.CurrentRecords)
			}
			if after.Generation != before.Generation {
				t.Fatalf("failed publish advanced generation %d -> %d", before.Generation, after.Generation)
			}
		})
	}
}
```

- [ ] **步骤 3：运行测试确认失败**

Run: `go test ./internal/themico/governance -run TestPublishGatesFailClosed -v`
Expected: FAIL，`undefined: governance.New`。

- [ ] **步骤 4：实现 assessment 校验**

`assessment.go`：

```go
package governance

const assessmentSchema = "themico/semantic-assessment"

// checkAssessment proves binding and structure only. Whether the notes are
// correct is a Human judgment the CLI never makes.
func checkAssessment(assessment model.SemanticAssessment, candidate model.CandidateRevision) error {
	if assessment.Schema != assessmentSchema {
		return validationError("assessment schema is invalid", nil)
	}
	if !assessment.Status.Valid() {
		return validationError("assessment status is invalid", nil)
	}
	if assessment.Status != model.AssessmentPass {
		return preconditionError("assessment did not pass", nil)
	}
	if assessment.CandidateID != candidate.CandidateID || assessment.CandidateRevision != candidate.Revision {
		return preconditionError("assessment is not bound to the candidate revision", nil)
	}
	if strings.TrimSpace(assessment.CheckerIdentity) == "" {
		return validationError("assessment checker identity is required", nil)
	}
	if assessment.CheckerIdentity == candidate.ProposedBy {
		return preconditionError("assessment checker must differ from the proposer", nil)
	}
	if _, err := time.Parse(time.RFC3339, assessment.CheckedAt); err != nil {
		return validationError("assessment time is invalid", err)
	}
	return nil
}
```

CLI 只比较 identity 字段是否不同，不声称两者在现实中确为不同的人或进程。

- [ ] **步骤 5：实现 PreparePublish**

`prepare.go` 的 `PreparePublish` 依次：`Inspect` current candidate → `validate.Candidate` 且要求 `Report.OK` → `checkAssessment` → 读取 `CurrentState()` 取 `expectedGeneration` → `AllocateID("kr_")` 与 `AllocateID("rev_")` → 构造 record revision、L1/L2 projection 与 content 的 canonical bytes → 计算每个 write 的 digest → 组装 `model.Prepare` → 计算 `Digest` → 以单次 commit 写入 `preparations/<prepare-id>/prepare.json` 与 `assessments/<assessment-digest>.json`。

首个交付只发布新记录，`Invalidations` 恒为空切片（不是 `nil`），字段仍必须存在并参与 digest。

write set 固定为四个不可变目标：

```text
records/<record-id>/revisions/<record-revision>/record.json
records/<record-id>/revisions/<record-revision>/content.md
projections/<record-id>/<record-revision>/l1.json
projections/<record-id>/<record-revision>/l2.json
```

Prepare 自身的 commit 不改变 current record pointers，只增加不可变工件。

- [ ] **步骤 6：实现 Approval 校验**

`approval.go`：

```go
package governance

const approvalSchema = "themico/approval"

// checkApproval verifies the authorization artifact's structure and its exact
// binding. It never claims to have verified the human behind approved_by.
func checkApproval(approval model.Approval, prepare model.Prepare) error {
	if approval.Schema != approvalSchema {
		return validationError("approval schema is invalid", nil)
	}
	if approval.Operation != operationPublish || prepare.Operation != operationPublish {
		return preconditionError("approval operation does not match publish", nil)
	}
	if approval.PrepareID != prepare.PrepareID || approval.PrepareDigest != prepare.Digest {
		return preconditionError("approval is not bound to this prepare", nil)
	}
	if strings.TrimSpace(approval.ApprovedBy) == "" || strings.TrimSpace(approval.AuthorityRef) == "" {
		return preconditionError("approval identity and authority reference are required", nil)
	}
	if _, err := time.Parse(time.RFC3339, approval.ApprovedAt); err != nil {
		return validationError("approval time is invalid", err)
	}
	return nil
}
```

- [ ] **步骤 7：实现 publish generation commit**

`publish.go` 的 `Publish`：读取 prepare → `checkApproval` → 重新读取 current candidate 并要求仍是 prepare 冻结的 revision → 重新校验 source currentness（漂移返回 `store.ErrValidation`）→ 要求 `CurrentState()` 的 generation 等于 `prepare.ExpectedGeneration`（否则 `store.ErrConflict`）→ 在**一次** `store.Commit` 中写入：

```go
plan := store.CommitPlan{
	ExpectedGeneration: prepare.ExpectedGeneration,
	Writes: []store.ImmutableWrite{
		{Path: recordPath(prepare.RecordID, prepare.RecordRevision, "record.json"), Data: recordBytes},
		{Path: recordPath(prepare.RecordID, prepare.RecordRevision, "content.md"), Data: contentBytes},
		{Path: projectionPath(prepare.RecordID, prepare.RecordRevision, "l1.json"), Data: l1Bytes},
		{Path: projectionPath(prepare.RecordID, prepare.RecordRevision, "l2.json"), Data: l2Bytes},
		{Path: approvalPath(approvalDigest), Data: approvalBytes},
	},
	Manifest: manifest,
	Views:    views,
}
```

`manifest` 在 `CurrentState()` 返回值基础上追加 active `model.RecordPointer`、追加 `model.ProjectionRef`，并把 candidate pointer 的 `Status` 改为 `model.CandidateStatusPublished`、`RecordID` 设为 `prepare.RecordID`。`views` 原样透传 `CurrentState()` 返回的 bytes——首个交付固定为 `{}`，本任务不得改写它。

同一 candidate 的 published 绑定必须由 candidate pointer 承担，任务 8 的 query 据此判断 candidate 与 record 的关系。

- [ ] **步骤 8：写 publish 成功与原子性测试**

```go
func TestPublishCommitsRecordProjectionAndCandidateBindingAtomically(t *testing.T) {
	fixture := newFixture(t)
	prepare := fixture.preparePublish(t)
	before := mustCurrent(t, fixture.store)

	record, err := fixture.governance.Publish(context.Background(), PublishRequest{
		PrepareID: prepare.PrepareID,
		Approval:  fixture.approvalFor(t, prepare),
	})
	if err != nil {
		t.Fatal(err)
	}

	after := mustCurrent(t, fixture.store)
	if after.Generation != before.Generation+1 {
		t.Fatalf("generation %d -> %d want exactly one commit", before.Generation, after.Generation)
	}
	if record.Status != model.RecordStatusActive || record.RecordID != prepare.RecordID {
		t.Fatalf("record=%+v", record)
	}

	pointer, ok := recordPointer(after, prepare.RecordID)
	if !ok || pointer.Revision != prepare.RecordRevision || pointer.Status != model.RecordStatusActive {
		t.Fatalf("record pointer=%+v ok=%v", pointer, ok)
	}
	projection, ok := projectionRef(after, prepare.RecordID)
	if !ok || projection.Revision != prepare.RecordRevision || projection.L3Digest != prepare.L3Digest {
		t.Fatalf("projection ref=%+v ok=%v", projection, ok)
	}
	candidate, ok := candidatePointer(after, prepare.CandidateID)
	if !ok || candidate.Status != model.CandidateStatusPublished || candidate.RecordID != prepare.RecordID {
		t.Fatalf("candidate pointer=%+v ok=%v", candidate, ok)
	}
}
```

- [ ] **步骤 9：写中断不产生可见发布的测试**

```go
func TestPublishInterruptedBeforeRenameLeavesCurrentStateUnchanged(t *testing.T) {
	fixture := newFixtureWithOptions(t, func(opts *store.Options) {
		opts.BeforeGenerationRename = func() error { return errors.New("injected pre-rename fault") }
	})
	prepare := fixture.preparePublish(t)
	before := mustCurrent(t, fixture.store)

	if _, err := fixture.governance.Publish(context.Background(), PublishRequest{
		PrepareID: prepare.PrepareID,
		Approval:  fixture.approvalFor(t, prepare),
	}); err == nil {
		t.Fatal("publish unexpectedly succeeded")
	}

	after := mustCurrent(t, fixture.store)
	if after.Generation != before.Generation {
		t.Fatalf("interrupted publish advanced generation %d -> %d", before.Generation, after.Generation)
	}
	if _, ok := recordPointer(after, prepare.RecordID); ok {
		t.Fatal("interrupted publish exposed a record pointer")
	}
}
```

- [ ] **步骤 10：运行测试并提交**

```bash
gofmt -w internal/themico/governance internal/themico/model
```

```bash
go test ./internal/themico/governance -count=1
```

```bash
go test ./... -count=1
```

```bash
git add internal/themico/governance internal/themico/model
```

```bash
git commit -m "feat: govern Themico publication"
```

---

### 任务 8：实现 record inspect 与基础 query

**文件：**
- 新建：`internal/themico/query/query.go`
- 新建：`internal/themico/query/inspect.go`
- 新建：`internal/themico/query/query_test.go`

**接口：**
- 消费：`(*store.Store).Current() (model.Manifest, error)`；`(*store.Store).Root() string`；`model.RecordPointer`、`model.ProjectionRef`、`model.Projection`、`model.RecordRevision`；`canonical.Encode`、`canonical.Digest`。
- 产出：

```go
package query

type Request struct {
	Zones              []model.Zone          `json:"zones"`
	Types              []model.KnowledgeType `json:"types"`
	Statuses           []model.RecordStatus  `json:"statuses"`
	Project            string                `json:"project"`
	DomainsAny         []string              `json:"domains_any"`
	ArchitectureAny    []string              `json:"architecture_units_any"`
	FeaturesAny        []string              `json:"features_any"`
	TagsAny            []string              `json:"tags_any"`
	TriggersAny        []string              `json:"triggers_any"`
	ContentBudgetBytes int64                 `json:"content_budget_bytes"`
}

type Candidate struct {
	RecordID string             `json:"record_id"`
	Revision string             `json:"record_revision"`
	Zone     model.Zone         `json:"zone"`
	Type     model.KnowledgeType `json:"knowledge_type"`
	Status   model.RecordStatus `json:"status"`
	L1       model.L1           `json:"l1"`
}

type Result struct {
	Generation uint64      `json:"generation"`
	Candidates []Candidate `json:"candidates"`
	Trace      Trace       `json:"trace"`
}

type InspectRequest struct {
	RecordIDs          []string `json:"record_ids"`
	Depth              int      `json:"depth"`
	ContentBudgetBytes int64    `json:"content_budget_bytes"`
}

type Item struct {
	RecordID string              `json:"record_id"`
	Revision string              `json:"record_revision"`
	Zone     model.Zone          `json:"zone"`
	Type     model.KnowledgeType  `json:"knowledge_type"`
	Status   model.RecordStatus  `json:"status"`
	Scope    model.Scope         `json:"scope"`
	L1       model.L1            `json:"l1"`
	L2       *model.L2           `json:"l2,omitempty"`
	L3       string              `json:"l3,omitempty"`
}

type InspectResult struct {
	Generation uint64 `json:"generation"`
	Items      []Item `json:"items"`
	Trace      Trace  `json:"trace"`
}

// Trace records replayable machine facts only. Agent relevance and semantic
// explanation stay outside CLI authority.
type Trace struct {
	ObservedGeneration uint64   `json:"observed_generation"`
	SearchedZones      []string `json:"searched_zones"`
	CandidateIDs       []string `json:"candidate_ids"`
	SelectedIDs        []string `json:"selected_ids"`
	ExcludedIDs        []string `json:"excluded_ids"`
	ContentBytes       int64    `json:"content_bytes"`
	RemainingBytes     int64    `json:"remaining_bytes"`
}

var ErrBudgetExceeded = errors.New("themico query budget exceeded")

func Search(ctx context.Context, st *store.Store, request Request) (Result, error)
func Inspect(ctx context.Context, st *store.Store, request InspectRequest) (InspectResult, error)
```

首个交付不实现 history、relation expansion、cross-Zone 扩展和 relevance ranking，因此 `Request` 不含相关字段——不得预留未接线的开关。

- [ ] **步骤 1：写 query 过滤与排序测试**

```go
func TestSearchReturnsOnlyCurrentActiveL1InStableOrder(t *testing.T) {
	fixture := newFixture(t)
	decision := fixture.publish(t, model.TypeDesignDecision, "themis", []string{"core"}, []string{"governance"})
	standard := fixture.publish(t, model.TypeDevelopmentStandard, "themis", []string{"core"}, []string{"review"})
	experience := fixture.publish(t, model.TypeDevelopmentExperience, "themis", []string{"store"}, []string{"commit"})

	result, err := Search(context.Background(), fixture.store, Request{
		Zones:              []model.Zone{model.ZoneProjectKnowledge},
		ContentBudgetBytes: 1 << 20,
	})
	if err != nil {
		t.Fatal(err)
	}

	got := recordIDs(result.Candidates)
	want := sortedIDs(decision.RecordID, standard.RecordID)
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("candidates=%v want %v (experience %s is in the other zone)", got, want, experience.RecordID)
	}
	for _, candidate := range result.Candidates {
		if candidate.Status != model.RecordStatusActive {
			t.Fatalf("non-active candidate: %+v", candidate)
		}
	}
}

func TestSearchAppliesDeterministicFilters(t *testing.T) {
	fixture := newFixture(t)
	matching := fixture.publishWithL1(t, model.TypeDesignDecision, model.L1{
		Title: "决策", Summary: "摘要", Triggers: []string{"发布"}, Tags: []string{"governance"},
	})
	fixture.publishWithL1(t, model.TypeDesignDecision, model.L1{
		Title: "其他", Summary: "摘要", Triggers: []string{"查询"}, Tags: []string{"query"},
	})

	for _, test := range []struct {
		name    string
		request Request
	}{
		{name: "tags", request: Request{TagsAny: []string{"governance"}}},
		{name: "triggers", request: Request{TriggersAny: []string{"发布"}}},
		{name: "types", request: Request{Types: []model.KnowledgeType{model.TypeDesignDecision}, TagsAny: []string{"governance"}}},
	} {
		t.Run(test.name, func(t *testing.T) {
			request := test.request
			request.Zones = []model.Zone{model.ZoneProjectKnowledge}
			request.ContentBudgetBytes = 1 << 20

			result, err := Search(context.Background(), fixture.store, request)
			if err != nil {
				t.Fatal(err)
			}
			if len(result.Candidates) != 1 || result.Candidates[0].RecordID != matching.RecordID {
				t.Fatalf("candidates=%v want only %s", recordIDs(result.Candidates), matching.RecordID)
			}
		})
	}
}
```

`Zones` 必填且非空，否则返回 `store.ErrValidation`；空 `Types`/`Statuses` 分别表示全部注册类型与仅 `active`。结果按 `RecordID`、`Revision` 升序。

- [ ] **步骤 2：运行测试确认失败**

Run: `go test ./internal/themico/query -run TestSearch -v`
Expected: FAIL，`undefined: query.Search`。

- [ ] **步骤 3：实现 Search**

`query.go` 从 `st.Current()` 取合法 current manifest，对每个 `model.RecordPointer` 只接受 `Status` 落在请求 status 集合中的项，按 `ProjectionRef` 读取 `projections/<record-id>/<record-revision>/l1.json`，逐项验证：projection 的 `RecordID`/`Revision` 与 pointer 一致、`L1Digest` 与重算值一致、`L3Digest` 与 `ProjectionRef.L3Digest` 一致。任一绑定失效即返回 `store.ErrValidation` 失败关闭，不得跳过该记录继续返回部分结果，也不得从 L3 生成摘要。

scope 过滤语义：`Project` 非空时要求精确相等；`DomainsAny`、`ArchitectureAny`、`FeaturesAny`、`TagsAny`、`TriggersAny` 非空时要求交集非空。

- [ ] **步骤 4：写 inspect depth 与预算边界测试**

```go
func TestInspectReturnsRequestedDepth(t *testing.T) {
	fixture := newFixture(t)
	published := fixture.publish(t, model.TypeDesignDecision, "themis", []string{"core"}, []string{"governance"})

	for _, test := range []struct {
		depth  int
		wantL2 bool
		wantL3 bool
	}{
		{depth: 1, wantL2: false, wantL3: false},
		{depth: 2, wantL2: true, wantL3: false},
		{depth: 3, wantL2: true, wantL3: true},
	} {
		t.Run(fmt.Sprintf("depth-%d", test.depth), func(t *testing.T) {
			result, err := Inspect(context.Background(), fixture.store, InspectRequest{
				RecordIDs:          []string{published.RecordID},
				Depth:              test.depth,
				ContentBudgetBytes: 1 << 20,
			})
			if err != nil {
				t.Fatal(err)
			}
			item := result.Items[0]
			if (item.L2 != nil) != test.wantL2 || (item.L3 != "") != test.wantL3 {
				t.Fatalf("depth %d: L2=%v L3=%v", test.depth, item.L2 != nil, item.L3 != "")
			}
		})
	}
}

func TestInspectRejectsInvalidDepthAndEnforcesExactBudget(t *testing.T) {
	fixture := newFixture(t)
	published := fixture.publish(t, model.TypeDesignDecision, "themis", []string{"core"}, []string{"governance"})

	for _, depth := range []int{0, 4, -1} {
		if _, err := Inspect(context.Background(), fixture.store, InspectRequest{
			RecordIDs:          []string{published.RecordID},
			Depth:              depth,
			ContentBudgetBytes: 1 << 20,
		}); !errors.Is(err, store.ErrValidation) {
			t.Fatalf("depth %d: %v", depth, err)
		}
	}

	exact := mustInspectBytes(t, fixture.store, published.RecordID, 3)
	if _, err := Inspect(context.Background(), fixture.store, InspectRequest{
		RecordIDs:          []string{published.RecordID},
		Depth:              3,
		ContentBudgetBytes: exact,
	}); err != nil {
		t.Fatalf("exact budget must succeed: %v", err)
	}
	result, err := Inspect(context.Background(), fixture.store, InspectRequest{
		RecordIDs:          []string{published.RecordID},
		Depth:              3,
		ContentBudgetBytes: exact - 1,
	})
	if !errors.Is(err, ErrBudgetExceeded) {
		t.Fatalf("error: %v want ErrBudgetExceeded", err)
	}
	if len(result.Items) != 0 {
		t.Fatalf("budget failure returned partial items: %+v", result.Items)
	}
}
```

- [ ] **步骤 5：新增 `store.ErrNotFound` sentinel**

`internal/themico/store/store.go` 当前只有 `ErrValidation`、`ErrPrecondition`、`ErrConflict`。在同一 `var` 块追加：

```go
var (
	ErrValidation   = errors.New("themico store validation failed")
	ErrPrecondition = errors.New("themico store precondition failed")
	ErrConflict     = errors.New("themico store conflict")
	ErrNotFound     = errors.New("themico store object not found")
)
```

该 sentinel 供 query/inspect 表达"请求的 record ID 不在 current manifest 中"，由任务 9 映射为 `not_found`。本步骤不改变任何既有行为。

- [ ] **步骤 6：实现 Inspect**

`inspect.go` 只接受 `Depth` 为 `1`、`2`、`3`，`ContentBudgetBytes` 范围为 `1` 到 `16 << 20`，越界返回 `store.ErrValidation`。记录必须由 exact record ID 请求，未找到返回 `store.ErrNotFound`。

预算按**实际返回 bytes** 计数：对每个 item 先 `canonical.Encode` 得到完整 bytes 长度，若超出剩余预算则整个请求返回 `ErrBudgetExceeded` 且 `Items` 为空——不截断 L3、不删除章节、不返回半个对象。每次读取同样执行本任务步骤 3 的 digest 与 pointer 绑定校验。

- [ ] **步骤 7：写篡改失败关闭测试**

```go
func TestReadsFailClosedWhenBindingsAreTampered(t *testing.T) {
	for _, test := range []struct {
		name   string
		tamper func(*testing.T, *fixtureState, model.RecordRevision)
	}{
		{name: "projection l1", tamper: overwriteProjectionL1},
		{name: "record content", tamper: overwriteRecordContent},
		{name: "record payload", tamper: overwriteRecordPayload},
	} {
		t.Run(test.name, func(t *testing.T) {
			fixture := newFixture(t)
			published := fixture.publish(t, model.TypeDesignDecision, "themis", []string{"core"}, []string{"governance"})
			test.tamper(t, fixture, published)

			if _, err := Search(context.Background(), fixture.store, Request{
				Zones:              []model.Zone{model.ZoneProjectKnowledge},
				ContentBudgetBytes: 1 << 20,
			}); !errors.Is(err, store.ErrValidation) {
				t.Fatalf("search error: %v want validation failure", err)
			}
			if _, err := Inspect(context.Background(), fixture.store, InspectRequest{
				RecordIDs:          []string{published.RecordID},
				Depth:              3,
				ContentBudgetBytes: 1 << 20,
			}); !errors.Is(err, store.ErrValidation) {
				t.Fatalf("inspect error: %v want validation failure", err)
			}
		})
	}
}
```

- [ ] **步骤 8：运行测试并提交**

```bash
gofmt -w internal/themico/query
```

```bash
go test ./internal/themico/query -count=1
```

```bash
go test ./... -count=1
```

```bash
git add internal/themico/query internal/themico/store
```

```bash
git commit -m "feat: add Themico query and record inspect"
```

---

### 任务 9：接通核心 `themico` CLI command surface

**文件：**
- 修改：`internal/themico/cli/cli.go`
- 新建：`internal/themico/cli/commands.go`
- 修改：`internal/themico/cli/cli_test.go`
- 修改：`cmd/themico/main.go`

**接口：**
- 消费：`store.Init`、`store.Open`；`candidate.New(...).Create/Revise/ConfirmType/Inspect`；`validate.Candidate`；`governance.New(...).PreparePublish/Publish`；`query.Search`、`query.Inspect`；`result.Envelope`、`result.Write`、`result.ExitCode`。
- 产出：可构建的 `themico` 二进制，stdout 恒为单一 JSON envelope。

- [ ] **步骤 1：写 command table 测试**

固定命令表（首个交付范围，不含延期能力）：

```text
themico help
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

```go
func TestRunEmitsExactlyOneEnvelopePerInvocation(t *testing.T) {
	for _, test := range []struct {
		name string
		args []string
		want result.Status
	}{
		{name: "unknown command", args: []string{"supersede"}, want: result.StatusUsageError},
		{name: "missing root", args: []string{"init"}, want: result.StatusUsageError},
		{name: "unknown flag", args: []string{"init", "--root", ".", "--force"}, want: result.StatusUsageError},
		{name: "absent store", args: []string{"candidate", "inspect", "--root", t.TempDir(), "--id", "cand_" + strings.Repeat("0", 32)}, want: result.StatusNotFound},
	} {
		t.Run(test.name, func(t *testing.T) {
			var stdout, stderr bytes.Buffer
			code := Run(context.Background(), test.args, &stdout, &stderr)

			var envelope result.Envelope
			decoder := json.NewDecoder(bytes.NewReader(stdout.Bytes()))
			if err := decoder.Decode(&envelope); err != nil {
				t.Fatalf("stdout is not one envelope: %v (%q)", err, stdout.String())
			}
			if err := decoder.Decode(&struct{}{}); err != io.EOF {
				t.Fatalf("stdout carries trailing output: %q", stdout.String())
			}
			if envelope.Status != test.want {
				t.Fatalf("status=%s want %s", envelope.Status, test.want)
			}
			wantCode, err := result.ExitCode(test.want)
			if err != nil {
				t.Fatal(err)
			}
			if code != wantCode {
				t.Fatalf("exit=%d want %d", code, wantCode)
			}
			if envelope.Issues == nil {
				t.Fatal("issues must be an empty array, never null")
			}
		})
	}
}
```

延期命令必须落在 `unknown_command`——不得注册占位 handler。

- [ ] **步骤 2：运行测试确认失败**

Run: `go test ./internal/themico/cli -run TestRunEmitsExactlyOneEnvelopePerInvocation -v`
Expected: FAIL，`init` 当前返回 `unknown_command`。

- [ ] **步骤 3：实现 strict JSON 文件解码**

`commands.go`：

```go
// decodeJSONFile reads one strict machine JSON document. Unknown fields,
// trailing values and oversized inputs are refused.
func decodeJSONFile(path string, destination any) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	if len(data) > maxMachineJSONBytes {
		return fmt.Errorf("machine JSON exceeds %d bytes", maxMachineJSONBytes)
	}
	if bytes.Equal(bytes.TrimSpace(data), []byte("null")) {
		return fmt.Errorf("payload must be an object")
	}
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
	decoder.UseNumber()
	if err := decoder.Decode(destination); err != nil {
		return err
	}
	if err := decoder.Decode(&struct{}{}); err != io.EOF {
		if err == nil {
			return fmt.Errorf("trailing JSON value")
		}
		return err
	}
	return nil
}
```

- [ ] **步骤 4：实现 domain error 到 status 的映射**

```go
func statusFor(err error) result.Status {
	switch {
	case err == nil:
		return result.StatusSucceeded
	case errors.Is(err, query.ErrBudgetExceeded):
		return result.StatusBudgetExceeded
	case errors.Is(err, store.ErrConflict):
		return result.StatusConflict
	case errors.Is(err, store.ErrPrecondition):
		return result.StatusPreconditionFailed
	case errors.Is(err, store.ErrNotFound), errors.Is(err, candidate.ErrNotFound):
		return result.StatusNotFound
	case errors.Is(err, store.ErrValidation), errors.Is(err, candidate.ErrTypeImmutable):
		return result.StatusValidationFailed
	default:
		return result.StatusInternalError
	}
}
```

CLI 层只做参数解析、strict decode、service 调用、错误映射与 envelope 输出，不重复 model、validation、governance 或 store 逻辑。

- [ ] **步骤 5：注册命令并更新 help**

`help` 的 `commands` 数组必须与实际注册表一致，且只列出首个交付命令。缺少必需 flag、未知 flag、未知子命令一律 `usage_error`。

- [ ] **步骤 6：写 help 确定性测试**

```go
func TestHelpOutputIsByteIdenticalAcrossRuns(t *testing.T) {
	var first, second bytes.Buffer
	if code := Run(context.Background(), []string{"help"}, &first, io.Discard); code != result.ExitSuccess {
		t.Fatalf("exit=%d", code)
	}
	if code := Run(context.Background(), []string{"help"}, &second, io.Discard); code != result.ExitSuccess {
		t.Fatalf("exit=%d", code)
	}
	if !bytes.Equal(first.Bytes(), second.Bytes()) {
		t.Fatalf("help is not deterministic:\n%s\n%s", first.String(), second.String())
	}
	for _, deferred := range []string{"supersede", "deprecate", "archive", "rebuild", "create-derived"} {
		if bytes.Contains(first.Bytes(), []byte(deferred)) {
			t.Fatalf("help advertises deferred command %q", deferred)
		}
	}
}
```

- [ ] **步骤 7：运行测试、构建并提交**

```bash
gofmt -w cmd/themico internal/themico/cli
```

```bash
go test ./internal/themico/cli -count=1
```

```bash
go build ./...
```

```bash
git add cmd/themico internal/themico/cli
```

```bash
git commit -m "feat: expose core Themico CLI commands"
```

---

### 任务 10：实现单一 `themico` Skill 与必要 references

**文件：**
- 新建：`templates/.claude/skills/themico/SKILL.md`
- 新建：`templates/.themico/core/references/common/operation-contract.md`
- 新建：`templates/.themico/core/references/common/result-contract.md`
- 新建：`templates/.themico/core/references/common/governance.md`
- 新建：`templates/.themico/core/references/common/knowledge-record.md`
- 新建：`templates/.themico/core/references/common/l1-discovery.md`
- 新建：`templates/.themico/core/references/common/type-registry.md`
- 新建：`templates/.themico/core/references/operations/query.md`
- 新建：`templates/.themico/core/references/operations/inspect.md`
- 新建：`templates/.themico/core/references/operations/create-candidate.md`
- 新建：`templates/.themico/core/references/operations/revise-candidate.md`
- 新建：`templates/.themico/core/references/operations/confirm-type.md`
- 新建：`templates/.themico/core/references/operations/validate.md`
- 新建：`templates/.themico/core/references/operations/prepare.md`
- 新建：`templates/.themico/core/references/operations/publish.md`
- 新建：`templates/.themico/core/references/types/design-decision/{factory,l2,l3,semantic-check}.md`
- 新建：`templates/.themico/core/references/types/development-standard/{factory,l2,l3,semantic-check}.md`
- 新建：`templates/.themico/core/references/types/development-experience/{factory,l2,l3,semantic-check}.md`
- 新建：`internal/themico/integration/skill_contract_test.go`

**接口：**
- 产出：唯一公共 `themico` Skill；一次 Invocation 只加载一个 operation reference 和 registry 选中的一个 type factory。

- [ ] **步骤 1：写 Skill tree contract 测试**

```go
func TestSkillTreeMatchesFirstUsableDeliveryContract(t *testing.T) {
	repository := repositoryRoot(t)
	skill := filepath.Join(repository, "templates", ".claude", "skills", "themico", "SKILL.md")
	references := filepath.Join(repository, "templates", ".themico", "core", "references")

	if entries, err := os.ReadDir(filepath.Dir(skill)); err != nil || len(entries) != 1 {
		t.Fatalf("skill directory must hold only SKILL.md: %v %v", entries, err)
	}

	operations := []string{
		"create-candidate", "revise-candidate", "confirm-type", "validate",
		"prepare", "publish", "query", "inspect",
	}
	got := markdownNames(t, filepath.Join(references, "operations"))
	if !reflect.DeepEqual(got, sorted(operations)) {
		t.Fatalf("operations=%v want %v", got, sorted(operations))
	}

	commons := []string{
		"operation-contract", "result-contract", "governance",
		"knowledge-record", "l1-discovery", "type-registry",
	}
	if got := markdownNames(t, filepath.Join(references, "common")); !reflect.DeepEqual(got, sorted(commons)) {
		t.Fatalf("common=%v want %v", got, sorted(commons))
	}

	for _, factory := range []string{"design-decision", "development-standard", "development-experience"} {
		directory := filepath.Join(references, "types", factory)
		want := sorted([]string{"factory", "l2", "l3", "semantic-check"})
		if got := markdownNames(t, directory); !reflect.DeepEqual(got, want) {
			t.Fatalf("%s=%v want %v", factory, got, want)
		}
	}

	assertOnlySkillHasFrontmatter(t, skill, references)
	assertNoDeferredOperationReference(t, references)
}
```

`assertNoDeferredOperationReference` 断言 `operations/` 下不存在 `supersede`、`deprecate`、`archive`、`rebuild`、`verify-projection`、`create-derived-candidate`。

- [ ] **步骤 2：运行测试确认失败**

Run: `go test ./internal/themico/integration -run TestSkillTree -v`
Expected: FAIL，Skill 目录尚不存在。

- [ ] **步骤 3：写公共 Skill 入口**

`SKILL.md` 只保留宿主发现所需的最小 frontmatter：

```markdown
---
name: themico
description: 查询与渐进读取 Themico 正式项目知识，形成和审阅知识候选，并通过 themico CLI 准备与执行经授权的治理发布。
---

# themico

## 职责

本 Skill 是 Themico 的唯一公共入口，只负责路由与解释。语义合同位于 `.themico/core/references/`，机器权威由 `themico` Go CLI 承担。
```

正文固定两条加载路径：

```text
已有正式记录或已有 candidate：
common/operation-contract
→ 唯一选中的 operation reference
→ CLI inspect/query 返回的 persisted knowledge_type
→ common/type-registry 的 identity routing table
→ 唯一选中的 type factory
→ 该 factory 的 L2/L3/semantic-check reference

尚无 proposed_type 的 create-candidate：
common/operation-contract
→ create-candidate reference
→ common/type-registry 的 lightweight classification registry
→ Agent 提出唯一 proposed_type 与分类依据
→ common/type-registry 的 identity routing table
→ 唯一选中的 type factory
→ 该 factory 的 L2/L3 reference
```

明确写出：已有记录的类型只能来自 CLI；不得根据标题、摘要或正文重新猜测类型；CLI 或所需 reference 不可用时只能产出 draft 并报告 unavailable，不得手工修改 `.themico/workspace/`，也不得声称结果已 published、current 或 valid。

- [ ] **步骤 4：写 common references**

`type-registry.md` 必须同时提供两张表且都不复制 factory 详细内容：

| `knowledge_type` | 分类问题 | 排除提示 |
| --- | --- | --- |
| `design_decision` | 材料是否主要回答"项目已决定什么以及为什么" | 若主要规定必须/禁止动作或复用观察经验，则不选 |
| `development_standard` | 材料是否主要回答"触发后必须、禁止或验证什么" | 若只是一次设计取舍或条件化观察，则不选 |
| `development_experience` | 材料是否主要回答"在何种背景下观察到什么、证据多强、建议如何行动" | 若内容是 current 设计决定或强制规则，则不选 |

| `knowledge_type` | factory | Zone |
| --- | --- | --- |
| `design_decision` | `types/design-decision/factory.md` | `project_knowledge` |
| `development_standard` | `types/development-standard/factory.md` | `project_knowledge` |
| `development_experience` | `types/development-experience/factory.md` | `project_experience` |

`result-contract.md` 列出 envelope 字段与闭集 status；`governance.md` 说明类型确认与 publication Approval 是两个独立 Human gate；`l1-discovery.md` 说明 L1 只用于发现与确定性筛选，升级读取需 exact record ID。

- [ ] **步骤 5：写八个 operation references**

每个 operation reference 固定包含：输入与前置条件、Agent 职责、对应 `themico` CLI command、Human gate、权威输出、合法 machine statuses、fail-closed 行为。不复制三种类型的完整 L2/L3 合同，不定义新的 Zone、类型、状态或关系。

- [ ] **步骤 6：写三个 type factory**

每个 factory 固定说明 type identity、唯一 Zone、适用与不适用分类依据，以及 L2/L3/semantic-check reference 路径。`l3.md` 中的固定 H2 章节必须与 `internal/themico/model/registry.go` 的 `L3Headings` 逐字一致。semantic-check 只产生 assessment candidate，不授予 publication authority。

- [ ] **步骤 7：写 L3 章节一致性测试**

```go
func TestFactoryL3ReferencesMatchRegistryHeadings(t *testing.T) {
	references := filepath.Join(repositoryRoot(t), "templates", ".themico", "core", "references", "types")
	for _, factory := range model.Factories() {
		directory := map[model.KnowledgeType]string{
			model.TypeDesignDecision:        "design-decision",
			model.TypeDevelopmentStandard:   "development-standard",
			model.TypeDevelopmentExperience: "development-experience",
		}[factory.Type]

		content, err := os.ReadFile(filepath.Join(references, directory, "l3.md"))
		if err != nil {
			t.Fatal(err)
		}
		for _, heading := range factory.L3Headings {
			if !bytes.Contains(content, []byte("## "+heading)) {
				t.Fatalf("%s l3.md is missing heading %q", directory, heading)
			}
		}
	}
}
```

- [ ] **步骤 8：运行测试并提交**

```bash
gofmt -w internal/themico/integration
```

```bash
go test ./internal/themico/integration -count=1
```

```bash
git add templates/.claude/skills/themico templates/.themico/core internal/themico/integration
```

```bash
git commit -m "feat: add Themico knowledge Skill"
```

---

### 任务 11：补齐端到端、并发、中断与安全测试

**文件：**
- 新建：`internal/themico/integration/lifecycle_test.go`
- 新建：`internal/themico/integration/query_test.go`
- 新建：`internal/themico/integration/interruption_test.go`
- 新建：`internal/themico/integration/security_test.go`

**接口：**
- 消费：`cli.Run(ctx, args, stdout, stderr) int`。
- 产出：从 CLI 请求到 generation commit 与读取的可重复证据。测试只通过 `cli.Run` 驱动，不直接调用内部 service，以证明命令面真实可用。

- [ ] **步骤 1：实现三类型完整 happy path**

```go
func TestPublishAndReadEachKnowledgeType(t *testing.T) {
	for _, knowledgeType := range []model.KnowledgeType{
		model.TypeDesignDecision,
		model.TypeDevelopmentStandard,
		model.TypeDevelopmentExperience,
	} {
		t.Run(string(knowledgeType), func(t *testing.T) {
			repository := t.TempDir()
			mustRunCLI(t, result.StatusSucceeded, "init", "--root", repository)

			candidateID, candidateRevision := createCandidate(t, repository, knowledgeType)
			confirmedRevision := confirmType(t, repository, candidateID, candidateRevision, knowledgeType)
			mustRunCLI(t, result.StatusSucceeded, "validate", "--root", repository,
				"--candidate", candidateID, "--revision", confirmedRevision)

			prepareID := preparePublish(t, repository, candidateID, confirmedRevision)
			recordID := publish(t, repository, prepareID)

			l1 := queryL1(t, repository, zoneFor(knowledgeType))
			if !containsRecord(l1, recordID) {
				t.Fatalf("query did not return %s", recordID)
			}
			for depth := 1; depth <= 3; depth++ {
				inspectRecord(t, repository, recordID, depth)
			}
		})
	}
}
```

- [ ] **步骤 2：实现类型改型拒绝测试**

确认类型后调用 `candidate revise` 并改变 `proposed_type`，断言返回 `validation_failed` 且 candidate pointer 的 `knowledge_type` 不变。

- [ ] **步骤 3：实现并发 generation conflict 测试**

```go
func TestConcurrentPublishLetsExactlyOneWinWithoutOverwriting(t *testing.T) {
	repository := t.TempDir()
	mustRunCLI(t, result.StatusSucceeded, "init", "--root", repository)
	firstPrepare := prepareReadyCandidate(t, repository)
	secondPrepare := prepareReadyCandidate(t, repository)

	statuses := make(chan result.Status, 2)
	start := make(chan struct{})
	var waiter sync.WaitGroup
	for _, prepareID := range []string{firstPrepare, secondPrepare} {
		waiter.Add(1)
		go func(id string) {
			defer waiter.Done()
			<-start
			statuses <- runCLIStatus(t, "publish", "--root", repository, "--prepare", id, "--approval", approvalFile(t, repository, id))
		}(prepareID)
	}
	close(start)
	waiter.Wait()
	close(statuses)

	var succeeded, conflicted int
	for status := range statuses {
		switch status {
		case result.StatusSucceeded:
			succeeded++
		case result.StatusConflict:
			conflicted++
		default:
			t.Fatalf("unexpected status %s", status)
		}
	}
	if succeeded != 1 || conflicted != 1 {
		t.Fatalf("succeeded=%d conflicted=%d want exactly one each", succeeded, conflicted)
	}
}
```

两个 prepare 必须基于同一 expected generation 创建，因此第二个 publish 只能返回 `conflict`。

- [ ] **步骤 4：实现中断测试**

分别在 payload 写入后、generation staging 写入后、rename 前注入故障，断言 current generation、query 结果和 record pointer 均不变，且 orphan payload 不被任何读取路径返回。

- [ ] **步骤 5：实现路径与输入安全测试**

覆盖：绝对路径 source、`..` 逃逸、symlink/junction 逃逸、超限 JSON、unknown field、duplicate key、invalid UTF-8、L3 frontmatter、source digest 漂移、byte budget 精确边界。

当前平台无法创建 junction 或 symlink 时必须 `t.Skip` 并在证据中记录 unavailable，不得伪造 PASS：

```go
if err := os.Symlink(target, link); err != nil {
	t.Skipf("symlink creation unavailable on this platform: %v", err)
}
```

- [ ] **步骤 6：实现 `init` 布局与控制面测试**

断言 `init` 产生 `.themico/core/` 与 `.themico/workspace/`；store payload 全部落在 `workspace/` 内；先安装 control plane 再 `init` 仍成功且 reference bytes 不变；重复 `init` 返回 `precondition_failed`。

- [ ] **步骤 7：运行全量测试并提交**

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
git commit -m "test: verify Themico first usable delivery"
```

---

### 任务 12：对齐产品说明并生成验收证据

**文件：**
- 修改：`README.md`
- 新建：`docs/plan/themico-core/implementation-evidence.md`
- 新建：`docs/plan/themico-core/manual-replay.md`

**接口：**
- 产出：只陈述实际实现能力的产品说明、fresh 命令证据、人工 replay 记录和逐条验收映射。

- [ ] **步骤 1：更新 README**

新增 Themico 说明，链接 `docs/superpowers/specs/2026-07-29-themico-design.md`、`docs/superpowers/specs/2026-07-29-themico-design/first-usable-delivery.md`、`templates/.claude/skills/themico/SKILL.md` 和 CLI 构建入口。明确列出当前 unavailable：supersede、deprecate、archive、history query、跨类型派生、relation traversal、聚合 view 与 `rebuild`、URL source、MCP adapter、Themis lifecycle 接线、Embedding/向量数据库/SQLite、token budget。

不得把计划或设计描述成已实现能力。

- [ ] **步骤 2：运行并记录 fresh verification**

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

把完整命令、exit code、测试数量、skip 数量、平台和执行时间写入 `implementation-evidence.md`。未运行或 skip 的保证标记 unavailable，不得推断为通过。

- [ ] **步骤 3：执行九个人工 replay**

使用构建出的 `themico` 二进制在临时仓库依次 replay，并记录实际输入、command、result status、generation before/after 和 observed files：

```text
1. design_decision 完整发布与 L1/L2/L3 读取
2. development_standard 完整发布与 L1/L2/L3 读取
3. development_experience 完整发布与 L1/L2/L3 读取
4. 类型确认后 revise 改型被拒绝
5. source drift 阻止 validate、prepare 或 publish
6. 错误或 stale Approval 阻止 publish
7. 并发 generation conflict 不覆盖获胜 generation
8. 投影或 content 篡改导致 query/inspect 失败关闭
9. byte budget 不足返回 budget_exceeded 且不截断 L3
```

- [ ] **步骤 4：逐条映射独立验收集合**

在 `implementation-evidence.md` 为 `first-usable-delivery.md` 第 8 节的 21 条验收条件各给出唯一的代码、测试或 replay 引用。找不到 fresh evidence 的条目保持 GAP，不得用计划文本或设计文档代替证据。

同时声明：本证据只覆盖首个可用交付，不构成 `acceptance.md` 完整 38 条目标的完成判定。

- [ ] **步骤 5：审查提交范围**

```bash
git status --short
```

```bash
git diff --stat
```

确认没有 `.themico` 测试数据、编译产物、Python、产品 YAML、MCP adapter、Themis lifecycle 改动或第三方依赖进入提交。

- [ ] **步骤 6：提交文档与证据**

```bash
git add README.md docs/plan/themico-core
```

```bash
git commit -m "docs: record Themico first usable delivery evidence"
```

---

## 完成判定

首个可用交付的完成判定以 `docs/superpowers/specs/2026-07-29-themico-design/first-usable-delivery.md` 第 8 节的 21 条独立验收集合为准。只有全部条件具备 fresh evidence 且 acceptance mapping 无未裁决 GAP 时，才能报告"首个可用交付完成"。

该判定不表示 `acceptance.md` 完整 38 条 Themico 设计目标已经满足，也不构成用户接受，更不授权 push、PR、MCP 集成或 Themis lifecycle 接线。

---

## 计划自检清单

- Spec coverage：任务 1–5（已完成）提供 Spec authority、CLI 进程合同、知识模型与 registry、canonical JSON 与 generation store、candidate 生命周期；任务 6 实现确定性 validate；任务 7 实现 assessment/prepare/Approval/publish；任务 8 实现 query 与 inspect；任务 9 接通核心 command surface；任务 10 实现单一 Skill 与八个 operation references；任务 11 提供 E2E、并发、中断与安全证据；任务 12 提供产品说明、人工 replay 与逐条验收映射。
- Authority separation：Agent proposal、Human 类型确认与 publication Approval、CLI machine authority 在 model、validate、governance、Skill 与测试中分别落实；CLI 只比较 identity 字段，不声称验证真实身份。
- Atomic record：candidate/record revision、L1/L2/L3、relations、source 与 generation commit 均以单条 Record 为治理单位；publish 在一次 generation commit 中同时更新 record pointer、projection ref 与 candidate published binding。
- Progressive read：L1 query、exact-ID L2/L3 inspect 与 byte budget 各有独立实现与测试；预算不足返回 `budget_exceeded` 且不截断完整 item。
- Projection boundary：L1/L2 绑定确切 record revision 与 L3 digest；绑定失效时读取失败关闭，不从 L3 生成摘要；`views.json` 固定为 canonical 空对象，不被任何任务声称为聚合索引。
- Type consistency：`model.Factory.L3Headings`、Skill `l3.md` 章节、validate 的 `checkMarkdown` 与三个 typed L2 payload 在 Spec、Go model、CLI、Skill 与测试中逐字一致（任务 10 步骤 7 以测试锁定）。
- Scope control：supersede/deprecate/archive、history query、跨类型派生、relation traversal、聚合 view 与 `rebuild`、Claude API、MCP、Themis lifecycle 接线、Embedding、SQLite、向量数据库、Web UI、token budget 均未实现，也不以空 command、占位 handler 或未接线 reference 出现。
- Repository constraints：无 Python、无 Shell fallback、无产品 YAML、无第三方 Go dependency、无功能版本或版本目录。
