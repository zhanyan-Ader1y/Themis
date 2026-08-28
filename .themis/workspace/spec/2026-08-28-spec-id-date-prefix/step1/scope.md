# scope.md — 2026-08-28-spec-id-date-prefix / step1

> 本文件是 step 定界节点的实例工件。本节点的前置闸门与产出见 `flow.md`「step 定界」节。以上只指向位置，本文件不复述其文字。
>
> **本文件的全部数字与存在性断言按 `template.md`「断言形态」记法书写，由本节点当场跑出。**

## 承担的上层分解项

`Intent.md`「step 分解」的唯一一项：把 spec-id 格式写进控制面，并按 R1 裁定改名既有八个实例。

## 本 step 边界

改 `template.md`（规定格式）；重命名 `.themis/workspace/spec/` 下八个目录；更新指向它们的引用。

## 与其他 step 的关系

**本需求只有一个 step。**

## 会触及或放宽的既有裁定与安全边界

**依 `flow.md` R2 节的交叉核查要求，本节先行列出。**

| 既有裁定 | 本 step 是否触及 |
| --- | --- |
| 「不改证据去迎合判据」 | **触及**。R1 已裁定：该原则保护记录的内容真实性，**不保护标识符的字面形态**。**效力边界已划**：只覆盖改名与随之的引用更新 |
| `themis` 不在只读白名单 | **触及**——判据要跑 `themis verify`。**照旧人工判** |
| 白名单只放行只读命令 | **不触及** |

## 核实到的、影响做法的四处事实

### （1）引用不全在 `.themis/workspace/` 内，有五份外部文件

本节点逐个 `grep -rl` 后核实，`.themis/workspace/spec/` 之外还有：

| 文件 | 出现的 spec-id 与次数 |
| --- | --- |
| `docs/superpowers/plans/2026-08-19-spec-flow-end-to-end-replay.md` | `core-removal` `41` 次 |
| `.themis/skills/spec-review-presentation/testing-notes.md` | 三个 id 合计 `15` 次 |
| `docs/plan/README.md` | 三个 id 合计 `5` 次 |
| `.themis/skills/spec-review-presentation/SKILL.md` | `core-removal` `1` 次 |
| `.claude/skills/spec-review-presentation/SKILL.md` | `core-removal` `1` 次 |

**另有 `docs/plan/spec-replay/` 与 `docs/superpowers/specs/` 下若干份。**

### （2）两处引用**不该**跟着改名，性质与其余不同

**这是本节点最要紧的核实。**

- **`SKILL.md` 第 `53` 行**——`core-removal` 出现在**反面示例**里，原文用它演示"读者不知道这代表什么意思"。**改成带日期的新 id，示例反而更不可读**，但那不是示例要教的东西；**更要紧的是：改了它，示例讲的就不再是当初那件事。**
- **`docs/superpowers/plans/2026-08-19-…md`**——该计划**规定**了 spec-id（原文"spec-id 固定为 `core-removal`"），是一份**历史执行记录**。**它记的是"当时规定用这个名字"这一事实**；改它等于篡改历史记录所陈述的内容。

**这两处落在 R1 裁定的效力边界之外**：R1 明写该裁定"不保护标识符的字面形态"，但同时写明"凡改动会使记录所陈述的事实发生变化的，仍属该原则禁止"。**这两处正是后者。**

### （3）改名后 `themis verify` 的断言会大面积失效

既有工件里有大量形如 `` `grep -c 'x' .themis/workspace/spec/<id>/...` `` 的断言。**改名后路径不存在，这些断言会从"通过"变成"执行失败"。**

**本节点实测确认该风险真实**：`grep -rc 'workspace/spec/core-removal' .themis/workspace/spec/` 有命中。

**处置须在设计阶段定**：断言里的路径是否随改名更新——**它属"记录的内容"还是"标识符的字面形态"，边界不自明**。

### （4）git 可追踪改名，历史不丢

`git mv` 保留历史，`git log --follow` 可跨改名追踪。**R1 已确认历史里的旧路径不追溯改写。**

## 本节点新暴露、不在 R1 已批准内容里的两处

**有两处**，均须交 R2 判定：

1. **事实（2）的两处例外**——R1 裁定"既有八个一并改名、`133` 处引用同步更新"，**未预见到有两处引用改了会篡改记录内容**。本节点主张这两处不改，但**不自行认定**。
2. **事实（3）的断言路径**——改名后既有工件里的路径断言会失效。**改与不改都有理由**，R1 未涉及。

## 命令证据

- `docs/superpowers/plans/2026-08-19-spec-flow-end-to-end-replay.md` 中 `core-removal` 出现次数：`41`
- `.themis/skills/spec-review-presentation/testing-notes.md` 中三个 id 合计：`15`
- `docs/plan/README.md` 中三个 id 合计：`5`
- 两份 `SKILL.md` 中各 `1` 次
