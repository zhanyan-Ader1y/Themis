# P2 实施设计 — Top-level Guidance

**关联计划**：[P2 — Top-level Guidance](README.md)
**状态**：已实施；Claude Code 运行时 import 探针待认证环境复核
**实施边界**：建立可被 Claude Code 加载的 Themis 顶层入口与基线 always-on 路由规则；不实现状态机、Shell 执行器、领域工作流、Commands、Skills、Agents、Init 合并或任何项目专有内容。

## 1. 诊断结论

当前 `CLAUDE.themis.md` 及其规则树过于简单，原因同时包含**计划内延后**和**计划归属缺口**。

### 1.1 计划内延后

P1 明确只创建最小、真实、可自检的 import 入口，并明确排除 Kernel 业务规则。因此当前八个 `rules.md` 只声明模块职责、Core/Workspace 边界和后续计划归属，是 P1 的预期结果，不是 P1 漏做。

后续计划已经拥有以下详细能力：

| 内容 | 计划所有者 |
|---|---|
| Requirement Questioning、一次一问、复杂度自适应、Spec 自检、`Draft → Specified` 硬门禁 | P5 |
| Behavior Map、Facts-First、Freshness、AC → Code 定位 | P6 |
| 领域 Agent、上下文隔离、Commands、Skills、确定性 Shell 执行器、`flow.yaml` 与 Agent 映射 | P8 |

P2 不应提前复制这些规则，否则后续计划会产生两份规范和升级冲突。

### 1.2 计划归属缺口

P2 原计划要求提供生命周期路由，但又把“模块具体控制逻辑”全部排除；P5/P6/P8 只拥有各自的领域增强或执行层。这使下列**基线 Orchestrator 语义**无人负责：

- 识别请求是否属于 Themis 管理的项目变更；
- 从现有 Workspace 工件判断当前可执行阶段；
- 在专用 Commands、Skills、Agents 和 Shell 尚未安装时提供安全退化路由；
- 缺少前置工件时停止后续阶段，而不是猜测或绕过；
- 区分提示性规则与未来确定性执行器的权威性；
- 阻止直接修改 Core、伪造 Gate 结果、仅凭对话记忆宣称阶段完成。

P2 接管这组**基线 always-on 路由与防绕过边界**。这不是完整状态机实现：P2 只告诉 Agent 应读取什么、何时停止、路由到哪个领域和什么不能声称；阶段迁移、证据检查和 Gate 执行仍由 P5/P8 的策略与确定性工具实现。

## 2. Lattice 对比与 Themis 适配

Lattice 的 `harness-template/CLAUDE.lattice.md` 也只有一行：

```text
@import lattice/kernel/orchestrator/rules.md
```

它之所以有效，不是因为单行入口本身包含能力，而是导入的 `rules.md` 已经包含完整的 Operating Rule、阶段路由、Source of Truth、Specification、Planning、Implementation、Review、Verification、Knowledge Capture、Review Contract 和 Artifact Layout，并直接引用 `guide.sh`、`spec-status.sh`、`task-next.sh`、`task-complete.sh`、pipeline 等确定性工具。同目录的 `flow.yaml` 和 Shell 脚本为提示规则提供可执行契约。

Themis 当前则是“一行顶层入口 + P1 最小规则”，所以只有结构连通性，没有可工作的 always-on SDD 路由。P2 的适配原则是：

1. 保留短顶层入口，不把完整 WIKI 塞入 `CLAUDE.themis.md`；
2. 将跨阶段、始终生效的最小路由放入 Orchestrator；
3. 将领域规则留在各领域 `rules.md`，并由后续计划逐步增强；
4. 在 P8 工具落地前明确规则只能保守路由，不能伪装成确定性状态机；
5. P8 落地后由 Shell/配置成为状态、任务与 Gate 的机器权威，规则只负责调用和解释结果。

## 3. Claude Code 加载约束与验证状态

### 3.1 当前可依赖的静态约束

P2 继续采用 P1 已实现并验证的静态契约：

- 顶层入口使用独立一行 `@import .themis/core/kernel/orchestrator/rules.md`；
- Core 内部 import 相对当前规则文件解析；
- 每个目标必须存在；
- Core 内部 import 规范化后不得逃出 `.themis/core/`；
- import 图保持无环且深度有限；P2 只使用“顶层 → Orchestrator → 领域规则”两级图；
- `bin/themis-template-check.sh` 负责源模板的路径、存在性和 Core 边界自检。

