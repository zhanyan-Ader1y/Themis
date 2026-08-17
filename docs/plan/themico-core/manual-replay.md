# Themico 首个可用交付：人工 replay 记录

本文档记录任务 12 执行时，用真实构建的 `themico` 二进制在一个临时仓库中逐场景手工 replay 的结果。所有命令、输入文件和输出均为真实执行产生，未凭代码推断编造。

## 0. 执行环境

- 构建命令：`go build -o themico.exe ./cmd/themico`（在 `C:/Coding/Themis/.claude/worktrees/themico-core` 下执行，commit `c168d5a47d9164bea7d33afc37b3b814ef93c2e1`）。
- 平台：`go1.26.5 windows/amd64`。
- 临时仓库根：一个空目录（下文用 `<REPO>` 表示其绝对路径），所有 `--root` 参数均指向该目录。仓库不属于本次提交范围，仅用于 replay。
- `<REPO>/inputs/` 保存本次 replay 手工编写的机器 JSON 输入文件；`<REPO>/docs/` 保存被绑定为 source 的真实文件。
- 每个场景的 `generation before/after` 通过直接列出 `<REPO>/.themico/workspace/generations/` 目录得到，不是推断值。
- 为节省篇幅，除场景 1 外，后续场景中与场景 1 结构相同的完整候选/记录 JSON 做了适度裁剪，但状态字段、issue 信息、生成号、摘要证据等关键字段均为真实输出的逐字摘录；被裁剪处以省略号标注。

九个场景严格对应 `first-usable-delivery.md` 第 7.2 节列出的顺序。场景 7（并发）之后另附两段补充复现材料，用于坐实 README 必须披露的两个已知缺陷，以及验收条目 7（assessment 绑定与 checker identity）在自动化测试中缺少的失败分支覆盖。

---

## 场景 1：design_decision 完整发布与 L1/L2/L3 读取

**目的**：走完 `init → create → confirm-type → validate → prepare publish → publish → query → inspect(depth 1/2/3)` 全链路，验证读取深度边界。

**真实输入**：
- `docs/design-source.md`（source 文件）
- `inputs/s1-candidate.json`（`candidate.CreateRequest`，`proposed_type=design_decision`，`zone=project_knowledge`）
- `inputs/s1-content.md`（含全部 7 个固定中文 L3 章节：背景与问题/决策/约束/备选方案/后果/证据与来源/重新评估条件）

**命令与真实输出**（generation before=0）：

```
$ themico init --root <REPO>
{"status":"succeeded", ..., "output":{"generation":0, ...}}

$ themico candidate create --root <REPO> --input inputs/s1-candidate.json --content inputs/s1-content.md
{"status":"succeeded", "output":{"candidate_id":"cand_2c4a5049ac3ccfc4d50ed0e36b8c3016","candidate_revision":"crev_c2b759ae5c84c1939f7a414dcd2d1ccd","status":"proposed", ...}}

$ themico candidate confirm-type --root <REPO> --confirmation inputs/s1-confirm.json
{"status":"succeeded", "output":{"candidate_revision":"crev_9fcb80db51be43fe9d8dbf921440bbfd","status":"type_confirmed","knowledge_type":"design_decision", ...}}

$ themico validate --root <REPO> --candidate cand_2c4a5049ac3ccfc4d50ed0e36b8c3016 --revision crev_9fcb80db51be43fe9d8dbf921440bbfd
{"status":"succeeded","output":{"issues":[],"ok":true}}

$ themico prepare publish --root <REPO> --candidate cand_... --assessment inputs/s1-assessment.json
{"status":"succeeded","output":{"prepare_id":"prep_37d6867a02fa09e666405cae4fc5cd8d",
  "digest":"sha256:8f024bed015b2b44c3a44064078fb4904882103484eb68fd5858d84f78f72146",
  "expected_generation":3,
  "record_id":"kr_4354caedebdf797b929f6a2201ae8338","record_revision":"rev_11bd9a12c8bac9e1660cc88e56e1139c",
  "writes":[
    {"path":"records/kr_4354.../revisions/rev_11bd.../record.json","digest":"sha256:d36f4d..."},
    {"path":"records/kr_4354.../revisions/rev_11bd.../content.md","digest":"sha256:e1c09c..."},
    {"path":"projections/kr_4354.../rev_11bd.../l1.json","digest":"sha256:56f5ef..."},
    {"path":"projections/kr_4354.../rev_11bd.../l2.json","digest":"sha256:56f5ef..."}
  ]}}

$ themico publish --root <REPO> --prepare prep_37d6867a02fa09e666405cae4fc5cd8d --approval inputs/s1-approval.json
{"status":"succeeded","output":{"generation":4,"record_id":"kr_4354caedebdf797b929f6a2201ae8338","status":"active", ...}}
```

