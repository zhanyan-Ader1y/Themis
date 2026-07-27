# Adapters — 适配器层

> 规范状态：正式设计。实现状态：已确认但未实现；当前模板只提供 Adapter 目录骨架和 Behavior Extractor 占位目录。

## 职责边界

Adapter 封装 Themis 与项目工具链之间的交互。Adapter 实现属于 Core；项目选择哪些 Adapter 及其配置属于 Workspace。

- 所有 Adapter 遵循统一的 [Adapter Protocol](protocols.md)。
- 配置存放在 `workspace/manifest.yaml`，实现中不得固化项目名称、业务模块或项目专用路径。
- Adapter 只翻译和执行外部工具交互，不决定生命周期状态、需求范围或评审结论。
- Adapter 输出必须保留退出码、stdout、stderr 和可引用的结构化结果，供 Verification 或其他调用领域记录证据。

## 设计中的 Adapter 类型

| 类型 | 目标职责 | 当前状态 |
|---|---|---|
| Git | `status`、`diff`、`log`、`blame`、SHA 与 branch 信息 | 未实现 |
| Command | 执行命令、超时、环境变量和结构化结果 | 未实现 |
| Testing | 测试执行、结果解析与覆盖率 | 未实现 |
| Schema | Migration 与 API/Schema 兼容性检查 | 未实现；仅有 Behavior Extractor 目录占位 |
| CI | 查询或触发 CI、读取运行日志 | 未实现 |
| Agent | 调用领域 Agent 并获取结构化结果 | 未实现 |

JUnit、pytest、Jest、Go test、GitHub Actions 等名称仅是未来 Adapter 可以支持的工具示例，不代表当前模板已经提供对应实现。

## Workspace 交互

```text
Adapters 读取:
  workspace/manifest.yaml    # 项目选择与配置

Adapters 输出:
  结构化执行结果              # 交由调用领域保存为 runs/evidence/cache

Adapters 不修改:
  core/                       # Core 能力在运行时保持只读
```

项目在完整扩展合同落地前不得通过把脚本放入 Workspace 来绕过 Core/Workspace 所有权。新增 Adapter 类型应先确认协议、加载方式、配置和证据合同，并同步更新本页与 [Workspace](../workspace/overview.md)。
