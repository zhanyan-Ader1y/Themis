# Context Package

## Responsibility

Context 解析项目“应当表达什么”的受治理事实，并与代码、配置、Schema 所表达的当前实现事实并列呈现。它支撑准确追问、Planning 和 Knowledge 演进，但不静默决定冲突。

## Owned assets

- `rules.md`：Context authority 与边界。
- `../../protocols/context/**`：Item、Catalog、Bundle、Signal 等结构输入。
- `../../templates/context-resolution.md` 与 `context-summary.md`：语义解析和 candidate 模板。
- Workspace `context/`、Catalog、Cache、Signals 和 transaction scaffold。

## Inputs and outputs

输入为 registered Context items、Catalog、当前代码/配置/Schema、显式 external references 和 task request。输出为选定事实、冲突/漂移说明、task-scoped Bundle、freshness report、Signal 或 Knowledge candidate。

## Prompt flow and handoff

1. 读取 Catalog、相关 L3 Context 和当前实现材料。
2. 分别标注 governed fact 与 observed implementation fact。
3. 检查缺失、freshness、重复、冲突和 scope。
4. 为调用领域产生可引用的 selection/Bundle 语义。
5. 可复用结论只作为 Knowledge candidate handoff，不直接写入正式 Context。

## Assurance boundary

Prompt 可执行语义选择和记录真实观察；不能伪造 Catalog validation、content digest、Bundle identity、Signal transition、atomic mutation 或 transaction。Plans 36/37 提供确定性合同和实现。

## Safe degradation

Catalog、source 或 executor 缺失时返回 unavailable/inconclusive，并阻止依赖该事实的结论。Cache 永不成为 authority，也不得把未注册扫描结果当正式知识。

## Workspace interaction

正式项目知识只写 `workspace/context/`；Cache 是派生数据，Signals 进入 `workspace/state/context-signals/`，Knowledge governance records 进入 `workspace/knowledge/`。

## Non-ownership

不拥有 requirements、Plan、project code、lifecycle state、Knowledge value judgment 或 external-source truth。

## Current status

rules、protocol/schema 草案、templates、Catalog 和目录 scaffold 存在；旧 Context Shell executors 和 tests 已移除。当前没有 deterministic search/assemble/lint/freshness/navigation、Catalog mutation、Signal disposition 或 transaction capability。
