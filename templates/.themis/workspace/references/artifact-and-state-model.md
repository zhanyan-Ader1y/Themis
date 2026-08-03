# 工件与状态模型

## 配对语义 revisions

Paired semantic revision 使用 opaque revision directory，并且必须同时包含：

```text
<artifact-family>/<opaque-revision-id>/
  record.md
  content.md
```

任一组件缺失，或 identity、digest、scope、source、artifact bindings 不一致时，整个 revision invalid。文件或路径存在不证明 complete、current 或 authoritative。

## 结构化与 operational records

Grounding、Complexity Assessment、Plan Check、Review Check 等 structured-only judgments，以及 Invocation、attempt、marker、pointer、command evidence 与 Git observation 等 operational/evidence records，保留各自独立 family，不伪装成 paired semantic revision。

## 追问

Completed Questioning exchange 是一个 immutable `questioning/<round-revision>/` pair。未回答问题只保存 proposal 与 durable continuation，不得创建 completed round 或更新 Current Questioning Pointer。

## Lifecycle state 最小化

Lifecycle state 只保存 control facts 与 references：

- current gate 与 current pointers；
- Policy identity/digest；
- sticky flags；
- Execution Identity 与 attempt refs；
- currentness、markers、invalidations；
- incomplete operations 与 last proven gate。

Lifecycle state 不复制 Current Request claims、Plan content、design、Acceptance semantics 或 artifact prose。

## 当前性

适用 authority 需要按顺序完成 result/binding validation、唯一 Policy route、声明的 materialization、complete observation、reread、immutable revision observation、separate current pointer update 与 pointer reread。Plan 35 只描述该合同；机器 validator、recorder、digest 和 atomic writer 当前 `unavailable`。
