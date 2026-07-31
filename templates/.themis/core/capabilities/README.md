# Capabilities Package

## Responsibility

Capabilities 保存 Themis 十六项内部语义合同。每个 Capability 只拥有一个语义判断，返回 proposed Capability Invocation Result；它不拥有路由、动态 authority state、持久化 currentness 或执行权限扩张。

本包不是 Claude Code project Skill 注册目录。它不使用 Skill frontmatter，不提供 slash-command 或 `user-invocable` 入口；唯一公共入口是 `.claude/skills/themis/SKILL.md`。

## Execution model

```text
Global Control Rule
→ transitions.yaml 选择一个 Capability 与 fixed Agent Profile
→ 建立绑定一个 authority scope 和 Execution Identity 的临时 Invocation
→ Capability 返回 proposed result
→ 校验 result identity、scope、Profile、status 与 bindings
→ policy 精确匹配 control action
→ recorder 完整持久化并记录 observation
→ 重读 identity、content、digest 与 bindings
→ 更新独立 current pointer
```

缺少任一步时，结果仍是提案，不能成为 authority 或推进 gate。

## Invocation invariants

- 一次 Invocation 只加载一个 Capability 与其固定 Agent Profile。
- 每次 Invocation 只绑定一个 authority scope、一个 Execution Identity 和一个 attempt identity。
- Capability 不调用其他 Capability 或 Agent，不选择或执行 route，不扩张 Profile。
- Capability 不返回多个竞争终态，不把聊天、summary 或临时推理当作 state。
- `recommended_route` 只供诊断；控制面只能使用 policy route。
- validator、recorder 或 runtime 不可用时必须报告 assurance unavailable，不能把计划动作写成 observed success。

## Common result envelope

```yaml
capability: themis-*
authority_scope: request-intake | lifecycle
agent_profile: semantic-readonly | independent-checker | human-dialogue | implementation-writer
status: <capability-legal status>
input_bindings:
  execution_identity: ""
  invocation_identity: ""
  attempt_identity: ""
  policy_identity: ""
  policy_digest: ""
  continuation_identity: ""
  selected_path: simple | full | null
  profile: lightweight | full | null
output:
  structured_result: {}
  proposed_artifact_references: []
  materialization_target: ""
diagnostics:
  gaps: []
  evidence: []
  affected_semantics: []
recommended_route: <advisory only>
```

每个合同分别声明 Stable identity、Authority scope、固定 Agent Profile、输入、合法状态、输出、权限、停止条件和 Materialization target。结构化结果或 Markdown 内容都只是 proposal；只有 policy control、完整 recorder observation 与重读可以建立 immutable revision 和 current pointer。

## Fixed capabilities

| Contract | Stable identity | Authority scope | Agent Profile | Materialization target |
|---|---|---|---|---|
| `current-request-dialogue.md` | `themis-current-request-dialogue` | `request-intake` | `human-dialogue` | Intake proposal/decision；policy 后续物化 Current Request |
| `questioning.md` | `themis-q` | `lifecycle` | `human-dialogue` | question continuation 或 paired Questioning round |
| `grounding.md` | `themis-grounding` | `lifecycle` | `semantic-readonly` | structured Grounding record |
| `complexity-assessment.md` | `themis-complexity-assessment` | `lifecycle` | `semantic-readonly` | structured Complexity Assessment record |
| `simple-planning.md` | `themis-simple-plan` | `lifecycle` | `semantic-readonly` | paired Plan revision |
| `specification.md` | `themis-spec` | `lifecycle` | `semantic-readonly` | temporary Invocation handoff only |
| `planning.md` | `themis-planning` | `lifecycle` | `semantic-readonly` | paired Plan revision |
| `plan-check.md` | `themis-plan-check` | `lifecycle` | `independent-checker` | structured Plan Check record |
| `review-projection.md` | `themis-review-projection` | `lifecycle` | `semantic-readonly` | paired Review Projection revision |
| `review-check.md` | `themis-review-check` | `lifecycle` | `independent-checker` | structured Review Check record |
| `review-dialogue.md` | `themis-review-dialogue` | `lifecycle` | `human-dialogue` | paired Review Feedback or Approval proposal |
| `implementation.md` | `themis-impl` | `lifecycle` | `implementation-writer` | paired Impl Result and operational evidence |
| `verification.md` | `themis-verification` | `lifecycle` | `independent-checker` | paired Verification revision |
| `acceptance-dialogue.md` | `themis-acceptance-dialogue` | `lifecycle` | `human-dialogue` | paired Human Acceptance revision |
| `failure-learning.md` | `themis-failure-learning` | `request-intake | lifecycle` | `semantic-readonly` | paired Failure Learning candidate revision |
| `summary.md` | `themis-summary` | `lifecycle` | `semantic-readonly` | paired Summary revision |

Strict Schema、canonical serialization、validator 与 semantic oracle 属于 Plan 36；recorder、evaluator、digest service 和 write primitives 属于 Plan 37。当前合同只声明 Prompt-level 语义和可人工重放的物化边界。
