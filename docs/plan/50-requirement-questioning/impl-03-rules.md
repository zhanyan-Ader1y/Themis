# P5 子模块：常驻规则与模板契约

## 覆盖内容

- 更新 `templates/.themis/core/kernel/specification/rules.md`
- 更新 `templates/.themis/core/kernel/orchestrator/rules.md`
- 更新 `bin/themis-template-check.sh`
- 更新 `tests/template-contract/test.sh`

## 常驻规则

`specification/rules.md` 是被 Orchestrator 常驻 import 的领域入口，必须保持在现有 50 行契约内。它只保留：

- Responsibility、Inputs、Outputs、Boundaries；
- P5 Step 0–4 的简洁路由；
- policy、Prompt 和 Draft Spec 的引用；
- P5 只能记录批准证据、P8 才能写状态迁移的边界。

详细的 Five Whys、Red Flags、自检和攻击场景不进入常驻 import 图，统一由两个按需 Prompt 模板承担。Orchestrator 移除“later questioning”占位语，但继续禁止没有持久状态或确定性执行器的生命周期迁移声明。

## 模板检查器

检查器保持 Bash 3.2 兼容、只读且只检查确定性结构：

1. P5 policy、两个 Prompt、`spec.yaml` 模板、v2 protocols 与 executor 必须存在。
2. `specification.yaml` 必须含正确 policy schema、三档复杂度、三种 flow、六维攻击、五项快速检查、三种处置、4+6 项自检。
3. `transitions.yaml` 必须含 keyed-map `draft_to_specified`，明确 `draft`/`specified`，并含八个稳定 validator check ID。
4. `spec.yaml` 必须使用 `themis-spec/v2` 与模板版本 2；独立 `templates/spec.md`、Artifact v1 支持或对应迁移脚本必须被拒绝。
5. 追问 Prompt 必须保留 Step 0–4；攻击库必须保留快速检查和六维标题。
6. 所有已 import 的领域规则（包括 Specification）继续不超过 50 行。

检查器不验证“根因正确”“AC 足够”“用户确实理解”或“批准语义有效”；这些由 Prompt 和人工门禁负责。

## TAP 回归

隔离夹具覆盖：

- v2 Spec schema、template 或 executor 缺失；
- transition map 不存在、条件数错误或稳定 ID 被替换；
- 快速检查或攻击维度数不正确；
- 预发布 `templates/spec.md`、Artifact v1 支持或对应迁移脚本重新出现；
- Step 4 或攻击标题被删除；
- Specification 常驻规则超过 50 行。

每个场景断言稳定诊断片段，所有写操作限制在临时夹具内。Shell 脚本中的新函数和控制流必须保留准确中文注释。

## 验证

```bash
bash -n bin/themis-template-check.sh
```

```bash
bash -n tests/template-contract/test.sh
```

```bash
shellcheck bin/themis-template-check.sh
```

```bash
shellcheck tests/template-contract/test.sh
```

```bash
bash bin/themis-template-check.sh
```

```bash
bash tests/template-contract/test.sh
```
