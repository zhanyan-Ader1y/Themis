# Changes

## 0.2.0

### 2026-07-27

- 将已确认的 Themis 设计规范统一迁入 `docs/design/**`，建立设计治理、架构、工作流、Core 与 Workspace 的单一权威入口
- 精简 `AGENTS.md`、`AGENTS.CN.md` 和文档导航为仓库协作与链接入口；旧 `docs/core/**`、`docs/workspace/**`、`docs/workflow.md` 和 `docs/runtime-environment.md` 保留为非规范兼容指针
- 校准 Init、Explicit Migration、Adapter、Protocol、Policy 与各 Kernel 模块的实现状态，并让待实施计划的未来文档目标指向 `docs/design/**`

### 2026-07-25

- 完成 P5 Requirement Questioning：新增 Step 0–4 的自适应追问 Prompt、Five Whys、Pre-mortem、Option Zero、AC 分段确认和对抗验证场景库
- 新增 `themis-spec/v1` Draft Spec 模板，持久记录复杂度、假设、证据、攻击处置、限制、回滚与用户批准；P5 不伪造机器生命周期迁移，确定性执行器留待 P8
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