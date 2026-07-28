<h1 align="center">Themis</h1>

<p align="center"><strong>面向团队的 repo-local 规范驱动 AI Coding Harness</strong></p>

Themis 围绕四项产品特点组织受治理的软件交付：

- **Spec 前追问**：发布 Spec 前，先澄清意图、范围、假设、约束和验收条件。
- **更轻松的 Spec Review**：通过提取plan将待review内容按需生成**时序/流程图**进行overview，并自顶向下的列出总结后review项，降低评审者理解成本，提高效率。。
- **外部经验可沉淀**：让脱离Themis得出的经验能主动纳入知识库中，不随对话消失。
- **不断进化的项目知识库**：通过受治理的知识积累，将经过事实核验和人工批准的经验沉淀为可追溯的多层级的项目 Context。

## 当前状态

当前工作树保留 Themis 的规则、策略、协议、模板和 `Themis-Q` 提问方法，但没有生产安装器、Spec/Context 确定性执行器、生命周期运行时或可执行回归套件。声明式文件描述合同，不证明相应能力已经可执行。

下一阶段按严格顺序实施：

```text
35 Core Prompt Flow
  → 36 Deterministic Assurance
      → 37 Native Go Runtime
```

35 先让四项特点通过 Prompt、持久语义工件、人工确认和真实工具观察端到端运行；36 固定语言无关的 schema、projection、currentness、transaction 与 conformance contracts；37 以单进程 Go CLI 提供第一套新的生产确定性运行时。

Multi-Agent execution 和 Attribution analytics 是可选能力，不进入核心依赖图。Upgrade、Migration 和 Behavior Map 已退役。所有业务模块只维护唯一当前合同，不使用功能性 `v1`、`v2` 目录或标识。

## 生命周期

```text
Draft → Specified → Planned → Reviewed → Implemented → Verified
      → Human Acceptance → Summary → Archived
```

Review 固定在 Implementation 前；Verification 固定在 Implementation 后；只有 current Verification `pass` 且 Human Acceptance `accepted` 后才能生成 Summary。

## 文档

- [安装包与模块合同](templates/.themis/README.md)
- [更新日志](CHANGES.md)

## 使用边界

当前没有可运行的 Init 或已安装项目运行时，因此本 checkout 不提供安装命令。未来 Plan 37 的目标是预编译 `themis` 可执行文件、fresh-only Init、跨平台离线分发和无生产 Shell fallback；在该计划完成并验证前，不得把目标能力描述为当前可用。

## 许可证

本项目采用 [MIT License](LICENSE)。
