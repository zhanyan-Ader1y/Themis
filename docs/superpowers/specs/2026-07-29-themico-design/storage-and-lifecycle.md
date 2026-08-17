# 存储、来源绑定与生命周期

## 1. 主题责任

本文定义 `.themico` 本地包布局、不可变对象、generation-directory commit、source binding、current/history 和正式生命周期操作。自然语言内容是否正确不属于存储层判断。

## 2. 包布局与控制面/工作区分离

Themico 安装到仓库根目录的 `.themico/`，并按 Themis 的既有划分把控制面与工作区分开：

```text
<repository-root>/.themico/
├── core/         控制面：Skill references 与 type factories
└── workspace/    工作区：受治理的 store
```

`core/` 保存 Prompt-level 语义合同，由 Human 与 Agent 阅读，不由 store 的 generation commit 写入。`workspace/` 保存机器权威 payload，只能由 `themico` CLI 通过受治理操作写入。两者不得互相写入：control-plane reference 的变化不产生 generation，store 的 commit 也不修改 `core/`。

宿主发现入口不在包内。公共 `SKILL.md` 位于 `.claude/skills/themico/SKILL.md`，因为 Claude Code 只从 `.claude/skills/` 发现 Skill；它只负责转发，语义合同仍在 `.themico/core/` 中。

## 3. 固定 workspace 布局

受治理 store 布局固定为：

```text
<repository-root>/.themico/workspace/
├── store.json
├── candidates/<candidate-id>/revisions/<candidate-revision>/
│   ├── candidate.json
│   └── content.md
├── records/<record-id>/revisions/<record-revision>/
│   ├── record.json
│   └── content.md
├── projections/<record-id>/<record-revision>/
│   ├── l1.json
│   └── l2.json
├── preparations/<prepare-id>/prepare.json
├── assessments/<assessment-digest>.json
├── approvals/<approval-digest>.json
└── generations/
    └── gen-<20 位十进制 generation>/
        ├── manifest.json
        └── views.json
```

store root 是 `.themico/workspace/`，不是 `.themico/`。所有 immutable payload 路径、generation directory 和 root containment 检查都以 workspace 为界；`core/` 不在 store 的可写根内。

初始化只拥有 `workspace/`。`.themico/workspace/` 已存在时，`themico init` 必须在任何写入前失败，不接管、转换或修复未知现有 store。`.themico/` 或 `.themico/core/` 已存在不构成失败条件：控制面与工作区可按任意顺序安装，init 按需创建缺失的包目录与空 `core/`，且不读取、改写或删除既有 control-plane 内容。

初始化在 `.themico/` 内构造完整 staging store，完成文件与目录持久化后以单次 rename 发布为 `workspace`。rename 前中断只留下 staging 残留，不产生可见 store；发布瞬间 `workspace` 已出现时必须失败，不替换既有目录。init 新建 `.themico/` 或 `core/` 时必须在其中发布任何内容前持久化该目录项。

初始化失败时只回收本次创建且仍为空的目录，不删除既有 control-plane 内容，也不删除并发 writer 已写入的内容。

repository-relative source path 相对仓库根解析，而不是相对包目录或 workspace。

## 4. 不可变 payload

以下对象一旦写入不得覆盖或原地修改：

- candidate revision；
- record revision；
- L1/L2 projection；
- prepare artifact；
- semantic assessment；
- Approval；
- generation manifest 与 views。

内容、来源、关系或状态变化都创建新 revision 或新对象。未被任何合法 generation 引用的对象可能是中断残留，但不构成 current authority，也不得由查询默认返回。

## 5. generation-directory commit

`generation-directory` 是唯一改变可见 current state 的提交边界。

每个 generation manifest 必须包含自身 generation、parent generation、parent manifest digest、current candidate/record pointers、projection references 和自身 canonical digest。合法 current generation 必须满足：

- 从 generation 0 开始连续；
- 每个 parent generation 与 parent digest 精确匹配；
- generation directory、manifest 和 views 完整；
- manifest 引用的不可变 payload 存在且 digest 匹配；
- 当前 generation 是完整合法链中的最高编号。

一次 mutation 的提交顺序固定为：

1. 读取并绑定 expected generation；
2. 写入新的不可变 payload，拒绝覆盖既有路径；
3. 在 `generations` 的同一父目录写完整 staging generation；
4. 持久化文件与目录；
5. rename 到新的、此前不存在的 `gen-<number>`；
6. 只有 rename 成功后，新 generation 才可见。

