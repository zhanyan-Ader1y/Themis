# Verification Package

## Responsibility

Verification 在 Implementation 后运行实际存在的 Gates，形成可复现、evidence-backed 的事实。它回答“当前实现被什么证据支持”，不修改代码或重做 Review。

## Owned assets

- `rules.md`：当前 Verification 边界。
- 未来 Gate、attempt、evidence、repair/resume 和 verdict contracts。

## Inputs and outputs

输入为 manifest 中结构化配置的 project commands/Gates、current implementation revision、approved Plan/Review 和 Task evidence。输出为 run/evidence records 与：

```text
pass | fail | inconclusive
```

每次 attempt 保存 executable/args、cwd、相关 environment、exit、stdout/stderr refs、AC coverage、revision、classification、rerun history 和 limitations。

## Prompt flow and handoff

1. 枚举 blocking Gates 和 evidence requirements。
2. 仅运行真实存在且明确配置的命令。
3. 保存观察结果并区分 fail、unavailable 和 not_run。
4. 所有 blocking Gates 有充分 evidence 才能 `pass`。
5. `fail`/`inconclusive` 产生 repair handoff；`pass` handoff 到 Delivery。

## Assurance boundary

Prompt 可运行可用工具并记录观察；不能伪造 command/exit/output 或自行把缺失证据聚合为 `pass`。Plan 37 runtime 以 child process 运行项目命令，不用 Shell 串联 Themis 操作。

## Safe degradation

未配置命令、工具缺失、输出不可访问或 evidence 不完整时返回 `inconclusive`/`unavailable`。任何实现变化使受影响 evidence 和 Acceptance 失效。

## Workspace interaction

runs 写入 `workspace/runs/`，evidence 写入 `workspace/evidence/`；不得在 Verification 中修改 project code。

## Non-ownership

不作 pre-Implementation Review、Implementation、Human Acceptance、Summary 或 Attribution causal judgment。

## Current status

`rules.md` 和 Workspace directories 存在；Gate runner、attempt/verdict schema、state invalidation、recovery 和 executable tests 尚未实现。
