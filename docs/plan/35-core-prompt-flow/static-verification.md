# Plan 35 Markdown-first 人工静态核验证据

> 日期：2026-08-03
> 当前范围：replacement Plan 35 的 Markdown-first Prompt、Policy、Capability、template、Workspace、Context、人工 replay 与 acceptance 合同
> 当前结论：人工静态核验和十六场景 replay 已完成；三十二条验收标准中 criteria 1–31 有当前证据，criterion 32 保持 `PENDING USER RE-ACCEPTANCE`

## 1. 核验边界

本证据通过文件树观察、逐文件阅读、迁移分片复核、引用追溯和 Git 工作树观察，人工检查：

- Markdown 文件树、短入口与按需 references；
- 字段合同、closed vocabulary、Capability/Profile binding；
- 自然语言控制规则对旧 YAML 合法组合的逐项迁移覆盖；
- artifact、Workspace、retention、Review、Verify、failure 与 assurance 不变量；
- cutover 后旧 YAML 和 legacy flat template 是否仍作为活动表示存在。

项目不使用 Python，本次没有创建 Python、Shell parser、一次性 validator 或其他临时项目脚本。自动项目核验只允许由已批准并已实现的公开 Themis Go CLI 提供；当前仓库没有对应命令，因此：

```text
automated-go-check: unavailable
```

本证据不证明 strict Schema、canonical serialization、digest 计算、Policy evaluation、state recording、Invocation hosting、deterministic write、transition、current pointer、invalidation、termination 或 recovery 已由机器运行。缺少对应 runtime evidence 时，文件存在、聊天内容、Agent report 或人工观察都不能替代机器执行事实。

2026-07-31 的 YAML-era 核验继续只作为历史事实保留，不作为本次结论输入。迁移前工作树基线、用户既有修改和 cutover 删除集均由 [迁移核验索引](migration-parity.md) 及其分片保存；本轮没有改写这些迁移观察或未裁决 GAP。

## 2. 核验输入与迁移门禁

任务 10–11 只读复核以下已闭环证据：

- [基线](migration-parity/baseline.md)：冻结旧表示、dirty `main` 基线和旧证据适用边界；
- [跨模块权威](migration-parity/authority.md)：一个短入口与十个 references；
- [自然语言 Policy](migration-parity/policy.md)：98 个旧 YAML 合法组合的逐项双向人工映射；该数字只描述历史迁移基线；
- 当前 Review owner closure amendment：为既有 `plan-check` 与 `review-projection` owner 补齐 simple/full 各一条 owner-specific status/rule，并定义 exact Feedback binding 与 separate resolution observations；
- [Global Rule 与公共入口](migration-parity/control-entry.md)：常驻 Rule、六个 references 和唯一公共 Skill；
- [Intake 与 Planning 模板](migration-parity/intake-and-planning-templates.md)；
- [Review 与 Delivery 模板](migration-parity/review-and-delivery-templates.md)；
- [Capability 合同](migration-parity/capabilities.md)；
- [Core、Workspace 与 Context](migration-parity/core-workspace-context.md)；
- [全局切换](migration-parity/cutover.md)：旧表示删除、消费者切换和 scoped re-review。

九个分片当前“未裁决 GAP”均为“无”。该事实允许建立 cutover 后的静态证据，但不替代当前十六场景 replay、acceptance audit 或用户重新接受。

## 3. Markdown-first 表示与宿主例外