**generation**：0 → 1（create）→ 2（confirm-type）→ 3（prepare 自身提交 prepare 工件）→ 4（publish）。

**query（zones=[project_knowledge]，content_budget_bytes=1048576）**：

```
{"status":"succeeded","output":{"generation":4,
 "candidates":[{"record_id":"kr_4354...","zone":"project_knowledge","knowledge_type":"design_decision",
   "l1":{"title":"示例设计决策","summary":"记录一次示例设计决策","triggers":["trigger-replay-1"],"tags":["design","replay"]}}],
 "trace":{"content_bytes":326,"remaining_bytes":1048250,"selected_ids":["kr_4354..."],"excluded_ids":[]}}}
```

L1 行**不含** `l2`/`l3` 字段——发现层不携带更深内容，与设计的“discovery/upgrade 边界”一致。

**inspect（record_ids=[kr_4354...]）三个深度**：

| depth | status | 是否含 l2 | 是否含 l3 | content_bytes |
|---|---|---|---|---|
| 1 | succeeded | 否 | 否 | 423 |
| 2 | succeeded | 是 | 否 | 781 |
| 3 | succeeded | 是 | 是（完整 7 章节 Markdown） | 1057 |

**observed files**：`<REPO>/.themico/workspace/records/kr_4354.../revisions/rev_11bd.../{record.json,content.md}`、`<REPO>/.themico/workspace/projections/kr_4354.../rev_11bd.../{l1.json,l2.json}` 均存在。

**已知缺陷 1 的现场证据**：对该记录的 `l1.json` 与 `l2.json` 执行 `diff`：

```
$ diff l1.json l2.json && echo "IDENTICAL"
IDENTICAL: l1.json and l2.json are byte-for-byte the same file
$ sha256sum l1.json l2.json
56f5efbe...  l1.json
56f5efbe...  l2.json
```

两文件字节完全相同（与 `prepare publish` 输出里 `l1.json`/`l2.json` 两条 `writes` 共享同一 digest 完全吻合）。详见下文"补充复现材料 A"。

**结论**：PASS，与设计预期完全一致；同时坐实已知缺陷 1。

---

## 场景 2：development_standard 完整发布与 L1/L2/L3 读取

**目的**：与场景 1 相同的链路，换用第二个知识类型，并验证 `query` 的 `types` 过滤器能在同一 Zone 内收窄。

**真实输入**：`docs/standard-source.md`、`inputs/s2-candidate.json`（`proposed_type=development_standard`）、`inputs/s2-content.md`（含 7 个固定章节：目的与适用范围/触发条件/必须执行/禁止行为/验证方法/例外策略/证据与来源）。

**generation before**：4（承接场景 1）。

```
$ themico candidate create ...   → succeeded, candidate_id=cand_8460a77d..., status=proposed
$ themico candidate confirm-type ... → succeeded, knowledge_type=development_standard, status=type_confirmed
$ themico validate ...           → succeeded, {"issues":[],"ok":true}
$ themico prepare publish ...    → succeeded, prepare_id=prep_1f20480d..., expected_generation=7,
                                     record_id=kr_e723006b..., writes 中 l1.json/l2.json digest 相同（sha256:b93171...）
$ themico publish ...            → succeeded, generation=8, record_id=kr_e723006b..., status=active
```

