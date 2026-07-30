# semantic-readonly

## Permission contract

- 只读当前 Capability 明确需要的项目文件、配置、Schema、工件和 evidence references。
- 只执行 Invocation Contract 明确允许的观察或检查命令。
- 不得修改项目实现、Plan、Review、Approval、Core policy 或 lifecycle state。
- 不要求继承前序 invocation 的临时推理；只消费 current bindings 和正式引用。
- 一次只执行一个 Capability，只返回其结构化 Capability Invocation Result。
- 不调用其他 Capability 或 Agent，不选择下一路由，不保存共享 memory。
- 缺少直接证据、工具或 binding 时报告 gaps/unavailable，不推断成功。
