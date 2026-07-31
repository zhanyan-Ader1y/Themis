# Plan 35 实施与核验证据概述

> 状态：Intake 完结后休眠合同、静态复核、十六类人工重放与验收审计均已完成；用户已于 2026-07-31 审阅证据并明确重新接受，Plan 35 current authority 已恢复。

## 实施内容概述

本次工作完成了 replacement Plan 35 的整体替换，将 Themis Core 重构为 Intake-first 的 Prompt 控制模型，主要包括：

- 建立独立的 Request Intake 与 lifecycle 双作用域；
- 统一所有外部消息的 Source Event 记录和 Intake 拦截流程；
- 建立用户确认、来源可追溯的 Current Request 模型；
- 完成十六个内部 Capability 和四个固定 Agent Profile 的合同；
- 建立唯一公共 `themis` Skill、唯一 Global Control Rule 和唯一双作用域 policy；
- 完成简单路径与完整路径，以及两条路径汇合后的 Review、Approval、Impl、Verification、Acceptance 和 Summary 流程；
- 建立不可变语义工件、独立 current pointer、失效传播和恢复边界；
- 建立 Intake 与 lifecycle 隔离的三次失败预算，以及非阻塞 Failure Learning；
- 建立 lifecycle 完成后的 Intake 休眠合同：逐 target 冻结、全部关联 lifecycle 完成后进入 `dormant-read-only`、continuation 失活、来源记录只读保留、新消息创建新 Intake；
- 对齐 Workspace、模块合同、安装说明、活动计划和项目概览；
- 移除旧的 lifecycle-first、持久化 Specification、单文件 Questioning、功能版本、迁移和兼容模型。

## 核验证据概述

### 静态核验

静态检查确认公共入口、Capability、Agent Profile、路由表、Global Rule、工件模板、Workspace 结构和安装说明之间保持一致。检查同时确认旧合同没有继续作为当前权威，并明确区分了 Plan 35 的 Prompt 合同与尚未实现的机器保证。

### 人工流程重放

人工重放覆盖了正常交付、需求更新、多目标分配、部分失败恢复、Review 返工、简单路径升级、非法结果、工件写入异常、失败预算、验收门禁、中断恢复、拒绝和放弃，以及 lifecycle 完成后的逐 target 冻结、整体休眠、恢复排除和新 Intake 创建。

十六类场景已按休眠合同完成重放，并与最新静态断言共同形成最终闭环证据。

### 验收审计

批准设计中的三十二项验收标准已完成映射：

- criteria 1–31 均有当前合同、静态观察或 replay 证据并通过；
- criterion 32 已由用户于 2026-07-31 审阅证据并明确重新接受而通过。

## 当前结论

replacement Plan 35 的 Prompt、模板、policy、Workspace 与 Intake 休眠合同已完成实现和核验，criteria 1–32 全部通过。用户已于 2026-07-31 明确重新接受，Plan 35 已恢复为 current product authority。

下一阶段可以依据该 current authority 对 Plan 36 进行完整重基线；Plan 36 仍需单独审阅和批准，不能因 Plan 35 的重新接受而自动实施。

## 能力边界

本次工作没有实现或声称以下能力已经可用：

- Plan 36 的严格 Schema、规范化、validator、问题分类和自动化 fixtures；
- Plan 37 的 policy evaluator、Invocation host、recorder、确定性写入、命令执行和原生恢复；
- Plan 80 的多 Agent 执行；
- Plan 90 的 Attribution 分析门禁；
- upgrade、migration、兼容层或 Shell fallback。

现有证据证明的是 Plan 35 的 Prompt-level 合同完整性和人工可重放性，不是机器运行时执行证明。

## 关联证据

- `static-verification.md`：静态一致性与工作树检查；
- `manual-replay.md`：十六类人工流程重放；
- `acceptance-audit.md`：三十二项验收标准审计。
