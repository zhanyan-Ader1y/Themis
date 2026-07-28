# Policies Package

## Responsibility

Policies 保存跨 Prompt 和 runtime 都必须遵守的稳定枚举、门禁条件和允许覆盖范围。它们约束操作，不替代拥有者的语义判断。

## Owned assets

- `transitions.yaml`：固定 lifecycle transition 条件的声明输入。
- `specification.yaml`：Specification artifact、questioning、readiness 和 adversarial policy 输入。
- 未来 Planning、Review、Implementation、Verification、Delivery、Knowledge policies。

## Inputs and outputs

Policy 是 Core-owned read-only input。Prompt 读取它决定必需步骤；future runtime 读取它执行确定性 validation。任何 machine result 必须另存于 Workspace，不能写回 policy。

## Boundaries

- 不保存项目事实或项目命令。
- 不包含功能性版本标识或模块变体。
- 不把 executor path 的存在当能力证明。
- 不允许 project override 绕过固定 lifecycle、Review、Verification、Acceptance、Summary 或 Knowledge approval。

## Safe degradation

policy 缺失或无法解析时 fail closed。runtime 缺失时 Prompt 可遵循语义规则，但必须将 assurance 标为 unavailable。

## Current status

现有 YAML 含部分有效规则，也含已删除 Shell executor、旧阶段标签和未实现 machine checks 的漂移。Plan 35 将修正语义引用；Plan 36 将定义 strict schemas 与 accepted vectors；Plan 37 将实现读取和 enforcement。
