# Assurance 边界

> 本文件属于 [`themis-core-control`](../README.md) 唯一 Policy，拥有 Plan 35 Prompt-level assurance boundary。它不是独立 Policy，也不把缺失能力描述成已实现 runtime。

## 当前八项边界

1. Strict Schema 与 validator 当前 `unavailable`，由未实施的 Plan 36 拥有。
2. Canonical serialization 与 digest algorithm 当前 `unavailable`，由未实施的 Plan 36 拥有。
3. Semantic oracle 与 accepted/rejected fixtures 当前 `unavailable`，由未实施的 Plan 36 拥有。
4. Policy evaluator 当前 `unavailable`，由未实施的 Plan 37 拥有。
5. State recorder 当前 `unavailable`，由未实施的 Plan 37 拥有。
6. Invocation host 当前 `unavailable`，由未实施的 Plan 37 拥有。
7. Deterministic write runtime 当前 `unavailable`，由未实施的 Plan 37 拥有。
8. 没有 observed runtime evidence 时，任何 transition、persistence、currentness、digest、attempt、invalidation、termination 或 recovery 的机器执行声明都 `forbidden`。

## Plan 35 可证明范围

Plan 35 只提供 Prompt、Capability、template、Workspace 和自然语言 Policy 的产品合同。当前可执行的核验只有人工文件读取、语义 parity review、人工 replay 和 Git diff observation；这些观察不构成 parser、hidden Schema、route DSL、recorder 或 machine enforcement。

当前没有已批准并已实现的 Themis Go CLI 文档/合同核验命令。自动项目检查必须标记为 `unavailable`，不得发明子命令或以 Python、Shell、临时脚本替代。

## 明确不包含

本 Policy 不包含功能版本、compatibility、installer、upgrade、runtime migration mechanism、Shell fallback、multi-Agent orchestration、Attribution gate、通用 lock、transaction、rollback journal 或 automatic repair。

## 安全降级

当缺失 machine guarantee 影响当前动作时，控制面必须停在 last proven gate，报告具体 unavailable assurance，并保留 durable continuation。不得以手工写入 machine-owned state、伪造 digest、跳过 currentness 或把文件存在当作成功来降级。
