# Themico 核心验收标准

## 1. 使用方式

本文定义后续实现必须提供的可运行验收证据。计划、代码存在、提交成功或文档声明本身都不能替代 fresh test、CLI replay 和文件系统观察。

每条验收必须映射到唯一的自动测试、集成测试或人工 replay。无法在当前平台证明的条件必须标记 GAP 或 unavailable，不能推断为通过。

## 2. 知识模型与类型

1. **原子记录**：一次治理操作的身份、lifecycle、sources/authorization、typed relations、L1、L2 和 L3 全部绑定到同一 Knowledge Record revision；聚合 view 只包含 current record ID 索引，不嵌入 L1 bytes，也不拥有独立语义。
2. **三个类型闭集**：registry 恰好接受 `design_decision`、`development_standard`、`development_experience`，拒绝未知类型和目录自动发现类型。
3. **Zone compatibility**：前两种类型只允许 `project_knowledge`，`development_experience` 只允许 `project_experience`；错误组合失败且不写入。
4. **读取深度**：每条记录都能独立返回 L1、L2、L3；scope 中的 project、domain、architecture unit 和 feature 不会被解释为 L1/L2/L3 层级。
5. **L1/L2/L3 合同**：三种类型共享 L1 和 L2 公共头部，分别严格校验类型化 L2 payload 与固定 L3 中文 Markdown 章节；未知字段、错配字段、缺失或乱序 H2 被拒绝。

## 3. 类型确认与跨类型派生

6. **Human 类型确认**：未确认类型的 candidate 不能 publish；确认工件必须绑定确切 candidate ID/revision，CLI 只在 registry 和 Zone compatibility 通过后固化 `knowledge_type`。
7. **类型不可原地改变**：类型固化后 revise 不能改变类型，已有正式记录的 factory 只能由持久化 `knowledge_type` 选择。
8. **跨类型派生**：从 `development_experience` 提炼 `development_standard` 时创建新的 candidate 与 record，并以 `derived_from` 连接原记录；原记录类型、current 内容和 lifecycle 不被原地修改。

## 4. 来源、assessment 与 Human Approval

9. **来源 digest**：CLI 对 root-relative 本地 source 读取实际 bytes 并保存 `sha256:` digest；绝对路径、`..`、symlink/junction escape、不存在文件、超限文件和 source drift 被拒绝或标记 stale。
10. **语义 assessment 分权**：Agent assessment 与 candidate revision 精确绑定，checker identity 不能等于 proposer identity；CLI 只校验结构和绑定，不判断 notes 是否正确。
11. **Human Approval**：publish、supersede、deprecate、archive 缺少 Approval 时失败；Approval 必须精确绑定 operation、prepare identity 与 digest，错误或过时 Approval 不产生任何 current 变化。
12. **身份声明边界**：测试与文档不把 CLI 字段校验描述为人的真实身份验证。

## 5. 存储、提交与并发

13. **初始化安全**：`.themico` 不存在时初始化 generation 0；已存在时在任何写入前失败，既有 bytes 不改变。
14. **generation commit**：只有完整 staging generation rename 到新的 generation directory 后，新 state 才可见；rename 前故障和 orphan payload 不进入 current 查询。
15. **连续 current chain**：CLI 只接受从 generation 0 连续连接、parent digest 正确且 payload 完整的最高 generation；编号更高但断链的目录不能成为 current。
16. **并发 conflict**：两个 writer 基于同一 expected generation apply 时恰好一个成功，另一个返回 conflict；失败方不能覆盖获胜 generation。
17. **历史保留**：publish、supersede、deprecate 和 archive 都不物理删除旧 revision 或内容；默认查询与显式 history 查询结果符合 lifecycle status。
18. **生命周期原子性**：supersede 在同一 generation 发布新 active record、创建旧 superseded revision 和 system-managed `supersedes` relation；任一 gate 失败时双方都不改变。

## 6. 查询、预算与关系

