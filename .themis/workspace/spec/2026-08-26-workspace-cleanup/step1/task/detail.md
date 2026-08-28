# task/detail.md — 2026-08-26-workspace-cleanup / step1

> 本文件是详细设计 + 任务节点的产出之一。判定与归属条款位置见 `task/basic.md` 开头的指向，本文件不重复。
>
> **本段承担全部落地。** basic 段为空，判定依据见 `task/basic.md`「判定依据」。六条任务**按编号顺序执行，次序不可颠倒**——次序由本文件的依赖声明承担，不由段间闸门承担（`rules.md` §4 末段）。

### T-D1

**删除 `.gitignore` 中针对 `.themis/` 控制面的四条忽略规则。**

- 对象：`.gitignore` 中 `/.themis/spec/`、`/.themis/skills/`、`/.themis/README.md`、`/.themis/CLAUDE.themis.md` 四行，以及它们上方那段说明其理由的注释（"安装到本仓库的 Themis 控制面副本……入库即两份控制面，改一处忘另一处就是漂移"）。注释与规则同去——理由已随两层模型取消而消失，留着即成误导。
- 依赖：无。**本任务必须最先执行。**
- 出处：`design.md`「结构决策」第 1 条；判据 SPEC-WSCLEAN-002。

### T-D2

**把 `.themis/spec/` 四份控制面文件入库。**

- 对象：`.themis/spec/README.md`、`flow.md`、`rules.md`、`template.md`。
- 做法：`git add`。**内容一字不动**（`Intent.md`「范围与非做」）。
- 依赖：**T-D1**——忽略规则未删前 `git add` 会被忽略规则挡住。
- 出处：`design.md`「结构决策」第 1 条；判据 SPEC-WSCLEAN-003。

### T-D3

**把三份只存在于包源的文件迁入 `.themis/` 并入库。**

- 对象与目标位置：
  - `templates/.themis/skills/themis/SKILL.md` → `.themis/skills/themis/SKILL.md`
  - `templates/.themis/skills/themico/SKILL.md` → `.themis/skills/themico/SKILL.md`
  - `templates/.themis/AGENTS.md` → `.themis/AGENTS.md`
- 做法：`git mv`，使迁移在 git 中记为 rename、内容逐字保留。
- 依赖：**T-D1**（忽略规则未删前 `.themis/skills/` 仍被忽略）。
- 出处：`design.md`「结构决策」第 2 条。
- **无判据覆盖**：R2 裁定 B 定为不补 SPEC-WSCLEAN-006。本任务的正确性不受判据保护，impl 节点须如实记录实际路径与内容比对结果，verify 节点须写明该范围不在断言范围内（`design-review.md`「裁定 B」）。

### T-D4

**删除 `templates/.themis/` 剩余全部内容。**

- 对象：T-D3 迁走三份后剩余的 45 个文件——`workspace/` 39 份、`spec/` 4 份、顶层 `README.md` 与 `CLAUDE.themis.md` 2 份。删除后 `templates/.themis/` 目录本身不存在。
- 依赖：**T-D2 与 T-D3**。这是本 step 唯一的真实风险点（`Intent.md`「核心链路」）：若在 T-D2 前执行，控制面将在 git 中出现空窗。
- 出处：`design.md`「架构与边界」；判据 SPEC-WSCLEAN-001。

### T-D5

**改写仓库中五处指向已删内容的活引用。**

- 对象与做法：
  - `AGENTS.md:13` — 模块规范索引表，改指 `.themis/AGENTS.md`（该文件由 T-D3 迁至此）。
  - `AGENTS.md:48-52`「安装包与项目工作区的边界」整节 — 描述的正是本 step 取消的两层模型，整节删除或改写；具体做法在落地时依实际文本定，并在 impl 工件中如实记录所选做法。
  - `README.md:44` — 指向将被删的 `templates/.themis/README.md`，删除该条。
  - `README.md:56` — themico 公共 Skill 入口，改指 `.themis/skills/themico/SKILL.md`。
  - `CLAUDE.md:5` — 复核其中 `templates/.themis/**/README.md` 一句；该路径下已无 README，须改写。
- 依赖：T-D4（先删后改，避免改完又被删除动作影响）。
- 出处：`design.md`「结构决策」第 4 条；判据 SPEC-WSCLEAN-004。

### T-D6

**改写 `templates/.themico/AGENTS.md:19` 的路径引用。**

- 对象：该行中 `templates/.themis/skills/themico/` 改为 `.themis/skills/themico/`。
- 依赖：T-D4。
- 出处：`design.md`「结构决策」第 3 条；判据 SPEC-WSCLEAN-004。
- **越界已获批准**：该文件在 `Intent.md`「范围与非做」之列，R2 裁定 A 明确接受本行改动。**批准范围仅限本行路径**——该包其余 26 份 reference 与其两层包源模型不得触碰（`design-review.md`「裁定 A」效力边界）。

---

## 依赖关系

```text
T-D1（删忽略规则）
 ├→ T-D2（控制面入库）──┐
 └→ T-D3（迁三份文件）──┴→ T-D4（删 templates/.themis/）
                                ├→ T-D5（改五处活引用）
                                └→ T-D6（改 themico 一行）
```

**T-D1 → T-D2 是本 step 的关键次序**：颠倒即出现控制面在 git 中不存在的窗口。

无任何任务依赖 `task/basic.md` 中的条目（该段为空），故无孤儿。
