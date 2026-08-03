# Plan 35 实施与核验证据概述

> 状态：Markdown authority cutover、Markdown-first 人工静态核验、十六场景人工 replay 与三十二条 acceptance remapping 已完成。Criteria 1–31 有当前证据；criterion 32 保持 `PENDING USER RE-ACCEPTANCE`，等待用户审阅并明确重新接受。

## 当前实现概述

Replacement Plan 35 当前以中文自然语言 Markdown 合同表示，主要包括：

- 独立的 `request-intake` 与 `lifecycle` authority scope；
- 所有外部消息的 immutable Source Event 与 Intake-first interception；
- 用户确认、来源可追溯的 Current Request；
- 十六个 internal Capability 与四个 fixed Agent Profile；
- 唯一公共 `themis` Skill、唯一 Global Rule 与唯一自然语言 Policy；
- simple/full 两条 Plan 前路径和统一 Plan family；
- Review、explicit Approval、Impl、independent Verification、Human Acceptance 与 Summary；
- immutable semantic revision、完整物化、separate current pointer、失效与恢复边界；
- Intake/lifecycle 隔离的三次 counted failure budget 与 scope-bound Failure Learning；
- lifecycle completion 后的逐 target freeze、all-target dormancy 与 `dormant-read-only` retention；
- Markdown-first Workspace、Context、module contract、活动 Prompt-level template 与中文安装 guidance。

活动 `templates/.themis` 产品树不再包含 YAML。公共 `themis/SKILL.md` 只保留 Claude Code 宿主发现所需的 `name` 与 `description` frontmatter；产品语义全部位于 Markdown 正文。

## 当前核验证据

### 迁移证据

[迁移核验索引](migration-parity.md) 与九个分片记录了基线冻结、authority/Policy/Rule/template/Capability/Workspace candidates、统一 cutover 和 independent read-only review。九个分片的未裁决 GAP 均为“无”。

该证据证明旧表示已逐项迁移并完成 authority cutover，不替代新的静态核验、replay 或用户接受。

### Markdown-first 静态核验

[静态核验证据](static-verification.md) 已完成当前表示的人工复核，观察到：

- `templates/.themis` 活动产品 YAML 数量为 0；
- current authority、Global Rule、Policy、Workspace 与 Context 已拆为短入口和按需 references，并满足已设入口体积目标；
- 一个公共 Skill、十六个 Capability、四个 Profile 和唯一 writer mapping 保持闭合；
- Capability contracts 不含 fenced YAML，并保留输入、状态、输出、权限与停止合同；
- 旧 YAML 的 98 个合法组合都能在迁移清单中定位到自然语言规则及其控制语义；当前 Policy 另以四条 owner-specific Review 规则闭合既有 `plan-check` / `review-projection` owner，人工枚举当前总数为 102，但该数字不是产品 identity、route table、DSL 或 Go CLI 输入；
- Review Feedback resolution 需要 exact Feedback/owner-continuation binding、owner 成功结果的完整物化与重读、separate resolution observation，以及后续 unresolved-set update observation；
- 十一类 paired family、七类 structured record、三种 Intake target operation 和 retention/recovery 不变量保持一致；
- Review-before-Impl、`Impl → independent Verification`、双 scope failure budget、三次上限、Failure Learning 和八项 assurance 边界保持一致；
- 自动 Themis Go CLI 核验为 `unavailable`，未使用 Python、Shell parser、一次性 validator 或虚构子命令替代。

这项结论只证明人工静态一致性，不证明 Policy evaluation、recording、digest、write、pointer、transition 或 recovery 已由机器执行。

### 人工流程重放

[人工流程重放索引](manual-replay.md) 为 60 行，链接恰好十六个当前 Markdown-first scenario。十六个场景合计 896 行，每个场景恰好包含十一项标准观察标题，总计 176 个标准标题，并分别覆盖 Intake-first、双 scope、multi-target、Review owner closure、代表 owner 新 Plan 使旧 Approval stale、sticky full、paired half-write/digest mismatch/pointer failure、invalid result、失败预算、Failure Learning、completion retention 与 durable recovery。

所有场景都明确区分 Prompt-level 人工合同结果与缺失机器保证。自动 Themis Go CLI replay 为：

```text
unavailable
```

2026-07-31 的 YAML-era replay 继续作为历史事实保留，但不作为当前 PASS 依据。

### 验收审计

[当前验收审计](acceptance-audit.md) 为 74 行。Criteria 1–31 已映射到当前 Markdown contract、人工静态观察或十六场景 replay；criterion 31 绑定当前证据，不复用旧 YAML PASS。

Criterion 32 保持：

```text
PENDING USER RE-ACCEPTANCE
```

历史 2026-07-31 acceptance 不覆盖本次 Markdown-first representation amendment。只有用户审阅当前静态证据、十六场景、acceptance audit 与本概述并明确重新接受后，criterion 32 才可改变。

## 当前状态

- Markdown authority cutover：完成；
- Markdown-first 人工静态核验：完成；Policy package 951 行，Templates package 1938 行；
- Markdown-first 十六场景 replay：完成；index 60 行，十六个场景、176 个标准观察标题；
- 三十二条 acceptance audit：完成重映射；criteria 1–31 有当前证据；
- Criterion 32：`PENDING USER RE-ACCEPTANCE`；
- Fresh read-only review：先发现本文件与静态证据的 stale Task 11 状态冲突，本轮已修正；reviewer 的 2026-08-03 “未来日期” finding 基于过期的 2026-08-02 日期上下文，不适用；后续 stdin-only reviewer 又发现十八个活动模板的 stale authority wording 与两份英文 Guidance，修复后的 scoped re-review 在显式提供 `2026-08-03 +0800` 后返回 `No findings` 与 `Verdict: APPROVED`；随后完整重新接受门禁 review 发现两个 Medium replay coverage gap，本轮已在场景 07 补齐新 Plan/旧 Approval stale 的 durable observation，并在场景 09 补齐明确 digest mismatch，与受影响的 replay/audit evidence 一并刷新；补齐后的 current-tree stdin-only 完整门禁 re-review 返回 `No findings` 与 `Verdict: APPROVED`，该结论只支持 criteria 1–31，不替代用户重新接受；
- 用户重新接受：待定；
- Plan 36/37：继续暂停。

Markdown-first 表示重构已完成；31 项技术/合同标准通过；criterion 32 等待用户审阅并明确重新接受。

用户沉默、assistant 判断、reviewer 报告或系统通知都不构成重新接受。

## 能力边界

当前未实现或未声称以下能力可用：

- Plan 36 strict Schema、canonicalization、validator、issue taxonomy、semantic oracle 与 fixtures；
- Plan 37 Policy evaluator、Invocation host、state recorder、deterministic writer、command execution 与 native recovery；
- Plan 80 multi-Agent execution；
- Plan 90 Attribution completion gate；
- upgrade、runtime migration、compatibility layer 或 Shell fallback。

## 关联证据

- [迁移核验索引](migration-parity.md)：Markdown authority migration 与 cutover；
- [静态核验证据](static-verification.md)：当前 Markdown-first 人工静态一致性；
- [人工流程重放](manual-replay.md)：当前 Markdown-first 十六场景 replay 索引与 coverage matrix；
- [验收审计](acceptance-audit.md)：当前三十二项矩阵，criteria 1–31 PASS，criterion 32 等待用户重新接受。
