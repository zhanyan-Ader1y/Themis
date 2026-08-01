# themis-skill-creator 设计

> 日期：2026-08-01
> 状态：待书面审阅
> 范围：创建或修改 Skill

## 1. 目标

新增独立的 `themis-skill-creator`，用于根据用户需求创建新 Skill 或修改已有 Skill。

它只负责 Skill 创建本身，不接入 Themis 的 Request Intake、Plan、Review、Approval、Capability、policy、Verification 或 lifecycle，也不改变 Plan 35 的控制流程。

安装位置：

```text
templates/.claude/skills/themis-skill-creator/
```

## 2. 实现基础

实现必须先完整复制以下 upstream 目录：

```text
repository: https://github.com/obra/superpowers
source path: skills/writing-skills
source commit: 44c9b2d6e889982ac18c27d05a19fefe335194e1
license: MIT
```

复制目标：

```text
templates/.claude/skills/themis-skill-creator/
```

复制完成后再在副本上修改身份、description 和正文。Anthropic `skills/skill-creator` 与本地 `C:\Coding\Jess2\.claude\skills\tool-jskill-creator` 只作为内容参考，不作为复制基础。

适配后的 Skill 必须保留可追溯的 upstream 来源与 MIT 许可信息。复制后未再使用的文件可以删除，不为保持目录外观而保留无关资产。

## 3. Creator 职责

`themis-skill-creator` 只执行以下工作：

1. 理解用户要创建或修改的 Skill；
2. 在修改已有 Skill 时读取其当前内容；
3. 必要时检查相邻 Skill，避免名称或职责明显重复；
4. 创建或修改 `SKILL.md`；
5. 只有实际内容需要时才增加 Markdown 参考文件、脚本或资源；
6. 检查生成结果是否完整、引用是否存在、是否仍有占位内容。

默认只创建：

```text
<skill-name>/
└── SKILL.md
```

不得为了通用性预先增加目录、Schema、状态机、Proposal 格式、评测框架或发布机制。

## 4. Description 编写要求

Description 是 Agent 在加载 Skill 正文前的发现与选择依据，必须简洁说明：

- Skill 能完成什么；
- 适用于什么用户意图或场景；
- 会产生什么关键结果。

推荐形式：

```text
完成什么任务并产出什么结果。适用于哪些用户意图或场景。
```

Description 不得写入：

- Skill 的实现步骤或阶段顺序；
- 内部算法、判断过程或工具链；
- 脚本、命令、Agent 或其他 Skill 的名称；
- 内部文件布局和实现架构；
- 权限、停止条件、失败处理和边界清单；
- “改用另一个 Skill”的路由说明；
- 与实际能力无关的营销语言或关键词堆砌。

`themis-skill-creator` 自身建议使用：

```text
创建或修改可复用 Skill，生成结构清晰、可直接使用的 SKILL.md 及必要资源。适用于新增 Skill 或调整现有 Skill 的职责、description 和正文内容。
```

## 5. Markdown 与 YAML 边界

Creator 的说明、流程、约束、示例和检查项全部使用自然语言 Markdown。

不得为 Creator 增加：

- YAML 输出合同；
- YAML Proposal；
- YAML 状态或路由表；
- YAML Skill 模板；
- 仅为结构化展示而存在的 YAML 文件。

`SKILL.md` 顶部由 Claude Code 宿主强制要求的最小 frontmatter 只保留 `name` 和 `description`。这是宿主发现元数据，不用于表达 Creator 的流程、状态或产品合同；这些内容必须保留在 Markdown 正文中。

## 6. 简化工作方式

```text
读取用户的创建或修改需求
→ 读取目标 Skill 或必要的相邻 Skill
→ 确定最小文件结构
→ 编写或修改完整内容
→ 检查 description、引用和占位内容
→ 返回实际创建或修改结果
```

Creator 可以直接完成用户授权的本地 Skill 文件变更，不需要生成中间 Proposal，也不需要把结果转交给 Themis 流程。

## 7. 不包含的功能

本设计不增加：

- Themis Intake 或 lifecycle 集成；
- Plan 35 route 或 Capability；
- Skill Creation Proposal；
- YAML envelope 或 Schema；
- 固定正负例数量、命中率或误触发率门槛；
- 独立 Agent 调度或评测系统；
- Skill 注册表、打包、发布或同步；
- 功能版本、upgrade 或 migration。

## 8. 完成条件

1. upstream `writing-skills` 目录先被完整复制到目标位置；
2. Skill identity 改为 `themis-skill-creator`；
3. Creator 能创建新 Skill 并修改已有 Skill；
4. 默认产物只有完整的 `SKILL.md`；
5. 额外文件只在目标 Skill 实际需要时创建；
6. description 明确能力、场景与关键产出，不描述实现细节；
7. Creator 正文和参考内容使用自然语言 Markdown；
8. 除宿主强制的最小 frontmatter 外，不增加 YAML；
9. Creator 不引用或接入 Themis 控制流程；
10. 不保留未引用的 upstream 资产；
11. upstream 来源和 MIT 许可可追溯；
12. 不引入本设计明确排除的附加功能。
