# Capabilities 包

## 职责

Capabilities 保存 Themis 十六项内部语义合同。每个 Capability 只拥有一个语义判断，返回 proposed Capability Invocation Result；它不拥有路由、动态 authority state、持久化 currentness 或执行权限扩张。

本包不是 Claude Code project Skill 注册目录。它不使用 Skill frontmatter，不提供 slash-command 或 `user-invocable` 入口；唯一公共入口是 `.claude/skills/themis/SKILL.md`。

## 执行模型

```text
Global Control Rule
→ 唯一自然语言 Policy 选择一个 Capability 与 fixed Agent Profile
→ 建立绑定一个 authority scope 和 Execution Identity 的临时 Invocation
→ Capability 返回 proposed result
→ 校验 result identity、scope、Profile、status 与 bindings
→ Policy 精确匹配 control action
→ recorder 完整持久化并记录 observation
→ 重读 identity、content、digest 与 bindings
→ 更新独立 current pointer
```

缺少任一步时，结果仍是提案，不能成为 authority 或推进 gate。

## Invocation 不变量

- 一次 Invocation 只加载一个 Capability 与其固定 Agent Profile。
- 每次 Invocation 只绑定一个 authority scope、一个 Execution Identity 和一个 attempt identity。
- Capability 不调用其他 Capability 或 Agent，不选择或执行 route，不扩张 Profile。
- Capability 不返回多个竞争终态，不把聊天、summary 或临时推理当作 state。
- `recommended_route` 只供诊断；控制面只能使用 policy route。
- validator、recorder 或 runtime 不可用时必须报告 assurance unavailable，不能把计划动作写成 observed success。

## 公共 Result Envelope

每个 Capability 的“输出字段合同”都必须显式保留以下稳定字段；Capability-specific bindings 与 structured result 字段仍在各合同内逐项展开，不能只引用本表。

| 字段 | 必填性 | 合法值或内容 | 语义 |
|---|---|---|---|
| `capability` | 必填 | 一个固定 `themis-*` identity | 结果生产者 |
| `authority_scope` | 必填 | `request-intake` 或 `lifecycle`；Failure Learning 由 Invocation 选择其一 | 动态状态隔离边界 |
| `agent_profile` | 必填 | `semantic-readonly`、`independent-checker`、`human-dialogue` 或 `implementation-writer` | 固定权限合同 |
| `status` | 必填 | 当前 Capability 与 path/profile 的唯一合法终态 | exactly-one Policy rule 的匹配输入 |
| `input_bindings` | 必填 | 合同逐项声明的 identity、revision、policy、continuation 与 path/profile bindings | result provenance |
| `output.structured_result` | 必填 | Capability-specific 字段集合 | semantic proposal |
| `output.proposed_artifact_references` | 必填 | proposal references 列表，可为空 | 不建立 persistence/currentness |
| `output.materialization_target` | 必填 | Invocation 预期的 Capability 合法 target family | 参与 result binding 校验；status-specific control action 只由 Policy route 决定 |
| `diagnostics.gaps` | 必填 | gaps 列表，可为空 | 未满足项 |
| `diagnostics.evidence` | 必填 | evidence references 列表，可为空 | 结论依据 |
| `diagnostics.affected_semantics` | 必填 | Capability-specific closed semantics 列表，可为空 | 失效与返工提示 |
| `recommended_route` | 必填 | Capability-specific advisory value | 仅供诊断，不能驱动 control |

每个 `input_bindings` 至少显式列出 `execution_identity`、`invocation_identity`、`attempt_identity`、`policy_identity`、`policy_digest`、`continuation_identity`、`selected_path` 和 `profile`，并按合同补充 scope identity 与 source/artifact bindings。七个 Review Feedback owner 在 owner continuation re-entry 时还必须绑定 exact `review_feedback_revision` 和 `review_feedback_owner_continuation_reference`；Capability result 只能证明它处理该 Feedback，不能自行声明 resolved。只有 owner-specific 成功结果完成 Policy control、完整物化与重读后，control layer 才能先记录并重读 resolution observation，再记录并重读引用它的 unresolved-set update observation；只有后一步完成后，新 state view 才能排除 exact Feedback。所有结构化字段与 Markdown 内容都只是 proposal；只有 Policy control、完整 recorder observation 与重读可以建立 immutable revision 和 current pointer。

## 固定 Capabilities

| Contract | Stable identity | Authority scope | Agent Profile | Materialization target |
|---|---|---|---|---|
| `current-request-dialogue.md` | `themis-current-request-dialogue` | `request-intake` | `human-dialogue` | Intake proposal/decision；policy 后续物化 Current Request |
| `questioning.md` | `themis-q` | `lifecycle` | `human-dialogue` | Questioning proposal 或 paired Questioning round |
| `grounding.md` | `themis-grounding` | `lifecycle` | `semantic-readonly` | structured Grounding record |
| `complexity-assessment.md` | `themis-complexity-assessment` | `lifecycle` | `semantic-readonly` | structured Complexity Assessment record |
| `simple-planning.md` | `themis-simple-plan` | `lifecycle` | `semantic-readonly` | paired Plan revision |
| `specification.md` | `themis-spec` | `lifecycle` | `semantic-readonly` | temporary Invocation handoff only |
| `planning.md` | `themis-planning` | `lifecycle` | `semantic-readonly` | paired Plan revision |
| `plan-check.md` | `themis-plan-check` | `lifecycle` | `independent-checker` | structured Plan Check record |
| `review-projection.md` | `themis-review-projection` | `lifecycle` | `semantic-readonly` | paired Review Projection revision |
| `review-check.md` | `themis-review-check` | `lifecycle` | `independent-checker` | structured Review Check record |
| `review-dialogue.md` | `themis-review-dialogue` | `lifecycle` | `human-dialogue` | durable Review Dialogue continuation、paired Review Feedback 或 Review Approval proposal |
| `implementation.md` | `themis-impl` | `lifecycle` | `implementation-writer` | paired Impl Result and operational evidence |
| `verification.md` | `themis-verification` | `lifecycle` | `independent-checker` | paired Verification revision |
| `acceptance-dialogue.md` | `themis-acceptance-dialogue` | `lifecycle` | `human-dialogue` | paired Human Acceptance revision |
| `failure-learning.md` | `themis-failure-learning` | `request-intake | lifecycle` | `semantic-readonly` | expected target 为 `failure-learning-pair`；只有 `candidate-ready`/`not-reusable` 实际形成 pair，其余由 Policy 保留 proposal 或记录 unavailable |
| `summary.md` | `themis-summary` | `lifecycle` | `semantic-readonly` | paired Summary revision |

Strict Schema、canonical serialization、validator 与 semantic oracle 属于 Plan 36；recorder、evaluator、digest service 和 write primitives 属于 Plan 37。当前合同只声明 Prompt-level 语义和可人工重放的物化边界。
