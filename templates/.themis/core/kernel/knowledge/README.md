# Knowledge Package

## Responsibility

Knowledge 管理从项目结果中提炼的 durable reusable candidates，并在事实核验和人工决定后更新正式 Context，使项目知识库持续演进而不形成第二个权威数据库。

## Owned assets

- `rules.md`：candidate 与正式 Context 边界。
- 未来 candidate、review、decision、action 和 disposition protocols。

## Inputs and outputs

输入为 outcome、runs/evidence、现有 Context、当前代码/配置/Schema 和可解析来源。输出为 candidate、重复/冲突分析、recommendation、human decision、approved change proposal、apply/reread record。

## Prompt flow and handoff

1. 从可解析来源建立 candidate。
2. 核验当前 Context 与相关 implementation facts。
3. 检查 exact/semantic duplicates、conflicts、sensitivity、scope 和 stability。
4. 形成 recommendation，接受用户 revise/reject/approve。
5. 只有 approved candidate 才可实际更新 `workspace/context/` 和 Catalog。
6. 写入后 reread；若未实际 apply/reread，状态保持 pending，不能称为 promotion。

## Assurance boundary

Knowledge value judgment 与批准属于人工/Agent 语义。未来 runtime 只执行/验证 provenance、action、idempotence、atomicity、rollback/recovery 和 reread evidence。

## Safe degradation

来源不可解析、事实冲突、批准缺失或写入工具不可用时保留 governance record，不修改 Context。不得 promotion secrets、transient logs 或未验证观察。

## Workspace interaction

正式知识只存在 `workspace/context/`；`workspace/knowledge/` 保存 candidate、review、decision 和 archival records。Core 不保存项目知识。

## Non-ownership

不拥有 Context 事实裁决之外的 Specification、Planning、Implementation、Verification 或 Acceptance。Attribution 可以提供 candidate source，但不是前置条件。

## Current status

`rules.md` 和 Workspace directories 存在；candidate/review/apply contracts、Prompt procedure、atomic Context/Catalog action、idempotence、recovery 和 tests 尚未实现。
