# Changes

## 0.4.0

### 2026-07-28

- 将 Requirement Questioning 落地为 Project Skill `themis-q`，仅维护聚焦、渐进式提问方法、需求覆盖、Acceptance Criteria 与对抗问题
- Specification 主动调用 `themis-q`，并独立负责 Context grounding、复杂度、收敛、规范化摘要、用户确认、candidate 创建与发布；Skill 不定义流程或 handoff
- Fresh Init 安全合并安装 `.claude/skills/themis-q/`，保留既有 `.claude` 设置与无关 Skills；同名路径冲突在写入前拒绝，后续失败仅回滚本次创建路径
- 退役 Core questioning Prompt 与攻击 checklist；详细攻击库改为 Skill sibling reference，并由模板契约保护提问方式、覆盖范围与收敛指导
- Spec 在正式发布前收敛为唯一无版本合同，移除 `spec_schema`、`template_version`、`questioning` 和 Agent 自报 self-check，保留 Artifact v2 与 Workspace v1 独立版本合同
- 新增最终 `context_basis`，并由确定性 executor 从最终语义计算 Context readiness 与 semantic consistency；八个稳定 readiness ID 及双视图事务发布保持不变
- 完成 P5.4 Context Restructure：新增 Item、Catalog、Bundle、Signal 与共享 result/revision/digest 五项 v1 Protocol，以及 lint、catalog、search、assemble、freshness、navigation 六个确定性执行器和共享运行时
- Fresh Init 安装 unbound 空 Catalog、七类 L1/L2 Navigation、Context Signal、owner-token lock、可恢复 transaction、可重建 index 与 resolved Bundle Cache；既有 `.themis` 仍在写入前拒绝
- Context 解析采用“受治理 Context 描述应当是什么、当前代码/配置/Schema 描述现在是什么”的双轴可信模型；Prompt 只能选择 Search/Prepare 冻结的候选，冲突、漂移与缺失通过持久 Signal 显式处置
- 新增 Context resolution/summary Prompt 与按需 rules 路由；summary 只生成待治理候选，不直接发布 L3、Catalog 或 L1/L2
- Behavior Map、Upgrade 与 Migration 继续保持退役；P5.4 不增加 Workspace/Artifact Schema 转换、Knowledge Promotion、生命周期编排或 Claude API/SDK 运行时依赖

## 0.3.0

### 2026-07-28

- 从当前产品退役 Behavior Map、Upgrade 与 Migration，移除其命令、测试、模板、策略、占位目录和现行规范入口；历史计划与发布记录继续保留
- 将 Core 兼容合同固定为 Workspace v1 与 Artifact v2 allow-list；unsupported schema 直接 fail closed，不声明或执行转换路径
- Init 收敛为 fresh installation，在任何写入前拒绝已有 `.themis/` 并保留现有 Workspace，不提供覆盖安装或删除重装绕行
- 生命周期调整为前置 Review、后置 Verification、Verification 通过后 Human Acceptance、验收通过后确定性生成 `summary.md`，再进入归档

### 2026-07-27

- 完成 P5.2 Spec 双视图：新安装使用 `themis-artifact/v2` 与 `themis-spec/v2`，`spec.yaml` 成为唯一权威语义源，`spec.md` 成为带 source/body OID 的确定性 Human 审阅投影
- 新增 Bash 3.2 兼容的 `themis-spec.sh`，提供 Draft/readiness 校验、稳定 ID/引用检查、确定性渲染、漂移检测和事务性 Spec pair 发布
- Specification、Planning 与 `draft_to_specified` 改为消费结构化真源和八个稳定 validator check ID，不再从 Markdown 标题或正文提取机器证据
- Artifact v2 与 Spec v2 作为首次投入使用的原生契约；不安装预发布 Spec 模板、Artifact v1 兼容层或对应迁移描述符
- 扩展 Template Contract、Init、Upgrade 与 Spec Artifact 隔离回归；Upgrade 继续保持 Workspace 字节不变

## 0.2.0

### 2026-07-27

- 将已确认的 Themis 设计规范统一迁入 `docs/design/**`，建立设计治理、架构、工作流、Core 与 Workspace 的单一权威入口
- 精简 `AGENTS.md`、`AGENTS.CN.md` 和文档导航为仓库协作与链接入口；旧 `docs/core/**`、`docs/workspace/**`、`docs/workflow.md` 和 `docs/runtime-environment.md` 保留为非规范兼容指针
- 校准 Init、Explicit Migration、Adapter、Protocol、Policy 与各 Kernel 模块的实现状态，并让待实施计划的未来文档目标指向 `docs/design/**`
- 将 `main` 新增的 P5.4 Context Trust 正式合同并入设计规范，保留 P5.2 Spec 双视图为待确认实施设计

### 2026-07-25

