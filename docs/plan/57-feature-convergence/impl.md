# P5.7 — FEATURE 收敛与运行时闭环实施索引

**优先级**：P5.7
**依赖**：P5.2 Spec Dual View、P5.4 Context Restructure、P5.5 Knowledge Governance、P5.8 Planning、P6.8 Review、P5.9 Implementation、P6.5 Verification
**状态**：设计裁决已同步；各运行时实施仍需分别取得用户确认

> 本计划只协调 `docs/design/FEATURE.md` 的候选意见处置和跨模块依赖，不拥有 Context、Knowledge、Planning、Review、Implementation、Verification 或 Spec 的长期规则。长期规则仍写入各自唯一 owning design page。

## 目标

1. 将 `FEATURE.md` 维护为候选意见与处置索引。
2. 保留已确认的 Core/Workspace、Policy/Prompt/Shell 与 Spec v2 双视图边界。
3. 从当前产品退役 Behavior Map、Upgrade 与 Migration，不引入替代命令、隐式 Schema 转换或第二套源码表示。
4. 串联显式 Context 引用、受治理知识候选、Planning、前置 Review、Implementation、后置 Verification、Human Acceptance 与 Summary。
5. 避免为 `FEATURE.md` 另造第二套 Context、Knowledge、Run、Evidence 或 Artifact 合同。

## 候选意见处置

| FEATURE 意见 | 处置 | 唯一归属/原因 |
|---|---|---|
| 移除 Behavior Map | `adopted` | Context 不拥有第二套源码表示；Planning/Review 直接核验当前源码并记录 revision/digest。 |
| 移除 Migration、Upgrade | `adopted` | 当前只支持 fresh Init、固定 schema allow-list 和 unsupported fail closed；未来恢复时重新设计。 |
| 禁止复杂脚本 | `adopted` | 归入 Architecture：一个 executor 只拥有一个协议操作或事务边界，不以任意行数裁决。 |
| 重新判断 Policy 是否存在 | `already_owned` | Policy 继续拥有稳定步骤、阈值、路由、枚举和处置。 |
| 明确自然语言/YAML/脚本边界 | `already_owned` | 现有 Policy → Prompt → deterministic Shell 模型保持不变。 |
| 项目“坑”沉淀为知识 | `already_owned` | 通过 Knowledge candidate → review → approved promotion 进入 Context。 |
| 需求澄清、图示和自主学习 | `adopted` | 澄清与图示归 Specification；学习必须经过 Knowledge Governance。 |
| 将设计正文写入 AGENTS | `rejected` | AGENTS 只保留协作规范与设计链接。 |
| CLAUDE/测试/对话/决策表是高 ROI 来源 | `adopted` | 只作为 candidate/evidence 来源，不独立建立项目事实。 |
| 知识准入启发式 | `adopted` | 归入 Governance/Knowledge 的可复用知识准入规则。 |
| 失败后停止、修复、重跑、最多 3 次、exit 2 | `adopted` | 归入 Orchestrator/Verification policy、protocol 和 runner。 |
| escalation 先生成 draft | `adopted` | 归入 Knowledge `verification_failure` candidate；禁止直接写 Context。 |
| 追问不生成文件 | `rejected` | 保留 cache candidate，以持久工件承载未完成语义并支持恢复。 |
| 移除 `spec.md` 投影章节 | `rejected` | 保留 Spec v2 单向 Human projection。 |
| 提供 `review.md` | `already_owned` | 由 P6.8 实施前置 Review evidence 与 Human projection。 |
| 新增 `summary.md` | `adopted` | 仅在 passing Verification 后的 Human Acceptance `accepted` 后确定性生成。 |
| Spec 声明 Context 来源 | `adopted` | 复用 `EVD-* kind: context`，P5.4 校验 Catalog/digest/freshness。 |

## 跨模块合同

```text
P5.4 Context
  ├─ 在 themis-workspace 内提供 Catalog/Search/Bundle/Signal/Freshness
  ├─ 被 Spec 引用校验和 Planning/Review 消费
  └─ 被 P5.5 fact validation 消费

Planning
  └─ current Spec + Context + direct source inspection
      → Plan/Task DAG/scope lock/AC traceability

P6.8 Review
  └─ current Spec/Plan/design/risk/rollback/acceptance design
      → approved | changes_requested | blocked
      → approved 才授权 Implementation

Implementation
  └─ 只执行 approved Review 绑定范围并记录 Task evidence

P6.5 Verification
  ├─ 消费 approved Review 与 implementation revision
  ├─ 首个 blocking Gate 失败即停
  ├─ 写 Run/Evidence/Repair State
  ├─ 外部修复后 resume
  └─ 3 个 repair cycle 耗尽 → Escalation

Escalation
  ├─ P5.5 可用 → verification_failure candidate
  └─ P5.5 不可用 → Run 中 candidate_pending

Verification pass
  → Human Acceptance
  → accepted 后生成 summary.md
  → Outcome / Attribution / Knowledge / Archived
```

## 项目身份与隔离

所有 Context Bundle、Knowledge candidate/review/action、Plan、Review evidence、Run、Repair State、Acceptance 和 Escalation 至少绑定：

- `project.name`；
- 规范化项目根或稳定 project root digest；
- Workspace root；
- source/implementation revision；
- Spec/Plan/Review/Task/Run/evidence 引用。