**generation**：4 → 5（create）→ 6（confirm-type）→ 7（prepare）→ 8（publish）。

**query（zones=[project_knowledge], types=[development_standard]）**：

```
{"status":"succeeded","output":{"generation":8,
 "candidates":[{"record_id":"kr_e723006b...","knowledge_type":"development_standard", "l1":{"title":"示例开发规范", ...}}],
 "trace":{"candidate_ids":["kr_4354...","kr_e723006b..."],"excluded_ids":["kr_4354..."],"selected_ids":["kr_e723006b..."]}}}
```

`candidate_ids` 里包含场景 1 的 `kr_4354...`，但因显式 `types` 过滤被放入 `excluded_ids`，只有 `kr_e723006b...` 进入 `selected_ids`——确定性过滤按预期工作。

**inspect 三个深度**：均 `succeeded`，depth 1 无 `l2`/`l3`（430 bytes），depth 2 含 `l2` 无 `l3`（849 bytes），depth 3 含完整 L3（1143 bytes，7 个章节标题与正文逐字匹配 `inputs/s2-content.md`）。

**结论**：PASS。

---

## 场景 3：development_experience 完整发布与 L1/L2/L3 读取

**目的**：验证第三个知识类型，且其 Zone 为 `project_experience`（与前两个类型的 `project_knowledge` 不同），坐实 Zone 隔离。

**真实输入**：`docs/experience-source.md`、`inputs/s3-candidate.json`（`proposed_type=development_experience`, `zone=project_experience`）、`inputs/s3-content.md`（7 个固定章节：背景与前置条件/观察到的现象/已确认事实/建议行动/风险与停止条件/证据与强度/适用与不适用条件）。

**generation before**：8。

```
$ themico candidate create ...   → succeeded, candidate_id=cand_beef951c..., zone=project_experience
$ themico candidate confirm-type ... → succeeded, knowledge_type=development_experience
$ themico validate ...           → succeeded, {"issues":[],"ok":true}
$ themico prepare publish ...    → succeeded, prepare_id=prep_70453ea1..., expected_generation=11,
                                     record_id=kr_703aac26...
$ themico publish ...            → succeeded, generation=12, record_id=kr_703aac26..., zone=project_experience, status=active
```

**generation**：8 → 9 → 10 → 11 → 12。

**query（zones=[project_experience]）**：

```
{"status":"succeeded","output":{"generation":12,
 "candidates":[{"record_id":"kr_703aac26...","zone":"project_experience","knowledge_type":"development_experience"}],
 "trace":{"candidate_ids":["kr_4354...","kr_703aac26...","kr_e723006b..."],
          "excluded_ids":["kr_4354...","kr_e723006b..."],
          "selected_ids":["kr_703aac26..."]}}}
```

`candidate_ids` 包含此前发布的全部三条记录（跨 Zone 都会先被列出候选），但显式 `zones=[project_experience]` 把另外两条 `project_knowledge` 记录都放进 `excluded_ids`——Zone 隔离按预期工作。

**inspect 三个深度**：均 `succeeded`，depth 3 的 L3 markdown 与 `inputs/s3-content.md` 逐字一致（1203 bytes）。

**结论**：PASS。

---

## 场景 4：类型确认后 revise 改型被拒绝

**目的**：验证 `confirm-type` 之后，`candidate revise` 试图改变 `proposed_type` 会被拒绝，且候选的类型与 revision 保持不变。

**真实输入**：新建候选 `cand_1283a73c60506b55b0c4a1246f17e610`，`proposed_type=design_decision`，`confirm-type` 后得到 `crev_9a3a1d95567797d7d892d3cbc2b65bd3`（`knowledge_type=design_decision`）。随后 `inputs/s4-revise.json` 携带**同一** `expected_revision`，但 `proposed_type` 改为 `development_standard`（与 `design_decision` 同 Zone `project_knowledge`，排除“Zone 不兼容”这条独立失败路径的干扰，确保测试的是类型不可变本身）。

**generation before**：12 → create（13）→ confirm-type（14）。

