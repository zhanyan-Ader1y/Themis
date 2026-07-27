# P8 — Multi-Agent Architecture（领域专用 Agent 体系）

**优先级**：P8
**依赖**：[P7 Integration Audit](../70-integration-audit/README.md)、[P1 Template Contract](../10-template-contract/README.md)、[P5 Requirement Questioning](../50-requirement-questioning/README.md)
**状态**：待用户主动发起

## 背景

当前 Themis 设计以模块划分能力边界，但未定义**执行层的 Agent 拆分**。如果所有 SDD 阶段共用一个 Agent（god agent），会导致：

- **上下文过长**：全部 rules.md、全部 context、全部 spec/plan/evidence 塞入单一上下文窗口
- **语义模糊**：Specification 的追问规则与 Implementation 的 TDD 规则混合，Agent 难以区分优先级
- **无关上下文污染**：写代码时看到 Review 规则，做 Review 时看到 Planning 规则
- **执行不一致**：同一操作在不同上下文中可能产生不同结果

## 参考来源

- **Superpowers** 的 subagent-driven-development：每个 task 由独立 subagent 执行，task-reviewer 二次审查
- **Lattice** 的 shell-script-driven 确定性操作：状态迁移、任务路由、Gate 执行全部通过 shell 脚本固定

## 核心设计原则

1. **每个领域唯一 Agent**：7 个 Agent，各对应一个 Kernel 模块，定义唯一、不可替代
2. **上下文隔离**：每个 Agent 只加载其领域 rules.md，只读写其领域 workspace 文件
3. **确定性操作走 Shell**：状态迁移、任务路由、Gate 执行、证据检查全部由 shell 脚本执行
4. **Agent 通过工件通信**：Agent 之间不直接对话，通过 `spec.yaml` 稳定对象、validator JSON、`plan.md`、`review.md` 等持久工件交接；`spec.md` 仅供人类审阅

---

## Agent 定义

### Agent 1: Themis-Spec（Specification 领域）

```
触发条件: 新需求、/themis-spec、/themis-clarify
加载规则: specification/rules.md
可读上下文:
  - workspace/context/（领域知识、架构、术语表、陷阱）
  - workspace/specs/（已有 Spec）
不可访问:
  - 具体代码实现
  - 测试结果
  - Gate 状态
产出: workspace/specs/<spec-id>/spec.yaml + spec.md（通过 themis-spec.sh publish）
确定性操作: themis-spec.sh validate/render/publish（复用 P5.2，不另建 lint 实现）
```

职责边界：只定义"要做什么"和"怎样算做完"，不涉及"如何实现"。

### Agent 2: Themis-Plan（Planning 领域）

```
触发条件: Spec 批准后、/themis-plan
加载规则: planning/rules.md
可读上下文:
  - workspace/specs/<spec-id>/spec.yaml（已验证的完整 Spec；spec.md 仅展示）
  - workspace/context/architecture/behavior-map/（行为地图）
  - workspace/context/architecture/（架构约束）
不可访问:
  - 具体代码文件内容（只需行为地图的结构信息）
  - 运行时状态
产出: workspace/specs/<spec-id>/plan.md
确定性操作:
  - themis-plan-lint.sh（校验 Plan 结构、AC 覆盖率）
  - themis-task-next.sh --json（从 Plan 中确定性解析下一个任务）
```

职责边界：只定义"任务如何组织"，不涉及"代码如何写"。

### Agent 3: Themis-Implement（Implementation 领域）

```
触发条件: Plan 就绪后、/themis-implement
加载规则: （task-driven，轻量 rules）
可读上下文:
  - 当前 Task 摘要（由 task-next.sh 输出）
  - 关联 AC（仅当前 Task 覆盖的 AC）
  - 涉及的具体源文件和测试文件
  - workspace/context/engineering/（工程规范）
不可访问:
  - 完整 Spec（仅当前 Task 的 AC 上下文）
  - 全局架构（仅涉及模块的边界约束）
  - 其他 Task 的实现细节
产出: 代码变更 + task evidence
确定性操作:
  - themis-task-complete.sh <spec-id> <task-id> --json（证据门禁完成检查）
  - themis-task-evidence-lint.sh（证据完整性校验）
```

职责边界：只实现**当前 Task 要求的行为**，不做跨 Task 重构。

### Agent 4: Themis-Review（Review 领域）

```
触发条件: 实现完成、/themis-review
加载规则: review/rules.md
可读上下文:
  - workspace/specs/<spec-id>/spec.yaml（权威语义）
  - workspace/specs/<spec-id>/spec.md（人类审阅投影）
  - workspace/specs/<spec-id>/plan.md
  - 代码 diff
  - task evidence
不可访问:
  - 实现推理过程（只读结果）
  - 未来 Spec/Plan
产出: workspace/specs/<spec-id>/review.md（pass/fail/cannot_verify）
确定性操作: themis-review-summary.sh（标准化评审结果写入）
```

