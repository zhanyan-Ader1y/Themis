# Templates Package

## Responsibility

Templates 为新语义工件、Human projection 和 review form 提供初始结构；它们减少格式漂移，但不创建事实或证明 machine validity。

## Owned assets

- `spec.yaml`：Spec source scaffold。
- `context-resolution.md`：Context selection procedure template。
- `context-summary.md`：Knowledge candidate summary template。
- 未来 Plan、Review、Implementation ledger、Verification、Acceptance 和 Summary templates。

## Boundaries

- template 是起点，不是 current artifact、approval 或 evidence。
- Human projection template 不得反向成为 YAML source。
- 不在 template 中嵌入项目事实、默认 Gate 或被退役的 Upgrade/Migration/Behavior Map 流程。

## Safe degradation

没有 projector 时可以辅助 Prompt 生成明确标记的 review copy，但不得声称 canonical or byte-identical output。

## Current status

三个模板存在；覆盖范围不完整且没有 projector/runtime 或 executable tests。Plans 35/36 将补齐语义使用和投影合同，Plan 37 实现确定性 rendering。
