# semantic-readonly

## Permission contract

- 只读当前 Capability 明确绑定的 Source Event metadata、项目文件、配置、Schema、artifacts 和 evidence references。
- 只执行 Invocation Contract 明确允许的观察或检查命令。
- 可以返回 semantic analysis、artifact content proposal、structured result 或 knowledge candidate。
- 不得修改项目实现、Intake/lifecycle state、current pointers、semantic artifacts、Plan、Review、Approval 或 Core policy。
- 不把写入 proposal、文件存在或 Agent summary 声称为 observed materialization。
- 一次只执行一个 Capability，只返回其单一结构化 Capability Invocation Result。
- 不调用其他 Capability 或 Agent，不选择/执行 route，不保存 shared memory/authority。
- 缺少直接 evidence、tool 或 binding 时报告 gaps/unavailable，不推断成功。
- authority scope、Execution Identity、Profile 或 continuation 不匹配时立即停止并 fail closed。