Core 只保存通用能力和策略。任何 executor 只能在显式传入且通过路径校验的一个 Workspace 内读取或写入；不得搜索、合并或提升其他 Workspace 的项目记录。

## Task DAG

| Task | 内容 | 依赖 | 完成条件 |
|---|---|---|---|
| FC-01 | 完成 `FEATURE.md` 处置索引、退役资产和正式设计同步 | 无 | 每条意见有处置和 owning page；退役入口不存在；无第二份规则正文。 |
| FC-02 | 实施 P5.4 Context | FC-01 | 当前 Workspace schema 内的 Protocol、Catalog/Search/Bundle/Signal 和 tests 通过。 |
| FC-03 | 扩展 Spec Context 引用 | FC-02 | `EVD-* context` 引用、validator 和投影测试通过。 |
| FC-04 | 实施 P5.5 Knowledge | FC-02 | record/lint/apply、批准门禁、隔离和回滚通过。 |
| FC-05 | 实施 Planning | FC-02、FC-03 | Plan、Task DAG、scope lock 和 AC traceability 通过。 |
| FC-06 | 实施 P6.8 前置 Review | FC-05 | current Spec/Plan 绑定、result、authorization、投影和 drift 测试通过。 |
| FC-07 | 实施 reviewed-scope Implementation | FC-06 | Task evidence 完整，未越过 scope lock。 |
| FC-08 | 实施 P6.5 Verification recovery | FC-07 | fail-fast、repair/resume、3 次耗尽、exit 2、持久 state 和 verify projection 通过。 |
| FC-09 | 集成 escalation → knowledge candidate | FC-04、FC-08 | 无直接 Context 写入；unavailable 时保留 candidate_pending。 |
| FC-10 | 实施 Acceptance、Summary 与归档门禁 | FC-08 | pass 后可验收；accepted 后生成 summary；来源引用与状态隔离正确。 |
| FC-11 | 全量回归和正式设计状态更新 | FC-09、FC-10 | 全部验证输出已观察，设计状态与资产一致。 |

```text
FC-01 → FC-02 ─┬→ FC-03 → FC-05 → FC-06 → FC-07 → FC-08 ─┬→ FC-10 → FC-11
               └→ FC-04 ────────────────────────────────┴→ FC-09 ─┘
```

## 目标文件类别

- `docs/design/architecture.md`：控制脚本职责、安装位置和执行模型边界。
- P5.4：`docs/plan/54-context-restructure/impl.md` 所列 Protocol、executors 与 tests；不得包含 Migration 或 Behavior Map。
- P5.5：`docs/plan/55-knowledge-governance/impl*.md` 所列 policy、templates、executors 与 tests；不得隐式改变 Workspace schema。
- Planning/Implementation：对应计划中的 Artifact、Task、scope lock 和 evidence 合同。
- P6.8：`docs/plan/68-review-enhancement/impl.md` 所列前置 Review policy、protocol、Prompt、renderer 与 tests。
- P6.5：`docs/plan/65-verification-enhancement/impl.md` 所列 policy、protocol、Prompt、runner、projection 与 tests。
- Acceptance/Summary：由后续获批计划落地 machine evidence、renderer 和 archive gate。

## 总验证矩阵

| 验证域 | 方法 | 必须证明 |
|---|---|---|
| 设计治理 | 链接和重复规则审计 | `FEATURE.md` 不拥有第二份长期合同，AGENTS 未复制设计。 |
| Shell | `bash -n`、ShellCheck | Bash 3.2，中文边界注释，JSON 接口稳定。 |
| Schema/Policy | `yq eval` + 故障夹具 | required/allowed/enums/IDs/refs 严格且 fail closed。 |
| Template contract | template checker + TAP | 新资产缺失、损坏、版本错误时稳定失败；退役资产出现时失败。 |
| Context | module TAP | 检索、Bundle、Signal、freshness 和隔离；不改变 Workspace schema。 |
| Spec | `tests/spec-artifact/test.sh` | Context 引用和双视图稳定，无反向同步。 |
| Knowledge | module TAP | candidate、人工批准、处置、隔离、幂等和回滚。 |
| Planning/Review | module TAP | scope/traceability、前置批准、authorization 绑定与失效。 |
| Implementation | module TAP | 只执行 reviewed Task，Task evidence 可追溯。 |
| Verification | module TAP | fail-fast、resume、evidence invalidation、attempt 持久化、exit 2。 |
| Acceptance/Summary | module TAP | 只有 pass 可验收，只有 accepted 可生成 summary，投影不成为 machine state。 |
| 安装边界 | Init suite | fresh Init 成功；已有 `.themis` 在写入前失败且 Workspace 不变。 |
| 端到端 | 隔离 fixture | Context → Spec → Plan → Review → Implement → Verify → Accept → Summary 可追溯。 |
| 最终一致性 | `git diff --check` + `git status --short` | 仅确认范围变化；既有删除不被意外恢复。 |

## 确认门禁

本索引不授予各运行时实施权限。P5.4/P5.5/Planning/Review/Implementation/Verification/Acceptance-Summary 必须分别按其获批 `impl.md` 执行；确认前不得创建对应 Core Runtime 或测试实现。
