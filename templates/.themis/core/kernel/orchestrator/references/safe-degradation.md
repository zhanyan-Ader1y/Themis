# 安全降级控制

> 本文件属于 [Themis Global Control Rule](../rules.md) 的按 gate 加载 reference。它解释 Plan 35 缺少 machine guarantee 时的 fail-closed 行为，并引用唯一 Policy 的 [Assurance 边界](../../../policies/references/assurance-boundary.md)。

## 加载条件

Preflight、Invocation、control action、materialization、currentness、failure recording、recovery 或 completion 需要当前未实现的 machine capability 时加载本文件；任何入口准备声明“已由机器执行”时也必须先加载。

## 当前 unavailable guarantee

Plan 35 当前不提供：

1. strict Schema 与 validator；
2. canonical serialization 与 digest algorithm；
3. semantic oracle 与 accepted/rejected fixtures；
4. Policy evaluator；
5. state recorder；
6. Invocation host；
7. deterministic write runtime。

没有 observed runtime evidence 时，transition、persistence、digest、currentness、invalidation、attempt、termination、recovery 与 completion 的 machine-execution claim 均被禁止。

Plan 36/37 的文档、计划或未来归属不表示这些能力已实现。Rule、Policy、Capability contract、template、Workspace directory、Markdown record 或成功文件写入也不是 runtime evidence。

## Fail-closed 行为

缺失 guarantee 影响当前动作时：

- 停在 last proven gate；
- 报告具体 unavailable assurance；
- 保留 exact durable continuation；
- 不创建伪 attempt 或伪 recorder observation；
- 不手写 machine-owned state；
- 不伪造 digest、current pointer、termination 或 completion；
- 不把文件存在、Agent statement 或 manual parity review 当作执行成功；
- 不自动 repair、rollback、merge、replay 或推断完成。

Invocation 前 required Policy package/reference unavailable 或 ambiguous 时适用 preflight fail-closed，不消耗 failure budget。Invocation 已开始后的真实 Agent/tool/command/result/materialization failure，仍按 current Policy 与 failure reference 分类。

## 允许的人工观察

当前可以记录：

- 人工文件读取；
- 语义 parity review；
- 人工 replay；
- Git status/diff observation；
- 独立 reviewer 对合同文本的判断。

这些观察只能证明 Prompt-level 表示和人工核验结果，不能证明 parser、validator、evaluator、recorder、Invocation host 或 deterministic write runtime。

当前没有已批准并已实现的 Themis Go CLI 文档/合同核验命令，自动项目检查必须记为 `unavailable`。不得发明子命令，也不得用 Python、Shell 或其他临时脚本模拟项目合同检查。Git 命令只用于版本控制观察。

## 明确禁止恢复的能力

安全降级不得恢复 functional version、compatibility、installer、upgrade、runtime migration、Shell fallback、multi-Agent orchestration、Attribution gate、通用 lock/transaction、rollback journal 或 automatic recovery。

## 返回

Unavailable 状态被清楚记录后，返回触发本 reference 的 last proven gate 与 exact durable continuation；只有实际 machine support 被观察且 current bindings 重新验证后，才可重试对应动作。不得通过换 Agent、换 model、resume session 或重复 prose instruction 绕过 unavailable boundary。
