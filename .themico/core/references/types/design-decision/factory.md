# design-decision factory

## type identity

`knowledge_type`: `design_decision`。

## 唯一 Zone

`project_knowledge`。CLI 会拒绝任何把 `design_decision` 绑定到其他 Zone 的候选或记录。

## 适用分类依据

材料主要回答"项目已决定什么以及为什么"——即已经做出、具有明确结论的一次性设计取舍，且这个取舍有背景、有理由、有后果。

## 不适用分类依据

- 若材料主要规定触发后必须、禁止或验证的动作，属于 `development_standard`，不选本类型。
- 若材料主要是从多次实践中归纳出的可复用观察经验（而非一次明确决定），属于 `development_experience`，不选本类型。

## 关联 reference

- L2 合同：`.themico/core/references/types/design-decision/l2.md`
- L3 合同：`.themico/core/references/types/design-decision/l3.md`
- 语义复核清单：`.themico/core/references/types/design-decision/semantic-check.md`