### 3.2 必须在实施阶段完成的 Claude Code 实测

本次设计尝试使用本机 Claude Code 2.1.200 在一次性目录验证直接 import、嵌套相对 import 和独立 `CLAUDE.themis.md` 自动加载。CLI 在加载探针前因未登录而失败，结果为 `Not logged in`，因此这些行为**尚不能记录为已运行验证**。

P2 实施阶段必须在已认证 Claude Code 环境执行隔离探针并记录版本与结果：

1. `CLAUDE.md` 直接 import 子文件，探针规则可被模型复述；
2. 被 import 文件再使用相对路径 import 第二层文件；
3. import 循环或缺失目标不会静默产生部分可信规则；
4. 只有 `CLAUDE.themis.md`、没有被识别入口引用时，验证其是否会自动加载；设计默认按**不会自动加载**处理，P3 必须建立显式入口；
5. import 放在代码块内时不应作为有效入口；
6. 在已有 `AGENTS.md` 的目标仓库中，验证 Claude Code 是否原生读取它；未获得实测或官方保证前，Themis 不依赖 `AGENTS.md` 来加载自身。

如果 1 或 2 失败，P2 不得落地链式 import，必须改为由受识别的项目 `CLAUDE.md` 直接 import 所需文件，或采用单文件展开。若 4 显示独立文件不自动加载，则确认 P3 的显式合并/引用是安装成功条件。

## 4. 责任分层

| 层 | P2 内容 | 明确不包含 |
|---|---|---|
| 项目 `CLAUDE.md` 集成块 | 一个稳定、可逆、可去重的 Themis import | 复制完整规则；P2 不修改真实项目 |
| `CLAUDE.themis.md` | 安装说明、入口身份、Core/Workspace 边界、Source of Truth 摘要、单一 Orchestrator import | 领域工作流细节、Shell 调用清单 |
| `orchestrator/rules.md` | always-on 识别、工件优先、阶段前置检查、领域路由、安全退化、禁止绕过、权威层级 | 执行状态迁移、解析 Plan、运行 Gate |
| 领域 `rules.md` | 每个模块的稳定职责、读写边界、最小输入/输出与不可越界行为 | P5/P6/P8 尚未设计的具体流程 |
| Skills / Commands | 后续显式工作流入口 | P2 不创建；P8 负责 |
| Agents | 后续领域上下文隔离 | P2 不创建；P8 负责 |
| Shell / `flow.yaml` | 后续机器可验证的状态、任务、证据和 Gate 操作 | P2 不创建；P8 负责 |

权威顺序定义为：

```text
当前代码、配置、结构化工件和命令输出
  > Workspace 中的持久状态与证据
  > Core policy / protocol / deterministic tool result
  > imported rules
  > 对话记忆或 Agent 推断
```

规则不得用低层级信息覆盖高层级事实。

## 5. 目标 import 图

```text
项目 CLAUDE.md（P3 根据用户选择建立显式入口）
  └── @import CLAUDE.themis.md
        └── @import .themis/core/kernel/orchestrator/rules.md
              ├── @import ../specification/rules.md
              ├── @import ../planning/rules.md
              ├── @import ../context/rules.md
              ├── @import ../verification/rules.md
              ├── @import ../review/rules.md
              └── @import ../knowledge/rules.md

attribution/rules.md
  └── 保持按需入口，不进入基线图；直到后续计划定义触发点。
```

P2 设计选择让项目 `CLAUDE.md` 引用 `CLAUDE.themis.md`，而不是直接跳过它引用 Orchestrator。这样独立文件可承载安装边界和版本无关的入口说明，同时 Core 路径仍由 Themis 升级管理。若 Claude Code 实测表明该两级链无法可靠加载，则回退为项目 `CLAUDE.md` 直接 import Orchestrator，并把 `CLAUDE.themis.md` 作为 P3 的可合并标记块来源。

## 6. 基线 Orchestrator 规则结构

P2 将 `orchestrator/rules.md` 从 P1 占位符扩展为以下结构，但不加入尚未实现的命令：

