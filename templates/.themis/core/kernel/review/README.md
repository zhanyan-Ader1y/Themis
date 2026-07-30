# Review Package

## Responsibility

Review 在任何项目实现变更前，把 checked Plan 压缩为低负担投影，独立检查投影，再通过渐进对话获得对特定 Plan revision 的明确整体批准。

## Capability mapping

- `themis-review-projection`：生成只读 `review.md`。
- `themis-review-check`：检查关键决定覆盖、投影忠实度、图形一致性和信息负担。
- `themis-review-dialogue`：解释、按需展开 Plan、记录反馈并分类影响。
- Global Control Rule：在 `approved` 后记录独立 Review Approval bindings。

## Review flow

```text
checked Plan
→ Review Projection
→ Review Check
→ Human Review Dialogue
→ explicit overall approval
→ independent Review Approval record
```

`review.md` 按抽象到具体、高影响到低影响呈现，图形按需生成。它不要求自包含完整 Plan，不作为 Impl 输入，不允许人工直接编辑。

## Approval boundary

Approval 绑定 Current Request、Questioning round、设计约束、Assessment、路径、Plan/Check、review/Check 和 baseline。任一绑定变化使旧 Approval 失效。批准 Plan 明确授权的 Impl delta 不自行使 Approval 失效；未授权 external drift 必须停止并重新核验。

## Non-ownership

Review 不实现代码、不运行 post-Impl Verification、不修改 Plan、不记录 Human Acceptance 或 Summary。

## Current status

Plan 35 provides internal Review Projection, Review Check, and Review Dialogue Capability contracts plus human-readable record templates. Strict projection/currentness contracts and fixtures belong to Plan 36; policy evaluation, per-lifecycle recording, atomic replacement, completion markers, and reread verification belong to Plan 37.
