# Adapters Package

## Responsibility

Adapters 在 core contract 已稳定时，把显式声明的外部工具或项目系统映射为结构化 Themis inputs/outputs。它们是可选边界，不是核心语义或兼容层。

## Inputs and outputs

输入来自 `workspace/manifest.yaml` 中显式配置的 adapter 和 credentials boundary；输出必须转换为 owning protocol 的结构化 observation/evidence，并保留原始来源引用。

## Boundaries

- 不猜测项目 Gate、命令、路径或外部身份。
- 不执行 Upgrade、Migration、Behavior Map、self-update 或 package management。
- 不覆盖 lifecycle、Spec/Plan、Review、Verification、Acceptance 或 Knowledge rules。
- adapter 缺失不能阻塞不依赖它的核心流程。

## Safe degradation

不可用、鉴权失败或结果不可验证时报告 unavailable/inconclusive；不得生成模拟成功证据。

## Current status

该 package 当前没有实现资产。`workspace/manifest.yaml` 只有空 `adapters` 配置位；没有 adapter protocol、runtime 或 tests，也没有活动核心计划依赖它。
