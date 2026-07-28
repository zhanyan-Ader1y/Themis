# Protocols Package

## Responsibility

Protocols 定义模块 handoff 和 machine assurance 所需的结构化字段、标识、引用和结果形状，避免 sibling modules 直接 import 对方规则。

## Owned assets

- `artifact/spec-schema.yaml` 与 `artifact/spec-projection.yaml`。
- `context/common-schema.yaml`、`context-item-schema.yaml`、`catalog-schema.yaml`、`bundle-schema.yaml`、`signal-schema.yaml`。
- 未来 Plan、Review、Implementation ledger、Verification evidence、Delivery 和 Knowledge protocols。

## Boundaries

- Protocol 不决定需求内容、Task decomposition、Review judgment、implementation choice、Human Acceptance 或 Knowledge value。
- 字段名称和 schema identity 只表达唯一当前合同，不使用功能性版本。
- Markdown projection 不是 protocol authority；unknown fields、canonicalization 和 currentness 由 Plan 36 明确定义。

## Safe degradation

声明协议存在但 validator 不存在时，只能称其为 contract input。不得手工伪造 validator output、digest、OID、transition 或 transaction record。

## Current status

Spec 与 Context 的部分 YAML 协议存在，尚未经过当前 executable conformance suite 验证；其他核心领域协议缺失。Plan 36 将统一语言无关合同和 `tests/contracts/` fixtures。