职责边界：只看"证据是否支撑 Spec 和 Plan 的完成"，不做实现建议。

### Agent 5: Themis-Verify（Verification 领域）

```
触发条件: Review 通过后、/themis-verify
加载规则: verification/rules.md（Gate 语义和 failure 分类）
可读上下文:
  - Gate 定义（workspace/manifest.yaml）
  - 失败分类策略（config/failure-categories.yaml）
  - 证据路径
不可访问:
  - 代码内容（只运行命令、读输出）
  - Spec/Plan 细节（已通过 Review）
产出: workspace/runs/<run-id>/ + workspace/evidence/
确定性操作: themis-pipeline.sh --json-out（**全部 Gate 执行均为确定性脚本**）
```

职责边界：**此 Agent 的核心工作全部由 themis-pipeline.sh 完成**。Agent 只负责分类失败和格式化 Verdict，不执行任何 Gate。

### Agent 6: Themis-Knowledge（Knowledge 领域）

```
触发条件: 验证完成后、/themis-capture、定期触发
加载规则: knowledge/rules.md
可读上下文:
  - workspace/outcomes/（执行结果）
  - workspace/knowledge/candidates/（候选知识）
  - workspace/context/（已有知识）
不可访问:
  - 活跃 Spec/Plan 细节
  - 运行时状态
产出: workspace/context/（提升后的正式知识）+ workspace/knowledge/（审核记录）
确定性操作:
  - themis-knowledge-lint.sh（知识格式校验）
  - themis-knowledge-review.sh（知识审核）
  - themis-learn-draft.sh（从执行过程提取知识草稿）
```

职责边界：只执行**知识治理流程**（候选→去重→审核→提升），不创造新知识内容（内容来自执行过程）。

### Agent 7: Themis-Context（Context 领域）

```
触发条件: Pre-Spec、/themis-context、行为地图过期时
加载规则: context/rules.md
可读上下文:
  - 项目源文件（通过 Adapter）
  - workspace/context/（已有上下文）
  - workspace/cache/（上下文索引）
不可访问:
  - Spec 需求
  - 实施计划
产出: workspace/context/（更新后的上下文）+ workspace/context/architecture/behavior-map/
确定性操作:
  - themis-loader.sh（按需加载上下文）
  - themis-sync.sh（同步上下文索引）
  - themis-behavior-extractor（静态分析 + 行为地图生成）
```

职责边界：只发现和索引**项目事实**，不解释事实如何影响 Spec。

---

## 上下文隔离总表

| Agent | 加载 rules | 读取 workspace | 写入 workspace | 确定性脚本 |
|---|---|---|---|---|
| Themis-Spec | specification/rules.md | context/, existing specs/ | specs/<id>/spec.yaml + spec.md | themis-spec.sh |
| Themis-Plan | planning/rules.md | spec.yaml + validator JSON, behavior-map/, architecture/ | specs/<id>/plan.md | themis-plan-lint.sh, themis-task-next.sh |
| Themis-Implement | （轻量 task-driven） | plan.md (current task), source files | code, task evidence | themis-task-complete.sh, themis-task-evidence-lint.sh |
| Themis-Review | review/rules.md | spec.yaml + current spec.md, plan.md, diff, evidence | specs/<id>/review.md | themis-review-summary.sh |
| Themis-Verify | verification/rules.md | Gate config, failure categories | runs/<id>/, evidence/ | **themis-pipeline.sh**（全量） |
| Themis-Knowledge | knowledge/rules.md | outcomes/, candidates/, context/ | context/, knowledge/reviews/ | themis-knowledge-lint.sh, themis-learn-draft.sh |
| Themis-Context | context/rules.md | source files, context/ | context/, behavior-map/ | themis-loader.sh, themis-sync.sh, themis-behavior-extractor |

---

## Agent 调用方式

### 用户主动调用（斜杠命令）

```text
/themis-clarify   → Themis-Spec（追问模式）
/themis-spec      → Themis-Spec
/themis-plan      → Themis-Plan
/themis-implement → Themis-Implement
/themis-review    → Themis-Review
/themis-verify    → Themis-Verify
/themis-capture   → Themis-Knowledge
/themis-context   → Themis-Context
```

### Orchestrator 自动路由

Orchestrator 通过 `themis-spec-status.sh <spec-id> --json` 返回当前阶段和下一步建议：

```json
{
  "spec_id": "SPEC-001",
  "stage": "planned",
  "next_stage": "implementation",
  "next_skill": "themis-implement",
  "mode": "plan",
  "spec_dir": "workspace/specs/SPEC-001"
}
```

