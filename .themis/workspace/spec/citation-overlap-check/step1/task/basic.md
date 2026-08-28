# task/basic.md — citation-overlap-check / step1

> 本文件是详细设计+任务节点的实例工件之一。本节点的前置闸门与产出见 `flow.md`「详细设计+任务」节；basic/detail 的分段判据见 `rules.md` §4。以上只指向位置，本文件不复述其文字。

## 基础任务

**无。本段为空。**

判定依据见 `design.md`「basic/detail 分段」：`SPEC-OVERLAP-001` 虽带 `[basic]` 标识（specify 层的条目分类，§5），**但落地上不构成独立的准备任务**——子命令入口与检出逻辑必须同时存在才能被测试调用，拆开会产生一个自身无法验证的空壳。

**`[basic]` 标识与 basic 段不是一回事**，§5 与 §4 分管两层。七个已闭合 step 的 basic 段全部为空。