**命令与真实输出**：

```
$ themico candidate revise --root <REPO> --input inputs/s4-revise.json --content inputs/s4-revise-content.md
{"schema":"themico-command-result","command":"candidate revise","status":"validation_failed",
 "issues":[{"code":"validation_failed","path":"",
   "message":"themico candidate type is immutable: proposed type cannot change after confirmation"}]}
```

**generation after**：14（未变化，被拒绝的 revise 未产生任何提交）。

**candidate inspect 复核**：

```
$ themico candidate inspect --root <REPO> --id cand_1283a73c60506b55b0c4a1246f17e610
{"status":"succeeded","output":{"knowledge_type":"design_decision","candidate_revision":"crev_9a3a1d95567797d7d892d3cbc2b65bd3","status":"type_confirmed", ...}}
```

`knowledge_type` 仍为 `design_decision`，`candidate_revision` 与 confirm-type 之后完全一致——改型请求没有产生任何可见效果。

**结论**：PASS，`candidate.ErrTypeImmutable` 生效。

---

## 场景 5：source drift 阻止 validate、prepare 或 publish

分三部分复现 drift 发生在三个不同时间点时，三个不同的门都能独立拦截。

### 5A/5B：drift 发生在 validate 之前，同一候选又拿去 prepare

**真实输入**：`docs/s5-source.md` 初始内容绑定进候选并 confirm-type。

```
$ themico validate ...（source 未改动）
{"status":"succeeded","output":{"issues":[],"ok":true}}

$ 覆写 docs/s5-source.md 为不同字节（sha256:8d57ab5b...）

$ themico validate ...（source 已改动）
{"status":"validation_failed","output":{"issues":[{"code":"source.stale","path":"sources[0]","message":"source bytes changed after binding"}],"ok":false}}

$ themico prepare publish ...（同一候选，source 仍处于 drift 状态）
{"status":"validation_failed","issues":[{"code":"validation_failed","message":"themico store validation failed: candidate failed deterministic validation"}]}
```

`prepare publish` 内部会先调用与独立 `validate` 命令相同的 `validate.Candidate`，因此即使不显式跑 `validate`，`prepare publish` 自身也会独立拦截 drift。

**generation**：两次失败均未推进（14 → 16，两次是 create+confirm-type 各自的提交，两次失败的 validate/prepare 本身不提交任何 generation）。

### 5C：drift 发生在 prepare 成功之后、publish 之前

**真实输入**：`docs/s5c-source.md`，候选 `cand_a5e480cab41b5529fae77e81e93bb21b`，`prepare publish` 在 source 未被改动前成功（`prepare_id=prep_76ce1d1bd4d21ff10dac096d0a16d38f`，`expected_generation=19`）。随后覆写 `docs/s5c-source.md`（新 sha256:afcd8cc3...），再执行 `publish`：

```
$ themico publish --root <REPO> --prepare prep_76ce1d1b... --approval inputs/s5c-approval.json
{"status":"validation_failed","issues":[{"code":"validation_failed","message":"themico store validation failed: source bytes changed after binding"}]}
```

**generation after**：19（未推进——`publish` 在任何写入之前就用 `checkSourceCurrency` 独立重读当前仓库字节并拒绝，不信任 `prepare` 时冻结的摘要）。

**query 复核**：该候选对应的 `record_id`（`kr_4a65896b7e60ab86b7145ec53c829e57`）未出现在当前 `project_knowledge` 记录列表中——发布确未生效。

**结论**：PASS，三个阶段（validate / prepare / publish）均能独立拦截 source drift，任一阶段拦截后 generation 均未推进。

---

## 场景 6：错误或 stale Approval 阻止 publish

**目的**：验证 `Approval` 与 `Prepare` 的精确绑定（`operation`、`prepare_id`、`prepare_digest`），以及 prepare 被消费后不能重放。

**真实输入**：候选 `cand_ee969485a74d934ef133e118161c6b50` 走完 create/confirm-type/prepare，得到 `prepare_id=prep_903f617f3f8add610a6175784d991bd8`，`digest=sha256:8a281f93...`。

