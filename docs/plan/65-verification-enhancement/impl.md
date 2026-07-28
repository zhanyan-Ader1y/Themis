# P6.5 实施索引

P6.5 将 Verification 从 policy/prompt 占位设计扩展为可恢复的确定性 Gate 运行时：顺序执行、首错停止、结构化失败、外部 Agent 修复交接、受影响 Gate 重跑、持久 attempt 和 escalation。Verification 仍不修改项目代码，也不记录 lifecycle transition。

**状态**：实施设计待用户确认。原计划“只提供 policy/prompt/rules、不实现 pipeline”的范围被本索引扩展；历史 README 保留，实施时以本索引和正式设计为准。

## 设计决策

| # | 决策 |
|---|---|
| D1 | Gate、分类、retry route、attempt limit、exit code 和 verdict 聚合由 YAML policy 定义。 |
| D2 | Prompt 只处理无法由命令/exit/status 确定的语义分类和 repair brief，不执行 Gate 或改代码。 |
| D3 | Shell runner 顺序执行 blocking Gate，在首个失败处停止；warning/info 依 policy 处理。 |
| D4 | `max_repair_attempts: 3` 表示初次失败后最多三个 repair + rerun cycle。 |
| D5 | attempt 写入 `workspace/state/retries/`，进程重启、Agent 会话变化或重复调用不得重置。 |
| D6 | Agent/用户在 runner 外修复；runner 只发出 `repair_required` 并在 `resume` 时校验 handoff、使旧 evidence 失效并重跑。 |
| D7 | retry 耗尽持久化 escalation，stdout 返回稳定 JSON，process exit `2`。普通 Gate fail/invalid input 使用 exit `1`，成功/可继续使用 `0`。 |
| D8 | escalation 只提交 Knowledge candidate 请求，不直接写 Context；Knowledge capability 缺失时在 Run 保留 `candidate_pending`。 |
| D9 | Run、Gate attempt、repair state、escalation 使用稳定无版本 Protocol；`verify.md` 是 Human projection，不是机器 verdict 源。 |
| D10 | 每个记录绑定 project identity、Workspace root、revision、Spec/Plan/approved Review/Task 和 evidence refs；runner 禁止跨 Workspace 操作。 |
| D11 | Verification 只接受 current approved Review 作为实施授权依据；Review 绑定失效时返回 inconclusive/blocked，不执行 Gate。 |
| D12 | verdict `pass` 后路由 Human Acceptance；Verification 不记录 acceptance，不生成 `summary.md`。 |

## Policy

目标：`templates/.themis/core/policies/verification.yaml`

至少声明：

- stable policy schema identifier；
- Gate type：`blocking | warning | informational`；
- execution mode：默认 sequential、blocking fail-fast；
- status：`pending | running | passed | failed | skipped | error`；
- verdict：`pass | fail | inconclusive`；
- failure categories：
  - `transient`；
  - `code_failure`；
  - `configuration_failure`；
  - `policy_conflict`；
  - `evidence_insufficient`；
  - `assumption_violated`；
  - `unknown`；
- 每类 route、是否允许 retry/repair、是否需人工裁决；
- `max_repair_attempts: 3`、允许 override 的收紧规则；
- evidence invalidation、timeout、skip 和 unavailable 规则；
- exit code：success `0`、failure `1`、escalated `2`。

`transient` 可以由 runner 自动重试有限次数；code repair 使用 repair cycle。`policy_conflict`、configuration unavailable、evidence insufficient 和 unknown 默认 fail closed，不邀请猜测性代码修复。

## Protocol

目标目录：`templates/.themis/core/protocols/verification/`

### Run record

记录 run ID、project/workspace/revision、effective policy snapshot/digest、Spec/Plan/approved Review/Task refs、implementation revision、Gate order、current gate、verdict、timestamps、attempt refs、evidence refs 和 summary。

### Gate attempt

记录 gate ID/type、exact command/args/cwd/environment declarations、status、exit code、stdout/stderr refs、timeout、failure reason/category、started/finished、revision/digest 和 superseded evidence refs。

### Repair state/handoff

记录 failed gate、failure scenario、category、attempt number/max、affected scope、constraints、evidence refs、allowed route、rerun command ID 和 Agent/用户修复摘要。Handoff 不包含未验证的“已修复”结论。

### Escalation

记录 exhaustion reason、all attempts、remaining blockers、human action、knowledge candidate payload/status：`not_requested | candidate_pending | recorded | unavailable`。

## Prompt

### `failure-classification.md`

- 先读取 observed command/exit/evidence 和 policy。
- 确定性分类可得时不得重新解释。
- 不确定时输出 `unknown` 或 `evidence_insufficient`，不能强行归为 code failure。
- 只使用 policy 枚举，给出证据引用和置信度理由。

### `repair-handoff.md`

- 生成 bounded brief：failure scenario、affected files/scope、不可违反的 Spec/Context/Plan 约束、evidence refs、allowed change boundary 和 rerun gate。
- 不扩展 Spec，不执行修复，不声称 Gate 已通过。
- capability 不可用时明确返回人工修复所需的同构结构。

## Runner

目标：`templates/.themis/core/kernel/verification/themis-verify.sh`

这是生命周期领域 runner，因此与 `verification/rules.md` 共置；跨领域 Context/Knowledge 数据服务仍位于 `core/bin/`。该位置规则在实现时同步到 Architecture。

### CLI

```text
themis-verify.sh run --workspace <path> --spec <id> [--task <id>] [--json]
themis-verify.sh classify --workspace <path> --run <id> --input <record>
themis-verify.sh resume --workspace <path> --run <id> --handoff <record>
themis-verify.sh status --workspace <path> --run <id>
themis-verify.sh render --workspace <path> --run <id> --output <verify.md>
```