| 人工观察 | 实际结果 | 结论 |
|---|---|---|
| `templates/.themis/**/*.yaml` | 活动产品 YAML 数量为 0 | 通过 |
| 旧 27 个 YAML | 已由 [cutover 删除矩阵](migration-parity/cutover.md#27-个-yaml-删除矩阵) 逐项映射并删除 | 通过 |
| 旧 13 个 flat Markdown templates 与 `.gitkeep` | 已由 [cutover 删除矩阵](migration-parity/cutover.md#13-个-flat-markdown-template-与-gitkeep-删除矩阵) 逐项映射并删除 | 通过 |
| 公共 `templates/.claude/skills/themis/SKILL.md` frontmatter | 只有 `name` 与 `description` | 通过，属于 Claude Code 宿主发现元数据 |
| 产品语义表示 | 位于中文自然语言 Markdown 正文、Policy references、Capability contracts 和 templates | 通过 |
| 活动 Guidance 语言 | 根 `CLAUDE.md` 与 `templates/.themis/CLAUDE.themis.md` 的说明性正文使用中文；stable identities、paths、fields、statuses 与 code blocks 保持原值 | 通过 |

公共 Skill 的最小 frontmatter 不是 Themis 产品 YAML contract。当前自然语言 Policy references 未使用 YAML/JSON route fragment、固定可解析行格式、Markdown DSL 或 parser instruction。

## 4. Authority、Global Rule、Policy 与 Workspace 体积

以下行数是 cutover 后的人工文件观察，不是 Go CLI 输出。目标上限来自重构计划；未单设上限的 package 只记录实际结构与最大文件。

| Package | 文件结构 | 当前行数观察 | 计划上限 | 结论 |
|---|---|---|---|---|
| Current Plan 35 authority | 1 个 dated entry + 10 个 references | entry 107；references 最大 191；合计 1422 | entry 180；每个 reference 220 | 通过 |
| Global Rule | `rules.md` + 6 个 references | entry 96；references 最大 81；合计 519 | entry 140；每个 reference 180 | 通过 |
| 唯一 Policy | `README.md` + 7 个 shared-topic refs + 6 个 phase-route refs | entry 62；shared refs 最大 95；route refs 最大 141；合计 951 | 未单设 package 上限 | 已按主题/阶段拆分 |
| Core/Workspace/Context | Core entry、Workspace entry/project/5 refs/catalog、Context protocol entry/5 refs | Core entry 29；Workspace entry 31；Context protocol entry 25；合计 686 | 120 / 140 / 120 | 通过 |

Authority entry 没有复制三十二条验收矩阵或历史 98 个组合；Global Rule 没有复制 Capability-specific status routes；Policy entry 没有把六个阶段 references 描述为多个 Policy；Workspace 与 Context entry 没有承载字段全集。Agent 可以从短入口按当前 gate 和主题加载最小 reference 集。

## 5. Capability、Agent Profile 与公共入口固定集合

人工文件树和合同复核结果：

- 公共治理 Skill 恰好一个，identity 为 `themis`；
- internal Capability contracts 恰好十六个，`README.md` 不计入 Capability；
- Agent Profile contracts 恰好四个，分别为 `semantic-readonly`、`independent-checker`、`human-dialogue`、`implementation-writer`；
- [Capability 绑定](../../../templates/.themis/core/policies/references/capability-bindings.md) 为十六个 Capability 声明固定 authority scope、Profile、path/profile domain、legal status 和 materialization target；
- 只有 `themis-impl` 绑定 `implementation-writer`；
- `request-intake` scope 只拥有 `themis-current-request-dialogue`，`themis-failure-learning` 可按已验证 binding 在两个 scope 运行，其余 lifecycle Capability 不扩张 scope；
- 十六个 Capability 均包含 identity/binding、输入、合法状态、结果字段、工具/权限和停止边界；六类固定合同章节共观察到 96 个章节；
- 十六个 Capability 文件未观察到 fenced YAML；
- 每个 Capability 都明确禁止调用其他 Capability 或 Agent、选择下一 route、扩张自身 Profile 或保留跨 Invocation authority。

Capability proposed result 不是 authority。公共 Skill 的加载链保持 `rules.md → 唯一 Policy → gate references → one Capability + fixed Profile → one temporary Invocation`。

## 6. 自然语言控制规则覆盖

[Policy 迁移分片](migration-parity/policy.md) 对已删除 YAML 中观察到的 98 个合法 route identity 逐项记录了新自然语言 owner、next、旧 control action、guard、invalidation、failure class 与迁移观察：

| 阶段 | 历史 YAML 迁移观察数 | 当前自然语言 owner |
|---|---:|---|
| Intake | 3 | `routes/intake.md` |
| Understanding | 8 | `routes/understanding.md` |
| Planning | 20 | `routes/planning.md` |
| Review | 24 | `routes/review.md` |
| Delivery | 31 | `routes/delivery.md` |
| Learning | 12 | `routes/learning.md` |
| 历史合计 | 98 | 六个 phase-route references |

当前活动 Policy 另含四个 owner-specific Review 结果：simple/full 的 `needs-plan-check` 与 simple/full 的 `needs-review-projection`。它们闭合已批准的七 owner 模型在旧表示中遗留的 reachability 缺口，因此当前 Review 自然语言结果为 28；若仅为人工覆盖核对而枚举，当前六阶段总数为 102。102 不是产品 identity、永久常量、固定 route table、Markdown DSL 或 Go CLI 输入。

人工复核结论：

- 历史 98 个来源组合都以 `capability + selected_path + profile + status` 定位到一个独立自然语言规则；`authority_scope` 由 Capability/Policy binding 固定，不是第五个 route key；
- 当前新增四条 owner-closure 规则使用同一四部分 identity，未增加 route-key dimension；
- 迁移清单没有为同一 durable facts 记录两个冲突 control action；
- quick-only status 只在 `simple/lightweight` 出现，full path 使用自己的 closed status；
- `themis-complexity-assessment/simple-qualified` 的 `full_path_required` guard failure 明确保持 sticky full、进入 full path 并失效 quick downstream；
- `dormant-read-only` 不是 Capability status、route dimension 或第五种 disposition；
- 每项规则都有 next/control action、适用 guard、invalidation、failure class 和共同 fail-closed 停止条件；
- zero/multiple match、unknown status、wrong Profile/scope/path、stale/duplicate/late result、illegal payload 和 materialization failure 不能由近似文本或 `recommended_route` 补全；
- 历史 98 只是一项已删除 YAML 的迁移覆盖观察值；当前人工枚举 102 只用于当前合同覆盖核对。二者都不是产品 identity、永久常量、固定 Markdown 行数、route table、DSL 或 Go CLI 输入。

当前 Policy 使用完整中文控制句和主题标题，不要求 parser、固定 route table 或机器行格式。

## 7. Artifact、Workspace 与 retention

[Templates package](../../../templates/.themis/core/templates/README.md) 与 Workspace references 的人工观察如下：

- paired semantic families 恰好十一类，共 22 个 `record.md` / `content.md` 文件；
- structured Markdown records 恰好七类；
- Context aids 两个，Templates README 一个；分层 template tree 合计 32 个 Markdown 文件、1938 行；
- legacy flat pair、YAML template 与 templates `.gitkeep` 均不存在；
- 十八个活动 record/structured 模板已删除迁移期“尚未切换为 current authority”说明，并明确区分活动 Prompt-level 模板与具体 revision 在 Policy-controlled materialization、observation、reread 及适用 pointer gate 完成前的 candidate 状态；
- completed Questioning round 是 per-round immutable pair，未回答 proposal 不创建 completed round，Current Questioning Pointer 单独更新；
- artifact revision、Invocation identity、attempt identity、operation identity、current pointer 与 incomplete operation 保持分离；
- paired revision 任一 half 缺失，或 identity/digest/scope/source/artifact binding 不一致时 whole revision invalid；
- target operation 闭合枚举恰好为 `create-lifecycle | update-current-request | no-change`；
- multi-target partial success 保持 `open + incomplete`，保留已成功 target，只从 `remaining_target_identities` 恢复；
- lifecycle completion 后按 target 独立记录 completion observation 并冻结 binding；
- 只有全部 associated lifecycle-bearing targets observed completed，Intake 才保持 disposition `assigned` 并派生 retention `dormant-read-only`；
- dormant Intake 不可 attachment、Invocation、mutation、reactivation 或 recovery，未来消息必须创建新 Intake；
- `request-intake` 与 `lifecycle` 只能交换 stable immutable references，不共享动态 state、Execution Identity、failure budget、continuation、pointer 或 completion state。

## 8. Review、Verify、failure 与 assurance

人工合同追溯结果：

- Review Approval 绑定 current assignment decision、Current Request、Questioning、设计约束、Assessment、selected path/profile、checked Plan、Plan Check、Review Projection、Review Check、review feedback closure、Policy binding、baseline 与 expected delta；
- Review Feedback affected owner 的闭合集合恰好七个：`current-request-dialogue | questioning | specification | simple-planning | planning | plan-check | review-projection`；owner-specific status 必须与 `affected_owner` 唯一一致；
- 七个 owner re-entry 都绑定 exact Feedback revision 与 durable owner continuation。只有 owner-specific 成功结果完整物化并重读后，控制层才能先记录并重读 separate resolution observation，再记录并重读引用它的 unresolved-set update observation；完成两步后新 state view 才能移除 exact Feedback。文件存在、Invocation 开始、等待、blocked、needs-*、grounding 或 escalation 都不能推断 resolved；
- Review 必须在 Impl 前完成并形成 current explicit Approval；
- Verify 顺序固定为 `themis-impl → independent themis-verification`；writer 不自验；
- Impl 与 Verification 使用 separate Invocation/attempt identity，但共享 current Approval、Plan task、baseline、expected delta、Plan Task Execution Identity 与 cumulative failure budget；
- Acceptance `implementation-defect` repair 复用同一 Plan task identity/budget，修复后必须重新 independent Verification；
- Request Intake Execution Identity 与 lifecycle Plan Task Execution Identity 隔离，各自最多三次 counted failure；第三次终止并禁止同一 identity 的第四次 Invocation；
- retry、resume、Agent/model/worktree change 或 simple→full escalation 不清零 identity/budget；
- Failure Learning scope-bound、non-blocking、non-recursive、candidate-only；自身失败不阻塞主 continuation，也不递归；
- Summary 只在 current Verification `passed` 且 current Human Acceptance `accepted` 后产生 pair；pair fully materialized、reread 并成为 current 后，completion 才作为单独 observation 记录；
- [Assurance 边界](../../../templates/.themis/core/policies/references/assurance-boundary.md) 保留三项 Plan 36 `unavailable`、四项 Plan 37 `unavailable` 和一项无 runtime evidence 时禁止机器执行声明，共八项 unavailable/forbidden 边界；
- Plan 80 multi-Agent 与 Plan 90 Attribution 不进入 Policy completion gate。

## 9. Markdown-first 人工 replay 与 acceptance audit

[人工流程重放](manual-replay.md) 与十六个独立场景文件按当前自然语言 Policy 完成人工重放：

- replay index 为 60 行，未超过计划的 160 行上限；
- scenario 文件恰好十六个，合计 896 行；
- 每个 scenario 恰好包含十一项标准观察标题，合计 176 个标准标题；
- 场景 07 以 current `plan-revision-p1` 与 prior `approval-revision-a1` 为 durable facts，代表性 `planning` owner re-entry 物化新 `plan-revision-p2`，并分别观察 Feedback 路由 invalidation 先使旧 Approval stale，以及新 Plan bindings 如何阻止其复活；`plan-check` / `review-projection` owner 不伪造新 Plan；
- 场景 09 分别实例化单 half、`record.md.content_digest != content.md observed digest` 与完整 pair 后 pointer update failure；前两者 whole revision invalid，后者只形成 valid non-current revision，且人工输入不冒充 digest runtime；
- 每个 scenario 都从 durable facts、Capability/Profile/scope、合法 status、自然语言规则标题、control action、物化、pointer/gate、失效、failure class 与缺失机器保证建立结论；
- 所有 scenario 均以 `PASS（人工合同重放）` 记录 Prompt-level 唯一声明式结果，但不把文件存在或人工判断冒充 runtime execution；
- 当前 replay 不引用已删除 YAML 作为 authority，也不建立固定 route table、Markdown DSL、parser instruction 或隐藏 Go CLI 输入；
- 自动 Themis Go CLI replay 保持 `unavailable`。

[验收审计](acceptance-audit.md) 为 74 行，并逐项映射权威合同、Policy、Capability/Profile、templates、Workspace、静态观察和当前 replay：

- criteria 1–31 均有当前 Markdown-first contract、人工静态观察或十六场景 replay 证据；
- criterion 31 只绑定本文件、当前 replay index 与十六个 scenario，不复用 2026-07-31 YAML-era PASS；
- criterion 32 保持 `PENDING USER RE-ACCEPTANCE`；
- 历史 2026-07-31 acceptance 只作为历史事实，不替代本次 representation amendment 的用户审阅与明确重新接受；
- 用户沉默、assistant 判断、reviewer 报告或系统通知均不构成重新接受。

## 10. 工作树与 whitespace 观察

本轮终审修复只处理已验证的当前冲突：十八个活动 record/structured 模板的迁移期 authority wording，以及根 `CLAUDE.md` 与 `templates/.themis/CLAUDE.themis.md` 的中文 guidance 合规；随后刷新本文件与 `evidence-summary.md`。没有 reset、restore、clean、stash、commit、push、worktree 创建或换行标准化。当前 `main` 工作树继续保留 migration 前后的全部既有未提交修改。

`git status --short` 只用于读取版本控制状态。当前 replacement Plan 35 authority、Policy、Rule、Capability、templates、Workspace/Context、guidance、计划状态和 evidence 仍处于未提交修改/新增/删除状态；旧 YAML 与 flat template 的 cutover 删除仍保留在工作树中。Plan 36/37/80/90 只保留暂停、边界或重基线 notice，没有开始对应实现。

`git diff --check` 只检查版本控制 diff hygiene，不是 Themis 项目 validator。自动项目 whitespace/link/contract 检查仍为 `unavailable`；Git 的 LF→CRLF working-copy 提示不构成 whitespace error，本轮没有执行换行标准化。

## 11. Fresh read-only review

任务 10 的独立 read-only reviewer 曾发现三条 `templates/...` 相对链接多退一级；链接修正后的 scoped re-review 返回 `No findings` 与 `Verdict: APPROVED`。

Task 11 完成后的 current-tree read-only reviewer 随后发现一个有效 High finding：本文件与 `evidence-summary.md` 仍把 replay 和 acceptance remapping 写成未完成，与已重建的 `manual-replay.md` 和 `acceptance-audit.md` 冲突。该 finding 已通过本次证据刷新修正：Task 11 明确完成，criteria 1–31 有当前证据，criterion 32 单独保持 pending。

同一 reviewer 报告的日期 finding 不适用：reviewer 以 2026-08-02 为运行日期判断 2026-08-03 是未来日期，而当前核验日期实际为 2026-08-03。证据日期保持不变；该误判不影响合同、replay 或 acceptance 结论。

后续 stdin-only current-tree reviewer 返回 `CHANGES REQUIRED`，并提出两项有效 finding：十八个活动模板仍声称“尚未切换为 current authority”，以及两份活动 Guidance 的说明性正文仍为英文。前者混淆 representation cutover 与具体 revision currentness，后者违反 `AGENTS.md` 的中文 Markdown 规则。本轮已分别改为活动 Prompt-level 模板 + candidate revision gate 表述，并将根 `CLAUDE.md` 与安装后的 `CLAUDE.themis.md` 翻译为中文，同时保留 stable English tokens。

修复后的 stdin-only re-review 首次仍沿用了 reviewer 自身过期的 2026-08-02 日期上下文，只重复报告 2026-08-03 为“未来日期”，未提出合同 finding。协调环境随后直接观察到 `2026-08-03 08:20:18 +0800`，并把该权威 review date 显式提供给同一只读审查范围；该次 template/Guidance scoped re-review 返回 `No findings.` 与 `Verdict: APPROVED`。

随后针对完整重新接受门禁的独立 review 发现两个 Medium replay coverage gap：场景 07 没有实际建立 prior Approval、新 Plan revision 与 stale binding observation；场景 09 只写 generic binding mismatch，没有显式实例化权威要求的 digest mismatch。本轮已按 current authority 补齐：场景 07 以 `plan-revision-p1`、`approval-revision-a1` 和新 `plan-revision-p2` 重放 Feedback invalidation、Plan pointer 更新与旧 Approval 不可复活；场景 09 拆分单 half、明确 digest mismatch 和 pointer update failure 三个 variant，并保持 digest/runtime `unavailable` 边界。它们不改变产品语义，只补齐既有权威枚举的人工观察。

补齐后的 current-tree stdin-only 完整门禁 re-review 显式使用 `2026-08-03 +0800`，输入 current authority、Review/materialization Policy、replay index、十六个 scenario、acceptance audit、静态证据与 evidence summary。Reviewer 返回 `No findings.` 与 `Verdict: APPROVED`；该 verdict 支持 criteria 1–31 的技术/合同证据闭合，不构成 criterion 32 的用户重新接受。

Reviewer 始终只读，没有修改文件、commit、push 或写 migration evidence。此前误用隔离 worktree 的 reviewer 调用不作为本轮方法继续采用；本轮只在当前 dirty `main` 执行只读观察。Reviewer 结论只作为独立技术复核，不构成 criterion 32 的用户重新接受。

## 12. 静态与 replay 结论

当前 Markdown-first 文件树与已批准 replacement Plan 35 产品语义在 Prompt-level 合同、人工静态观察和十六场景 replay 层面一致：

- Intake-first、immutable Source Event 和双 scope 隔离仍有活动 owner；
- 十六个 Capability、四个 fixed Profile、唯一公共 Skill、唯一 Global Rule 和唯一自然语言 Policy 保持闭合；
- simple/full 两条 Plan 前路径汇合到同一 Unified Plan、Review、Approval 与交付合同；
- Review-before-Impl、`Impl → independent Verification`、Human Acceptance、Summary 与 separate completion observation 均未改变；
- ordered materialization、whole-pair invalidation、separate pointer、scope-local 三次失败预算、Failure Learning 和 retention 不变量均可追溯；
- 旧 YAML、legacy flat templates、Python assertions 和隐藏 route DSL 没有作为当前产品保证继续存在；
- 缺失机器能力被明确记为 `unavailable`，没有被人工观察冒充。

因此，Markdown-first 表示重构已完成，criteria 1–31 的技术/合同标准有当前证据。Criterion 32 继续保持 `PENDING USER RE-ACCEPTANCE`，直到用户审阅当前静态证据、十六场景 replay、acceptance audit 与 evidence summary 并明确重新接受。Plan 36/37 继续暂停。

## 13. 自动 Go CLI 检查状态

```text
unavailable
```

当前不存在已批准并已实现的 Themis Go CLI Markdown 合同、链接、Policy parity、Workspace currentness、replay 或 whitespace 核验命令。未使用 Python、Shell parser、一次性 validator 或虚构子命令替代。