```
6a) approval.prepare_digest 被篡改（尾字符改动）：
$ themico publish ...
{"status":"precondition_failed","issues":[{"code":"precondition_failed","message":"themico store precondition failed: approval is not bound to this prepare"}]}
generation 未变（22 → 22）

6b) approval.operation="supersede"（非 publish）：
$ themico publish ...
{"status":"precondition_failed","issues":[{"code":"precondition_failed","message":"themico store precondition failed: approval operation does not match publish"}]}
generation 未变（22 → 22）

6c) 正确 Approval（基线）：
$ themico publish ...
{"status":"succeeded","output":{"generation":23,"record_id":"kr_0ec9a4884b5d5d162fd847c35cab13c0","status":"active"}}
generation 22 → 23

6d) 复用同一个（已被 6c 消费）prepare，重新构造一份格式正确的新 Approval 再次 publish：
$ themico publish ...
{"status":"precondition_failed","issues":[{"code":"precondition_failed","message":"themico store precondition failed: candidate advanced since prepare"}]}
generation 未变（23 → 23）
```

6d 之所以失败，是因为 `publish` 复核时读取候选当前状态，发现候选已在 6c 中被标记为 `published` 并绑定新的不可变 revision，与 `prepare` 冻结时的 `candidate_revision` 不再一致，因此即便 Approval 本身格式正确也被拒绝——这正是"stale Approval/stale prepare 阻止 publish"的真实体现。

**结论**：PASS，四个子场景（错误 digest、错误 operation、正确基线、重放）状态与 generation 变化均与设计预期一致。

---

## 场景 7：并发 generation conflict，不覆盖获胜 generation

**目的**：验证两个真实 OS 进程并发调用 `publish` 时，`store.Commit` 基于 `generations/gen-<N>` 目录 rename 的锁机制只让一方成功，失败方不覆盖获胜方的 current 状态。

**真实操作**：顺序为候选 A、候选 B 分别走完 create → confirm-type → prepare publish（各自的 3 次 setup 提交必然推进 generation，因此 A 的 `expected_generation=26`，B 的 `expected_generation=29`，二者天然不同——这与 `internal/themico/integration/lifecycle_test.go:480` 附近的自动化并发测试对同一结构性约束的说明一致：谁会在 publish 阶段冲突，在两个 publish 真正开始竞速之前就已经由 prepare 的准备顺序决定；但下面的两次 `publish` 调用仍然是通过 shell 后台任务 (`&` + `wait`) 派生的两个真实进程同时发起，共同竞争同一次 `store.Commit`）：

```
$ themico publish --root <REPO> --prepare prep_bcedb49f... --approval inputs/s7-approval-A.json &
$ themico publish --root <REPO> --prepare prep_bb3adf82... --approval inputs/s7-approval-B.json &
$ wait

候选 A 输出：
{"status":"conflict","issues":[{"code":"conflict","message":"themico store conflict: store advanced past the prepared generation"}]}

候选 B 输出：
{"status":"succeeded","output":{"generation":30,"record_id":"kr_39cdd7599f7e8d5dc0f4e7d0b19691e7","status":"active"}}
```

**generation after**：30（恰好只被推进一次，与预期的“只有一个成功提交”一致）。

**query 复核**（zones=[project_knowledge]）：候选 B 的记录 `kr_39cdd7599f7e8d5dc0f4e7d0b19691e7` 出现在 current 列表中；候选 A 的记录 `kr_243d2d5ac9ddeb02b1fe5c2aa8a9f2cd` **未出现**——失败方没有以任何形式覆盖或污染获胜方的 current 状态。