1. **Operating Contract**
   - Themis 管理 SDD 路由，不拥有项目内容；
   - Core 默认只读，Workspace 保存项目工件；
   - 从工件和实际命令输出工作，不从对话记忆推断完成状态。

2. **Managed Change Detection**
   - 新增/修改行为、修复缺陷、改变接口/配置/迁移/验证要求属于 SDD 变更；
   - 纯问答、只读调查和用户明确要求的非实现研究不伪造 Spec；
   - 边界不清时停在 Specification 路由，不直接实现。

3. **Artifact-first Routing**
   - 无 Spec：路由 Specification；
   - Spec 未批准或有开放问题：保持 Specification；
   - 有批准 Spec、无 Plan：路由 Planning；
   - 有 Plan、任务未完成：路由 Implementation；
   - 实现证据不足：不得进入 Review/Verification；
   - Review/Verification 只读取实际工件和命令证据；
   - P2 不直接改变任何生命周期状态。

4. **Safe Degradation Before P5/P8**
   - 如果专用 Skill、Command、Agent 或确定性脚本不存在，说明缺失能力并停在当前阶段；
   - 不用手写状态文件、伪造脚本结果或把自然语言判断当作 Gate；
   - 可以创建经用户批准的领域工件草案，但不能声称机器门禁已通过。

5. **Non-bypass Rules**
   - 不因“改动很小”跳过已有 Spec/Plan 前置条件；
   - 不直接修改 `.themis/core/` 来适配单个项目；
   - 不把缺失证据视为通过；
   - 不将 Review 和 Verification 合并为同一结论；
   - 需求超出已批准范围时回到 Specification/Planning，而非静默扩展。

6. **Domain Routing**
   - 只定义每个领域何时接管及预期工件；
   - 具体追问、行为地图、Agent 隔离与 Shell 命令分别留给 P5、P6、P8。

## 7. 顶层正文与篇幅预算

`CLAUDE.themis.md` 保持精简，目标为 40–80 行、建议不超过 120 行；Orchestrator 基线目标为 100–180 行、建议不超过 220 行；P2 修改后的每个领域规则目标为 15–40 行。

顶层正文大纲：

1. Themis 身份和适用范围；
2. Source Template 与 Installed Instance 区分；
3. Core/Workspace 所有权与 Upgrade 不覆盖 Workspace；
4. 工件优先和禁止从对话记忆推断；
5. SDD 阶段速查；
6. 关键路径速查；
7. Orchestrator import。

篇幅是设计预算，不作为单纯行数门禁；验收重点是无 WIKI 复制、无项目专有内容和无未实现能力声明。

## 8. 安装与合并场景

P2 只定义契约，P3 实现操作。

### 8.1 独立文件

- 始终安装项目根 `CLAUDE.themis.md`；
- 文件由 Themis 管理，可随 Core 兼容升级；
- 独立文件本身不被视为已加载，必须由受识别的项目入口显式 import。

### 8.2 显式合并到已有 `CLAUDE.md`

仅在用户选择合并时加入：

```md
<!-- themis:guidance:start -->
@import CLAUDE.themis.md
<!-- themis:guidance:end -->
```

约束：

- 标记全局唯一；
- 已存在完整标记块时幂等，不重复插入；
- 只有单边标记或多个块时拒绝自动修复并给出诊断；
- 卸载或回滚只删除标记之间的 Themis 块，不重写用户其余内容；
- 不把 Core 的长路径直接复制到多个位置，避免升级漂移。

### 8.3 没有 `CLAUDE.md`

P3 可在用户确认后创建最小 `CLAUDE.md`，内容只包含上述标记块；原子写入并保留可回滚路径。

### 8.4 已有 `AGENTS.md`

- P2/P3 不修改 `AGENTS.md`；
- 安装时报告其存在及仓库声明的优先级；
- 在 Claude Code 原生加载行为未经实测保证前，Themis 仍通过 `CLAUDE.md` 显式加载；
- 如果 `AGENTS.md` 与 Themis 规则冲突，停止并要求项目维护者决定，不自动覆盖任一方。

## 9. 目标文件与边界

P2 获批后允许修改：

