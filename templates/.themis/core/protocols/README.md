# Protocols Package

## Responsibility

Protocols 为未来 deterministic assurance 定义结构化 handoff 的归属边界。Plan 35 只声明统一 Capability Invocation Result 和 Prompt-level 工件字段，不用未经验证的 YAML Schema 冒充机器合同。

## Owned assets

- `context/` 下现有 Context 结构声明。
- lifecycle、Plan、Review、Verification 等严格协议由 Plan 36 基于已接受的 Plan 35 语义统一建立。

## Boundaries

- Protocol 不决定需求内容、复杂度、技术方案、Review 判断、实现选择、Human Acceptance 或知识价值。
- 字段名称只表达唯一 current contract，不使用功能版本或版本目录。
- Markdown template 不是 protocol authority。
- Specification handoff 是临时非权威上下文，不拥有持久 artifact protocol。

## Safe degradation

声明字段存在但 validator 不存在时，只能称其为 Prompt contract。不得手工伪造 validator output、digest、OID、currentness、transition、completion marker 或 recorded operation result。

## Current status

Context 的历史 YAML 声明仍存在，但尚无 executable conformance suite。Plan 36 将决定保留、重写或替换的严格协议，并建立 accepted/rejected fixtures。
