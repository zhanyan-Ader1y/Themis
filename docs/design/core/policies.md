# Policies — 策略层

> 规范状态：正式设计。实现状态：部分实现；当前模板包含 `specification.yaml` 和 `transitions.yaml`，其余策略属于已确认但未实现的设计。

## 职责边界

Policy 保存 Themis 的确定性默认规则。项目可以在明确允许的范围内扩展或收紧默认值，但不能直接修改已安装 Core，也不能改变 Protocol 语义。

```text
Effective Policy = Core Default Policy + Allowed Workspace Override
```

## 覆盖规则

| 操作 | 规则 |
|---|---|
| 增加 Gate | 允许，但必须满足 Gate Protocol |
| 收紧阈值或超时 | 允许 |
| 替换默认值 | 仅限 policy 明确标记为 `overridable` 的字段 |
| 弱化 hard gate | 禁止 |
| 修改状态或协议语义 | 禁止 |
| 把失败重新定义为通过 | 禁止 |

有效策略应在每次 Run 中持久化快照，使结果可以重放和解释。该执行能力当前尚未实现。

## 当前模板策略

| 文件 | 当前用途 | 状态 |
|---|---|---|
| `specification.yaml` | P5 复杂度分流、Step 0–4、双视图发布与对抗验证要求 | 已实现 |
| `transitions.yaml` | 声明 `draft_to_specified` 的八个 validator-backed readiness 条件 | 已实现声明；状态执行器未实现 |

P5 只将结构化证据写入 `spec.yaml` candidate，并通过 publisher 发布 canonical pair，仍保持 `status: draft`。`draft_to_specified` 只认可 `themis-spec.sh validate` 的稳定 JSON check ID；Markdown 标题或正文不是 transition evidence。当前原生 Artifact v2 / Spec v2 不声明历史兼容或转换路径。

## 已确认但未实现的策略

- lifecycle 与通用状态路由；
- artifact/plan/task 结构校验；
- `review.yaml`：前置评审维度、严重级别、Spec/Plan/设计/evidence 门禁和 `approved | changes_requested | blocked` 条件；
- `verification.yaml`：Gate 类型与顺序、blocking、fail-fast、失败分类、transient retry、`max_repair_attempts: 3`、evidence invalidation、escalation 和 exit code；
- `acceptance.yaml`：人工验收所需 artifact revision、必需 evidence、拒绝返工路由与 Summary 前置条件；
- `knowledge-governance.yaml`：候选来源、分类、审核维度、人工批准与允许处置。

稳定顺序、阈值、条件、ID 和处置必须先进入 YAML，再由 Prompt 与脚本引用；不得只在 Prompt 或 Agent 输出中维护确定性规则。

## 加载顺序

1. 加载 Core 默认 policy。
2. 加载 Workspace 中允许的项目 override。
3. 校验 override 没有弱化 hard gate 或改变协议语义。
4. 生成 Effective Policy。
5. 在 Run 中保存快照后再执行相关步骤。

该通用加载器尚未实现；当前脚本只读取各自明确声明的 YAML 文件。