- `templates/CLAUDE.themis.md`；
- `templates/.themis/core/kernel/orchestrator/rules.md`；
- 七个领域 `rules.md`，仅补充稳定边界与最小输入/输出；
- `bin/themis-template-check.sh` 与 `tests/template-contract/test.sh`，仅扩展 P2 import/内容结构的静态自检；
- P2 专用测试目录（精确位置在实施时沿用现有 `tests/` 约定）；
- `docs/plan/20-top-level-guidance/impl.md` 实施结果；
- `CHANGES.md`，仅在全部验证完成后更新。

P2 不修改或创建：

- P3 Init 安装/合并脚本；
- P5 追问策略、Spec 模板或 transitions policy；
- P6 Behavior Map Schema、Adapter 或 Context policy；
- P8 Commands、Skills、Agents、`flow.yaml` 或确定性 Shell 工具；
- 任何已安装项目的 `CLAUDE.md`、`AGENTS.md` 或 Workspace。

## 10. 实施任务

1. 在可认证的 Claude Code 环境完成隔离 import 探针，记录版本、命令、预期和结果；若链式加载不可靠，先按第 5 节回退策略修正图。
2. 扩展 `CLAUDE.themis.md`，只承载顶层所有权、Source of Truth、生命周期速查和唯一 Orchestrator 入口。
3. 扩展 Orchestrator 为可用的基线 always-on 路由与安全退化规则。
4. 为领域规则补齐稳定职责、最小输入/输出和不可越界行为；不实现 P5/P6/P8 流程。
5. 扩展模板检查和隔离测试，验证 import 图、唯一入口、禁止未实现命令声明、Core/Workspace 边界和合并标记契约。
6. 运行全部 P0/P1/P2 回归，记录实际结果并在完成后更新 `CHANGES.md`。

## 11. 验证矩阵

| 类别 | 检查 | 预期 |
|---|---|---|
| Claude Code 直接加载 | 认证环境中的一次性 `CLAUDE.md` import 探针 | 直接目标规则生效 |
| 嵌套加载 | Orchestrator 相对 import 领域规则 | 第二层规则生效，解析基准明确 |
| 独立文件 | 只有 `CLAUDE.themis.md` 的探针 | 记录实际行为；无论结果如何，安装契约使用显式入口 |
| 错误图 | 缺失目标、循环或越界夹具 | 明确失败，不将部分规则视为完整加载 |
| 静态契约 | `bash bin/themis-template-check.sh` | 成功且无输出 |
| 规则边界 | 搜索 P5/P6/P8 专属术语与未实现命令 | P2 不宣称这些能力已实现 |
| 责任完整性 | 检查六阶段路由与缺失工件行为 | 每个阶段有入口、停止条件和预期工件 |
| 合并契约 | 标记块的无/单/重复/破损夹具 | 可创建、幂等、冲突拒绝、可逆 |
| Shell 质量 | `bash -n`、ShellCheck（若脚本有修改） | 无语法错误、无 findings |
| 回归 | P0 31 项、P1 22 项及新增 P2 测试 | 全部通过 |
| 补丁卫生 | `git diff --check` 与目标文件审计 | 通过且不越出 P2 边界 |

## 12. 风险与回滚

- **提示词膨胀**：顶层只保留跨阶段常量，领域细节下沉，执行细节由按需 Skill/Agent 加载。
- **P2 提前占用 P5/P6/P8**：P2 只写路由和停止条件，不写领域算法、Agent prompt 或 Shell 命令契约。
- **规则冒充状态机**：没有确定性工具结果时，只能保守判断“前置工件存在/不存在”，不得写迁移状态或宣称 Gate 通过。
- **import 行为版本漂移**：记录 Claude Code 版本并保留静态图检查；P3 安装使用显式入口，不依赖任意文件名自动发现。
- **与项目规则冲突**：不改 `AGENTS.md`，合并块可逆；发现冲突时停止而非覆盖。
- **回滚**：恢复 P1 的最小 `CLAUDE.themis.md` 和八个规则入口，删除 P2 专用测试；不涉及 Workspace 数据迁移。

## 13. 实施结果

已落地：

