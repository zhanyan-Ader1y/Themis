# create-candidate

## 输入与前置条件

- `--input <candidate.json>`：`zone`、`scope`、`proposed_type`、`classification_rationale`、`source_paths`（repository-relative 本地文件路径数组）、`relations`、`l1`、`l2`（含公共头部与类型化 `payload`）、`proposed_by`。`classification_rationale` 与 `proposed_by` 必须非空。
- `--content <content.md>`：该候选的 L3 正文，必须非空且不超过 4 MiB；固定 Markdown 章节由 `proposed_type` 对应的 factory 决定。
- 前置条件：仓库已执行过 `themico init`，`.themico/workspace/` 已存在；`zone` 与 `proposed_type` 的绑定必须与 `common/type-registry` 的 identity routing table 一致。

## Agent 职责

- 先按 `common/type-registry` 的分类问题表判断材料属于哪一个 `knowledge_type`，提出唯一 `proposed_type` 与具体的 `classification_rationale`。
- 按选中 factory 的 `l2.md`、`l3.md` 起草 L1/L2 公共头部、类型化 payload 与 L3 固定章节正文。
- 声明 `source_paths` 时只能引用仓库内已存在的普通文件（非目录、非符号链接），CLI 会直接读取字节并计算 `sha256` 绑定。
- 本步骤只产出 proposal，不代表类型已被确认，也不代表内容已发布。

## 对应 CLI command

```text
themico candidate create --root <root> --input <candidate.json> --content <content.md>
```

## Human gate

无。创建候选不触发任何 Human gate；类型确认 gate 发生在后续的 `confirm-type` 操作。

## 权威输出

`output` 为一个 `model.CandidateRevision`，`status` 固定为 `proposed`，`knowledge_type` 为空（尚未固化）。`candidate_id`、`candidate_revision`、`l1_digest`、`l2_digest`、`l3_digest` 均由 CLI 计算。

## 合法 machine statuses

`succeeded`、`usage_error`、`validation_failed`、`not_found`（`.themico/workspace/` 尚不存在）、`internal_error`。

## fail-closed 行为

任何字段缺失、内容为空或超限、`proposed_type` 与 `zone` 不匹配、source path 不合法（越界、符号链接、不存在）都会使整个调用返回 `validation_failed`，不会产生半成品候选；CLI 不做任何截断或忽略字段的容错处理。
