# P5 子模块：文档同步

## 覆盖任务

- 任务 6：更新 `docs/core/kernel/specification.md`

## 设计依据

文档更新是规则文件落地后的最后一个步骤，确保 WIKI 与规则实现保持一致。不引入新设计决策。

## 目标文件：`docs/core/kernel/specification.md`

**路径**：`docs/core/kernel/specification.md`

### 变更内容

在现有人工维护文档中反映 P5 追问流程。保留已有的三个子模块（Spec-Model、Spec-Validation、Acceptance-Criteria），新增第四个。

### 具体变更

#### 1. 核心能力表（追加一行）

在现有三行后追加：

```markdown
| 需求追问 | 通过四步流程（意图发现→范围评估→上下文收集→设计收敛→对抗验证）将模糊意图收敛为可执行 Spec |
```

#### 2. 子模块段（新增第四个子模块）

在 Acceptance-Criteria 子模块之后、与 Workspace 交互段之前插入：

```markdown
### Requirement-Questioning — 需求追问

Specification 在 Spec 创建前执行结构化追问流程，从模糊意图到可执行 Spec：

```
Step 0: Intent Discovery（意图发现）
  └── Five Whys 根因分析，区分"用户要的"和"用户需要的"

Step 1: Scope Assessment（范围评估）
  └── 多子系统检测、Pre-mortem 风险识别、复杂度判定

Step 2: Context Gathering（上下文收集）
  └── 目标、约束、可量化成功标准、Option Zero、假设清单

Step 3: Design Convergence（设计收敛）
  └── 多方案对比、AC 分段确认、Spec 草稿写入、自检

Step 4: Adversarial Validation（对抗验证）
  └── AI 切换为攻击者立场，用标准攻击场景库扫描漏洞
```

**复杂度自适应**：低复杂度使用精简版流程和快速检查表；
中复杂度使用完整流程；高复杂度启用全覆盖对抗验证和多轮迭代。

**硬门禁**：用户批准 + 对抗验证通过 → Draft → Specified 状态迁移。

**策略文件**：`core/policies/specification.yaml`（追问规则）、
`core/policies/transitions.yaml`（门禁条件）

**模板文件**：`core/templates/spec-questioning.md`（追问 Prompt）、
`core/templates/spec-adversarial-checklist.md`（攻击场景库）

**边界**：Requirement-Questioning 负责"帮用户说清楚要做什么"，
Spec-Validation 负责"检查说清楚了没有"。两者串行执行。
```

#### 3. 与 Workspace 的交互段（更新）

在 Specification 写入部分增加 Draft 阶段的写入说明：

```markdown
Specification 写入:
  workspace/specs/<spec-id>/spec.md   # Step 3 后写入草稿，Step 4 + 批准后生效
  （校验结果通过 Verification 模块的 Gate 机制记录）
```

### 不变更内容

- Spec-Model 子模块（结构定义）
- Spec-Validation 子模块（结构校验）
- Acceptance-Criteria 子模块（AC 规范）
- 输入/输出协议段

## 验证要求

- 与 `specification/rules.md` 中的 Step 描述一致
- 与其他 kernel 文档（orchestrator.md、planning.md）的格式一致
- 子模块描述在 "与 Workspace 的交互" 段之前
- 链接文本可解析（`core/policies/specification.yaml` 等为相对路径说明，非 Markdown 链接）
