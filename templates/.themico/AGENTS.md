# `.themico` 模块规范

本文件是 `.themico` 安装包的模块级约定，约束**修改本模块的人**。跨模块约定见仓库根 `AGENTS.md`。

模块的完整设计见 `docs/superpowers/specs/2026-07-29-themico-design.md` 及同目录的主题 reference；首个可用交付的边界见其中的 `first-usable-delivery.md`。

## 控制面与工作区分离

```text
.themico/
├── core/       控制面：Skill references 与 type factories
└── workspace/  工作区：受治理的 store
```

`core/` 保存 Prompt-level 语义合同，由 Human 与 Agent 阅读。`workspace/` 保存机器权威 payload，**只能由 `themico` CLI 通过受治理操作写入**。

两者不得互相写入：control-plane reference 的变化不产生 generation，store 的 commit 也不修改 `core/`。

宿主发现入口不在包内——`SKILL.md` 随包放在 `templates/.themis/skills/themico/`，安装后到目标项目的 `.claude/skills/`，因为宿主只从那里发现 Skill。它只负责转发，语义合同仍在 `core/`。

## 三方分权

这是本模块最容易被写坏的边界，任何改动都不得削弱它：

- **Agent** 只产生 proposal、candidate content、semantic assessment、relevance decision 与 explanation。它不能产生 published、current 或 valid authority。
- **Human** 拥有类型确认与 publication 授权，两者是**两个独立的 gate**，互不替代。
- **CLI** 是唯一 machine authority：身份、revision、digest、source binding、currentness、提交。它不判断自然语言内容是否正确，也不声称验证了 `approved_by` 背后的真人——只校验授权工件的结构与精确绑定。

## 禁止的加载与写入方式

- 同时加载全部 operation reference 并混合多个操作；
- 为已有记录加载多个 factory 后由 Agent 投票选类型；
- 依据目录名自动注册新类型；
- 让 type factory 直接写 record 或 current pointer；
- 用 Python、Shell、PowerShell、`jq`、`yq` 或手工 JSON 替代 CLI operation，或直接编辑 `.themico/workspace/`；
- 在 MCP adapter 或 Themis lifecycle 尚未另行设计时声称已经接线。

## 类型路由

已有正式记录的 factory **只能由持久化的 `knowledge_type` 决定**。

禁止根据 title、summary、tags、L2 payload 或 L3 正文重新解释类型——即使标题写着"一次失败经验"，persisted type 为 `design_decision` 时也只能选 design-decision factory，由校验流程暴露内容错配。

新 candidate 先用 lightweight classification registry 提出唯一 `proposed_type`，再只加载该类型的一个 factory；不预加载三个 factory 让 Agent 挑。

## 失败关闭

CLI 不可用、registry 缺失、current generation 非法、投影绑定失效或授权不完整时，只能形成 draft 并报告 unavailable。

不得持久化正式 record，不得声称 draft 已 published、current 或 valid，不得用脚本模拟产品能力。

## 已知缺陷

以下三条已在 `README.md` 如实披露，改动本模块时不得声称它们已解决：

1. `l1.json` 与 `l2.json` 在磁盘上字节相同——物理层的 L1/L2 分离目前是假的。
2. L1/L2/Scope 缺少独立字节上限，仍可构造发布后 depth-3 读不回的记录。
3. assessment 独立性在 `create → revise → confirm-type → assess` 顺序下被削弱——`ConfirmType` 会覆写 `RevisedBy`，原 reviser 可自评。第二道 Human Approval gate 未受影响。
