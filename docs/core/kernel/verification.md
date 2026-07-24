# Verification — 验证

## 职责边界

Verification 是 SDD 质量门禁的执行引擎。它调度 Gate、采集证据、分类失败并计算最终 Verdict。它回答"这个 Spec 是否通过了所有质量检查"，但不定义检查的具体内容（检查内容由 Spec 和 Plan 定义）。

**Verification 是执行者，不是决策者——它只陈述事实，不判断好坏。**

## 核心能力

| 能力 | 说明 |
|---|---|
| Gate 调度 | 按策略调度和执行 Gate Pipeline |
| 证据采集 | 收集每个 Gate 的通过/失败证据 |
| 失败分类 | 按预定义类别对失败进行分类 |
| Verdict 计算 | 汇总所有 Gate 结果，计算最终 Verdict |

## 子模块

### Pipeline — Gate 流水线

定义和执行 Gate 的调度流水线：

- Gate 按依赖关系排序执行（如：Lint → Build → Test）
- 支持并行 Gate 执行（如：单元测试和集成测试可并行）
- 支持条件 Gate（如：仅当涉及 Schema 变更时运行 Schema 检查）
- 执行策略定义在 `core/policies/verification.yaml`

**边界**：Pipeline 调度 Gate 执行，但不实现具体 Gate 的检查逻辑（检查逻辑由各 Adapter 实现）。

### Gates — 门禁

定义 Gate 的类型和语义：

- **阻塞 Gate**：失败则阻止继续推进
- **警告 Gate**：失败但允许继续，标记为待处理
- **信息 Gate**：仅收集信息，不影响推进
- Gate 状态：`pending | running | passed | failed | skipped | error`
- Gate 语义定义在 `core/policies/verification.yaml`

**边界**：Gates 定义 Gate 的抽象模型，具体 Gate 实现由 Adapter 提供。

### Evidence — 证据采集

收集和保存 Gate 执行的证据：

- 每个 Gate 执行后保存其输出（命令输出、测试报告、构建日志等）
- 证据保存到 `workspace/evidence/` 对应子目录
- 证据格式由 Evidence Protocol 定义
- 支持文本证据和二进制证据（截图、日志文件等）

**边界**：Evidence 保存证据，不解释证据（解释是 Verdict 的职责）。

### Failure-Classification — 失败分类

对 Gate 失败进行分类：

- **瞬态失败**：环境问题、网络超时、资源竞争（可重试）
- **代码失败**：编译错误、测试失败、Lint 违规（需修复）
- **配置失败**：环境变量缺失、权限不足、配置错误（需运维介入）
- **策略冲突**：Gate 规则本身矛盾（需人工解决）
- 分类规则定义在 `core/policies/failure-categories.yaml`

**边界**：Failure-Classification 只分类失败，不修复失败。

### Verdict — 裁决

汇总所有 Gate 结果计算最终判定：

- `pass`：所有阻塞 Gate 通过
- `fail`：至少一个阻塞 Gate 失败
- `inconclusive`：证据不足以判断
- Verdict 写入 `workspace/runs/<run-id>/verdict.json`
- 附带完整的 Gate 结果列表和证据引用

**边界**：Verdict 是单次运行的结论，不代表最终交付质量（最终质量由 Outcomes 跟踪）。

## 与 Workspace 的交互

```
Verification 读取:
  workspace/manifest.yaml              # Gate 配置
  workspace/policies/verification.yaml # 项目验证策略
  workspace/specs/<spec-id>/           # 工件内容

Verification 写入:
  workspace/runs/<run-id>/             # 执行记录
  workspace/evidence/                  # 证据保存
  workspace/state/                     # 当前验证状态
```

## 输入/输出协议

- **输入**：通过 Gate Protocol 定义 Gate 接口，通过 Evidence Protocol 定义证据格式
- **输出**：Gate Result 通过 Gate Result Protocol 输出，Verdict 通过 Outcome Protocol 输出