- `templates/CLAUDE.themis.md`：从单行占位入口扩展为 58 行项目级指引，包含安装边界、Source of Truth、默认生命周期路由、关键 Workspace 路径以及唯一 Orchestrator import。
- `templates/.themis/core/kernel/orchestrator/rules.md`：新增 Operating Contract、Authority Order、Managed Change Detection、Artifact-First Routing、Safe Degradation、Non-Bypass Rules 和 Domain Boundaries；保持 6 条领域 import，不导入 Attribution。
- 七个领域规则：Specification、Planning、Context、Verification、Review、Attribution、Knowledge 均补齐 Responsibility、Inputs、Outputs 和 Boundaries；每个文件 24–25 行，未实现 P5/P6/P8 所属流程。
- `bin/themis-template-check.sh`：新增 P2 Markdown 锚点、篇幅上限和 import 数量验证。顶层必须恰好 1 条 import，Orchestrator 必须恰好 6 条；顶层不超过 120 行、Orchestrator 不超过 220 行、领域规则不超过 50 行。
- `tests/template-contract/test.sh`：从 22 项扩展到 32 项，新增重复 import、缺失安装边界、缺失 Artifact-First Routing、缺失领域 Boundaries 等隔离夹具。
- `docs/plan/20-top-level-guidance/README.md` 与计划索引：P2 标记为已完成，并显式保留认证环境中的 Claude Code 运行时 import 复核项。

验证结果：

- `bash -n bin/_themis-init-env.sh bin/themis-template-check.sh tests/init-environment/test.sh tests/template-contract/test.sh` 通过。
- ShellCheck 0.11.0 对上述四个 Bash 文件无 findings；当前 Git Bash PATH 未包含 ShellCheck，验证使用 winget 安装目录中的绝对可执行路径。
- `bash tests/init-environment/test.sh`：P0 的 31 项测试全部通过。
- `bash tests/template-contract/test.sh`：P1/P2 的 32 项测试全部通过。
- `bash bin/themis-template-check.sh`：源模板成功且无输出。
- 规则搜索确认顶层恰好 1 条 import、Orchestrator 恰好 6 条 import；所有规则未引用尚不存在的 `themis-*.sh`、`/themis-*`、`flow.yaml`、`agents.yaml` 或 `SKILL.md`。
- 实际篇幅为：顶层 58 行、Orchestrator 99 行、各领域 24–25 行，均在设计预算内。
- `git diff --check` 通过；仅报告现有 Windows 工作区的 LF/CRLF 转换警告，无 whitespace error。

未完成的环境验证：

- 本机 Claude Code 版本为 2.1.200，但 `claude auth status` 返回 `loggedIn: false`。直接、嵌套、独立文件和错误图的运行时模型探针均无法越过认证，因此未宣称 Claude Code 运行时 import 行为已经实测通过。
## 14. P3 集成布局修订（2026-07-24）

P3 实施前，用户将安装布局修订为最小化工程根目录改动的直接入口契约。以下内容取代第 5 节与第 8 节中关于项目根 `CLAUDE.themis.md`、可选合并与该文件二级 import 的**当前安装设计**；第 13 节保留的内容仅是当时 P2 的历史实施记录。

```text
项目 CLAUDE.md（Init 在文件末尾写入唯一标记块）
  ├── @import .themis/CLAUDE.themis.md
  └── @import .themis/core/kernel/orchestrator/rules.md
        ├── @import ../specification/rules.md
        ├── @import ../planning/rules.md
        ├── @import ../context/rules.md
        ├── @import ../verification/rules.md
        ├── @import ../review/rules.md
        └── @import ../knowledge/rules.md
```

- `CLAUDE.themis.md` 移至 `.themis/` 并成为 Themis 管理内容；它只承载顶层边界、Source of Truth 和生命周期速查，不再 import Orchestrator。
- Init 总是创建或在项目 `CLAUDE.md` 末尾追加全局唯一、可逆的两条直接 import 标记块；不创建项目根 `CLAUDE.themis.md`，也不提供可选合并开关。
- P4 Upgrade 替换 `.themis/` 中除 `workspace/` 外的内容，因此会更新 `.themis/CLAUDE.themis.md`；它不重写项目 `CLAUDE.md`，因为直接 import 路径稳定。
- 静态检查器验证被包含的 `.themis/CLAUDE.themis.md` 无 import，且 Orchestrator 保持六条 Core 内部 import。运行时 import 探针仍待认证 Claude Code 环境完成。