rename 前中断、staging 残留或 orphan payload 不改变 current state。两个 writer 基于相同 expected generation 时只能有一个成功；失败方返回 conflict，不得覆盖获胜 generation 或自动改基线重试。

Themico 不提供通用 rollback。可见状态的后续修正通过新的受治理 generation 表达。

## 6. current 与 history

- manifest 中的 current pointer 是正式 currentness 的唯一机器来源；
- 默认查询只返回 current active record revisions；
- superseded、deprecated、archived 和旧 revision 只在显式 history 请求中读取；
- record payload、投影和生命周期状态必须共同绑定到确切 revision；
- 历史保留不等于历史内容仍然 current；
- 文件修改时间、目录排序或“最新写入”的 payload 不能代替 manifest current pointer。

## 7. 本地 source binding

正式 source 首批只支持仓库根下的 repository-relative 本地文件，解析基准是仓库根，不是包目录或 workspace。每个 source binding 至少保存规范化相对路径、实际 source bytes 的 digest，以及绑定它的 candidate 或 record revision。

CLI 必须：

- 拒绝绝对路径和 `..` escape；
- 拒绝 symlink 或 junction 导致的 root escape；
- 读取实际 bytes，而不是信任 Agent 提供的 digest；
- 使用 `sha256:<64 位小写十六进制>` 保存 digest；
- 在 validate、prepare 和 apply 前重新读取 source，发现漂移时返回 stale 或对应校验失败；
- 保留旧 revision 当时的 source digest，不因源文件变化回写历史。

URL 抓取、远程文档、仅在对话中存在的来源和未物化外部来源不属于当前正式 source。可先作为 draft 说明，但不能伪装成已完成的 source binding。

## 8. machine JSON 与 digest

所有 machine JSON：

- 使用 UTF-8；
- 拒绝未知字段；
- 拒绝重复 key；
- 拒绝浮点数；
- 拒绝尾随的第二个 JSON 值；
- 使用项目定义的 canonical JSON 计算 digest。

canonical JSON 的 object key 按 Unicode code point 排序，array 保持原顺序，整数使用最短十进制表示，不输出无意义空白。digest 格式固定为 `sha256:<64 位小写十六进制>`。

## 9. 生命周期语义

### 9.1 publish

publish 从已确认类型、通过机器校验和 semantic assessment 的 candidate 创建新的 active record。publish 必须有精确绑定 prepare 的 Human Approval，并在一个 generation 中同时写入 record、投影、assessment、Approval 与 current pointer。

### 9.2 supersede

supersede 用于同一知识语义身份的正式替代。一次原子提交必须：

- 发布新的 active record；
- 为旧 record 创建 status 为 superseded 的新 revision；
- 由治理操作为新记录生成指向旧记录的 `supersedes` relation；
- 更新 current pointers 与投影；
- 保留旧内容及全部历史。

CLI 校验结构、binding 和原子性，不判断两条自然语言内容是否确属同一语义身份；该判断由 semantic assessment 与 Human Review 承担。

### 9.3 deprecate

deprecate 表示知识已不建议继续采用，但仍需保留审阅、追溯或历史查询。操作创建新的 record revision，复用已绑定内容，保存 reason 与 Approval，并将 status 改为 deprecated。默认查询排除该 revision。

### 9.4 archive

archive 表示知识退出日常 current 使用，但仍完整保留。操作创建新的 archived revision，保存 reason 与 Approval，不物理删除 record、content、source、关系或历史投影。默认查询排除该 revision。

### 9.5 跨类型派生

跨类型提炼不是 supersede，也不是原地改型。它必须创建新 candidate，经独立类型确认、assessment、prepare、Approval 和 publish，并以 `derived_from` 指向原记录。原记录不会因派生自动改变状态。

## 10. 安全与容量边界

当前实现合同要求：

- 单个 machine JSON 输入不超过 1 MiB；
- 单个 L3 Markdown 当前实现上限为 128 KiB（由 `query.Inspect` depth=3 读取时 canonical 的 1 MiB machine JSON envelope 硬上限反推得出，确保发布的内容一定能被读回；恢复到接近本节其余各项所暗示的更大数量级，需要先解决该 envelope 预算模型本身，属后续独立计划）；
- 单个 source file 不超过 16 MiB；
- 超限返回 `validation_failed`，不截断并继续治理；
- 时间由 CLI 使用 UTC `RFC3339Nano` 生成；
- 正式 ID 由 `crypto/rand` 生成 16 bytes，使用固定前缀加 32 位小写十六进制编码，不接受 Agent 自选 ID；
- 不使用 Python、Shell、PowerShell 或临时脚本代替存储与治理能力。