### `run`

1. 校验 Workspace、manifest、Spec/Plan/approved Review refs、implementation revision 和 policy。
2. 确认 Review authorization 仍绑定 current Spec/Plan；失效时不执行 Gate。
3. 合成并保存 effective policy snapshot；不得允许 override 弱化 hard gate。
4. 将 manifest command `null` 记录为 unavailable/inconclusive，不发明命令。
5. 按 policy 顺序执行 Gate；保存 exact command、stdout/stderr 和状态。
6. 首个 blocking fail/error 停止，写 Gate attempt、Run 和 repair/escalation route。
7. 所有 blocking Gate 通过且 evidence 充分才输出 `pass`，并路由 Human Acceptance。

### `classify`

- 校验分类记录只引用当前失败 attempt。
- 确定性原因与 Prompt 分类冲突时拒绝写入。
- 写入 failure category 和 route，不改变命令 evidence。

### `resume`

1. 校验 handoff、attempt 和 source revision。
2. 如果代码/config/schema 变化，使受影响 evidence 标记 superseded/invalidated。
3. 原子增加 repair attempt；不能由新进程重置。
4. 从失败 Gate 重跑，并按依赖关系重跑后续受影响 Gate。
5. 成功则继续 pipeline；失败则再次分类/repair，直到 policy limit。
6. limit 耗尽写 escalation、返回 JSON、exit 2。

### `status` / `render`

- `status` 只读返回当前机器状态。
- `render` 从 Run/Gate/Evidence 确定性生成 `workspace/specs/<spec-id>/verify.md`；Markdown 不反向同步。

## Knowledge handoff

- escalation payload 使用 P5.5 `verification_failure` source contract。
- Knowledge recorder 可用时只调用 record，不执行 promote。
- record 成功后保存 candidate ID/evidence digest。
- capability 缺失或失败时 Run 保存完整 `candidate_pending`，不得输出 `recorded`。
- 任意路径均禁止直接写 `workspace/context/`。

## 目标文件

### Core assets

- `templates/.themis/core/policies/verification.yaml`
- `templates/.themis/core/protocols/verification/{run,gate-attempt,repair-state,escalation}-schema.yaml`
- `templates/.themis/core/templates/{failure-classification,repair-handoff}.md`
- `templates/.themis/core/templates/verify.md` 或 projection protocol
- `templates/.themis/core/kernel/verification/themis-verify.sh`
- `templates/.themis/core/kernel/verification/rules.md`
- `templates/.themis/core/kernel/orchestrator/rules.md`

### Tests and checks

- `bin/themis-template-check.sh`
- `tests/template-contract/test.sh`
- `tests/verification-recovery/test.sh`
- `tests/init/test.sh`

### Design/release

- `docs/design/{architecture,workflow}.md`
- `docs/design/core/kernel/{orchestrator,verification,knowledge}.md`
- `docs/design/core/{policies,protocols,templates}.md`
- `docs/design/workspace/overview.md`
- `docs/plan/65-verification-enhancement/README.md`（添加 expanded/superseded 注记）
- `docs/plan/README.md`
- `CHANGES.md`
- Core/Bundle version files

## Task DAG

| Task | 内容 | 依赖 |
|---|---|---|
| VER-01 | Policy 和四类 Protocol | 无 |
| VER-02 | 分类与 repair Prompt | VER-01 |
| VER-03 | Run/Gate execution 与 evidence persistence | VER-01 |
| VER-04 | classify/resume、attempt persistence、invalidation | VER-02、VER-03 |
| VER-05 | exhaustion、exit 2、Knowledge handoff | VER-04、P5.5 record 可用接口 |
| VER-06 | verify.md renderer 和 drift/read-back | VER-03 |
| VER-07 | rules、template checks、module TAP | VER-04、VER-05、VER-06 |
| VER-08 | 正式设计、版本和全量回归 | VER-07 |

## 验证矩阵

| 场景 | 预期 |
|---|---|
| 全部 blocking pass | verdict pass，evidence 完整，exit 0。 |
| 首个 blocking fail | 后续 blocking Gate 未执行，repair_required 持久化。 |
| warning/info fail | 按 policy 记录，不错误聚合为 blocking fail。 |
| null command | unavailable/inconclusive，不发明命令。 |
| deterministic classification | Prompt 不可覆盖 observed category。 |
| semantic classification | 枚举外/无证据分类被拒绝。 |
| transient | 只按 policy 自动重试，不消耗 code repair cycle。 |
| code repair | 外部修改后 resume，旧 evidence invalidated，失败 Gate 重跑。 |
| three repair cycles | 初次失败后恰好允许 3 次 repair/rerun。 |
| exhaustion | escalation 持久化，JSON 状态一致，process exit 2。 |
| restart | attempt 不重置，不重复 Run/Gate identity。 |
| policy conflict/unavailable | fail closed，不生成猜测性 repair。 |
| knowledge available | 只记录 candidate，不直接 Context 写入。 |
| knowledge unavailable | Run 保留 candidate_pending，未谎报 recorded。 |
| interrupted write | 状态恢复或保留 recovery path，无半份 machine state。 |
| project isolation | 相邻 Workspace 和 Core 零变更。 |
| verify projection | 稳定、可重建、手改可检测或覆盖前被拒绝。 |

## 确认门禁

用户确认本扩展索引前，不得创建 Verification policy/protocol/runner/tests 或修改正式设计。P5.5 未实现时可以先完成 runner，但 Knowledge 集成测试必须使用 unavailable fallback，不能伪造 candidate。
