# specify.md — 2026-08-26-workspace-cleanup / step1

> 本文件是抽象设计（specify）节点的实例工件。本节点的前置闸门、产出、失效波及与失败去向见 `flow.md`「抽象设计（specify）」节；EARS 句式要求见该节所引 `SPEC-EARS-001`，`[basic]` 标识含义见 `rules.md` §5。以上各处只指向位置，本文件不复述其文字。
>
> 每条行为条目的验收判据写成**可执行命令加可判定语义**——不写"删干净了"这类笼统读法。这一点采自 `2026-08-19-core-removal` replay 的结论：verify/detail 之所以零漂移，靠的是判据在本节点就被写成可执行形态（`docs/plan/spec-replay/drift-log.md`「总结」）。

## 行为条目

### SPEC-WSCLEAN-001

`templates/.themis/` 目录必须不存在。

**验收判据**（命令 + 可判定语义）：

```bash
test -e templates/.themis && echo PRESENT || echo GONE
find templates/.themis -type f 2>/dev/null | wc -l
```

通过条件：第一条输出 `GONE`，第二条输出 `0`。

**为什么这样写**：不用 `git ls-files` 判——那只反映索引，删除后若工作区仍有未跟踪残留文件，索引会显示干净而目录实际还在。两条命令一条判存在性、一条判文件数，同形陷阱各自排除。

### SPEC-WSCLEAN-002

`.gitignore` 必须不含任何针对 `.themis/` 控制面的忽略规则。

**验收判据**：

```bash
grep -nE '^/?\.themis/(spec|skills)/?$|^/?\.themis/(README|CLAUDE\.themis)\.md$' .gitignore | wc -l
```

通过条件：输出 `0`。

**为什么用这个模式**：只匹配那四条控制面忽略规则，不匹配 `.gitignore` 里可能存在的其他 `.themis` 相关行（例如将来若有 `.themis/cache/`）。**不接受"grep 全文无 themis"这种宽读法**——那会把无关规则也判成违规。

### SPEC-WSCLEAN-003

控制面四份文件必须在 git 中可得，且内容与本 step 落地前的包源逐字相同。

**验收判据**：

```bash
for f in README flow rules template; do git ls-files --error-unmatch ".themis/spec/$f.md" >/dev/null 2>&1 && echo "$f TRACKED" || echo "$f UNTRACKED"; done
for f in README flow rules template; do git show <落地前基线>:templates/.themis/spec/$f.md | diff -q - ".themis/spec/$f.md" >/dev/null && echo "$f SAME" || echo "$f DIFF"; done
```

通过条件：四份全部 `TRACKED`，且四份全部 `SAME`。`<落地前基线>` 取本 step impl 开始前的 HEAD，由 impl 节点如实记录并在 verify 中引用。

**这是本 step 最重要的一条判据**。它同时验证两件事：控制面**在 git 中存在**（不是只剩一份被忽略的工作区副本），且**内容未在迁移中被改动**。`Intent.md`「范围与非做」明写本需求只改变存放位置与入库方式、正文一字不动，本条即该约束的可执行形态。

### SPEC-WSCLEAN-004

仓库中必须不存在指向已删内容的活引用。

**验收判据**：

```bash
grep -rn 'templates/\.themis' --include='*.md' . \
  --exclude-dir=.git --exclude-dir=.claude --exclude-dir=docs \
  --exclude-dir=workspace | wc -l
```

通过条件：输出 `0`。

**排除项的理由**（逐项，不可省略）：

- `docs/` — 历史记录与归档证据，`Intent.md`「约束」明写不得改写。含 `docs/plan/retired/`、`docs/superpowers/plans/`、`docs/plan/spec-replay/`。
- `.themis/workspace/` — 本 spec 与 `2026-08-19-core-removal` 的实例工件。**它们必须记录被删除的路径本身**，否则无法说明删了什么。这与 `2026-08-19-core-removal` replay 中记下的同型订正一致（`drift-log.md`：要求记录删除、同时要求全仓不出现被删路径，两者自相矛盾）。
- `.git/`、`.claude/` — 非仓库内容。

### SPEC-WSCLEAN-005

Go 侧构建与既有测试必须仍然通过。

**验收判据**：

```bash
go build ./... && echo BUILD_OK
go test ./... 2>&1 | grep -c '^ok'
go test ./... 2>&1 | grep -c '^FAIL'
```

通过条件：`BUILD_OK`；`ok` 计数不少于落地前基线（`2026-08-19-core-removal` step1 验证时为 10）；`FAIL` 计数为 `0`。

**为什么要这条**：本 step 删的全是 Markdown，理论上不该影响 Go 代码。**若影响了，说明有隐藏依赖**——这正是要测出来的东西。同一理由在 `2026-08-19-core-removal` step1 已用过一次，当时通过。

## 来源覆盖

每条行为条目的事实依据，及其对 `Intent.md` 达成状态的覆盖关系：

| 条目 | 覆盖的达成状态 | 事实来源 |
| --- | --- | --- |
| SPEC-WSCLEAN-001 | 第 1 项（目录不存在） | 代码#`templates/.themis/`（48 个文件，`Intent.md` 命令 9） |
| SPEC-WSCLEAN-002 | 第 2 项（忽略规则删除） | 代码#`.gitignore`（四条规则原文） |
| SPEC-WSCLEAN-003 | 第 3 项（控制面入库且内容不变） | 代码#`.themis/spec/`（四份，与包源逐字相同，`scope.md` 比对表）；用户确认#.themis/ 改为入库 |
| SPEC-WSCLEAN-004 | 第 4 项（无残留索引） | 代码#`templates/.themis/README.md:44-51`、`CLAUDE.themis.md:7,71-77`（`Intent.md` 命令 7） |
| SPEC-WSCLEAN-005 | 无（横切保护，非达成状态之一） | 代码#`cmd/themico`、`internal/themico`（39 个 Go 源文件，`Intent.md` 命令 8） |

**`[basic]` 标识：五条均不带。** 依 `rules.md` §5，该标识只用于契约存在性形态的条目；本 step 全是删除与移动，无一条在建立新的契约存在性。这与 `2026-08-19-core-removal` step1 的判定结果相同（该 step 四条行为条目同样全不带 `[basic]`）。

**一处未被上述条目覆盖、须由 design 处理的事**：`scope.md` 标出的 `skills/` 两份 SKILL.md 与顶层两份 md **没有安装副本**，只存在于包源一侧。SPEC-WSCLEAN-003 只约束 `spec/` 四份，因为只有它们有"落地前包源"可比对。这两组的去留由 design 决定；**若 design 决定保留它们，须在此新增对应行为条目并重走 R2**——不得在无判据的情况下落地。