- 完成 P5 Requirement Questioning：新增 Step 0–4 的自适应追问 Prompt、Five Whys、Pre-mortem、Option Zero、AC 分段确认和对抗验证场景库
- 新增 Draft Spec 模板，持久记录复杂度、假设、证据、攻击处置、限制、回滚与用户批准；P5 不伪造机器生命周期迁移，确定性状态执行器留待 P8
- 新增 Specification 与 `draft_to_specified` 声明式策略，扩展模板契约和隔离 TAP 回归，验证 P5 Core 资产、稳定门禁 ID、模板标题及常驻规则篇幅边界

## 0.1.0

### 2026-07-24

- 完成 P4 Upgrade：新增 Bash 3.2 兼容的 `themis-upgrade.sh`，仅替换 `.themis/` 中 Workspace 以外的受管内容，持久保留备份且不改写项目 `CLAUDE.md`/`AGENTS.md`
- 新增 33 项 Upgrade 集成测试，覆盖兼容替换、Workspace/项目指引不变性、dry-run、legacy 拒绝、Schema 拒绝与替换后自动回滚
- P4 不加载 P0 Init 环境校验；自身仅检查 mikefarah/yq v4，并拒绝需要 Workspace/Artifact migration 的不兼容 Schema

- 完成 P3 Init：新增 Bash 3.2 兼容的 `themis-init.sh`，在 P0 环境校验后安装经验证的 `.themis` 模板、写入项目 Manifest，并拒绝替换已有安装
- Themis 顶层指引移入 `.themis/CLAUDE.themis.md`；Init 仅在项目 `CLAUDE.md` 末尾追加可逆标记块，直接 import 包含式指引和 Core Orchestrator，不创建根目录 `CLAUDE.themis.md`
- 新增 22 项 Init 集成测试；模板契约扩展至 34 项，覆盖包含式指引、过时根目录指引拒绝、标记冲突和 Workspace 保护
- P4 Upgrade 明确只替换 `.themis/` 中 `workspace/` 以外的 Themis 管理内容，项目 `CLAUDE.md` 与 Workspace 均保持不变

- 完成 P2 Top-level Guidance：将 `CLAUDE.themis.md` 与 Kernel 规则从 P1 最小入口扩展为工件优先的基线 SDD 路由
- 明确 Core/Workspace 所有权、Source of Truth、生命周期停止条件、安全退化与防绕过规则；不提前实现 P5/P6/P8 的领域流程或执行器
- 扩展模板自检与隔离夹具至 32 项，验证唯一 import 图、规则结构和篇幅边界；Claude Code 运行时 import 探针待认证环境复核

- 完成 P1 Template Contract：将 `.themis` 源模板固化为版本化 Core/Workspace/Artifact 兼容契约
- 修正 `knowledge`、`migrations` 模板路径与顶层 Core 导入，新增 8 个最小 Kernel 规则入口
- 新增 Workspace 上下文完整子目录（architecture/behavior-map 等）及 P6 静态分析 Adapter 目录
- 新增 Bash/yq v4 模板自检及 22 项隔离夹具测试；不执行 Init、Upgrade 或已安装 Workspace 迁移

- 完成 P0 Init Environment Validation：新增 Bash 3.2、Git 2.0+ 与 mikefarah/yq v4 的 Init 专用校验库
- 新增 Init 环境说明和隔离测试矩阵；环境检查不进入 Upgrade、Core、Workspace 或正常 SDD 运行路径

### 2026-07-23

- 初始化 `.themis` 模板目录结构（`core/` + `workspace/` 双命名空间）
- 创建完整的 WIKI 文档体系，定义所有 Core 模块的边界和能力：
  - `docs/README.md` — WIKI 导航
  - `docs/core/kernel/` — 8 个内核模块（Orchestrator, Specification, Planning, Context, Verification, Review, Attribution, Knowledge）
  - `docs/core/` — 5 个基础设施模块（Protocols, Policies, Templates, Adapters, Migrations）
  - `docs/workspace/overview.md` — Workspace 完整说明
- 新增 `docs/plan/` 模块化实施计划体系（P0–P6）；计划为待执行设计，不代表功能已经实现
  - P0–P4：安装链路（Init 环境校验、模板契约、顶层指引、Init、Upgrade）
  - P5：需求追问子系统（适配 obra/superpowers 追问策略）
  - P6：代码行为地图与变更定位子系统（适配 Harness Handbook 方法论）
- 新增 [P7 集成审计](docs/plan/70-integration-audit/)：模块加载机制（对比 Lattice/Superpowers）、工作流编排保证、知识维护统一入口、当前结构缺失审计
- 将 P0–P8 实施计划迁移为各自独立目录；每个计划拥有隔离的 `impl.md` 记录位置
- 更新项目 README.md