Agent 据此决定是否可执行、需要哪些上下文。

### 子 Agent 调度（可选优化）

未来可实现 themis-orchestrate.sh，按 flow.yaml 自动调度 Agent：

```bash
bash .themis/core/kernel/orchestrator/themis-orchestrate.sh <spec-id>
```

但首版以用户主动调用为主。

---

## Shell 脚本清单（确定性操作全集）

| 脚本 | 所属模块 | 输入 | 输出 | 幂等 |
|---|---|---|---|---|
| `themis-spec.sh validate/render/publish` | Specification | spec.yaml candidate / canonical pair | validator JSON + spec.md / pair publication | 是 |
| `themis-plan-lint.sh` | Planning | plan.md | pass/fail + AC 覆盖报告 | 是 |
| `themis-task-next.sh` | Planning | plan.md | 下一 task JSON | 是 |
| `themis-task-complete.sh` | Planning/Verification | task-id + evidence path | pass/fail | 是 |
| `themis-task-evidence-lint.sh` | Verification | spec-id | pass/fail + 缺失证据 | 是 |
| `themis-review-summary.sh` | Review | spec-id + verdicts | review.md + review-summary.json | 是 |
| `themis-pipeline.sh --json-out` | Verification | spec-id | Gate 结果 + eval JSON | 是 |
| `themis-knowledge-lint.sh` | Knowledge | candidate path | pass/fail | 是 |
| `themis-knowledge-review.sh` | Knowledge | candidate path | review result | 是 |
| `themis-learn-draft.sh` | Knowledge | spec-id/outcome | knowledge draft | 否（时间戳不同） |
| `themis-loader.sh` | Context | keywords | context items | 是 |
| `themis-sync.sh` | Context | — | 更新 context-index | 是 |
| `themis-spec-status.sh` | Orchestrator | spec-id | 阶段 + 下一步 | 是 |

---

## 目标文件

- `core/kernel/orchestrator/agents.yaml` — Agent 定义与上下文隔离配置
- `core/kernel/orchestrator/flow.yaml` — 阶段与 Agent 的路由映射
- `core/kernel/*/rules.md` — 各 Agent 的领域规则（精简到只含该领域需要的）
- `bin/` 与已安装 Core 下的确定性 shell 脚本集合（复用 P5.2 `themis-spec.sh`，并新增 themis-plan-lint.sh, themis-task-next.sh, themis-task-complete.sh, themis-task-evidence-lint.sh, themis-review-summary.sh, themis-pipeline.sh, themis-knowledge-lint.sh, themis-knowledge-review.sh, themis-learn-draft.sh, themis-loader.sh, themis-sync.sh, themis-spec-status.sh）
- `.claude/commands/` 下的斜杠命令（themis-clarify/themis-spec/themis-plan/themis-implement/themis-review/themis-verify/themis-capture/themis-context）

## 执行前置步骤

当用户主动发起本计划时，**第一步**必须在本计划目录创建或更新 `impl.md`（`docs/plan/80-multi-agent-architecture/impl.md`），至少记录：

1. 每个 Agent 的精确 rules.md 内容边界和篇幅上限
2. Themis-Context 的 Adapter 接口和静态分析支持的语言列表
3. Shell 脚本的共享库设计（`_themis-lib.sh`）
4. Agent 调度机制：用户调用 vs Orchestrator 自动路由
5. 上下文窗口预算：每个 Agent 的最大 token 估算
6. 与 flow.yaml 的精确映射

`impl.md` 经用户确认前，不得修改目标文件。

## 验收条件

- 每个 Agent 的 rules.md 不超过其领域边界（不含其他模块的规则）
- themis-pipeline.sh 对同一输入产生相同输出（确定性验证）
- themis-task-next.sh 对同一 plan.md 返回相同任务序列
- Themis-Spec 无法读到代码实现文件
- Themis-Implement 无法读到完整 Spec（仅当前 Task 的 AC）
- 所有 Agent 通过工件交接，不依赖对话记忆

## 风险与回滚

- **风险**：Agent 拆分过细，导致单个 Agent 上下文不足而无法做出正确判断
- **缓解**：每个 Agent 的 rules.md 保持精简但完整；上下文不足时 Agent 应请求 Orchestrator 加载额外上下文，而非自己猜测
- **风险**：shell 脚本与 Agent 规则不同步，脚本检查通过但 Agent 产出不符合规范
- **缓解**：Agent rules.md 中引用 shell 脚本作为前置/后置条件，形成约束闭环
- **回滚**：移除 Agent 定义后可回退到单 Agent 模式；shell 脚本保持独立可运行