**诚实说明**：与 `internal/themico/integration/lifecycle_test.go` 中 `TestConcurrentPublishLetsExactlyOneWinWithoutOverwriting` 的取舍说明一致，本场景里"谁会冲突"在两个 `publish` 进程真正启动前就已由两次 `prepare` 各自冻结的 `expected_generation` 数值大小结构性决定（B 的 `expected_generation` 更大，无论调度顺序如何，A 都必然冲突）。这不是本次 replay 编造的巧合，而是当前设计下"发布消费一次 generation"这一不变量与"prepare 自身也会提交一次 generation"这一实现事实共同决定的结果——两个候选 prepare 顺序创建时，天然不可能得到相同的 `expected_generation`。真正被验证的是 `store.Commit` 的 rename 锁在两个真实并发 OS 进程下不会损坏状态、不会让失败方的写入可见，而不是"调度顺序决定胜负"这一在当前实现下并不成立的命题。

**结论**：PASS（结构确定 + 真实并发路径均验证）。

---

## 场景 8：投影或 content 篡改导致 query/inspect 失败关闭

**目的**：验证读取路径对 `record.json`/`content.md`/`l1.json`/`l2.json` 的 digest 绑定失效时整请求失败关闭，不做部分返回、不临时从 L3 生成摘要。复用场景 1 发布的记录 `kr_4354caedebdf797b929f6a2201ae8338`。

**8a：篡改 `content.md`（record 的 L3 原文），`inspect depth=3`**

```
$ echo "被篡改的内容" >> records/kr_4354.../revisions/rev_11bd.../content.md
$ themico inspect --root <REPO> --request {"record_ids":["kr_4354..."],"depth":3,"content_budget_bytes":1048576}
{"status":"validation_failed","issues":[{"code":"validation_failed",
  "message":"themico store validation failed: referenced record revision is missing or invalid: themico store validation failed: record content digest mismatch"}]}
$ 还原 content.md 后重新 inspect → succeeded（恢复正常，证明失败确实由篡改引起而非环境问题）
```

**8b：篡改 `l1.json`（投影文件字节），`query`（zones=[project_knowledge]）**

```
$ echo '{"tampered":true}' >> projections/kr_4354.../rev_11bd.../l1.json
$ themico query --root <REPO> --request {"zones":["project_knowledge"],"content_budget_bytes":1048576}
{"status":"validation_failed","issues":[{"code":"validation_failed",
  "message":"themico store validation failed: referenced projection is missing or invalid: themico store validation failed: invalid referenced machine JSON: trailing JSON token {"}]}
```

**关键观察**：`query` 请求里同时还应命中另外两条正常记录（development_standard 已发布），但**整个请求**仍然失败关闭为 `validation_failed`，不是"跳过坏记录、只返回好记录"。还原 `l1.json` 后重新 `query` → `succeeded` 且三条记录都正确返回。

**8c：篡改 `l2.json`，`inspect depth=2`**

```
$ echo '{"tampered":true}' >> projections/kr_4354.../rev_11bd.../l2.json
$ themico inspect --root <REPO> --request {"record_ids":["kr_4354..."],"depth":2, ...}
{"status":"validation_failed","issues":[{"code":"validation_failed",
  "message":"themico store validation failed: referenced projection is missing or invalid: themico store validation failed: invalid referenced machine JSON: trailing JSON token {"}]}
$ 还原 l2.json 后重新 inspect → succeeded
```

**结论**：PASS，三类篡改（record content、l1.json、l2.json）均触发整请求 `validation_failed`，且还原字节后立即恢复正常，证明失败确实由 digest/绑定校验引起。

---

## 场景 9：byte budget 不足返回 budget_exceeded，且不截断 L3

**目的**：验证 `content_budget_bytes` 精确边界与"预算不足时整请求失败关闭、不截断"。复用场景 1 的记录，其 depth=3 编码后精确字节数为 1057（场景 1 已实测得到）。

```
$ themico inspect --root <REPO> --request {"record_ids":["kr_4354..."],"depth":3,"content_budget_bytes":1057}
{"status":"succeeded","output":{"items":[{...含完整 l3...}],"trace":{"content_bytes":1057,"remaining_bytes":0}}}

$ themico inspect --root <REPO> --request {"record_ids":["kr_4354..."],"depth":3,"content_budget_bytes":1056}
{"status":"budget_exceeded","output":{"items":[],"trace":{"content_bytes":1057,"remaining_bytes":-1,
  "excluded_ids":["kr_4354..."],"selected_ids":[]}},
 "issues":[{"code":"budget_exceeded","message":"themico query budget exceeded"}]}
```