19. **渐进查询**：默认查询只返回指定 Zone 中 current active L1；L2/L3 必须通过 exact record IDs 请求，history 与跨 Zone 扩展必须显式开启。
20. **Agent/CLI 查询分权**：CLI trace 只包含过滤、选择、读取、关系扩展、generation 和预算事实；Agent relevance 与 semantic explanation 独立返回，不写入 machine authority。
21. **byte budget**：`content_budget_bytes` 必填且实施 1 byte 到 16 MiB 边界；预算不足返回 `budget_exceeded`，不截断 L3，不声称 token enforcement。
22. **关系完整性**：关系目标必须存在，跨 Zone 必须显式，`depends_on`、`derived_from`、`supersedes` 无环，candidate 不能自由创建 `supersedes`，关系深度不超过 2。
23. **因果表达**：无法证明修正与成功的因果时，系统允许 `follows` 或 `related_to` 等符合事实的关系，但不能自动改写为 `recovers_from` 或其他因果结论。

## 7. 投影与 view

24. **投影绑定**：L1、L2、record revision、L3 digest 和 manifest pointer 必须一致；任一 digest、revision 或 pointer 错配都被识别为投影失效。
25. **失效传播**：record revision 变化后旧投影保留为历史 payload，但 current manifest 不再引用；失效投影不能被 current 查询静默使用。
26. **view rebuild**：删除或破坏 current views 后，可从 current record revisions 及现存有效 L1/L2 创建新 generation 恢复；重建不调用 Agent、不从 L3 生成新摘要、不修改 record bytes。L1/L2 缺失时必须失败，不能声称仅靠 L3 已完成投影恢复。
27. **重建失败原子性**：任一 current record 或 projection 非法时，rebuild 整体失败且不提交部分 views。
28. **无独立 Catalog 漏项**：当前核心不定义独立 Catalog artifact、digest 或 command；manifest current pointers/projection references 承担 currentness，`views.json` 承担可重建 record-ID 聚合索引。投影模块接线前生命周期 commit 可以写空合法 views；接线后显式 rebuild 以新 generation 填充或恢复 views，任何阶段都不能把 stale 或部分 views 声称为完整 current 索引。

## 8. Skill、格式与安全降级

29. **单一 Skill**：只有一个公共 `themico` Skill；一次操作只加载一个 operation reference。已有正式记录只加载 persisted type 对应的一个 factory；新 candidate 先使用 common lightweight classification registry 提出唯一 type，再只加载该 type 的一个 factory。
30. **Skill references**：common、operation 和三个 type factory reference 路径完整；`common/type-registry.md` 同时包含不复制 L2/L3 的 classification registry 与 identity routing table；只有 `SKILL.md` 使用宿主要求的最小 YAML frontmatter，其他产品合同使用中文 Markdown。
31. **正式类型不可重解释**：给 persisted `design_decision` record 使用“失败经验”标题时，Skill 仍选择 design-decision factory，并由 semantic/结构审查报告错配，而不是改选 development-experience factory。
32. **安全降级**：CLI unavailable、registry 缺失、current generation 非法、投影无效或授权不完整时，只允许 draft-only；不持久化，不声称 published、current 或 valid，不用其他脚本模拟产品能力。
33. **输入安全**：machine JSON 拒绝 unknown field、duplicate key、float、invalid UTF-8、尾随 JSON 和超限输入；L3 拒绝 YAML frontmatter，路径检查覆盖当前平台可执行的 symlink/junction 情况。
34. **确定性输出**：相同输入的 canonical digest、issue 排序、query 排序、help 和 result envelope 可重复；stdout 只包含一个 JSON result envelope。

## 9. 范围边界

35. **无 MCP 越界**：当前代码和产品声明不包含 MCP adapter、MCP server、工具注册或已可用的 MCP 调用链。
36. **无 Themis integration 越界**：不修改 Themis Global Rule、Capability、Workspace 或 lifecycle，不把 Themico 正式知识写入 `workspace/context/` 并声称 Context authority。
37. **无外部模型与存储越界**：不实现 Claude API、内置 LLM、Embedding、向量数据库、SQLite、OpenViking、URL source fetch、自动知识摄取或自动经验晋升。
38. **仓库约束**：不新增 Python、产品 YAML、功能版本、版本目录、compatibility、upgrade 或 migration；CLI 二进制名为 `themico`。

## 10. 完成判定

只有在以上条件全部获得 fresh evidence，且 acceptance mapping 没有未裁决 GAP 时，才能报告 Themico 核心实现满足本 Spec。该判定不等于用户接受，也不授权 push、PR、MCP adapter 或 Themis integration。