`content_budget_bytes=1056`（比精确所需字节数少 1）时，`items` 为**空数组**——不是把 L3 截断到 1056 字节返回，而是整条 item 都不返回，`trace.content_bytes` 仍如实报告"这条 item 实际需要 1057 字节"，`selected_ids` 为空、`excluded_ids` 包含该记录。

另外验证了请求级别的 `[1, 16 MiB]` 边界：

```
$ content_budget_bytes=0    → validation_failed: "content budget bytes must be between 1 and 16 MiB"
$ content_budget_bytes=16777217（16MiB+1） → 同样 validation_failed
```

**结论**：PASS，精确边界（1057 成功、1056 失败）、失败时不截断、请求级别 `[1,16MiB]` 边界校验均得到真实验证。

---

## 补充复现材料 A：已知缺陷 1 —— l1.json 与 l2.json 是同一份完整 model.Projection 的字节副本

场景 1-9 的每一次 `prepare publish` 输出里，`writes` 数组中 `l1.json` 与 `l2.json` 两条 `path` 不同但 `digest` 字段**始终相同**（例如场景 1 中二者均为 `sha256:56f5efbe58b94b8021ec63db8fa4b30031d8e385ae763916b38fb63dadbc5bc7`，场景 2/3/6/7 亦各自如此）。场景 1 额外对发布后落盘的两个文件做了 `diff`/`sha256sum` 直接确认字节完全相同（见场景 1 小节）。

根因：`internal/themico/store/generation.go` 的 `validateProjectionReference`（第 351-400 行左右，两个 `check` 分支分别针对 `l1.json`、`l2.json`，均要求解码为完整 `model.Projection` 并对 `record.L1`、`record.L2` 做等值校验）强制两个文件必须携带同一份完整投影内容，`internal/themico/governance/prepare.go`（约第 119-129 行）与 `internal/themico/governance/publish.go`（约第 82-89、113-118 行）的代码注释明确记录了这一约束及其来源。

**影响边界**：API 层的发现/升级边界仍然成立——`internal/themico/query/query.go` 的 `Candidate` 类型（第 57-68 行）以及 `readProjectionL1`（第 308-335 行）只从磁盘上的完整投影里挑出 L1 字段对外返回，`query` 命令的输出里确实不含 `l2`/`l3`。但"L1、L2 是两个独立存储单元"这一物理层保证目前不成立：任何能读到 `l1.json` 的人也能读到完整 L2 内容。此为已知缺陷，需要后续独立计划修复（例如让 `validateProjectionReference` 对 `l1.json` 只校验 `L1`/`l1_digest`、对 `l2.json` 只校验 `L2`/`l2_digest`）。

---

## 补充复现材料 B：已知缺陷 2 —— canonical.Encode 的 1 MiB 硬上限与 query 的 16 MiB content_budget_bytes 冲突

**复现步骤**：发布两条 design_decision 记录（候选 X、候选 Y），每条记录的 L3 Markdown 正文刻意撑到约 594,228 字节（远低于单条记录 4 MiB 的 L3 上限，也低于单个 machine JSON 1 MiB 的硬上限），两条合计约 1,188,456 字节。

```
$ themico inspect --root <REPO> --request {"record_ids":["kr_d68f4c14..."],"depth":3,"content_budget_bytes":16777216}
{"status":"succeeded", ...}   # 单条 item 601586 字节，个体 < 1 MiB，本身可以正常返回

$ themico inspect --root <REPO> --request {"record_ids":["kr_d68f4c14...","kr_02e4ef2e..."],"depth":3,"content_budget_bytes":16777216}
{"schema":"themico-command-result","command":"inspect","status":"internal_error",
 "issues":[{"code":"internal_error","path":"","message":"machine JSON exceeds 1048576 bytes"}]}
```

两条记录合计约 1.19 MB，仍然远低于请求声明的 16 MiB 预算，`query.Inspect` 自身的预算核算（`internal/themico/query/inspect.go` 第 118-140 行，对每个 item 单独 `canonical.Encode` 并累加 `totalBytes`，再与 `request.ContentBudgetBytes` 比较）判定这次请求完全在预算内，返回了填满 `Items` 的成功结果。但 `internal/themico/cli/commands.go` 的 `canonicalOutput`/`traceEnvelope`（第 409-415、505-529 行）随后把整个 `InspectResult` 再作为**一个整体**交给 `internal/themico/canonical/canonical.go` 的 `Encode`（第 16、35-37 行硬编码 `maxMachineJSONBytes = 1 << 20`），一旦合并后的 envelope 输出超过 1,048,576 字节，`Encode` 直接返回错误，CLI 兜底为 `internal_error`——一个语义上完全合法、通过了 16 MiB 预算门禁的结果集，在写入 CLI envelope 时被错误分类为内部错误，而不是一个信息完整的 `budget_exceeded`（该状态本应保留给"确实超出用户声明预算"的情形）或某种更小的、诚实的成功上限。

**结论**：CLI 实际可返回的单次结果上限，受 canonical envelope 的 1 MiB 硬编码限制约束，而非 `query`/`inspect` 请求里声明的 `content_budget_bytes`（最高可声明到 16 MiB）。README 必须如实说明这一点，不得把 16 MiB 预算宣传为完全可用的读取能力上限。

---

## 补充复现材料 C：assessment 绑定与 checker identity 校验的失败分支（用于坐实验收条目 7）

自动化测试（`internal/themico/governance/governance_test.go`、`internal/themico/integration/lifecycle_test.go` 等）里所有会走到 `prepare publish` 的 fixture 全部固定使用"`checker_identity` 与 `proposed_by` 不同、`status=pass`、绑定到正确 candidate_revision"的 assessment，没有一处显式测试 `internal/themico/governance/assessment.go` 的 `checkAssessment` 函数（第 14-37 行）四条拒绝分支中的任意一条。为了不让验收条目 7（"independent assessment 绑定 exact candidate revision，checker identity 字段与 proposer 不同"）只依赖间接推断，本任务用真实 CLI 补做了以下 replay：

候选 `cand_1caa97d2e5f0d3548309dd41a3da7ad3` 的 `proposed_by="agent:same-identity"`，`confirm-type` 后得到 `crev_cbe7e2e2038896eec99a3d99d23060fe`。

```
7a) checker_identity 与 proposed_by 相同：
$ themico prepare publish ... --assessment {checker_identity:"agent:same-identity", ...}
{"status":"precondition_failed","issues":[{"code":"precondition_failed",
  "message":"themico store precondition failed: assessment checker must differ from the proposer"}]}

7b) assessment 绑定到错误的 candidate_revision：
$ themico prepare publish ... --assessment {candidate_revision:"crev_ffff...ffff", checker_identity:"agent:different-checker", ...}
{"status":"precondition_failed","issues":[{"code":"precondition_failed",
  "message":"themico store precondition failed: assessment is not bound to the candidate revision"}]}

7c) assessment status=fail：
$ themico prepare publish ... --assessment {status:"fail", checker_identity:"agent:different-checker", ...}
{"status":"precondition_failed","issues":[{"code":"precondition_failed",
  "message":"themico store precondition failed: assessment did not pass"}]}

7d) 基线对照，checker_identity 与 proposer 不同、绑定正确、status=pass：
$ themico prepare publish ...
{"status":"succeeded","output":{"prepare_id":"prep_fcea9e7029132d654628ed5dba095ead", ...}}
```

四个子场景状态与 `assessment.go` 的四条判定逐一对应，`generation` 在 7a/7b/7c 三次失败中均未被推进，只有 7d 成功后才提交了新的 generation。

**结论**：验收条目 7 的关键约束（checker identity 与 proposer 不同、精确绑定 candidate revision、`status=pass` 是硬性门槛）均有真实运行证据，弥补了自动化测试里对这些负向分支的覆盖空缺。
